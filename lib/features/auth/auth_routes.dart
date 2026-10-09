import 'package:go_router/go_router.dart';

import 'domain/auth_redirect.dart';
import 'presentation/email_screen.dart';
import 'presentation/login_screen.dart';
import 'presentation/password_screen.dart';
import 'presentation/reset_password_screen.dart';
import 'presentation/signup_complete_screen.dart';
import 'presentation/signup_password_screen.dart';

/// Routes owned by the `auth` feature (S05): `login lgEmail lgPw lgSignup`,
/// the password-reset deep link and consent ①. Exported to
/// `core/router/app_router.dart` (S05 owns the router).
final List<RouteBase> authRoutes = <RouteBase>[
  GoRoute(
    path: AppPaths.login,
    name: 'login',
    builder: (_, _) => const LoginScreen(),
  ),
  GoRoute(
    path: AppPaths.loginEmail,
    name: 'lgEmail',
    builder: (_, _) => const EmailScreen(),
  ),
  GoRoute(
    path: AppPaths.loginPassword,
    name: 'lgPw',
    builder: (_, _) => const PasswordScreen(),
  ),
  GoRoute(
    path: AppPaths.loginSignup,
    name: 'lgSignup',
    builder: (_, _) => const SignupPasswordScreen(),
  ),
  GoRoute(
    path: AppPaths.authReset,
    name: 'authReset',
    builder: (_, _) => const ResetPasswordScreen(),
  ),
  GoRoute(
    path: AppPaths.signupComplete,
    name: 'signupComplete',
    builder: (_, _) => const SignupCompleteScreen(),
  ),
];
