import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/contracts/study_restore.dart';
import '../../../core/contracts/transcription_engine.dart';
import '../../../core/strings/study_strings.dart';
import '../../../core/widgets/app_button.dart';
import '../../../data/auth/auth_gate.dart';
import '../../../data/photos/owned_picker_coordinator.dart';
import '../../../data/photos/study_crop.dart';
import '../../../data/photos/study_image_picker.dart';
import '../../../data/repositories/ai_request_repository.dart';
import '../../../data/repositories/local_purge.dart';
import '../../../data/repositories/repository_providers.dart';
import '../../../data/repositories/study_repository.dart';
import '../../../data/temp/temp_providers.dart';
import '../../measure/application/measure_controller.dart';
import '../application/study_providers.dart';
import 'crop_dialog.dart';

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
  String? _requestId;
  void Function()? _releaseApproval;

  @override
  void dispose() {
    _releaseApproval?.call();
    _operation++;
    _image?.fillRange(0, _image!.length, 0);
    _text.dispose();
    super.dispose();
  }

  Future<void> _pick(ImageSource source) async {
    if (_busy ||
        (source == ImageSource.camera &&
            ref.read(measureControllerProvider).isLive)) {
      return;
    }
    final operation = ++_operation;
    final owner = ref.read(currentUserIdProvider);
    final writer = ref.read(syncWriterProvider);
    final ownership = ref.read(tempOwnershipProvider);
    final tempEpoch = ownership.epoch(owner);
    int? generation;
    bool ownsOperation() =>
        mounted &&
        operation == _operation &&
        ownership.epoch(owner) == tempEpoch &&
        ref.read(currentUserIdProvider) == owner;
    bool current() =>
        ownsOperation() &&
        (generation == null || writer.purgeGeneration == generation);
    setState(() {
      _busy = true;
      _message = null;
    });
    StudyPickedImage? picked;
    try {
      generation = await writer.refreshPurgeGeneration();
      final purge = await LocalPurge.readState(writer.db);
      if (!current() || purge.inProgress || purge.generation != generation) {
        return;
      }
      _generation = generation;
      // No picker resize/compression: it may leave an undisclosed original copy.
      // ImagePicker-created app cache files are removed below. A user's
      // original outside our temporary directory is never deleted.
      picked = widget.pickImage != null
          ? await widget.pickImage!(source)
          : await ref
                .read(ownedPickerCoordinatorProvider)
                .pick(
                  source,
                  createTask: () => ref
                      .read(tempOwnershipProvider)
                      .create(
                        writer,
                        'picker',
                        generation: generation!,
                        alive: current,
                      ),
                );
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
        _requestId = null;
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
      // A purge can interrupt initial generation loading, before the stream
      // listener has an assigned generation to invalidate. Unlock only our
      // own operation even then; never unlock a newer request.
      if (ownsOperation()) setState(() => _busy = false);
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
      final approvals = ref.read(aiApprovalControllerProvider);
      bool valid() {
        if (!mounted ||
            op != _operation ||
            ref.read(currentUserIdProvider) != owner ||
            writer.purgeGeneration != generation ||
            !_agreed) {
          return false;
        }
        final gate = ref.read(authGateProvider);
        return gate is AuthGateSignedIn &&
            gate.profile?.readingConsentActive == true;
      }

      _requestId = null;
      _releaseApproval = approvals.bind(
        valid: valid,
        generation: generation,
        present: (quote) async {
          if (!valid()) return false;
          return await showDialog<bool>(
                context: context,
                builder: (dialog) => AlertDialog(
                  title: const Text('전사 실행 확인'),
                  content: Text(
                    '${quote.operation == 'ocr_math' ? '수식 전사' : '한국어 전사'} · ${quote.points} AI 포인트\n정책: ${quote.id}\n이용 조건: ${quote.terms}\n개발 평가용입니다. 풀이·정답 판정은 하지 않습니다.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(dialog, false),
                      child: const Text('취소'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(dialog, true),
                      child: const Text('포인트 확인 · 실행'),
                    ),
                  ],
                ),
              ) ??
              false;
        },
      );
      final result = await engine.transcribe(_image!, _kind, epoch: epoch);
      _requestId = approvals.requestId;
      if (!valid()) return;
      if (!mounted ||
          op != _operation ||
          ref.read(currentUserIdProvider) != owner) {
        return;
      }
      final state = await LocalPurge.readState(writer.db);
      if (!mounted ||
          ref.read(currentUserIdProvider) != owner ||
          state.inProgress ||
          state.generation != generation) {
        return;
      }
      setState(() {
        _generation = generation;
        _transcription = result;
        _text.text = result.text;
        _saved = null;
      });
    } on Object {
      if (mounted && op == _operation) {
        setState(() => _message = StudyStrings.error);
      }
    } finally {
      if (mounted && op == _operation) {
        _requestId ??= ref.read(aiApprovalControllerProvider).requestId;
        ref.invalidate(aiRequestsProvider);
      }
      _releaseApproval?.call();
      _releaseApproval = null;
      if (mounted && op == _operation) setState(() => _busy = false);
    }
  }

  Future<void> _save() async {
    final transcription = _transcription;
    if (transcription == null || _generation == null || _busy) return;
    final repo = ref.read(studyRepositoryProvider);
    final owner = ref.read(currentUserIdProvider);
    final op = ++_operation;
    final generation = _generation!;
    bool current() =>
        mounted &&
        op == _operation &&
        ref.read(currentUserIdProvider) == owner &&
        repo.writer.purgeGeneration == generation;
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      final result = _requestId != null
          ? await ref
                .read(aiRequestRepositoryProvider)
                .confirm(
                  _requestId!,
                  _text.text,
                  generation,
                  expectedRevision: _saved?.revision,
                  plannerItemId: widget.plannerItemId,
                )
          : await repo.save(
              transcription: transcription,
              text: _text.text,
              generation: generation,
              id: _saved?.id,
              expectedRevision: _saved?.revision,
              plannerItemId: widget.plannerItemId,
            );
      final purge = await LocalPurge.readState(repo.db);
      if (!current() || purge.inProgress || purge.generation != generation) {
        return;
      }
      ref.invalidate(studyDocumentsProvider);
      ref.invalidate(aiRequestsProvider);
      setState(() {
        _saved = result;
        _message = StudyStrings.saved;
      });
    } on Object {
      if (current()) setState(() => _message = StudyStrings.error);
    } finally {
      if (current()) setState(() => _busy = false);
    }
  }

  Future<void> _delete(StudySummary document) async {
    if (_busy) return;
    final repo = ref.read(studyRepositoryProvider);
    final owner = ref.read(currentUserIdProvider);
    final op = ++_operation;
    bool current() =>
        mounted && op == _operation && ref.read(currentUserIdProvider) == owner;
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      // Capture ownership before displaying the dialog. Confirmation cannot
      // adopt the account/generation that replaced the document underneath it.
      final generation = await repo.writer.refreshPurgeGeneration();
      if (!mounted || !current()) return;
      _generation = generation;
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
      if (confirmed != true || !current()) return;
      await repo.delete(document.id, generation);
      if (current() && repo.writer.purgeGeneration == generation) {
        ref.invalidate(studyDocumentsProvider);
        if (_saved?.id == document.id) setState(() => _saved = null);
      }
    } on Object {
      if (current()) setState(() => _message = StudyStrings.error);
    } finally {
      if (current()) setState(() => _busy = false);
    }
  }

  Future<void> _crop() async {
    if (_busy || _image == null || _generation == null) return;
    final op = ++_operation;
    final owner = ref.read(currentUserIdProvider);
    final generation = _generation!;
    final writer = ref.read(syncWriterProvider);
    final ownership = ref.read(tempOwnershipProvider);
    final token = ownership.epoch(owner);
    bool current() =>
        mounted &&
        op == _operation &&
        ref.read(currentUserIdProvider) == owner &&
        writer.purgeGeneration == generation &&
        ownership.epoch(owner) == token;
    setState(() => _busy = true);
    try {
      final selection = await showDialog<CropSelection>(
        context: context,
        builder: (_) => StudyCropDialog(image: _image!),
      );
      if (selection == null || !current()) return;
      final task = await ownership.create(
        writer,
        'picker',
        generation: generation,
        alive: current,
      );
      try {
        final bytes = await cropStudyImage(
          _image!,
          selection.rect,
          selection.turns,
          task,
        );
        if (!current()) {
          bytes.fillRange(0, bytes.length, 0);
          return;
        }
        setState(() {
          _image!.fillRange(0, _image!.length, 0);
          _image = bytes;
          _transcription = null;
          _requestId = null;
          _saved = null;
          _text.clear();
          _agreed = false;
        });
      } finally {
        await task.cleanup();
      }
    } on Object {
      if (current()) setState(() => _message = StudyStrings.error);
    } finally {
      if (current()) setState(() => _busy = false);
    }
  }

  Future<void> _recover(PendingAiRequest pending, {bool cancel = false}) async {
    if (_busy) return;
    final jobs = ref.read(remoteAiJobsProvider);
    if (jobs == null) return;
    final gate = ref.read(authGateProvider);
    if (gate is! AuthGateSignedIn ||
        gate.profile?.readingConsentActive != true) {
      return;
    }
    final owner = gate.userId;
    final op = ++_operation;
    final repository = ref.read(aiRequestRepositoryProvider);
    final writer = repository.documents.writer;
    bool current() =>
        mounted &&
        op == _operation &&
        ref.read(currentUserIdProvider) == owner &&
        writer.purgeGeneration == pending.generation;
    setState(() => _busy = true);
    try {
      await jobs.status(pending.epoch, pending.id, cancel: cancel);
      final updated = await repository.get(pending.id);
      if (!current() || updated == null) return;
      final currentGate = ref.read(authGateProvider);
      if (currentGate is! AuthGateSignedIn ||
          currentGate.profile?.readingConsentActive != true) {
        return;
      }
      final document = updated.documentId == null
          ? null
          : await repository.documents.get(updated.documentId!);
      if (!current()) return;
      setState(() {
        _image?.fillRange(0, _image!.length, 0);
        _image = null;
        _agreed = false;
        _requestId = updated.id;
        _generation = updated.generation;
        _transcription = updated.expired ? null : updated.transcription;
        _kind = updated.operation == 'ocr_math'
            ? TranscriptionKind.math
            : TranscriptionKind.text;
        _text.text = updated.correction ?? _transcription?.text ?? '';
        _saved = document;
        _message =
            '${_requestState(updated)}\n원본 사진은 보관하지 않았습니다. 요청을 자동 재실행하지 않습니다.';
      });
    } on Object {
      if (current()) {
        setState(
          () => _message =
              '요청을 조회하지 못했습니다. 요청 없음·연결 오류는 다시 실행하지 않습니다. 상태를 다시 확인해 주세요.',
        );
      }
    } finally {
      if (current()) {
        ref.invalidate(aiRequestsProvider);
        setState(() => _busy = false);
      }
    }
  }

  String _requestState(PendingAiRequest p) {
    final state = p.expired
        ? '결과 보관 만료'
        : switch (p.state) {
            'succeeded' => '결과 수신 · 사용자 확인 필요',
            'cancelled' => '취소됨',
            'failed' => '처리 실패',
            'reconciliation_required' => '실행 여부 확인 중',
            'submitting' => '전송 결과 확인 필요',
            _ => '처리 중',
          };
    final points = switch (p.pointsState) {
      'released' => '포인트 반환',
      'settled' => '포인트 사용 확정',
      'reserved' => '포인트 예약 중',
      _ => '포인트 상태 확인 필요',
    };
    return '$state · $points';
  }

  @override
  Widget build(BuildContext context) {
    final documents = ref.watch(studyDocumentsProvider);
    final requests = ref.watch(aiRequestsProvider);
    ref.listen(authGateProvider, (_, next) {
      if (next is AuthGateSignedIn &&
          next.profile?.readingConsentActive == true) {
        return;
      }
      _releaseApproval?.call();
      _operation++;
      _image?.fillRange(0, _image!.length, 0);
      setState(() {
        _image = null;
        _transcription = null;
        _requestId = null;
        _text.clear();
        _busy = false;
        _agreed = false;
        _saved = null;
      });
    });
    ref.listen(tempInvalidationProvider, (_, next) {
      if (next.asData?.value != ref.read(currentUserIdProvider)) return;
      _operation++;
      _image?.fillRange(0, _image!.length, 0);
      setState(() {
        _image = null;
        _transcription = null;
        _requestId = null;
        _text.clear();
        _agreed = false;
        _busy = false;
        _generation = null;
      });
    });
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
          _requestId = null;
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
        _requestId = null;
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
          TextButton(
            onPressed: _busy
                ? null
                : () => context.push(
                    Uri(
                      path: '/reading/grading',
                      queryParameters: widget.plannerItemId == null
                          ? null
                          : {'itemId': widget.plannerItemId!},
                    ).toString(),
                  ),
            child: const Text('채점표시 판독으로 이동'),
          ),
          const Text(StudyStrings.interruptedPicker),
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
            TextButton(
              onPressed: _busy ? null : _crop,
              child: const Text('영역 선택 · 회전'),
            ),
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
                      _requestId = null;
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
            Text('엔진: ${_transcription!.engine}'),
            if (_kind == TranscriptionKind.math)
              const Text('LaTeX 원문 · 자동 실행이나 수학적 검증을 하지 않습니다.'),
            SelectableText(_transcription!.text),
            TextField(
              controller: _text,
              enabled: !_busy,
              maxLines: 10,
              maxLength: 20000,
              onChanged: (value) {
                final id = _requestId;
                final generation = _generation;
                if (id != null && generation != null) {
                  ref
                      .read(aiRequestRepositoryProvider)
                      .correct(id, value, generation)
                      .catchError((Object _) {
                        if (mounted) {
                          setState(
                            () => _message = '교정 내용 보관에 실패했습니다. 입력은 유지됩니다.',
                          );
                        }
                      });
                }
              },
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
          const Text('이전 전사 요청 · 상태 조회'),
          ...requests.when(
            data: (rows) => rows
                .map(
                  (p) => ListTile(
                    title: Text(p.operation == 'ocr_math' ? '수식 전사' : '한국어 전사'),
                    subtitle: Text(_requestState(p)),
                    onTap: _busy ? null : () => _recover(p),
                    trailing:
                        {
                          'submitting',
                          'reserved',
                          'dispatching',
                          'reconciliation_required',
                        }.contains(p.state)
                        ? TextButton(
                            onPressed: _busy
                                ? null
                                : () => _recover(p, cancel: true),
                            child: const Text('취소 요청'),
                          )
                        : null,
                  ),
                )
                .toList(),
            loading: () => <Widget>[],
            error: (_, _) => <Widget>[const Text('이전 요청을 읽지 못했습니다.')],
          ),
          const Text(StudyStrings.history),
          ...documents.when(
            data: (rows) => rows
                .map(
                  (document) => ListTile(
                    title: Text(
                      document.title,
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
