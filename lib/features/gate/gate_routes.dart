import 'package:go_router/go_router.dart';

import '../auth/domain/auth_redirect.dart';
import 'presentation/gate_blocked_screen.dart';
import 'presentation/gate_screen.dart';

/// Routes owned by the `gate` feature (S05 · D6): `ageGate` · `ageBlocked`.
final List<RouteBase> gateRoutes = <RouteBase>[
  GoRoute(
    path: AppPaths.gate,
    name: 'ageGate',
    builder: (_, _) => const GateScreen(),
  ),
  GoRoute(
    path: AppPaths.gateBlocked,
    name: 'ageBlocked',
    builder: (_, _) => const GateBlockedScreen(),
  ),
];
