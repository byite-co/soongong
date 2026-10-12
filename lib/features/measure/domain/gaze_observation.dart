import 'dart:math' as math;

/// An observable eye-region signal, not a mental concentration score.
enum GazeState { unknown, uncalibrated, calibrating, reference, outside }

class GazePoint {
  const GazePoint(this.x, this.y);
  final double x;
  final double y;
}

/// One Euro filter equations; independent Dart implementation. Uses elapsed
/// seconds, resets for a gap/restart, never substitutes for SeatHysteresis.
class OneEuroSignal {
  OneEuroSignal({this.minCutoff = 1, this.beta = 0.02});
  final double minCutoff;
  final double beta;
  double? _raw;
  double? _value;
  double? _time;
  double _velocity = 0;

  void reset() { _raw = null; _value = null; _time = null; _velocity = 0; }
  double sample(double value, double seconds) {
    if (!value.isFinite || !seconds.isFinite) throw ArgumentError('non_finite_signal');
    final dt = _time == null ? 0.0 : seconds - _time!;
    if (_time == null || dt <= 0 || dt > 1) {
      _time = seconds; _raw = value; _value = value; _velocity = 0;
      return value;
    }
    double alpha(double cutoff) => 1 / (1 + 1 / (2 * math.pi * cutoff * dt));
    final velocity = (value - _raw!) / dt;
    final d = alpha(1);
    _velocity = d * velocity + (1 - d) * _velocity;
    final a = alpha(minCutoff + beta * _velocity.abs());
    _value = a * value + (1 - a) * _value!;
    _time = seconds; _raw = value;
    return _value!;
  }
}

/// Project each iris onto its own eye-corner axis; no face identity retained.
GazePoint? eyeSignal(List<GazePoint> points, int faces) {
  if (faces != 1 || points.length != 478 || points.any((p) => !p.x.isFinite || !p.y.isFinite || p.x < 0 || p.x > 1 || p.y < 0 || p.y > 1)) return null;
  GazePoint? eye(int a, int b, int iris, int upper, int lower) {
    final dx = points[b].x - points[a].x;
    final dy = points[b].y - points[a].y;
    final width2 = dx * dx + dy * dy;
    if (width2 < 0.0004) return null;
    final lidX = points[upper].x - points[lower].x;
    final lidY = points[upper].y - points[lower].y;
    if (math.sqrt((lidX * lidX + lidY * lidY) / width2) < 0.12) return null;
    final ix = points[iris].x - points[a].x;
    final iy = points[iris].y - points[a].y;
    final x = (ix * dx + iy * dy) / width2;
    final y = (iy * dx - ix * dy) / width2;
    if (x < -0.1 || x > 1.1 || y.abs() > 0.6) return null;
    return GazePoint(x, y);
  }
  final left = eye(33, 133, 468, 159, 145);
  final right = eye(362, 263, 473, 386, 374);
  if (left == null || right == null || (left.x - right.x).abs() > 0.35) return null;
  return GazePoint((left.x + right.x) / 2, (left.y + right.y) / 2);
}

class GazeCalibration {
  final _samples = <GazePoint>[];
  final _x = OneEuroSignal();
  final _y = OneEuroSignal();
  GazePoint? _center;
  double _radiusX = 0.12;
  double _radiusY = 0.12;
  bool collecting = false;
  double? _last;
  int get collected => _samples.length;

  void reset() {
    _samples.clear(); _center = null; collecting = false; _last = null; _x.reset(); _y.reset();
  }
  void begin() { reset(); collecting = true; }

  GazeState observe(GazePoint? point, double seconds) {
    if (!seconds.isFinite || (_last != null && seconds <= _last!)) return GazeState.unknown;
    if (_last != null && seconds - _last! > 1) { _x.reset(); _y.reset(); if (collecting) _samples.clear(); }
    _last = seconds;
    if (point == null || !point.x.isFinite || !point.y.isFinite) { _x.reset(); _y.reset(); if (collecting) _samples.clear(); return GazeState.unknown; }
    final filtered = GazePoint(_x.sample(point.x, seconds), _y.sample(point.y, seconds));
    if (collecting) {
      _samples.add(point);
      if (_samples.length < 15) return GazeState.calibrating;
      final x = _samples.map((p) => p.x).reduce((a, b) => a + b) / 15;
      final y = _samples.map((p) => p.y).reduce((a, b) => a + b) / 15;
      final vx = _samples.map((p) => math.pow(p.x - x, 2)).reduce((a, b) => a + b) / 15;
      final vy = _samples.map((p) => math.pow(p.y - y, 2)).reduce((a, b) => a + b) / 15;
      if (vx > 0.0064 || vy > 0.0064) { _samples.clear(); return GazeState.calibrating; }
      _center = GazePoint(x, y);
      _radiusX = math.max(0.12, 3 * math.sqrt(vx));
      _radiusY = math.max(0.12, 3 * math.sqrt(vy));
      collecting = false;
    }
    final center = _center;
    if (center == null) return GazeState.uncalibrated;
    final distance = math.pow((filtered.x - center.x) / _radiusX, 2) + math.pow((filtered.y - center.y) / _radiusY, 2);
    return distance <= 1 ? GazeState.reference : GazeState.outside;
  }
}
