// SignupPasswordScreen (`/login/signup`, userflow `lgSignup`, S05): new
// e-mail account — the age ticket is already in the flow; password ≥ 8 →
// `issue-pass` → `signUp` → consent ①. An expired ticket returns to the gate.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/strings/auth_strings.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/widgets.dart';
import '../application/login_controller.dart';
import '../application/signup_flow.dart';
import '../domain/auth_redirect.dart';
import 'login_screen.dart' show followLoginNext;

class SignupPasswordScreen extends ConsumerStatefulWidget {
  const SignupPasswordScreen({super.key});

  @override
  ConsumerState<SignupPasswordScreen> createState() => _SignupPasswordScreenState();
}

class _SignupPasswordScreenState extends ConsumerState<SignupPasswordScreen> {
  final TextEditingController _password = TextEditingController();

  @override
  void dispose() {
    _password.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    final next = await ref.read(loginControllerProvider.notifier).signUpWithPassword(_password.text);
    if (mounted) followLoginNext(context, next);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final state = ref.watch(loginControllerProvider);
    final email = ref.watch(signupFlowProvider.select((s) => s.pendingEmail));
    if (email == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.go(AppPaths.loginEmail);
      });
      return const Scaffold(body: SizedBox.shrink());
    }
    return FlowScaffold(
      title: AuthStrings.loginSignupTitle,
      onBack: () {
        ref.read(loginControllerProvider.notifier).clearError();
        if (context.canPop()) {
          context.pop();
        } else {
          context.go(AppPaths.login);
        }
      },
      bottom: AppButton(
        label: AuthStrings.signupCta,
        busy: state.busy,
        busyLabel: AuthStrings.loginBusy,
        onPressed: _create,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(AuthStrings.signupSub(email), style: AppTypography.body.copyWith(color: c.tx2)),
          const SizedBox(height: AppSpacing.s20),
          AppTextField(
            controller: _password,
            label: AuthStrings.passwordLabel,
            hint: AuthStrings.passwordHint,
            obscure: true,
            textInputAction: TextInputAction.done,
            autofillHints: const <String>[AutofillHints.newPassword],
            autofocus: true,
            enabled: !state.busy,
            highlightError: state.error != null,
            onChanged: (_) {
              if (state.error != null) ref.read(loginControllerProvider.notifier).clearError();
            },
            onSubmitted: (_) => _create(),
          ),
          const SizedBox(height: AppSpacing.s8),
          Text(AuthStrings.signupNewEmailNote, style: AppTypography.caption.copyWith(color: c.tx3)),
          if (state.error != null) ...<Widget>[
            const SizedBox(height: AppSpacing.s12),
            AppNotice.error(state.error!),
          ],
        ],
      ),
    );
  }
}
