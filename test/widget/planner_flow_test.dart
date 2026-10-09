// PlannerScreen (S07) in the local-only dev mode: grid, month navigation,
// register sheet → save, fold/detail, edit · dirty close · delete undo /
// commit, bands, repeats, 3D toggle, free vs premium, tablet, dark theme,
// week start, capture link and session link.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soongong/core/contracts/billing_gateway.dart';
import 'package:soongong/core/contracts/fakes/fakes.dart';
import 'package:soongong/core/contracts/providers.dart';
import 'package:soongong/core/domain/enums.dart';
import 'package:soongong/core/domain/local_date.dart';
import 'package:soongong/core/router/app_router.dart';
import 'package:soongong/core/strings/common_strings.dart';
import 'package:soongong/core/strings/planner_strings.dart';
import 'package:soongong/core/theme/app_theme.dart';
import 'package:soongong/core/widgets/widgets.dart';
import 'package:soongong/data/auth/auth_mode.dart';
import 'package:soongong/data/repositories/repositories.dart';
import 'package:soongong/features/measure/domain/segment.dart';
import 'package:soongong/features/planner/presentation/month_grid_view.dart';
import 'package:soongong/features/planner/presentation/planner_3d_painter.dart';
import 'package:soongong/features/planner/presentation/planner_item_sheet.dart';
import 'package:soongong/features/planner/presentation/planner_screen.dart';
import 'package:soongong/features/planner/presentation/recurrence_editor.dart';

import '../helpers/app_harness.dart';

