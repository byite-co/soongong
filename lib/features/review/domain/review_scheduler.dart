// ReviewScheduler (S02, pure Dart, D9):
//   initial 1 day → 맞음 ×2 (max 30 days) · 부분 interval kept · 또 틀림 reset
//   to 1 day · 2 consecutive 맞음 → leaves the queue.
// Voiding a record recomputes the schedule by replaying the remaining
// records from the initial state ([rebuild]).

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

sealed class ReviewOutcome {
  const ReviewOutcome();
}

/// Stays in the queue with a new schedule.
class ReviewScheduled extends ReviewOutcome {
  const ReviewScheduled(this.schedule);

  final ReviewSchedule schedule;
}

/// Two consecutive 맞음 — leaves the queue (entry soft-deleted).
class ReviewGraduated extends ReviewOutcome {
  const ReviewGraduated({required this.at});

  final DateTime at;
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

  /// Applies one retry result.
  ReviewOutcome record(ReviewSchedule current, RetryResult result, DateTime at) {
    switch (result) {
      case RetryResult.correct:
        final streak = current.consecutiveCorrect + 1;
        if (streak >= graduateAfter) return ReviewGraduated(at: at);
        final next = _clamp(current.intervalDays * 2);
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
        return ReviewScheduled(
          ReviewSchedule(
            intervalDays: initialDays,
            consecutiveCorrect: 0,
            dueAt: at.add(const Duration(days: initialDays)),
            lastResult: result,
          ),
        );
    }
  }

  /// Replays [events] (non-voided, any order) from the initial state. Used
  /// after a record is voided (`rtVoid`) — the entry is back to 미해결.
  ReviewOutcome rebuild(DateTime createdAt, Iterable<RetryEvent> events) {
    final sorted = events.toList()..sort((a, b) => a.at.compareTo(b.at));
    ReviewOutcome outcome = ReviewScheduled(initial(createdAt));
    for (final e in sorted) {
      final current = outcome;
      if (current is! ReviewScheduled) break; // graduated: later records ignored
      outcome = record(current.schedule, e.result, e.at);
    }
    return outcome;
  }

  static int _clamp(int days) => days > maxDays ? maxDays : days;
}
