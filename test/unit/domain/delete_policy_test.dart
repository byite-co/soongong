import 'package:flutter_test/flutter_test.dart';
import 'package:soongong/core/domain/delete_policy.dart';

void main() {
  const policy = DeletePolicy();
  final now = DateTime.utc(2026, 9, 30, 12);

  test('deadline is now + 5 s; expiry is inclusive of the deadline', () {
    expect(policy.deadline(now), now.add(const Duration(seconds: 5)));
    expect(policy.isExpired(now.add(const Duration(seconds: 5)), now.add(const Duration(seconds: 5))), isTrue);
    expect(policy.isExpired(now.add(const Duration(seconds: 5)), now.add(const Duration(milliseconds: 4999))), isFalse);
  });

  test('settle on restart: expired → commit, still pending → restore', () {
    final pending = <PendingDelete>[
      PendingDelete(table: 'sessions', id: 'old', pendingDeleteUntil: now.subtract(const Duration(hours: 1))),
      PendingDelete(table: 'planner_items', id: 'edge', pendingDeleteUntil: now),
      PendingDelete(table: 'subjects', id: 'fresh', pendingDeleteUntil: now.add(const Duration(seconds: 3))),
    ];
    final s = policy.settle(pending, now);
    expect(s.toCommit.map((p) => p.id), <String>['old', 'edge']);
    expect(s.toRestore.map((p) => p.id), <String>['fresh']);
    expect(DeletePolicy.tables, containsAll(<String>['subjects', 'sessions', 'planner_items', 'recurrences']));
  });
}
