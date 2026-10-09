// HomeScreen (S05) in the local-only dev mode: empty state, facts from the
// repositories, todo toggle, settings gear, tablet two-column layout, dark
// theme, and the session-recovery sheet (finish path, D23).

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soongong/core/domain/enums.dart';
import 'package:soongong/core/domain/local_date.dart';
import 'package:soongong/core/strings/common_strings.dart';
import 'package:soongong/core/strings/home_strings.dart';
import 'package:soongong/core/strings/measure_strings.dart';
import 'package:soongong/core/theme/app_theme.dart';
import 'package:soongong/data/auth/auth_mode.dart';
import 'package:soongong/data/repositories/repositories.dart';
import 'package:soongong/features/measure/domain/segment.dart';
import 'package:soongong/features/measure/domain/session_snapshot.dart';

import '../helpers/app_harness.dart';

void main() {
  late AppHarness h;

  setUp(() => h = AppHarness(mode: AuthMode.localOnly));
  tearDown(() => h.dispose());

  Future<void> seedSession({required DateTime start, required Duration seated, SessionKind kind = SessionKind.study}) =>
      h.container.read(sessionRepositoryProvider).saveFinished(
            id: 'sess-${start.millisecondsSinceEpoch}',
            kind: kind,
            mode: SessionMode.camera,
            startedAt: start,
            endedAt: start.add(seated),
            status: SessionStatus.finished,
            segments: <Segment>[
              Segment(id: 'seg-${start.millisecondsSinceEpoch}', kind: SegmentKind.seated, startAt: start.toUtc(), endAt: start.add(seated).toUtc()),
            ],
            sensitivityLevel: 0,
          );

  testWidgets('empty state: 0분, hint, no todos, 4 tabs, gear → settings', (tester) async {
    await h.pumpApp(tester);
    expect(find.text('0분'), findsOneWidget);
    expect(find.text(HomeStrings.emptyHint), findsOneWidget);
    expect(find.text(HomeStrings.todosEmpty), findsOneWidget);
    expect(find.text(HomeStrings.addTodo), findsOneWidget);
    expect(find.text(HomeStrings.todayEventsNone), findsOneWidget);
    expect(find.text(HomeStrings.fullDate(2026, 10, 3, 6)), findsOneWidget);
    expect(find.byType(NavigationBar), findsOneWidget);

    await tester.tap(find.byTooltip(HomeStrings.settings));
    await tester.pumpAndSettle();
    expect(find.text(CommonStrings.settingsTitle), findsWidgets);
    expect(find.text(CommonStrings.placeholderPreparing), findsOneWidget);
    await h.unmount(tester);
  });

  testWidgets('facts: today 1시간 30분 vs yesterday, streak 2, remaining todos, toggle done', (tester) async {
    final now = h.clock.now();
    await seedSession(start: now.subtract(const Duration(hours: 3)), seated: const Duration(hours: 1));
    await seedSession(start: now.subtract(const Duration(hours: 1)), seated: const Duration(minutes: 30), kind: SessionKind.self);
    await seedSession(start: now.subtract(const Duration(days: 1, hours: 2)), seated: const Duration(hours: 1));
    final planner = h.container.read(plannerRepositoryProvider);
    await planner.createItem(kind: PlannerKind.todo, title: '수학 숙제', date: LocalDate.of(now));
    await planner.createItem(kind: PlannerKind.study, title: '영어 단어', date: LocalDate.of(now));

    await h.pumpApp(tester);
    expect(find.text('1시간 30분'), findsOneWidget);
    expect(find.text(HomeStrings.moreThanYesterday('30분')), findsOneWidget);
    expect(find.text(HomeStrings.remainingTodos(2)), findsOneWidget);
    expect(find.text(HomeStrings.doneOfTotal(0, 2)), findsOneWidget);
    expect(find.text('2'), findsOneWidget, reason: 'streak days inside the flame');
    expect(find.text('수학 숙제'), findsOneWidget);

    await tester.tap(find.bySemanticsLabel(HomeStrings.toggleDone).first);
    await tester.pumpAndSettle();
    expect(find.text(HomeStrings.doneOfTotal(1, 2)), findsOneWidget);
    expect(find.text(HomeStrings.remainingTodos(1)), findsOneWidget);
    final items = await planner.getItemsBetween(LocalDate.of(now), LocalDate.of(now));
    expect(items.where((i) => i.isDone).length, 1);
    await h.unmount(tester);
  });

  testWidgets('tablet (t5): side rail and two columns; dark theme (s4) uses dark tokens', (tester) async {
    tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
    addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
    await h.pumpApp(tester, size: kTablet);
    expect(find.byType(NavigationRail), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);
    final scaffold = tester.widget<Scaffold>(find.byType(Scaffold).last);
    expect(scaffold.backgroundColor, AppColors.dark.bg);
    await h.unmount(tester);
  });

  testWidgets('recovery sheet from a snapshot opens summary, then saves an interrupted session', (tester) async {
    final now = h.clock.now();
    final start = now.subtract(const Duration(minutes: 70)).toUtc();
    await h.container.read(sessionRepositoryProvider).writeSnapshot(
          SessionSnapshot(
            sessionId: 'open-1',
            mode: SessionMode.camera,
            kind: SessionKind.study,
            startedAt: start,
            segments: const <Segment>[],
            openKind: SegmentKind.seated,
            openStart: start,
            savedAt: start.add(const Duration(minutes: 60)),
            sensitivity: 0,
          ),
        );
    await h.pumpApp(tester);
    expect(find.text(HomeStrings.recoverTitle), findsOneWidget);
    expect(find.textContaining('1시간'), findsWidgets);
    expect(find.text(HomeStrings.recoverResume), findsOneWidget);
    expect(find.text(HomeStrings.recoverDiscard), findsOneWidget);

    await tester.tap(find.text(HomeStrings.recoverFinish));
    await tester.pumpAndSettle();
    expect(find.text(HomeStrings.recoverTitle), findsNothing);
    expect(find.text(MeasureStrings.summary), findsOneWidget);
    expect(find.text('01:00:00'), findsOneWidget);
    await tester.tap(find.text(MeasureStrings.save));
    await tester.pumpAndSettle();
    expect(find.text(MeasureStrings.saved), findsOneWidget, reason: 'toast on home');

    final sessions = h.container.read(sessionRepositoryProvider);
    final saved = await sessions.get('open-1');
    expect(saved?.status, SessionStatus.interrupted);
    expect(saved?.seatedSeconds, 3600);
    expect(await sessions.readSnapshot(), isNull);
    expect(find.text('1시간'), findsOneWidget, reason: 'hero now shows the recovered time');
    await h.unmount(tester);
  });

  testWidgets('recovery sheet dismissed → kept toast, asked only once per run', (tester) async {
    final start = h.clock.now().subtract(const Duration(minutes: 10)).toUtc();
    await h.container.read(sessionRepositoryProvider).writeSnapshot(
          SessionSnapshot(
            sessionId: 'open-2',
            mode: SessionMode.manual,
            kind: SessionKind.self,
            startedAt: start,
            segments: const <Segment>[],
            openKind: SegmentKind.manual,
            openStart: start,
            savedAt: start.add(const Duration(minutes: 5)),
            sensitivity: 0,
          ),
        );
    await h.pumpApp(tester);
    expect(find.text(HomeStrings.recoverTitle), findsOneWidget);
    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();
    expect(find.text(HomeStrings.recoverTitle), findsNothing);
    expect(find.text(HomeStrings.recoverKept), findsOneWidget);
    expect(await h.container.read(sessionRepositoryProvider).readSnapshot(), isNotNull);
    await h.unmount(tester);
  });
}
