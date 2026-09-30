// Temporary splash for `/` (S01). S05 replaces this with the real routing
// (login → onboarding → home).

import 'package:flutter/material.dart';

import '../strings/common_strings.dart';
import '../theme/app_theme.dart';
import '../theme/tokens.dart';

class TempSplashScreen extends StatelessWidget {
  const TempSplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(
              CommonStrings.appName,
              style: AppTypography.display.copyWith(color: c.tx),
            ),
            const SizedBox(height: AppSpacing.s8),
            Text(
              CommonStrings.splashPreparing,
              style: AppTypography.label.copyWith(color: c.tx3),
            ),
          ],
        ),
      ),
    );
  }
}
