// AppToast (S01): bottom toast with an optional action; the undo variant
// stays for 5 seconds (D22 · CLAUDE.md §5). One toast at a time.

import 'dart:async';

import 'package:flutter/material.dart';

import '../strings/common_strings.dart';
import '../theme/app_theme.dart';
import '../theme/tokens.dart';
import 'lucide_icon.dart';

const Duration kToastDuration = Duration(milliseconds: 2600);

/// Shows a toast above the bottom safe area. Replaces any visible toast.
void showAppToast(
  BuildContext context, {
  required String message,
  String? actionLabel,
  VoidCallback? onAction,
  Duration duration = kToastDuration,
  IconData? icon,
  double bottomOffset = 40,
}) {
  AppToastController.instance.show(
    context,
    message: message,
    actionLabel: actionLabel,
    onAction: onAction,
    duration: duration,
    icon: icon,
    bottomOffset: bottomOffset,
  );
}

/// Undo toast: 5-second window, `되돌리기` action. [onUndo] runs at most
/// once; the caller commits the deletion when the window elapses (D22).
void showUndoToast(
  BuildContext context, {
  required String message,
  required VoidCallback onUndo,
  double bottomOffset = 40,
}) {
  showAppToast(
    context,
    message: message,
    actionLabel: CommonStrings.undo,
    onAction: onUndo,
    duration: AppMotion.undoWindow,
    icon: LucideIcons.rotateCcw,
    bottomOffset: bottomOffset,
  );
}

void hideAppToast() => AppToastController.instance.hide();

class AppToastController {
  AppToastController._();

  static final AppToastController instance = AppToastController._();

  OverlayEntry? _entry;
  Timer? _timer;

  bool get isVisible => _entry != null;

  void show(
    BuildContext context, {
    required String message,
    String? actionLabel,
    VoidCallback? onAction,
    required Duration duration,
    IconData? icon,
    required double bottomOffset,
  }) {
    hide();
    final overlay = Overlay.of(context, rootOverlay: true);
    var acted = false;
    late final OverlayEntry entry;
    entry = OverlayEntry(
      builder: (ctx) => Positioned(
        left: AppSpacing.page,
        right: AppSpacing.page,
        bottom: MediaQuery.paddingOf(ctx).bottom + bottomOffset,
        child: _ToastEntrance(
          child: AppToast(
            message: message,
            icon: icon,
            actionLabel: actionLabel,
            onAction: onAction == null
                ? null
                : () {
                    if (acted) return;
                    acted = true;
                    hide();
                    onAction();
                  },
          ),
        ),
      ),
    );
    _entry = entry;
    overlay.insert(entry);
    _timer = Timer(duration, hide);
  }

  void hide() {
    _timer?.cancel();
    _timer = null;
    _entry?.remove();
    _entry = null;
  }
}

class _ToastEntrance extends StatelessWidget {
  const _ToastEntrance({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (AppMotion.reduced(context)) return child;
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: AppMotion.toastIn,
      curve: AppMotion.sheetCurve,
      builder: (_, v, c) => Opacity(
        opacity: v,
        child: Transform.translate(offset: Offset(0, (1 - v) * 12), child: c),
      ),
      child: child,
    );
  }
}

/// Visual toast (stateless) — also used by the gallery.
class AppToast extends StatelessWidget {
  const AppToast({
    super.key,
    required this.message,
    this.icon,
    this.actionLabel,
    this.onAction,
  });

  final String message;
  final IconData? icon;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Semantics(
      liveRegion: true,
      child: Material(
        color: c.toastBg,
        borderRadius: BorderRadius.circular(AppRadius.toast),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.s14,
            vertical: AppSpacing.s12,
          ),
          child: Row(
            children: <Widget>[
              if (icon != null) ...<Widget>[
                LucideIcon.small(icon!, color: c.toastFg),
                const SizedBox(width: AppSpacing.s10),
              ],
              Expanded(
                child: Text(
                  message,
                  style: AppTypography.label.copyWith(
                    color: c.toastFg,
                    height: 1.45,
                  ),
                ),
              ),
              if (actionLabel != null) ...<Widget>[
                const SizedBox(width: AppSpacing.s10),
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: onAction,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.s8,
                      horizontal: AppSpacing.s4,
                    ),
                    child: Text(
                      actionLabel!,
                      style: AppTypography.withWeight(AppTypography.label, 600)
                          .copyWith(color: c.toastAction, height: 1.2),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
