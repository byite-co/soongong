// AwayPolicy (S02, pure Dart). Seated samples → away decision (D23 · PRD 4.1).
//
// - Threshold by sensitivity level: 0 → 60 s, 1 → 75 s, 2 → 90 s
//   ([S02] decision: the 0–2 level range maps onto the PRD's 60–90 s band).
// - When the threshold is exceeded the away segment starts retroactively at
//   `last_seated_at` (at most [maxRetro] before the confirming sample).
// - Returning re-seats automatically; an away episode longer than
//   [longAway] emits [AwayLong] once.
// - Camera loss / screen off are NOT away (they are `paused`, handled by the
//   timeline); this policy only sees samples from a working camera.

sealed class AwayEvent {
  const AwayEvent();
}

/// Away confirmed. [awayStartAt] is the retroactive start (D23).
class AwayConfirmed extends AwayEvent {
  const AwayConfirmed({required this.awayStartAt, required this.confirmedAt});

  final DateTime awayStartAt;
  final DateTime confirmedAt;
}

/// The user is back; measurement resumes automatically.
class AwayReturned extends AwayEvent {
  const AwayReturned({required this.awayStartAt, required this.returnedAt});

  final DateTime awayStartAt;
  final DateTime returnedAt;

  Duration get awayDuration => returnedAt.difference(awayStartAt);
}

/// Away for more than [AwayPolicy.longAway] — the UI offers 계속하기 / 종료하기.
class AwayLong extends AwayEvent {
  const AwayLong({required this.awayStartAt, required this.at});

  final DateTime awayStartAt;
  final DateTime at;
}

class AwayPolicy {
  AwayPolicy({
    required int sensitivityLevel,
    this.lastSeatedAt,
    this.awayCandidateSince,
    this._awayStartAt,
  }) : _level = sensitivityLevel.clamp(minLevel, maxLevel);

  static const int minLevel = 0;
  static const int maxLevel = 2;
  static const Duration baseThreshold = Duration(seconds: 60);
  static const Duration stepPerLevel = Duration(seconds: 15);

  /// Upper bound of the retroactive away start (D23).
  static const Duration maxRetro = Duration(seconds: 90);
  static const Duration longAway = Duration(minutes: 5);

  static Duration thresholdFor(int level) =>
      baseThreshold + stepPerLevel * level.clamp(minLevel, maxLevel);

  int _level;
  DateTime? _awayStartAt;
  bool _longNotified = false;

  /// Last sample that saw the user seated.
  DateTime? lastSeatedAt;

  /// First not-seated sample of the current (unconfirmed) candidate window.
  DateTime? awayCandidateSince;

  int get sensitivityLevel => _level;

  /// Mid-session level change (auto adjustment applies to the next decision).
  set sensitivityLevel(int v) => _level = v.clamp(minLevel, maxLevel);

  Duration get threshold => thresholdFor(_level);

  bool get isAway => _awayStartAt != null;

  DateTime? get awayStartAt => _awayStartAt;

  /// Feeds one sample. Returns the events it produced (usually none).
  List<AwayEvent> observe({required DateTime at, required bool seated}) {
    if (seated) return _onSeated(at);
    return _onNotSeated(at);
  }

  List<AwayEvent> _onSeated(DateTime at) {
    final events = <AwayEvent>[];
    final start = _awayStartAt;
    if (start != null) {
      events.add(AwayReturned(awayStartAt: start, returnedAt: at));
      _awayStartAt = null;
      _longNotified = false;
    }
    awayCandidateSince = null;
    lastSeatedAt = at;
    return events;
  }

  List<AwayEvent> _onNotSeated(DateTime at) {
    final start = _awayStartAt;
    if (start != null) {
      if (!_longNotified && at.difference(start) >= longAway) {
        _longNotified = true;
        return <AwayEvent>[AwayLong(awayStartAt: start, at: at)];
      }
      return const <AwayEvent>[];
    }
    final since = awayCandidateSince ??= at;
    if (at.difference(since) < threshold) return const <AwayEvent>[];

    // Confirmed: retroactive start = last seated sample, capped at maxRetro.
    final floor = at.subtract(maxRetro);
    var startAt = lastSeatedAt ?? since;
    if (startAt.isBefore(floor)) startAt = floor;
    if (startAt.isAfter(at)) startAt = at;
    _awayStartAt = startAt;
    awayCandidateSince = null;
    return <AwayEvent>[AwayConfirmed(awayStartAt: startAt, confirmedAt: at)];
  }

  /// Resets the candidate window and the away state (e.g. after a pause).
  void reset({DateTime? seatedAt}) {
    _awayStartAt = null;
    _longNotified = false;
    awayCandidateSince = null;
    if (seatedAt != null) lastSeatedAt = seatedAt;
  }
}
