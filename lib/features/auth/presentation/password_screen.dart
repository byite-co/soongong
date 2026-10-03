// PasswordScreen (`/login/password`, userflow `lgPw lgReset lgFail`, S05):
// existing account → password; "잊었어요" sends the reset mail and shows the
// factual confirmation. Failures keep the input.

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

class PasswordScreen extends ConsumerStatefulWidget {
  const PasswordScreen({super.key});

  @override
  ConsumerState<PasswordScreen> createState() => _PasswordScreenState();
}

class _PasswordScreenState extends ConsumerState<PasswordScreen> {
  final TextEditingController _password = TextEditingController();

  @override
  void dispose() {
    _password.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    final next = await ref.read(loginControllerProvider.notifier).signInWithPassword(_password.text);
    if (mounted) followLoginNext(context, next);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final state = ref.watch(loginControllerProvider);
    final email = ref.watch(signupFlowProvider.select((s) => s.pendingEmail));
    if (email == null) {
      // Reached without an e-mail (restart / deep link) → start over.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.go(AppPaths.loginEmail);
      });
      return const Scaffold(body: SizedBox.shrink());
    }
    return FlowScaffold(
      title: AuthStrings.passwordTitle,
      onBack: () {
        ref.read(loginControllerProvider.notifier).clearError();
        context.pop();
      },
      bottom: AppButton(
        label: AuthStrings.loginTitle,
        busy: state.busy,
        busyLabel: AuthStrings.loginBusy,
        onPressed: _signIn,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(AuthStrings.passwordSubExisting(email), style: AppTypography.body.copyWith(color: c.tx2)),
          const SizedBox(height: AppSpacing.s20),
          AppTextField(
            controller: _password,
            label: AuthStrings.passwordLabel,
            hint: AuthStrings.passwordHint,
            obscure: true,
            textInputAction: TextInputAction.done,
            autofillHints: const <String>[AutofillHints.password],
            autofocus: true,
            enabled: !state.busy,
            highlightError: state.error != null,
            onChanged: (_) {
              if (state.error != null) ref.read(loginControllerProvider.notifier).clearError();
            },
            onSubmitted: (_) => _signIn(),
          ),
          const SizedBox(height: AppSpacing.s8),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              onPressed: state.busy
                  ? null
                  : () => ref.read(loginControllerProvider.notifier).sendPasswordReset(),
              style: TextButton.styleFrom(
                minimumSize: const Size(AppSpacing.touchTarget, AppSpacing.touchTarget),
                padding: EdgeInsets.zero,
                foregroundColor: c.priTx,
              ),
              child: Text(
                AuthStrings.passwordForgot,
                style: AppTypography.withWeight(AppTypography.label, 600),
              ),
            ),
          ),
          if (state.resetSent) ...<Widget>[
            const SizedBox(height: AppSpacing.s8),
            AppNotice(AuthStrings.resetSentTo(email)),
          ],
          if (state.error != null) ...<Widget>[
            const SizedBox(height: AppSpacing.s12),
            AppNotice.error(state.error!),
          ],
        ],
      ),
    );
  }
}
