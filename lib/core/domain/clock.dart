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

/// Elapsed real time that keeps counting while the device sleeps (Android
/// `SystemClock.elapsedRealtime()`, iOS `clock_gettime(CLOCK_MONOTONIC)`).
/// Dart's [Stopwatch] (`CLOCK_MONOTONIC` on Android, `mach_absolute_time`
/// on iOS) stops during sleep, so the difference between the two across a
/// background interval is exactly the time the session clock did not see.
/// Never a wall clock: a device time change does not move it (D23 · [S06c]).
abstract class SleepAwareClock {
  const SleepAwareClock();

  /// null when the platform cannot answer (tests, unsupported host).
  Future<Duration?> elapsedRealtime();
}

/// No platform answer: the session clock is never corrected.
class NoSleepAwareClock extends SleepAwareClock {
  const NoSleepAwareClock();

  @override
  Future<Duration?> elapsedRealtime() async => null;
}

/// Test clock. [advance] moves it (a sleep interval advances this clock but
/// not the [FakeMonotonicClock]).
class FakeSleepAwareClock extends SleepAwareClock {
  FakeSleepAwareClock([this._elapsed = Duration.zero]);

  Duration? _elapsed;

  /// Set to null to simulate a platform without an answer.
  set elapsed(Duration? v) => _elapsed = v;

  @override
  Future<Duration?> elapsedRealtime() async => _elapsed;

  void advance(Duration by) {
    final e = _elapsed;
    if (e != null) _elapsed = e + by;
  }
}

