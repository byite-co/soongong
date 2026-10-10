// AccountController (S09, PRD 4.3c · D5): 로그아웃 = this device's photos
// are deleted (rows and files), then Auth sign-out; the records stay in the
// account and on this device (the binding wipes them only when a different
// account signs in, [S05]). 계정 삭제 = `delete-account` (server data + auth
// user) → photos → local database wiped. Both end at the gate through the
// auth state stream — screens never navigate themselves.

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../data/auth/auth_providers.dart';
import '../../../data/repositories/repository_providers.dart';
import '../../privacy/application/photo_retention.dart';

part 'account_controller.g.dart';

class AccountController {
  AccountController(this._ref);

  final Ref _ref;

  /// Throws when sign-out fails (the modal shows the error and keeps the
  /// user signed in).
  Future<void> logout() async {
    await _ref.read(photoRetentionProvider).wipeAll();
    await _ref.read(authRepositoryProvider).signOut();
  }

  Future<void> deleteAccount() async {
    await _ref.read(authRepositoryProvider).deleteAccount();
    await _ref.read(photoRetentionProvider).wipeAll();
    await _ref.read(appDatabaseProvider).wipeAll();
  }
}

/// keepAlive: the controller is used across async gaps from modals.
@Riverpod(keepAlive: true)
AccountController accountController(Ref ref) => AccountController(ref);
