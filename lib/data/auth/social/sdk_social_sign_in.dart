// SdkSocialSignIn (S05): SocialSignIn over the native provider SDKs. The only
// file that imports sign_in_with_apple / google_sign_in / kakao_flutter_sdk.
// Nothing here logs tokens, e-mails or names (CLAUDE.md §7).
//
// Availability is a build/platform fact, not a server state:
//   Apple  — iOS only in v1 (Android needs a Services ID web flow; S15).
//   Google — needs GOOGLE_SERVER_CLIENT_ID (web client id) for an id_token;
//            GOOGLE_IOS_CLIENT_ID on iOS.
//   Kakao  — needs KAKAO_NATIVE_APP_KEY (`KakaoSdk.init` in bootstrap) and
//            OIDC enabled on the Kakao app so the token carries an id_token.

import 'dart:async';
import 'dart:io' show SocketException;

import 'package:flutter/foundation.dart' show TargetPlatform, defaultTargetPlatform;
import 'package:flutter/services.dart' show PlatformException;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import '../../../core/config/app_config.dart';
import '../../../core/logging/app_logger.dart';
import '../auth_models.dart';
import 'nonce.dart';
import 'social_sign_in.dart';

class SdkSocialSignIn implements SocialSignIn {
  SdkSocialSignIn({
    String? googleServerClientId,
    String? googleIosClientId,
    String? kakaoNativeAppKey,
    TargetPlatform? platform,
  })  : _googleServerClientId = googleServerClientId ?? AppConfig.googleServerClientId,
        _googleIosClientId = googleIosClientId ?? AppConfig.googleIosClientId,
        _kakaoNativeAppKey = kakaoNativeAppKey ?? AppConfig.kakaoNativeAppKey,
        _platform = platform ?? defaultTargetPlatform;

  final String _googleServerClientId;
  final String _googleIosClientId;
  final String _kakaoNativeAppKey;
  final TargetPlatform _platform;

  bool _googleInitialised = false;

  @override
  bool isAvailable(SignupProvider provider) => switch (provider) {
        SignupProvider.apple => _platform == TargetPlatform.iOS,
        SignupProvider.google => _googleServerClientId.isNotEmpty,
        SignupProvider.kakao => _kakaoNativeAppKey.isNotEmpty,
        SignupProvider.email => false,
      };

  @override
  Future<SocialTokenOutcome> acquire(SignupProvider provider) async {
    if (!isAvailable(provider)) {
      appLog.i('social ${provider.wire}: unavailable in this build');
      return SocialTokenUnavailable('${provider.wire}_not_configured');
    }
    try {
      final out = await switch (provider) {
        SignupProvider.apple => _apple(),
        SignupProvider.google => _google(),
        SignupProvider.kakao => _kakao(),
        SignupProvider.email => throw ArgumentError('email is not a social provider'),
      };
      appLog.i('social ${provider.wire}: ${out.runtimeType}');
      return out;
    } on SocketException {
      return const SocialTokenFailed('socket', network: true);
    } on TimeoutException {
      return const SocialTokenFailed('timeout', network: true);
    } on Object catch (e) {
      appLog.w('social ${provider.wire}: ${e.runtimeType}');
      return SocialTokenFailed(e.runtimeType.toString());
    }
  }

  Future<SocialTokenOutcome> _apple() async {
    final rawNonce = generateRawNonce();
    try {
      final cred = await SignInWithApple.getAppleIDCredential(
        scopes: const <AppleIDAuthorizationScopes>[
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        nonce: sha256Hex(rawNonce),
      );
      final token = cred.identityToken;
      if (token == null) return const SocialTokenFailed('apple_no_identity_token');
      return SocialTokenAcquired(idToken: token, rawNonce: rawNonce);
    } on SignInWithAppleAuthorizationException catch (e) {
      if (e.code == AuthorizationErrorCode.canceled) return const SocialTokenCancelled();
      return SocialTokenFailed('apple_${e.code.name}');
    }
  }

  Future<SocialTokenOutcome> _google() async {
    final g = GoogleSignIn.instance;
    if (!_googleInitialised) {
      await g.initialize(
        clientId: _googleIosClientId.isEmpty ? null : _googleIosClientId,
        serverClientId: _googleServerClientId,
      );
      _googleInitialised = true;
    }
    try {
      final account = await g.authenticate(scopeHint: const <String>['email']);
      final idToken = account.authentication.idToken;
      if (idToken == null) return const SocialTokenFailed('google_no_id_token');
      return SocialTokenAcquired(idToken: idToken);
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) return const SocialTokenCancelled();
      return SocialTokenFailed('google_${e.code.name}');
    }
  }

  Future<SocialTokenOutcome> _kakao() async {
    OAuthToken token;
    try {
      if (await isKakaoTalkInstalled()) {
        try {
          token = await UserApi.instance.loginWithKakaoTalk();
        } on PlatformException catch (e) {
          // The user came back from KakaoTalk without finishing.
          if (e.code == 'CANCELED') return const SocialTokenCancelled();
          // KakaoTalk could not complete (not logged in, old version …) →
          // Kakao's documented fallback is the account (web) login.
          token = await UserApi.instance.loginWithKakaoAccount();
        }
      } else {
        token = await UserApi.instance.loginWithKakaoAccount();
      }
    } on KakaoAuthException catch (e) {
      if (e.error == AuthErrorCause.accessDenied) return const SocialTokenCancelled();
      return SocialTokenFailed('kakao_${e.error.name}');
    } on KakaoClientException catch (e) {
      if (e.reason == ClientErrorCause.cancelled) return const SocialTokenCancelled();
      return SocialTokenFailed('kakao_${e.reason.name}');
    }
    final idToken = token.idToken;
    if (idToken == null || idToken.isEmpty) return const SocialTokenFailed('kakao_no_id_token');
    return SocialTokenAcquired(idToken: idToken, accessToken: token.accessToken);
  }
}
