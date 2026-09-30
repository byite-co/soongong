// RingClock (S01): 24-hour ring shared by home and measure.
// 0h at the top, 6h on the right, 12h at the bottom, 18h on the left.
// Inner ring (stroke 10) carries session segments; outer ring (stroke 4)
// carries planner events; the accent hand marks "now".

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../theme/tokens.dart';

/// A coloured arc from [startHour] to [endHour] (0.0–24.0, clockwise).
class RingSegment {
  const RingSegment({
    required this.startHour,
    required this.endHour,
    required this.color,
    this.ghost = false,
  }) : assert(endHour >= startHour);

  final double startHour;
  final double endHour;
  final Color color;

  /// Planned / not-yet-confirmed: drawn at ghost opacity.
  final bool ghost;
}

class RingClock extends StatelessWidget {
  const RingClock({
    super.key,
    this.size = AppRing.size,
    this.segments = const <RingSegment>[],
    this.outerSegments = const <RingSegment>[],
    this.nowHour,
    this.center,
    this.showLabels = true,
    this.animate = true,
    this.semanticsLabel,
  });

  final double size;

  /// Inner ring (sessions).
  final List<RingSegment> segments;

  /// Outer ring (events / free slots).
  final List<RingSegment> outerSegments;

  /// Hand position (0.0–24.0). Hidden when null.
  final double? nowHour;

  /// Widget placed in the centre slot (84×84 at the default size).
  final Widget? center;

  final bool showLabels;
  final bool animate;
  final String? semanticsLabel;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final reduced = AppMotion.reduced(context);
    final scale = size / AppRing.size;
    final labelStyle = AppTypography.withWeight(AppTypography.caption, 600)
        .copyWith(fontSize: 10 * scale, color: c.tx3, height: 1);

    Widget ring(double progress) => CustomPaint(
          size: Size.square(size),
          painter: _RingPainter(
            colors: c,
            segments: segments,
            outerSegments: outerSegments,
            nowHour: nowHour,
            progress: progress,
            scale: scale,
          ),
        );

    final body = animate && !reduced
        ? TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0, end: 1),
            duration: AppMotion.ringIn,
            curve: AppMotion.meterCurve,
            builder: (_, v, _) => ring(v),
          )
        : ring(1);

    final labelOffset = (AppRing.outerRadius + 14) * scale;
    final half = size / 2;

    return Semantics(
      label: semanticsLabel,
      container: true,
      child: SizedBox(
        width: size + (showLabels ? 28 * scale : 0),
        height: size + (showLabels ? 28 * scale : 0),
        child: Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: <Widget>[
            body,
            if (center != null)
              SizedBox(width: 84 * scale, height: 84 * scale, child: center),
            if (showLabels) ...<Widget>[
              _label('0', labelStyle, Offset(0, -labelOffset), half),
              _label('6', labelStyle, Offset(labelOffset, 0), half),
              _label('12', labelStyle, Offset(0, labelOffset), half),
              _label('18', labelStyle, Offset(-labelOffset, 0), half),
            ],
          ],
        ),
      ),
    );
  }

  Widget _label(String text, TextStyle style, Offset offset, double half) {
    return Transform.translate(
      offset: offset,
      child: ExcludeSemantics(child: Text(text, style: style)),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({
    required this.colors,
    required this.segments,
    required this.outerSegments,
    required this.nowHour,
    required this.progress,
    required this.scale,
  });

  final AppColors colors;
  final List<RingSegment> segments;
  final List<RingSegment> outerSegments;
  final double? nowHour;
  final double progress;
  final double scale;

  static const double _startAngle = -math.pi / 2; // 0h at top

  double _angle(double hour) => _startAngle + (hour / 24) * 2 * math.pi;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final rOuter = AppRing.outerRadius * scale;
    final rInner = AppRing.innerRadius * scale;
    final wOuter = AppRing.outerStroke * scale;
    final wInner = AppRing.innerStroke * scale;

    // Tracks
    canvas.drawCircle(
      center,
      rOuter,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = wOuter
        ..color = colors.tx3.withValues(alpha: AppRing.outerTrackOpacity),
    );
    canvas.drawCircle(
      center,
      rInner,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = wInner
        ..color = colors.tx3.withValues(alpha: AppRing.innerTrackOpacity),
    );

    // Segments
    _drawSegments(canvas, center, rInner, wInner, segments);
    _drawSegments(canvas, center, rOuter, wOuter, outerSegments);

    // Ticks at 0 / 6 / 12 / 18 on the outer ring
    final tick = Paint()..color = colors.tx2;
    for (final h in <double>[0, 6, 12, 18]) {
      final a = _angle(h);
      canvas.drawCircle(
        center + Offset(math.cos(a), math.sin(a)) * rOuter,
        AppRing.tickRadius * scale,
        tick,
      );
    }

    // Now hand
    final now = nowHour;
    if (now != null) {
      final a = _angle(now);
      final dir = Offset(math.cos(a), math.sin(a));
      final from = center + dir * (50 * scale);
      final to = center + dir * (74 * scale);
      canvas.drawLine(
        from,
        to,
        Paint()
          ..color = colors.bg
          ..strokeWidth = AppRing.handHaloWidth * scale
          ..strokeCap = StrokeCap.round,
      );
      canvas.drawLine(
        from + dir * scale,
        to - dir * scale,
        Paint()
          ..color = colors.acc
          ..strokeWidth = AppRing.handWidth * scale
          ..strokeCap = StrokeCap.round,
      );
      canvas.drawCircle(
        to,
        AppRing.handKnobRadius * scale,
        Paint()..color = colors.acc,
      );
      canvas.drawCircle(
        to,
        AppRing.handKnobRadius * scale,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5 * scale
          ..color = colors.bg,
      );
    }
  }

  void _drawSegments(
    Canvas canvas,
    Offset center,
    double radius,
    double width,
    List<RingSegment> list,
  ) {
    final rect = Rect.fromCircle(center: center, radius: radius);
    for (final s in list) {
      final start = _angle(s.startHour.clamp(0, 24));
      final sweep = ((s.endHour - s.startHour).clamp(0, 24) / 24) *
          2 *
          math.pi *
          progress;
      if (sweep <= 0) continue;
      canvas.drawArc(
        rect,
        start,
        sweep,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = width
          ..strokeCap = StrokeCap.butt
          ..color = s.ghost
              ? s.color.withValues(alpha: AppRing.ghostOpacity)
              : s.color,
      );
    }
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.colors != colors ||
      old.segments != segments ||
      old.outerSegments != outerSegments ||
      old.nowHour != nowHour ||
      old.progress != progress ||
      old.scale != scale;
}
