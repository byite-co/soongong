import 'package:flutter_test/flutter_test.dart';
import 'package:soongong/core/domain/local_date.dart';

void main() {
  group('LocalDate', () {
    test('parse / key round-trip and ordering', () {
      final d = LocalDate.parse('2026-09-30');
      expect(d.key, '2026-09-30');
      expect(d.monthKey, '2026-09');
      expect(d.weekday, DateTime.wednesday);
      expect(d.addDays(1).key, '2026-10-01');
      expect(d.addDays(-30).key, '2026-08-31');
      expect(d.isBefore(LocalDate.parse('2026-10-01')), isTrue);
      expect(d.daysUntil(LocalDate.parse('2026-10-05')), 5);
      expect(LocalDate.tryParse('2026-9-30'), isNull);
      expect(() => LocalDate.parse('nope'), throwsFormatException);
    });

    test('startOfWeek honours the week start setting', () {
      final wed = LocalDate.parse('2026-09-30');
      expect(wed.startOfWeek(1).key, '2026-09-28', reason: 'Monday');
      expect(wed.startOfWeek(7).key, '2026-09-27', reason: 'Sunday');
      expect(wed.startOfWeek(3).key, '2026-09-30', reason: 'Wednesday');
      expect(wed.startOfWeek(4).key, '2026-09-24', reason: 'Thursday');
    });

    test('of() uses the local date of a UTC instant', () {
      final utc = DateTime.utc(2026, 9, 30, 23, 30);
      expect(LocalDate.of(utc), LocalDate.of(utc.toLocal()));
      expect(LocalDate.of(DateTime(2026, 9, 30, 0, 5)).key, '2026-09-30');
    });
  });

  group('LocalTime', () {
    test('parse / key / on(date) / compare', () {
      final t = LocalTime.parse('19:05');
      expect(t.key, '19:05');
      expect(t.minutesOfDay, 19 * 60 + 5);
      expect(t.on(LocalDate.parse('2026-09-30')), DateTime(2026, 9, 30, 19, 5));
      expect(t < LocalTime.parse('19:06'), isTrue);
      expect(LocalTime.tryParse('7:05'), isNull);
      expect(LocalTime.of(DateTime(2026, 1, 1, 7, 5)).key, '07:05');
    });
  });
}
