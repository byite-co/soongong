// S04b: generation gate (restart race), stop sequence (bounded wait, no
// close during inference) and capture-time samples.

import 'package:fake_async/fake_async.dart';
import 'package:flutter/widgets.dart' show AppLifecycleState;
import 'package:flutter_test/flutter_test.dart';
import 'package:soongong/core/contracts/seat_engine.dart';
import 'package:soongong/data/engines/engines.dart';

import '../../helpers/seat_engine_rig.dart';

void main() {
  group('generation', () {
    test('a detection that outlives stop → start is discarded, never applied to the new run', () {
      fakeAsync((async) {
        final r = Rig(async, detectorLatency: const Duration(seconds: 2));
        r.start();
        final oldGen = r.engine.generation;
        r.source.emit(present: true); // accepted at t=0, returns at t=2 s
        r.tick(const Duration(milliseconds: 100));
        expect(r.engine.inferenceInFlight, isTrue);

        var stopped = false;
        r.engine.stop().then((_) => stopped = true);
        async.flushMicrotasks();
        expect(r.engine.isRunning, isFalse, reason: 'fence is immediate');
        expect(r.source.isOpen, isFalse, reason: 'camera released before the wait');
        expect(stopped, isFalse, reason: 'waiting for the in-flight detection');
        r.idle(const Duration(milliseconds: 600));
        expect(stopped, isTrue, reason: 'the wait is bounded to 500 ms');
        final report = r.engine.lastStopReport!;
        expect(report.hadInFlight, isTrue);
        expect(report.inferenceTimedOut, isTrue);
        expect(report.clean, isFalse);
        expect(report.inferenceWait, const Duration(milliseconds: 500));
        expect(report.generation, oldGen);
        expect(r.samples, isEmpty);

        // New run with an instant detector and a different answer.
        r.detector.latency = Duration.zero;
        r.start();
        final newGen = r.engine.generation;
        expect(newGen, greaterThan(oldGen));
        r.stream(const Duration(seconds: 3), present: false);
        // The old detection (present: true) returned at ~t=2 s, inside the new run.
        expect(r.samples, isNotEmpty);
        expect(r.samples.every((s) => !s.seated), isTrue, reason: 'no leaked seated sample');
        expect(r.diagnostics.every((d) => d.generation == newGen), isTrue);
        expect(r.engine.suppressedResults, 1);
        expect(r.events, isEmpty);
      });
    });

    test('a detection that returns within the stop bound is still behind the fence: discarded', () {
      fakeAsync((async) {
        final r = Rig(async, detectorLatency: const Duration(milliseconds: 300));
        r.start();
        r.source.emit(present: true);
        r.tick(const Duration(milliseconds: 100));
        var stopped = false;
        r.engine.stop().then((_) => stopped = true);
        async.flushMicrotasks(); // fence + camera release happen now, the wait starts at t=100 ms
        r.idle(const Duration(milliseconds: 250));
        expect(stopped, isTrue);
        final report = r.engine.lastStopReport!;
        expect(report.hadInFlight, isTrue);
        expect(report.inferenceTimedOut, isFalse);
        expect(report.clean, isTrue);
        expect(report.inferenceWait, const Duration(milliseconds: 200));
        expect(r.samples, isEmpty);
        expect(r.diagnostics, isEmpty);
        expect(r.engine.suppressedResults, 1);
        expect(r.engine.inferenceInFlight, isFalse);
      });
    });

    test('a clean stop without a detection in flight reports no wait', () {
      fakeAsync((async) {
        final r = Rig(async);
        r.start();
        r.stream(const Duration(seconds: 2), present: true);
        r.stop();
        final report = r.engine.lastStopReport!;
        expect(report.reason, SeatEngineStopReason.caller);
        expect(report.hadInFlight, isFalse);
        expect(report.inferenceWait, Duration.zero);
        expect(report.clean, isTrue);
        expect(report.suppressedResults, 0);
      });
    });

    test('late frame / fault callbacks of the previous camera session are ignored after a restart', () {
      fakeAsync((async) {
        final r = Rig(async);
        r.start();
        r.stream(const Duration(seconds: 1), present: true);
        r.stop();
        r.start();
        expect(r.engine.framesDelivered, 0);
        r.source.emitLate(present: true);
        r.source.faultLate(CameraFault.inUse, 'The camera was already in use');
        async.flushMicrotasks();
        expect(r.engine.framesDelivered, 0, reason: 'the old session\'s frame is not counted');
        expect(r.events, isEmpty, reason: 'the old session\'s fault emits nothing');
        expect(r.engine.lastFault, isNull);
        final n = r.samples.length;
        r.stream(const Duration(seconds: 1), present: true);
        expect(r.samples.length, greaterThan(n));
      });
    });

    test('every start bumps the generation; stop bumps it too', () {
      fakeAsync((async) {
        final r = Rig(async);
        final g0 = r.engine.generation;
        r.start();
        final g1 = r.engine.generation;
        expect(g1, g0 + 1);
        r.stop();
        expect(r.engine.generation, g1 + 1);
        r.start();
        expect(r.engine.generation, g1 + 2);
      });
    });
  });

  group('stop sequence', () {
    test('stop during inference: no sample, no exception, detector kept open for reuse', () {
      fakeAsync((async) {
        final r = Rig(async, detectorLatency: const Duration(milliseconds: 300));
        r.start();
        r.source.emit(present: true);
        r.tick(const Duration(milliseconds: 100));
        r.engine.stop();
        r.idle(const Duration(seconds: 1));
        expect(r.samples, isEmpty);
        expect(r.detector.closeCalls, 0, reason: 'stop() does not close the detector');
        expect(r.detector.closed, isFalse);
        // Reuse after the stop works.
        r.detector.latency = Duration.zero;
        r.start();
        r.stream(const Duration(seconds: 1), present: true);
        expect(r.samples, hasLength(1));
      });
    });

    test('dispose during inference that returns within the bound: close once, after the detection', () {
      fakeAsync((async) {
        final r = Rig(async, detectorLatency: const Duration(milliseconds: 300));
        r.start();
        r.source.emit(present: true);
        r.tick(const Duration(milliseconds: 100));
        var disposed = false;
        r.engine.dispose().then((_) => disposed = true);
        async.flushMicrotasks();
        expect(r.detector.closeCalls, 0, reason: 'never closed while running');
        r.idle(const Duration(milliseconds: 250));
        expect(disposed, isTrue);
        expect(r.detector.closeCalls, 1);
        expect(r.samples, isEmpty);
        expect(r.engine.suppressedResults, 1);
      });
    });

    test('dispose during a long inference: returns after the bound, closes once when the detection returns', () {
      fakeAsync((async) {
        final r = Rig(async, detectorLatency: const Duration(seconds: 2));
        r.start();
        r.source.emit(present: true);
        r.tick(const Duration(milliseconds: 100));
        var disposed = false;
        r.engine.dispose().then((_) => disposed = true);
        r.idle(const Duration(milliseconds: 600));
        expect(disposed, isTrue, reason: 'dispose does not block on the detection');
        expect(r.engine.lastStopReport!.inferenceTimedOut, isTrue);
        expect(r.detector.closeCalls, 0, reason: 'still running: not closed');
        expect(r.engine.inferenceInFlight, isTrue);
        r.idle(const Duration(milliseconds: 1500));
        expect(r.detector.closeCalls, 1, reason: 'closed by the returning detection');
        expect(r.engine.inferenceInFlight, isFalse);
        expect(r.samples, isEmpty);
        expect(r.engine.suppressedResults, 1);
        r.start();
        expect(r.engine.isRunning, isFalse, reason: 'disposed engines do not restart');
      });
    });

    test('a detector that throws while stop waits: no sample, no event, stop completes', () {
      fakeAsync((async) {
        final r = Rig(async, detectorLatency: const Duration(milliseconds: 300));
        r.start();
        r.detector.error = StateError('boom');
        r.source.emit(present: true);
        r.tick(const Duration(milliseconds: 100));
        var stopped = false;
        r.engine.stop().then((_) => stopped = true);
        r.idle(const Duration(milliseconds: 300));
        expect(stopped, isTrue);
        expect(r.samples, isEmpty);
        expect(r.events, isEmpty, reason: 'a discarded failure is not reported');
      });
    });

    test('background stop runs the same sequence and reports its reason at the fence', () {
      fakeAsync((async) {
        final r = Rig(async, detectorLatency: const Duration(milliseconds: 300));
        r.start();
        r.source.emit(present: true);
        r.tick(const Duration(milliseconds: 100));
        r.lifecycle.add(AppLifecycleState.hidden);
        async.flushMicrotasks();
        expect(r.engine.isRunning, isFalse);
        expect(r.engine.lastStopReason, SeatEngineStopReason.background);
        expect(r.engine.lastStopReport, isNull, reason: 'still waiting for the detection');
        r.idle(const Duration(milliseconds: 300));
        expect(r.engine.lastStopReport!.reason, SeatEngineStopReason.background);
        expect(r.events.single, isA<SeatCameraLost>());
        expect(r.samples, isEmpty);
      });
    });
  });

  group('time', () {
    test('SeatSample.at is the capture time; completion time is diagnostics only', () {
      fakeAsync((async) {
        final r = Rig(async, detectorLatency: const Duration(milliseconds: 300));
        r.start();
        final captureWall = r.wall.now();
        final captureMono = r.mono.elapsed;
        r.source.emit(present: true);
        r.idle(const Duration(milliseconds: 400));
        expect(r.samples.single.at, captureWall);
        final d = r.diagnostics.single;
        expect(d.capturedWall, captureWall);
        expect(d.capturedAt, captureMono);
        expect(d.completedAt, captureMono + const Duration(milliseconds: 300));
        expect(d.latency, const Duration(milliseconds: 300));
        expect(d.generation, r.engine.generation);
      });
    });

    test('the hold window is measured on capture time, not on completion time', () {
      fakeAsync((async) {
        // 1 s detections: capture at 0 (present), result at 1; capture at 2
        // (absent), result at 3. Hold = 3 s from capture 0 → the absent frame
        // captured at 2 s is held, even though its result arrives at 3 s.
        final r = Rig(async, detectorLatency: const Duration(seconds: 1));
        r.start();
        r.source.emit(present: true);
        r.idle(const Duration(milliseconds: 1100));
        r.source.emit(present: false); // captured at 1.1 s
        r.idle(const Duration(milliseconds: 1100));
        expect(r.samples.map((s) => s.seated).toList(), <bool>[true, true]);
        expect(r.diagnostics.last.held, isTrue);
      });
    });
  });
}
