import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:soongong/core/contracts/seat_engine.dart';
import 'package:soongong/core/domain/clock.dart';
import 'package:soongong/core/domain/enums.dart';
import 'package:soongong/data/engines/engines.dart';
import 'package:soongong/features/measure/application/measure_controller.dart';

import '../../helpers/fake_seat_sources.dart';
import '../../helpers/measure_fakes.dart';
import '../data/db_test_helpers.dart';

void main() {
  late TestHarness h;
  late FakeMonotonicClock mono;
  late TestMeasureEngine engine;
  late MeasureController controller;
  _DelayedEventsSeatEngine? realEngine;

  Future<void> flush() async {
    for (var i = 0; i < 30; i++) {
      await Future<void>.delayed(Duration.zero);
    }
  }

  setUp(() {
    h = TestHarness();
    mono = FakeMonotonicClock();
    engine = TestMeasureEngine();
    realEngine = null;
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
    await realEngine?.dispose();
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

  test(
    'real engine failed readiness stays paused before delayed SeatError',
    () async {
      controller.dispose();
      await flush();
      final source = FakeSeatFrameSource(
        openError: const SeatFrameSourceException('camera_busy'),
      );
      final actual = _DelayedEventsSeatEngine(source, mono);
      realEngine = actual;
      controller = MeasureController(
        engine: actual,
        sessions: h.sessions,
        settings: h.settings,
        planner: h.planner,
        wall: h.clock,
        monotonic: mono,
        device: TestMeasureDevice(),
        automaticTicks: false,
      );

      expect(await controller.start(mode: SessionMode.camera), isTrue);
      await flush();
      expect(actual.isRunning, isFalse);
      expect(actual.pending.single, isA<SeatError>());
      // The engine's real start() has returned, but its failure event has
      // deliberately not reached the controller yet.
      expect(controller.paused, isTrue);
      expect(controller.cameraLost, isTrue);
      mono.advance(const Duration(seconds: 1));
      expect(controller.seated, Duration.zero);
      expect((await h.sessions.readSnapshot())!.openKind, SegmentKind.paused);

      actual.deliverPending();
      await flush();
      expect(controller.paused, isTrue);
      expect(controller.seated, Duration.zero);

      // A later real successful acquisition still follows the existing
      // policy: seated time begins as soon as the engine is running.
      source.openError = null;
      await controller.resume();
      expect(actual.isRunning, isTrue);
      expect(controller.paused, isFalse);
      mono.advance(const Duration(seconds: 5));
      expect(controller.seated, const Duration(seconds: 5));
    },
  );
}

/// Keep the real engine's start/failure/readiness behavior and delay only
/// delivery of its asynchronous events to make the ordering deterministic.
class _DelayedEventsSeatEngine extends SeatEngineImpl {
  _DelayedEventsSeatEngine(FakeSeatFrameSource source, MonotonicClock monotonic)
    : super(
        source: source,
        detectorFactory: FakePresenceDetector.new,
        permission: FakeCameraPermissionGateway(),
        monotonic: monotonic,
      ) {
    _original = super.events.listen(pending.add);
  }

  final List<SeatEngineEvent> pending = [];
  final _delayed = StreamController<SeatEngineEvent>.broadcast();
  late final StreamSubscription<SeatEngineEvent> _original;

  @override
  Stream<SeatEngineEvent> get events => _delayed.stream;

  void deliverPending() {
    for (final event in pending) {
      _delayed.add(event);
    }
    pending.clear();
  }

  @override
  Future<void> dispose() async {
    await _original.cancel();
    await super.dispose();
    await _delayed.close();
  }
}
