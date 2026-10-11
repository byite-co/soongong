// LocalPurge (S09 · S09b · S09c, PRD 4.4 모든 기록 삭제 · D14): removes the
// user's records of the generation before the purge from this device —
// sync tables (sessions · segments · corrections · planner · recurrences ·
// reading requests · wrongs · review · retries · subjects · settings ·
// activity days), their outbox entries, conflicts, the session snapshot and
// the sync cursor. Photo rows are NOT touched here: `PhotoRetention.wipeAll`
// deletes the files and purges only the rows whose file is gone, so a
// failed file keeps its row (account + path) for a retry ([S09b]). Keeps
// what the PRD says stays: the account binding (login) and the subscription
// / quota caches.
//
// Stages ([S09c], `sync_meta`):
//   purge_requested      a `purge-all` call was started; its result is not
//                        known yet (answered by the response, or by the
//                        server profile's `purge_epoch` at the next read)
//   purge_pending_epoch  the server confirmed [epoch]; the local steps
//                        (photos · rows · 기타 · marker) are not finished
//   purge_epoch          the epoch new rows are stamped with (D2)
//   purge_generation     bumped by every stage change; `SyncWriter.
//                        runOwnedTransaction` refuses a write whose caller
//                        started under another generation, and any ordinary
//                        write while a stage is open (the barrier)
//
// `run` is epoch-aware: only rows with `purge_epoch < epoch` go — a row
// written after the server epoch was stored (the resolved recovery
// session, today's activity day) carries the new epoch and survives, the
// same way the server keeps rows pushed under the new epoch.

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../db/app_database.dart';
import 'repository_providers.dart';
import 'write_context.dart';

part 'local_purge.g.dart';

enum PurgeStage {
  /// Nothing in progress.
  none,

  /// `purge-all` was called; the server's answer is unknown.
  requested,

  /// The server purged; local steps remain.
  pending,
}

class PurgeState {
  const PurgeState({
    required this.epoch,
    required this.pendingEpoch,
    required this.requested,
    required this.generation,
  });

  final int epoch;
  final int? pendingEpoch;
  final bool requested;
  final int generation;

  PurgeStage get stage => pendingEpoch != null
      ? PurgeStage.pending
      : requested
          ? PurgeStage.requested
          : PurgeStage.none;

  bool get inProgress => stage != PurgeStage.none;
}

class LocalPurge {
  LocalPurge(this.db, this.ctx);

  final AppDatabase db;
  final WriteContext ctx;

  static const String purgeEpochKey = 'purge_epoch';
  static const String pendingEpochKey = 'purge_pending_epoch';
  static const String requestedKey = 'purge_requested';
  static const String generationKey = 'purge_generation';
  static const String cursorKey = 'cursor_next_seq';

  /// Reads the whole purge state in one go (usable inside a transaction).
  static Future<PurgeState> readState(AppDatabase db) async {
    final rows = await (db.select(db.syncMeta)
          ..where((m) => m.key.isIn(const <String>[purgeEpochKey, pendingEpochKey, requestedKey, generationKey])))
        .get();
    final map = <String, String>{for (final r in rows) r.key: r.value};
    return PurgeState(
      epoch: int.tryParse(map[purgeEpochKey] ?? '') ?? 0,
      pendingEpoch: int.tryParse(map[pendingEpochKey] ?? ''),
      requested: map[requestedKey] != null,
      generation: int.tryParse(map[generationKey] ?? '') ?? 0,
    );
  }

  Future<PurgeState> state() => readState(db);

  /// The epoch of a local purge that has not completed, or null.
  Future<int?> pendingEpoch() async => (await state()).pendingEpoch;

  /// Records that a `purge-all` call is being made (before the call).
  Future<void> markRequested() => db.transaction(() async {
        await _put(requestedKey, '1');
        await _bump();
      });

  /// The server did not purge (its epoch equals ours): nothing to finish.
  Future<void> clearRequested() => db.transaction(() async {
        await (db.delete(db.syncMeta)..where((m) => m.key.equals(requestedKey))).go();
        await _bump();
      });

  /// Stores the server's [epoch] and marks the local purge as pending.
  Future<void> markPending(int epoch) => db.transaction(() async {
        await _put(purgeEpochKey, '$epoch');
        await _put(pendingEpochKey, '$epoch');
        await (db.delete(db.syncMeta)..where((m) => m.key.equals(requestedKey))).go();
        await _bump();
      });

  Future<void> clearPending() => db.transaction(() async {
        await (db.delete(db.syncMeta)..where((m) => m.key.equals(pendingEpochKey))).go();
        await _bump();
      });

  /// Deletes the user's records of the generations before [epoch] (not the
  /// photo rows), their outbox entries, conflicts, the snapshot and the
  /// cursor, and stores [epoch].
  Future<void> run({required int epoch}) => db.transaction(() async {
        for (final t in db.syncTables) {
          final name = t.actualTableName;
          await db.customStatement(
            'DELETE FROM "sync_outbox" WHERE table_name = ? AND row_id IN '
            '(SELECT id FROM "$name" WHERE user_id = ? AND purge_epoch < ?)',
            <Object>[name, ctx.userId, epoch],
          );
          await db.customStatement(
            'DELETE FROM "sync_conflicts" WHERE table_name = ? AND row_id IN '
            '(SELECT id FROM "$name" WHERE user_id = ? AND purge_epoch < ?)',
            <Object>[name, ctx.userId, epoch],
          );
          await db.customStatement(
            'DELETE FROM "$name" WHERE user_id = ? AND purge_epoch < ?',
            <Object>[ctx.userId, epoch],
          );
        }
        await db.delete(db.sessionSnapshots).go();
        await (db.delete(db.syncMeta)..where((m) => m.key.equals(cursorKey))).go();
        await _put(purgeEpochKey, '$epoch');
        await _bump();
      });

  Future<void> _bump() async {
    final row = await (db.select(db.syncMeta)..where((m) => m.key.equals(generationKey))).getSingleOrNull();
    final next = (int.tryParse(row?.value ?? '') ?? 0) + 1;
    await _put(generationKey, '$next');
    db.purgeGate.update(next);
  }

  Future<void> _put(String key, String value) =>
      db.into(db.syncMeta).insertOnConflictUpdate(SyncMetaCompanion.insert(key: key, value: value));
}

/// keepAlive: watched by the keepAlive `privacyActionsProvider`.
@Riverpod(keepAlive: true)
LocalPurge localPurge(Ref ref) => LocalPurge(ref.watch(appDatabaseProvider), ref.watch(writeContextProvider));
