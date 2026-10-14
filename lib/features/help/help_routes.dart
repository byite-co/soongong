import 'package:go_router/go_router.dart';

import 'presentation/help_screen.dart';

/// Routes owned by the `help` feature (S09, prototype N4 · N-문의 전송 실패).
///
/// Exported to `core/router/app_router.dart` (S05 owns the router).
final List<RouteBase> helpRoutes = <RouteBase>[
  GoRoute(
    path: helpPath,
    name: 'help',
    builder: (_, _) => const HelpScreen(),
  ),
];

const String helpPath = '/settings/help';
