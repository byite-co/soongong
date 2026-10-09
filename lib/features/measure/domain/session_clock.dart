// SessionClock (S02, D23): timestamps inside a running session are derived
// from a monotonic clock anchored to the wall clock at start, so wall-clock
// jumps do not stretch or shrink segments. The anchor lives in memory only —
// it is never written to the snapshot and never reused after a restart.

import '../../../core/domain/clock.dart';

class SessionClock {
  SessionClock({required this._wall, required this._monotonic});

  final Clock _wall;
  final MonotonicClock _monotonic;
  DateTime? _wallAnchor;
  Duration? _monoAnchor;

  bool get isStarted => _wallAnchor != null;

  /// Captures the anchor. Returns the session start time (wall clock).
  DateTime start() {
    _wallAnchor = _wall.now();
    _monoAnchor = _monotonic.elapsed;
    return _wallAnchor!;
  }

  /// Wall anchor + monotonic elapsed since [start].
  DateTime now() {
    final w = _wallAnchor;
    final m = _monoAnchor;
    if (w == null || m == null) return _wall.now();
    return w.add(_monotonic.elapsed - m);
  }

  /// Moves the anchor forward by [by] (ignored when not positive): the time
  /// the monotonic clock did not count while the device slept, measured by
  /// a sleep-aware monotonic source — never by the wall clock, so a device
  /// time change still cannot move any segment (D23 · [S06c]). The caller
  /// applies it on foreground return while the timeline is paused: the
  /// unobserved interval becomes a longer `paused` segment (never 순공) and
  /// the following segments keep their true position.
  Duration advance(Duration by) {
    final w = _wallAnchor;
    if (w == null || by <= Duration.zero) return Duration.zero;
    _wallAnchor = w.add(by);
    return by;
  }

  /// Elapsed since [start] (monotonic).
  Duration get elapsed {
    final m = _monoAnchor;
    return m == null ? Duration.zero : _monotonic.elapsed - m;
  }
}
