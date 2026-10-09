// StatsScreen (S08) in the local-only dev mode: loading skeleton, sparse
// state (< 3 recorded days), weekly facts (summary · comparison · bars tap
// · subjects · hours · focus), monthly toggle and navigation, wrongs
// section free / premium / expired, paywall and wrongs route reservations,
// hidden cross view, tablet two columns, dark theme.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soongong/core/contracts/billing_gateway.dart';
import 'package:soongong/core/contracts/fakes/fakes.dart';
import 'package:soongong/core/contracts/providers.dart';
import 'package:soongong/core/contracts/reading_engine.dart';
import 'package:soongong/core/domain/enums.dart';
import 'package:soongong/core/router/app_router.dart';
import 'package:soongong/core/strings/billing_strings.dart';
import 'package:soongong/core/strings/common_strings.dart';
import 'package:soongong/core/strings/measure_strings.dart';
import 'package:soongong/core/strings/planner_strings.dart';
import 'package:soongong/core/strings/stats_strings.dart';
import 'package:soongong/core/strings/wrongs_strings.dart';
import 'package:soongong/core/theme/app_theme.dart';
import 'package:soongong/data/auth/auth_mode.dart';
import 'package:soongong/data/repositories/repositories.dart';
import 'package:soongong/features/measure/domain/segment.dart';
import 'package:soongong/features/stats/presentation/stats_screen.dart';

import '../helpers/app_harness.dart';

