// S04c: Lost invalidation, lifecycle during start, unresponsiveness bounds
// (camera open · inference · stop) and the sinceStart contract.

import 'package:fake_async/fake_async.dart';
import 'package:flutter/widgets.dart' show AppLifecycleState;
import 'package:flutter_test/flutter_test.dart';
import 'package:soongong/core/contracts/seat_engine.dart';
import 'package:soongong/data/engines/engines.dart';
import 'package:soongong/features/measure/domain/away_policy.dart';

import '../../helpers/seat_engine_rig.dart';

Duration ms(int v) => Duration(milliseconds: v);
Duration s(int v) => Duration(seconds: v);

void main() {
  group('§1 lost invalidation', () {
    test('a detection in flight when the camera is lost never publishes', () {
      fakeAsync((async) {
        final r = Rig(async, detectorLatency: s(1));
        r.start();
        r.source.emit(present: true); // t=0, returns at t=1
        r.tick(ms(500));
        r.source.fault(CameraFault.inUse, 'The camera was already in use');
        async.flushMicrotasks();
        expect(r.events.single, isA<SeatCameraLost>());
        expect(r.engine.inferenceInFlight, isTrue, reason: 'physically still running');
        r.idle(ms(700)); // the detection returns at t=1
        expect(r.samples, isEmpty);
        expect(r.diagnostics, isEmpty);
        expect(r.engine.suppressedResults, 1);
        expect(r.engine.inferenceInFlight, isFalse);
        expect(r.engine.isRunning, isTrue, reason: 'lost is not stop');
      });
    });

    test('lost → recovered: the old detection is dropped, only frames after the recovery publish', () {
      fakeAsync((async) {
        final r = Rig(async, detectorLatency: s(2));
        r.start();
        r.source.emit(present: true); // t=0, would return at t=2 (seated)
        r.tick(ms(500));
        r.source.fault(CameraFault.inUse, 'in use');
        async.flushMicrotasks();
        r.tick(ms(600)); // t=1.1: the cadence slot was freed by the loss
        r.source.emit(present: false); // recovery frame → new detection, returns at t=3.1
        async.flushMicrotasks();
        expect(r.events.map((e) => e.runtimeType).toList(), <Type>[SeatCameraLost, SeatCameraRecovered]);
        r.idle(ms(1000)); // t=2.1: the old detection returned
        expect(r.samples, isEmpty, reason: 'the pre-loss decision is discarded');
        r.idle(ms(1100)); // t=3.2: the new detection returned
        expect(r.samples, hasLength(1));
        expect(r.samples.single.seated, isFalse);
        expect(r.diagnostics.single.generation, r.engine.generation);
        expect(r.engine.suppressedResults, 1);
      });
    });
  });

  group('§2 lifecycle during start', () {
    test('start while the app is already in the background opens nothing and reports a pause', () {
      fakeAsync((async) {
        final r = Rig(async);
        r.lifecycle.current = AppLifecycleState.paused;
        r.start();
        expect(r.engine.isRunning, isFalse);
        expect(r.source.openCount, 0);
        expect(r.events.single, isA<SeatPaused>());
        expect((r.events.single as SeatPaused).reason, SeatPauseReason.backgroundDuringStart);
        expect(r.engine.isLost, isTrue);

        r.lifecycle.add(AppLifecycleState.resumed);
        async.flushMicrotasks();
        r.start();
        expect(r.engine.isRunning, isTrue);
        r.stream(s(1), present: true);
        expect(r.events.last, isA<SeatCameraRecovered>());
        expect(r.samples, hasLength(1));
      });
    });

    test('background while the camera is opening: released on arrival, paused, no samples', () {
      fakeAsync((async) {
        final r = Rig(async);
        r.source.openDelay = s(1);
        var started = false;
        r.engine.start(const SeatEngineConfig()).then((_) => started = true);
        r.idle(ms(500));
        r.lifecycle.add(AppLifecycleState.hidden);
        async.flushMicrotasks();
        expect(started, isFalse);
        r.idle(ms(600)); // the camera finishes opening at t=1
        expect(started, isTrue);
        expect(r.source.openCount, 1);
        expect(r.source.closeCount, 1, reason: 'released again right after it opened');
        expect(r.source.isOpen, isFalse);
        expect(r.engine.isRunning, isFalse);
        expect(r.events.single, isA<SeatPaused>());
        expect((r.events.single as SeatPaused).reason, SeatPauseReason.backgroundDuringStart);
        expect(r.engine.lastStopReport, isNull, reason: 'the run never began');
        r.source.emitLate(present: true);
        async.flushMicrotasks();
        expect(r.samples, isEmpty);

        r.lifecycle.add(AppLifecycleState.resumed);
        async.flushMicrotasks();
        r.source.openDelay = Duration.zero;
        r.start();
        expect(r.engine.isRunning, isTrue);
        r.stream(s(1), present: true);
        expect(r.samples, hasLength(1));
        expect(r.events.last, isA<SeatCameraRecovered>());
      });
    });

    test('stop() while the camera is opening returns at once (S04d §6a); the open releases itself when it lands', () {
      fakeAsync((async) {
        final r = Rig(async);
        r.source.openDelay = s(1);
        var started = false;
        r.engine.start(const SeatEngineConfig()).then((_) => started = true);
        r.idle(ms(300));
        var stopped = false;
        r.engine.stop().then((_) => stopped = true);
        async.flushMicrotasks();
        expect(stopped, isTrue, reason: 'no wait for the open');
        expect(started, isFalse);
        expect(r.source.openCount, 0);
        r.idle(ms(800)); // the open lands at t=1
        expect(started, isTrue);
        expect(r.source.openCount, 1);
        expect(r.source.closeCount, 1, reason: 'the cancelled run released its own camera');
        expect(r.engine.isRunning, isFalse);
        expect(r.events, isEmpty);
      });
    });
  });

  group('§3a camera open bound', () {
    test('checkAvailability: a probe that hangs answers unavailable(timeout) after 8 s', () {
      fakeAsync((async) {
        final r = Rig(async);
        r.source.hangProbe = true;
        SeatAvailability? out;
        r.engine.checkAvailability().then((v) => out = v);
        r.idle(ms(7900));
        expect(out, isNull);
        r.idle(ms(200));
        expect(out, SeatAvailability.unavailable);
        expect(r.engine.lastAvailabilityReason, SeatEngineImpl.availabilityReasonTimeout);
      });
    });

    test('start: an open that hangs → SeatError(camera_init_timeout) after 8 s, not running', () {
      fakeAsync((async) {
        final r = Rig(async);
        r.source.hangOpen = true;
        var started = false;
        r.engine.start(const SeatEngineConfig()).then((_) => started = true);
        r.idle(ms(7900));
        expect(started, isFalse);
        r.idle(ms(200));
        expect(started, isTrue);
        expect(r.engine.isRunning, isFalse);
        expect((r.events.single as SeatError).message, SeatErrorCode.cameraInitTimeout);
      });
    });

    test('an open that completes after the bound is released in the background; a new start works', () {
      fakeAsync((async) {
        final r = Rig(async);
        r.source.openDelay = s(10);
        r.engine.start(const SeatEngineConfig());
        r.idle(ms(8100));
        expect((r.events.single as SeatError).message, SeatErrorCode.cameraInitTimeout);
        expect(r.source.openCount, 0);
        r.idle(s(2)); // the late open lands at t=10
        expect(r.source.openCount, 1);
        expect(r.source.closeCount, 1, reason: 'released as soon as it arrived');
        expect(r.source.isOpen, isFalse);
        r.source.emitLate(present: true);
        async.flushMicrotasks();
        expect(r.samples, isEmpty);
        expect(r.engine.isRunning, isFalse);

        r.source.openDelay = Duration.zero;
        r.start();
        expect(r.engine.isRunning, isTrue);
        expect(r.source.openCount, 2);
        r.stream(s(1), present: true);
        expect(r.samples, hasLength(1));
      });
    });
  });

  group('§3b inference deadline', () {
    test('a detector that never returns: the watchdog gives up after 2 s, retires it and the next frame runs on a new one', () {
      fakeAsync((async) {
        final r = Rig(async);
        r.detector.hang = true;
        r.start();
        r.source.emit(present: true); // hangs
        r.idle(ms(2100)); // watchdog at 1 s (too early) and 2 s (expired)
        expect(r.engine.inferenceTimeouts, 1);
        expect(r.engine.inferenceInFlight, isTrue, reason: 'physically still hanging');
        expect(r.engine.unfinishedDetections, 1);
        expect(r.engine.detectorReplacements, 1, reason: 'S04d: replaced at once');
        expect(r.detectors, hasLength(2));
        expect(r.samples, isEmpty);
        expect(r.events, isEmpty, reason: 'one stall is below the limit');

        r.source.emit(present: true); // goes to the new detector
        async.flushMicrotasks();
        expect(r.samples, hasLength(1));
        expect(r.engine.framesProcessed, 2);
        expect(r.detectors[1].calls, 1);
        expect(r.detector.calls, 1, reason: 'nothing more is submitted to the retired one');
      });
    });

    test('stalled detections up to the limit (2) → SeatError(detector_failed) + Lost; dispose never closes a running detector', () {
      fakeAsync((async) {
        final r = Rig(async, hangNewDetectors: true);
        r.start();
        for (var i = 0; i < 3; i++) {
          r.source.emit(present: true);
          async.flushMicrotasks();
          r.idle(s(3)); // deadline 2 s + watchdog granularity 1 s
        }
        expect(r.engine.inferenceTimeouts, 2, reason: 'the third frame was never submitted');
        expect(r.detectCalls, 2);
        expect(r.events.map((e) => e.runtimeType).toList(), <Type>[SeatError, SeatCameraLost]);
        expect((r.events.first as SeatError).message, SeatErrorCode.detectorFailed);
        var disposed = false;
        r.engine.dispose().then((_) => disposed = true);
        r.idle(s(3));
        expect(disposed, isTrue, reason: 'dispose is bounded');
        expect(r.engine.lastStopReport!.inferenceTimedOut, isTrue);
        expect(r.engine.lastStopReport!.unfinishedDetections, 2);
        expect(r.detectors.every((d) => d.closeCalls == 0), isTrue,
            reason: 'never closed during an inference, even a stuck one');
      });
    });
  });

  group('§3c stop bound', () {
    test('a camera release that hangs: stop returns after the 2 s bound; a restart is allowed', () {
      fakeAsync((async) {
        final r = Rig(async);
        r.source.hangClose = true;
        r.start();
        r.stream(s(1), present: true);
        var stopped = false;
        r.engine.stop().then((_) => stopped = true);
        r.idle(ms(1900));
        expect(stopped, isFalse);
        r.idle(ms(200));
        expect(stopped, isTrue);
        final report = r.engine.lastStopReport!;
        expect(report.cameraReleaseTimedOut, isTrue);
        expect(report.cameraReleaseWait, s(2));
        expect(report.clean, isFalse);
        expect(r.engine.isRunning, isFalse);

        r.start();
        expect(r.engine.isRunning, isTrue, reason: 'the previous release still pending does not block a new generation');
        expect(r.source.openCount, 2);
        final n = r.samples.length;
        r.stream(s(1), present: true);
        expect(r.samples.length, greaterThan(n));
      });
    });

    test('worst case: hanging release + hanging detection → stop returns within 2.5 s', () {
      fakeAsync((async) {
        final r = Rig(async);
        r.source.hangClose = true;
        r.detector.hang = true;
        r.start();
        r.source.emit(present: true);
        r.tick(ms(100));
        var stopped = false;
        r.engine.stop().then((_) => stopped = true);
        r.idle(ms(2400));
        expect(stopped, isFalse);
        r.idle(ms(200));
        expect(stopped, isTrue);
        final report = r.engine.lastStopReport!;
        expect(report.cameraReleaseTimedOut, isTrue);
        expect(report.hadInFlight, isTrue);
        expect(report.inferenceTimedOut, isTrue);
        expect(report.inferenceWait, ms(500));
        expect(r.samples, isEmpty);
      });
    });

    test('a clean stop reports both waits as not timed out', () {
      fakeAsync((async) {
        final r = Rig(async);
        r.start();
        r.stream(s(1), present: true);
        r.stop();
        final report = r.engine.lastStopReport!;
        expect(report.cameraReleaseTimedOut, isFalse);
        expect(report.inferenceTimedOut, isFalse);
        expect(report.clean, isTrue);
      });
    });
  });

  group('§4 sinceStart contract', () {
    test('sinceStart counts from start() on the monotonic clock; receivedAt is the wall clock', () {
      fakeAsync((async) {
        final r = Rig(async);
        r.tick(s(5)); // the engine existed for a while before the run
        final t0 = r.wall.now();
        r.start();
        r.stream(s(3), present: true);
        expect(r.samples, hasLength(3));
        expect(r.samples.first.sinceStart, Duration.zero);
        for (var i = 0; i < r.samples.length; i++) {
          expect(r.samples[i].sinceStart, r.diagnostics[i].sinceStart);
          expect(r.samples[i].receivedAt, t0.add(r.samples[i].sinceStart));
        }
        expect(r.samples[1].sinceStart - r.samples[0].sinceStart, ms(1056));
      });
    });

    test('a device clock change moves receivedAt only: sinceStart stays monotonic with 1 s steps', () {
      fakeAsync((async) {
        final r = Rig(async);
        r.start();
        r.stream(s(2), present: true);
        r.wall.jumpTo(r.wall.now().add(const Duration(hours: 1)));
        r.stream(s(2), present: true);
        r.wall.jumpTo(r.wall.now().subtract(const Duration(hours: 2)));
        r.stream(s(2), present: true);
        expect(r.samples, hasLength(6));
        for (var i = 1; i < r.samples.length; i++) {
          final step = r.samples[i].sinceStart - r.samples[i - 1].sinceStart;
          expect(step, ms(1056), reason: 'monotonic cadence at index $i');
        }
        final wallSteps = <Duration>[
          for (var i = 1; i < r.samples.length; i++)
            r.samples[i].receivedAt.difference(r.samples[i - 1].receivedAt),
        ];
        expect(wallSteps[1], const Duration(hours: 1) + ms(1056), reason: 'the forward jump');
        expect(wallSteps[3], ms(1056) - const Duration(hours: 2), reason: 'the backward jump');
      });
    });

    test('AwayPolicy placed with sessionStart + sinceStart keeps the 60 s threshold across a clock jump', () {
      fakeAsync((async) {
        final r = Rig(async);
        final sessionStart = r.wall.now();
        r.start();
        r.stream(s(5), present: true);
        r.stream(s(30), present: false);
        r.wall.jumpTo(r.wall.now().add(const Duration(hours: 1)));
        r.stream(s(40), present: false);

        // S06's placement: one reference instant + the monotonic offset.
        final policy = AwayPolicy(sensitivityLevel: 0, lastSeatedAt: sessionStart);
        AwayConfirmed? confirmed;
        for (final sample in r.samples) {
          for (final e in policy.observe(at: sessionStart.add(sample.sinceStart), seated: sample.seated)) {
            if (e is AwayConfirmed) confirmed ??= e;
          }
        }
        expect(confirmed, isNotNull);
        final awayAfter = confirmed!.confirmedAt.difference(sessionStart);
        // hold window: seated until ~3 s after the last detection at ~4.2 s;
        // the candidate opens at ~8.4 s and confirms 60 s later.
        expect(awayAfter, greaterThanOrEqualTo(s(65)));
        expect(awayAfter, lessThan(s(72)));

        // Placing by receivedAt instead would confirm at the clock jump.
        final naive = AwayPolicy(sensitivityLevel: 0, lastSeatedAt: sessionStart);
        AwayConfirmed? naiveConfirmed;
        for (final sample in r.samples) {
          for (final e in naive.observe(at: sample.receivedAt, seated: sample.seated)) {
            if (e is AwayConfirmed) naiveConfirmed ??= e;
          }
        }
        expect(
          naiveConfirmed!.confirmedAt.difference(sessionStart),
          greaterThan(const Duration(hours: 1)),
          reason: 'wall-clock placement is distorted by the jump',
        );
      });
    });

    test('restart resets sinceStart to zero', () {
      fakeAsync((async) {
        final r = Rig(async);
        r.start();
        r.stream(s(3), present: true);
        r.stop();
        r.start();
        r.stream(s(1), present: true);
        expect(r.samples.last.sinceStart, Duration.zero);
      });
    });
  });

  group('background → SeatPaused', () {
    test('background while running → SeatPaused(background), never a Lost; the next run recovers', () {
      fakeAsync((async) {
        final r = Rig(async);
        r.start();
        r.stream(s(2), present: true);
        r.lifecycle.add(AppLifecycleState.paused);
        async.flushMicrotasks();
        expect(r.events.single, isA<SeatPaused>());
        expect((r.events.single as SeatPaused).reason, SeatPauseReason.background);
        expect(r.events.whereType<SeatCameraLost>(), isEmpty);
        expect(r.engine.isRunning, isFalse);
        expect(r.engine.isLost, isTrue);
        r.lifecycle.add(AppLifecycleState.resumed);
        async.flushMicrotasks();
        r.start();
        r.stream(s(1), present: true);
        expect(r.events.last, isA<SeatCameraRecovered>());
      });
    });
  });
}
