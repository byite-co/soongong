// Work generation + inference gate (S04b · S04c, pure Dart).
//
// Design reference: byite-co/focus-engine `WorkGeneration` / `AnalysisGate`
// (Kotlin, read only — re-implemented here for the Dart contract). A
// generation number identifies one engine run. `start()` opens a new
// generation; a frame takes a [InferenceTicket] when its detection begins
// and the result is applied only when that ticket is still current. `stop()`
// bumps the generation, so a detection that returns late (after the stop
// fence, or into the next run) is discarded instead of leaking into the new
// session's samples and events.
//
// S04c adds two ways to invalidate the detection in flight without ending
// the run: [InferenceGate.invalidate] (camera lost — the result would be a
// decision taken on a stalled stream) and the per-detection deadline
// ([InferenceGate.expireIfOverdue], a detector that never returns must not
// block the cadence or the stop sequence).

class WorkGeneration {
  int _current = 0;

  int get current => _current;

  /// Invalidates every piece of work that captured an earlier generation.
  int bump() => ++_current;

  bool isCurrent(int generation) => generation == _current;
}

/// Identity of one detection: the run it belongs to and the invalidation
/// epoch inside that run.
class InferenceTicket {
  const InferenceTicket({required this.generation, required this.epoch, required this.startedAt});

  final int generation;
  final int epoch;

  /// Monotonic time the detection began.
  final Duration startedAt;

  @override
  String toString() => 'InferenceTicket(gen=$generation, epoch=$epoch, at=$startedAt)';
}

/// Bookkeeping around the single detection the engine keeps in flight.
class InferenceGate {
  InferenceGate({WorkGeneration? generation, this.deadline = defaultDeadline})
      : generation = generation ?? WorkGeneration();

  /// A detection older than this is treated as unresponsive (S04c §3b).
  static const Duration defaultDeadline = Duration(seconds: 2);

  final WorkGeneration generation;
  final Duration deadline;

  bool _open = false;
  int _epoch = 0;
  InferenceTicket? _inFlight;
  int _suppressed = 0;
  int _expired = 0;

  /// `start()` ran and `stop()` has not: frames may begin detections.
  bool get isOpen => _open;

  /// A detection began and has neither ended nor expired.
  bool get inFlight => _inFlight != null;

  /// The detection in flight, if any.
  InferenceTicket? get current => _inFlight;

  /// Results discarded because their ticket was no longer current.
  int get suppressed => _suppressed;

  /// Detections given up on because they outlived [deadline].
  int get expired => _expired;

  /// `start()`: opens the gate on a fresh generation and returns it.
  int open() {
    _open = true;
    _inFlight = null;
    return generation.bump();
  }

  /// Frame callback: the ticket for this detection, or `null` when the gate
  /// is closed (post nothing) or a detection is already running (the
  /// cadence should have dropped the frame).
  InferenceTicket? begin(Duration now) {
    if (!_open || _inFlight != null) return null;
    final t = InferenceTicket(generation: generation.current, epoch: _epoch, startedAt: now);
    _inFlight = t;
    return t;
  }

  /// Detection returned: `true` when its outcome may be applied.
  bool end(InferenceTicket ticket) {
    if (identical(_inFlight, ticket)) _inFlight = null;
    final ok = generation.isCurrent(ticket.generation) && ticket.epoch == _epoch;
    if (!ok) _suppressed++;
    return ok;
  }

  /// Camera lost (S04c §1): the detection in flight, if any, must not post —
  /// a decision taken on a stalled stream is no decision. The gate stays
  /// open for the frames that follow a recovery. Returns whether a
  /// detection was in flight.
  bool invalidate() {
    _epoch++;
    final had = _inFlight != null;
    _inFlight = null;
    return had;
  }

  /// Watchdog tick (S04c §3b): a detection older than [deadline] is given
  /// up on — the slot is freed so the next frame can run, and its eventual
  /// result is discarded. Returns the expired ticket, or `null`.
  InferenceTicket? expireIfOverdue(Duration now) {
    final t = _inFlight;
    if (t == null || now - t.startedAt < deadline) return null;
    _epoch++;
    _inFlight = null;
    _expired++;
    return t;
  }

  /// `stop()` fence: closes the gate and bumps the generation so the
  /// in-flight detection (if any) and every later frame post nothing.
  /// Returns whether a detection was in flight at that moment.
  bool cancel() {
    _open = false;
    generation.bump();
    final had = _inFlight != null;
    _inFlight = null;
    return had;
  }
}
