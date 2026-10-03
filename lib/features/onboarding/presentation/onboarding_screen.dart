// OnboardingScreen (`/onboarding/1..3`, userflow `ob1 ob2 ob3 t4`, S05):
// (1) 순공 측정 안내 → (2) 판독 동의 ② (no guardian box, D6 v1) → (3) 카메라
// 권한 → `profile_set_onboarding_done()` → home (empty state). Centred at
// 600 dp on tablets.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/strings/onboarding_strings.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/widgets.dart';
import '../../auth/domain/auth_redirect.dart';
import '../application/camera_permission.dart';
import '../application/onboarding_controller.dart';

class OnboardingScreen extends ConsumerWidget {
  const OnboardingScreen({super.key, required this.step});

  final int step;

  void _go(BuildContext context, int next) => context.go(AppPaths.onboardingStep(next));

  Future<void> _finish(BuildContext context, WidgetRef ref, {required bool camera}) async {
    final ctl = ref.read(onboardingControllerProvider.notifier);
    final ok = await ctl.finish(requestCamera: camera);
    if (!context.mounted || !ok) return;
    final result = ref.read(onboardingControllerProvider).cameraResult;
    if (camera && result != null && result != CameraPermissionResult.granted) {
      showAppToast(context, message: OnboardingStrings.cameraDenied);
    }
    context.go(AppPaths.home);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final state = ref.watch(onboardingControllerProvider);
    final ctl = ref.read(onboardingControllerProvider.notifier);

    final (String primaryLabel, Future<void> Function()? onPrimary) = switch (step) {
      1 => (OnboardingStrings.next, () async => _go(context, 2)),
      2 => (
          state.consentChecked ? OnboardingStrings.consentNext : OnboardingStrings.consentRequired,
          state.consentChecked
              ? () async {
                  final ok = await ctl.grantReadingConsent();
                  if (ok && context.mounted) _go(context, 3);
                }
              : null,
        ),
      _ => (OnboardingStrings.cameraAllowStart, () => _finish(context, ref, camera: true)),
    };
    final (String secondaryLabel, Future<void> Function() onSecondary) = switch (step) {
      1 => (OnboardingStrings.skip, () async => _go(context, 2)),
      2 => (
          OnboardingStrings.consentSkip,
          () async {
            final ok = await ctl.skipReadingConsent();
            if (ok && context.mounted) _go(context, 3);
          },
        ),
      _ => (OnboardingStrings.manualStart, () => _finish(context, ref, camera: false)),
    };

    return FlowScaffold(
      onBack: step > 1
          ? () {
              ctl.clearError();
              _go(context, step - 1);
            }
          : null,
      bottom: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          AppButton(
            label: primaryLabel,
            busy: state.busy,
            busyLabel: step == 2 ? OnboardingStrings.consentSaving : OnboardingStrings.finishing,
            onPressed: onPrimary,
          ),
          const SizedBox(height: AppSpacing.s4),
          TextButton(
            onPressed: state.busy ? null : onSecondary,
            style: TextButton.styleFrom(
              minimumSize: const Size.fromHeight(AppSpacing.touchTarget),
              foregroundColor: c.tx2,
            ),
            child: Text(secondaryLabel, style: AppTypography.label),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const SizedBox(height: AppSpacing.s12),
          _StepDots(step: step),
          const SizedBox(height: AppSpacing.s20),
          switch (step) {
            1 => const _Step1(),
            2 => _Step2(
                checked: state.consentChecked,
                enabled: !state.busy,
                onChanged: ctl.setConsentChecked,
              ),
            _ => const _Step3(),
          },
          if (state.error != null) ...<Widget>[
            const SizedBox(height: AppSpacing.s16),
            AppNotice.error(state.error!),
          ],
        ],
      ),
    );
  }
}

class _StepDots extends StatelessWidget {
  const _StepDots({required this.step});

  final int step;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Row(
      children: <Widget>[
        for (var i = 1; i <= 3; i++) ...<Widget>[
          Container(
            width: i == step ? 18 : 6,
            height: 6,
            decoration: BoxDecoration(
              color: i <= step ? c.pri : c.line,
              borderRadius: BorderRadius.circular(AppRadius.pill),
            ),
          ),
          const SizedBox(width: AppSpacing.s6),
        ],
        const SizedBox(width: AppSpacing.s6),
        Text(
          OnboardingStrings.stepOf(step),
          style: AppTypography.caption.copyWith(color: c.tx3, fontFeatures: AppTypography.tabularFigures),
        ),
      ],
    );
  }
}

