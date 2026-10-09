// Stats providers (S08): the weekly/monthly `SeatedAggregate` of the shown
// range (plus the previous week for the comparison), the whole-history
// recorded-day count (기록일 3일 미만 → sparse state), and the wrongs
// section inputs (entitlement status, wrong items, saved readings).
// Nothing here writes; every total is derived from the same clipped slices
// the home ring, the planner and the timetable use.

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/contracts/billing_gateway.dart';
import '../../../core/contracts/providers.dart';
import '../../../core/domain/entities/entities.dart';
import '../../../core/domain/enums.dart';
import '../../../core/domain/local_date.dart';
import '../../../data/repositories/repository_providers.dart';
import '../../planner/application/planner_providers.dart';
import '../domain/seated_aggregate.dart';
import '../domain/seated_slices.dart';

part 'stats_providers.g.dart';

/// Cross view (PRD 4.3 P1 F1): hidden in v1 — the section keeps its slot.
const bool kStatsCrossViewEnabled = false;

/// Days with a record needed before the statistics show (userflow s11).
const int kStatsMinRecordedDays = 3;

enum StatsPeriod { week, month }

/// One shown range: `w:yyyy-MM-dd` (week start) or `m:yyyy-MM`.
class StatsRange {
  const StatsRange._(this.period, this.from, this.to);

  factory StatsRange.week(LocalDate weekStart) => StatsRange._(StatsPeriod.week, weekStart, weekStart.addDays(6));

  factory StatsRange.month(int year, int month) {
    final first = LocalDate(year, month, 1);
    final last = (month == 12 ? LocalDate(year + 1, 1, 1) : LocalDate(year, month + 1, 1)).addDays(-1);
    return StatsRange._(StatsPeriod.month, first, last);
  }

  factory StatsRange.parse(String key) {
    final body = key.substring(2);
    return key.startsWith('w:') ? StatsRange.week(LocalDate.parse(body)) : StatsRange.month(int.parse(body.substring(0, 4)), int.parse(body.substring(5, 7)));
  }

  final StatsPeriod period;
  final LocalDate from;
  final LocalDate to;

  String get key => period == StatsPeriod.week ? 'w:${from.key}' : 'm:${from.monthKey}';

  bool contains(LocalDate d) => d >= from && d <= to;

  StatsRange shift(int n) {
    if (period == StatsPeriod.week) return StatsRange.week(from.addDays(7 * n));
    final months = from.year * 12 + (from.month - 1) + n;
    return StatsRange.month(months ~/ 12, months % 12 + 1);
  }

  StatsRange get previous => shift(-1);
  StatsRange get next => shift(1);
}

/// Segments overlapping the range [from]..[to] of [key] — the previous
/// week is loaded for the comparison, so the family is keyed by the range.
@riverpod
Stream<List<SessionSegment>> statsSegments(Ref ref, String rangeKey) {
  final r = StatsRange.parse(rangeKey);
  return ref.watch(sessionRepositoryProvider).watchSegmentsOverlapping(r.from, r.to);
}

/// Whole-history segments: the recorded-day count behind the sparse state
/// and the "지금까지" total.
@riverpod
Stream<List<SessionSegment>> statsAllSegments(Ref ref) => ref.watch(sessionRepositoryProvider).watchAllSegments();

sealed class StatsRecordState {
  const StatsRecordState();
}

class StatsRecordLoading extends StatsRecordState {
  const StatsRecordLoading();
}

class StatsRecordError extends StatsRecordState {
  const StatsRecordError(this.error);

  final Object error;
}

/// Facts about the whole history: distinct local days with 순공 and the
/// total so far.
class StatsRecordReady extends StatsRecordState {
  const StatsRecordReady({required this.recordedDays, required this.totalSeconds});

  final int recordedDays;
  final int totalSeconds;

  bool get isSparse => recordedDays < kStatsMinRecordedDays;
}

@riverpod
StatsRecordState statsRecord(Ref ref) {
  final segments = ref.watch(statsAllSegmentsProvider);
  final sessions = ref.watch(plannerAllSessionsProvider);
  for (final a in [segments, sessions]) {
    if (a.hasError) return StatsRecordError(a.error!);
  }
  if (!segments.hasValue || !sessions.hasValue) return const StatsRecordLoading();
  final all = sessions.value!;
  if (all.isEmpty) return const StatsRecordReady(recordedDays: 0, totalSeconds: 0);
  LocalDate? first;
  LocalDate? last;
  for (final s in segments.value!) {
    final a = LocalDate.of(s.startAt.toLocal());
    final b = LocalDate.of(s.endAt.toLocal());
    if (first == null || a.isBefore(first)) first = a;
    if (last == null || b.isAfter(last)) last = b;
  }
  if (first == null || last == null) return const StatsRecordReady(recordedDays: 0, totalSeconds: 0);
  final slices = SeatedSlices.clip(from: first, to: last, segments: segments.value!, sessions: all);
  var total = 0;
  for (final s in slices) {
    total += s.seconds;
  }
  return StatsRecordReady(recordedDays: SeatedSlices.recordedDays(slices).length, totalSeconds: total);
}

sealed class StatsViewState {
  const StatsViewState();
}

class StatsViewLoading extends StatsViewState {
  const StatsViewLoading();
}

