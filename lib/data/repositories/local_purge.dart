// LocalPurge (S09 · S09b, PRD 4.4 모든 기록 삭제 · D14): removes every record
// of the user from this device after the server `purge-all` — sync tables
// (sessions · segments · corrections · planner · recurrences · reading
// requests · wrongs · review · retries · subjects · settings · activity
// days), the outbox, conflicts, the session snapshot and the sync cursor.
// Photo rows are NOT touched here: `PhotoRetention.wipeAll` deletes the
// files and purges only the rows whose file is gone, so a failed file keeps
// its row (account + path) for a retry ([S09b]). Keeps what the PRD says
// stays: the account binding (login) and the subscription / quota caches.
//
// Epoch contract (D2): the server's new epoch is stored FIRST, together
// with a pending marker, in `markPending`; `run` deletes the rows and
// `clearPending` closes the marker. A marker left behind (app killed, a
// measurement that started meanwhile) is completed by
// `PrivacyActions.completePending` at the next start — the old rows are
// never pushed under the new epoch.

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../db/app_database.dart';
import 'repository_providers.dart';
import 'write_context.dart';

part 'local_purge.g.dart';

class LocalPurge {
  LocalPurge(this.db, this.ctx);

  final AppDatabase db;
  final WriteContext ctx;

  static const String purgeEpochKey = 'purge_epoch';
  static const String pendingEpochKey = 'purge_pending_epoch';
  static const String cursorKey = 'cursor_next_seq';

  /// Stores the server's [epoch] and marks the local purge as pending.
  Future<void> markPending(int epoch) => db.transaction(() async {
        await _put(purgeEpochKey, '$epoch');
        await _put(pendingEpochKey, '$epoch');
      });

  /// The epoch of a local purge that has not completed, or null.
  Future<int?> pendingEpoch() async {
    final row = await (db.select(db.syncMeta)..where((m) => m.key.equals(pendingEpochKey))).getSingleOrNull();
    return row == null ? null : int.tryParse(row.value);
  }

  Future<void> clearPending() => (db.delete(db.syncMeta)..where((m) => m.key.equals(pendingEpochKey))).go();

  /// Deletes the user's records (not the photo rows) and stores [epoch].
  Future<void> run({required int epoch}) => db.transaction(() async {
        for (final t in db.syncTables) {
          await db.customStatement(
            'DELETE FROM "${t.actualTableName}" WHERE user_id = ?',
            <Object>[ctx.userId],
          );
        }
        await db.delete(db.syncOutbox).go();
        await db.delete(db.syncConflicts).go();
        await db.delete(db.sessionSnapshots).go();
        await (db.delete(db.syncMeta)..where((m) => m.key.equals(cursorKey))).go();
        await _put(purgeEpochKey, '$epoch');
      });

  Future<void> _put(String key, String value) =>
      db.into(db.syncMeta).insertOnConflictUpdate(SyncMetaCompanion.insert(key: key, value: value));
}

/// keepAlive: watched by the keepAlive `privacyActionsProvider`.
@Riverpod(keepAlive: true)
LocalPurge localPurge(Ref ref) => LocalPurge(ref.watch(appDatabaseProvider), ref.watch(writeContextProvider));