void main() {
  late AppHarness h;
  final today = LocalDate.of(kHarnessNow); // 2026-10-03 (Saturday)

  setUp(() => h = AppHarness(mode: AuthMode.localOnly));
  tearDown(() => h.dispose());

  Future<void> openPlanner(WidgetTester tester, {Size size = kPhone}) async {
    await h.pumpApp(tester, size: size);
    await tester.tap(find.text(CommonStrings.tabPlanner).last);
    await tester.pumpAndSettle();
  }

  Future<void> seedSession({
    required DateTime start,
    required Duration seated,
    String? subjectId,
    String? itemId,
  }) =>
      h.container.read(sessionRepositoryProvider).saveFinished(
            id: 'sess-${start.millisecondsSinceEpoch}',
            kind: SessionKind.study,
            mode: SessionMode.manual,
            startedAt: start,
            endedAt: start.add(seated),
            status: SessionStatus.finished,
            subjectId: subjectId,
            plannerItemId: itemId,
            segments: <Segment>[
              Segment(id: 'seg-${start.millisecondsSinceEpoch}', kind: SegmentKind.manual, startAt: start.toUtc(), endAt: start.add(seated).toUtc()),
            ],
            sensitivityLevel: 0,
          );

  testWidgets('grid: month title, 42 cells, Monday first, today cell, prev/next and 오늘', (tester) async {
    await openPlanner(tester);
    expect(find.text(PlannerStrings.monthTitle(2026, 10)), findsOneWidget);
    expect(find.byKey(PlannerGridKeys.cell(LocalDate.parse('2026-09-28'))), findsOneWidget, reason: 'grid starts on Monday 9/28');
    expect(find.byKey(PlannerGridKeys.cell(LocalDate.parse('2026-11-08'))), findsOneWidget, reason: '42nd cell');
    expect(find.byKey(PlannerGridKeys.cell(today)), findsOneWidget);
    expect(find.byKey(PlannerKeys.today), findsNothing, reason: 'current month: no 오늘 button');
    expect(find.text(PlannerStrings.planned(0, 0)), findsOneWidget);

    await tester.tap(find.byKey(PlannerKeys.next));
    await tester.pumpAndSettle();
    expect(find.text(PlannerStrings.monthTitle(2026, 11)), findsOneWidget);
    expect(find.byKey(PlannerKeys.today), findsOneWidget);
    await tester.tap(find.byKey(PlannerKeys.prev));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(PlannerKeys.prev));
    await tester.pumpAndSettle();
    expect(find.text(PlannerStrings.monthTitle(2026, 9)), findsOneWidget);
    await tester.tap(find.byKey(PlannerKeys.today));
    await tester.pumpAndSettle();
    expect(find.text(PlannerStrings.monthTitle(2026, 10)), findsOneWidget);
    expect(find.byKey(PlannerKeys.detail), findsNothing, reason: 'grid stays unfolded');
    await h.unmount(tester);
  });

  testWidgets('register: FAB → study with subject and 45분 → 추가하기 → toast, grid line, detail row', (tester) async {
    await h.container.read(subjectRepositoryProvider).create(name: '수학', colorIndex: 0);
    await openPlanner(tester);
    await tester.tap(find.byKey(PlannerKeys.fab));
    await tester.pumpAndSettle();
    expect(find.text(PlannerStrings.sheetAdd), findsOneWidget);
    expect(find.text(PlannerStrings.dateButtonToday(10, 3)), findsOneWidget);
    expect(find.text(PlannerStrings.hintStudyLocked), findsOneWidget, reason: 'free');
    expect(find.text(PlannerStrings.expectedLocked), findsOneWidget, reason: 'PremiumLockHint');

    await tester.enterText(find.byKey(PlannerSheetKeys.title), '미적분 p.80');
    await tester.enterText(find.byKey(PlannerSheetKeys.range), 'p.80–86');
    await tester.tap(find.descendant(of: find.byType(PlannerItemSheet), matching: find.text('수학')));
    await tester.tap(find.text(PlannerStrings.targetMinutes(45)));
    await tester.pump();
    await tester.ensureVisible(find.byKey(PlannerSheetKeys.save));
    await tester.tap(find.byKey(PlannerSheetKeys.save));
    await tester.pumpAndSettle();

    expect(find.text(PlannerStrings.added), findsOneWidget);
    final items = await h.container.read(plannerRepositoryProvider).getAllItems();
    expect(items.single.title, '미적분 p.80');
    expect(items.single.targetMinutes, 45);
    expect(items.single.rangeText, 'p.80–86');
    expect(items.single.date, today);
    expect(find.text('미적분 p.80'), findsWidgets, reason: 'grid line + detail row');
    expect(find.byKey(PlannerKeys.detail), findsOneWidget, reason: 'saved date is selected and folded');
    expect(find.text('${PlannerStrings.sectionStudy} · ${PlannerStrings.studyActual(0)}'), findsOneWidget);
    expect(find.text(PlannerStrings.planned(0, 1)), findsOneWidget);
    await h.unmount(tester);
  });

  Future<void> openDay(WidgetTester tester, LocalDate d) async {
    await tester.tap(find.byKey(PlannerGridKeys.cell(d)));
    await tester.pumpAndSettle();
  }

  testWidgets('fold: date tap folds to its week with the day detail; same tap unfolds; handle folds again', (tester) async {
    await openPlanner(tester);
    final d = LocalDate.parse('2026-10-10');
    await openDay(tester, d);
    expect(find.byKey(PlannerKeys.detail), findsOneWidget);
    expect(find.text(PlannerStrings.dayTitle(10, 10, '토')), findsOneWidget);
    expect(find.text(PlannerStrings.plannedCount(0)), findsOneWidget, reason: 'future day: planned count');
    expect(find.text(PlannerStrings.empty), findsOneWidget);
    expect(find.byKey(PlannerGridKeys.cell(LocalDate.parse('2026-10-05'))), findsOneWidget, reason: 'the selected week stays');
    expect(find.byKey(PlannerGridKeys.cell(LocalDate.parse('2026-10-12'))), findsNothing, reason: 'other weeks folded away');

    await openDay(tester, d);
    expect(find.byKey(PlannerKeys.detail), findsNothing);
    expect(find.byKey(PlannerGridKeys.cell(LocalDate.parse('2026-10-12'))), findsOneWidget);

    await tester.tap(find.byKey(PlannerKeys.handle));
    await tester.pumpAndSettle();
    expect(find.byKey(PlannerKeys.detail), findsOneWidget);
    expect(find.text(PlannerStrings.dayTitle(10, 10, '토')), findsOneWidget, reason: 'keeps the last selection');

    await tester.tap(find.byKey(PlannerKeys.handle)); // unfold: today's week is not the folded one
    await tester.pumpAndSettle();
    await openDay(tester, today);
    expect(find.text(PlannerStrings.dayTitle(10, 3, '토')), findsOneWidget);
    expect(find.text(PlannerStrings.noRecord), findsOneWidget, reason: 'today without 순공');
    await h.unmount(tester);
  });

  testWidgets('edit: dirty close asks and keeps editing; save updates; delete → undo restores; delete → window → committed', (tester) async {
    final repo = h.container.read(plannerRepositoryProvider);
    final item = await repo.createItem(kind: PlannerKind.study, title: '수학 문제', date: today, targetMinutes: 30);
    await openPlanner(tester);
    await openDay(tester, today);
    expect(find.byKey(PlannerKeys.item(item.id)), findsOneWidget);
    await tester.tap(find.descendant(of: find.byKey(PlannerKeys.item(item.id)), matching: find.text('수학 문제')));
    await tester.pumpAndSettle();
    expect(find.text(PlannerStrings.sheetEdit), findsOneWidget);
    expect(find.byKey(PlannerSheetKeys.delete), findsOneWidget);
    expect(find.text(PlannerStrings.kindEvent), findsNothing, reason: 'an item cannot become a 일정 in edit mode');

    // dirty close → confirm → keep editing
    await tester.enterText(find.byKey(PlannerSheetKeys.title), '수학 문제 2');
    await tester.pump();
    await tester.tap(find.byKey(PlannerSheetKeys.close));
    await tester.pumpAndSettle();
    expect(find.text(PlannerStrings.cancelEditTitle), findsOneWidget);
    await tester.tap(find.text(PlannerStrings.cancelEditKeep));
    await tester.pumpAndSettle();
    expect(find.byKey(PlannerSheetKeys.title), findsOneWidget, reason: 'sheet still open');
    expect((await repo.getItem(item.id))!.title, '수학 문제', reason: 'nothing saved yet');

    await tester.ensureVisible(find.byKey(PlannerSheetKeys.save));
    await tester.tap(find.byKey(PlannerSheetKeys.save));
    await tester.pumpAndSettle();
    expect(find.text(PlannerStrings.saved), findsOneWidget);
    expect((await repo.getItem(item.id))!.title, '수학 문제 2');
    expect(find.text('수학 문제 2'), findsWidgets);

    // unchanged close → no dialog
    hideAppToast();
    await tester.pump();
    await tester.tap(find.descendant(of: find.byKey(PlannerKeys.item(item.id)), matching: find.text('수학 문제 2')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(PlannerSheetKeys.close));
    await tester.pumpAndSettle();
    expect(find.text(PlannerStrings.cancelEditTitle), findsNothing);
    expect(find.byKey(PlannerSheetKeys.title), findsNothing);

    // delete → undo
    await tester.tap(find.descendant(of: find.byKey(PlannerKeys.item(item.id)), matching: find.text('수학 문제 2')));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(PlannerSheetKeys.delete));
    await tester.tap(find.byKey(PlannerSheetKeys.delete));
    await tester.pumpAndSettle();
    expect(find.text(PlannerStrings.deleteItemTitle), findsOneWidget);
    await tester.tap(find.text(CommonStrings.delete).last);
    await tester.pumpAndSettle();
    expect(find.text(PlannerStrings.deleted), findsOneWidget);
    expect(find.byKey(PlannerKeys.item(item.id)), findsNothing, reason: 'hidden while pending');
    await tester.tap(find.text(CommonStrings.undo));
    await tester.pumpAndSettle();
    expect(find.text(PlannerStrings.restored), findsOneWidget);
    expect(find.byKey(PlannerKeys.item(item.id)), findsOneWidget);
    expect((await repo.getItem(item.id))!.stamp.pendingDeleteUntil, isNull);

    // delete → window elapses → committed
    hideAppToast();
    await tester.pump();
    await tester.tap(find.descendant(of: find.byKey(PlannerKeys.item(item.id)), matching: find.text('수학 문제 2')));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(PlannerSheetKeys.delete));
    await tester.tap(find.byKey(PlannerSheetKeys.delete));
    await tester.pumpAndSettle();
    await tester.tap(find.text(CommonStrings.delete).last);
    await tester.pumpAndSettle();
    h.clock.advance(const Duration(seconds: 6));
    await tester.pump(const Duration(seconds: 6));
    await tester.pumpAndSettle();
    final raw = await h.db.customSelect("SELECT deleted_at FROM planner_items WHERE id = '${item.id}'").getSingle();
    expect(raw.read<String?>('deleted_at'), isNotNull);
    expect(find.byKey(PlannerKeys.item(item.id)), findsNothing);
    expect(find.text(PlannerStrings.empty), findsOneWidget);
    await h.unmount(tester);
  });

  testWidgets('band: 일정 · 기간 3일 → strip on the grid and a band row; edit sheet; delete with undo', (tester) async {
    await openPlanner(tester);
    await tester.tap(find.byKey(PlannerKeys.fab));
    await tester.pumpAndSettle();
    await tester.tap(find.text(PlannerStrings.kindEvent));
    await tester.pumpAndSettle();
    expect(find.text(PlannerStrings.sheetAddEvent), findsOneWidget);
    expect(find.text(PlannerStrings.eventPeriod), findsOneWidget);
    await tester.enterText(find.byKey(PlannerSheetKeys.title), '중간고사');
    await tester.pump();
    // end +2 days (10/3 → 10/5)
    await tester.tap(find.bySemanticsLabel('${PlannerStrings.periodEnd} ${PlannerStrings.dayAfter}'));
    await tester.pump();
    await tester.tap(find.bySemanticsLabel('${PlannerStrings.periodEnd} ${PlannerStrings.dayAfter}'));
    await tester.pump();
    expect(find.text(PlannerStrings.periodLength(3)), findsOneWidget);
    await tester.ensureVisible(find.byKey(PlannerSheetKeys.save));
    expect(find.text(PlannerStrings.btnAddPeriod), findsOneWidget);
    await tester.tap(find.byKey(PlannerSheetKeys.save));
    await tester.pumpAndSettle();

    final band = (await h.container.read(plannerRepositoryProvider).getAllItems()).single;
    expect(band.isBand, isTrue);
    expect(band.bandStart!.key, '2026-10-03');
    expect(band.bandEnd!.key, '2026-10-05');
    // folded on the band's first day → detail band row; unfold → strips on rows 0 (10/3–10/4) and 1 (10/5)
    expect(find.byKey(PlannerKeys.band(band.id)), findsOneWidget);
    expect(find.text(PlannerStrings.bandRange('10/3', '10/5')), findsOneWidget);
    await openDay(tester, today);
    expect(find.byKey(PlannerGridKeys.band(band.id, 0)), findsOneWidget);
    expect(find.byKey(PlannerGridKeys.band(band.id, 1)), findsOneWidget);

    hideAppToast();
    await tester.pump();
    await openDay(tester, LocalDate.parse('2026-10-05'));
    await tester.tap(find.byKey(PlannerKeys.band(band.id)));
    await tester.pumpAndSettle();
    expect(find.text(PlannerStrings.sheetEditBand), findsOneWidget);
    expect(find.text(PlannerStrings.kindStudy), findsNothing, reason: 'a band stays a 일정');
    await tester.ensureVisible(find.byKey(PlannerSheetKeys.delete));
    await tester.tap(find.byKey(PlannerSheetKeys.delete));
    await tester.pumpAndSettle();
    expect(find.text(PlannerStrings.deleteBandTitle), findsOneWidget);
    await tester.tap(find.text(CommonStrings.delete).last);
    await tester.pumpAndSettle();
    expect(find.byKey(PlannerKeys.band(band.id)), findsNothing);
    await tester.tap(find.text(CommonStrings.undo));
    await tester.pumpAndSettle();
    expect(find.byKey(PlannerKeys.band(band.id)), findsOneWidget);
    await h.unmount(tester);
  });

  testWidgets('repeat: 일정 · 반복 토 19:00–21:00 → recurrence row on Saturdays; whole edit note; delete with undo', (tester) async {
    await openPlanner(tester);
    await tester.tap(find.byKey(PlannerKeys.fab));
    await tester.pumpAndSettle();
    await tester.tap(find.text(PlannerStrings.kindEvent));
    await tester.pumpAndSettle();
    await tester.tap(find.text(PlannerStrings.eventRepeat));
    await tester.pumpAndSettle();
    expect(find.text(PlannerStrings.repeatPickDays), findsOneWidget);
    await tester.enterText(find.byKey(PlannerSheetKeys.title), '수학 학원');
    await tester.pump();
    final saturdayChip = find.descendant(of: find.byType(RecurrenceEditor), matching: find.text('토'));
    await tester.ensureVisible(saturdayChip);
    await tester.tap(saturdayChip);
    await tester.pump();
    expect(find.text(PlannerStrings.repeatSummary('토', '19:00', '21:00')), findsOneWidget);
    await tester.ensureVisible(find.byKey(PlannerSheetKeys.save));
    expect(find.text(PlannerStrings.btnAddRepeat), findsOneWidget);
    await tester.tap(find.byKey(PlannerSheetKeys.save));
    await tester.pumpAndSettle();
    expect(find.text(PlannerStrings.added), findsOneWidget);
    final rec = (await h.container.read(plannerRepositoryProvider).getRecurrences()).single;
    expect(rec.weekdayMask, 1 << 5);
    expect(rec.endsOn, isNull);

    hideAppToast();
    await tester.pump();
    await openDay(tester, today); // Saturday
    expect(find.byKey(PlannerKeys.recurrence(rec.id)), findsOneWidget);
    expect(find.text(PlannerStrings.recurrenceTime('19:00', '21:00')), findsOneWidget);
    await openDay(tester, LocalDate.parse('2026-10-04')); // Sunday
    expect(find.byKey(PlannerKeys.recurrence(rec.id)), findsNothing);
    await tester.tap(find.byKey(PlannerKeys.handle)); // unfold: 10/10 is in the next week
    await tester.pumpAndSettle();
    await openDay(tester, LocalDate.parse('2026-10-10'));
    await tester.tap(find.byKey(PlannerKeys.recurrence(rec.id)));
    await tester.pumpAndSettle();
    expect(find.text(PlannerStrings.sheetEditRecurrence), findsOneWidget);
    expect(find.text(PlannerStrings.repeatWholeOnly), findsOneWidget);
    await tester.ensureVisible(find.byKey(PlannerSheetKeys.delete));
    await tester.tap(find.byKey(PlannerSheetKeys.delete));
    await tester.pumpAndSettle();
    expect(find.text(PlannerStrings.deleteRecurrenceTitle), findsOneWidget);
    await tester.tap(find.text(CommonStrings.delete).last);
    await tester.pumpAndSettle();
    expect(find.byKey(PlannerKeys.recurrence(rec.id)), findsNothing);
    await tester.tap(find.text(CommonStrings.undo));
    await tester.pumpAndSettle();
    expect(find.byKey(PlannerKeys.recurrence(rec.id)), findsOneWidget);
    await h.unmount(tester);
  });

  testWidgets('3D: button and horizontal swipe toggle; columns for days with 순공; reduced motion is immediate', (tester) async {
    await seedSession(start: kHarnessNow.subtract(const Duration(days: 1)), seated: const Duration(minutes: 30));
    await openPlanner(tester);
    bool painted() => find.byWidgetPredicate((w) => w is CustomPaint && w.painter is Planner3dPainter).evaluate().isNotEmpty;
    expect(painted(), isFalse);
    await tester.tap(find.byKey(PlannerKeys.toggle3d));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 120));
    final mid = tester.widgetList<CustomPaint>(find.byWidgetPredicate((w) => w is CustomPaint && w.painter is Planner3dPainter)).map((w) => (w.painter! as Planner3dPainter).t).first;
    expect(mid, greaterThan(0));
    expect(mid, lessThan(1), reason: '250 ms transition in progress');
    await tester.pumpAndSettle();
    expect(find.text(PlannerStrings.legendSeated), findsOneWidget);
    expect(painted(), isTrue, reason: 'yesterday has a column');
    expect(find.text(PlannerStrings.legendPlanned), findsNothing, reason: 'free: no planned columns');

    await tester.fling(find.byKey(PlannerKeys.grid), const Offset(-240, 0), 1200);
    await tester.pumpAndSettle();
    expect(find.text(PlannerStrings.legendSeated), findsNothing);
    expect(painted(), isFalse);

    tester.platformDispatcher.accessibilityFeaturesTestValue = const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    await tester.pump();
    await tester.tap(find.byKey(PlannerKeys.toggle3d));
    await tester.pump();
    final t = tester.widgetList<CustomPaint>(find.byWidgetPredicate((w) => w is CustomPaint && w.painter is Planner3dPainter)).map((w) => (w.painter! as Planner3dPainter).t).first;
    expect(t, 1.0, reason: 'no transition under reduced motion');
    await h.unmount(tester);
  });

  testWidgets('free: 30분 default + lock hint; premium: 최근 수학 5회 평균 fills the target and detail shows 계획', (tester) async {
    final subject = await h.container.read(subjectRepositoryProvider).create(name: '수학', colorIndex: 0);
    for (var i = 1; i <= 6; i++) {
      await seedSession(start: DateTime(2026, 9, i, 9), seated: Duration(minutes: 30 + i * 5), subjectId: subject.id);
    }
    await openPlanner(tester);
    await tester.tap(find.byKey(PlannerKeys.fab));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(PlannerSheetKeys.title), '무료 항목');
    await tester.tap(find.descendant(of: find.byType(PlannerItemSheet), matching: find.text('수학')));
    await tester.pump();
    expect(find.text(PlannerStrings.expectedLocked), findsOneWidget);
    expect(find.text(PlannerStrings.expected('수학', 50)), findsNothing);
    await tester.ensureVisible(find.byKey(PlannerSheetKeys.save));
    await tester.tap(find.byKey(PlannerSheetKeys.save));
    await tester.pumpAndSettle();
    final repo = h.container.read(plannerRepositoryProvider);
    expect((await repo.getAllItems()).single.targetMinutes, 30);
    expect(find.text('${PlannerStrings.sectionStudy} · ${PlannerStrings.studyActual(0)}'), findsOneWidget, reason: 'free: no 계획 → 실제');

    hideAppToast();
    (h.container.read(billingGatewayProvider) as FakeBillingGateway).force(EntitlementStatus.premium);
    await tester.pumpAndSettle();
    expect(find.text('${PlannerStrings.sectionStudy} · ${PlannerStrings.studyPlannedActual(30, 0)}'), findsOneWidget);
    expect(find.text(PlannerStrings.captureHint), findsOneWidget);
    await tester.tap(find.byKey(PlannerKeys.fab));
    await tester.pumpAndSettle();
    expect(find.text(PlannerStrings.hintStudy), findsOneWidget);
    expect(find.text(PlannerStrings.expectedFirst), findsOneWidget, reason: 'no subject yet');
    await tester.enterText(find.byKey(PlannerSheetKeys.title), '프리미엄 항목');
    await tester.tap(find.descendant(of: find.byType(PlannerItemSheet), matching: find.text('수학')));
    await tester.pump();
    // latest 5 of 6 sessions: 40,45,50,55,60 → 50
    expect(find.text(PlannerStrings.expected('수학', 50)), findsOneWidget);
    expect(find.text('${PlannerStrings.targetCustom} · ${PlannerStrings.targetMinutes(50)}'), findsOneWidget);
    await tester.ensureVisible(find.byKey(PlannerSheetKeys.save));
    await tester.tap(find.byKey(PlannerSheetKeys.save));
    await tester.pumpAndSettle();
    final premiumItem = (await repo.getAllItems()).firstWhere((i) => i.title == '프리미엄 항목');
    expect(premiumItem.targetMinutes, 50, reason: 'suggestion filled the target');
    await h.unmount(tester);
  });

  testWidgets('tablet (t7): grid and detail side by side, no fold; dark theme (s10) uses dark tokens', (tester) async {
    tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
    addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
    await openPlanner(tester, size: kTablet);
    expect(find.byKey(PlannerKeys.detail), findsOneWidget, reason: 'detail always visible');
    expect(find.byKey(PlannerKeys.handle), findsNothing);
    expect(find.text(PlannerStrings.dayTitle(10, 3, '토')), findsOneWidget, reason: 'today selected by default');
    await openDay(tester, LocalDate.parse('2026-10-20'));
    expect(find.text(PlannerStrings.dayTitle(10, 20, '화')), findsOneWidget);
    expect(find.byKey(PlannerGridKeys.cell(LocalDate.parse('2026-09-28'))), findsOneWidget, reason: 'grid never folds');
    final scaffold = tester.widget<Scaffold>(find.byType(Scaffold).last);
    expect(scaffold.backgroundColor, AppColors.dark.bg);
    await h.unmount(tester);
  });

  testWidgets('week start Sunday (settings) moves the first column', (tester) async {
    await h.container.read(settingsRepositoryProvider).setWeekStart(7);
    await openPlanner(tester);
    expect(find.byKey(PlannerGridKeys.cell(LocalDate.parse('2026-09-27'))), findsOneWidget);
    expect(find.byKey(PlannerGridKeys.cell(LocalDate.parse('2026-11-07'))), findsOneWidget);
    expect(find.byKey(PlannerGridKeys.cell(LocalDate.parse('2026-11-08'))), findsNothing);
    await h.unmount(tester);
  });

  testWidgets('capture button opens /reading/capture?from=planner&itemId=; a linked session opens /session/:id', (tester) async {
    final repo = h.container.read(plannerRepositoryProvider);
    final item = await repo.createItem(kind: PlannerKind.study, title: '기출 3회', date: today, targetMinutes: 60);
    final start = kHarnessNow.subtract(const Duration(hours: 2));
    await seedSession(start: start, seated: const Duration(minutes: 30), itemId: item.id);
    await openPlanner(tester);
    await openDay(tester, today);
    expect(find.text(PlannerStrings.seatedSummary('30분')), findsOneWidget);
    expect(find.byKey(PlannerKeys.record(item.id)), findsOneWidget);
    expect(find.text(PlannerStrings.targetMinutes(30)), findsOneWidget, reason: 'free: actual minutes');

    await tester.tap(find.byKey(PlannerKeys.capture(item.id)));
    await tester.pumpAndSettle();
    final router = h.container.read(appRouterProvider);
    expect(router.state.uri.toString(), '/reading/capture?from=planner&itemId=${item.id}');
    router.pop();
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(PlannerKeys.record(item.id)));
    await tester.pumpAndSettle();
    expect(router.state.uri.path, '/session/sess-${start.millisecondsSinceEpoch}');
    await h.unmount(tester);
  });

  // ------------------------------------------------------------------
  // [S07b] GPT review regressions

  testWidgets('[S07b] P2-1: 자습 saved without a plan shows under 추가 자습 and opens /session/:id', (tester) async {
    final start = kHarnessNow.subtract(const Duration(hours: 3));
    await h.container.read(sessionRepositoryProvider).saveFinished(
          id: 'self-1',
          kind: SessionKind.self,
          mode: SessionMode.manual,
          startedAt: start,
          endedAt: start.add(const Duration(minutes: 30)),
          status: SessionStatus.finished,
          segments: <Segment>[
            Segment(id: 'self-1-seg', kind: SegmentKind.manual, startAt: start.toUtc(), endAt: start.add(const Duration(minutes: 30)).toUtc()),
          ],
          sensitivityLevel: 0,
        );
    await openPlanner(tester);
    await openDay(tester, today);
    expect(find.text(PlannerStrings.seatedSummary('30분')), findsOneWidget);
    expect(find.text('${PlannerStrings.sectionSelf} · ${PlannerStrings.selfSum(30)}'), findsOneWidget);
    expect(find.byKey(PlannerKeys.session('self-1')), findsOneWidget);
    expect(find.text(PlannerStrings.selfRecord), findsOneWidget);
    expect(find.text(PlannerStrings.recordStartedAt('07:00')), findsOneWidget);
    expect(find.text(PlannerStrings.empty), findsNothing);
    await tester.tap(find.byKey(PlannerKeys.session('self-1')));
    await tester.pumpAndSettle();
    expect(h.container.read(appRouterProvider).state.uri.path, '/session/self-1');
    await h.unmount(tester);
  });

  testWidgets('[S07b] P2-2: a session paused since last month counts today; an August item shows 실제 from an October session', (tester) async {
    final sessions = h.container.read(sessionRepositoryProvider);
    // A: started 9/20, paused across days, resumed today for 30 min.
    final aStart = DateTime(2026, 9, 20, 9);
    final resume = DateTime(2026, 10, 3, 9);
    await sessions.saveFinished(
      id: 'paused-a',
      kind: SessionKind.study,
      mode: SessionMode.manual,
      startedAt: aStart,
      endedAt: resume.add(const Duration(minutes: 30)),
      status: SessionStatus.finished,
      segments: <Segment>[
        Segment(id: 'a-p', kind: SegmentKind.paused, startAt: aStart.toUtc(), endAt: resume.toUtc()),
        Segment(id: 'a-s', kind: SegmentKind.manual, startAt: resume.toUtc(), endAt: resume.add(const Duration(minutes: 30)).toUtc()),
      ],
      sensitivityLevel: 0,
    );
    // B: an August 밀린 일 executed today for 30 min.
    final repo = h.container.read(plannerRepositoryProvider);
    final aug = await repo.createItem(kind: PlannerKind.study, title: '밀린 개념 정리', date: LocalDate.parse('2026-08-01'), targetMinutes: 30);
    await seedSession(start: DateTime(2026, 10, 3, 14), seated: const Duration(minutes: 30), itemId: aug.id);

    await openPlanner(tester);
    await openDay(tester, today);
    expect(find.text(PlannerStrings.seatedSummary('1시간')), findsOneWidget, reason: '30 (A) + 30 (B)');
    expect(find.byKey(PlannerKeys.session('paused-a')), findsNothing, reason: 'unlinked rows list under their start day (9/20), not today; the 순공 still counts today');
    await h.unmount(tester);
  });

  testWidgets('[S07b] P2-2b: August grid: the item linked to an October session shows 실제 30분', (tester) async {
    final repo = h.container.read(plannerRepositoryProvider);
    final aug = await repo.createItem(kind: PlannerKind.study, title: '밀린 개념 정리', date: LocalDate.parse('2026-08-01'), targetMinutes: 30);
    await seedSession(start: DateTime(2026, 10, 3, 14), seated: const Duration(minutes: 30), itemId: aug.id);
    await openPlanner(tester);
    await tester.tap(find.byKey(PlannerKeys.prev));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(PlannerKeys.prev));
    await tester.pumpAndSettle();
    expect(find.text(PlannerStrings.monthTitle(2026, 8)), findsOneWidget);
    await openDay(tester, LocalDate.parse('2026-08-01'));
    expect(find.byKey(PlannerKeys.record(aug.id)), findsOneWidget);
    expect(find.text(PlannerStrings.targetMinutes(30)), findsOneWidget, reason: 'free: actual minutes from the October session');
    expect(find.text('${PlannerStrings.sectionStudy} · ${PlannerStrings.studyActual(30)}'), findsOneWidget);
    await h.unmount(tester);
  });

  testWidgets('[S07b] P2-3: 600×900 uses the fold layout (no overflow); 768×1024 and 1024×768 use two columns', (tester) async {
    await openPlanner(tester, size: const Size(600, 900));
    expect(find.byKey(PlannerKeys.handle), findsOneWidget, reason: 'too narrow for two columns beside the rail');
    expect(find.byKey(PlannerKeys.detail), findsNothing);
    await openDay(tester, today);
    expect(find.byKey(PlannerKeys.detail), findsOneWidget);
    expect(tester.takeException(), isNull);
    await h.unmount(tester);

    await openPlanner(tester, size: const Size(768, 1024));
    expect(find.byKey(PlannerKeys.handle), findsNothing);
    expect(find.byKey(PlannerKeys.detail), findsOneWidget);
    expect(tester.takeException(), isNull);
    await h.unmount(tester);

    await openPlanner(tester, size: kTablet);
    expect(find.byKey(PlannerKeys.handle), findsNothing);
    expect(find.byKey(PlannerKeys.detail), findsOneWidget);
    expect(tester.takeException(), isNull);
    await h.unmount(tester);
  });

  testWidgets('[S07b] §4.5: premium 목표 column overlays the 순공 column on the same day; free has none', (tester) async {
    final repo = h.container.read(plannerRepositoryProvider);
    final yesterday = today.addDays(-1);
    await repo.createItem(kind: PlannerKind.study, title: '계획', date: yesterday, targetMinutes: 60);
    await seedSession(start: kHarnessNow.subtract(const Duration(days: 1)), seated: const Duration(minutes: 30));
    List<Planner3dPainter> painters() => tester
        .widgetList<CustomPaint>(find.byWidgetPredicate((w) => w is CustomPaint && w.painter is Planner3dPainter))
        .map((w) => w.painter! as Planner3dPainter)
        .toList();

    await openPlanner(tester);
    await tester.tap(find.byKey(PlannerKeys.toggle3d));
    await tester.pumpAndSettle();
    expect(painters().every((p) => p.plannedHeightPx == 0), isTrue, reason: 'free: no 목표 column');
    expect(painters().where((p) => p.heightPx > 0).length, 1, reason: 'yesterday has 순공');

    (h.container.read(billingGatewayProvider) as FakeBillingGateway).force(EntitlementStatus.premium);
    await tester.pumpAndSettle();
    final both = painters().where((p) => p.heightPx > 0 && p.plannedHeightPx > 0).toList();
    expect(both.length, 1, reason: 'yesterday: record and plan on the same cell');
    expect(both.single.liftPx, both.single.heightPx, reason: 'content sits on the record');
    expect(find.text(PlannerStrings.legendPlanned), findsOneWidget);
    await h.unmount(tester);
  });
}
