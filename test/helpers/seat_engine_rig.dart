import 'package:fake_async/fake_async.dart';
import 'package:soongong/core/contracts/seat_engine.dart';
import 'package:soongong/core/domain/clock.dart';
import 'package:soongong/data/engines/engines.dart';

import 'fake_seat_sources.dart';

/// Engine + doubles. Time is driven by [tick]: fake_async timers and the
/// engine's monotonic clock advance together.
class Rig {
  Rig(
    this.async, {
    CameraPermissionResult permission = CameraPermissionResult.granted,
    Duration detectorLatency = Duration.zero,
    CameraProbeResult probe = CameraProbeResult.ok,
  })  : source = FakeSeatFrameSource(probeResult: probe),
        detector = FakePresenceDetector(latency: detectorLatency),
        gateway = FakeCameraPermissionGateway(current: permission),
        lifecycle = FakeLifecycleSource(),
        mono = FakeMonotonicClock(),
        wall = FixedClock(DateTime.utc(2026, 10, 1, 9)) {
    engine = SeatEngineImpl(
      source: source,
      detector: detector,
      permission: gateway,
      lifecycle: lifecycle,
      clock: wall,
      monotonic: mono,
    );
    engine.samples.listen(samples.add);
    engine.events.listen(events.add);
    engine.diagnostics.listen(diagnostics.add);
  }

  final FakeAsync async;
  final FakeSeatFrameSource source;
  final FakePresenceDetector detector;
  final FakeCameraPermissionGateway gateway;
  final FakeLifecycleSource lifecycle;
  final FakeMonotonicClock mono;
  final FixedClock wall;
  late final SeatEngineImpl engine;
  final List<SeatSample> samples = <SeatSample>[];
  final List<SeatEngineEvent> events = <SeatEngineEvent>[];
  final List<SeatDiagnostic> diagnostics = <SeatDiagnostic>[];

  void tick(Duration d) {
    mono.advance(d);
    wall.advance(d);
    async.elapse(d);
  }

  /// Camera running at [fps] for [duration] with a constant detector answer.
  void stream(Duration duration, {required bool present, int fps = 15}) {
    final step = Duration(milliseconds: 1000 ~/ fps);
    var t = Duration.zero;
    while (t < duration) {
      source.emit(present: present);
      async.flushMicrotasks(); // zero-latency detections complete "now"
      tick(step);
      t += step;
    }
  }

  /// No frames at all for [duration] (camera stalled).
  void idle(Duration duration) {
    const step = Duration(milliseconds: 100);
    var t = Duration.zero;
    while (t < duration) {
      tick(step);
      t += step;
    }
  }

  void start([SeatEngineConfig config = const SeatEngineConfig()]) {
    engine.start(config);
    async.flushMicrotasks();
  }

  void stop() {
    engine.stop();
    async.flushMicrotasks();
  }
}

