// Supabase client initialisation (S03). Called from bootstrap() only when the
// flavor env carries the public URL + anon key; otherwise the app keeps
// running on Fakes/local data (S01–S02 behaviour).

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/config/app_config.dart';
import '../../core/logging/app_logger.dart';
import 'secure_auth_storage.dart';

Future<bool> initSupabaseIfConfigured() async {
  if (!AppConfig.hasBackendConfig) return false;
  final keys = AuthStorageKeys(url: AppConfig.supabaseUrl, flavor: AppConfig.flavor.name);
  const secrets = PlatformAuthSecretStore();
  await Supabase.initialize(
    url: AppConfig.supabaseUrl,
    // The legacy anon JWT and the new sb_publishable_… key both go here.
    publishableKey: AppConfig.supabaseAnonKey,
    // S05b: the SDK's deep-link observer is the single handler of
    // `soongong://auth/reset` (PKCE code exchange → `passwordRecovery` event).
    authOptions: FlutterAuthClientOptions(
      autoRefreshToken: true,
      detectSessionInUri: true,
      localStorage: SecureSessionStorage(
        secrets: secrets,
        key: keys.session,
        legacy: SharedPreferencesLocalStorage(persistSessionKey: keys.legacySession),
      ),
      pkceAsyncStorage: SecurePkceStorage(
        secrets: secrets,
        keys: keys,
        legacy: SharedPreferencesGotrueAsyncStorage(),
      ),
    ),
  );
  appLog.i('supabase: initialised');
  return true;
}
