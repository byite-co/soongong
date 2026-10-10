import 'package:go_router/go_router.dart';

import 'presentation/privacy_screen.dart';

/// Routes owned by the `privacy` feature (S09, prototype 11 · N6 · N7 ·
/// expSheet · delDlg).
///
/// Exported to `core/router/app_router.dart` (S05 owns the router). The
/// photos sheet, the export sheet and the delete confirmations are not
/// routes.
final List<RouteBase> privacyRoutes = <RouteBase>[
  GoRoute(
    path: privacyPath,
    name: 'privacy',
    builder: (_, _) => const PrivacyScreen(),
  ),
];

const String privacyPath = '/settings/privacy';
