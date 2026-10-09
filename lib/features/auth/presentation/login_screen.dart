// LoginScreen (`/login`, userflow `login lgBusy lgFail`, S05 · PRD 4.3c):
// Apple · Google · 카카오 · 이메일. With an age ticket in the flow this is the
// provider choice of a new account ("계정 만들기"); without one it is the
// existing-account sign-in, with a "처음이에요 → 계정 만들기" branch to the gate.

import 'package:flutter/foundation.dart' show TargetPlatform, defaultTargetPlatform;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/strings/auth_strings.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/widgets.dart';
import '../../../data/auth/auth_models.dart';
import '../../../data/auth/auth_providers.dart';
import '../application/login_controller.dart';
import '../application/signup_flow.dart';
import '../domain/auth_redirect.dart';
import 'widgets/provider_button.dart';

/// Shared by every login screen: where to go after a controller call.
void followLoginNext(BuildContext context, LoginNext next) {
  switch (next) {
    case LoginNext.none:
      break;
    case LoginNext.gate:
      context.go(AppPaths.gate);
    case LoginNext.password:
      context.push(AppPaths.loginPassword);
    case LoginNext.signup:
      context.go(AppPaths.loginSignup);
    case LoginNext.consent:
      context.go(AppPaths.signupComplete);
    case LoginNext.onboarding:
      context.go(AppPaths.onboardingStep(1));
    case LoginNext.home:
      context.go(AppPaths.home);
    case LoginNext.launch:
      context.go(AppPaths.launch);
  }
}

class LoginScreen extends ConsumerWidget {
  const LoginScreen({super.key});

  static const List<SignupProvider> _socialOrder = <SignupProvider>[
    SignupProvider.apple,
    SignupProvider.google,
    SignupProvider.kakao,
  ];

  List<SignupProvider> _providers(WidgetRef ref) {
    final social = ref.read(socialSignInProvider);
    final list = _socialOrder.where(social.isAvailable).toList();
    // iOS: Apple first (platform guide). Elsewhere Apple is not offered in v1.
    if (defaultTargetPlatform != TargetPlatform.iOS) {
      list.remove(SignupProvider.apple);
      if (social.isAvailable(SignupProvider.apple)) list.add(SignupProvider.apple);
    }
    return list;
  }

  Future<void> _social(BuildContext context, WidgetRef ref, SignupProvider p) async {
    final next = await ref.read(loginControllerProvider.notifier).signInWithSocial(p);
    if (context.mounted) followLoginNext(context, next);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final state = ref.watch(loginControllerProvider);
    final flow = ref.watch(signupFlowProvider);
    final signup = flow.hasTicket;
    final providers = _providers(ref);

    final body = FlowScaffold(
      title: signup ? AuthStrings.loginSignupTitle : AuthStrings.loginTitle,
      onBack: signup
          ? () {
              ref.read(signupFlowProvider.notifier).reset();
              context.go(AppPaths.gate);
            }
          : null,
      bottom: signup
          ? null
          : TextButton(
              onPressed: state.busy
                  ? null
                  : () {
                      ref.read(signupFlowProvider.notifier).reset();
                      context.go(AppPaths.gate);
                    },
              style: TextButton.styleFrom(
                minimumSize: const Size.fromHeight(AppSpacing.touchTarget),
                foregroundColor: c.priTx,
              ),
              child: Text(
                AuthStrings.loginNewAccount,
                style: AppTypography.withWeight(AppTypography.label, 600),
              ),
            ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const SizedBox(height: AppSpacing.s24),
          Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: c.pri,
              borderRadius: BorderRadius.circular(AppRadius.r14),
            ),
            child: Text(
              '순',
              style: AppTypography.withWeight(AppTypography.heading, 700).copyWith(color: c.onPri),
            ),
          ),
          const SizedBox(height: AppSpacing.s20),
          Text(AuthStrings.loginTagline, style: AppTypography.title.copyWith(color: c.tx)),
          const SizedBox(height: AppSpacing.s8),
          Text(AuthStrings.loginSub, style: AppTypography.label.copyWith(color: c.tx2)),
          if (flow.notice != null) ...<Widget>[
            const SizedBox(height: AppSpacing.s16),
            AppNotice(flow.notice!),
          ],
          if (state.error != null) ...<Widget>[
            const SizedBox(height: AppSpacing.s16),
            AppNotice.error(state.error!),
          ],
          const SizedBox(height: AppSpacing.s24),
          for (final p in providers) ...<Widget>[
            ProviderButton(
              provider: p,
              label: switch (p) {
                SignupProvider.apple => AuthStrings.loginApple,
                SignupProvider.google => AuthStrings.loginGoogle,
                SignupProvider.kakao => AuthStrings.loginKakao,
                SignupProvider.email => AuthStrings.loginEmail,
              },
              enabled: !state.busy,
              onPressed: () => _social(context, ref, p),
            ),
            const SizedBox(height: AppSpacing.s10),
          ],
          const SizedBox(height: AppSpacing.s6),
          ProviderButton(
            provider: SignupProvider.email,
            label: AuthStrings.loginEmail,
            enabled: !state.busy,
            onPressed: () {
              ref.read(loginControllerProvider.notifier).clearError();
              if (signup && flow.pendingEmail != null) {
                context.push(AppPaths.loginSignup);
              } else {
                context.push(AppPaths.loginEmail);
              }
            },
          ),
          const SizedBox(height: AppSpacing.s16),
          Text(
            AuthStrings.loginTerms,
            textAlign: TextAlign.center,
            style: AppTypography.caption.copyWith(color: c.tx3),
          ),
        ],
      ),
    );

    return Stack(
      children: <Widget>[
        body,
        if (state.busy && state.busyLabel != null)
          Positioned.fill(
            child: Semantics(
              liveRegion: true,
              label: state.busyLabel,
              child: AbsorbPointer(
                child: ColoredBox(
                  color: c.scrim,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.s20,
                        vertical: AppSpacing.s16,
                      ),
                      decoration: BoxDecoration(
                        color: c.surface,
                        borderRadius: BorderRadius.circular(AppRadius.r16),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          SizedBox(
                            width: AppIcon.sizeSmall + 2,
                            height: AppIcon.sizeSmall + 2,
                            child: CircularProgressIndicator(strokeWidth: 2, color: c.pri),
                          ),
                          const SizedBox(width: AppSpacing.s12),
                          Text(state.busyLabel!, style: AppTypography.body.copyWith(color: c.tx)),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
