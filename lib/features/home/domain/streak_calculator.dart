// StreakCalculator (S02, pure Dart, D4): a day counts when at least one
// session was saved that day (sessions under 3 minutes included once saved).
// The number is shown as a fact (불꽃 안 연속 일수) — never as a judgement.

import '../../../core/domain/local_date.dart';

class StreakResult {
  const StreakResult({
    required this.current,
    required this.longest,
    required this.todayCounted,
  });

  /// Consecutive days ending today, or ending yesterday when today has no
  /// session yet (the streak is still alive until midnight).
  final int current;
  final int longest;
  final bool todayCounted;

  static const StreakResult zero =
      StreakResult(current: 0, longest: 0, todayCounted: false);
}

class StreakCalculator {
  const StreakCalculator();

  StreakResult compute(Set<LocalDate> daysWithSavedSession, LocalDate today) {
    if (daysWithSavedSession.isEmpty) return StreakResult.zero;
    final todayCounted = daysWithSavedSession.contains(today);
    var anchor = todayCounted ? today : today.addDays(-1);
    var current = 0;
    while (daysWithSavedSession.contains(anchor)) {
      current++;
      anchor = anchor.addDays(-1);
    }
    return StreakResult(
      current: current,
      longest: _longest(daysWithSavedSession),
      todayCounted: todayCounted,
    );
  }

  int _longest(Set<LocalDate> days) {
    final sorted = days.toList()..sort();
    var best = 0;
    var run = 0;
    LocalDate? prev;
    for (final d in sorted) {
      if (prev != null && prev.daysUntil(d) == 1) {
        run++;
      } else {
        run = 1;
      }
      if (run > best) best = run;
      prev = d;
    }
    return best;
  }
}
