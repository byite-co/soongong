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

  /// Elapsed since [start] (monotonic).
  Duration get elapsed {
    final m = _monoAnchor;
    return m == null ? Duration.zero : _monotonic.elapsed - m;
  }
}
