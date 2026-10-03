// S04e: a detector mid-call is retired on any gate invalidation (stop · Lost ·
// deadline) and never reused; the unfinished-call limit counts actual calls
// and reports detector_failed once per streak; a stale start never emits or
// touches the current run; camera release results propagate.

import 'package:fake_async/fake_async.dart';
import 'package:flutter/widgets.dart' show AppLifecycleState;
import 'package:flutter_test/flutter_test.dart';
import 'package:soongong/core/contracts/seat_engine.dart';
import 'package:soongong/data/engines/engines.dart';

import '../../helpers/seat_engine_rig.dart';

Duration ms(int v) => Duration(milliseconds: v);
Duration s(int v) => Duration(seconds: v);

void main() {
  group('§1 retirement decoupled from the gate', () {
    test('(a) hung detection → stop before the deadline → start ×5: ≤ 2 unfinished calls, no new submissions, detector_failed once', () {
      fakeAsync((async) {
        final r = Rig(async, hangNewDetectors: true);
        for (var i = 0; i < 5; i++) {
          r.start();
          r.source.emit(present: true); // hangs on the current detector, if any
          r.tick(ms(500)); // well before the 2 s deadline
          r.stop();
          r.idle(ms(600)); // the stop's bounded wait for the hung call
        }
        expect(r.detectors, hasLength(2), reason: 'one per run until the limit; nothing created afterwards');
        expect(r.detectCalls, 2, reason: 'runs 3–5 submitted nothing');
        expect(r.engine.unfinishedDetections, 2);
        expect(r.detectors.every((d) => d.pendingCalls == 1), isTrue);
        expect(r.events.whereType<SeatError>().map((e) => e.message).toList(), <String>[SeatErrorCode.detectorFailed],
            reason: 'once per streak, not once per refused start');
        expect(r.events.whereType<SeatCameraLost>(), isEmpty, reason: 'never running while exhausted');
        expect(r.source.openCount, 2, reason: 'refused starts do not open the camera');
        expect(r.engine.isRunning, isFalse);
        expect(r.detectors.every((d) => d.closeCalls == 0), isTrue);
      });
    });

    test('(b) hung detection → Lost → Recovered ×5: the same bound, detector_failed once', () {
      fakeAsync((async) {
        final r = Rig(async, hangNewDetectors: true);
        r.start();
        r.source.emit(present: true); // hangs on detector #1 at t=0
        for (var i = 0; i < 5; i++) {
          r.tick(ms(1100)); // before the 2 s deadline, after the 1 s cadence
          r.source.fault(CameraFault.inUse, 'The camera was already in use'); // Lost: the busy detector is retired
          async.flushMicrotasks();
          r.tick(ms(1100));
          r.source.emit(present: true); // recovery frame → a new detector while the limit allows, then hangs
          async.flushMicrotasks();
        }
        expect(r.detectors, hasLength(2));
        expect(r.detectCalls, 2);
        expect(r.engine.unfinishedDetections, 2);
        expect(r.engine.inferenceTimeouts, 0, reason: 'retired by the loss, not by the deadline');
        expect(
          r.events.map((e) => e.runtimeType).toList(),
          <Type>[SeatCameraLost, SeatCameraRecovered, SeatCameraLost, SeatError],
          reason: 'second loss exhausts the limit; later frames neither recover nor re-report',
        );
        expect((r.events.last as SeatError).message, SeatErrorCode.detectorFailed);
        expect(r.engine.isLost, isTrue);
        expect(r.engine.isRunning, isTrue);
        expect(r.samples, isEmpty);
      });
    });

    test('a detector mid-call at stop is retired and closed by its returning call; the next run gets a fresh one', () {
      fakeAsync((async) {
        final r = Rig(async, detectorLatency: ms(300));
        r.start();
        r.source.emit(present: true);
        r.tick(ms(100));
        r.stop();
        expect(r.detector.closeCalls, 0, reason: 'still running: never closed mid-call');
        r.idle(ms(300)); // the call returns
        expect(r.detector.closeCalls, 1, reason: 'retired at the stop → closed on return');
        expect(r.engine.unfinishedDetections, 0);
        r.detectorLatency = Duration.zero;
        r.start();
        r.stream(s(1), present: true);
        expect(r.detectors, hasLength(2), reason: 'the retired detector is not reused');
        expect(r.detectors[1].calls, 1);
        expect(r.samples, hasLength(1));
      });
    });

    test('an idle detector at stop is kept and reused', () {
      fakeAsync((async) {
        final r = Rig(async);
        r.start();
        r.stream(s(2), present: true);
        r.stop();
        r.start();
        r.stream(s(1), present: true);
        expect(r.detectors, hasLength(1));
        expect(r.detector.closeCalls, 0);
      });
    });

    test('the limit counts calls, not detectors: a retired detector that returned frees its slot', () {
      fakeAsync((async) {
        final r = Rig(async, hangNewDetectors: true);
        r.start();
        r.source.emit(present: true);
        r.tick(ms(200));
        r.stop(); // #1 retired, 1 unfinished
        r.idle(ms(600));
        r.detectors.first.releaseHung();
        async.flushMicrotasks();
        expect(r.engine.unfinishedDetections, 0);
        expect(r.detectors.first.closeCalls, 1);
        for (var i = 0; i < 2; i++) {
          r.start();
          r.source.emit(present: true);
          r.tick(ms(200));
          r.stop();
          r.idle(ms(600));
        }
        expect(r.detectors, hasLength(3), reason: 'the returned call did not count against the limit');
        expect(r.engine.unfinishedDetections, 2);
        expect(r.events.whereType<SeatError>(), isEmpty, reason: 'the limit is reached but no start was refused yet');
        r.start();
        expect(r.engine.isRunning, isFalse);
        expect(r.events.whereType<SeatError>(), hasLength(1));
      });
    });
  });

  group('§2 run ownership after awaits in _start()', () {
    test('a start aborted by the lifecycle whose release outlives a stop + new start neither pauses nor detaches the new run', () {
      fakeAsync((async) {
        final r = Rig(async);
        r.source.openDelay = s(1);
        r.source.hangClose = true; // every release runs into the 2 s bound
        r.engine.start(const SeatEngineConfig()); // run A
        r.idle(ms(500));
        r.lifecycle.add(AppLifecycleState.paused); // A is still opening
        async.flushMicrotasks();
        r.idle(ms(600)); // t≈1.1: A's camera landed → A starts releasing it (hangs)
        expect(r.source.handles, hasLength(1));
        expect(r.source.handles[0].closed, isTrue);
        expect(r.events, isEmpty, reason: 'A has not reported yet: its release is pending');

        r.stop(); // cancels A while its release is pending
        r.lifecycle.add(AppLifecycleState.resumed);
        async.flushMicrotasks();
        r.source.openDelay = Duration.zero;
        r.start(); // run B
        expect(r.engine.isRunning, isTrue);
        expect(r.source.handles, hasLength(2));
        r.stream(s(2), present: true); // t≈3.1: A's bounded release expired meanwhile
        final n = r.samples.length;
        expect(n, greaterThan(0));
        expect(r.events, isEmpty, reason: 'A was stale when its release finished: no SeatPaused');
        expect(r.engine.isRunning, isTrue);

        r.lifecycle.add(AppLifecycleState.paused); // B must still be subscribed
        async.flushMicrotasks();
        expect(r.events.single, isA<SeatPaused>());
        expect((r.events.single as SeatPaused).reason, SeatPauseReason.background);
        expect(r.engine.isRunning, isFalse);
        expect(r.source.handles[1].closed, isTrue, reason: 'B released its own camera');
        r.stream(s(1), present: true);
        expect(r.samples.length, n);
      });
    });

    test('a start aborted by the lifecycle that stays current still reports its pause', () {
      fakeAsync((async) {
        final r = Rig(async);
        r.source.openDelay = s(1);
        r.source.hangClose = true;
        r.engine.start(const SeatEngineConfig());
        r.idle(ms(500));
        r.lifecycle.add(AppLifecycleState.hidden);
        async.flushMicrotasks();
        r.idle(ms(600));
        expect(r.events, isEmpty);
        r.idle(s(2)); // the bounded release expires; the run is still current
        expect(r.events.single, isA<SeatPaused>());
        expect((r.events.single as SeatPaused).reason, SeatPauseReason.backgroundDuringStart);
      });
    });
  });

  group('§3 camera release result', () {
    test('a release that fails is reported in the stop report and makes the stop unclean', () {
      fakeAsync((async) {
        final r = Rig(async);
        r.source.closeError = StateError('dispose exploded');
        r.start();
        r.stream(s(1), present: true);
        r.stop();
        final report = r.engine.lastStopReport!;
        expect(report.closeResult.outcome, CloseOutcome.failed);
        expect(report.closeResult.error, isA<StateError>());
        expect(report.cameraReleaseFailed, isTrue);
        expect(report.cameraReleaseTimedOut, isFalse);
        expect(report.clean, isFalse);
        expect(r.engine.isRunning, isFalse);
        r.source.closeError = null;
        r.start();
        expect(r.engine.isRunning, isTrue, reason: 'a failed release does not block the next run');
      });
    });

    test('a timeout reported by the source itself propagates as timeout', () {
      fakeAsync((async) {
        final r = Rig(async);
        r.source.closeResult = const CloseResult.timeout(Duration(seconds: 2));
        r.start();
        r.stream(s(1), present: true);
        r.stop();
        final report = r.engine.lastStopReport!;
        expect(report.closeResult.outcome, CloseOutcome.timeout);
        expect(report.cameraReleaseTimedOut, isTrue);
        expect(report.clean, isFalse);
      });
    });

    test('a release that never completes is timeout after the engine bound; a clean release is ok', () {
      fakeAsync((async) {
        final r = Rig(async);
        r.source.hangClose = true;
        r.start();
        r.stream(s(1), present: true);
        var stopped = false;
        r.engine.stop().then((_) => stopped = true);
        r.idle(ms(2100));
        expect(stopped, isTrue);
        expect(r.engine.lastStopReport!.closeResult.outcome, CloseOutcome.timeout);
        expect(r.engine.lastStopReport!.closeResult.waited, s(2));

        r.source.hangClose = false;
        r.start();
        r.stream(s(1), present: true);
        r.stop();
        expect(r.engine.lastStopReport!.closeResult.isOk, isTrue);
        expect(r.engine.lastStopReport!.clean, isTrue);
      });
    });
  });
}
