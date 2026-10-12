// SubjectDraft (S09): name rules (trimmed · ≤ 20 · unique, case-insensitive)
// and the one-colour-per-subject rule against the live list; the editing
// subject never collides with itself.

import 'package:flutter_test/flutter_test.dart';
import 'package:soongong/core/domain/entities/entities.dart';
import 'package:soongong/features/subjects/domain/subject_draft.dart';

void main() {
  final t0 = DateTime(2026, 10, 3);
  final stamp = SyncStamp(userId: 'u', createdAt: t0, clientUpdatedAt: t0, deviceId: 'd');
  Subject s(String id, String name, int color) => Subject(id: id, stamp: stamp, name: name, colorIndex: color, sortOrder: 0);
  final live = <Subject>[s('m', '수학', 0), s('e', 'English', 3), s('o', '기타', 7)];

  test('valid draft: trimmed name, free colour', () {
    expect(const SubjectDraft(name: ' 한국사 ', colorIndex: 1).validate(live), isEmpty);
    expect(const SubjectDraft(name: ' 한국사 ').trimmedName, '한국사');
  });

  test('name: empty · too long · duplicate (case-insensitive, trimmed)', () {
    expect(const SubjectDraft(name: '  ', colorIndex: 1).validate(live), [SubjectDraftError.nameEmpty]);
    expect(SubjectDraft(name: 'ㄱ' * 21, colorIndex: 1).validate(live), [SubjectDraftError.nameTooLong]);
    expect(SubjectDraft(name: 'ㄱ' * 20, colorIndex: 1).validate(live), isEmpty);
    expect(const SubjectDraft(name: ' english', colorIndex: 1).validate(live), [SubjectDraftError.nameDuplicate]);
    expect(const SubjectDraft(name: 'English', colorIndex: 3).validate(live, editingId: 'e'), isEmpty, reason: 'editing itself');
  });

  test('colour: taken by another live subject', () {
    expect(const SubjectDraft(name: '한국사', colorIndex: 0).validate(live), [SubjectDraftError.colorTaken]);
    expect(const SubjectDraft(name: '수학', colorIndex: 0).validate(live, editingId: 'm'), isEmpty);
    expect(SubjectDraft.takenColors(live), <int>{0, 3, 7});
    expect(SubjectDraft.takenColors(live, editingId: 'm'), <int>{3, 7});
    expect(const SubjectDraft(name: '', colorIndex: 0).validate(live), [SubjectDraftError.nameEmpty, SubjectDraftError.colorTaken]);
  });

  test('firstFreeColor skips taken colours and is null when all 8 are used', () {
    expect(SubjectDraft.firstFreeColor(live), 1);
    final full = <Subject>[for (var i = 0; i < 8; i++) s('s$i', '과목$i', i)];
    expect(SubjectDraft.firstFreeColor(full), isNull);
    expect(SubjectDraft.firstFreeColor(const <Subject>[]), 0);
  });

  test('fromSubject · differsFrom', () {
    final d = SubjectDraft.fromSubject(live.first);
    expect(d.differsFrom(live.first), isFalse);
    expect(d.copyWith(name: '수학 ').differsFrom(live.first), isFalse, reason: 'trimmed');
    expect(d.copyWith(colorIndex: 2).differsFrom(live.first), isTrue);
  });
}
