import 'package:go_router/go_router.dart';

import '../auth/domain/auth_redirect.dart';
import 'presentation/stats_screen.dart';

/// Routes owned by the `stats` feature (S08).
///
/// `AppPaths.stats` is a tab root of the shell (S05 `app_router.dart`).
/// Sub-routes stay inside the tab. Sheets and modals are not routes — use
/// `showAppSheet` / `showAppModal`. The wrongs card links `/wrongs` (S09)
/// and the premium badge `/paywall` (S12), both reserved as placeholders.
final List<RouteBase> statsRoutes = <RouteBase>[
  GoRoute(
    path: AppPaths.stats,
    name: 'stats',
    builder: (_, _) => const StatsScreen(),
  ),
];
