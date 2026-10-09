// SignupCompleteScreen (`/signup/complete`, S05 · D6 ⑤): consent ① (계정·
// 학습기록 처리) → `complete-signup`. Shown until a `profiles` row exists —
// also after a restart right after signing up. `not_approved` ends the
// session and returns to the gate with one sentence.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/strings/auth_strings.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/widgets.dart';
import '../../../data/auth/auth_gate.dart';
import '../../../data/auth/auth_models.dart';
import '../../../data/auth/auth_providers.dart';
import '../application/signup_flow.dart';
import '../domain/auth_redirect.dart';

class SignupCompleteScreen extends ConsumerStatefulWidget {
  const SignupCompleteScreen({super.key});

  @override
  ConsumerState<SignupCompleteScreen> createState() => _SignupCompleteScreenState();
}

class _SignupCompleteScreenState extends ConsumerState<SignupCompleteScreen> {
  bool _checked = false;
  bool _busy = false;
  String? _error;

  Future<void> _confirm() async {
    if (_busy || !_checked) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    final outcome = await ref.read(authRepositoryProvider).confirmAccountConsent();
    if (!mounted) return;
    switch (outcome) {
      case SignedIn(:final profile):
        setState(() => _busy = false);
        if (profile != null) ref.read(authGateProvider.notifier).applyProfile(profile);
        context.go(AppPaths.onboardingStep(1));
      case SignInRejected(:final reason):
        setState(() => _busy = false);
        if (reason == AuthRejection.notApproved) {
          ref.read(signupFlowProvider.notifier)
            ..reset()
            ..setNotice(AuthStrings.rejectNotApproved);
          context.go(AppPaths.gate);
          return;
        }
        setState(() => _error = AuthStrings.forRejection(reason));
    }
  }

  Future<void> _switchAccount() async {
    if (_busy) return;
    setState(() => _busy = true);
    await ref.read(authRepositoryProvider).signOut();
    if (!mounted) return;
    setState(() => _busy = false);
    context.go(AppPaths.gate);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return FlowScaffold(
      title: AuthStrings.consentAccountTitle,
      bottom: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          AppButton(
            label: _checked ? AuthStrings.consentAccountCta : AuthStrings.consentAccountRequired,
            busy: _busy,
            onPressed: _checked ? _confirm : null,
          ),
          const SizedBox(height: AppSpacing.s4),
          TextButton(
            onPressed: _busy ? null : _switchAccount,
            style: TextButton.styleFrom(
              minimumSize: const Size.fromHeight(AppSpacing.touchTarget),
              foregroundColor: c.tx2,
            ),
            child: Text(AuthStrings.consentSwitchAccount, style: AppTypography.label),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(AuthStrings.consentAccountIntro, style: AppTypography.body.copyWith(color: c.tx2)),
          const SizedBox(height: AppSpacing.s20),
          for (final item in const <String>[
            AuthStrings.consentAccountItem1,
            AuthStrings.consentAccountItem2,
            AuthStrings.consentAccountItem3,
          ]) ...<Widget>[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.only(top: 3),
                  child: LucideIcon(LucideIcons.check, size: AppIcon.sizeSmall, color: c.priTx),
                ),
                const SizedBox(width: AppSpacing.s10),
                Expanded(child: Text(item, style: AppTypography.body.copyWith(color: c.tx))),
              ],
            ),
            const SizedBox(height: AppSpacing.s12),
          ],
          const SizedBox(height: AppSpacing.s8),
          AppCheckRow(
            label: AuthStrings.consentAccountCheck,
            checked: _checked,
            enabled: !_busy,
            onChanged: (v) => setState(() {
              _checked = v;
              _error = null;
            }),
          ),
          const SizedBox(height: AppSpacing.s8),
          Text(
            AuthStrings.consentVersionLabel(ConsentVersions.account),
            style: AppTypography.caption.copyWith(color: c.tx3),
          ),
          if (_error != null) ...<Widget>[
            const SizedBox(height: AppSpacing.s12),
            AppNotice.error(_error!),
          ],
        ],
      ),
    );
  }
}
