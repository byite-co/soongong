// AuthMode (S05): how this build authenticates. Derived from the compile-time
// env by default; tests override the provider to run the real gate/login
// flows against a fake backend.

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../core/config/app_config.dart';

part 'auth_mode.g.dart';

enum AuthMode {
  /// Supabase URL + anon key present: age gate · login · profiles.
  backend,

  /// Dev build without backend config: no auth, local user, fakes (S01–S02).
  localOnly,

  /// Prod build without backend config — a build error; nothing signs in.
  misconfigured,
}

@Riverpod(keepAlive: true)
AuthMode authMode(Ref ref) {
  if (AppConfig.hasBackendConfig) return AuthMode.backend;
  return AppConfig.isDev ? AuthMode.localOnly : AuthMode.misconfigured;
}
