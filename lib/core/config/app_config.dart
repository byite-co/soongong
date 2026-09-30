// Client configuration injected with `--dart-define-from-file=env/app.<flavor>.json`
// (D12 · CLAUDE.md §7). Public values only: there is no slot for a service
// role key here and there never will be — server secrets live in
// `supabase/.env` (S03) and are never referenced from app code.

enum AppFlavor { dev, prod }

abstract final class AppConfig {
  static const String _flavorRaw =
      String.fromEnvironment('APP_FLAVOR', defaultValue: 'dev');

  static AppFlavor get flavor =>
      _flavorRaw == 'prod' ? AppFlavor.prod : AppFlavor.dev;

  static bool get isProd => flavor == AppFlavor.prod;
  static bool get isDev => flavor == AppFlavor.dev;

  /// Supabase project URL (public).
  static const String supabaseUrl = String.fromEnvironment('SUPABASE_URL');

  /// Supabase anon key (public, RLS-scoped).
  static const String supabaseAnonKey =
      String.fromEnvironment('SUPABASE_ANON_KEY');

  /// RevenueCat public SDK keys (public).
  static const String revenueCatPublicKeyAndroid =
      String.fromEnvironment('REVENUECAT_PUBLIC_KEY_ANDROID');
  static const String revenueCatPublicKeyIos =
      String.fromEnvironment('REVENUECAT_PUBLIC_KEY_IOS');

  /// Whether the backend values are present. Until S03 wires Supabase the app
  /// runs entirely on Fakes, so this is informational.
  static bool get hasBackendConfig =>
      supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;

  /// Dev tools (dev menu, `/_gallery`) are compiled in only when
  /// `DEV_MENU=true` is defined AND the flavor is not prod. Both are
  /// compile-time constants so prod builds tree-shake the dev code.
  static const bool devToolsEnabled =
      bool.fromEnvironment('DEV_MENU') && _flavorRaw != 'prod';
}
