// Home providers (S05): reactive streams from the S02 repositories composed
// into one `HomeViewState` (loading / error / ready → HomeSummary) plus the
// session-recovery candidate. Nothing here writes.

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/contracts/providers.dart';
import '../../../core/domain/entities/entities.dart';
import '../../../core/domain/ids.dart';
import '../../../core/domain/local_date.dart';
import '../../../core/lifecycle/calendar_day.dart';
import '../../../core/strings/subjects_strings.dart';
import '../../../data/repositories/repository_providers.dart';
import '../../measure/domain/session_snapshot.dart';
import '../domain/home_summary.dart';
import '../domain/recovery_candidate.dart';
import '../domain/streak_calculator.dart';

part 'home_providers.g.dart';

/// Today, refreshed at midnight and on app resume ([S08b] `CalendarDay`).
@riverpod
LocalDate homeToday(Ref ref) => ref.watch(calendarDayProvider);

@riverpod
Stream<List<StudySession>> homeRecentSessions(Ref ref) {
  final today = ref.watch(homeTodayProvider);
  return ref
      .watch(sessionRepositoryProvider)
      .watchBetween(today.addDays(-1), today);
}

@riverpod
Stream<List<StudySession>> homeAllSessions(Ref ref) =>
    ref.watch(sessionRepositoryProvider).watchAll();

/// Segments overlapping yesterday..today (the ring and the two totals never
/// need older ones; a session that started yesterday and crossed midnight
/// is included because its segments overlap today).
@riverpod
Stream<List<SessionSegment>> homeSegments(Ref ref) {
  final today = ref.watch(homeTodayProvider);
  return ref
      .watch(sessionRepositoryProvider)
      .watchSegmentsOverlapping(today.addDays(-1), today);
}

@riverpod
Stream<List<PlannerItem>> homeTodayItems(Ref ref) => ref
    .watch(plannerRepositoryProvider)
    .watchItemsOn(ref.watch(homeTodayProvider));

@riverpod
Stream<List<Recurrence>> homeRecurrences(Ref ref) =>
    ref.watch(plannerRepositoryProvider).watchRecurrences();

@riverpod
Stream<List<Subject>> homeSubjects(Ref ref) =>
    ref.watch(subjectRepositoryProvider).watchAll();

@riverpod
Stream<SessionSnapshot?> homeSnapshot(Ref ref) =>
    ref.watch(sessionRepositoryProvider).watchSnapshot();

sealed class HomeViewState {
  const HomeViewState();
}

class HomeLoading extends HomeViewState {
  const HomeLoading();
}

class HomeError extends HomeViewState {
  const HomeError(this.error);

  final Object error;
}

class HomeReady extends HomeViewState {
  const HomeReady(this.summary);

  final HomeSummary summary;
}

@riverpod
HomeViewState homeView(Ref ref) {
  final today = ref.watch(homeTodayProvider);
  final recent = ref.watch(homeRecentSessionsProvider);
  final all = ref.watch(homeAllSessionsProvider);
  final items = ref.watch(homeTodayItemsProvider);
  final recs = ref.watch(homeRecurrencesProvider);
  final subjects = ref.watch(homeSubjectsProvider);
  final segments = ref.watch(homeSegmentsProvider);
  for (final a in [recent, all, items, recs, subjects, segments]) {
    if (a.hasError) return HomeError(a.error!);
  }
  if (!recent.hasValue ||
      !all.hasValue ||
      !items.hasValue ||
      !recs.hasValue ||
      !subjects.hasValue ||
      !segments.hasValue) {
    return const HomeLoading();
  }
  final streak = const StreakCalculator().compute(
    HomeSummary.savedDays(all.value!),
    today,
  );
  return HomeReady(
    HomeSummary.build(
      today: today,
      sessions: all.value!,
      segments: segments.value!,
      items: items.value!,
      recurrences: recs.value!,
      subjects: <String, Subject>{for (final s in subjects.value!) s.id: s},
      streak: streak,
      fallbackSubjectName: SubjectsStrings.defaultSubjectName,
    ),
  );
}

/// null while loading or when nothing is unfinished.
@riverpod
RecoveryCandidate? homeRecoveryCandidate(Ref ref) {
  final snapshot = ref.watch(homeSnapshotProvider);
  final all = ref.watch(homeAllSessionsProvider);
  if (!snapshot.hasValue || !all.hasValue) return null;
  return RecoveryCandidate.detect(
    snapshot: snapshot.value,
    sessions: all.value!,
    newId: newUuid,
    deviceId: ref.watch(deviceIdProvider),
  );
}
