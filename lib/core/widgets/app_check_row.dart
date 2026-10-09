// AppCheckRow (S05): a 44 px consent/confirmation row — box + label, whole
// row tappable, exposed as a checkbox to assistive tech.

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../theme/tokens.dart';
import 'lucide_icon.dart';

class AppCheckRow extends StatelessWidget {
  const AppCheckRow({
    super.key,
    required this.label,
    required this.checked,
    required this.onChanged,
    this.enabled = true,
  });

  final String label;
  final bool checked;
  final ValueChanged<bool> onChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Semantics(
      container: true,
      checked: checked,
      enabled: enabled,
      label: label,
      onTap: enabled ? () => onChanged(!checked) : null,
      child: ExcludeSemantics(
        child: InkWell(
          onTap: enabled ? () => onChanged(!checked) : null,
          borderRadius: BorderRadius.circular(AppRadius.r14),
          child: Container(
            constraints: const BoxConstraints(minHeight: AppSpacing.touchTarget + AppSpacing.s4),
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s14, vertical: AppSpacing.s12),
            decoration: BoxDecoration(
              border: Border.all(color: checked ? c.pri : c.line),
              borderRadius: BorderRadius.circular(AppRadius.r14),
              color: c.surface,
            ),
            child: Row(
              children: <Widget>[
                AnimatedContainer(
                  duration: AppMotion.fade,
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    color: checked ? c.pri : Colors.transparent,
                    border: Border.all(color: checked ? c.pri : c.tx3, width: 1.5),
                    borderRadius: BorderRadius.circular(AppRadius.r8 - 2),
                  ),
                  child: checked
                      ? LucideIcon(LucideIcons.check, size: AppIcon.sizeSmall, color: c.onPri)
                      : null,
                ),
                const SizedBox(width: AppSpacing.s12),
                Expanded(
                  child: Text(
                    label,
                    style: AppTypography.withWeight(AppTypography.body, 600).copyWith(color: c.tx),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
