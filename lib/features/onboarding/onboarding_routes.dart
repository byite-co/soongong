import 'package:go_router/go_router.dart';

import '../auth/domain/auth_redirect.dart';
import 'presentation/onboarding_screen.dart';

/// Routes owned by the `onboarding` feature (S05): `ob1 ob2 ob3` as
/// `/onboarding/1..3`. `/onboarding` forwards to step 1.
final List<RouteBase> onboardingRoutes = <RouteBase>[
  GoRoute(
    path: AppPaths.onboarding,
    redirect: (_, _) => AppPaths.onboardingStep(1),
  ),
  GoRoute(
    path: '${AppPaths.onboarding}/:step',
    name: 'onboarding',
    builder: (_, state) {
      final step = int.tryParse(state.pathParameters['step'] ?? '') ?? 1;
      return OnboardingScreen(step: step.clamp(1, 3));
    },
  ),
];
