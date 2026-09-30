// StatePanel (S01): shared loading / empty / error panel with a next-action
// button (CLAUDE.md §5 — empty states always offer the next action).

import 'package:flutter/material.dart';

import '../strings/common_strings.dart';
import '../theme/app_theme.dart';
import '../theme/tokens.dart';
import 'app_button.dart';
import 'lucide_icon.dart';

enum StatePanelKind { loading, empty, error }

class StatePanel extends StatelessWidget {
  const StatePanel({
    super.key,
    required this.kind,
    this.title,
    this.body,
    this.icon,
    this.actionLabel,
    this.onAction,
  });

  const StatePanel.loading({super.key, this.body = CommonStrings.loading})
      : kind = StatePanelKind.loading,
        title = null,
        icon = null,
        actionLabel = null,
        onAction = null;

  const StatePanel.empty({
    super.key,
    this.title = CommonStrings.emptyTitle,
    this.body,
    this.icon = LucideIcons.inbox,
    this.actionLabel,
    this.onAction,
  }) : kind = StatePanelKind.empty;

  const StatePanel.error({
    super.key,
    this.title = CommonStrings.errorTitle,
    this.body = CommonStrings.errorBody,
    this.icon = LucideIcons.circleAlert,
    this.actionLabel = CommonStrings.retry,
    this.onAction,
  }) : kind = StatePanelKind.error;

  final StatePanelKind kind;
  final String? title;
  final String? body;
  final IconData? icon;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final children = <Widget>[];

    if (kind == StatePanelKind.loading) {
      children.add(
        SizedBox(
          width: AppIcon.size,
          height: AppIcon.size,
          child: CircularProgressIndicator(strokeWidth: 2.5, color: c.pri),
        ),
      );
    } else if (icon != null) {
      children.add(LucideIcon(icon!, size: AppIcon.sizeLarge, color: c.tx3));
    }

    if (title != null) {
      children.add(const SizedBox(height: AppSpacing.s14));
      children.add(
        Text(
          title!,
          textAlign: TextAlign.center,
          style: AppTypography.heading.copyWith(color: c.tx),
        ),
      );
    }
    if (body != null) {
      children.add(SizedBox(height: title == null ? AppSpacing.s12 : AppSpacing.s6));
      children.add(
        Text(
          body!,
          textAlign: TextAlign.center,
          style: AppTypography.label.copyWith(color: c.tx2),
        ),
      );
    }
    if (actionLabel != null && onAction != null) {
      children.add(const SizedBox(height: AppSpacing.s20));
      children.add(
        AppButton(
          label: actionLabel!,
          onPressed: onAction,
          variant: kind == StatePanelKind.error
              ? AppButtonVariant.secondary
              : AppButtonVariant.primary,
          size: AppButtonSize.small,
          expand: false,
        ),
      );
    }

    return Semantics(
      liveRegion: kind != StatePanelKind.loading,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.s32,
            vertical: AppSpacing.s24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: children,
          ),
        ),
      ),
    );
  }
}