void main() {
  late AppHarness h;

  setUp(() => h = AppHarness(mode: AuthMode.localOnly));
  tearDown(() => h.dispose());

  Future<void> openStats(WidgetTester tester, {Size size = kPhone}) async {
    await h.pumpApp(tester, size: size);
    await tester.tap(find.text(CommonStrings.tabStats).last);
    await tester.pumpAndSettle();
  }

  Future<void> seedSession({
    required String id,
    required DateTime start,
    required Duration length,
    String? subjectId,
    SessionKind kind = SessionKind.study,
  }) =>
      h.container.read(sessionRepositoryProvider).saveFinished(
            id: id,
            kind: kind,
            mode: SessionMode.camera,
            startedAt: start,
            endedAt: start.add(length),
            status: SessionStatus.finished,
            subjectId: subjectId,
            segments: <Segment>[
              Segment(id: '$id-seg', kind: SegmentKind.seated, startAt: start.toUtc(), endAt: start.add(length).toUtc()),
            ],
            sensitivityLevel: 0,
          );

  /// Three recorded days this week (Mon 9/28 … Sun 10/4) + one last week.
  Future<({String math, String eng})> seedWeek() async {
    final subjects = h.container.read(subjectRepositoryProvider);
    final math = await subjects.create(name: '수학', colorIndex: 0);
    final eng = await subjects.create(name: '영어', colorIndex: 1);
    await seedSession(id: 'm', start: DateTime(2026, 9, 29, 9), length: const Duration(hours: 1), subjectId: math.id);
    await seedSession(id: 'e', start: DateTime(2026, 10, 1, 9), length: const Duration(minutes: 45), subjectId: eng.id, kind: SessionKind.todo);
    await seedSession(id: 's', start: DateTime(2026, 10, 3, 9), length: const Duration(minutes: 30), kind: SessionKind.self);
    await seedSession(id: 'last', start: DateTime(2026, 9, 24, 9), length: const Duration(minutes: 30), subjectId: math.id);
    return (math: math.id, eng: eng.id);
  }

  Future<void> seedWrongs(String subjectId) => h.container.read(wrongsRepositoryProvider).applySaved(
        requestId: 'req-1',
        subjectId: subjectId,
        rangeText: 'p.10',
        items: const <WrongItemDraft>[
          WrongItemDraft(id: 'w1', pageIndex: 0, number: 3, mark: Mark.wrong, confidence: 0.5, userConfirmed: true),
          WrongItemDraft(id: 'w2', pageIndex: 0, number: 7, mark: Mark.unsolved, confidence: 0.4, userConfirmed: true),
        ],
        entries: const <ReviewEntryDraft>[],
      );

  FakeBillingGateway billing() => h.container.read(billingGatewayProvider) as FakeBillingGateway;

  testWidgets('loading skeleton on the first frame, then the sparse state with 지금까지 and 집중 시작', (tester) async {
    await h.pumpApp(tester);
    await tester.tap(find.text(CommonStrings.tabStats).last);
    await tester.pump();
    expect(find.byKey(StatsKeys.skeleton), findsOneWidget);
    await tester.pumpAndSettle();
    expect(find.byKey(StatsKeys.skeleton), findsNothing);
    expect(find.descendant(of: find.byType(StatsScreen), matching: find.text(StatsStrings.title)), findsOneWidget);
    expect(find.byKey(StatsKeys.sparse), findsOneWidget);
    expect(find.text(StatsStrings.sparseTitle), findsOneWidget);
    expect(find.text(StatsStrings.sparseSoFar('0분')), findsOneWidget);
    expect(find.byKey(StatsKeys.summary), findsNothing);
    expect(find.text(StatsStrings.wrongsTeaserTitle), findsOneWidget, reason: 'free teaser above the sparse card');

    await tester.tap(find.byKey(StatsKeys.sparseStart));
    await tester.pumpAndSettle();
    expect(find.text(MeasureStrings.setup), findsWidgets);
    await h.unmount(tester);
  });

  testWidgets('two recorded days (one session across midnight) stay sparse with the total so far', (tester) async {
    await seedSession(id: 'a', start: DateTime(2026, 10, 2, 23, 30), length: const Duration(hours: 1));
    await openStats(tester);
    expect(find.byKey(StatsKeys.sparse), findsOneWidget);
    expect(find.text(StatsStrings.sparseSoFar('1시간')), findsOneWidget);
    await h.unmount(tester);
  });

  testWidgets('weekly facts: summary, 지난주 comparison, bar tooltip, subjects split, hours bands, focus pattern', (tester) async {
    await seedWeek();
    await openStats(tester);
    expect(find.byKey(StatsKeys.sparse), findsNothing);
    expect(find.text(StatsStrings.thisWeekSeated), findsOneWidget);
    expect(find.text(StatsStrings.weekRange(9, 28, 10, 4)), findsOneWidget);
    expect(find.text('2시간 15분'), findsOneWidget);
    expect(find.text(StatsStrings.compareMore('1시간 45분')), findsOneWidget, reason: '135 min through Saturday vs 30 min last week through Saturday');
    expect(find.text('${StatsStrings.recordedDays(3)} · ${StatsStrings.dailyAverage('45분')}'), findsOneWidget);

    // Bars: tap today's bar (Saturday, 6th of 7 slots).
    final chart = tester.getRect(find.descendant(of: find.byKey(StatsKeys.bars), matching: find.byType(CustomPaint)).first);
    await tester.tapAt(Offset(chart.left + chart.width * 5.5 / 7, chart.center.dy));
    await tester.pumpAndSettle();
    expect(find.byKey(StatsKeys.barTooltip), findsOneWidget);
    expect(find.text(StatsStrings.barValue('10월 3일 토', '30분')), findsOneWidget);
    await tester.tapAt(Offset(chart.left + chart.width * 6.5 / 7, chart.center.dy));
    await tester.pumpAndSettle();
    expect(find.text(StatsStrings.barValue('10월 4일 일', StatsStrings.futureDay)), findsOneWidget);

    // Subjects
    await tester.ensureVisible(find.byKey(StatsKeys.subjects));
    await tester.pumpAndSettle();
    expect(find.text('${StatsStrings.bySubject} · ${StatsStrings.subjectTotal('2시간 15분')}'), findsOneWidget);
    expect(find.text('수학'), findsOneWidget);
    expect(find.text(StatsStrings.percent(44)), findsOneWidget);
    expect(find.text(StatsStrings.subjectSplit('1시간', StatsStrings.none)), findsOneWidget);
    expect(find.text(StatsStrings.subjectSplit(StatsStrings.none, '30분')), findsOneWidget, reason: '과목 없음 자습');
    expect(find.text(PlannerStrings.noSubject), findsOneWidget);

    // Hours: everything between 09:00 and 10:00 → 오전 band
    await tester.ensureVisible(find.byKey(StatsKeys.hours));
    await tester.pumpAndSettle();
    expect(find.text(StatsStrings.hourBands[1]), findsOneWidget);
    expect(find.descendant(of: find.byKey(StatsKeys.hours), matching: find.text('2시간 15분')), findsOneWidget, reason: '오전 band');

    // Focus pattern: runs 60 · 45 · 30 min
    await tester.ensureVisible(find.byKey(StatsKeys.focus));
    await tester.pumpAndSettle();
    expect(find.text(StatsStrings.longestRun('1시간')), findsOneWidget);
    expect(find.text('${StatsStrings.averageSession('45분')} · ${StatsStrings.sessionCount(3)}'), findsOneWidget);
    expect(find.text(StatsStrings.runs(2)), findsOneWidget, reason: '30–60분');
    expect(find.byKey(StatsKeys.crossView), findsOneWidget);
    expect(find.text(StatsStrings.crossHidden), findsNothing, reason: 'cross view hidden in v1');
    await h.unmount(tester);
  });

  testWidgets('monthly: toggle, month range pill, October total, prev/next/오늘', (tester) async {
    await seedWeek();
    await openStats(tester);
    await tester.tap(find.text(StatsStrings.periodMonth));
    await tester.pumpAndSettle();
    expect(find.text(StatsStrings.thisMonthSeated), findsOneWidget);
    expect(find.text(PlannerStrings.pickerMonth(2026, 10)), findsOneWidget);
    expect(find.text('1시간 15분'), findsOneWidget, reason: '10/1 45분 + 10/3 30분');
    expect(find.text(StatsStrings.monthRange(10, 31)), findsOneWidget);
    expect(find.byKey(StatsKeys.today), findsNothing);

    await tester.tap(find.byKey(StatsKeys.prev));
    await tester.pumpAndSettle();
    expect(find.text(StatsStrings.monthSeated(2026, 9)), findsOneWidget);
    expect(find.descendant(of: find.byKey(StatsKeys.summary), matching: find.text('1시간 30분')), findsOneWidget, reason: '9/24 30분 + 9/29 60분');
    expect(find.byKey(StatsKeys.today), findsOneWidget);
    await tester.tap(find.byKey(StatsKeys.today));
    await tester.pumpAndSettle();
    expect(find.text(StatsStrings.thisMonthSeated), findsOneWidget);

    await tester.tap(find.text(StatsStrings.periodWeek));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(StatsKeys.prev));
    await tester.pumpAndSettle();
    expect(find.text(StatsStrings.lastWeekSeated), findsOneWidget);
    expect(find.text(StatsStrings.compareNone), findsOneWidget, reason: 'nothing two weeks ago');
    await h.unmount(tester);
  });

  testWidgets('wrongs: free teaser → paywall; premium card with counts and 전체 보기 → /wrongs; expired read-only card → 재구독', (tester) async {
    final ids = await seedWeek();
    await seedWrongs(ids.math);
    await openStats(tester);
    expect(find.text(StatsStrings.wrongsTeaserTitle), findsOneWidget);
    expect(find.text(StatsStrings.premiumBadge), findsOneWidget);
    await tester.tap(find.byKey(StatsKeys.wrongsBadge));
    await tester.pumpAndSettle();
    expect(find.text(BillingStrings.paywallTitle), findsWidgets);
    h.container.read(appRouterProvider).pop();
    await tester.pumpAndSettle();

    billing().force(EntitlementStatus.premium);
    await tester.pumpAndSettle();
    expect(find.text(StatsStrings.wrongsTeaserTitle), findsNothing);
    expect(
      find.text('${StatsStrings.wrongsOpen(2)} · ${StatsStrings.readingsThisWeek(0)} · ${StatsStrings.wrongsResolved(0)}'),
      findsOneWidget,
    );
    expect(find.text(StatsStrings.wrongsCount(2)), findsOneWidget);
    await tester.tap(find.byKey(StatsKeys.wrongsSeeAll));
    await tester.pumpAndSettle();
    expect(find.text(WrongsStrings.title), findsWidgets);
    h.container.read(appRouterProvider).pop();
    await tester.pumpAndSettle();

    billing().force(EntitlementStatus.expired);
    await tester.pumpAndSettle();
    expect(find.text(StatsStrings.wrongsExpired(2, 1)), findsOneWidget);
    expect(find.text(StatsStrings.readOnly), findsOneWidget);
    expect(find.text(StatsStrings.wrongsExpiredBody), findsOneWidget);
    await tester.tap(find.byKey(StatsKeys.wrongsResubscribe));
    await tester.pumpAndSettle();
    expect(find.text(BillingStrings.paywallTitle), findsWidgets);
    await h.unmount(tester);
  });

  testWidgets('premium without saved wrongs shows the empty wrongs card', (tester) async {
    billing().force(EntitlementStatus.premium);
    await openStats(tester);
    expect(find.text(StatsStrings.wrongsEmptyTitle), findsOneWidget);
    expect(find.byKey(StatsKeys.wrongsSeeAll), findsOneWidget);
    await h.unmount(tester);
  });

  testWidgets('tablet: summary column left, bars right; dark theme tokens', (tester) async {
    tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
    addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
    await seedWeek();
    await openStats(tester, size: kTablet);
    expect(find.byKey(StatsKeys.summary), findsOneWidget);
    expect(find.byKey(StatsKeys.bars), findsOneWidget);
    final summary = tester.getRect(find.byKey(StatsKeys.summary));
    final bars = tester.getRect(find.byKey(StatsKeys.bars));
    expect(bars.left, greaterThan(summary.right), reason: 'two columns');
    final scaffold = tester.widget<Scaffold>(find.descendant(of: find.byType(StatsScreen), matching: find.byType(Scaffold)));
    expect(scaffold.backgroundColor, AppColors.dark.bg);
    expect(tester.takeException(), isNull);
    await h.unmount(tester);
  });
}
