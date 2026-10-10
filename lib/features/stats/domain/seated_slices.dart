// Seated slices (S08, pure Dart): the one place that turns saved sessions'
// seated/manual segments into pieces clipped to local days and to a query
// range, in seconds. Every S08 total (timetable blocks, weekly/monthly
// sums, subject split, hour histogram) is built from these slices, so the
// home ring (`HomeSummary.build`), the planner (`MonthAggregate`), the
// timetable and the statistics agree on the same numbers: a session that
// crossed midnight counts on both days by its parts, a session that started
// before the range still contributes its inside parts, and unsaved,
// discarded, deleted or pending-delete sessions never count.

import '../../../core/domain/entities/entities.dart';
import '../../../core/domain/local_date.dart';
import '../../planner/domain/month_aggregate.dart';

/// One seated/manual piece of a saved session inside one local day.
class SeatedSlice {
  const SeatedSlice({
    required this.session,
    required this.day,
    required this.start,
    required this.end,
  });

  final StudySession session;
  final LocalDate day;

  /// Local wall-clock instants; [end] is at most the next local midnight.
  final DateTime start;
  final DateTime end;

  int get seconds => end.difference(start).inSeconds;

  /// Minutes after the day's local midnight (0 – 1440).
  double get startMinutes => start.difference(day.toDateTime()).inSeconds / 60;
  double get endMinutes => end.difference(day.toDateTime()).inSeconds / 60;
}

abstract final class SeatedSlices {
  /// Saved = finished/interrupted with an end — the home/planner rule.
  static bool isSaved(StudySession s) => MonthAggregate.isSaved(s);

  /// Seated/manual pieces of [segments] that belong to a saved session in
  /// [sessions], clipped to each local day of [from]..[to] (inclusive).
  /// Sorted by start instant. Segments of other sessions are ignored (the
  /// caller passes whatever overlaps the range; sessions should be the whole
  /// live history so a session started before the range is still found).
  static List<SeatedSlice> clip({
    required LocalDate from,
    required LocalDate to,
    required Iterable<SessionSegment> segments,
    required Iterable<StudySession> sessions,
  }) {
    final out = <SeatedSlice>[];
    if (to.isBefore(from)) return out;
    final saved = <String, StudySession>{
      for (final s in sessions)
        if (isSaved(s)) s.id: s,
    };
    final rangeStart = from.toDateTime();
    final rangeEnd = to.addDays(1).toDateTime();
    for (final seg in segments) {
      if (!seg.kind.countsAsSeated) continue;
      final session = saved[seg.sessionId];
      if (session == null) continue;
      final segStart = seg.startAt.toLocal();
      final segEnd = seg.endAt.toLocal();
      if (!segEnd.isAfter(rangeStart) || !segStart.isBefore(rangeEnd)) continue;
      var day = LocalDate.of(segStart);
      if (day.isBefore(from)) day = from;
      while (day <= to) {
        final dayStart = day.toDateTime();
        final dayEnd = day.addDays(1).toDateTime();
        if (!segEnd.isAfter(dayStart)) break;
        final a = segStart.isBefore(dayStart) ? dayStart : segStart;
        final b = segEnd.isAfter(dayEnd) ? dayEnd : segEnd;
        if (b.isAfter(a)) {
          out.add(SeatedSlice(session: session, day: day, start: a, end: b));
        }
        day = day.addDays(1);
      }
    }
    out.sort((x, y) {
      final c = x.start.compareTo(y.start);
      return c != 0 ? c : x.session.id.compareTo(y.session.id);
    });
    return out;
  }

  /// Local calendar days with at least one second of 순공 in [slices].
  static Set<LocalDate> recordedDays(Iterable<SeatedSlice> slices) => <LocalDate>{
        for (final s in slices)
          if (s.seconds > 0) s.day,
      };
}
