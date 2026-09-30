// SubjectChip (S01): subject color dot + mandatory name label. Colour alone
// never distinguishes subjects (PRD §8).

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../theme/tokens.dart';

class SubjectChip extends StatelessWidget {
  const SubjectChip({
    super.key,
    required this.name,
    required this.color,
    this.selected = false,
    this.onTap,
  });

  /// Uses the theme's subject palette by index (0–7).
  SubjectChip.index({
    super.key,
    required this.name,
    required int colorIndex,
    required Brightness brightness,
    this.selected = false,
    this.onTap,
  }) : color = AppColors.of(brightness).subject(colorIndex);

  final String name;
  final Color color;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final chip = Container(
      height: 24,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s12),
      decoration: BoxDecoration(
        color: selected ? c.priWeak : c.surface,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: selected ? c.pri : c.line),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: AppSpacing.s6),
          Text(
            name,
            style: AppTypography.withWeight(AppTypography.caption, 600)
                .copyWith(color: c.tx, height: 1.2),
          ),
        ],
      ),
    );
    final labelled = Semantics(
      label: name,
      selected: selected,
      button: onTap != null,
      child: chip,
    );
    if (onTap == null) return labelled;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.s10),
        child: labelled,
      ),
    );
  }
}
