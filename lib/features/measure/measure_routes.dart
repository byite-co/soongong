import 'package:go_router/go_router.dart';

import '../../core/config/app_config.dart';
import '../../core/dev/seat_lab/seat_lab_screen.dart';
import '../../core/router/placeholder_screen.dart';
import '../../core/strings/common_strings.dart';
import '../auth/domain/auth_redirect.dart';

/// Routes owned by the `measure` feature (S06).
///
/// Exported to `core/router/app_router.dart` (S05 owns the router). Route
/// paths follow userflow node IDs (CLAUDE.md §4). Sheets and modals are not
/// routes — use `showAppSheet` / `showAppModal`.
///
/// `/measure/setup` (`setupOn`) is the home CTA target; S05 placed a
/// placeholder. The session-recovery sheet resumes with
/// `/measure/setup?resume=<sessionId>` (docs/routes.md). Routes sit outside
/// the tab shell (full-screen measurement).
final List<RouteBase> measureRoutes = <RouteBase>[
  GoRoute(
    path: AppPaths.measureSetup,
    name: 'setupOn',
    builder: (_, _) => const PlaceholderScreen(title: CommonStrings.measureSetupTitle),
  ),
  // S04 · `/_seat_lab`: seat engine measurement harness. Dev tools only —
  // compiled out of prod together with the dev menu. Listed here (not in
  // app_router.dart) because the router is S05-owned; S05/S14 may move it
  // next to `/_gallery`. The guard treats it like `/_gallery`
  // (`AppPaths.seatLab`).
  if (AppConfig.devToolsEnabled)
    GoRoute(
      path: seatLabPath,
      name: 'seatLab',
      builder: (_, _) => const SeatLabScreen(),
    ),
];
