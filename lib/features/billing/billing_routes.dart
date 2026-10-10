import 'package:go_router/go_router.dart';

import '../../core/router/placeholder_screen.dart';
import '../../core/strings/billing_strings.dart';

/// Routes owned by the `billing` feature.
///
/// Exported to `core/router/app_router.dart` (S05 owns the router). Route
/// paths follow userflow node IDs (CLAUDE.md §4). Sheets and modals are not
/// routes — use `showAppSheet` / `showAppModal`.
///
/// `/paywall` (`paywall`) is reserved by S08: the statistics' 프리미엄 badge,
/// the 재구독 button of the expired wrongs card and the timetable's edit
/// sheet lock hint push it. S12 replaces the placeholder builder.
final List<RouteBase> billingRoutes = <RouteBase>[
  GoRoute(
    path: paywallPath,
    name: 'paywall',
    builder: (_, _) => const PlaceholderScreen(title: BillingStrings.paywallTitle),
  ),
];

const String paywallPath = '/paywall';
