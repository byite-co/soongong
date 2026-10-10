import 'package:go_router/go_router.dart';

import '../../core/router/placeholder_screen.dart';
import '../../core/strings/wrongs_strings.dart';

/// Routes owned by the `wrongs` feature.
///
/// Exported to `core/router/app_router.dart` (S05 owns the router). Route
/// paths follow userflow node IDs (CLAUDE.md §4). Sheets and modals are not
/// routes — use `showAppSheet` / `showAppModal`.
///
/// `/wrongs` (`wrongs`) is reserved by S08: the statistics' premium wrongs
/// card links "전체 보기" here. S09 replaces the placeholder builder.
final List<RouteBase> wrongsRoutes = <RouteBase>[
  GoRoute(
    path: wrongsPath,
    name: 'wrongs',
    builder: (_, _) => const PlaceholderScreen(title: WrongsStrings.title),
  ),
];

const String wrongsPath = '/wrongs';
