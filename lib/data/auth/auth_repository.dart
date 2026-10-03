// AuthRepository (S03 · PRD 4.3c · D6). Provider flows, email flows, sign-out,
// account deletion, onboarding flag, consent ②, auth state. Screens: S05.
//
// Signup order (per provider): birth date → `age-check` ticket → native token
// → `issue-pass` → `signInWithIdToken` (`signUp` for email) → `complete-signup`.
// An existing user signs in without a ticket; if the hook rejects the sign-in
// with [AuthRejection.signupPassRequired] the account is new → S05 runs the
// age gate and calls the same method again with the ticket.

import 'dart:async';

import '../../core/logging/app_logger.dart';
import 'age_gate_repository.dart';
import 'auth_backend.dart';
import 'auth_models.dart';

class AuthRepository {
  AuthRepository(this._backend, this._ageGate, {required this.checkEmailAppKey});

  final AuthBackend _backend;
  final AgeGateRepository _ageGate;

  /// `x-app-key` for `check-email` (public app key from `env/app.<flavor>.json`).
  final String checkEmailAppKey;

  // ---------------------------------------------------------------------
  // State

  String? get currentUserId => _backend.currentSession?.userId;

  AuthSession? get currentSession => _backend.currentSession;

  /// Session changes (null = signed out). S05 router guard listens here.
  Stream<AuthSession?> get authState => _backend.sessions;

  // ---------------------------------------------------------------------
  // Email

  /// Pre-login existence check (`check-email`), for 기존/신규 자동 판별.
  Future<bool> checkEmailExists(String email) async {
    final res = await _backend.invoke(
      'check-email',
      body: <String, dynamic>{'email': email.trim()},
      headers: <String, String>{'x-app-key': checkEmailAppKey},
      withUser: false,
    );
    return res['exists'] == true;
  }

  /// New email account: `issue-pass` (ticket + email) → `signUp` → `complete-signup`.
  Future<SignInOutcome> signUpWithEmail({
    required String ticket,
    required String email,
    required String password,
  }) async {
    final pass = await _ageGate.issuePass(ticket: ticket, provider: SignupProvider.email, email: email);
    if (pass is PassFailed) return SignInRejected(pass.reason);
    return _run(() async {
      final session = await _backend.signUpWithEmail(email: email.trim(), password: password);
      return _completeSignup(session, isNewUser: true);
    });
  }

  Future<SignInOutcome> signInWithEmail({required String email, required String password}) =>
      _run(() async {
        final session = await _backend.signInWithPassword(email: email.trim(), password: password);
        return _completeSignup(session, isNewUser: false);
      });

  Future<void> sendPasswordReset(String email) => _backend.resetPasswordForEmail(email.trim());

  // ---------------------------------------------------------------------
  // Social (Apple · Google · Kakao)

  /// [ticket] == null → sign-in attempt for an existing account. A hook
  /// rejection ([AuthRejection.signupPassRequired]) means the account is new:
  /// run the age gate, then call again with the ticket → `issue-pass` first.
  Future<SignInOutcome> signInWithProvider({
    required SignupProvider provider,
    required String idToken,
    String? accessToken,
    String? nonce,
    String? ticket,
  }) async {
    assert(provider != SignupProvider.email);
    if (ticket != null) {
      final pass = await _ageGate.issuePass(
        ticket: ticket,
        provider: provider,
        idToken: idToken,
        nonce: nonce,
      );
      if (pass is PassFailed) return SignInRejected(pass.reason);
    }
    return _run(() async {
      final session = await _backend.signInWithIdToken(
        provider: provider,
        idToken: idToken,
        accessToken: accessToken,
        nonce: nonce,
      );
      return _completeSignup(session, isNewUser: ticket != null);
    });
  }

  // ---------------------------------------------------------------------
  // Profile · consent · onboarding

  /// `complete-signup` (idempotent). Also used after a plain sign-in so an
  /// account whose first `complete-signup` was lost still gets its profile.
  Future<ProfileSnapshot> completeSignup({String consentVersion = ConsentVersions.account}) async {
    final res = await _backend.invoke(
      'complete-signup',
      body: <String, dynamic>{'consent_version': consentVersion},
    );
    return ProfileSnapshot.fromJson(Map<String, dynamic>.from(res['profile'] as Map));
  }

  /// Consent ② — external reading transfer (`update-consent`).
  Future<ProfileSnapshot> updateReadingConsent({
    required bool granted,
    String consentVersion = ConsentVersions.reading,
  }) async {
    final res = await _backend.invoke(
      'update-consent',
      body: <String, dynamic>{
        'granted': granted,
        if (granted) 'consent_version': consentVersion,
      },
    );
    return ProfileSnapshot.fromJson(Map<String, dynamic>.from(res['profile'] as Map));
  }

  /// `profile_set_onboarding_done()` RPC (D24).
  Future<void> setOnboardingDone() => _backend.rpc('profile_set_onboarding_done', const <String, dynamic>{});

  // ---------------------------------------------------------------------
  // Sign out · delete

  Future<void> signOut() => _backend.signOut();

  /// `delete-account` (server data + auth user) then local sign-out. The
  /// caller wipes the local DB and photo files (D5 · D27).
  Future<void> deleteAccount() async {
    await _backend.invoke('delete-account');
    try {
      await _backend.signOut();
    } on Object catch (_) {
      // The auth user is already gone; a failing sign-out only means the
      // local session could not be cleared through Auth. S05 wipes local state.
    }
  }

  // ---------------------------------------------------------------------

  Future<SignInOutcome> _completeSignup(AuthSession session, {required bool isNewUser}) async {
    try {
      final profile = await completeSignup();
      appLog.i('auth: signed in (new=$isNewUser)');
      return SignedIn(userId: session.userId, isNewUser: isNewUser, profile: profile);
    } on EdgeFunctionException catch (e) {
      if (e.code == 'not_approved') {
        // Signed in but never approved (hook/trigger bypassed?) — RLS blocks
        // everything without a profile, so end the session (D6 backstop).
        appLog.w('auth: complete-signup not_approved → sign out');
        await _backend.signOut();
        return const SignInRejected(AuthRejection.notApproved);
      }
      rethrow;
    }
  }

  Future<SignInOutcome> _run(Future<SignInOutcome> Function() body) async {
    try {
      return await body();
    } on Object catch (e) {
      final reason = AuthRejectionMapper.fromError(e);
      appLog.w('auth: rejected (${reason.name})');
      return SignInRejected(reason, serverMessage: e is AuthBackendException ? e.message : null);
    }
  }
}
