// AuthGate (S05): the one place that answers "who is signed in and how far
// did they get" for the router guard and `currentUserIdProvider`.
//
//   loading      → session restored, own profile being read
//   localOnly    → dev build without backend config (S01–S02 workflow)
//   signedOut    → `/gate` (age gate first; existing accounts via `/login`)
//   signedIn     → profile null = consent ① pending (`/signup/complete`),
//                  onboarding_done false = `/onboarding/1`, else the app
//   profileError → the profile row could not be read (offline); retry on `/`
//
// Before a user is reported as signed in the local database is bound to
// that account (`AccountBinding`, wipe on switch — D27).

import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../core/logging/app_logger.dart';
import 'account_binding.dart';
import 'auth_mode.dart';
import 'auth_models.dart';
import 'auth_providers.dart';

part 'auth_gate.g.dart';

sealed class AuthGateState {
  const AuthGateState();

  /// A user id the repositories may write under.
  String? get userId => null;

  bool get hasUser => userId != null;
}

class AuthGateLoading extends AuthGateState {
  const AuthGateLoading();
}

class AuthGateLocalOnly extends AuthGateState {
  const AuthGateLocalOnly();

  @override
  String? get userId => kLocalOnlyUserId;
}

class AuthGateSignedOut extends AuthGateState {
  const AuthGateSignedOut();
}

class AuthGateSignedIn extends AuthGateState {
  const AuthGateSignedIn({required this.userId, required this.profile});

  @override
  final String userId;

  /// null = no `profiles` row yet → consent ① / `complete-signup` pending.
  final ProfileSnapshot? profile;

  bool get needsSignupCompletion => profile == null;

  bool get needsOnboarding => profile != null && !profile!.onboardingDone;

  bool get ready => profile != null && profile!.onboardingDone;
}

class AuthGateProfileError extends AuthGateState {
  const AuthGateProfileError({required this.userId, required this.reason});

  @override
  final String userId;
  final AuthRejection reason;
}

/// User id of the dev build that runs without a backend (was S02's `'local'`).
const String kLocalOnlyUserId = 'local';

@Riverpod(keepAlive: true)
class AuthGate extends _$AuthGate {
  StreamSubscription<AuthSession?>? _sub;
  int _generation = 0;

  /// Set by the login screens around a sign-in call so the session event
  /// does not trigger a second profile read; [applySignIn] resolves instead.
  bool _loginInProgress = false;

  @override
  AuthGateState build() {
    switch (ref.watch(authModeProvider)) {
      case AuthMode.localOnly:
        // Dev without config keeps the offline-first app usable (fakes + local DB).
        return const AuthGateLocalOnly();
      case AuthMode.misconfigured:
        // Prod without config is a build error; nothing can sign in.
        return const AuthGateSignedOut();
      case AuthMode.backend:
        break;
    }
    final repo = ref.watch(authRepositoryProvider);
    _sub = repo.authState.listen(_onSession);
    ref.onDispose(() => _sub?.cancel());
    final session = repo.currentSession;
    if (session == null) return const AuthGateSignedOut();
    unawaited(_resolve(session.userId));
    return const AuthGateLoading();
  }

  void _onSession(AuthSession? session) {
    if (session == null) {
      _generation++;
      state = const AuthGateSignedOut();
      return;
    }
    final current = state;
    if (current.userId == session.userId && current is! AuthGateProfileError) {
      // Token refresh / duplicate event for the same user: nothing changes.
      return;
    }
    state = const AuthGateLoading();
    if (_loginInProgress) return; // the login flow hands over its result
    unawaited(_resolve(session.userId));
  }

  /// Login flow about to call the backend (see [_loginInProgress]).
  void beginLogin() => _loginInProgress = true;

  /// Login flow ended without a session (rejected / cancelled).
  void endLogin() {
    _loginInProgress = false;
    if (state is AuthGateLoading) {
      final session = ref.read(authRepositoryProvider).currentSession;
      if (session == null) {
        state = const AuthGateSignedOut();
      } else {
        unawaited(_resolve(session.userId));
      }
    }
  }

  Future<void> _resolve(String userId, {ProfileSnapshot? known, bool profileLoaded = false}) async {
    final gen = ++_generation;
    try {
      await ref.read(accountBindingProvider).bind(userId);
      final profile = profileLoaded ? known : await ref.read(authRepositoryProvider).fetchProfile();
      if (gen != _generation) return;
      state = AuthGateSignedIn(userId: userId, profile: profile);
    } on Object catch (e) {
      if (gen != _generation) return;
      final reason = AuthRejectionMapper.fromError(e);
      appLog.w('auth gate: profile read failed (${reason.name})');
      state = AuthGateProfileError(userId: userId, reason: reason);
    }
  }

  /// Login screens hand over their [SignedIn] result so the guard does not
  /// wait for the session stream (and does not read the profile twice).
  Future<void> applySignIn(SignedIn outcome) {
    _loginInProgress = false;
    return _resolve(outcome.userId, known: outcome.profile, profileLoaded: outcome.profileLoaded);
  }

  /// After `complete-signup` / `update-consent` / `profile_set_onboarding_done`.
  void applyProfile(ProfileSnapshot profile) {
    final current = state;
    if (current is AuthGateSignedIn && current.userId == profile.userId) {
      state = AuthGateSignedIn(userId: profile.userId, profile: profile);
    } else if (current.userId == profile.userId || current is AuthGateLoading) {
      state = AuthGateSignedIn(userId: profile.userId, profile: profile);
    }
  }

  /// Re-reads the profile (launch screen retry).
  Future<void> retry() async {
    final session = ref.read(authRepositoryProvider).currentSession;
    if (session == null) {
      state = const AuthGateSignedOut();
      return;
    }
    state = const AuthGateLoading();
    await _resolve(session.userId);
  }
}
