// AccountBinding (S05 · D27): the local database belongs to one account.
// `sync_meta.account_user_id` remembers whose rows are inside; a different
// user signing in on this device wipes everything first (`wipeAll()`), so no
// row of user A is ever read, edited or pushed as user B.

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../core/logging/app_logger.dart';
import '../db/app_database.dart';
import '../photos/photo_store.dart';
import '../repositories/reading_repository.dart';
import '../repositories/repository_providers.dart';
import '../repositories/sync_writer.dart';
import '../temp/temp_ownership.dart';
import '../temp/temp_providers.dart';

part 'account_binding.g.dart';

class AccountLocalCleanupPending implements Exception {
  const AccountLocalCleanupPending({this.remaining = 0, this.unknown = false});
  final int remaining;
  final bool unknown;
  @override
  String toString() => 'AccountLocalCleanupPending';
}

class AccountDeletedLocally implements Exception {
  const AccountDeletedLocally();
}

class AccountBinding {
  AccountBinding(this._db, {this.temporary, this.photos});

  final AppDatabase _db;
  final TempOwnership? temporary;
  final PhotoStore? photos;
  Future<void> _tail = Future<void>.value();

  static const String key = SyncWriter.accountUserIdKey;
  static const String deletedAccountKey = 'confirmed_account_deletion_v1';

  Future<String?> current() async {
    final row = await (_db.select(
      _db.syncMeta,
    )..where((m) => m.key.equals(key))).getSingleOrNull();
    return row?.value;
  }

  Future<String?> deletedAccount() async => (await (_db.select(
    _db.syncMeta,
  )..where((m) => m.key.equals(deletedAccountKey))).getSingleOrNull())?.value;

  /// Called only after the server acknowledged deletion. Never overwrites B's
  /// binding or receipt when A's remote response arrives late.
  Future<void> rememberDeletion(String userId) => _db.transaction(() async {
    final bound = await current();
    if (bound != null && bound != userId) return;
    await _db
        .into(_db.syncMeta)
        .insertOnConflictUpdate(
          SyncMetaCompanion.insert(key: deletedAccountKey, value: userId),
        );
  });

  /// A failed SDK sign-out must not allow a restored deleted session to bind.
  /// Clear only after local cleanup and an auth transition have both completed.
  Future<void> clearDeletionReceipt(String userId) => _db.transaction(() async {
    if (await current() != null || await deletedAccount() != userId) return;
    await (_db.delete(
      _db.syncMeta,
    )..where((m) => m.key.equals(deletedAccountKey))).go();
  });

  Future<void> _finishDeletion(String userId, {bool Function()? alive}) =>
      _db.transaction(() async {
        void guard() {
          if (alive != null && !alive()) {
            throw StateError('account cleanup cancelled');
          }
        }

        guard();
        final bound = await current();
        if (bound != null && bound != userId) return;
        final result = await temporary?.revoke(userId);
        if (result != null && !result.complete) {
          throw AccountLocalCleanupPending(
            remaining: result.remaining,
            unknown: result.unknown,
          );
        }
        final sweep = await temporary?.store.sweep();
        if (sweep != null && !sweep.complete) {
          throw AccountLocalCleanupPending(
            remaining: sweep.remaining,
            unknown: sweep.unknown,
          );
        }
        guard();
        if (photos != null) {
          final result = await photos!.sweep(proceed: alive);
          if (!result.clean) {
            throw AccountLocalCleanupPending(
              remaining: result.left.length,
              unknown: !result.complete,
            );
          }
        }
        guard();
        await _db.wipeAll();
        await _db
            .into(_db.syncMeta)
            .insertOnConflictUpdate(
              SyncMetaCompanion.insert(key: deletedAccountKey, value: userId),
            );
        guard();
      });

  Future<void> finishDeletion(String userId) {
    final operation = _tail.then((_) => _finishDeletion(userId));
    _tail = operation.then<void>((_) {}, onError: (Object _, StackTrace __) {});
    return operation;
  }

  /// Binds the database to [userId]. Returns true when a wipe happened.
  Future<bool> bind(String userId, {bool Function()? alive}) {
    void guard() {
      if (alive != null && !alive()) {
        throw StateError('account binding cancelled');
      }
    }

    final operation = _tail.then((_) async {
      guard();
      final deleted = await deletedAccount();
      if (deleted != null) {
        await _finishDeletion(deleted, alive: alive);
        guard();
        // Cleanup commits before refusing the deleted account's old session.
        if (deleted == userId) throw const AccountDeletedLocally();
      }
      return _db.transaction(() async {
        guard();
        final previous = await current();
        guard();
        var wiped = false;
        var photoSweepPending = false;
        if (previous != null && previous != userId) {
          // Record the old scope's obligation before wiping its encrypted map.
          // Cleanup may be incomplete; a failed durable marker blocks the wipe.
          await temporary?.revoke(previous);
          guard();
          if (photos != null) {
            try {
              photoSweepPending = !(await photos!.sweep(proceed: alive)).clean;
            } on Object {
              photoSweepPending = true;
            }
          }
          guard();
          // Holding this transaction until the old global photo sweep finishes
          // prevents a newer account from binding/creating files underneath it.
          await _db.wipeAll();
          guard();
          wiped = true;
          appLog.i('account: switched → local database wiped');
        }
        if (previous != userId) {
          if (deleted != null && deleted != userId) {
            await (_db.delete(
              _db.syncMeta,
            )..where((m) => m.key.equals(deletedAccountKey))).go();
          }
          await _db
              .into(_db.syncMeta)
              .insertOnConflictUpdate(
                SyncMetaCompanion.insert(key: key, value: userId),
              );
        }
        if (photoSweepPending) {
          await _db
              .into(_db.syncMeta)
              .insertOnConflictUpdate(
                SyncMetaCompanion.insert(
                  key: ReadingRepository.photoSweepPendingKey,
                  value: userId,
                ),
              );
        }
        guard();
        return wiped;
      });
    });
    _tail = operation.then<void>((_) {}, onError: (Object _, StackTrace __) {});
    return operation;
  }

  /// Sign-out keeps the rows (PRD 4.3c: 기록은 계정에 남음) but the binding
  /// stays so the next sign-in of a different account wipes them.
}

@Riverpod(keepAlive: true)
AccountBinding accountBinding(Ref ref) => AccountBinding(
  ref.watch(appDatabaseProvider),
  temporary: ref.watch(tempOwnershipProvider),
  photos: ref.watch(photoStoreProvider),
);
