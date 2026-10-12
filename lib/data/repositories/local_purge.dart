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
//   purge_requested      the client request id of a `purge-all` call that
//                        was started; its result is not known yet (answered
//                        by the response, by the server profile's
//                        `purge_request_id` / `purge_epoch`, or by re-sending
//                        the same id — the server replays it, [S09e])
//   purge_requested_at   when that call was started (UTC) — informational;
//                        time is never evidence about the server ([S09e])
//   purge_expected_epoch the server epoch the request was formed against
//                        (read from the profile right before the call); sent
//                        with every (re)send so a request older than a later
//                        purge is superseded, not executed ([S09e])
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
    required this.requestId,
    required this.requestedAt,
    required this.expectedEpoch,
    required this.generation,
  });

  final int epoch;
  final int? pendingEpoch;

  /// The open `purge-all` request id, or null.
  final String? requestId;
  final DateTime? requestedAt;

  /// The server epoch the open request was formed against ([S09e]); null for
  /// a request stored before S09e.
  final int? expectedEpoch;
  final int generation;

  bool get requested => requestId != null;

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
  static const String requestedAtKey = 'purge_requested_at';
  static const String expectedEpochKey = 'purge_expected_epoch';
  static const String generationKey = 'purge_generation';
  static const String cursorKey = 'cursor_next_seq';

  /// Reads the whole purge state in one go (usable inside a transaction).
  static Future<PurgeState> readState(AppDatabase db) async {
    final rows = await (db.select(db.syncMeta)
          ..where((m) => m.key.isIn(const <String>[purgeEpochKey, pendingEpochKey, requestedKey, requestedAtKey, expectedEpochKey, generationKey])))
        .get();
    final map = <String, String>{for (final r in rows) r.key: r.value};
    final requestedAt = map[requestedAtKey];
    return PurgeState(
      epoch: int.tryParse(map[purgeEpochKey] ?? '') ?? 0,
      pendingEpoch: int.tryParse(map[pendingEpochKey] ?? ''),
      requestId: map[requestedKey],
      requestedAt: requestedAt == null ? null : DateTime.tryParse(requestedAt)?.toUtc(),
      expectedEpoch: int.tryParse(map[expectedEpochKey] ?? ''),
      generation: int.tryParse(map[generationKey] ?? '') ?? 0,
    );
  }

  Future<PurgeState> state() => readState(db);

  /// The epoch of a local purge that has not completed, or null.
  Future<int?> pendingEpoch() async => (await state()).pendingEpoch;

  /// Records that a `purge-all` call with [requestId] is being made (before
  /// the call), formed against the server's [expectedEpoch]. Re-marking the
  /// same id (a resend) only refreshes the time.
  Future<void> markRequested(String requestId, {int? expectedEpoch}) => db.transaction(() async {
        await _put(requestedKey, requestId);
        await _put(requestedAtKey, ctx.nowUtc().toIso8601String());
        if (expectedEpoch == null) {
          await (db.delete(db.syncMeta)..where((m) => m.key.equals(expectedEpochKey))).go();
        } else {
          await _put(expectedEpochKey, '$expectedEpoch');
        }
        await _bump();
      });

  /// The server confirmed it never served the request (or refused it):
  /// nothing to finish.
  Future<void> clearRequested() => db.transaction(() async {
        await _clearRequest();
        await _bump();
      });

  /// Stores the server's [epoch] and marks the local purge as pending. The
  /// stored epoch never moves backwards ([S09e]: a replayed answer carries
  /// the account's current epoch; an older one is never applied) — the
  /// epoch actually stored is returned and is the one the local steps use.
  Future<int> markPending(int epoch) => db.transaction(() async {
        final current = (await state()).epoch;
        final target = epoch > current ? epoch : current;
        await _put(purgeEpochKey, '$target');
        await _put(pendingEpochKey, '$target');
        await _clearRequest();
        await _bump();
        return target;
      });

  Future<void> _clearRequest() =>
      (db.delete(db.syncMeta)..where((m) => m.key.isIn(const <String>[requestedKey, requestedAtKey, expectedEpochKey]))).go();

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
        await db.customStatement('DELETE FROM study_documents WHERE user_id=? AND purge_epoch < ?', [ctx.userId, epoch]);
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
