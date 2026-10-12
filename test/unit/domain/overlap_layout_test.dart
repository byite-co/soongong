import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:soongong/features/timetable/domain/overlap_layout.dart';

void main() {
  test('separate groups recover full width and input order is preserved', () {
    final out = layoutTimetableIntervals(const [
      TimetableInterval(800, 900), TimetableInterval(100, 200), TimetableInterval(150, 250),
    ]);
    expect(out[0].columns, 1);
    expect(out[1].columns, 2);
    expect(out[2].columns, 2);
    expect(out[1].column, isNot(out[2].column));
    expect(out[0].topFraction, 800 / 1440);
  });

  test('touching edges reuse a column', () {
    final out = layoutTimetableIntervals(const [TimetableInterval(60, 120), TimetableInterval(120, 180)]);
    expect(out.map((p) => p.columns), everyElement(1));
  });

  test('nested and chained intervals share a group and reuse free columns', () {
    final out = layoutTimetableIntervals(const [
      TimetableInterval(100, 400), TimetableInterval(120, 200),
      TimetableInterval(200, 300), TimetableInterval(280, 500),
    ]);
    expect(out.map((p) => p.columns), everyElement(3));
    expect(out[1].column, out[2].column);
  });

  test('short blocks expanded at day end remain inside and side by side', () {
    final out = layoutTimetableIntervals(const [TimetableInterval(1438, 1438.5), TimetableInterval(1439, 1439.5)]);
    for (final p in out) {
      expect(p.topFraction, closeTo(0.98, 1e-12));
      expect(p.topFraction + p.heightFraction, lessThanOrEqualTo(1));
      expect(p.columns, 2);
    }
    expect(out[0].column, isNot(out[1].column));
  });

  test('empty input and invalid geometry', () {
    expect(layoutTimetableIntervals(const []), isEmpty);
    expect(() => layoutTimetableIntervals(const [TimetableInterval(1, 1)]), throwsArgumentError);
    expect(() => layoutTimetableIntervals(const [TimetableInterval(double.nan, 3)]), throwsArgumentError);
    expect(() => layoutTimetableIntervals(const [], minHeightFraction: -1), throwsArgumentError);
  });

  test('seeded varied schedules never overlap inside the same visual column', () {
    final random = Random(20261012);
    for (var trial = 0; trial < 150; trial++) {
      final inputs = List.generate(30, (_) {
        final start = random.nextDouble() * 1439;
        return TimetableInterval(start, min(1440, start + 0.5 + random.nextDouble() * 300));
      });
      final out = layoutTimetableIntervals(inputs);
      expect(out.length, inputs.length);
      for (var i = 0; i < out.length; i++) {
        final a = out[i];
        expect(a.topFraction, greaterThanOrEqualTo(0));
        expect(a.topFraction + a.heightFraction, lessThanOrEqualTo(1.0000000001));
        expect(a.leftFraction + a.widthFraction, lessThanOrEqualTo(1.0000000001));
        for (var j = i + 1; j < out.length; j++) {
          final b = out[j];
          final verticalOverlap = a.topFraction < b.topFraction + b.heightFraction &&
              b.topFraction < a.topFraction + a.heightFraction;
          if (verticalOverlap) expect(a.column, isNot(b.column));
        }
      }
    }
  });
}
