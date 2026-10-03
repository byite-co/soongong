// LaunchScreen (`/`, S05): shown while the auth gate reads the session and
// the profile. When the profile read fails (offline right after launch) it
// offers a retry and a way to sign in with another account.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/auth/auth_gate.dart';
import '../../data/auth/auth_providers.dart';
import '../strings/auth_strings.dart';
import '../strings/common_strings.dart';
import '../theme/app_theme.dart';
import '../theme/tokens.dart';
import '../widgets/app_button.dart';
import '../widgets/state_panel.dart';

class LaunchScreen extends ConsumerWidget {
  const LaunchScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final gate = ref.watch(authGateProvider);
    if (gate is AuthGateProfileError) {
      return Scaffold(
        body: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              StatePanel.error(
                title: AuthStrings.profileLoadFailedTitle,
                body: AuthStrings.forRejection(gate.reason),
                onAction: () => ref.read(authGateProvider.notifier).retry(),
              ),
              AppButton.secondary(
                label: AuthStrings.consentSwitchAccount,
                expand: false,
                size: AppButtonSize.small,
                onPressed: () => ref.read(authRepositoryProvider).signOut(),
              ),
            ],
          ),
        ),
      );
    }
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
