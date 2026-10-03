// resolveAuthRedirect (S05, pure Dart): the router guard as a function of the
// auth gate state and the requested location, so the five redirect cases are
// unit-testable without a widget tree (docs/routes.md §2).
//
// Public while signed out: `/gate/*`, `/login/*`, `/auth/reset` (password
// reset deep link `soongong://auth/reset`, which the platform delivers as
// host `auth` + path `/reset` and is normalised here).

import '../../../data/auth/auth_gate.dart';

abstract final class AppPaths {
  static const String launch = '/';
  static const String gate = '/gate';
  static const String gateBlocked = '/gate/blocked';
  static const String login = '/login';
  static const String loginEmail = '/login/email';
  static const String loginPassword = '/login/password';
  static const String loginSignup = '/login/signup';
  static const String authReset = '/auth/reset';
  static const String signupComplete = '/signup/complete';
  static const String onboarding = '/onboarding';
  static String onboardingStep(int step) => '/onboarding/$step';
  static const String home = '/home';
  static const String planner = '/planner';
  static const String timetable = '/timetable';
  static const String stats = '/stats';
  static const String settings = '/settings';
  static const String measureSetup = '/measure/setup';
  static const String gallery = '/_gallery';
}

/// Returns the location to go to instead, or null to allow [uri].
String? resolveAuthRedirect({required AuthGateState gate, required Uri uri}) {
  // Deep link normalisation: `soongong://auth/reset` → `/auth/reset`.
  if (uri.host == 'auth' && (uri.path == '/reset' || uri.path == 'reset')) {
    return AppPaths.authReset;
  }
  final path = uri.path;
  final isReset = path == AppPaths.authReset;
  final isGate = path == AppPaths.gate || path.startsWith('${AppPaths.gate}/');
  final isLogin = path == AppPaths.login || path.startsWith('${AppPaths.login}/');
  final isPublic = isReset || isGate || isLogin;
  final isLaunch = path == AppPaths.launch || path.isEmpty;
  final isDevTool = path == AppPaths.gallery;
  final isConsent = path == AppPaths.signupComplete;
  final isOnboarding = path == AppPaths.onboarding || path.startsWith('${AppPaths.onboarding}/');

  switch (gate) {
    case AuthGateLoading():
      // Hold on the launch screen until the profile is known; keep a reset
      // deep link (its screen shows the loading state itself).
      return isLaunch || isReset ? null : AppPaths.launch;
    case AuthGateProfileError():
      return isLaunch || isReset ? null : AppPaths.launch;
    case AuthGateLocalOnly():
      return isLaunch || isPublic || isConsent || isOnboarding ? AppPaths.home : null;
    case AuthGateSignedOut():
      return isPublic || isDevTool ? null : AppPaths.gate;
    case AuthGateSignedIn(:final profile):
      if (isReset || isDevTool) return null;
      if (profile == null) return isConsent ? null : AppPaths.signupComplete;
      if (!profile.onboardingDone) return isOnboarding ? null : AppPaths.onboardingStep(1);
      return isLaunch || isPublic || isConsent || isOnboarding ? AppPaths.home : null;
  }
}
