import 'package:go_router/go_router.dart';

import '../../core/router/placeholder_screen.dart';
import '../../core/strings/reading_strings.dart';

/// Routes owned by the `reading` feature.
///
/// Exported to `core/router/app_router.dart` (S05 owns the router). Route
/// paths follow userflow node IDs (CLAUDE.md §4). Sheets and modals are not
/// routes — use `showAppSheet` / `showAppModal`.
///
/// `/reading/capture` (`capture`) is reserved by S07: the planner's 판독
/// button pushes `/reading/capture?from=planner&itemId=<plannerItemId>`
/// (D27: the item's `range_text`, else its title, is the reading range).
/// S10 replaces the placeholder builder and reads both query parameters.
final List<RouteBase> readingRoutes = <RouteBase>[
  GoRoute(
    path: readingCapturePath,
    name: 'capture',
    builder: (_, _) => const PlaceholderScreen(title: ReadingStrings.captureTitle),
  ),
];

const String readingCapturePath = '/reading/capture';

/// `/reading/capture?from=planner&itemId=…` (S07 → S10 hand-off).
String readingCaptureFromPlanner(String plannerItemId) =>
    Uri(path: readingCapturePath, queryParameters: <String, String>{'from': 'planner', 'itemId': plannerItemId})
        .toString();
