// Timetable providers (S08): one `WeekTimetable` per week, built from the
// segments overlapping that week, the whole live session history (a session
// paused across days owns segments inside the week although it started
// before it, [S07b]) and the recurrences. Reads only — recurrence edits and
// deletions go through S07's `PlannerController` (`runOwnedTransaction`).

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/domain/entities/entities.dart';
import '../../../core/domain/local_date.dart';
import '../../../data/repositories/repository_providers.dart';
import '../../planner/application/planner_providers.dart';
import '../domain/week_timetable.dart';

part 'timetable_providers.g.dart';

/// Segments overlapping the week starting on [weekKey] (`yyyy-MM-dd`).
@riverpod
Stream<List<SessionSegment>> timetableSegments(Ref ref, String weekKey) {
  final start = LocalDate.parse(weekKey);
  return ref.watch(sessionRepositoryProvider).watchSegmentsOverlapping(start, start.addDays(6));
}

sealed class TimetableWeekState {
  const TimetableWeekState();
}

class TimetableWeekLoading extends TimetableWeekState {
  const TimetableWeekLoading();
}

class TimetableWeekError extends TimetableWeekState {
  const TimetableWeekError(this.error);

  final Object error;
}

class TimetableWeekReady extends TimetableWeekState {
  const TimetableWeekReady(this.week);

  final WeekTimetable week;
}

@riverpod
TimetableWeekState timetableWeek(Ref ref, String weekKey) {
  final segments = ref.watch(timetableSegmentsProvider(weekKey));
  final sessions = ref.watch(plannerAllSessionsProvider);
  final recs = ref.watch(plannerRecurrencesProvider);
  for (final a in [segments, sessions, recs]) {
    if (a.hasError) return TimetableWeekError(a.error!);
  }
  if (!segments.hasValue || !sessions.hasValue || !recs.hasValue) {
    return const TimetableWeekLoading();
  }
  return TimetableWeekReady(
    WeekTimetable.build(
      weekStart: LocalDate.parse(weekKey),
      segments: segments.value!,
      sessions: sessions.value!,
      recurrences: recs.value!,
    ),
  );
}
