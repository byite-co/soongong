// MonthAggregate (S07, pure Dart): everything the month grid and the day
// detail draw for one `MonthGrid` — per-day 순공 seconds (saved sessions'
// seated/manual segments clipped to local midnight, the home/S06 rule),
// dated items, expanded recurrences, bands, linked sessions per item and
// the month's planned/done counts. S08 reuses this through
// `plannerMonthProvider`.

import '../../../core/domain/entities/planner.dart';
import '../../../core/domain/entities/session.dart';
import '../../../core/domain/enums.dart';
import '../../../core/domain/local_date.dart';
import '../../measure/domain/seated_time_calculator.dart';
import '../../timetable/domain/recurrence_expander.dart';
import 'band_layout.dart';
import 'month_grid.dart';

class DayAggregate {
  const DayAggregate({
    required this.date,
    required this.seatedSeconds,
    required this.items,
    required this.recurrences,
    this.sessions = const <StudySession>[],
  });

  final LocalDate date;

  /// 순공 that fell inside this local day (0 when nothing was saved).
  final int seatedSeconds;

  /// Non-band items dated this day, by sort order (events included).
  final List<PlannerItem> items;

  /// Recurrence instances on this day, by start time.
  final List<RecurrenceInstance> recurrences;

  /// Saved sessions that **started** this local day without a planner item
  /// (`planner_item_id` null) — 자습 recorded without a plan ([S07b]),
  /// oldest first. Linked sessions hang off their item instead.
  final List<StudySession> sessions;

  /// 순공 minutes of the unlinked sessions.
  int get unlinkedMinutes => sessions.fold<int>(0, (a, s) => a + s.seatedSeconds) ~/ 60;

  bool get hasSeated => seatedSeconds > 0;
  Iterable<PlannerItem> get study => items.where((i) => i.kind == PlannerKind.study);
  Iterable<PlannerItem> get todos => items.where((i) => i.kind == PlannerKind.todo);
  Iterable<PlannerItem> get self => items.where((i) => i.kind == PlannerKind.self);
  Iterable<PlannerItem> get events => items.where((i) => i.kind == PlannerKind.event);

  /// Planned 공부 minutes (sum of targets).
  int get plannedMinutes => study.fold<int>(0, (a, i) => a + (i.targetMinutes ?? 0));

  int get doneCount => items.where((i) => i.kind != PlannerKind.event && i.isDone).length;
  int get plannableCount => items.where((i) => i.kind != PlannerKind.event).length;
}

class MonthAggregate {
  const MonthAggregate({
    required this.grid,
    required this.days,
    required this.bands,
    required this.bandLayout,
    required this.sessionsByItem,
    required this.plannedCount,
    required this.doneCount,
  });

  final MonthGrid grid;
  final Map<LocalDate, DayAggregate> days;

  /// Bands overlapping the grid.
  final List<PlannerItem> bands;
  final BandLayout bandLayout;

  /// Saved sessions linked to a planner item (`planner_item_id`), newest first.
  final Map<String, List<StudySession>> sessionsByItem;

  /// In-month items other than events (공부 · 할 일 · 자습) and how many are done.
  final int plannedCount;
  final int doneCount;

  DayAggregate dayOf(LocalDate d) =>
      days[d] ??
      DayAggregate(
        date: d,
        seatedSeconds: 0,
        items: const <PlannerItem>[],
        recurrences: const <RecurrenceInstance>[],
      );

  int seatedOn(LocalDate d) => days[d]?.seatedSeconds ?? 0;

  /// Linked 순공 minutes of [item] (0 when no session is linked).
  int actualMinutes(PlannerItem item) =>
      (sessionsByItem[item.id] ?? const <StudySession>[]).fold<int>(0, (a, s) => a + s.seatedSeconds) ~/ 60;

  /// Saved = finished/interrupted with an end (the home rule, [S06]).
  static bool isSaved(StudySession s) =>
      s.endedAt != null && (s.status == SessionStatus.finished || s.status == SessionStatus.interrupted);

