// Supabase client initialisation (S03). Called from bootstrap() only when the
// flavor env carries the public URL + anon key; otherwise the app keeps
// running on Fakes/local data (S01–S02 behaviour).

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/config/app_config.dart';
import '../../core/logging/app_logger.dart';

Future<bool> initSupabaseIfConfigured() async {
  if (!AppConfig.hasBackendConfig) return false;
  await Supabase.initialize(
    url: AppConfig.supabaseUrl,
    // The legacy anon JWT and the new sb_publishable_… key both go here.
    publishableKey: AppConfig.supabaseAnonKey,
    authOptions: const FlutterAuthClientOptions(autoRefreshToken: true),
  );
  appLog.i('supabase: initialised');
  return true;
}
