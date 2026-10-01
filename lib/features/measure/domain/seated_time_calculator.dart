// SeatedTimeCalculator (S02, pure Dart). 순공시간 = seated + manual segments.
// Corrections are already reflected in the segments' kinds.

import '../../../core/domain/entities/session.dart';
import '../../../core/domain/enums.dart';
import 'segment.dart';

class SeatedTimeCalculator {
  const SeatedTimeCalculator();

  /// Sum of the seated/manual segments. When [clipEnd] is given, nothing after
  /// it is counted (recovery never adds time past the snapshot, D23).
  Duration seated(Iterable<Segment> segments, {DateTime? clipEnd}) =>
      _sum(segments, (k) => k.countsAsSeated, clipEnd: clipEnd);

  int seatedSeconds(Iterable<Segment> segments, {DateTime? clipEnd}) =>
      seated(segments, clipEnd: clipEnd).inSeconds;

  Duration away(Iterable<Segment> segments) =>
      _sum(segments, (k) => k == SegmentKind.away);

  Duration paused(Iterable<Segment> segments) =>
      _sum(segments, (k) => k == SegmentKind.paused);

  /// Totals per session kind (공부 · 할 일 · 자습) from the cached seconds.
  Map<SessionKind, Duration> byKind(Iterable<StudySession> sessions) {
    final out = <SessionKind, Duration>{
      for (final k in SessionKind.values) k: Duration.zero,
    };
    for (final s in sessions) {
      out[s.kind] = out[s.kind]! + s.seated;
    }
    return out;
  }

  /// Total 순공 of [sessions].
  Duration total(Iterable<StudySession> sessions) => sessions.fold(
        Duration.zero,
        (acc, s) => acc + s.seated,
      );

  Duration _sum(
    Iterable<Segment> segments,
    bool Function(SegmentKind) where, {
    DateTime? clipEnd,
  }) {
    var total = Duration.zero;
    for (final s in segments) {
      if (!where(s.kind)) continue;
      var end = s.endAt;
      if (clipEnd != null && end.isAfter(clipEnd)) end = clipEnd;
      if (!end.isAfter(s.startAt)) continue;
      total += end.difference(s.startAt);
    }
    return total;
  }
}
