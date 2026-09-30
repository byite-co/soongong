// OWNER: S05 — `app_router.dart` 는 S05가 소유한다. S05 머지 후에는 S14만
// 수정한다(통합 소유 이관, CLAUDE.md §4). 다른 feature 세션은 이 파일을 건드리지
// 않고 `features/<feature>/<feature>_routes.dart` 에 라우트 목록만 export 한다.
//
// S01 provides only: `/` → temporary splash, `/_gallery` (dev tools only), and
// the spread of every feature route list so S05 can see the wiring pattern.
// Route paths follow userflow node IDs (e.g. `/measure/setup` = setupOn).

import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../features/auth/auth_routes.dart';
import '../../features/billing/billing_routes.dart';
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
import 'temp_splash_screen.dart';

part 'app_router.g.dart';

/// Root navigator — used by sheets/modals (`useRootNavigator`) and the dev
/// menu gate.
final GlobalKey<NavigatorState> rootNavigatorKey =
    GlobalKey<NavigatorState>(debugLabel: 'root');

const String galleryPath = '/_gallery';

@Riverpod(keepAlive: true)
GoRouter appRouter(Ref ref) {
  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: '/',
    routes: <RouteBase>[
      GoRoute(
        path: '/',
        name: 'splash',
        builder: (_, _) => const TempSplashScreen(),
      ),
      if (AppConfig.devToolsEnabled)
        GoRoute(
          path: galleryPath,
          name: 'gallery',
          builder: (_, _) => const GalleryScreen(),
        ),
      ...authRoutes,
      ...onboardingRoutes,
      ...homeRoutes,
      ...measureRoutes,
      ...plannerRoutes,
      ...timetableRoutes,
      ...statsRoutes,
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
