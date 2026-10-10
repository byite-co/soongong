// SubjectsController (S09): the subject screen's writes — add, edit (name ·
// colour), delete with the 5-second undo window and deferred commit (D22;
// records move to 기타 at commit, `SubjectRepository.commitDelete`). Every
// write runs in `SyncWriter.runOwnedTransaction` with this controller's
// liveness so a stale controller never writes into another account's
// database ([S06d] · [S07]). Mirrors `PlannerController`.

import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/theme/tokens.dart';
import '../../../data/repositories/repository_providers.dart';
import '../../../data/repositories/subject_repository.dart';
import '../domain/subject_draft.dart';

part 'subjects_controller.g.dart';

sealed class SubjectSaveOutcome {
  const SubjectSaveOutcome();
}

class SubjectSaved extends SubjectSaveOutcome {
  const SubjectSaved(this.id);

  final String id;
}

class SubjectSaveFailed extends SubjectSaveOutcome {
  const SubjectSaveFailed(this.error);

  final Object error;
}

class SubjectSaveInvalid extends SubjectSaveOutcome {
  const SubjectSaveInvalid(this.errors);

  final List<SubjectDraftError> errors;
}

/// A soft-deleted subject inside its undo window.
class PendingSubjectDelete {
  PendingSubjectDelete._(this.id, this._undo);

  final String id;
  final Future<bool> Function() _undo;
  bool _undone = false;

  Future<bool> undo() async {
    if (_undone) return false;
    _undone = true;
    return _undo();
  }
}

class SubjectsController {
  SubjectsController({required this.subjects, this.undoWindow = AppMotion.undoWindow});

  final SubjectRepository subjects;
  final Duration undoWindow;

  bool _disposed = false;
  bool get isDisposed => _disposed;
  final Set<Timer> _timers = <Timer>{};

  void dispose() {
    if (_disposed) return;
    _disposed = true;
    for (final t in _timers) {
      t.cancel();
    }
    _timers.clear();
  }

  /// Validates against the live subjects, then creates ([id] null) or
  /// updates. Never throws.
  Future<SubjectSaveOutcome> save(SubjectDraft draft, {String? id}) async {
    if (_disposed) return SubjectSaveFailed(StateError('controller disposed'));
    try {
      return await subjects.writer.runOwnedTransaction(
        () async {
          final live = await subjects.getAll();
          final errors = draft.validate(live, editingId: id);
          if (errors.isNotEmpty) return SubjectSaveInvalid(errors);
          if (id == null) {
            final created = await subjects.create(name: draft.trimmedName, colorIndex: draft.colorIndex);
            return SubjectSaved(created.id);
          }
          await subjects.update(id, name: draft.trimmedName, colorIndex: draft.colorIndex);
          return SubjectSaved(id);
        },
        alive: () => !_disposed,
      );
    } on Object catch (e) {
      return SubjectSaveFailed(e);
    }
  }

  /// Soft-deletes [id]; commit after the window unless undone (D22).
  Future<PendingSubjectDelete> delete(String id) async {
    if (_disposed) throw StateError('controller disposed');
    final now = subjects.ctx.clock.now();
    await subjects.writer.runOwnedTransaction(() => subjects.softDelete(id), alive: () => !_disposed);
    late final Timer timer;
    timer = Timer(undoWindow, () async {
      _timers.remove(timer);
      if (_disposed) return;
      try {
        await subjects.writer.runOwnedTransaction(
          () => _commitIfDue(id, notBefore: now.add(undoWindow)),
          alive: () => !_disposed,
        );
      } on Object {
        // Left pending: the restart settlement commits it (D22).
      }
    });
    _timers.add(timer);
    return PendingSubjectDelete._(id, () async {
      if (_disposed) return false;
      timer.cancel();
      _timers.remove(timer);
      try {
        return await subjects.writer.runOwnedTransaction(
          () async {
            final row = await subjects.get(id);
            if (row == null || row.stamp.pendingDeleteUntil == null) return false;
            await subjects.undoDelete(id);
            return true;
          },
          alive: () => !_disposed,
        );
      } on Object {
        return false;
      }
    });
  }

  Future<void> _commitIfDue(String id, {required DateTime notBefore}) async {
    final row = await subjects.get(id);
    final until = row?.stamp.pendingDeleteUntil;
    if (until != null && !subjects.ctx.clock.now().isBefore(until)) {
      await subjects.commitDelete(id);
    }
  }
}

/// Rebuilt when the repositories change (account switch, D27).
@Riverpod(keepAlive: true)
SubjectsController subjectsController(Ref ref) {
  final c = SubjectsController(subjects: ref.watch(subjectRepositoryProvider));
  ref.onDispose(c.dispose);
  return c;
}
