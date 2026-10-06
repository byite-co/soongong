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

  /// Re-anchors the clock so that [now] reads [wallNow] when the wall clock
  /// is ahead of the monotonic-derived time, and returns the applied shift.
  ///
  /// The monotonic clock does not advance while the device sleeps (Android
  /// `CLOCK_MONOTONIC`, iOS `mach_absolute_time`), so after a background /
  /// screen-off interval `now()` would lag the real time by the sleep
  /// duration and every later segment would be placed too early. The caller
  /// applies this on foreground return while the timeline is paused: the
  /// unobserved interval becomes a longer `paused` segment (never 순공) and
  /// the following segments sit at their true wall-clock position. Time is
  /// never moved backwards (a wall clock set back stays ignored — D23).
  Duration realign(DateTime wallNow) {
    final w = _wallAnchor;
    if (w == null) return Duration.zero;
    final current = now();
    if (!wallNow.isAfter(current)) return Duration.zero;
    final shift = wallNow.difference(current);
    _wallAnchor = w.add(shift);
    return shift;
  }

  /// Elapsed since [start] (monotonic).
  Duration get elapsed {
    final m = _monoAnchor;
    return m == null ? Duration.zero : _monotonic.elapsed - m;
  }
}
