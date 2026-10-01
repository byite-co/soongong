import 'package:flutter_test/flutter_test.dart';
import 'package:soongong/core/domain/local_date.dart';
import 'package:soongong/features/home/domain/streak_calculator.dart';

LocalDate d(String k) => LocalDate.parse(k);

void main() {
  const calc = StreakCalculator();
  final today = d('2026-09-30');

  test('today counted: consecutive days ending today', () {
    final r = calc.compute(
      <LocalDate>{d('2026-09-27'), d('2026-09-28'), d('2026-09-29'), d('2026-09-30')},
      today,
    );
    expect(r.current, 4);
    expect(r.todayCounted, isTrue);
    expect(r.longest, 4);
  });

  test('no session today yet: the streak ending yesterday is still alive', () {
    final r = calc.compute(<LocalDate>{d('2026-09-28'), d('2026-09-29')}, today);
    expect(r.current, 2);
    expect(r.todayCounted, isFalse);
  });

  test('a gap of one day ends the streak; empty → zero; longest is historic',
      () {
    final r = calc.compute(<LocalDate>{d('2026-09-20'), d('2026-09-21'), d('2026-09-22'), d('2026-09-28')}, today);
    expect(r.current, 0);
    expect(r.longest, 3);
    expect(calc.compute(<LocalDate>{}, today), StreakResult.zero);
    // A single saved session (even < 3 min) counts (D4).
    expect(calc.compute(<LocalDate>{today}, today).current, 1);
  });
}
