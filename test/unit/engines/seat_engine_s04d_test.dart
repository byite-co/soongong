// S04d: per-run camera ownership (late opens release only their own camera),
// stop() during the open returns at once, detector retire/replace with the
// stalled-call limit, and the sinceStart reference = the start() call.

import 'package:fake_async/fake_async.dart';
import 'package:flutter/widgets.dart' show AppLifecycleState;
import 'package:flutter_test/flutter_test.dart';
import 'package:soongong/core/contracts/seat_engine.dart';
import 'package:soongong/data/engines/engines.dart';

import '../../helpers/seat_engine_rig.dart';

Duration ms(int v) => Duration(milliseconds: v);
Duration s(int v) => Duration(seconds: v);

void main() {
  group('§1 open ownership', () {
    test('a first open that lands after its start timed out closes only its own camera; the second run keeps streaming', () {
      fakeAsync((async) {
        final r = Rig(async);
        r.source.openDelay = s(10);
        r.engine.start(const SeatEngineConfig()); // run 1, never opens in time
        r.idle(ms(8100));
        expect((r.events.single as SeatError).message, SeatErrorCode.cameraInitTimeout);
        expect(r.source.handles, isEmpty, reason: 'the first open is still pending');

        r.source.openDelay = Duration.zero;
        r.start(); // run 2 opens at once
        expect(r.engine.isRunning, isTrue);
        expect(r.source.handles, hasLength(1));
        final second = r.source.handles[0];
        r.stream(s(1), present: true);
        final n = r.samples.length;
        expect(n, greaterThan(0));

        r.idle(s(2)); // t≈10.1: the first open lands
        expect(r.source.handles, hasLength(2));
        final first = r.source.handles[1];
        expect(first.closed, isTrue, reason: 'released through its own handle');
        expect(first.closeCalls, 1);
        expect(second.isOpen, isTrue, reason: 'the current run\'s camera is untouched');
        expect(second.closeCalls, 0);
        expect(r.source.closeCount, 1);
        expect(r.engine.isRunning, isTrue);

        first.emit(present: true); // a frame from the abandoned session
        async.flushMicrotasks();
        expect(r.samples.length, n, reason: 'carries a cancelled generation');
        r.stream(s(1), present: true);
        expect(r.samples.length, greaterThan(n), reason: 'run 2 streams on');
        expect(r.events, hasLength(1), reason: 'nothing new was reported');
      });
    });

    test('stop() during the open returns at once; the open lands later, releases its own camera and leaves the next run alone', () {
      fakeAsync((async) {
        final r = Rig(async);
        r.source.openDelay = s(3);
        var firstStarted = false;
        r.engine.start(const SeatEngineConfig()).then((_) => firstStarted = true);
        r.idle(ms(500));
        var stopped = false;
        r.engine.stop().then((_) => stopped = true);
        async.flushMicrotasks();
        expect(stopped, isTrue, reason: 'bounded by nothing: the run token is cancelled');
        expect(r.engine.isRunning, isFalse);
        expect(r.engine.lastStopReason, SeatEngineStopReason.caller);

        r.source.openDelay = Duration.zero;
        r.start(); // a new run while the first open is still pending
        expect(r.engine.isRunning, isTrue);
        expect(r.source.handles, hasLength(1));
        final second = r.source.handles[0];
        r.stream(s(1), present: true);
        final n = r.samples.length;

        r.idle(ms(1600)); // t≈3.1: the cancelled run's open lands
        expect(firstStarted, isTrue, reason: 'the first start() completes when its open lands');
        expect(r.source.handles, hasLength(2));
        expect(r.source.handles[1].closed, isTrue);
        expect(second.isOpen, isTrue);
        expect(r.source.closeCount, 1);
        expect(r.engine.isRunning, isTrue);
        r.stream(s(1), present: true);
        expect(r.samples.length, greaterThan(n));
        expect(r.events, isEmpty, reason: 'a cancelled start reports nothing');
      });
    });

    test('dispose() during the open: the late camera is released, nothing is emitted', () {
      fakeAsync((async) {
        final r = Rig(async);
        r.source.openDelay = s(2);
        r.engine.start(const SeatEngineConfig());
        r.idle(ms(200));
        var disposed = false;
        r.engine.dispose().then((_) => disposed = true);
        async.flushMicrotasks();
        expect(disposed, isTrue);
        expect(r.detector.closed, isTrue, reason: 'idle detector closed at once');
        r.idle(s(2));
        expect(r.source.openCount, 1);
        expect(r.source.closeCount, 1);
        expect(r.events, isEmpty);
        expect(r.samples, isEmpty);
      });
    });
  });

  group('§2 unresponsive detector', () {
    test('a permanently hung detector with 60 s of frames: at most 2 unfinished calls, no new submissions, Lost', () {
      fakeAsync((async) {
        final r = Rig(async, hangNewDetectors: true);
        r.start();
        r.stream(s(60), present: true);
        expect(r.detectors, hasLength(2), reason: 'one replacement, then the limit');
        expect(r.detectCalls, 2, reason: 'unfinished calls ≤ 2 and nothing more submitted');
        expect(r.detectors.every((d) => d.pendingCalls == 1), isTrue);
        expect(r.engine.unfinishedDetections, 2);
        expect(r.engine.detectorReplacements, 1);
        expect(r.engine.inferenceTimeouts, 2);
        expect(r.engine.detectorAvailable, isFalse);
        expect(r.events.map((e) => e.runtimeType).toList(), <Type>[SeatError, SeatCameraLost]);
        expect((r.events.first as SeatError).message, SeatErrorCode.detectorFailed);
        expect(r.engine.isLost, isTrue);
        expect(r.engine.lastLostReason, SeatLostReason.detectorExhausted);
        expect(r.engine.isRunning, isTrue, reason: 'the camera is fine; only the detector is gone');
        expect(r.samples, isEmpty);
        expect(r.engine.framesDelivered, greaterThan(800), reason: 'frames kept arriving and were ignored');
        expect(r.detectors.every((d) => d.closeCalls == 0), isTrue, reason: 'never closed during a call');
      });
    });

    test('recovery only through a new detector: a hung call returning frees a slot, the next frame gets a fresh detector', () {
      fakeAsync((async) {
        final r = Rig(async, hangNewDetectors: true);
        r.start();
        r.stream(s(10), present: true);
        expect(r.engine.unfinishedDetections, 2);
        expect(r.events, hasLength(2));

        r.hangNewDetectors = false;
        r.detectors.first.releaseHung(); // detector #1 finally answers
        async.flushMicrotasks();
        expect(r.detectors.first.closeCalls, 1, reason: 'retired and idle → closed by its returning call');
        expect(r.engine.unfinishedDetections, 1);
        expect(r.samples, isEmpty, reason: 'its answer was discarded (expired ticket)');
        expect(r.engine.suppressedResults, 1);

        r.stream(s(2), present: true);
        expect(r.detectors, hasLength(3));
        expect(r.events.last, isA<SeatCameraRecovered>());
        expect(r.engine.isLost, isFalse);
        expect(r.samples, isNotEmpty);
        expect(r.samples.every((x) => x.seated), isTrue);
        expect(r.detectors[1].closeCalls, 0, reason: 'still hanging: never closed');
      });
    });

    test('start() while the limit is reached → SeatError(detector_failed), not running; works again once a call returns', () {
      fakeAsync((async) {
        final r = Rig(async, hangNewDetectors: true);
        r.start();
        r.stream(s(10), present: true);
        r.stop();
        expect(r.engine.isRunning, isFalse);
        r.idle(ms(600)); // the stop waits ≤ 500 ms for the latest (hung) detection
        expect(r.engine.lastStopReport!.unfinishedDetections, 2);
        expect(r.engine.lastStopReport!.inferenceTimedOut, isTrue);
        final before = r.events.length;
        r.hangNewDetectors = false;
        r.start();
        expect(r.engine.isRunning, isFalse);
        expect(r.events.length, before,
            reason: 'S04e: detector_failed was already reported for this streak — a refused start stays silent');
        expect(r.source.openCount, 1, reason: 'the camera is not opened without a detector');

        r.detectors[1].releaseHung();
        async.flushMicrotasks();
        r.start();
        expect(r.engine.isRunning, isTrue);
        expect(r.detectors, hasLength(3));
        r.stream(s(1), present: true);
        expect(r.events.last, isA<SeatCameraRecovered>());
        expect(r.samples, isNotEmpty);
      });
    });

    test('a single stall is transparent: replaced, no event; the retired detector closes when it returns', () {
      fakeAsync((async) {
        final r = Rig(async);
        r.detector.hang = true;
        r.start();
        r.source.emit(present: true);
        r.idle(ms(2100));
        expect(r.detectors, hasLength(2));
        r.stream(s(3), present: true);
        expect(r.samples, hasLength(3));
        expect(r.events, isEmpty);
        r.detector.releaseHung();
        async.flushMicrotasks();
        expect(r.detector.closeCalls, 1);
        expect(r.detectors[1].closeCalls, 0);
        expect(r.engine.unfinishedDetections, 0);
        r.stop();
        expect(r.engine.lastStopReport!.clean, isTrue);
      });
    });
  });

  group('§3 sinceStart reference = the start() call', () {
    test('a 5 s camera open: the first sample\'s sinceStart is ≥ 5 s and receivedAt = callInstant + sinceStart', () {
      fakeAsync((async) {
        final r = Rig(async);
        r.source.openDelay = s(5);
        final callWall = r.wall.now();
        r.engine.start(const SeatEngineConfig());
        r.idle(ms(5000));
        async.flushMicrotasks();
        expect(r.engine.isRunning, isTrue);
        r.stream(s(1), present: true);
        expect(r.samples.first.sinceStart, greaterThanOrEqualTo(s(5)));
        expect(r.samples.first.receivedAt, callWall.add(r.samples.first.sinceStart));
        expect(r.events, isEmpty, reason: 'a 5 s open does not trip the frame watchdog');
      });
    });

    test('after a 3 s pause the first sample of the next run lands after the gap (placed with the new call instant)', () {
      fakeAsync((async) {
        final r = Rig(async);
        final runStart1 = r.wall.now();
        r.start();
        r.stream(s(2), present: true);
        final lastBeforePause = runStart1.add(r.samples.last.sinceStart);
        r.lifecycle.add(AppLifecycleState.paused);
        async.flushMicrotasks();
        final pausedAt = r.wall.now();
        expect(r.events.single, isA<SeatPaused>());
        r.idle(s(3));
        r.lifecycle.add(AppLifecycleState.resumed);
        async.flushMicrotasks();

        r.source.openDelay = s(1);
        final runStart2 = r.wall.now(); // S06: one wall instant right before start()
        r.engine.start(const SeatEngineConfig());
        r.idle(ms(1000));
        async.flushMicrotasks();
        final n = r.samples.length;
        r.stream(s(1), present: true);
        final first = r.samples[n];
        expect(first.sinceStart, greaterThanOrEqualTo(s(1)), reason: 'counts from the call, through the open');
        final placed = runStart2.add(first.sinceStart);
        expect(placed.isAfter(pausedAt.add(s(3))), isTrue, reason: 'after the pause gap');
        expect(placed.isAfter(lastBeforePause), isTrue);
        expect(first.receivedAt, placed);
      });
    });
  });

  group('§6a stop bound during init', () {
    test('an open that never completes: stop() returns at once, start()\'s future ends at the 8 s bound without an event, a new start works', () {
      fakeAsync((async) {
        final r = Rig(async);
        r.source.hangOpen = true;
        var started = false;
        r.engine.start(const SeatEngineConfig()).then((_) => started = true);
        r.idle(ms(300));
        var stopped = false;
        r.engine.stop().then((_) => stopped = true);
        async.flushMicrotasks();
        expect(stopped, isTrue);
        expect(started, isFalse);

        r.source.hangOpen = false;
        r.start();
        expect(r.engine.isRunning, isTrue);
        r.stream(s(9), present: true); // run 2 streams past the cancelled run's 8 s bound
        expect(r.samples.length, greaterThanOrEqualTo(8));
        expect(started, isTrue, reason: 'the cancelled start() ended at its bound');
        expect(r.events, isEmpty, reason: 'no camera_init_timeout for a cancelled run');
        expect(r.engine.isRunning, isTrue);
      });
    });
  });
}
