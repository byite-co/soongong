// AppModal (S01): confirmation dialog — title · body · primary/secondary
// buttons · destructive style. Modals are not routes (CLAUDE.md §4).

import 'dart:async';

import 'package:flutter/material.dart';

import '../strings/common_strings.dart';
import '../theme/app_theme.dart';
import '../theme/tokens.dart';
import 'app_button.dart';

/// Returns `true` when the primary action completed, `false` when the
/// secondary action was chosen, `null` when dismissed.
Future<bool?> showAppModal(
  BuildContext context, {
  required String title,
  String? body,
  required String primaryLabel,
  String secondaryLabel = CommonStrings.cancel,
  bool destructive = false,
  FutureOr<void> Function()? onPrimary,
  bool barrierDismissible = true,
  bool useRootNavigator = true,
}) {
  final c = context.colors;
  final reduced = AppMotion.reduced(context);
  return showGeneralDialog<bool>(
    context: context,
    useRootNavigator: useRootNavigator,
    barrierDismissible: barrierDismissible,
    barrierLabel: title,
    barrierColor: c.scrim,
    transitionDuration: reduced ? Duration.zero : AppMotion.pop,
    transitionBuilder: (_, anim, _, child) => FadeTransition(
      opacity: anim,
      child: ScaleTransition(
        scale: Tween<double>(begin: 0.96, end: 1).animate(
          CurvedAnimation(parent: anim, curve: AppMotion.sheetCurve),
        ),
        child: child,
      ),
    ),
    pageBuilder: (ctx, _, _) => AppModal(
      title: title,
      body: body,
      primaryLabel: primaryLabel,
      secondaryLabel: secondaryLabel,
      destructive: destructive,
      onPrimary: () async {
        if (onPrimary != null) await onPrimary();
        if (ctx.mounted) Navigator.of(ctx).pop(true);
      },
      onSecondary: () => Navigator.of(ctx).pop(false),
    ),
  );
}

class AppModal extends StatelessWidget {
  const AppModal({
    super.key,
    required this.title,
    this.body,
    required this.primaryLabel,
    this.secondaryLabel = CommonStrings.cancel,
    this.destructive = false,
    this.onPrimary,
    this.onSecondary,
  });

  final String title;
  final String? body;
  final String primaryLabel;
  final String secondaryLabel;
  final bool destructive;
  final FutureOr<void> Function()? onPrimary;
  final VoidCallback? onSecondary;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppLayout.dialogHorizontalInset,
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: AppLayout.dialogMaxWidth),
            child: Material(
              color: c.surface,
              borderRadius: BorderRadius.circular(AppRadius.dialog),
              clipBehavior: Clip.antiAlias,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.page,
                  vertical: AppSpacing.s24,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    Semantics(
                      header: true,
                      child: Text(
                        title,
                        textAlign: TextAlign.center,
                        style: AppTypography.heading.copyWith(color: c.tx),
                      ),
                    ),
                    if (body != null)
                      Padding(
                        padding: const EdgeInsets.only(
                          top: AppSpacing.s8,
                          left: AppSpacing.s6,
                          right: AppSpacing.s6,
                        ),
                        child: Text(
                          body!,
                          textAlign: TextAlign.center,
                          style: AppTypography.label.copyWith(
                            color: c.tx2,
                            height: 1.6,
                          ),
                        ),
                      ),
                    const SizedBox(height: AppSpacing.s20),
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: AppButton.secondary(
                            label: secondaryLabel,
                            onPressed: onSecondary,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.s8),
                        Expanded(
                          child: destructive
                              ? AppButton.destructive(
                                  label: primaryLabel,
                                  onPressed: onPrimary,
                                )
                              : AppButton(
                                  label: primaryLabel,
                                  onPressed: onPrimary,
                                ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
