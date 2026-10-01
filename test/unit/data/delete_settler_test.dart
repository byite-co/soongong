import 'package:flutter_test/flutter_test.dart';
import 'package:soongong/core/domain/enums.dart';
import 'package:soongong/core/domain/local_date.dart';

import 'db_test_helpers.dart';

void main() {
  late TestHarness h;

  setUp(() => h = TestHarness());
  tearDown(() => h.close());

  test('restart settlement (D22): expired pending deletes commit, fresh ones '
      'restore; nothing is enqueued for the restored row', () async {
    final old = await h.planner.createItem(kind: PlannerKind.todo, title: '오래된 삭제', date: LocalDate.of(kT0));
    final fresh = await h.planner.createItem(kind: PlannerKind.todo, title: '방금 삭제', date: LocalDate.of(kT0));
    final rec = await h.planner.createRecurrence(
      title: '학원',
      weekdayMask: 1,
      startTime: LocalTime.parse('19:00'),
      endTime: LocalTime.parse('20:00'),
    );

    await h.planner.softDeleteItem(old.id);
    await h.planner.softDeleteRecurrence(rec.id);
    h.clock.advance(const Duration(seconds: 30)); // both windows expire
    await h.planner.softDeleteItem(fresh.id); // window until +5 s
    h.clock.advance(const Duration(seconds: 2));

    final pending = await h.settler.pending();
    expect(pending.map((p) => p.id), containsAll(<String>[old.id, fresh.id, rec.id]));

    final s = await h.settler.settle();
    expect(s.toCommit.map((p) => p.id), containsAll(<String>[old.id, rec.id]));
    expect(s.toRestore.map((p) => p.id), <String>[fresh.id]);

    expect((await h.raw('planner_items', old.id))!['deleted_at'], isNotNull);
    expect((await h.raw('planner_items', old.id))!['title'], isNull);
    expect((await h.raw('recurrences', rec.id))!['deleted_at'], isNotNull);
    expect((await h.raw('planner_items', fresh.id))!['deleted_at'], isNull);
    expect((await h.raw('planner_items', fresh.id))!['pending_delete_until'], isNull);
    expect((await h.planner.getAllItems()).map((i) => i.id), <String>[fresh.id]);
    expect((await h.outboxRow('planner_items', fresh.id))!.mutationId, isNotNull);
    expect((await h.raw('planner_items', fresh.id))!['client_rev'], 1, reason: 'restore is not a user write');
    expect(await h.settler.pending(), isEmpty);
  });
}
