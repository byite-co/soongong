// Planner3dPainter (S07): one cell's 순공 column in the prototype's oblique
// projection (front face skewX 26.6°, side face skewY 63.4° — the top face
// is the cell content lifted by (−h/2, −h)). Drawn per cell so the grid
// stays a plain widget tree; [t] animates the extrusion (0 = flat).

import 'package:flutter/material.dart';

import '../../../core/theme/tokens.dart';


enum ColumnTone { seated, today }

class Planner3dPainter extends CustomPainter {
  const Planner3dPainter({
    required this.heightPx,
    required this.t,
    required this.front,
    required this.side,
    required this.top,
    required this.edge,
    this.opacity = 1,
    this.plannedHeightPx = 0,
    this.plannedFront = const Color(0x00000000),
    this.plannedSide = const Color(0x00000000),
    this.plannedOpacity = AppPlanner.plannedOpacity,
    this.inset = 3,
  });

  /// 순공 column height at t = 1 (0 = no column).
  final double heightPx;

  /// 0..1 extrusion progress.
  final double t;
  final Color front;
  final Color side;
  final Color top;
  final Color edge;
  final double opacity;

  /// Premium 목표 column (S07 §4.5): drawn translucent **over** the 순공
  /// column so plan and record are both visible on the same day; 0 = none.
  final double plannedHeightPx;
  final Color plannedFront;
  final Color plannedSide;
  final double plannedOpacity;
  final double inset;

  /// Height the cell content is lifted by: the record when there is one,
  /// else the plan.
  double get liftPx => heightPx > 0 ? heightPx : plannedHeightPx;

  /// Horizontal shear of the column top for height [h] (prototype dx = h/2).
  static double shearOf(double h) => h * 0.5;

  @override
  void paint(Canvas canvas, Size size) {
    final h = heightPx * t;
    final hp = plannedHeightPx * t;
    if (h <= 0.01 && hp <= 0.01) return;
    if (h > 0.01) {
      _column(canvas, size, h, front: front, side: side, top: top, edge: edge, alpha: opacity);
    }
    if (hp > 0.01) {
      // Translucent 목표 column over the record (§4.5). Its top face is left
      // open so the lifted content stays readable.
      _column(canvas, size, hp, front: plannedFront, side: plannedSide, top: null, edge: null, alpha: plannedOpacity);
    }
  }

  void _column(
    Canvas canvas,
    Size size,
    double h, {
    required Color front,
    required Color side,
    required Color? top,
    required Color? edge,
    required double alpha,
  }) {
    final dx = shearOf(h);
    final x0 = inset;
    final y0 = inset;
    final x1 = size.width - inset;
    final y1 = size.height - inset;
    final fill = Paint()..style = PaintingStyle.fill;

    // Side face: right edge of the floor → right edge of the lifted top.
    final sidePath = Path()
      ..moveTo(x1, y0)
      ..lineTo(x1, y1)
      ..lineTo(x1 - dx, y1 - h)
      ..lineTo(x1 - dx, y0 - h)
      ..close();
    canvas.drawPath(sidePath, fill..color = side.withValues(alpha: side.a * alpha));

    // Front face: bottom edge of the floor → bottom edge of the lifted top.
    final frontPath = Path()
      ..moveTo(x0, y1)
      ..lineTo(x1, y1)
      ..lineTo(x1 - dx, y1 - h)
      ..lineTo(x0 - dx, y1 - h)
      ..close();
    canvas.drawPath(frontPath, fill..color = front.withValues(alpha: front.a * alpha));

    if (top == null) return;
    // Top face (the content sits on it).
    final topRect = Rect.fromLTRB(x0 - dx, y0 - h, x1 - dx, y1 - h);
    final rr = RRect.fromRectAndRadius(topRect, const Radius.circular(3));
    canvas.drawRRect(rr, fill..color = top.withValues(alpha: top.a * alpha));
    if (edge != null) {
      canvas.drawRRect(
        rr,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1
          ..color = edge.withValues(alpha: edge.a * alpha),
      );
    }
  }

  @override
  bool shouldRepaint(Planner3dPainter old) =>
      old.heightPx != heightPx ||
      old.plannedHeightPx != plannedHeightPx ||
      old.t != t ||
      old.front != front ||
      old.side != side ||
      old.top != top ||
      old.edge != edge ||
      old.opacity != opacity ||
      old.plannedFront != plannedFront ||
      old.plannedSide != plannedSide ||
      old.plannedOpacity != plannedOpacity ||
      old.inset != inset;
}
