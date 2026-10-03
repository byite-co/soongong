// FrameCadence (S04, pure Dart). The camera delivers 15–30 frames per
// second; the engine processes at most one per [interval] and never while a
// detection is still in flight. Every other frame is dropped synchronously
// inside the camera callback — nothing is queued or copied (CLAUDE.md §9,
// PRD §8 battery budget).

import '../../../core/contracts/seat_engine.dart';

class FrameCadence {
  FrameCadence({required this.interval})
      : assert(interval > Duration.zero, 'interval must be positive');

  /// Normal mode: `1000 ms / sampleHz`, with sampleHz clamped to [1, 2]
  /// (instruction §4.2: 1–2 frames per second at most).
  static const int minHz = 1;
  static const int maxHz = 2;

  /// Low-power mode: one frame every 2 seconds (instruction §4.3).
  static const Duration lowPowerInterval = Duration(seconds: 2);

  static Duration intervalFor(SeatEngineConfig config) {
    if (config.lowPower) return lowPowerInterval;
    final hz = config.sampleHz.clamp(minHz, maxHz);
    return Duration(milliseconds: 1000 ~/ hz);
  }

  final Duration interval;

  Duration? _lastAcceptedAt;
  bool _busy = false;
  int _accepted = 0;
  int _dropped = 0;

  /// A detection is in flight.
  bool get isBusy => _busy;

  int get accepted => _accepted;
  int get dropped => _dropped;

  /// Decides whether the frame delivered at monotonic time [at] is processed.
  /// Accepting marks the cadence busy until [release].
  bool accept(Duration at) {
    if (_busy) {
      _dropped++;
      return false;
    }
    final last = _lastAcceptedAt;
    if (last != null && at - last < interval) {
      _dropped++;
      return false;
    }
    _lastAcceptedAt = at;
    _busy = true;
    _accepted++;
    return true;
  }

  /// Detection finished (success or failure).
  void release() => _busy = false;

  void reset() {
    _lastAcceptedAt = null;
    _busy = false;
    _accepted = 0;
    _dropped = 0;
  }
}
