// Subjects providers (S09): the live subject list and each subject's 순공
// of the current week (the same clipped slices the statistics use).

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/domain/entities/entities.dart';
import '../../../core/lifecycle/calendar_day.dart';
import '../../../data/repositories/repository_providers.dart';
import '../../planner/application/planner_providers.dart';
import '../../stats/domain/seated_aggregate.dart';

part 'subjects_providers.g.dart';

@riverpod
Stream<List<Subject>> subjectsList(Ref ref) => ref.watch(subjectRepositoryProvider).watchAll();

@riverpod
Stream<List<SessionSegment>> subjectsWeekSegments(Ref ref) {
  final today = ref.watch(calendarDayProvider);
  final start = today.startOfWeek(ref.watch(plannerWeekStartProvider));
  return ref.watch(sessionRepositoryProvider).watchSegmentsOverlapping(start, start.addDays(6));
}

/// Subject id → 순공 seconds this week (null subject keyed by '').
@riverpod
Map<String, int> subjectsWeekSeated(Ref ref) {
  final today = ref.watch(calendarDayProvider);
  final start = today.startOfWeek(ref.watch(plannerWeekStartProvider));
  final segments = ref.watch(subjectsWeekSegmentsProvider).value;
  final sessions = ref.watch(plannerAllSessionsProvider).value;
  if (segments == null || sessions == null) return const <String, int>{};
  final agg = SeatedAggregate.build(from: start, to: start.addDays(6), segments: segments, sessions: sessions);
  return <String, int>{for (final s in agg.bySubject) s.subjectId ?? '': s.total};
}
