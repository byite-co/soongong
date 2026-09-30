import 'package:go_router/go_router.dart';

/// Routes owned by the `timetable` feature.
///
/// Exported to `core/router/app_router.dart` (S05 owns the router). Route
/// paths follow userflow node IDs (CLAUDE.md §4). Sheets and modals are not
/// routes — use `showAppSheet` / `showAppModal`.
final List<RouteBase> timetableRoutes = <RouteBase>[];
