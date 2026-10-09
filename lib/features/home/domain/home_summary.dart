// HomeSummary (S05, pure Dart): everything the home hero and todo list show,
// derived from today's/yesterday's sessions, today's planner items and the
// recurrences. Facts only — durations, counts, arcs. No scores, no sums of
// planned time (PRD 4.2: 남은 할 일 N개, 시간 합산 없음).

import '../../../core/domain/entities/entities.dart';
import '../../../core/domain/enums.dart';
import '../../../core/domain/local_date.dart';
import '../../../core/utils/time_format.dart';
import '../../timetable/domain/recurrence_expander.dart';
import 'streak_calculator.dart';

enum HomeArcKind {
  /// 순공 (study / todo sessions) — blue, inner ring.
  study,

  /// 자습 — orange, inner ring.
  self,

  /// Planner event with a time — outer ring, solid.
  event,

  /// Recurring schedule instance — outer ring, ghost (점선 대용).
  recurrence,
}

class HomeArc {
  const HomeArc({
    required this.startHour,
    required this.endHour,
    required this.kind,
  });

  final double startHour;
  final double endHour;
  final HomeArcKind kind;
}

class SubjectTotal {
  const SubjectTotal({required this.name, required this.seated});

  final String name;
  final Duration seated;
}

class TodayEvent {
  const TodayEvent({
    required this.title,
    required this.start,
    required this.end,
  });

  final String title;
  final LocalTime start;
  final LocalTime end;

  String get label => '$title ${start.key}–${end.key}';
}

class HomeSummary {
  const HomeSummary({
    required this.today,
    required this.seatedToday,
    required this.seatedYesterday,
    required this.streak,
    required this.todos,
    required this.arcs,
    required this.subjectTotals,
    required this.events,
  });

  final LocalDate today;
  final Duration seatedToday;
  final Duration seatedYesterday;
  final StreakResult streak;

  /// Today's non-event planner items, open first, then by sort order.
  final List<PlannerItem> todos;
  final List<HomeArc> arcs;
  final List<SubjectTotal> subjectTotals;
  final List<TodayEvent> events;

  int get totalTodos => todos.length;
  int get doneTodos => todos.where((t) => t.isDone).length;
  int get remainingTodos => totalTodos - doneTodos;

  /// Today minus yesterday (negative when less).
  Duration get diffFromYesterday => seatedToday - seatedYesterday;

  bool get hasSeatedToday => seatedToday > Duration.zero;

  /// Nothing to show yet (userflow `homeEmpty`).
  bool get isEmpty => !hasSeatedToday && todos.isEmpty && arcs.isEmpty;

