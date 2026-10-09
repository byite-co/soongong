// PasswordRecovery (S05b): true from the moment the Supabase SDK exchanged a
// `soongong://auth/reset` link for a session (`passwordRecovery` auth event)
// until the new password is saved or the user leaves the flow. The router
// guard sends every location to `/auth/reset` while it is true.
//
// The SDK's deep-link observer (`detectSessionInUri`, app_links) is the ONLY
// handler of that link: Flutter's own deep-link routing is switched off on
// both platforms (`flutter_deeplinking_enabled` / `FlutterDeepLinkingEnabled`
// = false), so the code exchange never runs twice and go_router never sees
// the raw link.

import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../core/logging/app_logger.dart';
import 'auth_mode.dart';
import 'auth_models.dart';
import 'auth_providers.dart';

part 'password_recovery.g.dart';

@Riverpod(keepAlive: true)
class PasswordRecovery extends _$PasswordRecovery {
  StreamSubscription<void>? _sub;
  StreamSubscription<AuthSession?>? _sessions;

  @override
  bool build() {
    if (ref.watch(authModeProvider) != AuthMode.backend) return false;
    final repo = ref.watch(authRepositoryProvider);
    _sub = repo.passwordRecovery.listen((_) {
      appLog.i('auth: password recovery link exchanged → /auth/reset');
      state = true;
    });
    _sessions = repo.authState.listen((s) {
      if (s == null) state = false;
    });
    ref.onDispose(() {
      _sub?.cancel();
      _sessions?.cancel();
    });
    return false;
  }

  /// New password saved, or the user asked for a new mail instead.
  void clear() => state = false;
}
