import 'package:go_router/go_router.dart';

import '../../core/config/app_config.dart';
import '../../core/dev/seat_lab/seat_lab_screen.dart';

/// Routes owned by the `measure` feature.
///
/// Exported to `core/router/app_router.dart` (S05 owns the router). Route
/// paths follow userflow node IDs (CLAUDE.md §4). Sheets and modals are not
/// routes — use `showAppSheet` / `showAppModal`.
final List<RouteBase> measureRoutes = <RouteBase>[
  // S04 · `/_seat_lab`: seat engine measurement harness. Dev tools only —
  // compiled out of prod together with the dev menu. Listed here (not in
  // app_router.dart) because the router is S05-owned; S05/S14 may move it
  // next to `/_gallery`.
  if (AppConfig.devToolsEnabled)
    GoRoute(
      path: seatLabPath,
      name: 'seatLab',
      builder: (_, _) => const SeatLabScreen(),
    ),
];
