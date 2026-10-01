// Clocks (S02). Domain logic never calls `DateTime.now()` directly: a
// [Clock] is injected for wall-clock time and a [MonotonicClock] for elapsed
// time (D23: elapsed time uses a monotonic clock; its reference point is
// never persisted, so it is never reused across a restart).

abstract class Clock {
  const Clock();

  /// Wall-clock time. Implementations return local time; callers convert to
  /// UTC at the storage boundary (CLAUDE.md §7).
  DateTime now();
}

class SystemClock extends Clock {
  const SystemClock();

  @override
  DateTime now() => DateTime.now();
}

/// Test clock. [advance] moves it forward.
class FixedClock extends Clock {
  FixedClock(this._now);

  DateTime _now;

  @override
  DateTime now() => _now;

  void jumpTo(DateTime value) => _now = value;

  void advance(Duration by) => _now = _now.add(by);
}

/// Monotonic elapsed time since the clock was created. Immune to wall-clock
/// changes (NTP jumps, manual edits).
abstract class MonotonicClock {
  Duration get elapsed;
}

class StopwatchMonotonicClock implements MonotonicClock {
  StopwatchMonotonicClock() : _sw = Stopwatch()..start();

  final Stopwatch _sw;

  @override
  Duration get elapsed => _sw.elapsed;
}

class FakeMonotonicClock implements MonotonicClock {
  FakeMonotonicClock([this._elapsed = Duration.zero]);

  Duration _elapsed;

  @override
  Duration get elapsed => _elapsed;

  void advance(Duration by) => _elapsed += by;
}