  static HomeSummary build({
    required LocalDate today,
    required List<StudySession> sessions,
    required List<PlannerItem> items,
    required List<Recurrence> recurrences,
    required Map<String, Subject> subjects,
    required StreakResult streak,
    required String fallbackSubjectName,
    List<SessionSegment>? segments,
  }) {
    final yesterday = today.addDays(-1);
    final todaySessions = <StudySession>[];
    var seatedToday = 0;
    var seatedYesterday = 0;
    final savedSessions = sessions
        .where(
          (s) =>
              (s.status == SessionStatus.finished ||
                  s.status == SessionStatus.interrupted) &&
              s.endedAt != null,
        )
        .toList();
    for (final s in savedSessions) {
      if (s.status == SessionStatus.discarded) continue;
      final day = LocalDate.of(s.startedAt.toLocal());
      if (day == today) {
        todaySessions.add(s);
        seatedToday += s.seatedSeconds;
      } else if (day == yesterday) {
        seatedYesterday += s.seatedSeconds;
      }
    }

    final arcs = <HomeArc>[];
    if (segments != null) {
      // Saved segments are the source of truth. Clip each one to the local
      // day, including sessions which crossed midnight or started earlier.
      final byId = {for (final session in savedSessions) session.id: session};
      final dayStart = today.toDateTime();
      final dayEnd = today.addDays(1).toDateTime();
      final yesterdayStart = yesterday.toDateTime();
      int clippedSeconds(SessionSegment segment, DateTime start, DateTime end) {
        final a = segment.startAt.isBefore(start) ? start : segment.startAt;
        final b = segment.endAt.isAfter(end) ? end : segment.endAt;
        return b.isAfter(a) ? b.difference(a).inSeconds : 0;
      }

      seatedToday = 0;
      seatedYesterday = 0;
      todaySessions.clear();
      final totals = <String, int>{};
      for (final segment in segments) {
        final session = byId[segment.sessionId];
        if (session == null || !segment.kind.countsAsSeated) continue;
        final seconds = clippedSeconds(segment, dayStart, dayEnd);
        seatedToday += seconds;
        seatedYesterday += clippedSeconds(segment, yesterdayStart, dayStart);
        if (seconds == 0) continue;
        totals.update(
          session.id,
          (value) => value + seconds,
          ifAbsent: () => seconds,
        );
        final start = segment.startAt.isBefore(dayStart)
            ? dayStart
            : segment.startAt.toLocal();
        final end = segment.endAt.isAfter(dayEnd)
            ? dayEnd
            : segment.endAt.toLocal();
        arcs.add(
          HomeArc(
            startHour: hourOfDay(start),
            endHour: end == dayEnd ? 24.0 : hourOfDay(end),
            kind: session.kind == SessionKind.self
                ? HomeArcKind.self
                : HomeArcKind.study,
          ),
        );
      }
      for (final entry in totals.entries) {
        todaySessions.add(
          byId[entry.key]!.copyWith(seatedSeconds: entry.value),
        );
      }
    } else {
      for (final s in todaySessions) {
        final start = hourOfDay(s.startedAt.toLocal());
        final ended = s.endedAt;
        if (ended == null) continue;
        final endLocal = ended.toLocal();
        final end = LocalDate.of(endLocal) == today
            ? hourOfDay(endLocal)
            : 24.0;
        if (end <= start) continue;
        arcs.add(
          HomeArc(
            startHour: start,
            endHour: end,
            kind: s.kind == SessionKind.self
                ? HomeArcKind.self
                : HomeArcKind.study,
          ),
        );
      }
    }

    final events = <TodayEvent>[];
    for (final it in items) {
      if (it.kind != PlannerKind.event || it.isBand) continue;
      final st = it.startTime;
      final en = it.endTime;
      if (st == null || en == null || !(en > st)) continue;
      events.add(TodayEvent(title: it.title, start: st, end: en));
      arcs.add(
        HomeArc(
          startHour: st.minutesOfDay / 60,
          endHour: en.minutesOfDay / 60,
          kind: HomeArcKind.event,
        ),
      );
    }
    for (final inst in const RecurrenceExpander().expand(
      recurrences,
      from: today,
      to: today,
    )) {
      final r = inst.recurrence;
      events.add(
        TodayEvent(title: r.title, start: r.startTime, end: r.endTime),
      );
      arcs.add(
        HomeArc(
          startHour: r.startTime.minutesOfDay / 60,
          endHour: r.endTime.minutesOfDay / 60,
          kind: HomeArcKind.recurrence,
        ),
      );
    }
    events.sort((a, b) => a.start.compareTo(b.start));

    final todos = items.where((it) => it.kind != PlannerKind.event).toList()
      ..sort((a, b) {
        if (a.isDone != b.isDone) return a.isDone ? 1 : -1;
        return a.sortOrder.compareTo(b.sortOrder);
      });

    final bySubject = <String?, int>{};
    for (final s in todaySessions) {
      bySubject.update(
        s.subjectId,
        (v) => v + s.seatedSeconds,
        ifAbsent: () => s.seatedSeconds,
      );
    }
    final totals = <SubjectTotal>[
      for (final e in bySubject.entries)
        if (e.value > 0)
          SubjectTotal(
            name: subjects[e.key]?.name ?? fallbackSubjectName,
            seated: Duration(seconds: e.value),
          ),
    ]..sort((a, b) => b.seated.compareTo(a.seated));

    return HomeSummary(
      today: today,
      seatedToday: Duration(seconds: seatedToday),
      seatedYesterday: Duration(seconds: seatedYesterday),
      streak: streak,
      todos: todos,
      arcs: arcs,
      subjectTotals: totals,
      events: events,
    );
  }

  /// Local dates with a saved session (D4: ≥ 1 saved session, any length).
  static Set<LocalDate> savedDays(Iterable<StudySession> all) => <LocalDate>{
    for (final s in all)
      if ((s.status == SessionStatus.finished ||
              s.status == SessionStatus.interrupted) &&
          s.endedAt != null)
        LocalDate.of(s.startedAt.toLocal()),
  };
}
