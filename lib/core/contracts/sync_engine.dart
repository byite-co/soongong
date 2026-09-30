// SyncEngine contract (S01). Signatures are frozen — changes require the
// CONTRACT-CHANGE procedure (CLAUDE.md §8). Sync rules: D2.

sealed class SyncState {
  const SyncState();
}

class SyncIdle extends SyncState {
  const SyncIdle();
}

class SyncSyncing extends SyncState {
  const SyncSyncing(this.pending);

  /// Outbox rows still to push.
  final int pending;
}

class SyncOffline extends SyncState {
  const SyncOffline();
}

class SyncError extends SyncState {
  const SyncError(this.message);

  final String message;
}

class SyncFullResyncRequired extends SyncState {
  const SyncFullResyncRequired();
}

abstract class SyncEngine {
  /// outbox → `sync_push` RPC (D2 CAS · receipts).
  Future<void> pushPending();

  /// null = stored cursor, 0 = from the beginning. No overlap, cursor is
  /// monotonic.
  Future<void> pull({int? sinceSeq});

  /// D2 procedure, 3 steps.
  Future<void> fullResync();

  Stream<SyncState> get state;

  DateTime? get lastSyncedAt;
}
