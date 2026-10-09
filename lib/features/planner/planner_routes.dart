import 'package:go_router/go_router.dart';

import '../auth/domain/auth_redirect.dart';
import 'presentation/planner_screen.dart';

/// Routes owned by the `planner` feature (S07).
///
/// `AppPaths.planner` is a tab root of the shell (S05 `app_router.dart`).
/// `?date=yyyy-MM-dd` opens that month with the day selected (the home's
/// "할 일 추가" and S10's "플래너에서 열기" use it). Sheets and modals are not
/// routes — the register/edit sheet is `showPlannerItemSheet`.
final List<RouteBase> plannerRoutes = <RouteBase>[
  GoRoute(
    path: AppPaths.planner,
    name: 'planner',
    builder: (_, state) => PlannerScreen(initialDate: state.uri.queryParameters['date']),
  ),
];
