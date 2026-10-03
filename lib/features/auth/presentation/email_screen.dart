// EmailScreen (`/login/email`, userflow `lgEmail`, S05): e-mail →
// `check-email` → existing: password · new: age gate first (then signup).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/strings/auth_strings.dart';
import '../../../core/strings/common_strings.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/widgets.dart';
import '../application/login_controller.dart';
import '../application/signup_flow.dart';
import 'login_screen.dart' show followLoginNext;

class EmailScreen extends ConsumerStatefulWidget {
  const EmailScreen({super.key});

  @override
  ConsumerState<EmailScreen> createState() => _EmailScreenState();
}

class _EmailScreenState extends ConsumerState<EmailScreen> {
  late final TextEditingController _email =
      TextEditingController(text: ref.read(signupFlowProvider).pendingEmail ?? '');

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _next() async {
    final next = await ref.read(loginControllerProvider.notifier).submitEmail(_email.text);
    if (mounted) followLoginNext(context, next);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final state = ref.watch(loginControllerProvider);
    return FlowScaffold(
      title: AuthStrings.emailTitle,
      onBack: () {
        ref.read(loginControllerProvider.notifier).clearError();
        context.pop();
      },
      bottom: AppButton(
        label: CommonStrings.next,
        busy: state.busy,
        busyLabel: AuthStrings.ageGateChecking,
        onPressed: _next,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(AuthStrings.emailSub, style: AppTypography.body.copyWith(color: c.tx2)),
          const SizedBox(height: AppSpacing.s20),
          AppTextField(
            controller: _email,
            label: AuthStrings.emailLabel,
            hint: AuthStrings.emailHint,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            autofillHints: const <String>[AutofillHints.email],
            autofocus: true,
            enabled: !state.busy,
            highlightError: state.error != null,
            onChanged: (_) {
              if (state.error != null) ref.read(loginControllerProvider.notifier).clearError();
            },
            onSubmitted: (_) => _next(),
          ),
          if (state.error != null) ...<Widget>[
            const SizedBox(height: AppSpacing.s12),
            AppNotice.error(state.error!),
          ],
          const SizedBox(height: AppSpacing.s12),
          Text(AuthStrings.emailFoot, style: AppTypography.caption.copyWith(color: c.tx3)),
        ],
      ),
    );
  }
}
