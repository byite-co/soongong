// SubjectsController (S09): save outcomes (created · updated · invalid ·
// failed, input kept), delete → undo inside the window, delete → commit
// after the window (records move to 기타), the default subject refused,
// stale writes refused after dispose.

import 'package:flutter_test/flutter_test.dart';
import 'package:soongong/core/domain/enums.dart';
import 'package:soongong/core/domain/local_date.dart';
import 'package:soongong/features/subjects/application/subjects_controller.dart';
import 'package:soongong/features/subjects/domain/subject_draft.dart';

import '../data/db_test_helpers.dart';

void main() {
  late TestHarness h;
  late SubjectsController c;

  setUp(() {
    h = TestHarness();
    c = SubjectsController(subjects: h.subjects, undoWindow: Duration.zero);
  });
  tearDown(() async {
    c.dispose();
    await h.close();
  });

  test('save: create · update · invalid keeps nothing written', () async {
    final created = await c.save(const SubjectDraft(name: ' 수학 ', colorIndex: 0));
    final id = (created as SubjectSaved).id;
    expect((await h.subjects.get(id))!.name, '수학');

    final dup = await c.save(const SubjectDraft(name: '수학', colorIndex: 1));
    expect((dup as SubjectSaveInvalid).errors, [SubjectDraftError.nameDuplicate]);
    final taken = await c.save(const SubjectDraft(name: '영어', colorIndex: 0));
    expect((taken as SubjectSaveInvalid).errors, [SubjectDraftError.colorTaken]);
    expect((await h.subjects.getAll()).length, 1);

    final updated = await c.save(const SubjectDraft(name: '수학 I', colorIndex: 2), id: id);
    expect(updated, isA<SubjectSaved>());
    final row = (await h.subjects.get(id))!;
    expect(row.name, '수학 I');
    expect(row.colorIndex, 2);
    expect(await c.save(const SubjectDraft(name: '수학 I', colorIndex: 2), id: id), isA<SubjectSaved>(), reason: 'own name/colour');
  });

  test('delete → undo: row restored, nothing moved', () async {
    final math = await h.subjects.create(name: '수학', colorIndex: 0);
    final item = await h.planner.createItem(kind: PlannerKind.todo, title: '문제집', date: LocalDate.of(kT0), subjectId: math.id);
    c = SubjectsController(subjects: h.subjects, undoWindow: const Duration(seconds: 5));
    final pending = await c.delete(math.id);
    expect(await h.subjects.getAll(), isEmpty, reason: 'hidden while pending');
    expect((await h.subjects.get(math.id))!.stamp.pendingDeleteUntil, isNotNull);
    expect(await pending.undo(), isTrue);
    expect((await h.subjects.getAll()).map((s) => s.id), [math.id]);
    expect((await h.planner.getItem(item.id))!.subjectId, math.id);
    expect(await pending.undo(), isFalse, reason: 'once');
  });

  test('delete → window elapses → committed, records move to 기타', () async {
    final math = await h.subjects.create(name: '수학', colorIndex: 0);
    final item = await h.planner.createItem(kind: PlannerKind.todo, title: '문제집', date: LocalDate.of(kT0), subjectId: math.id);
    final pending = await c.delete(math.id);
    h.clock.advance(const Duration(seconds: 5)); // the row's own window (D22)
    await Future<void>.delayed(const Duration(milliseconds: 20));
    final other = await h.subjects.ensureDefault();
    expect((await h.raw('subjects', math.id))!['deleted_at'], isNotNull);
    expect((await h.planner.getItem(item.id))!.subjectId, other.id);
    expect(await pending.undo(), isFalse, reason: 'already committed');
  });

  test('the default subject cannot be deleted; a disposed controller refuses', () async {
    final def = await h.subjects.ensureDefault();
    expect(() => c.delete(def.id), throwsStateError);
    c.dispose();
    expect(await c.save(const SubjectDraft(name: '국어', colorIndex: 1)), isA<SubjectSaveFailed>());
    expect(() => c.delete(def.id), throwsStateError);
  });
}
