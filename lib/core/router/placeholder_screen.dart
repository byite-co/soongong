// PlaceholderScreen (S05): stands in for routes reserved for other lanes
// (docs/routes.md) until their session replaces it. Facts only.

import 'package:flutter/material.dart';

import '../strings/common_strings.dart';
import '../theme/app_theme.dart';
import '../widgets/lucide_icon.dart';
import '../widgets/state_panel.dart';

class PlaceholderScreen extends StatelessWidget {
  const PlaceholderScreen({super.key, required this.title, this.inTab = false});

  final String title;

  /// Tab roots have no back button; pushed routes get an app bar.
  final bool inTab;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Scaffold(
      appBar: inTab
          ? null
          : AppBar(
              title: Text(title),
              backgroundColor: c.bg,
              surfaceTintColor: Colors.transparent,
            ),
      body: SafeArea(
        child: StatePanel.empty(
          title: title,
          body: CommonStrings.placeholderPreparing,
          icon: LucideIcons.construction,
        ),
      ),
    );
  }
}
