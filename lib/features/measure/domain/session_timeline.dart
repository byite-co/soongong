// SessionTimeline (S02, pure Dart, D23). In-memory source of truth for a
// running session: closed segments + one open segment. Camera samples go
// through [AwayPolicy]; camera loss / screen off / another app map to
// `paused` (never away). [snapshot] produces the 15-second checkpoint,
// [recover] settles a snapshot after a forced termination.
//
// Every timestamp is supplied by the caller (from [SessionClock]); the
// timeline itself never reads a clock.

import '../../../core/domain/enums.dart';
import 'away_policy.dart';
import 'seated_time_calculator.dart';
import 'segment.dart';
import 'session_snapshot.dart';

/// Result of [SessionTimeline.recover] (D23 kind-based settlement).
class RecoveredTimeline {
  const RecoveredTimeline({
    required this.segments,
    required this.seatedSeconds,
    required this.endedAt,
  });

  final List<Segment> segments;
  final int seatedSeconds;

  /// Never later than the snapshot's `saved_at` (or the session start when
  /// there was no snapshot).
  final DateTime endedAt;

  /// Recovered sessions are always `interrupted`.
  SessionStatus get status => SessionStatus.interrupted;
}

class SessionTimeline {
  SessionTimeline._({
    required this.sessionId,
    required this.mode,
    required this.kind,
    required this.startedAt,
    required this.sensitivityLevel,
    required this._newId,
    required this._closed,
    required this._openKind,
    required this._openStart,
    required this._away,
    this.subjectId,
    this.plannerItemId,
  });

  /// Starts a new timeline: camera mode opens a `seated` segment (the first
  /// sample decides otherwise), manual mode opens a `manual` segment.
  factory SessionTimeline.start({
    required String sessionId,
    required SessionMode mode,
    required SessionKind kind,
    required DateTime startedAt,
    required int sensitivityLevel,
    required String Function() newId,
    String? subjectId,
    String? plannerItemId,
  }) =>
      SessionTimeline._(
        sessionId: sessionId,
        mode: mode,
        kind: kind,
        startedAt: startedAt,
        sensitivityLevel: sensitivityLevel,
        newId: newId,
        closed: <Segment>[],
        openKind:
            mode == SessionMode.camera ? SegmentKind.seated : SegmentKind.manual,
        openStart: startedAt,
        away: mode == SessionMode.camera
            ? AwayPolicy(sensitivityLevel: sensitivityLevel, lastSeatedAt: startedAt)
            : null,
        subjectId: subjectId,
        plannerItemId: plannerItemId,
      );

  /// Continues a live session from its latest snapshot (same process, e.g.
  /// after the screen was rebuilt). For a killed process use [recover].
  factory SessionTimeline.fromSnapshot(
    SessionSnapshot s, {
    required String Function() newId,
  }) =>
      SessionTimeline._(
        sessionId: s.sessionId,
        mode: s.mode,
        kind: s.kind,
        startedAt: s.startedAt,
        sensitivityLevel: s.sensitivity,
        newId: newId,
        closed: List<Segment>.of(s.segments),
        openKind: s.openKind,
        openStart: s.openStart,
        away: s.mode == SessionMode.camera
            ? AwayPolicy(
                sensitivityLevel: s.sensitivity,
                lastSeatedAt: s.lastSeatedAt,
                awayCandidateSince: s.awayCandidateSince,
                awayStartAt: s.openKind == SegmentKind.away ? s.openStart : null,
              )
            : null,
        subjectId: s.subjectId,
        plannerItemId: s.plannerItemId,
      );

  static const SeatedTimeCalculator _calc = SeatedTimeCalculator();

  final String sessionId;
  final SessionMode mode;
  final SessionKind kind;
  final DateTime startedAt;
  final String? subjectId;
  final String? plannerItemId;
  final String Function() _newId;
  final List<Segment> _closed;
  final AwayPolicy? _away;
  SegmentKind _openKind;
  DateTime _openStart;
  int sensitivityLevel;
  bool _ended = false;

  List<Segment> get closedSegments => List<Segment>.unmodifiable(_closed);
  SegmentKind get openKind => _openKind;
  DateTime get openStart => _openStart;
  bool get isPaused => _openKind == SegmentKind.paused;
  bool get isAway => _openKind == SegmentKind.away;
  bool get isEnded => _ended;
  DateTime? get lastSeatedAt => _away?.lastSeatedAt;
  DateTime? get awayCandidateSince => _away?.awayCandidateSince;

  /// Closed + open (clipped at [now]) segments. After [end] only the closed
  /// ones remain.
  List<Segment> segmentsAt(DateTime now) => <Segment>[
        ..._closed,
        if (!_ended && now.isAfter(_openStart))
          Segment(id: 'open', kind: _openKind, startAt: _openStart, endAt: now),
      ];

  Duration seatedAt(DateTime now) => _calc.seated(segmentsAt(now));

