import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/contracts/problem_solver.dart';
import '../../../core/strings/study_strings.dart';
import '../../../core/widgets/app_button.dart';
import '../../../data/auth/auth_gate.dart';
import '../../../data/repositories/local_purge.dart';
import '../../../data/repositories/repository_providers.dart';
import '../../../data/repositories/study_repository.dart';
import '../application/study_providers.dart';

class ProblemSolverScreen extends ConsumerStatefulWidget {
  const ProblemSolverScreen({super.key, required this.documentId});
  final String documentId;
  @override
  ConsumerState<ProblemSolverScreen> createState() =>
      _ProblemSolverScreenState();
}

class _ProblemSolverScreenState extends ConsumerState<ProblemSolverScreen> {
  final _reference = TextEditingController();
  StudyDocument? _document;
  ProblemSolution? _solution;
  bool _agreed = false;
  bool _busy = false;
  String? _message;
  int? _generation;
  int _operation = 0;

  bool _current(int op, String owner) =>
      mounted && op == _operation && ref.read(currentUserIdProvider) == owner;

  @override
  void dispose() {
    _operation++;
    _reference.dispose();
    super.dispose();
  }

  Future<void> _solve() async {
    if (!_agreed || _busy) return;
    final gate = ref.read(authGateProvider);
    if (gate is! AuthGateSignedIn ||
        gate.profile?.readingConsentActive != true) {
      setState(() => _message = StudyStrings.readingConsent);
      return;
    }
    final engine = ref.read(problemSolverProvider);
    if (engine == null) {
      setState(() => _message = StudyStrings.unavailable);
      return;
    }
    final repo = ref.read(studyRepositoryProvider);
    final owner = gate.userId;
    final op = ++_operation;
    setState(() {
      _busy = true;
      _message = null;
      _solution = null;
    });
    try {
      final generation = await repo.writer.refreshPurgeGeneration();
      final document = await repo.get(widget.documentId);
      if (document == null) throw StateError('document_unavailable');
      final before = await LocalPurge.readState(repo.db);
      if (before.inProgress || before.generation != generation) return;
      final epoch = before.epoch;
      if (!_current(op, owner)) return;
      _generation = generation;
      _document = document;
      final reference = _reference.text.trim();
      final result = await engine.solve(
        documentId: document.id,
        revision: document.revision,
        text: document.text,
        epoch: epoch,
        referenceAnswer: reference.isEmpty ? null : reference,
      );
      final current = await repo.get(document.id);
      final purge = await LocalPurge.readState(repo.db);
      if (!_current(op, owner)) return;
      if (purge.inProgress ||
          purge.generation != generation ||
          current?.revision != document.revision)
        throw StateError('stale_result');
      if (result.documentId != document.id ||
          result.revision != document.revision)
        throw StateError('stale_result');
      setState(() {
        _generation = generation;
        _document = document;
        _solution = result;
      });
    } on Object {
      if (_current(op, owner)) setState(() => _message = StudyStrings.error);
    } finally {
      if (_current(op, owner)) setState(() => _busy = false);
    }
  }

  Future<void> _save() async {
    final result = _solution;
    if (result == null || _generation == null || _busy) return;
    final repo = ref.read(studyRepositoryProvider);
    final owner = ref.read(currentUserIdProvider);
    final generation = _generation!;
    final op = ++_operation;
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      await repo.saveSolution(
        result.documentId,
        result.revision,
        result.toJson(),
        generation,
      );
      final purge = await LocalPurge.readState(repo.db);
      if (_current(op, owner) &&
          !purge.inProgress &&
          purge.generation == generation) {
        ref.invalidate(studyDocumentsProvider);
        setState(() => _message = StudyStrings.saved);
      }
    } on Object {
      if (_current(op, owner)) setState(() => _message = StudyStrings.error);
    } finally {
      if (_current(op, owner)) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final rows = ref.watch(studyDocumentsProvider);
    ref.listen(studyDocumentsProvider, (_, next) {
      final values = next.asData?.value;
      if (values == null || _document == null) return;
      final current = values
          .where((d) => d.id == widget.documentId)
          .firstOrNull;
      if (current?.revision != _document!.revision) {
        _operation++;
        setState(() {
          _solution = null;
          _document = null;
          _busy = false;
          _message = null;
        });
      }
    });
    ref.listen(studyGenerationProvider, (_, next) {
      final generation = next.asData?.value;
      if (_generation != null &&
          generation != null &&
          generation != _generation) {
        _operation++;
        setState(() {
          _solution = null;
          _document = null;
          _busy = false;
          _generation = null;
          _reference.clear();
        });
      }
    });
    final document = rows.asData?.value
        .where((d) => d.id == widget.documentId)
        .firstOrNull;
    ref.listen(currentUserIdProvider, (_, _) {
      _operation++;
      setState(() {
        _solution = null;
        _document = null;
        _busy = false;
        _agreed = false;
        _generation = null;
        _reference.clear();
        _message = null;
      });
    });
    ProblemSolution? stored;
    try {
      if (document?.solution != null)
        stored = ProblemSolution.fromJson(document!.solution!);
    } on Object {
      stored = null;
    }
    final candidate = _solution ?? stored;
    final result =
        candidate?.documentId == document?.id &&
            candidate?.revision == document?.revision
        ? candidate
        : null;
    return Scaffold(
      appBar: AppBar(title: const Text(StudyStrings.solveTitle)),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text(StudyStrings.solveHint),
          const SizedBox(height: 16),
          SelectableText(
            document?.text ?? _document?.text ?? StudyStrings.error,
          ),
          TextField(
            controller: _reference,
            enabled: !_busy,
            maxLength: 100,
            decoration: const InputDecoration(
              labelText: StudyStrings.reference,
            ),
          ),
          CheckboxListTile(
            value: _agreed,
            title: const Text(StudyStrings.solveConsent),
            onChanged: _busy
                ? null
                : (v) => setState(() => _agreed = v ?? false),
          ),
          AppButton(
            key: ValueKey('solve-$_operation'),
            label: StudyStrings.solve,
            busy: _busy,
            onPressed: _agreed && document != null ? _solve : null,
          ),
          if (result != null) ...[
            const SizedBox(height: 20),
            SelectableText(result.answer),
            Text(switch (result.verification) {
              SolutionVerification.verified => StudyStrings.verified,
              SolutionVerification.contradicted => StudyStrings.contradicted,
              SolutionVerification.inconclusive => StudyStrings.inconclusive,
              SolutionVerification.unsupported => StudyStrings.unsupported,
            }),
            const SizedBox(height: 12),
            SelectableText(result.explanation),
            AppButton.secondary(
              label: StudyStrings.saveSolution,
              busy: _busy,
              onPressed: _solution == null ? null : _save,
            ),
          ],
          if (_message != null) Text(_message!),
        ],
      ),
    );
  }
}
