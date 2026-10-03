import 'package:go_router/go_router.dart';

import '../auth/domain/auth_redirect.dart';
import 'presentation/home_screen.dart';

/// Routes owned by the `home` feature (S05): `/home` is the first tab of the
/// shell (`core/router/app_router.dart`). Sub-routes added here stay inside
/// the tab (the tab bar remains visible).
final List<RouteBase> homeRoutes = <RouteBase>[
  GoRoute(
    path: AppPaths.home,
    name: 'home',
    builder: (_, _) => const HomeScreen(),
  ),
];
