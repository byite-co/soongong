// GateBlockedScreen (`/gate/blocked`, userflow `ageBlocked`, S05 · D6 v1):
// one fact, one close button back to the first screen. No retry wording; no
// provider was called; the entered date is already gone.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/strings/auth_strings.dart';
import '../../../core/strings/common_strings.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/widgets.dart';
import '../../auth/application/signup_flow.dart';
import '../../auth/domain/auth_redirect.dart';

class GateBlockedScreen extends ConsumerWidget {
  const GateBlockedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    return FlowScaffold(
      bottom: AppButton.secondary(
        label: CommonStrings.close,
        onPressed: () {
          ref.read(signupFlowProvider.notifier).reset();
          context.go(AppPaths.gate);
        },
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const SizedBox(height: AppSpacing.s44),
          LucideIcon(LucideIcons.lock, size: AppIcon.sizeLarge, color: c.tx3),
          const SizedBox(height: AppSpacing.s16),
          Text(AuthStrings.ageBlockedTitle, style: AppTypography.title.copyWith(color: c.tx)),
          const SizedBox(height: AppSpacing.s8),
          Text(AuthStrings.ageBlockedBody, style: AppTypography.body.copyWith(color: c.tx2)),
        ],
      ),
    );
  }
}
