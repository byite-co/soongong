// AccountBinding (S05 · D27): the local database belongs to one account.
// `sync_meta.account_user_id` remembers whose rows are inside; a different
// user signing in on this device wipes everything first (`wipeAll()`), so no
// row of user A is ever read, edited or pushed as user B.

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../core/logging/app_logger.dart';
import '../db/app_database.dart';
import '../repositories/repository_providers.dart';
import '../repositories/sync_writer.dart';

part 'account_binding.g.dart';

class AccountBinding {
  AccountBinding(this._db);

  final AppDatabase _db;

  static const String key = SyncWriter.accountUserIdKey;

  Future<String?> current() async {
    final row = await (_db.select(_db.syncMeta)..where((m) => m.key.equals(key))).getSingleOrNull();
    return row?.value;
  }

  /// Binds the database to [userId]. Returns true when a wipe happened.
  Future<bool> bind(String userId) async {
    final previous = await current();
    var wiped = false;
    if (previous != null && previous != userId) {
      await _db.wipeAll();
      wiped = true;
      appLog.i('account: switched → local database wiped');
    }
    if (previous != userId) {
      await _db.into(_db.syncMeta).insertOnConflictUpdate(
            SyncMetaCompanion.insert(key: key, value: userId),
          );
    }
    return wiped;
  }

  /// Sign-out keeps the rows (PRD 4.3c: 기록은 계정에 남음) but the binding
  /// stays so the next sign-in of a different account wipes them.
}

@Riverpod(keepAlive: true)
AccountBinding accountBinding(Ref ref) => AccountBinding(ref.watch(appDatabaseProvider));
