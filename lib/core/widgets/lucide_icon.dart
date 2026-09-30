// Lucide icon wrapper (S01). 24px grid; the font's stroke is fixed at its
// native 2px (a font glyph cannot vary stroke width — AppIcon.strokeWidth
// 1.75 applies to custom-painted icons such as the ring hand).

import 'package:flutter/widgets.dart';

import '../theme/tokens.dart';

export 'package:lucide_icons_flutter/lucide_icons.dart' show LucideIcons;

class LucideIcon extends StatelessWidget {
  const LucideIcon(
    this.icon, {
    super.key,
    this.size = AppIcon.size,
    this.color,
    this.semanticLabel,
  });

  const LucideIcon.small(
    this.icon, {
    super.key,
    this.color,
    this.semanticLabel,
  }) : size = AppIcon.sizeSmall;

  final IconData icon;
  final double size;
  final Color? color;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    return Icon(icon, size: size, color: color, semanticLabel: semanticLabel);
  }
}
