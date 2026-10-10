// TimetableScreen (S08) in the local-only dev mode: empty state, blocks
// from clipped segments (midnight split), block → session detail, week
// swipe / arrows / 이번 주, week start setting, recurrences (row summary,
// edit sheet, whole delete with undo and commit), tablet two columns, dark
// theme, current-time line.

import 'package:drift/drift.dart' show Variable;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soongong/core/domain/entities/entities.dart';
import 'package:soongong/core/domain/enums.dart';
import 'package:soongong/core/domain/local_date.dart';
import 'package:soongong/core/router/app_router.dart';
import 'package:soongong/core/strings/common_strings.dart';
import 'package:soongong/core/strings/measure_strings.dart';
import 'package:soongong/core/strings/planner_strings.dart';
import 'package:soongong/core/strings/timetable_strings.dart';
import 'package:soongong/core/theme/app_theme.dart';
import 'package:soongong/core/widgets/widgets.dart';
import 'package:soongong/data/auth/auth_mode.dart';
import 'package:soongong/data/repositories/repositories.dart';
import 'package:soongong/features/measure/domain/segment.dart';
import 'package:soongong/features/planner/presentation/planner_item_sheet.dart';
import 'package:soongong/features/timetable/presentation/timetable_screen.dart';

import '../helpers/app_harness.dart';

