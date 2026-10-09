// BirthDateInput (S05 · D6): client range check + the boundary the server
// decides on ("오늘 생일 만 14세") expressed through the same yyyy-MM-dd key.

import 'package:flutter_test/flutter_test.dart';
import 'package:soongong/data/auth/auth_models.dart';
import 'package:soongong/features/gate/domain/birth_date_input.dart';

/// Mirror of `supabase/functions/_shared/ticket.ts isAtLeast14` (KST date).
bool isAtLeast14Kst(String birthKey, DateTime nowUtc) {
  final parts = birthKey.split('-').map(int.parse).toList();
  final kst = nowUtc.toUtc().add(const Duration(hours: 9));
  var age = kst.year - parts[0];
  if (kst.month < parts[1] || (kst.month == parts[1] && kst.day < parts[2])) age -= 1;
  return age >= 14;
}

void main() {
  final today = DateTime(2026, 10, 3, 12);

  group('validate', () {
    test('a normal date passes and keeps year/month/day', () {
      final d = const BirthDateInput(year: 2010, month: 3, day: 7).validate(today);
      expect(d, DateTime(2010, 3, 7));
      expect(birthDateKey(d!), '2010-03-07');
    });

    test('today is allowed, tomorrow is not (future)', () {
      expect(const BirthDateInput(year: 2026, month: 10, day: 3).validate(today), isNotNull);
      expect(const BirthDateInput(year: 2026, month: 10, day: 4).validate(today), isNull);
    });

    test('150 years back is the oldest year', () {
      expect(const BirthDateInput(year: 1876, month: 1, day: 1).validate(today), isNotNull);
      expect(const BirthDateInput(year: 1875, month: 12, day: 31).validate(today), isNull);
    });

    test('impossible calendar days are rejected; copyWith clamps the day', () {
      expect(const BirthDateInput(year: 2011, month: 2, day: 29).validate(today), isNull);
      expect(const BirthDateInput(year: 2012, month: 2, day: 29).validate(today), isNotNull);
      final clamped = const BirthDateInput(year: 2012, month: 1, day: 31).copyWith(month: 2);
      expect(clamped.day, 29);
    });

    test('initial position is 15 years back, 1 January', () {
      final i = BirthDateInput.initial(today);
      expect((i.year, i.month, i.day), (2011, 1, 1));
    });

    test('toString never prints the date', () {
      expect(const BirthDateInput(year: 2010, month: 3, day: 7).toString(), isNot(contains('2010')));
    });
  });

  group('server boundary (same key the app sends)', () {
    // 2026-10-03 03:00Z = 12:00 KST on 2026-10-03.
    final nowUtc = DateTime.utc(2026, 10, 3, 3);

    test('14th birthday today → allowed', () {
      expect(isAtLeast14Kst(birthDateKey(DateTime(2012, 10, 3)), nowUtc), isTrue);
    });

    test('14th birthday tomorrow → blocked', () {
      expect(isAtLeast14Kst(birthDateKey(DateTime(2012, 10, 4)), nowUtc), isFalse);
    });

    test('the KST date decides, not the UTC date', () {
      // 2026-10-02 16:00Z is already 2026-10-03 01:00 KST.
      final lateUtc = DateTime.utc(2026, 10, 2, 16);
      expect(isAtLeast14Kst('2012-10-03', lateUtc), isTrue);
    });
  });
}
