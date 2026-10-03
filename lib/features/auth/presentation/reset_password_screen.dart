// ResetPasswordScreen (`/auth/reset`, S05 · S05b): where the router lands
// after the Supabase SDK exchanged a `soongong://auth/reset` link for a
// session (`passwordRecoveryProvider`). Waits for the auth gate, then takes
// the new password; clears the recovery flag when done or when the user asks
// for a new mail. Reachable while signed out (router exception).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/strings/auth_strings.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/widgets.dart';
import '../../../data/auth/auth_gate.dart';
import '../../../data/auth/auth_providers.dart';
import '../../../data/auth/password_recovery.dart';
import '../domain/auth_redirect.dart';

class ResetPasswordScreen extends ConsumerStatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  ConsumerState<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends ConsumerState<ResetPasswordScreen> {
  final TextEditingController _password = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_busy) return;
    if (_password.text.length < 8) {
      setState(() => _error = AuthStrings.rejectWeakPassword);
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    final reason = await ref.read(authRepositoryProvider).updatePassword(_password.text);
    if (!mounted) return;
    if (reason != null) {
      setState(() {
        _busy = false;
        _error = AuthStrings.forRejection(reason);
      });
      return;
    }
    setState(() => _busy = false);
    ref.read(passwordRecoveryProvider.notifier).clear();
    showAppToast(context, message: AuthStrings.resetDone);
    context.go(AppPaths.launch);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final gate = ref.watch(authGateProvider);
    final Widget child;
    switch (gate) {
      case AuthGateLoading():
        child = const Padding(
          padding: EdgeInsets.only(top: AppSpacing.s44),
          child: StatePanel.loading(body: AuthStrings.resetChecking),
        );
      case AuthGateSignedOut():
      case AuthGateLocalOnly():
      case AuthGateProfileError():
        child = Padding(
          padding: const EdgeInsets.only(top: AppSpacing.s44),
          child: StatePanel.error(
            title: AuthStrings.resetLinkInvalid,
            body: null,
            actionLabel: AuthStrings.resetRequestAgain,
            onAction: () {
              ref.read(passwordRecoveryProvider.notifier).clear();
              context.go(AppPaths.loginEmail);
            },
          ),
        );
      case AuthGateSignedIn():
        child = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(AuthStrings.resetSub, style: AppTypography.body.copyWith(color: c.tx2)),
            const SizedBox(height: AppSpacing.s20),
            AppTextField(
              controller: _password,
              label: AuthStrings.passwordLabel,
              hint: AuthStrings.passwordHint,
              obscure: true,
              textInputAction: TextInputAction.done,
              autofillHints: const <String>[AutofillHints.newPassword],
              autofocus: true,
              enabled: !_busy,
              highlightError: _error != null,
              onChanged: (_) {
                if (_error != null) setState(() => _error = null);
              },
              onSubmitted: (_) => _submit(),
            ),
            if (_error != null) ...<Widget>[
              const SizedBox(height: AppSpacing.s12),
              AppNotice.error(_error!),
            ],
          ],
        );
    }
    return FlowScaffold(
      title: AuthStrings.resetTitle,
      bottom: gate is AuthGateSignedIn
          ? AppButton(
              label: AuthStrings.resetCta,
              busy: _busy,
              onPressed: _submit,
            )
          : null,
      child: child,
    );
  }
}