  /// [items] = everything overlapping the grid, bands included. [segments]
  /// = segments overlapping the grid (any session). [sessions] = the user's
  /// **whole** live session history ([S07b]): a session that started before
  /// the grid still owns segments inside it (paused across days), and an
  /// item's 실제 시간 comes from its linked sessions whenever they ran. Only
  /// saved sessions count (`isSaved`); deleted and pending-delete rows never
  /// reach here (live reads).
  factory MonthAggregate.build({
    required MonthGrid grid,
    required List<PlannerItem> items,
    required List<Recurrence> recurrences,
    required List<SessionSegment> segments,
    required List<StudySession> sessions,
  }) {
    const calc = SeatedTimeCalculator();
    final saved = sessions.where(isSaved).toList();
    final savedIds = saved.map((s) => s.id).toSet();
    final usable = segments.where((s) => savedIds.contains(s.sessionId)).toList();

    final bands = items.where((i) => i.isBand).toList();
    final byDay = <LocalDate, List<PlannerItem>>{};
    for (final it in items) {
      if (it.isBand) continue;
      byDay.putIfAbsent(it.date, () => <PlannerItem>[]).add(it);
    }
    for (final l in byDay.values) {
      l.sort((a, b) {
        final c = a.sortOrder.compareTo(b.sortOrder);
        return c != 0 ? c : a.id.compareTo(b.id);
      });
    }
    final recByDay = <LocalDate, List<RecurrenceInstance>>{};
    for (final r in const RecurrenceExpander().expand(recurrences, from: grid.first, to: grid.last)) {
      recByDay.putIfAbsent(r.date, () => <RecurrenceInstance>[]).add(r);
    }
    final days = <LocalDate, DayAggregate>{};
    var planned = 0;
    var done = 0;
    for (final d in grid.days) {
      final list = byDay[d] ?? const <PlannerItem>[];
      days[d] = DayAggregate(
        date: d,
        seatedSeconds: usable.isEmpty ? 0 : calc.seatedSecondsOn(usable, d),
        items: list,
        recurrences: recByDay[d] ?? const <RecurrenceInstance>[],
      );
      if (grid.inMonth(d)) {
        for (final it in list) {
          if (it.kind == PlannerKind.event) continue;
          planned++;
          if (it.isDone) done++;
        }
      }
    }
    final byItem = <String, List<StudySession>>{};
    final unlinkedByDay = <LocalDate, List<StudySession>>{};
    for (final s in saved) {
      final id = s.plannerItemId;
      if (id != null) {
        byItem.putIfAbsent(id, () => <StudySession>[]).add(s);
        continue;
      }
      final d = LocalDate.of(s.startedAt);
      if (grid.contains(d)) unlinkedByDay.putIfAbsent(d, () => <StudySession>[]).add(s);
    }
    for (final l in byItem.values) {
      l.sort((a, b) => b.startedAt.compareTo(a.startedAt));
    }
    for (final e in unlinkedByDay.entries) {
      e.value.sort((a, b) => a.startedAt.compareTo(b.startedAt));
      final day = days[e.key]!;
      days[e.key] = DayAggregate(
        date: day.date,
        seatedSeconds: day.seatedSeconds,
        items: day.items,
        recurrences: day.recurrences,
        sessions: List<StudySession>.unmodifiable(e.value),
      );
    }
    return MonthAggregate(
      grid: grid,
      days: Map<LocalDate, DayAggregate>.unmodifiable(days),
      bands: List<PlannerItem>.unmodifiable(bands),
      bandLayout: BandLayout.compute(bands, grid),
      sessionsByItem: Map<String, List<StudySession>>.unmodifiable(byItem),
      plannedCount: planned,
      doneCount: done,
    );
  }

  /// Daily 순공 seconds of [from]..[to] from saved sessions' segments — the
  /// density window input (`DensityScale.fromDaily`).
  static List<int> dailySeated({
    required LocalDate from,
    required LocalDate to,
    required Iterable<SessionSegment> segments,
    required Iterable<StudySession> sessions,
  }) {
    const calc = SeatedTimeCalculator();
    final savedIds = sessions.where(isSaved).map((s) => s.id).toSet();
    final usable = segments.where((s) => savedIds.contains(s.sessionId)).toList();
    final n = from.daysUntil(to);
    if (n < 0) return const <int>[];
    return List<int>.generate(n + 1, (i) => usable.isEmpty ? 0 : calc.seatedSecondsOn(usable, from.addDays(i)));
  }
}
