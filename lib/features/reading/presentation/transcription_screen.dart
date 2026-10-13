import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/contracts/transcription_engine.dart';
import '../../../core/strings/study_strings.dart';
import '../../../core/widgets/app_button.dart';
import '../../../data/auth/auth_gate.dart';
import '../../../data/photos/study_image_picker.dart';
import '../../../data/repositories/local_purge.dart';
import '../../../data/repositories/repository_providers.dart';
import '../../../data/repositories/study_repository.dart';
import '../../measure/application/measure_controller.dart';
import '../application/study_providers.dart';

class TranscriptionScreen extends ConsumerStatefulWidget {
  const TranscriptionScreen({super.key, this.plannerItemId, this.pickImage});
  final String? plannerItemId;
  final Future<StudyPickedImage?> Function(ImageSource)? pickImage;
  @override
  ConsumerState<TranscriptionScreen> createState() =>
      _TranscriptionScreenState();
}

class _TranscriptionScreenState extends ConsumerState<TranscriptionScreen> {
  final _text = TextEditingController();
  Uint8List? _image;
  TranscriptionKind _kind = TranscriptionKind.text;
  DocumentTranscription? _transcription;
  StudyDocument? _saved;
  bool _agreed = false;
  bool _busy = false;
  String? _message;
  int _operation = 0;
  int? _generation;
  late final _picker = widget.pickImage ?? StudyImagePicker().pick;

  @override
  void dispose() {
    _operation++;
    _image?.fillRange(0, _image!.length, 0);
    _text.dispose();
    super.dispose();
  }

  Future<void> _pick(ImageSource source) async {
    if (_busy ||
        (source == ImageSource.camera &&
            ref.read(measureControllerProvider).isLive))
      return;
    final operation = ++_operation;
    final owner = ref.read(currentUserIdProvider);
    final writer = ref.read(syncWriterProvider);
    int? generation;
    bool current() =>
        mounted &&
        operation == _operation &&
        ref.read(currentUserIdProvider) == owner &&
        (generation == null || writer.purgeGeneration == generation);
    setState(() {
      _busy = true;
      _message = null;
    });
    StudyPickedImage? picked;
    try {
      generation = await writer.refreshPurgeGeneration();
      final purge = await LocalPurge.readState(writer.db);
      if (!current() || purge.inProgress || purge.generation != generation)
        return;
      _generation = generation;
      // No picker resize/compression: it may leave an undisclosed original copy.
      // ImagePicker-created app cache files are removed below. A user's
      // original outside our temporary directory is never deleted.
      picked = await _picker(source);
      if (picked == null || !current()) return;
      final length = await picked.length();
      if (!current()) return;
      if (length > 4 * 1024 * 1024) {
        setState(() => _message = StudyStrings.tooLarge);
        return;
      }
      final bytes = await picked.readAsBytes();
      if (!current()) {
        bytes.fillRange(0, bytes.length, 0);
        return;
      }
      setState(() {
        _image?.fillRange(0, _image!.length, 0);
        _image = bytes;
        _transcription = null;
        _saved = null;
        _agreed = false;
        _text.clear();
      });
    } on Object {
      if (current()) setState(() => _message = StudyStrings.error);
    } finally {
      if (picked != null) {
        try {
          await picked.cleanup();
        } on Object {
          if (current()) {
            _image?.fillRange(0, _image!.length, 0);
            setState(() {
              _image = null;
              _transcription = null;
              _message = StudyStrings.cacheCleanupFailed;
            });
          }
        }
      }
      if (current()) setState(() => _busy = false);
    }
  }

