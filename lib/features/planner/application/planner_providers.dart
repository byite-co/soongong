// Planner providers (S07): reactive month aggregates from the S02
// repositories. `plannerMonthProvider(yyyy-MM)` is the reusable monthly
// stream (S08 statistics read the same `MonthAggregate`); the density
// reference follows the last 60 days regardless of the month shown.
// Nothing here writes — writes go through `PlannerController`.

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/contracts/providers.dart';
import '../../../core/domain/entities/entities.dart';
import '../../../core/domain/local_date.dart';
import '../../../data/repositories/repository_providers.dart';
import '../domain/density_scale.dart';
import '../domain/month_aggregate.dart';
import '../domain/month_grid.dart';
import 'planner_controller.dart';

part 'planner_providers.g.dart';

/// Suggestion slot (PRD 4.3 P1 "제안 받기"): hidden in v1 — the header keeps
/// the slot so S14/S16 can turn it on without touching layout.
const bool kPlannerSuggestionsEnabled = false;

@riverpod
LocalDate plannerToday(Ref ref) => LocalDate.of(ref.watch(appClockProvider).now());

@riverpod
Stream<AppSettings> plannerSettings(Ref ref) => ref.watch(settingsRepositoryProvider).watch();

/// Week start (1 = Monday … 7 = Sunday); Monday until settings load.
@riverpod
int plannerWeekStart(Ref ref) => ref.watch(plannerSettingsProvider).value?.weekStart ?? 1;

/// Premium entitlement from the BillingGateway stream (D18). false until
/// the first value arrives, so free rules never flash premium content.
@riverpod
Stream<bool> plannerEntitlement(Ref ref) =>
    ref.watch(billingGatewayProvider).entitlement.map((e) => e.entitled);

@riverpod
bool plannerEntitled(Ref ref) => ref.watch(plannerEntitlementProvider).value ?? false;

@riverpod
Stream<List<Subject>> plannerSubjects(Ref ref) => ref.watch(subjectRepositoryProvider).watchAll();

@riverpod
Stream<List<Recurrence>> plannerRecurrences(Ref ref) =>
    ref.watch(plannerRepositoryProvider).watchRecurrences();

/// Sessions of the whole history (item links · suggestion samples).
@riverpod
Stream<List<StudySession>> plannerAllSessions(Ref ref) =>
    ref.watch(sessionRepositoryProvider).watchAll();

// ---------------------------------------------------------------------------
// Density (last 60 days, today inclusive)

@riverpod
Stream<List<SessionSegment>> plannerDensitySegments(Ref ref) {
  final today = ref.watch(plannerTodayProvider);
  return ref
      .watch(sessionRepositoryProvider)
      .watchSegmentsOverlapping(today.addDays(-(DensityScale.windowDays - 1)), today);
}

/// `DensityScale.none` until the window has loaded.
@riverpod
DensityScale plannerDensity(Ref ref) {
  final today = ref.watch(plannerTodayProvider);
  final segments = ref.watch(plannerDensitySegmentsProvider);
  final sessions = ref.watch(plannerAllSessionsProvider);
  if (!segments.hasValue || !sessions.hasValue) return DensityScale.none;
  final daily = MonthAggregate.dailySeated(
    from: today.addDays(-(DensityScale.windowDays - 1)),
    to: today,
    segments: segments.value!,
    sessions: sessions.value!,
  );
  return DensityScale.fromDaily(daily);
}

// ---------------------------------------------------------------------------
// Month (family by `yyyy-MM`)

@riverpod
MonthGrid plannerGrid(Ref ref, String monthKey) {
  final d = LocalDate.parse('$monthKey-01');
  return MonthGrid.of(d.year, d.month, weekStart: ref.watch(plannerWeekStartProvider));
}

@riverpod
Stream<List<PlannerItem>> plannerGridItems(Ref ref, String monthKey) {
  final grid = ref.watch(plannerGridProvider(monthKey));
  return ref.watch(plannerRepositoryProvider).watchItemsBetween(grid.first, grid.last);
}

@riverpod
Stream<List<SessionSegment>> plannerGridSegments(Ref ref, String monthKey) {
  final grid = ref.watch(plannerGridProvider(monthKey));
  return ref.watch(sessionRepositoryProvider).watchSegmentsOverlapping(grid.first, grid.last);
}

/// Sessions that started the day before the grid or later (a session that
/// crossed midnight into the grid is included for its segments).
@riverpod
Stream<List<StudySession>> plannerGridSessions(Ref ref, String monthKey) {
  final grid = ref.watch(plannerGridProvider(monthKey));
  return ref.watch(sessionRepositoryProvider).watchBetween(grid.first.addDays(-1), grid.last);
}

sealed class PlannerMonthState {
  const PlannerMonthState();
}

class PlannerMonthLoading extends PlannerMonthState {
  const PlannerMonthLoading();
}

class PlannerMonthError extends PlannerMonthState {
  const PlannerMonthError(this.error);

  final Object error;
}

class PlannerMonthReady extends PlannerMonthState {
  const PlannerMonthReady(this.aggregate);

  final MonthAggregate aggregate;
}

/// One month's grid data (items · bands · recurrences · 순공 per day ·
/// linked sessions). Reused by S08.
@riverpod
PlannerMonthState plannerMonth(Ref ref, String monthKey) {
  final grid = ref.watch(plannerGridProvider(monthKey));
  final items = ref.watch(plannerGridItemsProvider(monthKey));
  final recs = ref.watch(plannerRecurrencesProvider);
  final segments = ref.watch(plannerGridSegmentsProvider(monthKey));
  final sessions = ref.watch(plannerGridSessionsProvider(monthKey));
  for (final a in [items, recs, segments, sessions]) {
    if (a.hasError) return PlannerMonthError(a.error!);
  }
  if (!items.hasValue || !recs.hasValue || !segments.hasValue || !sessions.hasValue) {
    return const PlannerMonthLoading();
  }
  return PlannerMonthReady(
    MonthAggregate.build(
      grid: grid,
      items: items.value!,
      recurrences: recs.value!,
      segments: segments.value!,
      sessions: sessions.value!,
    ),
  );
}

// ---------------------------------------------------------------------------
// Writes

/// Rebuilt when the repositories change (account switch, D27); the old
/// instance is disposed so its pending delete timers never commit.
@Riverpod(keepAlive: true)
PlannerController plannerController(Ref ref) {
  final c = PlannerController(
    planner: ref.watch(plannerRepositoryProvider),
    subjects: ref.watch(subjectRepositoryProvider),
  );
  ref.onDispose(c.dispose);
  return c;
}
