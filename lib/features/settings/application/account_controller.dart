// AccountController (S09 · S09b, PRD 4.3c · D5): 로그아웃 = this device's
// photos are deleted (rows and files), then Auth sign-out; the records stay
// in the account and on this device (the binding wipes them only when a
// different account signs in, [S05]). 계정 삭제 = photos → `delete-account`
// (server data + auth user, sign-out guarded by the account that asked) →
// local database wiped inside an owned transaction.
//
// [S09b] Photo deletion failures are not swallowed: both actions stop with
// `PhotoWipeFailed` (rows stay for a retry) before anything irreversible.
// The controller is built per account (its dependencies are captured at
// build) and refuses to continue for an account that is no longer signed in.

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../data/auth/account_binding.dart';
import '../../../data/auth/auth_backend.dart';
import '../../../data/auth/auth_gate.dart';
import '../../../data/auth/auth_models.dart';
import '../../../data/auth/auth_providers.dart';
import '../../../data/auth/auth_repository.dart';
import '../../../data/db/app_database.dart';
import '../../../data/repositories/repository_providers.dart';
import '../../../data/repositories/sync_writer.dart';
import '../../../data/temp/temp_ownership.dart';
import '../../../data/temp/temp_providers.dart';
import '../../privacy/application/photo_retention.dart';

part 'account_controller.g.dart';

/// The remote account is already deleted. Retrying performs only local work.
class AccountDeleteLocalCleanupFailed implements Exception {
  const AccountDeleteLocalCleanupFailed({
    this.remaining = 0,
    this.unknown = true,
  });
  final int remaining;
  final bool unknown;
  @override
  String toString() => 'AccountDeleteLocalCleanupFailed';
}

class AccountController {
  AccountController({
    required this.userId,
    required this.auth,
    required this.backend,
    required this.photos,
    required this.writer,
    required this.db,
    required this.applyProfile,
    this.temporary,
    AccountBinding? binding,
  }) : binding =
           binding ??
           AccountBinding(db, temporary: temporary, photos: photos.store);

  /// The account this controller acts for.
  final String userId;
  final AuthRepository auth;
  final AuthBackend backend;
  final PhotoRetention photos;
  final SyncWriter writer;
  final AppDatabase db;
  final TempOwnership? temporary;
  final AccountBinding binding;
  bool _serverDeleted = false;
  Future<void>? _deletion;
  Future<void>? _logout;
  bool get serverDeleted => _serverDeleted;

  /// Hands the profile `update-consent` returns to the auth gate.
  final void Function(ProfileSnapshot profile) applyProfile;

  bool _disposed = false;
  void dispose() => _disposed = true;

  bool get _signedInAsOwner => backend.currentSession?.userId == userId;
  bool _alive() => !_disposed && _signedInAsOwner;

  /// Throws [PhotoWipeFailed] when a photo file could not be deleted (rows
  /// and the sweep marker stay; nothing else happens) and [StateError] when
  /// the account changed meanwhile (the wipe stops at that point, [S09c]).
  Future<void> logout() => _logout ??= _performLogout().whenComplete(() {
    _logout = null;
  });

  Future<void> _revokeTemporary() async {
    try {
      final result = await temporary?.revoke(userId);
      if (result != null && !result.complete) {
        throw PhotoWipeFailed(
          result.remaining,
          storeUnavailable: result.unknown,
        );
      }
    } on PhotoWipeFailed {
      rethrow;
    } on Object {
      throw const PhotoWipeFailed(0, storeUnavailable: true);
    }
  }

  Future<void> _performLogout() async {
    _guard();
    temporary?.beginBoundary(userId);
    await _revokeTemporary();
    _guard();
    final result = await photos.wipeAll(alive: _alive);
    _guard();
    if (!result.allDone) {
      throw PhotoWipeFailed(
        result.failedCount,
        storeUnavailable: result.storeUnavailable,
      );
    }
    await auth.signOut();
  }

  /// Photos first (a failure stops before the server call), then
  /// `delete-account`, then the local database — only while it is still
  /// bound to this account (the owned transaction refuses otherwise).
  Future<void> deleteAccount() =>
      _deletion ??= _performDelete().whenComplete(() {
        _deletion = null;
      });

  Future<void> _performDelete() async {
    if (!_serverDeleted) _guard();
    temporary?.beginBoundary(userId);
    _serverDeleted = _serverDeleted || await binding.deletedAccount() == userId;
    if (!_serverDeleted) {
      _guard();
      await _revokeTemporary();
      _guard();
      final result = await photos.wipeAll(alive: _alive);
      _guard();
      if (!result.allDone) {
        throw PhotoWipeFailed(
          result.failedCount,
          storeUnavailable: result.storeUnavailable,
        );
      }
      await auth.deleteAccount(forUserId: userId, signOutAfterDelete: false);
      _serverDeleted = true;
    }
    await retryLocalCleanup();
  }

  Future<void> retryLocalCleanup() async {
    if (!_serverDeleted && await binding.deletedAccount() != userId) {
      throw StateError('account deletion not confirmed');
    }
    _serverDeleted = true;
    try {
      await binding.rememberDeletion(userId);
      await binding.finishDeletion(userId);
      if (_signedInAsOwner) await auth.signOut();
      await binding.clearDeletionReceipt(userId);
    } on AccountLocalCleanupPending catch (error) {
      throw AccountDeleteLocalCleanupFailed(
        remaining: error.remaining,
        unknown: error.unknown,
      );
    } on Object {
      throw const AccountDeleteLocalCleanupFailed();
    }
  }

  /// Consent ② withdrawn (`update-consent`, 원본 §4.2 — only ② can be
  /// revoked); the gate gets the returned profile.
  Future<void> revokeReadingConsent() async {
    _guard();
    final cleanup = await temporary?.cancelPicker(userId);
    _guard();
    if (cleanup != null && !cleanup.complete) {
      throw PhotoWipeFailed(
        cleanup.remaining,
        storeUnavailable: cleanup.unknown,
      );
    }
    final profile = await auth.updateReadingConsent(granted: false);
    _guard();
    applyProfile(profile);
  }

  void _guard() {
    if (_disposed || !_signedInAsOwner) throw StateError('account changed');
  }
}

/// Rebuilt when the account (write context) changes.
@Riverpod(keepAlive: true)
AccountController accountController(Ref ref) {
  final c = AccountController(
    userId: ref.watch(currentUserIdProvider),
    auth: ref.watch(authRepositoryProvider),
    backend: ref.watch(authBackendProvider),
    photos: ref.watch(photoRetentionProvider),
    writer: ref.watch(syncWriterProvider),
    db: ref.watch(appDatabaseProvider),
    temporary: ref.watch(tempOwnershipProvider),
    binding: ref.watch(accountBindingProvider),
    applyProfile: (p) => ref.read(authGateProvider.notifier).applyProfile(p),
  );
  ref.onDispose(c.dispose);
  ref.listen(authGateProvider, (before, after) {
    if (before?.userId != after.userId) c.dispose();
  });
  return c;
}
