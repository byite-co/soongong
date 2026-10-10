// SeatedAggregate (S08, pure Dart): the statistics of one local date range
// — daily 순공 seconds, subject split (할 일 · 자습), 24-hour histogram,
// consecutive-seating distribution, session count and average session
// length — computed from `SeatedSlices` (saved sessions' seated/manual
// segments clipped to the range and to local days, in seconds, never
// rounded per session). The session-start-date `StatsAggregator` (S02)
// stays for its callers; the screens use this one because its sums match
// the home ring and the planner at every midnight, week and month boundary.

import '../../../core/domain/entities/entities.dart';
import '../../../core/domain/enums.dart';
import '../../../core/domain/local_date.dart';
import 'seated_slices.dart';

/// 순공 of one subject split by how it was recorded.
class SubjectSeated {
  const SubjectSeated({required this.subjectId, required this.planned, required this.self});

  final String? subjectId;

  /// 공부 · 할 일 sessions (planned work).
  final int planned;

  /// 자습 sessions.
  final int self;

  int get total => planned + self;
}

/// Consecutive seating runs (adjacent seated/manual segments of one
/// session, gap ≤ 1 s) bucketed by length. Counts, not scores.
class FocusDistribution {
  const FocusDistribution({
    required this.under15,
    required this.from15To30,
    required this.from30To60,
    required this.over60,
    required this.longestSeconds,
  });

  static const FocusDistribution empty =
      FocusDistribution(under15: 0, from15To30: 0, from30To60: 0, over60: 0, longestSeconds: 0);

  final int under15;
  final int from15To30;
  final int from30To60;
  final int over60;
  final int longestSeconds;

  int get runCount => under15 + from15To30 + from30To60 + over60;
  List<int> get counts => <int>[under15, from15To30, from30To60, over60];
}

class SeatedAggregate {
  const SeatedAggregate._({
    required this.from,
    required this.to,
    required this.daily,
    required this.dailyBySubject,
    required this.totalSeconds,
    required this.recordedDays,
    required this.bySubject,
    required this.hourHistogram,
    required this.focus,
    required this.sessionCount,
    required this.averageSessionSeconds,
  });

  final LocalDate from;
  final LocalDate to;

  /// 순공 seconds per local day, index 0 = [from].
  final List<int> daily;

  /// Per day: subject id (null = no subject) → seconds (stacked bars).
  final List<Map<String?, int>> dailyBySubject;
  final int totalSeconds;

  /// Days of the range with at least one second.
  final int recordedDays;

  /// Largest first; subjects with zero seconds are absent.
  final List<SubjectSeated> bySubject;

  /// 24 buckets of seconds by local hour of day.
  final List<int> hourHistogram;
  final FocusDistribution focus;

  /// Saved sessions with at least one second inside the range.
  final int sessionCount;

  /// Mean clipped seconds per counted session (0 when none).
  final int averageSessionSeconds;

  int get dayCount => daily.length;
  bool get hasRecord => totalSeconds > 0;

  /// Mean seconds per recorded day (0 when none) — 일평균.
  int get averagePerRecordedDay => recordedDays == 0 ? 0 : totalSeconds ~/ recordedDays;

  int seatedOn(LocalDate day) {
    final i = from.daysUntil(day);
    return i < 0 || i >= daily.length ? 0 : daily[i];
  }

  /// Sum of [from]..[day] (clamped to the range).
  int secondsThrough(LocalDate day) {
    var total = 0;
    final n = from.daysUntil(day);
    for (var i = 0; i <= n && i < daily.length; i++) {
      total += daily[i];
    }
    return total;
  }

  static const int _runGapSeconds = 1;

  /// [segments] = anything overlapping the range; [sessions] = the whole
  /// live session history (a session paused across days owns segments
  /// inside the range although it started before it).
  factory SeatedAggregate.build({
    required LocalDate from,
    required LocalDate to,
    required Iterable<SessionSegment> segments,
    required Iterable<StudySession> sessions,
  }) {
    final n = from.daysUntil(to) + 1;
    final daily = List<int>.filled(n < 0 ? 0 : n, 0);
    final dailyBySubject = List<Map<String?, int>>.generate(daily.length, (_) => <String?, int>{});
    final slices = SeatedSlices.clip(from: from, to: to, segments: segments, sessions: sessions);
    final hours = List<int>.filled(24, 0);
    final perSession = <String, int>{};
    final subjectPlanned = <String?, int>{};
    final subjectSelf = <String?, int>{};
    var total = 0;
    for (final s in slices) {
      final seconds = s.seconds;
      if (seconds <= 0) continue;
      total += seconds;
      final dayIndex = from.daysUntil(s.day);
      daily[dayIndex] += seconds;
      dailyBySubject[dayIndex].update(s.session.subjectId, (v) => v + seconds, ifAbsent: () => seconds);
      perSession.update(s.session.id, (v) => v + seconds, ifAbsent: () => seconds);
      final bucket = s.session.kind == SessionKind.self ? subjectSelf : subjectPlanned;
      bucket.update(s.session.subjectId, (v) => v + seconds, ifAbsent: () => seconds);
      _splitByHour(s, hours);
    }
    final subjectIds = <String?>{...subjectPlanned.keys, ...subjectSelf.keys};
    final bySubject = <SubjectSeated>[
      for (final id in subjectIds)
        SubjectSeated(subjectId: id, planned: subjectPlanned[id] ?? 0, self: subjectSelf[id] ?? 0),
    ]..sort((a, b) {
        final c = b.total.compareTo(a.total);
        return c != 0 ? c : (a.subjectId ?? '').compareTo(b.subjectId ?? '');
      });
    final sessionCount = perSession.length;
    return SeatedAggregate._(
      from: from,
      to: to,
      daily: daily,
      dailyBySubject: dailyBySubject,
      totalSeconds: total,
      recordedDays: daily.where((d) => d > 0).length,
      bySubject: bySubject,
      hourHistogram: hours,
      focus: focusOf(from: from, to: to, segments: segments, sessions: sessions),
      sessionCount: sessionCount,
      averageSessionSeconds: sessionCount == 0 ? 0 : total ~/ sessionCount,
    );
  }

