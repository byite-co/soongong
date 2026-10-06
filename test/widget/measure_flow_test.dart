import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soongong/app.dart';
import 'package:soongong/core/contracts/fakes/fake_seat_engine.dart';
import 'package:soongong/core/contracts/providers.dart';
import 'package:soongong/core/contracts/seat_engine.dart';
import 'package:soongong/core/domain/clock.dart';
import 'package:soongong/core/domain/enums.dart';
import 'package:soongong/core/domain/local_date.dart';
import 'package:soongong/core/router/app_router.dart';
import 'package:soongong/core/strings/home_strings.dart';
import 'package:soongong/core/strings/measure_strings.dart';
import 'package:soongong/core/widgets/widgets.dart';
import 'package:soongong/data/auth/auth_mode.dart';
import 'package:soongong/data/repositories/repository_providers.dart';
import 'package:soongong/features/home/application/session_recovery.dart';
import 'package:soongong/features/measure/application/measure_controller.dart';

import '../helpers/measure_fakes.dart';
import '../unit/data/db_test_helpers.dart';

void main() {
  late TestHarness h;
  late FakeMonotonicClock mono;
  late TestMeasureEngine engine;
  late MeasureController controller;
  late ProviderContainer container;
  setUp(() {
    h = TestHarness(userId: kLocalUserId);
    mono = FakeMonotonicClock();
    engine = TestMeasureEngine();
    controller = MeasureController(
      engine: engine,
      sessions: h.sessions,
      settings: h.settings,
      planner: h.planner,
      wall: h.clock,
      monotonic: mono,
      device: TestMeasureDevice(),
      automaticTicks: false,
    );
    container = ProviderContainer(
      overrides: [
        deviceIdProvider.overrideWithValue('dev-a'),
        appDatabaseProvider.overrideWithValue(h.db),
        appClockProvider.overrideWithValue(h.clock),
        authModeProvider.overrideWithValue(AuthMode.localOnly),
        measureControllerProvider.overrideWithValue(controller),
        seatEngineProvider.overrideWithValue(engine),
      ],
    );
  });
  tearDown(() async {
    controller.dispose();
    container.dispose();
    await engine.close();
    await h.close();
    hideAppToast();
  });
  Future<void> mount(WidgetTester tester) async {
    if (const bool.fromEnvironment('MEASURE_SCREENSHOTS')) {
      await tester.runAsync(() async {
        final font = FontLoader('Pretendard')
          ..addFont(rootBundle.load('assets/fonts/PretendardVariable.ttf'));
        await font.load();
        final icons = FontLoader('packages/lucide_icons_flutter/Lucide')
          ..addFont(
            rootBundle.load('packages/lucide_icons_flutter/assets/lucide.ttf'),
          );
        await icons.load();
      });
    }
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      RepaintBoundary(
        key: const ValueKey('measure-preview'),
        child: UncontrolledProviderScope(
          container: container,
          child: const SoongongApp(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> capture(WidgetTester tester, String name) async {
    if (!const bool.fromEnvironment('MEASURE_SCREENSHOTS')) return;
    final boundary = tester.renderObject<RenderRepaintBoundary>(
      find.byKey(const ValueKey('measure-preview')),
    );
    await tester.runAsync(() async {
      final rendered = await boundary.toImage();
      final bytes = await rendered.toByteData(format: ui.ImageByteFormat.png);
      final directory = Directory('../measure-preview')
        ..createSync(recursive: true);
      await File('${directory.path}/$name.png')
          .writeAsBytes(bytes!.buffer.asUint8List());
      rendered.dispose();
    });
  }

  Future<void> unmount(WidgetTester tester) async {
    hideAppToast();
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  }

  Future<void> tap(WidgetTester tester, String label) async {
    final finder = find.text(label).last;
    await tester.ensureVisible(finder);
    await tester.tap(finder);
    await tester.pump(const Duration(milliseconds: 100));
    if (find.text(MeasureStrings.shortTitle).evaluate().isNotEmpty) {
      await tester.pump(const Duration(milliseconds: 300));
      return; // The button awaits the user's decision; its spinner is intentional.
    }
    await tester.pumpAndSettle();
  }

  testWidgets(
    'home → setup task → manual focus → pause → summary → save → home ring',
    (tester) async {
      await h.settings.setSeatDetectionEnabled(on: false);
      await h.planner.createItem(
        kind: PlannerKind.todo,
        title: '오늘 문제 풀기',
        date: LocalDate.of(kT0),
      );
      await mount(tester);
      await tap(tester, HomeStrings.startFocus);
      await tap(tester, '오늘 문제 풀기');
      await capture(tester, 'setup-light');
      await tap(tester, MeasureStrings.start);
      expect(find.text(MeasureStrings.focus), findsOneWidget);
      expect(
        find.text(HomeStrings.recoverTitle),
        findsNothing,
        reason: 'own live snapshot must not trigger home recovery sheet',
      );
      mono.advance(const Duration(minutes: 4));
      controller.tick();
      await tester.pump();
      await capture(tester, 'focus-light');
      await tap(tester, MeasureStrings.pause);
      mono.advance(const Duration(minutes: 1));
      controller.tick();
      await tester.pump();
      await tap(tester, MeasureStrings.resume);
      mono.advance(const Duration(minutes: 1));
      controller.tick();
      await tester.pump();
      await tap(tester, MeasureStrings.end);
      expect(find.text('00:05:00'), findsOneWidget);
      await capture(tester, 'summary-light');
      await tap(tester, MeasureStrings.completeTask);
      await tap(tester, MeasureStrings.save);
      expect(find.text(MeasureStrings.saved), findsOneWidget);
      await tap(tester, MeasureStrings.home);
      expect(find.text('5분'), findsOneWidget);
      expect((await h.sessions.getAll()).single.seatedSeconds, 300);
      expect((await h.planner.getAllItems()).single.isDone, isTrue);
      expect(await h.sessions.readSnapshot(), isNull);
      await unmount(tester);
    },
  );

  testWidgets(
    'cameraBusy → manual preparation → short-save confirmation → discard clears snapshot',
    (tester) async {
      engine.availability = SeatAvailability.cameraBusy;
      await mount(tester);
      await tap(tester, HomeStrings.startFocus);
      expect(find.text(MeasureStrings.cameraBusy), findsOneWidget);
      await tap(tester, MeasureStrings.toManual);
      await tap(tester, MeasureStrings.start);
      expect(controller.mode, SessionMode.manual);
      mono.advance(const Duration(seconds: 40));
      await tap(tester, MeasureStrings.end);
      await tap(tester, MeasureStrings.save);
      expect(find.text(MeasureStrings.shortTitle), findsOneWidget);
      await tap(tester, '취소');
      await tap(tester, MeasureStrings.discard);
      await tap(tester, MeasureStrings.discard);
      expect(await h.sessions.readSnapshot(), isNull);
      expect(await h.sessions.getAll(), isEmpty);
      await unmount(tester);
    },
  );

  testWidgets('dark tablet focus and summary preserve layout', (tester) async {
    tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
    addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
    await controller.start(mode: SessionMode.manual);
    container.read(recoveryPromptedProvider.notifier).mark();
    await mount(tester);
    tester.view.physicalSize = const Size(1024, 768);
    container.read(appRouterProvider).go('/measure/focus');
    mono.advance(const Duration(minutes: 4));
    controller.tick();
    await tester.pumpAndSettle();
    expect(
      Theme.of(tester.element(find.text(MeasureStrings.focus))).brightness,
      Brightness.dark,
    );
    await capture(tester, 'focus-dark-tablet');
    await tap(tester, MeasureStrings.end);
    await capture(tester, 'summary-dark-tablet');
    expect(tester.takeException(), isNull);
    await unmount(tester);
  });

  for (final scenario in [
    FakeSeatScenario.alwaysSeated,
    FakeSeatScenario.awayAfter,
    FakeSeatScenario.lostAfter,
  ]) {
    testWidgets('Fake ${scenario.name}: setup → focus → save → home', (
      tester,
    ) async {
      controller.dispose();
      container.dispose();
      final fake = FakeSeatEngine(
        scenario: scenario,
        afterSeconds: 5,
        now: h.clock.now,
      );
      addTearDown(fake.dispose);
      controller = MeasureController(
        engine: fake,
        sessions: h.sessions,
        settings: h.settings,
        planner: h.planner,
        wall: h.clock,
        monotonic: mono,
        device: TestMeasureDevice(),
        automaticTicks: false,
      );
      container = ProviderContainer(
        overrides: [
          deviceIdProvider.overrideWithValue('dev-a'),
          appDatabaseProvider.overrideWithValue(h.db),
          appClockProvider.overrideWithValue(h.clock),
          authModeProvider.overrideWithValue(AuthMode.localOnly),
          measureControllerProvider.overrideWithValue(controller),
          seatEngineProvider.overrideWithValue(fake),
        ],
      );
      await mount(tester);
      await tap(tester, HomeStrings.startFocus);
      await tap(tester, MeasureStrings.start);
      for (var i = 0; i < 100; i++) {
        mono.advance(const Duration(seconds: 1));
        controller.tick();
        await tester.pump(const Duration(seconds: 1));
        if (controller.cameraLost) {
          await tap(tester, MeasureStrings.manualContinue);
        }
      }
      if (scenario == FakeSeatScenario.awayAfter) {
        expect(controller.currentKind, SegmentKind.away);
      }
      if (scenario == FakeSeatScenario.lostAfter) {
        expect(controller.mode, SessionMode.manual);
      }
      await tap(tester, MeasureStrings.end);
      await tap(tester, MeasureStrings.save);
      expect(find.text(MeasureStrings.shortTitle), findsOneWidget);
      await tap(tester, MeasureStrings.save);
      expect(find.text(MeasureStrings.saved), findsOneWidget);
      await tap(tester, MeasureStrings.home);
      expect((await h.sessions.getAll()).single.seatedSeconds, greaterThan(0));
      expect(await h.sessions.readSnapshot(), isNull);
      expect(tester.takeException(), isNull);
      await unmount(tester);
    });
  }

  testWidgets(
    'summary saving, failure, retry keep input; detail cancel and delete undo preserve data',
    (tester) async {
      await controller.start(mode: SessionMode.camera);
      mono.advance(const Duration(seconds: 10));
      engine.sample(10, seated: true);
      mono.advance(const Duration(seconds: 1));
      engine.sample(11, seated: false);
      mono.advance(const Duration(seconds: 61));
      engine.sample(72, seated: false);
      mono.advance(const Duration(seconds: 130));
      engine.sample(202, seated: true);
      mono.advance(const Duration(seconds: 200));
      await controller.finish();
      container.read(recoveryPromptedProvider.notifier).mark();
      await mount(tester);
      container.read(appRouterProvider).go('/measure/summary');
      await tester.pumpAndSettle();
      await h.db.customStatement(
        "CREATE TRIGGER fail_save BEFORE UPDATE ON sessions BEGIN SELECT RAISE(ABORT, 'test failure'); END",
      );
      final entered = Completer<void>();
      final release = Completer<void>();
      final blocker = h.writer.runInTransaction(() async {
        entered.complete();
        await release.future;
      });
      await entered.future;
      await tester.tap(find.text(MeasureStrings.save));
      await tester.pump();
      expect(controller.saveState, isA<MeasureSaving>());
      expect(find.text(MeasureStrings.saving), findsOneWidget);
      release.complete();
      await blocker;
      await tester.pumpAndSettle();
      expect(find.text(MeasureStrings.failed), findsOneWidget);
      expect(await h.sessions.readSnapshot(), isNotNull);
      await h.db.customStatement('DROP TRIGGER fail_save');
      await tap(tester, MeasureStrings.retry);
      expect(find.text(MeasureStrings.saved), findsOneWidget);
      final id = (await h.sessions.getAll()).single.id;
      await tap(tester, MeasureStrings.viewSession);
      await tap(tester, MeasureStrings.edit);
      await tap(tester, MeasureStrings.segment(SegmentKind.away));
      await tap(tester, MeasureStrings.restore);
      await tap(tester, MeasureStrings.cancelChanges);
      await tap(tester, MeasureStrings.cancelChanges);
      expect(
        (await h.sessions.getSegments(id)).any((s) => s.corrected),
        isFalse,
      );
      expect(await h.sessions.correctionsSince(kT0), isEmpty);
      await tap(tester, MeasureStrings.delete);
      await tap(tester, MeasureStrings.delete);
      await tap(tester, MeasureStrings.undo);
      expect((await h.sessions.get(id))!.stamp.pendingDeleteUntil, isNull);
      await tester.pump(const Duration(seconds: 6));
      expect(await h.sessions.get(id), isNotNull);
      await unmount(tester);
    },
  );
}
