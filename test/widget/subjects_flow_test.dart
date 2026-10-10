// SubjectsScreen (S09): rows with 이번 주 facts and the 기타 badge, the
// add/edit sheet (validation · colour uniqueness · save), delete → undo,
// delete → committed after the window with records moved to 기타, the
// default subject without a delete row, and the 8-colour cap.

import 'package:drift/drift.dart' show Variable;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soongong/core/domain/enums.dart';
import 'package:soongong/core/domain/local_date.dart';
import 'package:soongong/core/router/app_router.dart';
import 'package:soongong/core/strings/common_strings.dart';
import 'package:soongong/core/strings/home_strings.dart';
import 'package:soongong/core/strings/subjects_strings.dart';
import 'package:soongong/core/widgets/app_toast.dart';
import 'package:soongong/data/auth/auth_mode.dart';
import 'package:soongong/data/repositories/repositories.dart';
import 'package:soongong/features/measure/domain/segment.dart';
import 'package:soongong/features/settings/presentation/settings_screen.dart';
import 'package:soongong/features/subjects/presentation/subjects_screen.dart';

import '../helpers/app_harness.dart';

void main() {
  late AppHarness h;

  setUp(() => h = AppHarness(mode: AuthMode.localOnly));
  tearDown(() => h.dispose());

  SubjectRepository repo() => h.container.read(subjectRepositoryProvider);

  Future<void> openSubjects(WidgetTester tester) async {
    await h.pumpApp(tester);
    await tester.tap(find.byTooltip(HomeStrings.settings));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(SettingsKeys.subjectsRow));
    await tester.pumpAndSettle();
    expect(find.text(SubjectsStrings.title), findsOneWidget);
  }

  Future<void> typeName(WidgetTester tester, String text) async {
    await tester.enterText(find.descendant(of: find.byKey(SubjectsKeys.sheetName), matching: find.byType(TextField)), text);
    await tester.pumpAndSettle();
  }

  Future<void> seedSession(String id, DateTime start, Duration len, String subjectId) => h.container.read(sessionRepositoryProvider).saveFinished(
        id: id,
        kind: SessionKind.study,
        mode: SessionMode.manual,
        startedAt: start,
        endedAt: start.add(len),
        status: SessionStatus.finished,
        segments: <Segment>[Segment(id: '$id-seg', kind: SegmentKind.manual, startAt: start.toUtc(), endAt: start.add(len).toUtc())],
        sensitivityLevel: 0,
        subjectId: subjectId,
      );

  testWidgets('rows: 이번 주 fact per subject, 기록 없음, 기타 badge', (tester) async {
    final math = await repo().create(name: '수학', colorIndex: 0);
    await repo().ensureDefault();
    await seedSession('a', DateTime(2026, 9, 29, 9), const Duration(minutes: 72), math.id);
    await seedSession('old', DateTime(2026, 9, 20, 9), const Duration(hours: 3), math.id);
    await openSubjects(tester);
    expect(find.text(SubjectsStrings.thisWeek('1시간 12분')), findsOneWidget);
    expect(find.text(SubjectsStrings.noRecord), findsOneWidget);
    expect(find.text(SubjectsStrings.defaultBadge), findsOneWidget);
    await h.unmount(tester);
  });

  testWidgets('add: empty · duplicate · colour taken are refused with the input kept; then saved', (tester) async {
    await repo().create(name: '수학', colorIndex: 0);
    await openSubjects(tester);
    await tester.tap(find.byKey(SubjectsKeys.add));
    await tester.pumpAndSettle();
    expect(find.byKey(SubjectsKeys.sheetName), findsOneWidget);
    await tester.tap(find.byKey(SubjectsKeys.save));
    await tester.pumpAndSettle();
    expect(find.text(SubjectsStrings.nameEmpty), findsOneWidget);

    await typeName(tester, ' 수학 ');
    await tester.tap(find.byKey(SubjectsKeys.save));
    await tester.pumpAndSettle();
    expect(find.text(SubjectsStrings.nameDuplicate), findsOneWidget);

    await typeName(tester, '영어');
    await tester.tap(find.byKey(SubjectsKeys.color(0)));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(SubjectsKeys.save));
    await tester.pumpAndSettle();
    expect(find.byKey(SubjectsKeys.sheetName), findsNothing);
    expect(find.text(SubjectsStrings.added), findsOneWidget);
    final all = await repo().getAll();
    final eng = all.firstWhere((s) => s.name == '영어');
    expect(eng.colorIndex, 1, reason: 'first free colour; the taken swatch is not selectable');
    expect(find.text('영어'), findsOneWidget);
    await h.unmount(tester);
  });

  testWidgets('edit: rename + colour → saved', (tester) async {
    final math = await repo().create(name: '수학', colorIndex: 0);
    await openSubjects(tester);
    await tester.tap(find.byKey(SubjectsKeys.row(math.id)));
    await tester.pumpAndSettle();
    expect(find.text(SubjectsStrings.sheetEdit), findsOneWidget);
    await typeName(tester, '수학 I');
    await tester.tap(find.byKey(SubjectsKeys.color(3)));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(SubjectsKeys.save));
    await tester.pumpAndSettle();
    expect(find.text(SubjectsStrings.saved), findsOneWidget);
    final row = (await repo().get(math.id))!;
    expect(row.name, '수학 I');
    expect(row.colorIndex, 3);
    expect(find.text('수학 I'), findsOneWidget);
    await h.unmount(tester);
  });

  testWidgets('delete → undo restores; delete → window elapses → committed, records moved to 기타', (tester) async {
    final math = await repo().create(name: '수학', colorIndex: 0);
    final item = await h.container.read(plannerRepositoryProvider).createItem(
          kind: PlannerKind.todo,
          title: '문제집',
          date: LocalDate.of(kHarnessNow),
          subjectId: math.id,
        );
    await openSubjects(tester);

    Future<void> deleteMath() async {
      await tester.tap(find.byKey(SubjectsKeys.row(math.id)));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(SubjectsKeys.delete));
      await tester.pumpAndSettle();
      expect(find.text(SubjectsStrings.deleteTitle('수학')), findsOneWidget);
      await tester.tap(find.text(SubjectsStrings.deleteConfirm).last);
      await tester.pumpAndSettle();
    }

    await deleteMath();
    expect(find.text(SubjectsStrings.deleted('수학')), findsOneWidget);
    expect(find.byKey(SubjectsKeys.row(math.id)), findsNothing, reason: 'hidden while pending');
    await tester.tap(find.text(CommonStrings.undo));
    await tester.pumpAndSettle();
    expect(find.text(SubjectsStrings.restored), findsOneWidget);
    expect(find.byKey(SubjectsKeys.row(math.id)), findsOneWidget);
    expect((await repo().get(math.id))!.stamp.pendingDeleteUntil, isNull);
    hideAppToast();
    await tester.pump();

    await deleteMath();
    h.clock.advance(const Duration(seconds: 6));
    await tester.pump(const Duration(seconds: 6));
    await tester.pumpAndSettle();
    expect(find.byKey(SubjectsKeys.row(math.id)), findsNothing);
    final raw = await h.db.customSelect('SELECT deleted_at FROM subjects WHERE id = ?', variables: [Variable<String>(math.id)]).getSingle();
    expect(raw.read<String?>('deleted_at'), isNotNull);
    final fallback = await repo().ensureDefault();
    expect((await h.container.read(plannerRepositoryProvider).getItem(item.id))!.subjectId, fallback.id);
    await h.unmount(tester);
  });

  testWidgets('기타: no delete row; eight subjects → 과목 추가 disabled with the colour-cap fact', (tester) async {
    final def = await repo().ensureDefault();
    await openSubjects(tester);
    await tester.tap(find.byKey(SubjectsKeys.row(def.id)));
    await tester.pumpAndSettle();
    expect(find.byKey(SubjectsKeys.delete), findsNothing);
    expect(find.text(SubjectsStrings.defaultCannotDelete), findsOneWidget);
    expect(find.text(SubjectsStrings.defaultColorLocked), findsOneWidget, reason: '§4.3-4: name only');
    await tester.tap(find.byKey(SubjectsKeys.color(2)));
    await tester.pumpAndSettle();
    await typeName(tester, '그 외');
    await tester.tap(find.byKey(SubjectsKeys.save));
    await tester.pumpAndSettle();
    final renamed = (await repo().get(def.id))!;
    expect(renamed.name, '그 외');
    expect(renamed.colorIndex, SubjectRepository.defaultColorIndex, reason: 'colour locked');
    await tester.tap(find.byKey(SubjectsKeys.row(def.id)));
    await tester.pumpAndSettle();
    h.container.read(appRouterProvider).pop();
    await tester.pumpAndSettle();

    for (var i = 0; i < 7; i++) {
      await repo().create(name: '과목$i', colorIndex: i);
    }
    await tester.pumpAndSettle();
    expect(find.byKey(SubjectsKeys.colorsFull), findsOneWidget);
    await tester.tap(find.byKey(SubjectsKeys.add));
    await tester.pumpAndSettle();
    expect(find.byKey(SubjectsKeys.sheetName), findsNothing, reason: 'disabled');
    await h.unmount(tester);
  });
}
