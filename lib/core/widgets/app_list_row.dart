// AppListRow (S09): the prototype's settings row — label (+ optional hint
// line) on the left, a fact value and a chevron on the right, ≥ 52 px tall,
// whole row tappable. Used by the settings and privacy screens.

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../theme/tokens.dart';
import 'lucide_icon.dart';

class AppListRow extends StatelessWidget {
  const AppListRow({
    super.key,
    required this.label,
    this.value,
    this.hint,
    this.leading,
    this.trailing,
    this.onTap,
    this.chevron = true,
    this.destructive = false,
  });

  final String label;

  /// Fact shown on the right (`켬 · 30일 보관`, `21:00`, …).
  final String? value;

  /// Second line under the label.
  final String? hint;
  final Widget? leading;

  /// Replaces the value + chevron (e.g. a switch).
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool chevron;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final labelColor = destructive ? c.accTx : c.tx;
    final row = Container(
      constraints: const BoxConstraints(minHeight: 52),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s16, vertical: AppSpacing.s10),
      child: Row(
        children: <Widget>[
          if (leading != null) ...<Widget>[leading!, const SizedBox(width: AppSpacing.s12)],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(label, style: AppTypography.body.copyWith(color: labelColor)),
                if (hint != null)
                  Text(hint!, style: AppTypography.caption.copyWith(color: c.tx3)),
              ],
            ),
          ),
          if (trailing != null)
            trailing!
          else ...<Widget>[
            if (value != null)
              Flexible(
                child: Text(
                  value!,
                  textAlign: TextAlign.end,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.label.copyWith(color: c.tx2),
                ),
              ),
            if (onTap != null && chevron) ...<Widget>[
              const SizedBox(width: AppSpacing.s4),
              LucideIcon.small(LucideIcons.chevronRight, color: c.tx3),
            ],
          ],
        ],
      ),
    );
    if (onTap == null) return row;
    return Semantics(
      button: true,
      label: value == null ? label : '$label · $value',
      child: InkWell(onTap: onTap, child: ExcludeSemantics(child: row)),
    );
  }
}

/// Section = caption title + a bordered surface card of rows separated by
/// hairlines (prototype 12 · 11).
class AppListSection extends StatelessWidget {
  const AppListSection({super.key, this.title, required this.children});

  final String? title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.s20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          if (title != null)
            Padding(
              padding: const EdgeInsets.only(left: AppSpacing.s4, bottom: AppSpacing.s8),
              child: Text(
                title!,
                style: AppTypography.withWeight(AppTypography.caption, 600).copyWith(color: c.tx3),
              ),
            ),
          Material(
            color: c.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.card),
              side: BorderSide(color: c.line),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                for (var i = 0; i < children.length; i++) ...<Widget>[
                  if (i > 0) Divider(height: 1, thickness: 1, color: c.line),
                  children[i],
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
