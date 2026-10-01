// ReviewScheduler (S02 · S02b, pure Dart, D9):
//   initial 1 day → 맞음 ×2 (max 30 days) · 부분 interval kept · 또 틀림 reset
//   to 1 day · 2 consecutive 맞음 → leaves the queue.
//
// One transition function, [applyResult], drives everything: the
// incremental path ([record]) and the full recomputation after a record is
// voided ([rebuild]) fold the same function in time order, so they can never
// disagree. After graduation a 부분 re-enters with the interval kept, a
// 또 틀림 re-enters with the 1-day reset, a 맞음 keeps the item out.

import '../../../core/domain/enums.dart';

class ReviewSchedule {
  const ReviewSchedule({
    required this.intervalDays,
    required this.consecutiveCorrect,
    required this.dueAt,
    this.lastResult,
  });

  final int intervalDays;
  final int consecutiveCorrect;
  final DateTime dueAt;
  final RetryResult? lastResult;

  @override
  bool operator ==(Object other) =>
      other is ReviewSchedule &&
      other.intervalDays == intervalDays &&
      other.consecutiveCorrect == consecutiveCorrect &&
      other.dueAt.isAtSameMomentAs(dueAt) &&
      other.lastResult == lastResult;

  @override
  int get hashCode => Object.hash(
        intervalDays,
        consecutiveCorrect,
        dueAt.millisecondsSinceEpoch,
        lastResult,
      );

  @override
  String toString() =>
      'ReviewSchedule($intervalDays d, ×$consecutiveCorrect, due $dueAt, $lastResult)';
}

/// Review state of one wrong item (also the outcome of a transition).
sealed class ReviewOutcome {
  const ReviewOutcome();
}

/// In the queue with a schedule.
class ReviewScheduled extends ReviewOutcome {
  const ReviewScheduled(this.schedule);

  final ReviewSchedule schedule;

  @override
  bool operator ==(Object other) =>
      other is ReviewScheduled && other.schedule == schedule;

  @override
  int get hashCode => schedule.hashCode;

  @override
  String toString() => 'ReviewScheduled($schedule)';
}

/// Two consecutive 맞음 — out of the queue (entry soft-deleted). Keeps the
/// interval it graduated with so a later 부분 re-enters with it.
class ReviewGraduated extends ReviewOutcome {
  const ReviewGraduated({required this.at, required this.intervalDays});

  final DateTime at;
  final int intervalDays;

  @override
  bool operator ==(Object other) =>
      other is ReviewGraduated &&
      other.at.isAtSameMomentAs(at) &&
      other.intervalDays == intervalDays;

  @override
  int get hashCode => Object.hash(at.millisecondsSinceEpoch, intervalDays);

  @override
  String toString() => 'ReviewGraduated(at $at, $intervalDays d)';
}

/// A retry record as seen by [ReviewScheduler.rebuild].
class RetryEvent {
  const RetryEvent({required this.result, required this.at});

  final RetryResult result;
  final DateTime at;
}

class ReviewScheduler {
  const ReviewScheduler();

  static const int initialDays = 1;
  static const int maxDays = 30;
  static const int graduateAfter = 2;

  /// Schedule of a freshly saved wrong item.
  ReviewSchedule initial(DateTime at) => ReviewSchedule(
        intervalDays: initialDays,
        consecutiveCorrect: 0,
        dueAt: at.add(const Duration(days: initialDays)),
      );

  /// THE transition: `state × result → state`.
  ReviewOutcome applyResult(ReviewOutcome state, RetryResult result, DateTime at) {
    switch (state) {
      case ReviewScheduled(:final schedule):
        return _fromScheduled(schedule, result, at);
      case ReviewGraduated(:final intervalDays):
        switch (result) {
          case RetryResult.correct:
            return state; // stays out of the queue
          case RetryResult.partial:
            return ReviewScheduled(
              ReviewSchedule(
                intervalDays: intervalDays,
                consecutiveCorrect: 0,
                dueAt: at.add(Duration(days: intervalDays)),
                lastResult: result,
              ),
            );
          case RetryResult.wrong:
            return ReviewScheduled(_reset(at, result));
        }
    }
  }

  /// Incremental path: applies one retry result to the current schedule.
  ReviewOutcome record(ReviewSchedule current, RetryResult result, DateTime at) =>
      applyResult(ReviewScheduled(current), result, at);

  /// Full recomputation: folds [applyResult] over [events] (non-voided, any
  /// order) from the initial state. Used after a record is voided
  /// (`rtVoid`). Identical to applying the same events incrementally.
  ReviewOutcome rebuild(DateTime createdAt, Iterable<RetryEvent> events) {
    final sorted = events.toList()..sort((a, b) => a.at.compareTo(b.at));
    ReviewOutcome state = ReviewScheduled(initial(createdAt));
    for (final e in sorted) {
      state = applyResult(state, e.result, e.at);
    }
    return state;
  }

  ReviewOutcome _fromScheduled(ReviewSchedule current, RetryResult result, DateTime at) {
    switch (result) {
      case RetryResult.correct:
        final streak = current.consecutiveCorrect + 1;
        final next = _clamp(current.intervalDays * 2);
        if (streak >= graduateAfter) {
          return ReviewGraduated(at: at, intervalDays: next);
        }
        return ReviewScheduled(
          ReviewSchedule(
            intervalDays: next,
            consecutiveCorrect: streak,
            dueAt: at.add(Duration(days: next)),
            lastResult: result,
          ),
        );
      case RetryResult.partial:
        return ReviewScheduled(
          ReviewSchedule(
            intervalDays: current.intervalDays,
            consecutiveCorrect: 0,
            dueAt: at.add(Duration(days: current.intervalDays)),
            lastResult: result,
          ),
        );
      case RetryResult.wrong:
        return ReviewScheduled(_reset(at, result));
    }
  }

  static ReviewSchedule _reset(DateTime at, RetryResult result) => ReviewSchedule(
        intervalDays: initialDays,
        consecutiveCorrect: 0,
        dueAt: at.add(const Duration(days: initialDays)),
        lastResult: result,
      );

  static int _clamp(int days) => days > maxDays ? maxDays : days;
}
