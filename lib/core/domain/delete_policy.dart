// DeletePolicy (S02, pure Dart, D22): 5-second undo.
//   softDelete → pending_delete_until = now + 5 s (no outbox)
//   undoDelete → pending_delete_until = null
//   commitDelete (after the window) → deleted_at + outbox
// On app start [settle] commits the expired ones and restores the rest
// (no toast is shown again). Confirmed deletes (account · all records ·
// saved reading results) bypass the window and commit immediately.

class PendingDelete {
  const PendingDelete({
    required this.table,
    required this.id,
    required this.pendingDeleteUntil,
  });

  final String table;
  final String id;
  final DateTime pendingDeleteUntil;
}

class DeleteSettlement {
  const DeleteSettlement({required this.toCommit, required this.toRestore});

  final List<PendingDelete> toCommit;
  final List<PendingDelete> toRestore;
}

class DeletePolicy {
  const DeletePolicy();

  static const Duration undoWindow = Duration(seconds: 5);

  /// Tables that support the undo window.
  static const Set<String> tables = <String>{
    'subjects',
    'sessions',
    'planner_items',
    'recurrences',
  };

  DateTime deadline(DateTime now) => now.add(undoWindow);

  bool isExpired(DateTime pendingDeleteUntil, DateTime now) =>
      !now.isBefore(pendingDeleteUntil);

  DeleteSettlement settle(Iterable<PendingDelete> pending, DateTime now) {
    final commit = <PendingDelete>[];
    final restore = <PendingDelete>[];
    for (final p in pending) {
      (isExpired(p.pendingDeleteUntil, now) ? commit : restore).add(p);
    }
    return DeleteSettlement(toCommit: commit, toRestore: restore);
  }
}
