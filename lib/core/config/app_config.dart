// Client configuration injected with `--dart-define-from-file=env/app.<flavor>.json`
// (D12 · CLAUDE.md §7). Public values only: there is no slot for a service
// role key here and there never will be — server secrets live in
// `supabase/.env` (S03) and are never referenced from app code.

import 'dart:io' show Platform;

enum AppFlavor { dev, prod }

abstract final class AppConfig {
  static const String _flavorRaw =
      String.fromEnvironment('APP_FLAVOR', defaultValue: 'dev');

  static AppFlavor get flavor =>
      _flavorRaw == 'prod' ? AppFlavor.prod : AppFlavor.dev;

  static bool get isProd => flavor == AppFlavor.prod;
  static bool get isDev => flavor == AppFlavor.dev;

  /// App version shown in 설정 (S09) and sent with 문의. The build injects
  /// `APP_VERSION` (pubspec `version`); the default matches pubspec today.
  static const String appVersion = String.fromEnvironment('APP_VERSION', defaultValue: '0.1.0');

  /// S09b: the support mailbox shown as the fallback for a failed inquiry.
  /// Empty (default) = not decided yet — the help screen then states that
  /// the fallback address is pending instead of inventing one.
  static const String supportEmail = String.fromEnvironment('SUPPORT_EMAIL');
  static bool get hasSupportEmail => supportEmail.trim().isNotEmpty;

  /// `ios` · `android` · … for the inquiry summary line (no device ids).
  static String get platformLabel => Platform.operatingSystem;

  /// Supabase project URL (public).
  static const String supabaseUrl = String.fromEnvironment('SUPABASE_URL');

  /// Supabase anon key (public, RLS-scoped).
  static const String supabaseAnonKey =
      String.fromEnvironment('SUPABASE_ANON_KEY');

  /// App key sent as `x-app-key` to the pre-login `check-email` function
  /// (abuse deterrent, not a secret — it ships in the binary).
  static const String checkEmailAppKey = String.fromEnvironment('CHECK_EMAIL_APP_KEY');

  /// Social sign-in client ids (public, S05 · D6). Empty = provider not
  /// offered in this build. Google needs the *web* client id for an id_token.
  static const String googleServerClientId =
      String.fromEnvironment('GOOGLE_SERVER_CLIENT_ID');
  static const String googleIosClientId =
      String.fromEnvironment('GOOGLE_IOS_CLIENT_ID');
  static const String kakaoNativeAppKey =
      String.fromEnvironment('KAKAO_NATIVE_APP_KEY');

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
