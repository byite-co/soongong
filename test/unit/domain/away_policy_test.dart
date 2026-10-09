import 'package:flutter_test/flutter_test.dart';
import 'package:soongong/features/measure/domain/away_policy.dart';

final DateTime t0 = DateTime.utc(2026, 9, 30, 10);
DateTime at(int seconds) => t0.add(Duration(seconds: seconds));

/// Feeds 1 Hz samples: seated until [seatedUntil] (exclusive), then not
/// seated until [until] (inclusive). Returns every event with its second.
List<(int, AwayEvent)> run(
  AwayPolicy p, {
  required int seatedUntil,
  required int until,
}) {
  final out = <(int, AwayEvent)>[];
  for (var s = 0; s <= until; s++) {
    for (final e in p.observe(at: at(s), seated: s < seatedUntil)) {
      out.add((s, e));
    }
  }
  return out;
}

void main() {
  test('threshold per sensitivity level: 60 / 75 / 90 s, clamped', () {
    expect(AwayPolicy.thresholdFor(0), const Duration(seconds: 60));
    expect(AwayPolicy.thresholdFor(1), const Duration(seconds: 75));
    expect(AwayPolicy.thresholdFor(2), const Duration(seconds: 90));
    expect(AwayPolicy.thresholdFor(5), const Duration(seconds: 90));
    expect(AwayPolicy.thresholdFor(-1), const Duration(seconds: 60));
  });

  test('level 0: 59 s not seated → nothing; 60 s → AwayConfirmed starting at '
      'last_seated_at (retroactive)', () {
    final p = AwayPolicy(sensitivityLevel: 0);
    // seated 0..9, not seated from 10; candidate since 10, threshold at 70.
    final events = run(p, seatedUntil: 10, until: 69);
    expect(events, isEmpty);
    expect(p.isAway, isFalse);
    expect(p.awayCandidateSince, at(10));

    final e = p.observe(at: at(70), seated: false).single;
    expect(e, isA<AwayConfirmed>());
    final c = e as AwayConfirmed;
    expect(c.awayStartAt, at(9), reason: 'last seated sample');
    expect(c.confirmedAt, at(70));
    expect(p.isAway, isTrue);
    expect(p.awayCandidateSince, isNull);
  });

  test('level 2: 89 s → nothing, 90 s → confirmed', () {
    final p = AwayPolicy(sensitivityLevel: 2);
    // Not seated from the first sample: candidate since 0 → threshold at 90.
    expect(run(p, seatedUntil: 0, until: 89), isEmpty);
    expect(p.observe(at: at(90), seated: false).single, isA<AwayConfirmed>());
  });

  test('retroactive start is capped at 90 s before the confirming sample', () {
    final p = AwayPolicy(sensitivityLevel: 0, lastSeatedAt: at(0));
    // No samples for a long time, then a burst of not-seated samples 200..260.
    for (var s = 200; s < 260; s++) {
      expect(p.observe(at: at(s), seated: false), isEmpty);
    }
    final c = p.observe(at: at(260), seated: false).single as AwayConfirmed;
    expect(c.awayStartAt, at(260 - 90));
  });

  test('a glance away shorter than the threshold never becomes away', () {
    final p = AwayPolicy(sensitivityLevel: 0);
    expect(run(p, seatedUntil: 5, until: 40), isEmpty);
    expect(p.observe(at: at(41), seated: true), isEmpty);
    expect(p.awayCandidateSince, isNull);
    expect(p.lastSeatedAt, at(41));
    expect(p.isAway, isFalse);
  });

  test('returning emits AwayReturned and re-seats automatically', () {
    final p = AwayPolicy(sensitivityLevel: 0);
    run(p, seatedUntil: 10, until: 70);
    expect(p.isAway, isTrue);
    final e = p.observe(at: at(100), seated: true).single as AwayReturned;
    expect(e.awayStartAt, at(9));
    expect(e.returnedAt, at(100));
    expect(e.awayDuration, const Duration(seconds: 91));
    expect(p.isAway, isFalse);
    expect(p.lastSeatedAt, at(100));
    // A new episode starts a fresh candidate window.
    expect(run(p, seatedUntil: 101, until: 160), isEmpty);
  });

  test('AwayLong fires once after 5 minutes away, not again', () {
    final p = AwayPolicy(sensitivityLevel: 0);
    run(p, seatedUntil: 10, until: 70); // confirmed at 70, start 9
    const longAt = 9 + 300;
    expect(p.observe(at: at(longAt - 1), seated: false), isEmpty);
    expect(p.observe(at: at(longAt), seated: false), isEmpty);
    final e = p.observe(at: at(longAt + 1), seated: false).single;
    expect(e, isA<AwayLong>());
    expect((e as AwayLong).awayStartAt, at(9));
    expect(p.observe(at: at(longAt + 2), seated: false), isEmpty);
    expect(p.observe(at: at(longAt + 60), seated: false), isEmpty);
  });

  test('mid-session level change applies to the next decision; reset clears',
      () {
    final p = AwayPolicy(sensitivityLevel: 0);
    p.sensitivityLevel = 1;
    expect(p.threshold, const Duration(seconds: 75));
    expect(run(p, seatedUntil: 0, until: 74), isEmpty);
    expect(p.observe(at: at(75), seated: false).single, isA<AwayConfirmed>());
    p.reset(seatedAt: at(80));
    expect(p.isAway, isFalse);
    expect(p.awayCandidateSince, isNull);
    expect(p.lastSeatedAt, at(80));
  });
}
