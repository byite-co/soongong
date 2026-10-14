import 'package:go_router/go_router.dart';

import 'presentation/subjects_screen.dart';

/// Routes owned by the `subjects` feature (S09, prototype 13 · N11 · B8).
///
/// Exported to `core/router/app_router.dart` (S05 owns the router). The
/// add/edit sheet and the delete confirmation are not routes.
final List<RouteBase> subjectsRoutes = <RouteBase>[
  GoRoute(
    path: subjectsPath,
    name: 'subjects',
    builder: (_, _) => const SubjectsScreen(),
  ),
];

const String subjectsPath = '/settings/subjects';
