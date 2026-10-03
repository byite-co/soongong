import 'package:go_router/go_router.dart';

import '../../core/router/placeholder_screen.dart';
import '../../core/strings/common_strings.dart';
import '../auth/domain/auth_redirect.dart';

/// Routes owned by the `measure` feature (S06).
///
/// `/measure/setup` (`setupOn`) is the home CTA target; S05 placed a
/// placeholder. The session-recovery sheet resumes with
/// `/measure/setup?resume=<sessionId>` (docs/routes.md). Routes sit outside
/// the tab shell (full-screen measurement). Sheets and modals are not routes.
final List<RouteBase> measureRoutes = <RouteBase>[
  GoRoute(
    path: AppPaths.measureSetup,
    name: 'setupOn',
    builder: (_, _) => const PlaceholderScreen(title: CommonStrings.measureSetupTitle),
  ),
];
