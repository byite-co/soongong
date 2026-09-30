// AppModal (S01 · S01b): confirmation dialog — title · body · primary /
// secondary buttons · destructive style · in-progress lock.
// Modals are not routes (CLAUDE.md §4).
//
// Lock (S01b): while [onConfirm] runs, the barrier tap, the back gesture and
// the secondary button are all ignored. `true` is returned only after
// [onConfirm] completed without throwing (or immediately when there is no
// [onConfirm]); `false` means the action did not run. An exception keeps the
// modal open and shows an error line so the user can retry or cancel.

import 'package:flutter/material.dart';

import '../logging/app_logger.dart';
import '../strings/common_strings.dart';
import '../theme/app_theme.dart';
import '../theme/tokens.dart';
import 'app_button.dart';

Future<bool> showAppModal(
  BuildContext context, {
  required String title,
  String? body,
  required String primaryLabel,
  String secondaryLabel = CommonStrings.cancel,
  bool destructive = false,
  Future<void> Function()? onConfirm,
  bool barrierDismissible = true,
  bool useRootNavigator = true,
}) async {
  final c = context.colors;
  final reduced = AppMotion.reduced(context);
  final result = await showGeneralDialog<bool>(
    context: context,
    useRootNavigator: useRootNavigator,
    // The barrier is handled inside the page so it can be locked at runtime.
    barrierDismissible: false,
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
    pageBuilder: (_, _, _) => _AppModalPage(
      title: title,
      body: body,
      primaryLabel: primaryLabel,
      secondaryLabel: secondaryLabel,
      destructive: destructive,
      onConfirm: onConfirm,
      barrierDismissible: barrierDismissible,
    ),
  );
  return result ?? false;
}

class _AppModalPage extends StatefulWidget {
  const _AppModalPage({
    required this.title,
    required this.body,
    required this.primaryLabel,
    required this.secondaryLabel,
    required this.destructive,
    required this.onConfirm,
    required this.barrierDismissible,
  });

  final String title;
  final String? body;
  final String primaryLabel;
  final String secondaryLabel;
  final bool destructive;
  final Future<void> Function()? onConfirm;
  final bool barrierDismissible;

  @override
  State<_AppModalPage> createState() => _AppModalPageState();
}

class _AppModalPageState extends State<_AppModalPage> {
  bool _running = false;
  String? _error;

  void _dismiss() {
    if (_running) return;
    Navigator.of(context).pop(false);
  }

  Future<void> _confirm() async {
    if (_running) return;
    final cb = widget.onConfirm;
    if (cb == null) {
      Navigator.of(context).pop(true);
      return;
    }
    setState(() {
      _running = true;
      _error = null;
    });
    try {
      await cb();
      if (mounted) Navigator.of(context).pop(true);
    } catch (e, st) {
      appLog.w('AppModal onConfirm failed', error: e, stackTrace: st);
      if (mounted) {
        setState(() {
          _running = false;
          _error = CommonStrings.actionFailedRetry;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _dismiss();
      },
      child: Stack(
        children: <Widget>[
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: widget.barrierDismissible && !_running ? _dismiss : null,
              child: const SizedBox.expand(),
            ),
          ),
          AppModal(
            title: widget.title,
            body: widget.body,
            primaryLabel: widget.primaryLabel,
            secondaryLabel: widget.secondaryLabel,
            destructive: widget.destructive,
            running: _running,
            errorText: _error,
            onPrimary: _confirm,
            onSecondary: _dismiss,
          ),
        ],
      ),
    );
  }
}

/// Visual modal (stateless). [running] locks the secondary button and shows
/// progress on the primary one; [errorText] fills the error slot.
class AppModal extends StatelessWidget {
  const AppModal({
    super.key,
    required this.title,
    this.body,
    required this.primaryLabel,
    this.secondaryLabel = CommonStrings.cancel,
    this.destructive = false,
    this.running = false,
    this.errorText,
    this.onPrimary,
    this.onSecondary,
  });

  final String title;
  final String? body;
  final String primaryLabel;
  final String secondaryLabel;
  final bool destructive;
  final bool running;
  final String? errorText;
  final VoidCallback? onPrimary;
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
                    if (errorText != null)
                      Padding(
                        padding: const EdgeInsets.only(top: AppSpacing.s10),
                        child: Semantics(
                          liveRegion: true,
                          child: Text(
                            errorText!,
                            textAlign: TextAlign.center,
                            style: AppTypography.withWeight(AppTypography.label, 600)
                                .copyWith(color: c.accTx),
                          ),
                        ),
                      ),
                    const SizedBox(height: AppSpacing.s20),
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: AppButton.secondary(
                            label: secondaryLabel,
                            onPressed: running ? null : onSecondary,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.s8),
                        Expanded(
                          child: destructive
                              ? AppButton.destructive(
                                  label: primaryLabel,
                                  busy: running,
                                  onPressed: onPrimary,
                                )
                              : AppButton(
                                  label: primaryLabel,
                                  busy: running,
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
