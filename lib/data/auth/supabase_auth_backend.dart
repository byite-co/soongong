// SupabaseAuthBackend (S03): AuthBackend over supabase_flutter. The only file
// in the app that imports Supabase auth/functions types for the auth flow.
// No birth date, email or token is logged here (CLAUDE.md §7).

import 'dart:async';
import 'dart:io' show SocketException;

import 'package:http/http.dart' show ClientException;
import 'package:supabase_flutter/supabase_flutter.dart';

import 'auth_backend.dart';
import 'auth_models.dart';

class SupabaseAuthBackend implements AuthBackend {
  SupabaseAuthBackend(this._client, {required this.deviceId});

  final SupabaseClient _client;

  /// Sent as `x-device-id` so server-created rows carry the device (D2).
  final String deviceId;

  GoTrueClient get _auth => _client.auth;

  /// [withUser] is informational here: supabase_flutter attaches the session
  /// JWT when one exists and the anon key otherwise, and the pre-login
  /// functions (`age-check` · `issue-pass` · `check-email`) run with
  /// `verify_jwt = false`, so no header override is needed.
  @override
  Future<Map<String, dynamic>> invoke(
    String function, {
    Map<String, dynamic> body = const <String, dynamic>{},
    Map<String, String> headers = const <String, String>{},
    bool withUser = true,
  }) async {
    try {
      final res = await _client.functions.invoke(
        function,
        body: body,
        headers: <String, String>{
          'x-device-id': deviceId,
          'x-request-id': _requestId(),
          ...headers,
        },
      );
      return _asMap(res.data);
    } on FunctionException catch (e) {
      final details = e.details;
      final map = details is Map ? Map<String, dynamic>.from(details) : <String, dynamic>{};
      throw EdgeFunctionException(
        e.status,
        (map['error'] as String?) ?? 'http_${e.status}',
        detail: map['detail'] as String?,
        body: map,
      );
    } on SocketException {
      throw const NetworkUnavailableException();
    } on ClientException {
      throw const NetworkUnavailableException();
    } on TimeoutException {
      throw const NetworkUnavailableException();
    }
  }

  @override
  Future<dynamic> rpc(String name, Map<String, dynamic> params) async {
    try {
      return await _client.rpc<dynamic>(name, params: params);
    } on PostgrestException catch (e) {
      throw AuthBackendException(e.message, statusCode: e.code, code: e.code);
    } on SocketException {
      throw const NetworkUnavailableException();
    } on ClientException {
      throw const NetworkUnavailableException();
    }
  }

  @override
  Future<AuthSession> signInWithIdToken({
    required SignupProvider provider,
    required String idToken,
    String? accessToken,
    String? nonce,
  }) =>
      _guard(() async {
        final res = await _auth.signInWithIdToken(
          provider: switch (provider) {
            SignupProvider.apple => OAuthProvider.apple,
            SignupProvider.google => OAuthProvider.google,
            SignupProvider.kakao => OAuthProvider.kakao,
            SignupProvider.email => throw ArgumentError('email is not an id_token provider'),
          },
          idToken: idToken,
          accessToken: accessToken,
          nonce: nonce,
        );
        return _sessionOf(res);
      });

  @override
  Future<AuthSession> signUpWithEmail({required String email, required String password}) =>
      _guard(() async => _sessionOf(await _auth.signUp(email: email, password: password)));

  @override
  Future<AuthSession> signInWithPassword({required String email, required String password}) =>
      _guard(() async =>
          _sessionOf(await _auth.signInWithPassword(email: email, password: password)));

  @override
  Future<void> resetPasswordForEmail(String email) =>
      _guard(() => _auth.resetPasswordForEmail(email));

  @override
  Future<void> signOut() => _guard(() => _auth.signOut());

  @override
  AuthSession? get currentSession {
    final s = _auth.currentSession;
    if (s == null) return null;
    return AuthSession(userId: s.user.id, email: s.user.email);
  }

  @override
  Stream<AuthSession?> get sessions => _auth.onAuthStateChange.map((state) {
        final s = state.session;
        return s == null ? null : AuthSession(userId: s.user.id, email: s.user.email);
      });

  // ---------------------------------------------------------------------

  static AuthSession _sessionOf(AuthResponse res) {
    final user = res.user ?? res.session?.user;
    if (user == null) {
      // Email confirmation enabled on the project → no session yet. S03 dev
      // projects run with confirmation off (docs/supabase-auth.md).
      throw const AuthBackendException('no_session', code: 'no_session');
    }
    return AuthSession(userId: user.id, email: user.email);
  }

  static Future<T> _guard<T>(Future<T> Function() body) async {
    try {
      return await body();
    } on AuthRetryableFetchException {
      throw const NetworkUnavailableException();
    } on AuthException catch (e) {
      throw AuthBackendException(e.message, statusCode: e.statusCode, code: e.code);
    } on SocketException {
      throw const NetworkUnavailableException();
    } on ClientException {
      throw const NetworkUnavailableException();
    }
  }

  static Map<String, dynamic> _asMap(Object? data) {
    if (data is Map) return Map<String, dynamic>.from(data);
    if (data == null) return <String, dynamic>{};
    return <String, dynamic>{'data': data};
  }

  static int _counter = 0;

  static String _requestId() =>
      '${DateTime.now().toUtc().microsecondsSinceEpoch.toRadixString(36)}-${(_counter++).toRadixString(36)}';
}
