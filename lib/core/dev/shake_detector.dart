// Shake detection (pure Dart, S01). Feed it accelerometer magnitudes; it
// fires when [threshold] is exceeded [hits] times inside [window], then
// rests for [cooldown].

import 'dart:async';
import 'dart:math' as math;

class ShakeDetector {
  ShakeDetector({
    this.threshold = 22.0, // m/s², gravity included (~2.2 g)
    this.hits = 2,
    this.window = const Duration(milliseconds: 700),
    this.cooldown = const Duration(milliseconds: 1500),
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now;

  final double threshold;
  final int hits;
  final Duration window;
  final Duration cooldown;
  final DateTime Function() _now;

  final List<DateTime> _spikes = <DateTime>[];
  DateTime? _lastFired;
  StreamSubscription<dynamic>? _sub;

  final StreamController<void> _out = StreamController<void>.broadcast();

  Stream<void> get onShake => _out.stream;

  /// Returns true when this sample completes a shake.
  bool addSample(double x, double y, double z) {
    final magnitude = math.sqrt(x * x + y * y + z * z);
    final now = _now();
    if (_lastFired != null && now.difference(_lastFired!) < cooldown) {
      return false;
    }
    if (magnitude < threshold) return false;
    _spikes.add(now);
    _spikes.removeWhere((t) => now.difference(t) > window);
    if (_spikes.length >= hits) {
      _spikes.clear();
      _lastFired = now;
      if (!_out.isClosed) _out.add(null);
      return true;
    }
    return false;
  }

  /// Binds to a stream of (x, y, z) records.
  void listen(Stream<({double x, double y, double z})> source) {
    _sub?.cancel();
    _sub = source.listen((e) => addSample(e.x, e.y, e.z));
  }

  Future<void> dispose() async {
    await _sub?.cancel();
    await _out.close();
  }
}
