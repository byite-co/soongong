// AppButton (S01): primary / secondary / destructive, with built-in
// in-progress lock (CLAUDE.md §7: async UI actions must not run twice).

import 'dart:async';

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../theme/tokens.dart';

enum AppButtonVariant { primary, secondary, destructive }

enum AppButtonSize {
  large(AppLayout.buttonLarge, AppRadius.button),
  medium(AppLayout.buttonMedium, AppRadius.button),
  small(AppLayout.buttonSmall, AppRadius.buttonSmall);

  const AppButtonSize(this.height, this.radius);

  final double height;
  final double radius;
}

class AppButton extends StatefulWidget {
  const AppButton({
    super.key,
    required this.label,
    this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.size = AppButtonSize.medium,
    this.expand = true,
    this.icon,
    this.busy = false,
    this.busyLabel,
  });

  const AppButton.secondary({
    super.key,
    required this.label,
    this.onPressed,
    this.size = AppButtonSize.medium,
    this.expand = true,
    this.icon,
    this.busy = false,
    this.busyLabel,
  }) : variant = AppButtonVariant.secondary;

  const AppButton.destructive({
    super.key,
    required this.label,
    this.onPressed,
    this.size = AppButtonSize.medium,
    this.expand = true,
    this.icon,
    this.busy = false,
    this.busyLabel,
  }) : variant = AppButtonVariant.destructive;

  final String label;

  /// Sync or async. While an async callback runs the button is locked and
  /// shows a progress indicator; re-taps are ignored.
  final FutureOr<void> Function()? onPressed;
  final AppButtonVariant variant;
  final AppButtonSize size;
  final bool expand;
  final IconData? icon;

  /// External lock (e.g. a form-level "saving" state).
  final bool busy;
  final String? busyLabel;

  @override
  State<AppButton> createState() => _AppButtonState();
}

class _AppButtonState extends State<AppButton> {
  bool _running = false;
  bool _pressed = false;

  bool get _locked => _running || widget.busy;
  bool get _enabled => widget.onPressed != null && !_locked;

  Future<void> _handleTap() async {
    if (!_enabled) return;
    final cb = widget.onPressed!;
    setState(() => _running = true);
    try {
      await cb();
    } finally {
      if (mounted) setState(() => _running = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final (Color bg, Color fg) = switch (widget.variant) {
      AppButtonVariant.primary => (c.pri, c.onPri),
      AppButtonVariant.secondary => (c.sunk, c.tx2),
      AppButtonVariant.destructive => (c.acc, c.onAcc),
    };
    final disabled = widget.onPressed == null;
    final bgColor = disabled ? c.sunk : bg;
    final fgColor = disabled ? c.tx3 : fg;
    final base = widget.size == AppButtonSize.small
        ? AppTypography.label
        : AppTypography.body;
    final style = AppTypography.withWeight(base, 600).copyWith(
      color: fgColor,
      height: 1.2,
    );
    final label = _locked && widget.busyLabel != null
        ? widget.busyLabel!
        : widget.label;

    final child = Row(
      mainAxisSize: widget.expand ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        if (_locked)
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.s8),
            child: SizedBox(
              width: AppIcon.sizeSmall,
              height: AppIcon.sizeSmall,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: fgColor,
              ),
            ),
          )
        else if (widget.icon != null)
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.s8),
            child: Icon(widget.icon, size: AppIcon.sizeSmall, color: fgColor),
          ),
        Flexible(
          child: Text(
            label,
            style: style,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );

    final reduced = AppMotion.reduced(context);
    final visual = AnimatedScale(
      scale: _pressed && !reduced ? 0.97 : 1,
      duration: reduced ? Duration.zero : const Duration(milliseconds: 90),
      child: Container(
        height: widget.size.height,
        width: widget.expand ? double.infinity : null,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s16),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(widget.size.radius),
        ),
        alignment: Alignment.center,
        child: child,
      ),
    );

    // The tap area itself is ≥ 44 tall (S01b): the visual box (42 for
    // `small`) is centred inside the GestureDetector, not padded outside it.
    return Semantics(
      button: true,
      enabled: _enabled,
      label: label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: _enabled ? (_) => setState(() => _pressed = true) : null,
        onTapCancel: () => setState(() => _pressed = false),
        onTapUp: (_) => setState(() => _pressed = false),
        onTap: _enabled ? _handleTap : null,
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            minHeight: AppSpacing.touchTarget,
            minWidth: AppSpacing.touchTarget,
          ),
          child: Center(
            widthFactor: widget.expand ? null : 1,
            child: visual,
          ),
        ),
      ),
    );
  }
}
