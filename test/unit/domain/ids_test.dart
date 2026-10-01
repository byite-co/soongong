import 'package:flutter_test/flutter_test.dart';
import 'package:soongong/core/domain/ids.dart';
import 'package:soongong/core/domain/local_date.dart';

void main() {
  final uuidRe = RegExp(r'^[0-9a-f]{8}-[0-9a-f]{4}-5[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$');

  test('activity_days id is deterministic per (user, date) — two devices agree',
      () {
    final d = LocalDate.parse('2026-09-30');
    final a = activityDayId('user-1', d);
    final b = activityDayId('user-1', const LocalDate(2026, 9, 30));
    expect(a, b);
    expect(uuidRe.hasMatch(a), isTrue, reason: 'uuid v5 layout');
  });

  test('different user or date → different id; v4 ids are unique', () {
    final d = LocalDate.parse('2026-09-30');
    expect(activityDayId('user-1', d), isNot(activityDayId('user-2', d)));
    expect(activityDayId('user-1', d), isNot(activityDayId('user-1', d.addDays(1))));
    expect(newUuid(), isNot(newUuid()));
  });
}