class _Title extends StatelessWidget {
  const _Title(this.title, this.body);

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(title, style: AppTypography.title.copyWith(color: c.tx)),
        const SizedBox(height: AppSpacing.s10),
        Text(body, style: AppTypography.body.copyWith(color: c.tx2)),
      ],
    );
  }
}

class _FactRow extends StatelessWidget {
  const _FactRow(this.icon, this.text);

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.s10),
      child: Row(
        children: <Widget>[
          LucideIcon(icon, size: AppIcon.sizeSmall + 2, color: c.priTx),
          const SizedBox(width: AppSpacing.s12),
          Expanded(child: Text(text, style: AppTypography.body.copyWith(color: c.tx))),
        ],
      ),
    );
  }
}

class _Step1 extends StatelessWidget {
  const _Step1();

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const _Title(OnboardingStrings.step1Title, OnboardingStrings.step1Body),
        const SizedBox(height: AppSpacing.s20),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s16, vertical: AppSpacing.s4),
          decoration: BoxDecoration(
            color: c.surface,
            borderRadius: BorderRadius.circular(AppRadius.r16),
            border: Border.all(color: c.line),
          ),
          child: Column(
            children: <Widget>[
              const _FactRow(LucideIcons.eyeOff, OnboardingStrings.step1Fact1),
              Divider(height: 1, color: c.line),
              const _FactRow(LucideIcons.smartphone, OnboardingStrings.step1Fact2),
              Divider(height: 1, color: c.line),
              const _FactRow(LucideIcons.clock, OnboardingStrings.step1Fact3),
            ],
          ),
        ),
      ],
    );
  }
}

class _Step2 extends StatelessWidget {
  const _Step2({required this.checked, required this.enabled, required this.onChanged});

  final bool checked;
  final bool enabled;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const _Title(OnboardingStrings.step2Title, OnboardingStrings.step2Body),
        const SizedBox(height: AppSpacing.s20),
        Container(
          padding: const EdgeInsets.all(AppSpacing.s16),
          decoration: BoxDecoration(
            color: c.surface,
            borderRadius: BorderRadius.circular(AppRadius.r16),
            border: Border.all(color: c.line),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      OnboardingStrings.step2CardTitle,
                      style: AppTypography.withWeight(AppTypography.label, 600).copyWith(color: c.tx),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.s8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s8, vertical: AppSpacing.s2),
                    decoration: BoxDecoration(
                      color: c.accWeak,
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                    ),
                    child: Text(
                      OnboardingStrings.step2Premium,
                      style: AppTypography.withWeight(AppTypography.caption, 600).copyWith(color: c.accTx),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.s6),
              Text(OnboardingStrings.step2CardSub, style: AppTypography.caption.copyWith(color: c.tx3)),
              const SizedBox(height: AppSpacing.s14),
              for (final s in const <String>[
                OnboardingStrings.consent1,
                OnboardingStrings.consent2,
                OnboardingStrings.consent3,
              ])
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.s8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Padding(
                        padding: const EdgeInsets.only(top: 3),
                        child: LucideIcon(LucideIcons.check, size: AppIcon.sizeSmall, color: c.priTx),
                      ),
                      const SizedBox(width: AppSpacing.s8),
                      Expanded(child: Text(s, style: AppTypography.label.copyWith(color: c.tx))),
                    ],
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.s16),
        AppCheckRow(
          label: OnboardingStrings.consentCheck,
          checked: checked,
          enabled: enabled,
          onChanged: onChanged,
        ),
      ],
    );
  }
}

class _Step3 extends StatelessWidget {
  const _Step3();

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const _Title(OnboardingStrings.step3Title, OnboardingStrings.step3Body),
        const SizedBox(height: AppSpacing.s24),
        Center(
          child: Container(
            width: 120,
            height: 120,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: c.priWeak,
              borderRadius: BorderRadius.circular(AppRadius.r26),
            ),
            child: LucideIcon(LucideIcons.camera, size: 44, color: c.priTx),
          ),
        ),
      ],
    );
  }
}