  static void _splitByHour(SeatedSlice s, List<int> hours) {
    var cursor = s.start;
    while (cursor.isBefore(s.end)) {
      final nextHour = DateTime(cursor.year, cursor.month, cursor.day, cursor.hour + 1);
      final stop = nextHour.isBefore(s.end) ? nextHour : s.end;
      final secs = stop.difference(cursor).inSeconds;
      if (secs > 0) hours[cursor.hour] += secs;
      if (!stop.isAfter(cursor)) break;
      cursor = stop;
    }
  }

  /// Consecutive seating runs clipped to the range (not to days: sitting
  /// through midnight is one run). A run = adjacent seated/manual segments
  /// of one saved session with gaps ≤ 1 s.
  static FocusDistribution focusOf({
    required LocalDate from,
    required LocalDate to,
    required Iterable<SessionSegment> segments,
    required Iterable<StudySession> sessions,
  }) {
    if (to.isBefore(from)) return FocusDistribution.empty;
    final savedIds = <String>{
      for (final s in sessions)
        if (SeatedSlices.isSaved(s)) s.id,
    };
    final rangeStart = from.toDateTime();
    final rangeEnd = to.addDays(1).toDateTime();
    final bySession = <String, List<SessionSegment>>{};
    for (final seg in segments) {
      if (!seg.kind.countsAsSeated || !savedIds.contains(seg.sessionId)) continue;
      bySession.putIfAbsent(seg.sessionId, () => <SessionSegment>[]).add(seg);
    }
    var under15 = 0;
    var from15To30 = 0;
    var from30To60 = 0;
    var over60 = 0;
    var longest = 0;
    void count(DateTime start, DateTime end) {
      final a = start.isBefore(rangeStart) ? rangeStart : start;
      final b = end.isAfter(rangeEnd) ? rangeEnd : end;
      if (!b.isAfter(a)) return;
      final secs = b.difference(a).inSeconds;
      if (secs <= 0) return;
      if (secs < 15 * 60) {
        under15++;
      } else if (secs < 30 * 60) {
        from15To30++;
      } else if (secs < 60 * 60) {
        from30To60++;
      } else {
        over60++;
      }
      if (secs > longest) longest = secs;
    }

    for (final list in bySession.values) {
      list.sort((x, y) => x.startAt.compareTo(y.startAt));
      DateTime? runStart;
      DateTime? runEnd;
      for (final seg in list) {
        if (runEnd != null && seg.startAt.difference(runEnd).inSeconds <= _runGapSeconds) {
          if (seg.endAt.isAfter(runEnd)) runEnd = seg.endAt;
          continue;
        }
        if (runStart != null && runEnd != null) count(runStart, runEnd);
        runStart = seg.startAt;
        runEnd = seg.endAt;
      }
      if (runStart != null && runEnd != null) count(runStart, runEnd);
    }
    return FocusDistribution(
      under15: under15,
      from15To30: from15To30,
      from30To60: from30To60,
      over60: over60,
      longestSeconds: longest,
    );
  }

  /// 24 buckets → the prototype's five bands (새벽·아침 05–09 · 오전 09–12
  /// · 오후 12–18 · 저녁 18–22 · 밤 22–05).
  List<int> get hourBands => <int>[
        _sumHours(5, 9),
        _sumHours(9, 12),
        _sumHours(12, 18),
        _sumHours(18, 22),
        _sumHours(22, 24) + _sumHours(0, 5),
      ];

  int _sumHours(int from, int to) {
    var t = 0;
    for (var h = from; h < to; h++) {
      t += hourHistogram[h];
    }
    return t;
  }
}

/// Week-over-week facts (PRD 4.2: 지난주 비교는 사실만).
class WeekComparison {
  const WeekComparison._({required this.thisSeconds, required this.lastSeconds, required this.hasLast, required this.partial});

  /// [current] and [previous] are consecutive weeks. When [today] lies in
  /// [current], both are summed through the same weekday (partial week);
  /// otherwise whole weeks are compared.
  factory WeekComparison.of({
    required SeatedAggregate current,
    required SeatedAggregate previous,
    required LocalDate today,
  }) {
    final partial = today >= current.from && today <= current.to;
    final offset = partial ? current.from.daysUntil(today) : current.dayCount - 1;
    return WeekComparison._(
      thisSeconds: current.secondsThrough(current.from.addDays(offset)),
      lastSeconds: previous.secondsThrough(previous.from.addDays(offset)),
      hasLast: previous.hasRecord,
      partial: partial,
    );
  }

  final int thisSeconds;
  final int lastSeconds;

  /// False when the previous week has no record at all (nothing to compare).
  final bool hasLast;

  /// True when the comparison stops at today's weekday.
  final bool partial;

  int get diffSeconds => thisSeconds - lastSeconds;
}
