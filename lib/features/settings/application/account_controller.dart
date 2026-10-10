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

import '../../../data/auth/auth_backend.dart';
import '../../../data/auth/auth_gate.dart';
import '../../../data/auth/auth_models.dart';
import '../../../data/auth/auth_providers.dart';
import '../../../data/auth/auth_repository.dart';
import '../../../data/db/app_database.dart';
import '../../../data/repositories/repository_providers.dart';
import '../../../data/repositories/sync_writer.dart';
import '../../privacy/application/photo_retention.dart';

part 'account_controller.g.dart';

class AccountController {
  AccountController({
    required this.userId,
    required this.auth,
    required this.backend,
    required this.photos,
    required this.writer,
    required this.db,
    required this.applyProfile,
  });

  /// The account this controller acts for.
  final String userId;
  final AuthRepository auth;
  final AuthBackend backend;
  final PhotoRetention photos;
  final SyncWriter writer;
  final AppDatabase db;

  /// Hands the profile `update-consent` returns to the auth gate.
  final void Function(ProfileSnapshot profile) applyProfile;

  bool _disposed = false;
  void dispose() => _disposed = true;

  bool get _signedInAsOwner => backend.currentSession?.userId == userId;

  /// Throws [PhotoWipeFailed] when a photo could not be deleted (nothing
  /// else happens) and [StateError] when the account changed meanwhile.
  Future<void> logout() async {
    _guard();
    final result = await photos.wipeAll();
    if (result.failed.isNotEmpty) throw PhotoWipeFailed(result.failed.length);
    _guard();
    await auth.signOut();
  }

  /// Photos first (a failure stops before the server call), then
  /// `delete-account`, then the local database — only while it is still
  /// bound to this account (the owned transaction refuses otherwise).
  Future<void> deleteAccount() async {
    _guard();
    final result = await photos.wipeAll();
    if (result.failed.isNotEmpty) throw PhotoWipeFailed(result.failed.length);
    _guard();
    await auth.deleteAccount(forUserId: userId);
    try {
      await writer.runOwnedTransaction(db.wipeAll);
    } on StateError {
      // Another account is bound to the database by now: its data is not
      // ours to wipe; the server-side deletion already succeeded.
    }
  }

  /// Consent ② withdrawn (`update-consent`, 원본 §4.2 — only ② can be
  /// revoked); the gate gets the returned profile.
  Future<void> revokeReadingConsent() async {
    _guard();
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
    applyProfile: (p) => ref.read(authGateProvider.notifier).applyProfile(p),
  );
  ref.onDispose(c.dispose);
  return c;
}
