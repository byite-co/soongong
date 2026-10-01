import 'package:flutter_test/flutter_test.dart';
import 'package:soongong/core/domain/entities/entities.dart';
import 'package:soongong/features/reading/domain/reading_quota_policy.dart';

void main() {
  const policy = ReadingQuotaPolicy();

  test('no ledger, or a ledger of another month → unknown (not 20/20)', () {
    final v = policy.view(null, month: '2026-09');
    expect(v.isKnown, isFalse);
    expect(v.hasRemaining, isFalse);
    expect(v.limit, 20);

    const old = ReadingQuota(userId: 'u', month: '2026-08', used: 3, reserved: 0, limit: 20);
    expect(policy.view(old, month: '2026-09').isKnown, isFalse);
  });

  test('remaining = limit − used − reserved, clamped; display only', () {
    const q = ReadingQuota(userId: 'u', month: '2026-09', used: 17, reserved: 1, limit: 20);
    final v = policy.view(q, month: '2026-09');
    expect(v.isKnown, isTrue);
    expect(v.remaining, 2);
    expect(v.hasRemaining, isTrue);
    expect(q.remaining, 2);
    expect(q.toSnapshot(DateTime.utc(2026)).remaining, 2);

    const exhausted = ReadingQuota(userId: 'u', month: '2026-09', used: 20, reserved: 3, limit: 20);
    expect(policy.view(exhausted, month: '2026-09').remaining, 0);
    expect(policy.view(exhausted, month: '2026-09').hasRemaining, isFalse);
  });

  test('monthKey is the local yyyy-MM', () {
    expect(ReadingQuotaPolicy.monthKey(DateTime(2026, 9, 30, 23, 59)), '2026-09');
    expect(ReadingQuotaPolicy.monthKey(DateTime(2026, 1, 1)), '2026-01');
  });
}
