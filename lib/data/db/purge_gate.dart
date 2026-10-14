// PurgeGate (S09c): the in-memory mirror of `sync_meta.purge_generation`,
// shared by everything that uses one database. A controller reads
// [generation] synchronously when an action starts and hands it to
// `SyncWriter.runOwnedTransaction`, which compares it with the stored value
// once it holds the database lock — a write that was queued before 모든
// 기록 삭제 ran is refused instead of re-creating the deleted rows under
// the new epoch. null = not read yet in this process (no comparison; the
// first owned write and the startup tasks fill it from the database).

class PurgeGate {
  int? _generation;

  /// The last `purge_generation` this process read or wrote, or null.
  int? get generation => _generation;

  void update(int value) => _generation = value;
}
