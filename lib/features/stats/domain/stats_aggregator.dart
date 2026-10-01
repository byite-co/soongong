// StatsAggregator (S02, pure Dart). Facts only: sums, distributions and the
// difference to last week. No scores, grades or judgements (CLAUDE.md §1).
// Dates are local; sessions are keyed by the local date of `started_at`.

import '../../../core/domain/entities/session.dart';
import '../../../core/domain/enums.dart';
import '../../../core/domain/local_date.dart';
import '../../measure/domain/segment.dart';

/// Distribution of continuous seated runs (집중 패턴).
class FocusPattern {
  const FocusPattern({
    required this.under15,
    required this.from15To30,
    required this.from30To60,
    required this.over60,
    required this.longest,
  });

  final int under15;
  final int from15To30;
  final int from30To60;
  final int over60;
  final Duration longest;

  int get runs => under15 + from15To30 + from30To60 + over60;
}

class WeekComparison {
  const WeekComparison({
    required this.thisWeekStart,
    required this.thisWeek,
    required this.lastWeek,
  });

  final LocalDate thisWeekStart;
  final Duration thisWeek;
  final Duration lastWeek;

  /// Positive = more than last week. A fact, not a verdict.
  Duration get difference => thisWeek - lastWeek;
}

class StatsAggregator {
  const StatsAggregator({this.weekStart = 1});

  /// 1 = Monday … 7 = Sunday (settings `week_start`).
  final int weekStart;

  /// Seated seconds per local day.
  Map<LocalDate, Duration> daily(Iterable<StudySession> sessions) {
    final out = <LocalDate, Duration>{};
    for (final s in sessions) {
      final d = LocalDate.of(s.startedAt);
      out[d] = (out[d] ?? Duration.zero) + s.seated;
    }
    return out;
  }

  Duration totalBetween(
    Iterable<StudySession> sessions,
    LocalDate from,
    LocalDate to,
  ) {
    var total = Duration.zero;
    for (final s in sessions) {
      final d = LocalDate.of(s.startedAt);
      if (d >= from && d <= to) total += s.seated;
    }
    return total;
  }

  /// Keyed by the first day of each week.
  Map<LocalDate, Duration> weekly(Iterable<StudySession> sessions) {
    final out = <LocalDate, Duration>{};
    for (final s in sessions) {
      final w = LocalDate.of(s.startedAt).startOfWeek(weekStart);
      out[w] = (out[w] ?? Duration.zero) + s.seated;
    }
    return out;
  }

  /// Keyed by `yyyy-MM`.
  Map<String, Duration> monthly(Iterable<StudySession> sessions) {
    final out = <String, Duration>{};
    for (final s in sessions) {
      final m = LocalDate.of(s.startedAt).monthKey;
      out[m] = (out[m] ?? Duration.zero) + s.seated;
    }
    return out;
  }

  /// Keyed by subject id (null = no subject).
  Map<String?, Duration> bySubject(Iterable<StudySession> sessions) {
    final out = <String?, Duration>{};
    for (final s in sessions) {
      out[s.subjectId] = (out[s.subjectId] ?? Duration.zero) + s.seated;
    }
    return out;
  }

  Map<SessionKind, Duration> byKind(Iterable<StudySession> sessions) {
    final out = <SessionKind, Duration>{
      for (final k in SessionKind.values) k: Duration.zero,
    };
    for (final s in sessions) {
      out[s.kind] = out[s.kind]! + s.seated;
    }
    return out;
  }

  /// Number of distinct local days with at least one session.
  int activeDays(Iterable<StudySession> sessions) =>
      sessions.map((s) => LocalDate.of(s.startedAt)).toSet().length;

  /// 24 buckets: seated time overlapping each local hour of the day.
  List<Duration> hourHistogram(Iterable<Segment> segments) {
    final buckets = List<Duration>.filled(24, Duration.zero);
    for (final seg in segments) {
      if (!seg.kind.countsAsSeated || seg.isEmpty) continue;
      var cursor = seg.startAt.toLocal();
      final end = seg.endAt.toLocal();
      while (cursor.isBefore(end)) {
        final nextHour =
            DateTime(cursor.year, cursor.month, cursor.day, cursor.hour + 1);
        final sliceEnd = nextHour.isBefore(end) ? nextHour : end;
        buckets[cursor.hour] += sliceEnd.difference(cursor);
        cursor = sliceEnd;
      }
    }
    return buckets;
  }

  /// Continuous seated runs: adjacent seated/manual segments (gap ≤ 1 s,
  /// e.g. split by a correction) are merged before bucketing.
  FocusPattern focusPattern(Iterable<Segment> segments) {
    final seated = segments.where((s) => s.kind.countsAsSeated && !s.isEmpty).toList()
      ..sort((a, b) => a.startAt.compareTo(b.startAt));
    final runs = <Duration>[];
    DateTime? runStart;
    DateTime? runEnd;
    for (final s in seated) {
      if (runEnd != null &&
          runStart != null &&
          s.startAt.difference(runEnd) <= const Duration(seconds: 1)) {
        if (s.endAt.isAfter(runEnd)) runEnd = s.endAt;
        continue;
      }
      if (runStart != null && runEnd != null) {
        runs.add(runEnd.difference(runStart));
      }
      runStart = s.startAt;
      runEnd = s.endAt;
    }
    if (runStart != null && runEnd != null) runs.add(runEnd.difference(runStart));

    var under15 = 0;
    var b15 = 0;
    var b30 = 0;
    var over60 = 0;
    var longest = Duration.zero;
    for (final r in runs) {
      if (r > longest) longest = r;
      final m = r.inMinutes;
      if (m < 15) {
        under15++;
      } else if (m < 30) {
        b15++;
      } else if (m < 60) {
        b30++;
      } else {
        over60++;
      }
    }
    return FocusPattern(
      under15: under15,
      from15To30: b15,
      from30To60: b30,
      over60: over60,
      longest: longest,
    );
  }

  /// This week (the one containing [today]) vs the previous week.
  WeekComparison compareWeeks(
    Iterable<StudySession> sessions, {
    required LocalDate today,
  }) {
    final thisStart = today.startOfWeek(weekStart);
    final lastStart = thisStart.addDays(-7);
    return WeekComparison(
      thisWeekStart: thisStart,
      thisWeek: totalBetween(sessions, thisStart, thisStart.addDays(6)),
      lastWeek: totalBetween(sessions, lastStart, thisStart.addDays(-1)),
    );
  }
}
