// Work generation + inference gate (S04b, pure Dart).
//
// Design reference: byite-co/focus-engine `WorkGeneration` / `AnalysisGate`
// (Kotlin, read only — re-implemented here for the Dart contract). A
// generation number identifies one engine run. `start()` opens a new
// generation; a frame captures the generation when its detection begins and
// the result is applied only when that generation is still current. `stop()`
// bumps the generation, so a detection that returns late (after the stop
// fence, or into the next run) is discarded instead of leaking into the new
// session's samples and events.

class WorkGeneration {
  int _current = 0;

  int get current => _current;

  /// Invalidates every piece of work that captured an earlier generation.
  int bump() => ++_current;

  bool isCurrent(int generation) => generation == _current;
}

/// Bookkeeping around the single detection the engine keeps in flight.
class InferenceGate {
  InferenceGate([WorkGeneration? generation])
      : generation = generation ?? WorkGeneration();

  final WorkGeneration generation;

  bool _open = false;
  int? _inFlightGeneration;
  int _suppressed = 0;

  /// `start()` ran and `stop()` has not: frames may begin detections.
  bool get isOpen => _open;

  /// A detection began and has not ended yet.
  bool get inFlight => _inFlightGeneration != null;

  /// Results discarded because their generation was no longer current.
  int get suppressed => _suppressed;

  /// `start()`: opens the gate on a fresh generation and returns it.
  int open() {
    _open = true;
    return generation.bump();
  }

  /// Frame callback: the generation this detection belongs to, or `null`
  /// when the gate is closed (post nothing) or a detection is already
  /// running (the cadence should have dropped the frame).
  int? begin() {
    if (!_open || _inFlightGeneration != null) return null;
    final g = generation.current;
    _inFlightGeneration = g;
    return g;
  }

  /// Detection returned: `true` when its outcome may be applied.
  bool end(int frameGeneration) {
    _inFlightGeneration = null;
    final ok = generation.isCurrent(frameGeneration);
    if (!ok) _suppressed++;
    return ok;
  }

  /// `stop()` fence: closes the gate and bumps the generation so the
  /// in-flight detection (if any) and every later frame post nothing.
  /// Returns whether a detection was in flight at that moment.
  bool cancel() {
    _open = false;
    generation.bump();
    return _inFlightGeneration != null;
  }
}
