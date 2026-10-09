// PlannerController (S07): save outcomes per target, failure keeps the
// input (no row), subject creation, delete → undo / commit after the
// window, and stale writes refused after dispose or an account rebind.

import 'package:flutter_test/flutter_test.dart';
import 'package:soongong/core/domain/enums.dart';
import 'package:soongong/core/domain/local_date.dart';
import 'package:soongong/data/db/app_database.dart';
import 'package:soongong/data/repositories/sync_writer.dart';
import 'package:soongong/features/planner/application/planner_controller.dart';
import 'package:soongong/features/planner/domain/planner_draft.dart';

import '../data/db_test_helpers.dart';

void main() {
  late TestHarness h;
  late PlannerController c;
  final day = LocalDate.parse('2026-09-30');

  setUp(() {
    h = TestHarness();
    c = PlannerController(planner: h.planner, subjects: h.subjects, undoWindow: Duration.zero);
  });
  tearDown(() async {
    c.dispose();
    await h.close();
  });

  Future<int> outboxCount() async =>
      (await h.db.customSelect('SELECT COUNT(*) AS n FROM sync_outbox').getSingle()).read<int>('n');

  group('save', () {
    test('new study item · todo · self · band · recurrence', () async {
      final study = await c.save(
        PlannerDraft.create(date: day).copyWith(title: ' 수학 ', subjectId: 'm', rangeText: ' p.1–5 ', targetMinutes: 45),
        const NewEntry(),
      );
      final id = (study as PlannerSaved).id;
      final row = (await h.planner.getItem(id))!;
      expect(row.kind, PlannerKind.study);
      expect(row.title, '수학');
      expect(row.rangeText, 'p.1–5');
      expect(row.targetMinutes, 45);
      expect(row.subjectId, 'm');
      expect(row.date, day);

      final todo = await c.save(PlannerDraft.create(date: day, kind: PlannerKind.todo).copyWith(title: '프린트'), const NewEntry());
      final todoRow = (await h.planner.getItem((todo as PlannerSaved).id))!;
      expect(todoRow.targetMinutes, isNull);
      expect(todoRow.rangeText, isNull);

      final self = await c.save(PlannerDraft.create(date: day, kind: PlannerKind.self).copyWith(title: '자습'), const NewEntry());
      expect((await h.planner.getItem((self as PlannerSaved).id))!.targetMinutes, 30);

      final band = await c.save(
        PlannerDraft.create(date: day, kind: PlannerKind.event)
            .copyWith(title: '중간고사', bandStart: LocalDate.parse('2026-10-05'), bandEnd: LocalDate.parse('2026-10-08')),
        const NewEntry(),
      );
      final bandRow = (await h.planner.getItem((band as PlannerSaved).id))!;
      expect(bandRow.isBand, isTrue);
      expect(bandRow.date.key, '2026-10-05');
      expect(bandRow.bandEnd!.key, '2026-10-08');

      final rec = await c.save(
        PlannerDraft.create(date: day, kind: PlannerKind.event).copyWith(
          title: '학원',
          eventMode: DraftEventMode.repeat,
          weekdays: <int>{1, 3},
          startTime: const LocalTime(19, 0),
          endTime: const LocalTime(21, 0),
          endOption: RecurrenceEndOption.endOfMonth,
        ),
        const NewEntry(),
      );
      final recRow = (await h.planner.getRecurrence((rec as PlannerSaved).id))!;
      expect(recRow.weekdayMask, 1 | 4);
      expect(recRow.endsOn!.key, '2026-09-30');
      expect(recRow.startTime.key, '19:00');
      expect(await outboxCount(), 5);
    });

    test('edit item / band / recurrence writes only the applicable fields', () async {
      final item = await h.planner.createItem(kind: PlannerKind.study, title: '수학', date: day, targetMinutes: 30, subjectId: 'm');
      final d = PlannerDraft.fromItem(item).copyWith(title: '수학 2', date: LocalDate.parse('2026-10-01')).withKind(PlannerKind.todo);
      expect(await c.save(d, ExistingItem(item.id)), isA<PlannerSaved>());
      final edited = (await h.planner.getItem(item.id))!;
      expect(edited.kind, PlannerKind.todo);
      expect(edited.title, '수학 2');
      expect(edited.targetMinutes, isNull);
      expect(edited.date.key, '2026-10-01');
      expect(edited.subjectId, 'm');

      final band = await h.planner.createItem(
        kind: PlannerKind.event,
        title: '시험',
        date: LocalDate.parse('2026-10-05'),
        bandStart: LocalDate.parse('2026-10-05'),
        bandEnd: LocalDate.parse('2026-10-06'),
      );
      final bd = PlannerDraft.fromItem(band).copyWith(bandStart: LocalDate.parse('2026-10-04'), bandEnd: LocalDate.parse('2026-10-07'), title: '기말');
      expect(await c.save(bd, ExistingBand(band.id)), isA<PlannerSaved>());
      final bandRow = (await h.planner.getItem(band.id))!;
      expect(bandRow.title, '기말');
      expect(bandRow.date.key, '2026-10-04');
      expect(bandRow.bandStart!.key, '2026-10-04');
      expect(bandRow.bandEnd!.key, '2026-10-07');

      final rec = await h.planner.createRecurrence(
        title: '학원',
        weekdayMask: 1,
        startTime: const LocalTime(19, 0),
        endTime: const LocalTime(21, 0),
      );
      final rd = PlannerDraft.fromRecurrence(rec, date: day).copyWith(weekdays: <int>{2, 4}, endOption: RecurrenceEndOption.date, endsOn: LocalDate.parse('2026-12-31'));
      expect(await c.save(rd, ExistingRecurrence(rec.id)), isA<PlannerSaved>());
      final recRow = (await h.planner.getRecurrence(rec.id))!;
      expect(recRow.weekdayMask, 2 | 8);
      expect(recRow.endsOn!.key, '2026-12-31');
    });

    test('invalid draft → failed without writing; DB failure → failed, retry succeeds', () async {
      final empty = await c.save(PlannerDraft.create(date: day), const NewEntry());
      expect(empty, isA<PlannerSaveFailed>());
      expect((empty as PlannerSaveFailed).error, isA<DraftInvalid>());
      expect(await h.planner.getAllItems(), isEmpty);

      await h.db.customStatement(
        "CREATE TRIGGER fail_insert BEFORE INSERT ON planner_items BEGIN SELECT RAISE(ABORT, 'boom'); END;",
      );
      final draft = PlannerDraft.create(date: day).copyWith(title: '수학');
      final failed = await c.save(draft, const NewEntry());
      expect(failed, isA<PlannerSaveFailed>());
      expect(await h.planner.getAllItems(), isEmpty);
      expect(await outboxCount(), 0, reason: 'transaction rolled back');

      await h.db.customStatement('DROP TRIGGER fail_insert');
      expect(await c.save(draft, const NewEntry()), isA<PlannerSaved>());
      expect((await h.planner.getAllItems()).single.title, '수학');
    });

    test('addSubject · setDone', () async {
      final s = await c.addSubject(name: ' 한국사 ', colorIndex: 9);
      expect(s.name, '한국사');
      expect(s.colorIndex, 1);
      await expectLater(c.addSubject(name: ' ', colorIndex: 0), throwsArgumentError);
      final item = await h.planner.createItem(kind: PlannerKind.todo, title: 't', date: day);
      await c.setDone(item.id, done: true);
      expect((await h.planner.getItem(item.id))!.isDone, isTrue);
    });
  });

  group('delete (D22)', () {
    test('item: soft delete → undo restores; soft delete → window → commit tombstone + outbox', () async {
      final item = await h.planner.createItem(kind: PlannerKind.study, title: '수학', date: day);
      final before = await outboxCount();
      final pending = await c.delete(ExistingItem(item.id));
      expect((await h.raw('planner_items', item.id))!['pending_delete_until'], isNotNull);
      expect(await h.planner.getAllItems(), isEmpty, reason: 'hidden while pending');
      expect(await pending.undo(), isTrue);
      expect((await h.raw('planner_items', item.id))!['pending_delete_until'], isNull);
      expect((await h.planner.getAllItems()).single.id, item.id);
      expect(await pending.undo(), isFalse, reason: 'undo runs at most once');
      expect(await outboxCount(), before, reason: 'no outbox write while pending/undone');

      final again = await c.delete(ExistingItem(item.id));
      h.clock.advance(const Duration(seconds: 6));
      await Future<void>.delayed(const Duration(milliseconds: 20));
      final row = (await h.raw('planner_items', item.id))!;
      expect(row['deleted_at'], isNotNull);
      expect(row['pending_delete_until'], isNull);
      expect(await outboxCount(), before, reason: 'one outbox row per entity: the create row now carries the tombstone mutation');
      final outbox = await h.db.customSelect("SELECT sent_client_rev FROM sync_outbox WHERE row_id = '${item.id}'").get();
      expect(outbox.length, 1);
      expect(await again.undo(), isFalse, reason: 'already committed');
    });

    test('commit is skipped while the window has not elapsed on the clock', () async {
      final item = await h.planner.createItem(kind: PlannerKind.todo, title: 't', date: day);
      await c.delete(ExistingItem(item.id));
      // Timer (zero) fires but the clock did not reach pending_delete_until.
      await Future<void>.delayed(const Duration(milliseconds: 20));
      final row = (await h.raw('planner_items', item.id))!;
      expect(row['deleted_at'], isNull);
      expect(row['pending_delete_until'], isNotNull, reason: 'left for the restart settlement');
    });

    test('recurrence and band follow the same path', () async {
      final rec = await h.planner.createRecurrence(title: '학원', weekdayMask: 1, startTime: const LocalTime(19, 0), endTime: const LocalTime(20, 0));
      final p = await c.delete(ExistingRecurrence(rec.id));
      expect(await h.planner.getRecurrences(), isEmpty);
      expect(await p.undo(), isTrue);
      expect((await h.planner.getRecurrences()).single.id, rec.id);
      final band = await h.planner.createItem(kind: PlannerKind.event, title: 'b', date: day, bandStart: day, bandEnd: day);
      await c.delete(ExistingBand(band.id));
      h.clock.advance(const Duration(seconds: 6));
      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect((await h.raw('planner_items', band.id))!['deleted_at'], isNotNull);
    });

    test('disposed controller: no commit, undo false, save failed; DB bound to another account refuses', () async {
      final item = await h.planner.createItem(kind: PlannerKind.todo, title: 't', date: day);
      final pending = await c.delete(ExistingItem(item.id));
      c.dispose();
      h.clock.advance(const Duration(seconds: 6));
      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect((await h.raw('planner_items', item.id))!['deleted_at'], isNull, reason: 'stale timer never commits');
      expect(await pending.undo(), isFalse);
      expect(await c.save(PlannerDraft.create(date: day).copyWith(title: 'x'), const NewEntry()), isA<PlannerSaveFailed>());
      await expectLater(c.delete(ExistingItem(item.id)), throwsStateError);

      final c2 = PlannerController(planner: h.planner, subjects: h.subjects, undoWindow: Duration.zero);
      await h.db.into(h.db.syncMeta).insert(SyncMetaCompanion.insert(key: SyncWriter.accountUserIdKey, value: 'u2'));
      final refused = await c2.save(PlannerDraft.create(date: day).copyWith(title: 'y'), const NewEntry());
      expect(refused, isA<PlannerSaveFailed>());
      expect((await h.planner.getAllItems()).where((i) => i.title == 'y'), isEmpty);
      await expectLater(c2.delete(ExistingItem(item.id)), throwsStateError);
      c2.dispose();
    });
  });
}
