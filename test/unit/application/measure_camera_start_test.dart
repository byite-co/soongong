import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:soongong/core/contracts/seat_engine.dart';
import 'package:soongong/core/domain/clock.dart';
import 'package:soongong/core/domain/enums.dart';
import 'package:soongong/features/measure/application/measure_controller.dart';

import '../../helpers/measure_fakes.dart';
import '../data/db_test_helpers.dart';

void main() {
  late TestHarness h;
  late FakeMonotonicClock mono;
  late TestMeasureEngine engine;
  late MeasureController controller;

  Future<void> flush() async {
    for (var i = 0; i < 30; i++) {
      await Future<void>.delayed(Duration.zero);
    }
  }

  setUp(() {
    h = TestHarness();
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
  });

  tearDown(() async {
    controller.dispose();
    await flush();
    await engine.close();
    await h.close();
  });

  test(
    'camera open wait is paused and only successful ready time is seated',
    () async {
      final ready = Completer<void>();
      engine.starting = ready;
      final starting = controller.start(mode: SessionMode.camera);
      await flush();
      expect(engine.starts, 1);
      mono.advance(const Duration(seconds: 8));
      expect(controller.paused, isTrue);
      expect(controller.seated, Duration.zero);
      expect((await h.sessions.readSnapshot())!.openKind, SegmentKind.paused);
      ready.complete();
      expect(await starting, isTrue);
      expect(controller.paused, isFalse);
      expect(controller.seated, Duration.zero);
      mono.advance(const Duration(seconds: 5));
      expect(controller.seated, const Duration(seconds: 5));
    },
  );

  for (final failure in ['throw', 'event']) {
    test(
      'camera $failure during open adds no seated time before or after failure',
      () async {
        final ready = Completer<void>();
        engine.starting = ready;
        engine.failStart = failure == 'throw';
        final starting = controller.start(mode: SessionMode.camera);
        await flush();
        expect(engine.starts, 1);
        mono.advance(const Duration(seconds: 8));
        if (failure == 'event') {
          engine.eventBus.add(const SeatError('camera_busy'));
        }
        ready.complete();
        await starting;
        await flush();
        expect(controller.cameraLost, isTrue);
        expect(controller.paused, isTrue);
        expect(controller.seated, Duration.zero);
        mono.advance(const Duration(seconds: 20));
        expect(controller.seated, Duration.zero);
      },
    );
  }

  test('failed and pending camera resume preserve prior seated time', () async {
    await controller.start(mode: SessionMode.camera);
    mono.advance(const Duration(seconds: 5));
    await controller.pause();
    final blocked = Completer<void>();
    engine.starting = blocked;
    engine.failStart = true;
    final failedResume = controller.resume();
    await flush();
    mono.advance(const Duration(seconds: 8));
    expect(controller.seated, const Duration(seconds: 5));
    blocked.complete();
    await failedResume;
    expect(controller.paused, isTrue);
    expect(controller.reconnectFailed, isTrue);
    expect(controller.seated, const Duration(seconds: 5));

    final ready = Completer<void>();
    engine.starting = ready;
    engine.failStart = false;
    final resumed = controller.resume();
    await flush();
    mono.advance(const Duration(seconds: 3));
    expect(controller.seated, const Duration(seconds: 5));
    ready.complete();
    await resumed;
    expect(controller.paused, isFalse);
    mono.advance(const Duration(seconds: 4));
    expect(controller.seated, const Duration(seconds: 9));
  });
}
