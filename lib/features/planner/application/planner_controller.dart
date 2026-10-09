// PlannerController (S07): the planner's writes — register/edit/delete of
// items, bands and recurrences, subject creation, done toggles. Every write
// is one repository transaction (outbox included, D2); deletion is soft
// with the 5-second undo window and a deferred commit (D22). The deferred
// commit and the undo run in `SyncWriter.runOwnedTransaction` with this
// controller's liveness, so after an account switch (D27) a stale
// controller never writes into the new account's database ([S06d]).

import 'dart:async';

import 'package:drift/drift.dart' show Value;

import '../../../core/domain/entities/entities.dart';
import '../../../core/theme/tokens.dart';
import '../../../data/repositories/planner_repository.dart';
import '../../../data/repositories/subject_repository.dart';
import '../domain/planner_draft.dart';

sealed class PlannerSaveOutcome {
  const PlannerSaveOutcome();
}

class PlannerSaved extends PlannerSaveOutcome {
  const PlannerSaved(this.id);

  /// The saved item or recurrence id.
  final String id;
}

class PlannerSaveFailed extends PlannerSaveOutcome {
  const PlannerSaveFailed(this.error);

  final Object error;
}

/// A soft-deleted entry inside its undo window.
class PendingDelete {
  PendingDelete._(this.target, this._undo);

  final DraftTarget target;
  final Future<bool> Function() _undo;
  bool _undone = false;

  /// Restores the entry. true when restored; false when the window had
  /// already been committed, the controller was disposed, or the write
  /// was refused (another account owns the database).
  Future<bool> undo() async {
    if (_undone) return false;
    _undone = true;
    return _undo();
  }
}

class PlannerController {
  PlannerController({
    required this.planner,
    required this.subjects,
    this.undoWindow = AppMotion.undoWindow,
  });

  final PlannerRepository planner;
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

  // ---------------------------------------------------------------------
  // Save

  /// Persists [draft] into [target]. Never throws: failures come back as
  /// [PlannerSaveFailed] so the sheet keeps the input (CLAUDE.md §5).
  Future<PlannerSaveOutcome> save(PlannerDraft draft, DraftTarget target) async {
    if (_disposed) return PlannerSaveFailed(StateError('controller disposed'));
    final errors = draft.validate();
    if (errors.isNotEmpty) return PlannerSaveFailed(DraftInvalid(errors));
    try {
      final id = await planner.writer.runOwnedTransaction(
        () => _write(draft, target),
        alive: () => !_disposed,
      );
      return PlannerSaved(id);
    } on Object catch (e) {
      return PlannerSaveFailed(e);
    }
  }

  Future<String> _write(PlannerDraft draft, DraftTarget target) async {
    switch (target) {
      case NewEntry():
        if (draft.isRepeat) {
          final r = await planner.createRecurrence(
            title: draft.trimmedTitle,
            subjectId: draft.subjectId,
            weekdayMask: Recurrence.maskOf(draft.weekdays),
            startTime: draft.startTime,
            endTime: draft.endTime,
            endsOn: draft.resolvedEndsOn(),
          );
          return r.id;
        }
        final item = await planner.createItem(
          kind: draft.kind,
          title: draft.trimmedTitle,
          date: draft.isPeriod ? draft.bandStart : draft.date,
          subjectId: draft.subjectId,
          rangeText: draft.trimmedRange,
          targetMinutes: draft.hasTarget ? draft.targetMinutes : null,
          bandStart: draft.isPeriod ? draft.bandStart : null,
          bandEnd: draft.isPeriod ? draft.bandEnd : null,
        );
        return item.id;
      case ExistingItem(:final id):
        await planner.updateItem(
          id,
          kind: Value(draft.kind),
          title: Value(draft.trimmedTitle),
          subjectId: Value(draft.subjectId),
          rangeText: Value(draft.trimmedRange),
          targetMinutes: Value(draft.hasTarget ? draft.targetMinutes : null),
          date: Value(draft.date),
        );
        return id;
      case ExistingBand(:final id):
        await planner.updateItem(
          id,
          title: Value(draft.trimmedTitle),
          subjectId: Value(draft.subjectId),
          date: Value(draft.bandStart),
          bandStart: Value(draft.bandStart),
          bandEnd: Value(draft.bandEnd),
        );
        return id;
      case ExistingRecurrence(:final id):
        // Whole-recurrence edit only (PRD 4.2: 전체 수정).
        await planner.updateRecurrence(
          id,
          title: Value(draft.trimmedTitle),
          subjectId: Value(draft.subjectId),
          weekdayMask: Value(Recurrence.maskOf(draft.weekdays)),
          startTime: Value(draft.startTime),
          endTime: Value(draft.endTime),
          endsOn: Value(draft.resolvedEndsOn()),
        );
        return id;
    }
  }