void main() {
  late AppHarness h;

  setUp(() => h = AppHarness(mode: AuthMode.localOnly));
  tearDown(() => h.dispose());

  Future<void> openTimetable(WidgetTester tester, {Size size = kPhone}) async {
    await h.pumpApp(tester, size: size);
    await tester.tap(find.text(CommonStrings.tabTimetable).last);
    await tester.pumpAndSettle();
  }

  Future<void> seedSession({
    required String id,
    required DateTime start,
    required DateTime end,
    String? subjectId,
    SessionKind kind = SessionKind.study,
  }) =>
      h.container.read(sessionRepositoryProvider).saveFinished(
            id: id,
            kind: kind,
            mode: SessionMode.camera,
            startedAt: start,
            endedAt: end,
            status: SessionStatus.finished,
            subjectId: subjectId,
            segments: <Segment>[
              Segment(id: '$id-seg', kind: SegmentKind.seated, startAt: start.toUtc(), endAt: end.toUtc()),
            ],
            sensitivityLevel: 0,
          );

  /// The recurrence list sits under the grid in a lazy ListView.
  Future<void> reveal(WidgetTester tester, Finder target) async {
    await tester.scrollUntilVisible(
      target,
      200,
      scrollable: find.descendant(of: find.byType(ListView).first, matching: find.byType(Scrollable)).first,
    );
    await tester.pumpAndSettle();
  }

  Future<Recurrence> seedRecurrence({String title = '수학 학원', String? subjectId}) =>
      h.container.read(plannerRepositoryProvider).createRecurrence(
            title: title,
            weekdayMask: Recurrence.maskOf(const <int>[6, 7]),
            startTime: const LocalTime(16, 0),
            endTime: const LocalTime(17, 30),
            subjectId: subjectId,
          );

  testWidgets('empty week: title, range, empty card with next actions, recurrences hint; 집중 시작 → setup', (tester) async {
    await openTimetable(tester);
    expect(find.descendant(of: find.byType(TimetableScreen), matching: find.text(TimetableStrings.title)), findsOneWidget);
    expect(find.text(TimetableStrings.weekRange(9, 28, 10, 4)), findsOneWidget);
    expect(find.byKey(TimetableKeys.empty), findsOneWidget);
    expect(find.text(TimetableStrings.emptyTitle), findsOneWidget);
    expect(find.byKey(TimetableKeys.grid), findsNothing);
    expect(find.text(TimetableStrings.recurrencesEmpty), findsOneWidget);
    expect(find.byKey(TimetableKeys.thisWeek), findsNothing);

    await tester.tap(find.byKey(TimetableKeys.emptyStart));
    await tester.pumpAndSettle();
    expect(find.text(MeasureStrings.setup), findsWidgets);
    await h.unmount(tester);
  });

  testWidgets('blocks: midnight session on both days, self orange, week total, now line, block → session detail', (tester) async {
    final math = await h.container.read(subjectRepositoryProvider).create(name: '수학', colorIndex: 0);
    await seedSession(id: 'a', start: DateTime(2026, 10, 2, 23, 20), end: DateTime(2026, 10, 3, 0, 40), subjectId: math.id);
    await seedSession(id: 'b', start: DateTime(2026, 10, 3, 9), end: DateTime(2026, 10, 3, 10, 15), kind: SessionKind.self);
    await seedSession(id: 'c', start: DateTime(2026, 9, 27, 23), end: DateTime(2026, 9, 28, 1));
    await openTimetable(tester);

    expect(find.byKey(TimetableKeys.grid), findsOneWidget);
    expect(find.byKey(TimetableKeys.empty), findsNothing);
    expect(find.text(TimetableStrings.weekSeated('3시간 35분')), findsOneWidget, reason: '40 + 40 + 75 + 60 min inside the week');
    expect(find.byKey(TimetableKeys.block('a', const LocalDate(2026, 10, 2), 0)), findsOneWidget);
    expect(find.byKey(TimetableKeys.block('a', const LocalDate(2026, 10, 3), 0)), findsOneWidget);
    expect(find.byKey(TimetableKeys.block('b', const LocalDate(2026, 10, 3), 1)), findsOneWidget);
    expect(find.byKey(TimetableKeys.block('c', const LocalDate(2026, 9, 28), 0)), findsOneWidget);
    expect(find.byKey(TimetableKeys.block('c', const LocalDate(2026, 9, 27), 0)), findsNothing, reason: 'previous week');
    expect(find.byKey(TimetableKeys.nowLine), findsOneWidget);
    expect(find.text(TimetableStrings.blockSelf), findsWidgets);

    const c = AppColors.light;
    final self = tester.widget<Container>(
      find.descendant(of: find.byKey(TimetableKeys.block('b', const LocalDate(2026, 10, 3), 1)), matching: find.byType(Container)).first,
    );
    expect((self.decoration! as BoxDecoration).color, c.acc, reason: '자습 is orange');
    final study = tester.widget<Container>(
      find.descendant(of: find.byKey(TimetableKeys.block('a', const LocalDate(2026, 10, 3), 0)), matching: find.byType(Container)).first,
    );
    expect((study.decoration! as BoxDecoration).color, c.subject(0));

    await tester.tap(find.byKey(TimetableKeys.block('b', const LocalDate(2026, 10, 3), 1)));
    await tester.pumpAndSettle();
    expect(find.text(MeasureStrings.detail), findsWidgets);
    h.container.read(appRouterProvider).pop();
    await tester.pumpAndSettle();
    expect(find.byKey(TimetableKeys.grid), findsOneWidget);
    await h.unmount(tester);
  });

  testWidgets('week navigation: swipe, 이번 주, arrows; week start setting moves the range', (tester) async {
    await openTimetable(tester);
    await tester.drag(find.byKey(TimetableKeys.pager), const Offset(-400, 0));
    await tester.pumpAndSettle();
    expect(find.text(TimetableStrings.weekRange(10, 5, 10, 11)), findsOneWidget);
    expect(find.byKey(TimetableKeys.thisWeek), findsOneWidget);

    await tester.tap(find.byKey(TimetableKeys.thisWeek));
    await tester.pumpAndSettle();
    expect(find.text(TimetableStrings.weekRange(9, 28, 10, 4)), findsOneWidget);
    expect(find.byKey(TimetableKeys.thisWeek), findsNothing);

    await tester.tap(find.byKey(TimetableKeys.prev));
    await tester.pumpAndSettle();
    expect(find.text(TimetableStrings.weekRange(9, 21, 9, 27)), findsOneWidget);
    await tester.tap(find.byKey(TimetableKeys.next));
    await tester.pumpAndSettle();
    expect(find.text(TimetableStrings.weekRange(9, 28, 10, 4)), findsOneWidget);

    await h.container.read(settingsRepositoryProvider).setWeekStart(7);
    await tester.pumpAndSettle();
    expect(find.text(TimetableStrings.weekRange(9, 27, 10, 3)), findsOneWidget);
    await h.unmount(tester);
  });

  testWidgets('recurrences: row summary and grid block; delete → confirm → undo restores; delete again → commit after 5 s', (tester) async {
    final r = await seedRecurrence();
    await openTimetable(tester);
    expect(find.byKey(TimetableKeys.grid), findsOneWidget, reason: '[S08b] recurrences are drawn on the grid even without 순공');
    await reveal(tester, find.byKey(TimetableKeys.recurrenceRow(r.id)));
    expect(find.text('수학 학원'), findsWidgets);
    expect(find.text(TimetableStrings.recurrenceSummary('토·일', '16:00', '17:30')), findsOneWidget);
    expect(find.byKey(TimetableKeys.recurrenceBlock(r.id, const LocalDate(2026, 10, 3))), findsOneWidget);
    expect(find.byKey(TimetableKeys.empty), findsNothing);
    expect(find.byKey(TimetableKeys.noRecord), findsOneWidget, reason: 'facts + next actions under the grid');

    await tester.tap(find.byKey(TimetableKeys.recurrenceDelete(r.id)));
    await tester.pumpAndSettle();
    expect(find.text(TimetableStrings.deleteTitle), findsOneWidget);
    await tester.tap(find.text(TimetableStrings.deleteAll));
    await tester.pumpAndSettle();
    expect(find.text(TimetableStrings.deletedAll('수학 학원')), findsOneWidget);
    expect(find.byKey(TimetableKeys.recurrenceRow(r.id)), findsNothing);
    expect(find.byKey(TimetableKeys.empty), findsOneWidget, reason: 'nothing left to draw');
    final repo = h.container.read(plannerRepositoryProvider);
    expect(await repo.getRecurrences(), isEmpty, reason: 'pending delete is not live');

    await tester.tap(find.text(CommonStrings.undo));
    await tester.pumpAndSettle();
    expect(find.text(TimetableStrings.restored), findsOneWidget);
    expect(find.byKey(TimetableKeys.grid), findsOneWidget, reason: 'the restored recurrence is drawn again');
    await reveal(tester, find.byKey(TimetableKeys.recurrenceRow(r.id)));
    expect(find.byKey(TimetableKeys.recurrenceRow(r.id)), findsOneWidget);
    expect((await repo.getRecurrences()).length, 1);
    hideAppToast();
    await tester.pump();

    await tester.tap(find.byKey(TimetableKeys.recurrenceDelete(r.id)));
    await tester.pumpAndSettle();
    await tester.tap(find.text(TimetableStrings.deleteAll));
    await tester.pumpAndSettle();
    h.clock.advance(const Duration(seconds: 6));
    await tester.pump(const Duration(seconds: 6));
    await tester.pumpAndSettle();
    expect(await repo.getRecurrences(), isEmpty);
    final raw = await h.db.customSelect('SELECT deleted_at FROM recurrences WHERE id = ?', variables: [Variable<String>(r.id)]).getSingle();
    expect(raw.data['deleted_at'], isNotNull, reason: 'committed after the undo window');
    await h.unmount(tester);
  });

  testWidgets('recurrence edit: row tap opens the S07 sheet, whole-recurrence note, save → 모두 바꿨습니다; empty-state add opens the repeat sheet', (tester) async {
    final r = await seedRecurrence();
    await openTimetable(tester);
    await reveal(tester, find.byKey(TimetableKeys.recurrenceRow(r.id)));
    await tester.tap(find.byKey(TimetableKeys.recurrenceRow(r.id)));
    await tester.pumpAndSettle();
    expect(find.text(PlannerStrings.sheetEditRecurrence), findsOneWidget);
    expect(find.text(PlannerStrings.repeatWholeOnly), findsOneWidget);
    await tester.enterText(find.byType(TextField).first, '영어 학원');
    await tester.pump();
    await tester.tap(find.byKey(PlannerSheetKeys.save));
    await tester.pumpAndSettle();
    expect(find.text(TimetableStrings.changedAll('영어 학원')), findsOneWidget);
    expect(find.text('영어 학원'), findsWidgets);
    expect((await h.container.read(plannerRepositoryProvider).getRecurrence(r.id))!.title, '영어 학원');
    hideAppToast();
    await tester.pump();

    await reveal(tester, find.byKey(TimetableKeys.emptyAdd));
    await tester.tap(find.byKey(TimetableKeys.emptyAdd));
    await tester.pumpAndSettle();
    expect(find.text(PlannerStrings.sheetAddEvent), findsOneWidget);
    expect(find.text(PlannerStrings.btnAddRepeat), findsOneWidget, reason: 'repeat mode preselected');
    await h.unmount(tester);
  });

  testWidgets('tablet: grid and recurrence list side by side with blocks and recurrence blocks; dark theme tokens', (tester) async {
    tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
    addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
    final r = await seedRecurrence();
    await seedSession(id: 'a', start: DateTime(2026, 10, 1, 9), end: DateTime(2026, 10, 1, 10));
    await openTimetable(tester, size: kTablet);
    expect(find.byKey(TimetableKeys.grid), findsOneWidget);
    expect(find.byKey(TimetableKeys.addInPlanner), findsOneWidget);
    expect(find.byKey(TimetableKeys.recurrenceRow(r.id)), findsOneWidget);
    expect(find.byKey(TimetableKeys.recurrenceBlock(r.id, const LocalDate(2026, 10, 3))), findsOneWidget);
    expect(find.byKey(TimetableKeys.recurrenceBlock(r.id, const LocalDate(2026, 10, 4))), findsOneWidget);
    expect(find.byKey(TimetableKeys.recurrenceBlock(r.id, const LocalDate(2026, 10, 2))), findsNothing, reason: 'created today, no past instances');
    final gridRect = tester.getRect(find.byKey(TimetableKeys.grid));
    final sideRect = tester.getRect(find.byKey(TimetableKeys.addInPlanner));
    expect(sideRect.left, greaterThan(gridRect.right), reason: 'two columns');
    final scaffold = tester.widget<Scaffold>(find.descendant(of: find.byType(TimetableScreen), matching: find.byType(Scaffold)));
    expect(scaffold.backgroundColor, AppColors.dark.bg);
    expect(tester.takeException(), isNull);
    await h.unmount(tester);
  });

  testWidgets('[S08b] 23:59 and 00:00 short blocks stay inside the column and open the detail; midnight-crossing session on both days', (tester) async {
    await seedSession(id: 'late', start: DateTime(2026, 10, 3, 23, 59), end: DateTime(2026, 10, 3, 23, 59, 30));
    await seedSession(id: 'early', start: DateTime(2026, 10, 3, 0, 0), end: DateTime(2026, 10, 3, 0, 0, 30));
    await seedSession(id: 'cross', start: DateTime(2026, 10, 1, 23, 50), end: DateTime(2026, 10, 2, 0, 10));
    final r = await h.container.read(plannerRepositoryProvider).createRecurrence(
          title: '야간 수업',
          weekdayMask: Recurrence.maskOf(const <int>[6]),
          startTime: const LocalTime(23, 30),
          endTime: const LocalTime(23, 59),
        );
    await openTimetable(tester);

    final column = tester.getRect(find.byKey(TimetableKeys.column(const LocalDate(2026, 10, 3))));
    final late = tester.getRect(find.byKey(TimetableKeys.block('late', const LocalDate(2026, 10, 3), 1)));
    expect(late.bottom, lessThanOrEqualTo(column.bottom + 0.01), reason: 'minimum height never pushes the block past 24:00');
    expect(late.top, greaterThanOrEqualTo(column.top));
    expect(late.height, greaterThanOrEqualTo(column.height * 0.02 - 0.01));
    final early = tester.getRect(find.byKey(TimetableKeys.block('early', const LocalDate(2026, 10, 3), 0)));
    expect(early.top, closeTo(column.top, 0.01));
    final rec = tester.getRect(find.byKey(TimetableKeys.recurrenceBlock(r.id, const LocalDate(2026, 10, 3))));
    expect(rec.bottom, lessThanOrEqualTo(column.bottom + 0.01));

    await tester.tapAt(late.center);
    await tester.pumpAndSettle();
    expect(find.text(MeasureStrings.detail), findsWidgets, reason: 'the 23:59 block is tappable');
    h.container.read(appRouterProvider).pop();
    await tester.pumpAndSettle();

    expect(find.byKey(TimetableKeys.block('cross', const LocalDate(2026, 10, 1), 0)), findsOneWidget);
    final crossNext = find.byKey(TimetableKeys.block('cross', const LocalDate(2026, 10, 2), 0));
    expect(crossNext, findsOneWidget);
    expect(tester.getRect(crossNext).top, closeTo(tester.getRect(find.byKey(TimetableKeys.column(const LocalDate(2026, 10, 2)))).top, 0.01));
    await tester.tap(crossNext);
    await tester.pumpAndSettle();
    expect(find.text(MeasureStrings.detail), findsWidgets);
    h.container.read(appRouterProvider).pop();
    await tester.pumpAndSettle();
    await h.unmount(tester);
  });

  testWidgets('[S08b] screen open across Sunday→Monday midnight: the minute tick moves the week, today column and now line', (tester) async {
    final old = h;
    h = AppHarness(mode: AuthMode.localOnly, now: DateTime(2026, 10, 4, 23, 59));
    await old.dispose();
    await seedSession(id: 'sun', start: DateTime(2026, 10, 4, 22), end: DateTime(2026, 10, 4, 23));
    await seedSession(id: 'mon', start: DateTime(2026, 10, 5, 0, 0, 30), end: DateTime(2026, 10, 5, 0, 10));
    await openTimetable(tester);
    expect(find.text(TimetableStrings.weekRange(9, 28, 10, 4)), findsOneWidget);
    expect(find.descendant(of: find.byKey(TimetableKeys.column(const LocalDate(2026, 10, 4))), matching: find.byKey(TimetableKeys.nowLine)), findsOneWidget);

    h.clock.advance(const Duration(minutes: 2)); // 2026-10-05 00:01
    await tester.pump(const Duration(minutes: 1)); // minute tick → CalendarDay.refresh()
    await tester.pumpAndSettle();
    expect(find.text(TimetableStrings.weekRange(10, 5, 10, 11)), findsOneWidget, reason: 'the current week is now Monday 10/5');
    expect(find.text(TimetableStrings.weekRange(9, 28, 10, 4)), findsNothing);
    expect(find.byKey(TimetableKeys.thisWeek), findsNothing, reason: 'still offset 0');
    expect(find.descendant(of: find.byKey(TimetableKeys.column(const LocalDate(2026, 10, 5))), matching: find.byKey(TimetableKeys.nowLine)), findsOneWidget);
    expect(find.byKey(TimetableKeys.block('mon', const LocalDate(2026, 10, 5), 0)), findsOneWidget);
    await h.unmount(tester);
  });

  testWidgets('[S08b] app resume after midnight refreshes the date without waiting for the tick', (tester) async {
    final old = h;
    h = AppHarness(mode: AuthMode.localOnly, now: DateTime(2026, 10, 4, 23, 59));
    await old.dispose();
    await openTimetable(tester);
    expect(find.text(TimetableStrings.weekRange(9, 28, 10, 4)), findsOneWidget);
    h.clock.advance(const Duration(minutes: 3));
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();
    expect(find.text(TimetableStrings.weekRange(10, 5, 10, 11)), findsOneWidget);
    await h.unmount(tester);
  });

  testWidgets('[S08c] empty-state wording follows the shown week: 이번 주 only for the current week, 선택한 주 elsewhere (grid + no-record row, empty card)', (tester) async {
    await seedSession(id: 'today', start: DateTime(2026, 10, 3, 9), end: DateTime(2026, 10, 3, 10));
    final r = await h.container.read(plannerRepositoryProvider).createRecurrence(
          title: '토요 수업',
          weekdayMask: Recurrence.maskOf(const <int>[6]),
          startTime: const LocalTime(16, 0),
          endTime: const LocalTime(17, 0),
        );
    await openTimetable(tester);
    expect(find.byKey(TimetableKeys.noRecord), findsNothing, reason: 'the current week has a record');
    expect(find.text(TimetableStrings.emptyTitle), findsNothing);

    // next week: recurrence instance only → grid + no-record row, not "이번 주"
    await tester.tap(find.byKey(TimetableKeys.next));
    await tester.pumpAndSettle();
    expect(find.text(TimetableStrings.weekRange(10, 5, 10, 11)), findsOneWidget);
    expect(find.byKey(TimetableKeys.grid), findsOneWidget);
    expect(find.byKey(TimetableKeys.recurrenceBlock(r.id, const LocalDate(2026, 10, 10))), findsOneWidget);
    expect(find.byKey(TimetableKeys.noRecord), findsOneWidget);
    expect(find.text(TimetableStrings.emptyTitleOtherWeek), findsOneWidget);
    expect(find.text(TimetableStrings.emptyTitle), findsNothing);

    // previous week: nothing at all (the recurrence starts today) → empty card, not "이번 주"
    await tester.tap(find.byKey(TimetableKeys.thisWeek));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(TimetableKeys.prev));
    await tester.pumpAndSettle();
    expect(find.text(TimetableStrings.weekRange(9, 21, 9, 27)), findsOneWidget);
    expect(find.byKey(TimetableKeys.empty), findsOneWidget);
    expect(find.text(TimetableStrings.emptyTitleOtherWeek), findsOneWidget);
    expect(find.text(TimetableStrings.emptyBodyOtherWeek), findsOneWidget);
    expect(find.text(TimetableStrings.emptyTitle), findsNothing);

    // back to the current week with a recurrence-only state: "이번 주" wording
    await h.container.read(sessionRepositoryProvider).softDelete('today');
    await tester.tap(find.byKey(TimetableKeys.thisWeek));
    await tester.pumpAndSettle();
    expect(find.byKey(TimetableKeys.noRecord), findsOneWidget);
    expect(find.text(TimetableStrings.emptyTitle), findsOneWidget);
    expect(find.text(TimetableStrings.emptyTitleOtherWeek), findsNothing);
    await h.unmount(tester);
  });
}