  /// Mid-session sensitivity change (auto adjustment).
  void setSensitivity(int level) {
    sensitivityLevel = level;
    _away?.sensitivityLevel = level;
  }

  /// Camera sample. Ignored while paused (camera is not the source then).
  List<AwayEvent> onSeatSample({required DateTime at, required bool seated}) {
    final away = _away;
    if (away == null || _ended || isPaused) return const <AwayEvent>[];
    final events = away.observe(at: at, seated: seated);
    for (final e in events) {
      switch (e) {
        case AwayConfirmed():
          // Retroactive: the seated segment ends where the away one starts.
          _switchTo(SegmentKind.away, at: e.awayStartAt);
        case AwayReturned():
          _switchTo(SegmentKind.seated, at: e.returnedAt);
        case AwayLong():
          break;
      }
    }
    return events;
  }

  /// Camera lost · screen off · another app took the camera · user pause.
  void pause(DateTime at) {
    if (_ended || isPaused) return;
    _switchTo(SegmentKind.paused, at: at);
    _away?.reset();
  }

  /// Camera recovered / user resume. Camera mode resumes as seated (the next
  /// sample decides otherwise), manual mode as manual.
  void resume(DateTime at) {
    if (_ended || !isPaused) return;
    _switchTo(
      mode == SessionMode.camera ? SegmentKind.seated : SegmentKind.manual,
      at: at,
    );
    _away?.reset(seatedAt: at);
  }

  /// Closes the open segment and returns every segment (empty ones dropped).
  List<Segment> end(DateTime at) {
    if (!_ended) {
      _close(at);
      _ended = true;
    }
    return List<Segment>.unmodifiable(_closed);
  }

  SessionSnapshot snapshot(DateTime savedAt) => SessionSnapshot(
        sessionId: sessionId,
        mode: mode,
        kind: kind,
        startedAt: startedAt,
        segments: List<Segment>.unmodifiable(_closed),
        openKind: _openKind,
        openStart: _openStart,
        savedAt: savedAt,
        sensitivity: sensitivityLevel,
        lastSeatedAt: _away?.lastSeatedAt,
        awayCandidateSince: _away?.awayCandidateSince,
        subjectId: subjectId,
        plannerItemId: plannerItemId,
      );

  /// D23 recovery after a forced termination. Closes the open segment by
  /// kind, never adds time past `saved_at`; no snapshot → 0 minutes.
  static RecoveredTimeline recover({
    required SessionSnapshot? snapshot,
    required DateTime sessionStartedAt,
    required String Function() newId,
  }) {
    if (snapshot == null) {
      return RecoveredTimeline(
        segments: const <Segment>[],
        seatedSeconds: 0,
        endedAt: sessionStartedAt,
      );
    }
    final savedAt = snapshot.savedAt;
    final out = <Segment>[
      for (final s in snapshot.segments)
        if (!s.isEmpty) s,
    ];
    final openStart = snapshot.openStart;
    switch (snapshot.openKind) {
      case SegmentKind.seated:
        final candidate = snapshot.awayCandidateSince;
        if (candidate == null) {
          _add(out, newId, SegmentKind.seated, openStart, savedAt);
        } else {
          // Seated until the last seated sample, away after it.
          var seatedEnd = snapshot.lastSeatedAt ?? openStart;
          if (seatedEnd.isBefore(openStart)) seatedEnd = openStart;
          if (seatedEnd.isAfter(savedAt)) seatedEnd = savedAt;
          _add(out, newId, SegmentKind.seated, openStart, seatedEnd);
          _add(out, newId, SegmentKind.away, seatedEnd, savedAt);
        }
      case SegmentKind.manual:
        _add(out, newId, SegmentKind.manual, openStart, savedAt);
      case SegmentKind.away:
      case SegmentKind.paused:
        _add(out, newId, snapshot.openKind, openStart, savedAt);
    }
    return RecoveredTimeline(
      segments: List<Segment>.unmodifiable(out),
      seatedSeconds: _calc.seatedSeconds(out, clipEnd: savedAt),
      endedAt: savedAt,
    );
  }

  static void _add(
    List<Segment> out,
    String Function() newId,
    SegmentKind kind,
    DateTime start,
    DateTime end,
  ) {
    if (!end.isAfter(start)) return;
    out.add(Segment(id: newId(), kind: kind, startAt: start, endAt: end));
  }

  void _switchTo(SegmentKind kind, {required DateTime at}) {
    _close(at);
    _openKind = kind;
    _openStart = at;
  }

  void _close(DateTime at) {
    var end = at;
    if (end.isBefore(_openStart)) end = _openStart;
    // A retroactive switch may land inside the previous closed segment
    // (away start < open start is impossible by construction, but a
    // defensive trim keeps the timeline monotonic).
    if (end.isAfter(_openStart)) {
      _closed.add(
        Segment(id: _newId(), kind: _openKind, startAt: _openStart, endAt: end),
      );
    }
  }
}
