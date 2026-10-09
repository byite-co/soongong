// AuthBackend (S03): the thin seam between the repositories and
// supabase_flutter. Everything the repositories need from Supabase is here, in
// our own types, so tests run against [FakeAuthBackend] without the SDK.

import 'auth_models.dart';

abstract class AuthBackend {
  /// Calls an Edge Function with a JSON body. [withUser] adds the session JWT.
  /// Non-2xx → [EdgeFunctionException]; no network → [NetworkUnavailableException].
  Future<Map<String, dynamic>> invoke(
    String function, {
    Map<String, dynamic> body = const <String, dynamic>{},
    Map<String, String> headers = const <String, String>{},
    bool withUser = true,
  });

  /// `supabase.rpc(name, params)` as the signed-in user.
  Future<dynamic> rpc(String name, Map<String, dynamic> params);

  Future<AuthSession> signInWithIdToken({
    required SignupProvider provider,
    required String idToken,
    String? accessToken,
    String? nonce,
  });

  Future<AuthSession> signUpWithEmail({required String email, required String password});

  Future<AuthSession> signInWithPassword({required String email, required String password});

  /// Sends the reset mail; the Supabase implementation passes
  /// [AuthDeepLinks.passwordReset] as `redirectTo` (S05 `/auth/reset`).
  Future<void> resetPasswordForEmail(String email);

  /// `auth.updateUser(password)` for the signed-in user (password recovery).
  Future<void> updatePassword(String newPassword);

  /// Own `profiles` row (RLS: readable only while it exists) or null when the
  /// account has no profile yet (`complete-signup` pending). S05 routing.
  Future<Map<String, dynamic>?> fetchOwnProfile();

  Future<void> signOut();

  AuthSession? get currentSession;

  /// Emits the current session on every auth change (null when signed out).
  Stream<AuthSession?> get sessions;

  /// Fires once per password-recovery link the SDK exchanged for a session
  /// (`AuthChangeEvent.passwordRecovery`). S05b: the SDK's deep-link observer
  /// owns `soongong://auth/reset`; the router only reacts to this event.
  Stream<void> get passwordRecoveryEvents;
}
