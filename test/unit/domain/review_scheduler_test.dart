import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:soongong/core/domain/enums.dart';
import 'package:soongong/features/review/domain/review_scheduler.dart';

final DateTime t0 = DateTime.utc(2026, 9, 30, 12);
DateTime day(int n) => t0.add(Duration(days: n));

ReviewSchedule scheduled(ReviewOutcome o) => (o as ReviewScheduled).schedule;

void main() {
  const s = ReviewScheduler();

  test('initial: 1 day', () {
    final init = s.initial(t0);
    expect(init.intervalDays, 1);
    expect(init.consecutiveCorrect, 0);
    expect(init.dueAt, day(1));
    expect(init.lastResult, isNull);
  });

  test('맞음 doubles the interval; a second consecutive 맞음 leaves the queue',
      () {
    final first = scheduled(s.record(s.initial(t0), RetryResult.correct, day(1)));
    expect(first.intervalDays, 2);
    expect(first.consecutiveCorrect, 1);
    expect(first.dueAt, day(3));
    expect(first.lastResult, RetryResult.correct);

    final second = s.record(first, RetryResult.correct, day(3));
    expect(second, isA<ReviewGraduated>());
    expect((second as ReviewGraduated).at, day(3));
    expect(second.intervalDays, 4, reason: 'interval it graduated with');
  });

  test('after graduation (S02b): 맞음 stays out, 부분 re-enters with the '
      'graduation interval, 또 틀림 re-enters at 1 day', () {
    final grad = ReviewGraduated(at: day(3), intervalDays: 4);
    expect(s.applyResult(grad, RetryResult.correct, day(9)), grad);

    final partial = scheduled(s.applyResult(grad, RetryResult.partial, day(9)));
    expect(partial.intervalDays, 4);
    expect(partial.consecutiveCorrect, 0);
    expect(partial.dueAt, day(13));
    expect(partial.lastResult, RetryResult.partial);

    final wrong = scheduled(s.applyResult(grad, RetryResult.wrong, day(9)));
    expect(wrong.intervalDays, 1);
    expect(wrong.dueAt, day(10));
    expect(wrong.lastResult, RetryResult.wrong);
  });

  test('property: incremental applyResult == rebuild for random histories, '
      'including after a voided record', () {
    final rng = Random(7);
    for (var trial = 0; trial < 300; trial++) {
      final n = 1 + rng.nextInt(12);
      var at = t0;
      final events = <RetryEvent>[];
      for (var i = 0; i < n; i++) {
        at = at.add(Duration(hours: 6 + rng.nextInt(60)));
        events.add(RetryEvent(result: RetryResult.values[rng.nextInt(3)], at: at));
      }
      ReviewOutcome incremental = ReviewScheduled(s.initial(t0));
      for (final e in events) {
        incremental = s.applyResult(incremental, e.result, e.at);
      }
      expect(s.rebuild(t0, events), incremental, reason: 'trial $trial');

      // Void one record: fold of the rest == incremental over the rest.
      final voided = rng.nextInt(n);
      final rest = <RetryEvent>[
        for (var i = 0; i < n; i++)
          if (i != voided) events[i],
      ];
      ReviewOutcome inc2 = ReviewScheduled(s.initial(t0));
      for (final e in rest) {
        inc2 = s.applyResult(inc2, e.result, e.at);
      }
      expect(s.rebuild(t0, rest), inc2, reason: 'trial $trial void $voided');
      // Order independence of rebuild input.
      expect(s.rebuild(t0, rest.reversed), inc2);
    }
  });

  test('부분 keeps the interval and resets the streak', () {
    final first = scheduled(s.record(s.initial(t0), RetryResult.correct, day(1)));
    final partial = scheduled(s.record(first, RetryResult.partial, day(3)));
    expect(partial.intervalDays, 2);
    expect(partial.consecutiveCorrect, 0);
    expect(partial.dueAt, day(5));
    // Two more 맞음 are needed again after a 부분.
    final c1 = scheduled(s.record(partial, RetryResult.correct, day(5)));
    expect(c1.consecutiveCorrect, 1);
    expect(c1.intervalDays, 4);
    expect(s.record(c1, RetryResult.correct, day(9)), isA<ReviewGraduated>());
  });

  test('또 틀림 resets to 1 day', () {
    final first = scheduled(s.record(s.initial(t0), RetryResult.correct, day(1)));
    final wrong = scheduled(s.record(first, RetryResult.wrong, day(3)));
    expect(wrong.intervalDays, 1);
    expect(wrong.consecutiveCorrect, 0);
    expect(wrong.dueAt, day(4));
    expect(wrong.lastResult, RetryResult.wrong);
  });

  test('interval is capped at 30 days', () {
    // correct/partial alternation doubles without graduating.
    var cur = s.initial(t0);
    var at = t0;
    for (var i = 0; i < 8; i++) {
      at = at.add(const Duration(days: 1));
      cur = scheduled(s.record(cur, RetryResult.correct, at));
      at = at.add(const Duration(days: 1));
      cur = scheduled(s.record(cur, RetryResult.partial, at));
    }
    expect(cur.intervalDays, 30);
    expect(cur.dueAt, at.add(const Duration(days: 30)));
  });

  test('rebuild replays non-voided records in time order (record cancel)', () {
    final events = <RetryEvent>[
      RetryEvent(result: RetryResult.correct, at: day(3)),
      RetryEvent(result: RetryResult.correct, at: day(1)),
    ];
    expect(s.rebuild(t0, events), isA<ReviewGraduated>());

    // Voiding the second 맞음 puts the item back in the queue at 2 days.
    final afterVoid = scheduled(s.rebuild(t0, <RetryEvent>[events[1]]));
    expect(afterVoid.intervalDays, 2);
    expect(afterVoid.consecutiveCorrect, 1);
    expect(afterVoid.dueAt, day(3));

    // Voiding everything → initial schedule.
    expect(scheduled(s.rebuild(t0, const <RetryEvent>[])), s.initial(t0));

    // A 또 틀림 after graduation re-enters (S02b).
    final extra = <RetryEvent>[
      ...events,
      RetryEvent(result: RetryResult.wrong, at: day(9)),
    ];
    final reentered = scheduled(s.rebuild(t0, extra));
    expect(reentered.intervalDays, 1);
    expect(reentered.dueAt, day(10));
  });
}