class StatsViewError extends StatsViewState {
  const StatsViewError(this.error);

  final Object error;
}

class StatsViewReady extends StatsViewState {
  const StatsViewReady({required this.range, required this.aggregate, this.comparison});

  final StatsRange range;
  final SeatedAggregate aggregate;

  /// Week ranges only.
  final WeekComparison? comparison;
}

@riverpod
StatsViewState statsView(Ref ref, String rangeKey) {
  final range = StatsRange.parse(rangeKey);
  final today = ref.watch(plannerTodayProvider);
  final segments = ref.watch(statsSegmentsProvider(rangeKey));
  final sessions = ref.watch(plannerAllSessionsProvider);
  final previous = range.period == StatsPeriod.week ? ref.watch(statsSegmentsProvider(range.previous.key)) : null;
  for (final a in [segments, sessions, ?previous]) {
    if (a.hasError) return StatsViewError(a.error!);
  }
  if (!segments.hasValue || !sessions.hasValue || (previous != null && !previous.hasValue)) {
    return const StatsViewLoading();
  }
  final aggregate = SeatedAggregate.build(from: range.from, to: range.to, segments: segments.value!, sessions: sessions.value!);
  WeekComparison? comparison;
  if (previous != null) {
    final prev = range.previous;
    comparison = WeekComparison.of(
      current: aggregate,
      previous: SeatedAggregate.build(from: prev.from, to: prev.to, segments: previous.value!, sessions: sessions.value!),
      today: today,
    );
  }
  return StatsViewReady(range: range, aggregate: aggregate, comparison: comparison);
}

// ---------------------------------------------------------------------------
// Wrongs section (PRD 4.3 · 4.4)

/// Full entitlement (status matters: `expired` shows the read-only card).
@riverpod
Stream<Entitlement> statsEntitlement(Ref ref) => ref.watch(billingGatewayProvider).entitlement;

@riverpod
Stream<List<WrongItem>> statsWrongs(Ref ref) => ref.watch(wrongsRepositoryProvider).watchAll();

@riverpod
Stream<List<ReadingRequest>> statsSavedReadings(Ref ref) => ref.watch(readingRepositoryProvider).watchSaved();

enum WrongsCardKind {
  /// Entitled: counts, per-subject rows, 전체 보기.
  premium,

  /// Never entitled: the free teaser.
  teaser,

  /// Subscription ended with saved wrongs: read-only card (PRD 4.4).
  expired,
}

class WrongsFacts {
  const WrongsFacts({
    required this.kind,
    required this.open,
    required this.resolved,
    required this.ranges,
    required this.readingsInRange,
    required this.openBySubject,
  });

  final WrongsCardKind kind;
  final int open;
  final int resolved;

  /// Distinct (subject · range) pairs among the saved wrongs.
  final int ranges;

  /// Saved readings completed inside the shown range.
  final int readingsInRange;

  /// Subject id → open count, largest first.
  final List<MapEntry<String, int>> openBySubject;

  int get total => open + resolved;
}

sealed class WrongsState {
  const WrongsState();
}

class WrongsLoading extends WrongsState {
  const WrongsLoading();
}

class WrongsReady extends WrongsState {
  const WrongsReady(this.facts);

  final WrongsFacts facts;
}

@riverpod
WrongsState statsWrongsSection(Ref ref, String rangeKey) {
  final range = StatsRange.parse(rangeKey);
  final entitlement = ref.watch(statsEntitlementProvider);
  final wrongs = ref.watch(statsWrongsProvider);
  final readings = ref.watch(statsSavedReadingsProvider);
  if (!entitlement.hasValue || !wrongs.hasValue || !readings.hasValue) return const WrongsLoading();
  final e = entitlement.value!;
  final items = wrongs.value!;
  var open = 0;
  var resolved = 0;
  final ranges = <String>{};
  final bySubject = <String, int>{};
  for (final w in items) {
    ranges.add('${w.subjectId}|${w.rangeText}');
    if (w.status == WrongItemStatus.open) {
      open++;
      bySubject.update(w.subjectId, (v) => v + 1, ifAbsent: () => 1);
    } else {
      resolved++;
    }
  }
  final from = range.from.toDateTime();
  final to = range.to.addDays(1).toDateTime();
  var inRange = 0;
  for (final r in readings.value!) {
    final at = (r.completedAt ?? r.submittedAt)?.toLocal();
    if (at != null && !at.isBefore(from) && at.isBefore(to)) inRange++;
  }
  // Read-only card only when there is something to read (PRD 4.4: 기존
  // 오답 N문항 보기); an ended subscription without saved wrongs sees the teaser.
  final kind = e.entitled
      ? WrongsCardKind.premium
      : items.isNotEmpty && (e.status == EntitlementStatus.expired || e.trialUsed)
          ? WrongsCardKind.expired
          : WrongsCardKind.teaser;
  final sorted = bySubject.entries.toList()
    ..sort((a, b) {
      final c = b.value.compareTo(a.value);
      return c != 0 ? c : a.key.compareTo(b.key);
    });
  return WrongsReady(
    WrongsFacts(
      kind: kind,
      open: open,
      resolved: resolved,
      ranges: ranges.length,
      readingsInRange: inRange,
      openBySubject: sorted,
    ),
  );
}
