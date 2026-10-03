// Auth providers (S03). `authBackendProvider` returns the Supabase-backed
// implementation once `Supabase.initialize` ran (bootstrap, when the env has
// SUPABASE_URL/ANON_KEY); without backend config it throws so a screen never
// silently runs against nothing. S05 overrides `currentUserIdProvider` from
// `authRepositoryProvider.authState`.

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show Supabase;

import '../../core/config/app_config.dart';
import '../../core/contracts/providers.dart';
import 'age_gate_repository.dart';
import 'auth_backend.dart';
import 'auth_repository.dart';
import 'social/sdk_social_sign_in.dart';
import 'social/social_sign_in.dart';
import 'supabase_auth_backend.dart';

part 'auth_providers.g.dart';

@Riverpod(keepAlive: true)
AuthBackend authBackend(Ref ref) {
  if (!AppConfig.hasBackendConfig) {
    throw StateError('Supabase is not configured (env/app.<flavor>.json)');
  }
  return SupabaseAuthBackend(Supabase.instance.client, deviceId: ref.watch(deviceIdProvider));
}

@Riverpod(keepAlive: true)
AgeGateRepository ageGateRepository(Ref ref) => AgeGateRepository(ref.watch(authBackendProvider));

@Riverpod(keepAlive: true)
AuthRepository authRepository(Ref ref) => AuthRepository(
      ref.watch(authBackendProvider),
      ref.watch(ageGateRepositoryProvider),
      checkEmailAppKey: AppConfig.checkEmailAppKey,
    );

/// Native provider tokens (S05). Tests override with [FakeSocialSignIn].
@Riverpod(keepAlive: true)
SocialSignIn socialSignIn(Ref ref) => SdkSocialSignIn();
