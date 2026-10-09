import 'package:go_router/go_router.dart';

import '../../core/router/placeholder_screen.dart';
import '../../core/strings/common_strings.dart';
import '../auth/domain/auth_redirect.dart';

/// Routes owned by the `settings` feature (S09).
///
/// `/settings` sits outside the tab shell (home header gear → push on the
/// root navigator). S05 placed a placeholder; S09 replaces the builder and
/// adds sub-routes. Sheets and modals are not routes — use `showAppSheet` /
/// `showAppModal`.
final List<RouteBase> settingsRoutes = <RouteBase>[
  GoRoute(
    path: AppPaths.settings,
    name: 'settings',
    builder: (_, _) => const PlaceholderScreen(title: CommonStrings.settingsTitle),
  ),
];