  /// `과목 추가` inside the sheet (8 palette colors). Throws on failure —
  /// the sheet shows the error and keeps the name.
  Future<Subject> addSubject({required String name, required int colorIndex}) async {
    if (_disposed) throw StateError('controller disposed');
    final n = name.trim();
    if (n.isEmpty) throw ArgumentError('name empty');
    return planner.writer.runOwnedTransaction(
      () => subjects.create(name: n, colorIndex: colorIndex % AppSubjectColors.count),
      alive: () => !_disposed,
    );
  }

  Future<void> setDone(String id, {required bool done}) => planner.writer.runOwnedTransaction(
        () => planner.setDone(id, done: done),
        alive: () => !_disposed,
      );

  // ---------------------------------------------------------------------
  // Delete (D22)

  /// Soft-deletes [target] now and commits after [undoWindow] unless undone.
  /// Throws when the soft delete itself fails (nothing changed).
  Future<PendingDelete> delete(DraftTarget target) async {
    if (_disposed) throw StateError('controller disposed');
    final now = planner.ctx.clock.now();
    await planner.writer.runOwnedTransaction(
      () => _softDelete(target),
      alive: () => !_disposed,
    );
    // Commit only after the window elapsed, and only if the entry is still
    // pending (the undo clears `pending_delete_until`). The restart
    // settlement (D22) owns whatever a disposed controller leaves behind.
    late final Timer timer;
    timer = Timer(undoWindow, () async {
      _timers.remove(timer);
      if (_disposed) return;
      try {
        await planner.writer.runOwnedTransaction(
          () => _commitIfDue(target, notBefore: now.add(undoWindow)),
          alive: () => !_disposed,
        );
      } on Object {
        // Left pending: the restart settlement commits it (D22).
      }
    });
    _timers.add(timer);
    return PendingDelete._(target, () async {
      if (_disposed) return false;
      timer.cancel();
      _timers.remove(timer);
      try {
        return await planner.writer.runOwnedTransaction(
          () => _undo(target),
          alive: () => !_disposed,
        );
      } on Object {
        return false;
      }
    });
  }

  Future<void> _softDelete(DraftTarget target) => switch (target) {
        ExistingItem(:final id) || ExistingBand(:final id) => planner.softDeleteItem(id),
        ExistingRecurrence(:final id) => planner.softDeleteRecurrence(id),
        NewEntry() => throw ArgumentError('nothing to delete'),
      };

  Future<void> _commitIfDue(DraftTarget target, {required DateTime notBefore}) async {
    switch (target) {
      case ExistingItem(:final id) || ExistingBand(:final id):
        final row = await planner.getItem(id);
        final until = row?.stamp.pendingDeleteUntil;
        if (until != null && !planner.ctx.clock.now().isBefore(until)) {
          await planner.commitDeleteItem(id);
        }
      case ExistingRecurrence(:final id):
        final row = await planner.getRecurrence(id);
        final until = row?.stamp.pendingDeleteUntil;
        if (until != null && !planner.ctx.clock.now().isBefore(until)) {
          await planner.commitDeleteRecurrence(id);
        }
      case NewEntry():
        break;
    }
  }

  Future<bool> _undo(DraftTarget target) async {
    switch (target) {
      case ExistingItem(:final id) || ExistingBand(:final id):
        final row = await planner.getItem(id);
        if (row == null || row.stamp.pendingDeleteUntil == null) return false;
        await planner.undoDeleteItem(id);
        return true;
      case ExistingRecurrence(:final id):
        final row = await planner.getRecurrence(id);
        if (row == null || row.stamp.pendingDeleteUntil == null) return false;
        await planner.undoDeleteRecurrence(id);
        return true;
      case NewEntry():
        return false;
    }
  }
}

/// `save` refused the draft before writing.
class DraftInvalid implements Exception {
  const DraftInvalid(this.errors);

  final List<DraftError> errors;

  @override
  String toString() => 'DraftInvalid($errors)';
}
