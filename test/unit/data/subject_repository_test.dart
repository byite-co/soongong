import 'package:flutter_test/flutter_test.dart';
import 'package:soongong/core/domain/enums.dart';
import 'package:soongong/core/domain/local_date.dart';
import 'package:soongong/core/strings/subjects_strings.dart';
import 'package:soongong/features/measure/domain/segment.dart';

import 'db_test_helpers.dart';

void main() {
  late TestHarness h;

  setUp(() => h = TestHarness());
  tearDown(() => h.close());

  test('create / watchAll order / update / reorder', () async {
    final a = await h.subjects.create(name: '국어', colorIndex: 0);
    final b = await h.subjects.create(name: '수학', colorIndex: 1);
    expect(a.sortOrder, 0);
    expect(b.sortOrder, 1);
    expect((await h.subjects.getAll()).map((s) => s.name), <String>['국어', '수학']);

    await h.subjects.reorder(<String>[b.id, a.id]);
    expect((await h.subjects.watchAll().first).map((s) => s.name), <String>['수학', '국어']);

    await h.subjects.update(a.id, name: '국어 II');
    expect((await h.subjects.get(a.id))!.name, '국어 II');
    expect((await h.subjects.get(a.id))!.stamp.clientRev, 3, reason: 'reorder + update');
  });

  test('soft delete hides the row without outbox; undo restores; commit '
      'tombstones and moves records to 기타', () async {
    final math = await h.subjects.create(name: '수학', colorIndex: 1);
    final outboxBefore = (await h.outbox()).length;

    await h.subjects.softDelete(math.id);
    expect(await h.subjects.getAll(), isEmpty);
    expect((await h.raw('subjects', math.id))!['pending_delete_until'], isNotNull);
    expect((await h.outbox()).length, outboxBefore, reason: 'no enqueue on soft delete');
    expect((await h.raw('subjects', math.id))!['client_rev'], 1);

    await h.subjects.undoDelete(math.id);
    expect((await h.subjects.getAll()).single.id, math.id);

    // Records pointing at the subject.
    final session = await h.sessions.saveFinished(
      id: 'sess-1',
      kind: SessionKind.study,
      mode: SessionMode.manual,
      startedAt: kT0,
      endedAt: kT0.add(const Duration(minutes: 10)),
      status: SessionStatus.finished,
      segments: <Segment>[
        Segment(id: 'seg-1', kind: SegmentKind.manual, startAt: kT0, endAt: kT0.add(const Duration(minutes: 10))),
      ],
      sensitivityLevel: 0,
      subjectId: math.id,
    );
    final item = await h.planner.createItem(
      kind: PlannerKind.study,
      title: '문제집',
      date: LocalDate.of(kT0),
      subjectId: math.id,
    );

    await h.subjects.softDelete(math.id);
    await h.subjects.commitDelete(math.id);

    final fallback = await h.subjects.ensureDefault();
    expect(fallback.name, SubjectsStrings.defaultSubjectName);
    expect(fallback.isDefault, isTrue);
    expect((await h.sessions.get(session.id))!.subjectId, fallback.id);
    expect((await h.planner.getItem(item.id))!.subjectId, fallback.id);

    final dead = (await h.raw('subjects', math.id))!;
    expect(dead['deleted_at'], isNotNull);
    expect(dead['name'], isNull);
    expect(dead['pending_delete_until'], isNull);
    expect(await h.outboxRow('subjects', math.id), isNotNull);
    expect((await h.subjects.getAll()).map((s) => s.name), <String>[SubjectsStrings.defaultSubjectName]);
  });

  test('the default subject cannot be deleted; ensureDefault is idempotent',
      () async {
    final d1 = await h.subjects.ensureDefault();
    final d2 = await h.subjects.ensureDefault();
    expect(d1.id, d2.id);
    expect(() => h.subjects.softDelete(d1.id), throwsStateError);
    expect(() => h.subjects.commitDelete(d1.id), throwsStateError);
    expect((await h.subjects.getAll()).length, 1);
  });
}