  Future<void> _recognize() async {
    final engine = ref.read(transcriptionEngineProvider);
    final gate = ref.read(authGateProvider);
    if (engine == null) {
      setState(() => _message = StudyStrings.unavailable);
      return;
    }
    if (gate is! AuthGateSignedIn ||
        gate.profile?.readingConsentActive != true) {
      setState(() => _message = StudyStrings.readingConsent);
      return;
    }
    if (_image == null || !_agreed || _busy) return;
    final op = ++_operation;
    final owner = gate.userId;
    final writer = ref.read(syncWriterProvider);
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      final generation = await writer.refreshPurgeGeneration();
      final before = await LocalPurge.readState(writer.db);
      if (before.inProgress || before.generation != generation) return;
      final epoch = before.epoch;
      if (!mounted || op != _operation) return;
      _generation = generation;
      final result = await engine.transcribe(_image!, _kind, epoch: epoch);
      if (!mounted ||
          op != _operation ||
          ref.read(currentUserIdProvider) != owner)
        return;
      final state = await LocalPurge.readState(writer.db);
      if (!mounted ||
          ref.read(currentUserIdProvider) != owner ||
          state.inProgress ||
          state.generation != generation)
        return;
      setState(() {
        _generation = generation;
        _transcription = result;
        _text.text = result.text;
        _saved = null;
      });
    } on Object {
      if (mounted && op == _operation)
        setState(() => _message = StudyStrings.error);
    } finally {
      if (mounted && op == _operation) setState(() => _busy = false);
    }
  }

  Future<void> _save() async {
    final transcription = _transcription;
    if (transcription == null || _generation == null || _busy) return;
    final repo = ref.read(studyRepositoryProvider);
    final owner = ref.read(currentUserIdProvider);
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      final generation = _generation!;
      final result = await repo.save(
        transcription: transcription,
        text: _text.text,
        generation: generation,
        id: _saved?.id,
        expectedRevision: _saved?.revision,
        plannerItemId: widget.plannerItemId,
      );
      if (!mounted || ref.read(currentUserIdProvider) != owner) return;
      ref.invalidate(studyDocumentsProvider);
      setState(() {
        _saved = result;
        _message = StudyStrings.saved;
      });
    } on Object {
      if (mounted) setState(() => _message = StudyStrings.error);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _delete(StudyDocument document) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        content: const Text(StudyStrings.deletePrompt),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(StudyStrings.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(StudyStrings.delete),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final repo = ref.read(studyRepositoryProvider);
    setState(() => _busy = true);
    try {
      final generation = await repo.writer.refreshPurgeGeneration();
      await repo.delete(document.id, generation);
      if (mounted) {
        ref.invalidate(studyDocumentsProvider);
        if (_saved?.id == document.id) setState(() => _saved = null);
      }
    } on Object {
      if (mounted) setState(() => _message = StudyStrings.error);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final documents = ref.watch(studyDocumentsProvider);
    ref.listen(studyGenerationProvider, (_, next) {
      final generation = next.asData?.value;
      if (_generation != null &&
          generation != null &&
          generation != _generation) {
        _operation++;
        _image?.fillRange(0, _image!.length, 0);
        setState(() {
          _image = null;
          _text.clear();
          _transcription = null;
          _saved = null;
          _busy = false;
          _agreed = false;
          _generation = null;
        });
      }
    });
    final measuring = ref.watch(measureControllerProvider).isLive;
    ref.listen(currentUserIdProvider, (_, _) {
      _operation++;
      _image?.fillRange(0, _image!.length, 0);
      setState(() {
        _image = null;
        _text.clear();
        _transcription = null;
        _saved = null;
        _busy = false;
        _agreed = false;
      });
    });
    return Scaffold(
      appBar: AppBar(title: const Text(StudyStrings.title)),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text(StudyStrings.localOnly),
          const SizedBox(height: 16),
          AppButton.secondary(
            label: StudyStrings.select,
            onPressed: _busy ? null : () => _pick(ImageSource.gallery),
          ),
          AppButton.secondary(
            label: StudyStrings.camera,
            onPressed: _busy || measuring
                ? null
                : () => _pick(ImageSource.camera),
          ),
          if (_image != null) ...[
            const SizedBox(height: 16),
            Image.memory(_image!, height: 220, fit: BoxFit.contain),
            SegmentedButton<TranscriptionKind>(
              segments: const [
                ButtonSegment(
                  value: TranscriptionKind.text,
                  label: Text(StudyStrings.text),
                ),
                ButtonSegment(
                  value: TranscriptionKind.math,
                  label: Text(StudyStrings.math),
                ),
              ],
              selected: {_kind},
              onSelectionChanged: _busy
                  ? null
                  : (v) => setState(() {
                      _kind = v.single;
                      _transcription = null;
                      _saved = null;
                      _text.clear();
                    }),
            ),
            const Text(StudyStrings.consent),
            CheckboxListTile(
              value: _agreed,
              title: const Text(StudyStrings.agree),
              onChanged: _busy
                  ? null
                  : (v) => setState(() => _agreed = v ?? false),
            ),
            AppButton(
              label: StudyStrings.recognize,
              busy: _busy,
              onPressed: _agreed ? _recognize : null,
            ),
          ],
          if (_transcription != null) ...[
            const Text(StudyStrings.review),
            TextField(
              controller: _text,
              enabled: !_busy,
              maxLines: 10,
              maxLength: 20000,
            ),
            AppButton(
              label: StudyStrings.confirm,
              busy: _busy,
              onPressed: _save,
            ),
          ],
          if (_message != null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(_message!),
            ),
          const SizedBox(height: 16),
          const Text(StudyStrings.history),
          ...documents.when(
            data: (rows) => rows
                .map(
                  (document) => ListTile(
                    title: Text(
                      document.text,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: const Text(StudyStrings.solveTitle),
                    onTap: _busy
                        ? null
                        : () => context.push('/reading/solve/${document.id}'),
                    trailing: IconButton(
                      tooltip: StudyStrings.delete,
                      icon: const Icon(Icons.delete_outline),
                      onPressed: _busy ? null : () => _delete(document),
                    ),
                  ),
                )
                .toList(),
            loading: () => <Widget>[const LinearProgressIndicator()],
            error: (_, _) => <Widget>[const Text(StudyStrings.error)],
          ),
        ],
      ),
    );
  }
}
