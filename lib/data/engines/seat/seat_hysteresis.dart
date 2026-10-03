// SeatHysteresis (S04, pure Dart). Short-blink suppression INSIDE the
// engine: when the detector misses a frame (head bowed while writing, a
// hand in front of the face) the engine keeps reporting `seated` for up to
// [hold] after the last detection. This is not the away decision — the
// 60–90 s away threshold lives in `features/measure/domain/away_policy.dart`
// (S06 feeds it the samples this engine emits).
//
// Timestamps are monotonic durations (D23), never wall-clock.

class SeatHysteresis {
  SeatHysteresis({this.hold = defaultHold})
      : assert(hold >= Duration.zero, 'hold must not be negative');

  /// Default hold window (instruction §4.2: N = 3 s).
  static const Duration defaultHold = Duration(seconds: 3);

  final Duration hold;

  Duration? _lastDetectedAt;

  /// Monotonic time of the last frame in which a person was detected.
  Duration? get lastDetectedAt => _lastDetectedAt;

  /// Feeds one detector result taken at monotonic time [at] and returns the
  /// seated output: `true` when detected, or when the last detection is at
  /// most [hold] ago.
  bool observe({required Duration at, required bool detected}) {
    if (detected) {
      _lastDetectedAt = at;
      return true;
    }
    final last = _lastDetectedAt;
    if (last == null) return false;
    return at - last <= hold;
  }

  /// `true` when the most recent output was seated only because of the hold
  /// window (no detection at [at] itself).
  bool isHoldingAt(Duration at) {
    final last = _lastDetectedAt;
    return last != null && at != last && at - last <= hold;
  }

  void reset() => _lastDetectedAt = null;
}
