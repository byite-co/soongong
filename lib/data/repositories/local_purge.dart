// LocalPurge (S09, PRD 4.4 모든 기록 삭제 · D14): removes every record of the
// user from this device after the server `purge-all` — sync tables (sessions
// · segments · corrections · planner · recurrences · reading requests ·
// wrongs · review · retries · subjects · settings · activity days), the
// outbox, conflicts, the session snapshot and the photo rows (files go
// through `PhotoRetention` first). Keeps what the PRD says stays: the
// account binding (login) and the subscription / quota caches. Stores the
// server's new epoch so the next sync starts clean (D2).

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
  static const String cursorKey = 'cursor_next_seq';

  Future<void> run({required int epoch}) => db.transaction(() async {
        for (final t in db.syncTables) {
          await db.customStatement(
            'DELETE FROM "${t.actualTableName}" WHERE user_id = ?',
            <Object>[ctx.userId],
          );
        }
        await (db.delete(db.photos)..where((p) => p.userId.equals(ctx.userId))).go();
        await db.delete(db.syncOutbox).go();
        await db.delete(db.syncConflicts).go();
        await db.delete(db.sessionSnapshots).go();
        await (db.delete(db.syncMeta)..where((m) => m.key.equals(cursorKey))).go();
        await db.into(db.syncMeta).insertOnConflictUpdate(
              SyncMetaCompanion.insert(key: purgeEpochKey, value: '$epoch'),
            );
      });
}

@riverpod
LocalPurge localPurge(Ref ref) => LocalPurge(ref.watch(appDatabaseProvider), ref.watch(writeContextProvider));
