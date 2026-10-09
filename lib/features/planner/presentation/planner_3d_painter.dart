// Planner3dPainter (S07): one cell's 순공 column in the prototype's oblique
// projection (front face skewX 26.6°, side face skewY 63.4° — the top face
// is the cell content lifted by (−h/2, −h)). Drawn per cell so the grid
// stays a plain widget tree; [t] animates the extrusion (0 = flat).

import 'package:flutter/material.dart';


enum ColumnTone { seated, planned, today }

class Planner3dPainter extends CustomPainter {
  const Planner3dPainter({
    required this.heightPx,
    required this.t,
    required this.front,
    required this.side,
    required this.top,
    required this.edge,
    required this.opacity,
    this.inset = 3,
  });

  /// Target extrusion height at t = 1.
  final double heightPx;

  /// 0..1 extrusion progress.
  final double t;
  final Color front;
  final Color side;
  final Color top;
  final Color edge;
  final double opacity;
  final double inset;

  /// Horizontal shear of the column top for height [h] (prototype dx = h/2).
  static double shearOf(double h) => h * 0.5;

  @override
  void paint(Canvas canvas, Size size) {
    final h = heightPx * t;
    if (h <= 0.01) return;
    final dx = shearOf(h);
    final x0 = inset;
    final y0 = inset;
    final x1 = size.width - inset;
    final y1 = size.height - inset;
    final fill = Paint()..style = PaintingStyle.fill;
    final line = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = edge.withValues(alpha: edge.a * opacity);

    // Side face: right edge of the floor → right edge of the lifted top.
    final sidePath = Path()
      ..moveTo(x1, y0)
      ..lineTo(x1, y1)
      ..lineTo(x1 - dx, y1 - h)
      ..lineTo(x1 - dx, y0 - h)
      ..close();
    canvas.drawPath(sidePath, fill..color = side.withValues(alpha: side.a * opacity));

    // Front face: bottom edge of the floor → bottom edge of the lifted top.
    final frontPath = Path()
      ..moveTo(x0, y1)
      ..lineTo(x1, y1)
      ..lineTo(x1 - dx, y1 - h)
      ..lineTo(x0 - dx, y1 - h)
      ..close();
    canvas.drawPath(frontPath, fill..color = front.withValues(alpha: front.a * opacity));

    // Top face (the content sits on it).
    final topRect = Rect.fromLTRB(x0 - dx, y0 - h, x1 - dx, y1 - h);
    final rr = RRect.fromRectAndRadius(topRect, const Radius.circular(3));
    canvas.drawRRect(rr, fill..color = top.withValues(alpha: top.a * opacity));
    canvas.drawRRect(rr, line);
  }

  @override
  bool shouldRepaint(Planner3dPainter old) =>
      old.heightPx != heightPx ||
      old.t != t ||
      old.front != front ||
      old.side != side ||
      old.top != top ||
      old.edge != edge ||
      old.opacity != opacity ||
      old.inset != inset;
}
