import 'package:flutter_test/flutter_test.dart';
import 'package:soongong/core/utils/time_format.dart';

void main() {
  test('formatDuration', () {
    expect(formatDuration(const Duration(hours: 1, minutes: 28)), '1시간 28분');
    expect(formatDuration(const Duration(minutes: 45)), '45분');
    expect(formatDuration(const Duration(hours: 2)), '2시간');
    expect(formatDuration(Duration.zero), '0분');
    expect(formatDuration(const Duration(minutes: -5)), '0분');
    expect(formatDuration(const Duration(seconds: 59)), '0분');
  });

  test('formatTimeRange / formatClock', () {
    final s = DateTime(2026, 8, 20, 19, 32);
    final e = DateTime(2026, 8, 20, 21, 3);
    expect(formatClock(s), '19:32');
    expect(formatTimeRange(s, e), '19:32 – 21:03');
  });

  test('hourOfDay', () {
    expect(hourOfDay(DateTime(2026, 1, 1, 6, 30)), 6.5);
    expect(hourOfDay(DateTime(2026, 1, 1)), 0);
  });
}
