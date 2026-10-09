// FakeAuthBackend (S03 → shared in S05): records every call, returns scripted
// responses, and drives the session stream like gotrue would.

import 'dart:async';

import 'package:soongong/data/auth/auth_backend.dart';
import 'package:soongong/data/auth/auth_models.dart';

class RecordedCall {
  RecordedCall(this.name, this.body, this.headers, this.withUser);

  final String name;
  final Map<String, dynamic> body;
  final Map<String, String> headers;
  final bool withUser;

  @override
  String toString() => '$name $body';
}

/// A `profiles` row as PostgREST returns it (`onboarding_done` false).
const Map<String, dynamic> kProfileRowOnboardingPending = <String, dynamic>{
  'user_id': 'u-1',
  'onboarding_done': false,
  'purge_epoch': 0,
  'consent_account_version': '2026-10-01',
  'consent_account_at': '2026-10-01T00:00:00+00:00',
  'consent_reading_version': null,
  'consent_reading_at': null,
  'consent_reading_revoked_at': null,
  'created_at': '2026-10-01T00:00:00+00:00',
};

final Map<String, dynamic> kProfileRowOnboardingDone = <String, dynamic>{
  ...kProfileRowOnboardingPending,
  'onboarding_done': true,
};

class FakeAuthBackend implements AuthBackend {
  FakeAuthBackend({this.session, this.profileRow});

  final List<RecordedCall> calls = <RecordedCall>[];
  final Map<String, Object> responses = <String, Object>{};
  Object? signInError;
  Object? signUpError;
  Object? signOutError;
  Object? updatePasswordError;

  /// Own `profiles` row returned by [fetchOwnProfile]; null = no profile yet.
  Map<String, dynamic>? profileRow;

  /// When set, [fetchOwnProfile] throws it (offline right after sign-in).
  Object? profileError;

  AuthSession? session;
  AuthSession signedInSession = const AuthSession(userId: 'u-1', email: 'a@x.io');
  final StreamController<AuthSession?> _ctrl = StreamController<AuthSession?>.broadcast();

  List<String> get callNames => calls.map((c) => c.name).toList();

  @override
  Future<Map<String, dynamic>> invoke(
    String function, {
    Map<String, dynamic> body = const <String, dynamic>{},
    Map<String, String> headers = const <String, String>{},
    bool withUser = true,
  }) async {
    calls.add(RecordedCall(function, body, headers, withUser));
    final r = responses[function];
    if (r is Exception) throw r;
    if (r is Map<String, dynamic>) return r;
    return <String, dynamic>{};
  }

  @override
  Future<dynamic> rpc(String name, Map<String, dynamic> params) async {
    calls.add(RecordedCall('rpc:$name', params, const {}, true));
    final r = responses['rpc:$name'];
    if (r is Exception) throw r;
    return r;
  }

  AuthSession _signIn(String name, Map<String, dynamic> body, Object? error) {
    calls.add(RecordedCall(name, body, const {}, true));
    if (error != null) throw error;
    session = signedInSession;
    _ctrl.add(session);
    return session!;
  }

  @override
  Future<AuthSession> signInWithIdToken({
    required SignupProvider provider,
    required String idToken,
    String? accessToken,
    String? nonce,
  }) async =>
      _signIn('signInWithIdToken', {'provider': provider.wire, 'nonce': nonce}, signInError);

  @override
  Future<AuthSession> signUpWithEmail({required String email, required String password}) async =>
      _signIn('signUp', {'email': email}, signUpError);

  @override
  Future<AuthSession> signInWithPassword({required String email, required String password}) async =>
      _signIn('signInWithPassword', {'email': email}, signInError);

  @override
  Future<void> resetPasswordForEmail(String email) async =>
      calls.add(RecordedCall('reset', {'email': email}, const {}, false));

  @override
  Future<void> updatePassword(String newPassword) async {
    calls.add(RecordedCall('updatePassword', const {}, const {}, true));
    if (updatePasswordError != null) throw updatePasswordError!;
  }

  @override
  Future<Map<String, dynamic>?> fetchOwnProfile() async {
    calls.add(RecordedCall('fetchProfile', const {}, const {}, true));
    if (profileError != null) throw profileError!;
    return session == null ? null : profileRow;
  }

  @override
  Future<void> signOut() async {
    calls.add(RecordedCall('signOut', const {}, const {}, true));
    if (signOutError != null) throw signOutError!;
    session = null;
    _ctrl.add(null);
  }

  /// Simulates a session arriving from outside a call (deep link, restore).
  void emitSession(AuthSession? s) {
    session = s;
    _ctrl.add(s);
  }

  final StreamController<void> _recovery = StreamController<void>.broadcast();

  /// Simulates the SDK exchanging a `soongong://auth/reset` link: the session
  /// arrives, then the `passwordRecovery` event fires (S05b).
  void emitPasswordRecovery({AuthSession? session}) {
    if (session != null) emitSession(session);
    _recovery.add(null);
  }

  @override
  Stream<void> get passwordRecoveryEvents => _recovery.stream;

  @override
  AuthSession? get currentSession => session;

  @override
  Stream<AuthSession?> get sessions => _ctrl.stream;
}
