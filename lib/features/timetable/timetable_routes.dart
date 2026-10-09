import 'package:go_router/go_router.dart';

import '../../core/router/placeholder_screen.dart';
import '../../core/strings/common_strings.dart';
import '../auth/domain/auth_redirect.dart';

/// Routes owned by the `timetable` feature.
///
/// `AppPaths.timetable` is a tab root of the shell (S05 `app_router.dart`); S05 placed a
/// placeholder so the tab exists. The owning session replaces the builder and
/// adds sub-routes here (they stay inside the tab). Sheets and modals are not
/// routes — use `showAppSheet` / `showAppModal`.
final List<RouteBase> timetableRoutes = <RouteBase>[
  GoRoute(
    path: AppPaths.timetable,
    name: 'timetable',
    builder: (_, _) => const PlaceholderScreen(title: CommonStrings.tabTimetable, inTab: true),
  ),
];
