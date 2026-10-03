import 'package:fake_async/fake_async.dart';
import 'package:flutter/widgets.dart' show AppLifecycleState;
import 'package:flutter_test/flutter_test.dart';
import 'package:soongong/core/contracts/seat_engine.dart';
import 'package:soongong/data/engines/engines.dart';

import '../../helpers/seat_engine_rig.dart';

void main() {
  test('1 Hz samples; seated follows detection; other frames are dropped', () {
    fakeAsync((async) {
      final r = Rig(async);
      r.start();
      expect(r.engine.isRunning, isTrue);
      expect(r.source.openCount, 1);
      expect(r.source.lastConfig!.lowPower, isFalse);

      r.stream(const Duration(seconds: 5), present: true);
      expect(r.samples.length, 5);
      expect(r.samples.every((s) => s.seated), isTrue);
      expect(r.samples.every((s) => s.confidence == null), isTrue);
      expect(r.samples.first.receivedAt, DateTime.utc(2026, 10, 1, 9));
      expect(r.samples.first.sinceStart, Duration.zero);
      expect(r.engine.framesDelivered, greaterThan(70));
      expect(r.engine.framesProcessed, 5);
      expect(r.engine.framesDropped, r.engine.framesDelivered - 5);
      expect(r.detector.calls, 5);
      expect(r.events, isEmpty);
      expect(r.engine.previewOrNull(), isNull);
    });
  });

  test('hold window: a 2 s miss stays seated, a 5 s miss turns not seated after 3 s', () {
    fakeAsync((async) {
      final r = Rig(async);
      r.start();
      r.stream(const Duration(seconds: 3), present: true);
      r.stream(const Duration(seconds: 2), present: false);
      expect(r.samples.every((s) => s.seated), isTrue, reason: '2 s gap is bridged');

      r.stream(const Duration(seconds: 2), present: true);
      final before = r.samples.length;
      r.stream(const Duration(seconds: 6), present: false);
      final tail = r.samples.sublist(before);
      // samples ~1.06 s apart: held, held, (3.17 s → not held), ...
      expect(tail.map((s) => s.seated).toList(), <bool>[true, true, false, false, false, false]);
      final diag = r.diagnostics.sublist(before);
      expect(diag[0].detected, isFalse);
      expect(diag[0].held, isTrue);
      expect(diag[2].held, isFalse);
    });
  });

  test('lowPower: one sample per 2 s, lowPower passed to the source', () {
    fakeAsync((async) {
      final r = Rig(async);
      r.start(const SeatEngineConfig(lowPower: true));
      expect(r.source.lastConfig!.lowPower, isTrue);
      expect(r.source.lastConfig!.targetFps, SeatFrameSourceConfig.lowPowerFps);
      expect(r.engine.processingInterval, const Duration(seconds: 2));
      r.stream(const Duration(seconds: 10), present: true);
      expect(r.samples.length, 5);
    });
  });

  test('sampleHz 2 → 500 ms; sampleHz 5 is clamped to 2', () {
    fakeAsync((async) {
      final r = Rig(async);
      r.start(const SeatEngineConfig(sampleHz: 5));
      expect(r.engine.processingInterval, const Duration(milliseconds: 500));
      r.stream(const Duration(seconds: 4), present: true, fps: 20);
      expect(r.samples.length, 8);
    });
  });

  test('detector latency longer than the interval → frames drop until it returns', () {
    fakeAsync((async) {
      final r = Rig(async, detectorLatency: const Duration(milliseconds: 1500));
      r.start();
      r.stream(const Duration(seconds: 6), present: true);
      // accepted at ~0, ~1.6, ~3.2, ~4.8 → the first three completed inside 6 s
      expect(r.samples.length, 3);
      expect(r.detector.calls, 4);
      expect(r.diagnostics.first.latency, greaterThanOrEqualTo(const Duration(milliseconds: 1500)));
    });
  });

  test('watchdog: no frame for 3 s → Lost once, no samples; frames resume → Recovered', () {
    fakeAsync((async) {
      final r = Rig(async);
      r.start();
      r.stream(const Duration(seconds: 2), present: true);
      final n = r.samples.length;

      r.idle(const Duration(milliseconds: 2900));
      expect(r.events, isEmpty);
      r.idle(const Duration(milliseconds: 300));
      expect(r.events.single, isA<SeatCameraLost>());
      expect(r.engine.isLost, isTrue);
      r.idle(const Duration(seconds: 5));
      expect(r.events.length, 1, reason: 'Lost is emitted once');
      expect(r.samples.length, n, reason: 'no decision without frames');

      r.stream(const Duration(seconds: 2), present: true);
      expect(r.events.length, 2);
      expect(r.events.last, isA<SeatCameraRecovered>());
      expect(r.engine.isLost, isFalse);
      expect(r.samples.length, greaterThan(n));
    });
  });

  test('camera fault inUse while running → Lost right away; recoverable fault → watchdog decides', () {
    fakeAsync((async) {
      final r = Rig(async);
      r.start();
      r.stream(const Duration(seconds: 1), present: true);
      r.source.fault(CameraFault.recoverable, 'recoverable');
      async.flushMicrotasks();
      expect(r.events, isEmpty);
      r.source.fault(CameraFault.inUse, 'The camera was already in use');
      async.flushMicrotasks();
      expect(r.events.single, isA<SeatCameraLost>());
      expect(r.engine.lastFault, 'The camera was already in use');
      r.source.fault(CameraFault.fatal, 'fatal');
      expect(r.events.length, 1);
      r.stream(const Duration(seconds: 1), present: true);
      expect(r.events.last, isA<SeatCameraRecovered>());
    });
  });

  test('background → camera released, Paused; restart by the caller → Recovered on the first frame', () {
    fakeAsync((async) {
      final r = Rig(async);
      r.start();
      r.stream(const Duration(seconds: 2), present: true);
      final n = r.samples.length;

      r.lifecycle.add(AppLifecycleState.inactive);
      async.flushMicrotasks();
      expect(r.engine.isRunning, isTrue, reason: 'inactive is not background');

      r.lifecycle.add(AppLifecycleState.hidden);
      async.flushMicrotasks();
      expect(r.engine.isRunning, isFalse);
      expect(r.source.isOpen, isFalse);
      expect(r.source.closeCount, 1);
      expect(r.engine.lastStopReason, SeatEngineStopReason.background);
      expect(r.events.single, isA<SeatPaused>());
      expect((r.events.single as SeatPaused).reason, SeatPauseReason.background);

      r.lifecycle.add(AppLifecycleState.paused);
      async.flushMicrotasks();
      expect(r.events.length, 1);

      // Frames after the stop (late callbacks) are ignored.
      r.stream(const Duration(seconds: 2), present: true);
      expect(r.samples.length, n);

      r.lifecycle.add(AppLifecycleState.resumed);
      async.flushMicrotasks();
      expect(r.engine.isRunning, isFalse, reason: 'restart is the caller\'s job');

      r.start();
      expect(r.source.openCount, 2);
      r.stream(const Duration(seconds: 1), present: true);
      expect(r.events.length, 2);
      expect(r.events.last, isA<SeatCameraRecovered>());
      expect(r.samples.length, greaterThan(n));
    });
  });

  test('start without permission → SeatError(permission_denied), source never opened', () {
    fakeAsync((async) {
      final r = Rig(async, permission: CameraPermissionResult.denied);
      r.start();
      expect(r.engine.isRunning, isFalse);
      expect(r.source.openCount, 0);
      expect(r.gateway.requests, 0, reason: 'start does not prompt');
      expect((r.events.single as SeatError).message, SeatErrorCode.permissionDenied);
    });
  });

  test('camera open failure → SeatError(code), not running; a later start works', () {
    fakeAsync((async) {
      final r = Rig(async);
      r.source.openError = const SeatFrameSourceException('camera_busy');
      r.start();
      expect(r.engine.isRunning, isFalse);
      expect((r.events.single as SeatError).message, SeatErrorCode.cameraBusy);
      r.source.openError = null;
      r.start();
      expect(r.engine.isRunning, isTrue);
    });
  });

  test('start is idempotent and stop ends sampling (in-flight detection discarded)', () {
    fakeAsync((async) {
      final r = Rig(async, detectorLatency: const Duration(milliseconds: 300));
      r.start();
      r.start();
      expect(r.source.openCount, 1);
      r.stream(const Duration(seconds: 2), present: true);
      final n = r.samples.length;
      r.source.emit(present: true); // accepted, detector busy for 300 ms
      r.tick(const Duration(milliseconds: 100));
      r.stop();
      expect(r.engine.isRunning, isFalse);
      expect(r.source.isOpen, isFalse);
      expect(r.engine.lastStopReason, SeatEngineStopReason.caller);
      r.idle(const Duration(seconds: 5));
      expect(r.samples.length, n, reason: 'no sample after stop');
      expect(r.events, isEmpty, reason: 'no Lost after a caller stop');
      r.stop(); // no-op
      expect(r.source.closeCount, 1);
    });
  });

  test('detector keeps failing → SeatError(detector_failed) once per streak; no samples meanwhile', () {
    fakeAsync((async) {
      final r = Rig(async);
      r.start();
      r.detector.error = StateError('boom');
      r.stream(const Duration(seconds: 5), present: true);
      expect(r.samples, isEmpty);
      expect(r.events.whereType<SeatError>().map((e) => e.message), <String>[
        SeatErrorCode.detectorFailed,
      ]);
      expect(r.detector.calls, 5, reason: 'failures release the cadence');

      r.detector.error = null;
      r.stream(const Duration(seconds: 2), present: true);
      expect(r.samples.length, 2);

      r.detector.error = StateError('boom');
      r.stream(const Duration(seconds: 4), present: true);
      expect(r.events.whereType<SeatError>().length, 2);
    });
  });

  group('checkAvailability', () {
    test('granted → probe decides (ok · busy · noCamera · failed)', () {
      fakeAsync((async) {
        for (final (probe, expected) in <(CameraProbeResult, SeatAvailability)>[
          (CameraProbeResult.ok, SeatAvailability.ok),
          (CameraProbeResult.busy, SeatAvailability.cameraBusy),
          (CameraProbeResult.noCamera, SeatAvailability.unavailable),
          (CameraProbeResult.failed, SeatAvailability.unavailable),
          (CameraProbeResult.permissionDenied, SeatAvailability.permissionDenied),
        ]) {
          final r = Rig(async, probe: probe);
          SeatAvailability? out;
          r.engine.checkAvailability().then((v) => out = v);
          async.flushMicrotasks();
          expect(out, expected, reason: probe.name);
          expect(r.gateway.requests, 0);
          expect(r.source.probeCount, 1);
        }
      });
    });

    test('denied → prompts once; granted afterwards → probe; still denied → no probe', () {
      fakeAsync((async) {
        final r = Rig(async, permission: CameraPermissionResult.denied);
        r.gateway.afterRequest = CameraPermissionResult.granted;
        SeatAvailability? out;
        r.engine.checkAvailability().then((v) => out = v);
        async.flushMicrotasks();
        expect(out, SeatAvailability.ok);
        expect(r.gateway.requests, 1);
        expect(r.source.probeCount, 1);

        final r2 = Rig(async, permission: CameraPermissionResult.denied);
        r2.engine.checkAvailability().then((v) => out = v);
        async.flushMicrotasks();
        expect(out, SeatAvailability.permissionDenied);
        expect(r2.gateway.requests, 1);
        expect(r2.source.probeCount, 0);
      });
    });

    test('permanentlyDenied / restricted → no prompt, permissionDenied', () {
      fakeAsync((async) {
        for (final p in <CameraPermissionResult>[
          CameraPermissionResult.permanentlyDenied,
          CameraPermissionResult.restricted,
        ]) {
          final r = Rig(async, permission: p);
          SeatAvailability? out;
          r.engine.checkAvailability().then((v) => out = v);
          async.flushMicrotasks();
          expect(out, SeatAvailability.permissionDenied);
          expect(r.gateway.requests, 0);
          expect(r.source.probeCount, 0);
        }
      });
    });
  });

  test('dispose stops the camera, closes the detector and the streams', () {
    fakeAsync((async) {
      final r = Rig(async);
      r.start();
      r.stream(const Duration(seconds: 1), present: true);
      var samplesDone = false;
      var eventsDone = false;
      r.engine.samples.listen(null, onDone: () => samplesDone = true);
      r.engine.events.listen(null, onDone: () => eventsDone = true);
      r.engine.dispose();
      async.flushMicrotasks();
      expect(r.source.isOpen, isFalse);
      expect(r.detector.closed, isTrue);
      expect(samplesDone, isTrue);
      expect(eventsDone, isTrue);
      expect(r.engine.lastStopReason, SeatEngineStopReason.disposed);
      r.start(); // after dispose: no-op
      expect(r.engine.isRunning, isFalse);
    });
  });
}
