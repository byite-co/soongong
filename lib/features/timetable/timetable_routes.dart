import 'package:go_router/go_router.dart';

import '../auth/domain/auth_redirect.dart';
import 'presentation/timetable_screen.dart';

/// Routes owned by the `timetable` feature (S08).
///
/// `AppPaths.timetable` is a tab root of the shell (S05 `app_router.dart`).
/// Sub-routes stay inside the tab. Sheets and modals are not routes — use
/// `showAppSheet` / `showAppModal`. Session blocks push `/session/:id`
/// (S06, outside the shell).
final List<RouteBase> timetableRoutes = <RouteBase>[
  GoRoute(
    path: AppPaths.timetable,
    name: 'timetable',
    builder: (_, _) => const TimetableScreen(),
  ),
];
