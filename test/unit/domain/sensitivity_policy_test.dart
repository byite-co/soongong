import 'package:flutter_test/flutter_test.dart';
import 'package:soongong/features/measure/domain/sensitivity_policy.dart';

final DateTime now = DateTime.utc(2026, 9, 30, 12);
DateTime daysAgo(int d) => now.subtract(Duration(days: d));

void main() {
  const policy = SensitivityPolicy();

  test('level steps every 3 corrections and caps at 2', () {
    expect(SensitivityPolicy.levelFor(0), 0);
    expect(SensitivityPolicy.levelFor(2), 0);
    expect(SensitivityPolicy.levelFor(3), 1);
    expect(SensitivityPolicy.levelFor(5), 1);
    expect(SensitivityPolicy.levelFor(6), 2);
    expect(SensitivityPolicy.levelFor(30), 2);
  });

  test('the third correction switches 0 → 1 with a toast; the second does not',
      () {
    final two = policy.evaluate(
      currentLevel: 0,
      correctionsAt: <DateTime>[daysAgo(1), daysAgo(2)],
      now: now,
    );
    expect(two.level, 0);
    expect(two.changed, isFalse);

    final three = policy.evaluate(
      currentLevel: 0,
      correctionsAt: <DateTime>[daysAgo(1), daysAgo(2), now],
      now: now,
    );
    expect(three.level, 1);
    expect(three.changed, isTrue);
    expect(three.recentCorrections, 3);
  });

  test('only the last 2 weeks count; ageing out lowers the level (toast)', () {
    final adj = policy.evaluate(
      currentLevel: 1,
      correctionsAt: <DateTime>[daysAgo(15), daysAgo(14).subtract(const Duration(seconds: 1)), daysAgo(3), daysAgo(1)],
      now: now,
    );
    expect(adj.recentCorrections, 2);
    expect(adj.level, 0);
    expect(adj.changed, isTrue);
    // Exactly 14 days ago is still inside the window.
    expect(SensitivityPolicy.countRecent(<DateTime>[daysAgo(14)], now), 1);
    // Future timestamps are ignored.
    expect(
      SensitivityPolicy.countRecent(<DateTime>[now.add(const Duration(minutes: 1))], now),
      0,
    );
  });

  test('auto off keeps the manual level, never toasts', () {
    final adj = policy.evaluate(
      currentLevel: 2,
      correctionsAt: const <DateTime>[],
      now: now,
      auto: false,
    );
    expect(adj.level, 2);
    expect(adj.changed, isFalse);
  });
}
