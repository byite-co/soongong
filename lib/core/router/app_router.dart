// OWNER: S05 — `app_router.dart` 는 S05가 소유한다. S05 머지 후에는 S14만
// 수정한다(통합 소유 이관, CLAUDE.md §4). 다른 feature 세션은 이 파일을 건드리지
// 않고 `features/<feature>/<feature>_routes.dart` 에 라우트 목록만 export 한다.
// 경로 예약 표: docs/routes.md.
//
// Structure (S05):
//   /                 launch — holds while the session/profile is read
//   /gate /gate/blocked /login/* /auth/reset /signup/complete /onboarding/*
//   StatefulShellRoute — 4 tabs: /home /planner /timetable /stats
//   /settings /measure/* … (outside the shell, pushed on the root navigator)
// Guard: `resolveAuthRedirect` (pure) over `authGateProvider`; the router
// re-evaluates it whenever the gate state changes (refreshListenable).

import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../data/auth/auth_gate.dart';
import '../../features/auth/auth_routes.dart';
import '../../features/auth/domain/auth_redirect.dart';
import '../../features/billing/billing_routes.dart';
import '../../features/gate/gate_routes.dart';
import '../../features/help/help_routes.dart';
import '../../features/home/home_routes.dart';
import '../../features/measure/measure_routes.dart';
import '../../features/onboarding/onboarding_routes.dart';
import '../../features/planner/planner_routes.dart';
import '../../features/privacy/privacy_routes.dart';
import '../../features/reading/reading_routes.dart';
import '../../features/review/review_routes.dart';
import '../../features/settings/settings_routes.dart';
import '../../features/stats/stats_routes.dart';
import '../../features/subjects/subjects_routes.dart';
import '../../features/timetable/timetable_routes.dart';
import '../../features/wrongs/wrongs_routes.dart';
import '../config/app_config.dart';
import '../dev/gallery/gallery_screen.dart';
import 'app_shell.dart';
import 'launch_screen.dart';

part 'app_router.g.dart';

/// Root navigator — used by sheets/modals (`useRootNavigator`) and the dev
/// menu gate. Routes outside the shell (settings, measure, …) push here.
final GlobalKey<NavigatorState> rootNavigatorKey =
    GlobalKey<NavigatorState>(debugLabel: 'root');

const String galleryPath = AppPaths.gallery;

/// Bridges auth-gate changes into go_router's `refreshListenable`.
class RouterRefresh extends ChangeNotifier {
  void ping() => notifyListeners();
}

@Riverpod(keepAlive: true)
GoRouter appRouter(Ref ref) {
  final refresh = RouterRefresh();
  ref.listen<AuthGateState>(authGateProvider, (_, _) => refresh.ping());
  ref.onDispose(refresh.dispose);

  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: AppPaths.launch,
    refreshListenable: refresh,
    redirect: (_, state) =>
        resolveAuthRedirect(gate: ref.read(authGateProvider), uri: state.uri),
    routes: <RouteBase>[
      GoRoute(
        path: AppPaths.launch,
        name: 'launch',
        builder: (_, _) => const LaunchScreen(),
      ),
      if (AppConfig.devToolsEnabled)
        GoRoute(
          path: galleryPath,
          name: 'gallery',
          builder: (_, _) => const GalleryScreen(),
        ),
      ...gateRoutes,
      ...authRoutes,
      ...onboardingRoutes,
      StatefulShellRoute.indexedStack(
        builder: (_, _, shell) => AppShell(shell: shell),
        branches: <StatefulShellBranch>[
          StatefulShellBranch(routes: homeRoutes),
          StatefulShellBranch(routes: plannerRoutes),
          StatefulShellBranch(routes: timetableRoutes),
          StatefulShellBranch(routes: statsRoutes),
        ],
      ),
      ...measureRoutes,
      ...settingsRoutes,
      ...subjectsRoutes,
      ...privacyRoutes,
      ...readingRoutes,
      ...wrongsRoutes,
      ...reviewRoutes,
      ...billingRoutes,
      ...helpRoutes,
    ],
  );
}
