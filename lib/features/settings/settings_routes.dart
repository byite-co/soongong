import 'package:go_router/go_router.dart';

import '../auth/domain/auth_redirect.dart';
import 'presentation/settings_screen.dart';

/// Routes owned by the `settings` feature (S09).
///
/// `/settings` sits outside the tab shell (home header gear → push on the
/// root navigator). Sub-screens live in their own features
/// (`/settings/subjects` · `/settings/privacy` · `/settings/help`). Sheets
/// (목표 시간 · 주 시작 요일 · 알림) and modals are not routes — `showAppSheet`
/// / `showAppModal`.
final List<RouteBase> settingsRoutes = <RouteBase>[
  GoRoute(
    path: AppPaths.settings,
    name: 'settings',
    builder: (_, _) => const SettingsScreen(),
  ),
];
