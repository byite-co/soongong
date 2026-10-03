import 'package:fake_async/fake_async.dart';
import 'package:soongong/core/contracts/seat_engine.dart';
import 'package:soongong/core/domain/clock.dart';
import 'package:soongong/data/engines/engines.dart';

import 'fake_seat_sources.dart';

/// Engine + doubles. Time is driven by [tick]: fake_async timers and the
/// engine's monotonic clock advance together.
///
/// Detectors come from a factory (S04d): [detector] is the first one (the
/// engine creates it at construction); every replacement the engine asks for
/// is appended to [detectors] and inherits [detectorLatency] /
/// [hangNewDetectors] at creation time.
class Rig {
  Rig(
    this.async, {
    CameraPermissionResult permission = CameraPermissionResult.granted,
    this.detectorLatency = Duration.zero,
    CameraProbeResult probe = CameraProbeResult.ok,
    this.hangNewDetectors = false,
  })  : source = FakeSeatFrameSource(probeResult: probe),
        gateway = FakeCameraPermissionGateway(current: permission),
        lifecycle = FakeLifecycleSource(),
        mono = FakeMonotonicClock(),
        wall = FixedClock(DateTime.utc(2026, 10, 1, 9)) {
    engine = SeatEngineImpl(
      source: source,
      detectorFactory: _newDetector,
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
  final FakeCameraPermissionGateway gateway;
  final FakeLifecycleSource lifecycle;
  final FakeMonotonicClock mono;
  final FixedClock wall;

  /// Latency given to detectors created from now on.
  Duration detectorLatency;

  /// Detectors created from now on start hung.
  bool hangNewDetectors;
  final List<FakePresenceDetector> detectors = <FakePresenceDetector>[];
  late final SeatEngineImpl engine;
  final List<SeatSample> samples = <SeatSample>[];
  final List<SeatEngineEvent> events = <SeatEngineEvent>[];
  final List<SeatDiagnostic> diagnostics = <SeatDiagnostic>[];

  FakePresenceDetector _newDetector() {
    final d = FakePresenceDetector(latency: detectorLatency, hang: hangNewDetectors);
    detectors.add(d);
    return d;
  }

  /// The first detector (the one in use until the engine replaces it).
  FakePresenceDetector get detector => detectors.first;

  /// `detect` calls across every detector.
  int get detectCalls => detectors.fold(0, (n, d) => n + d.calls);

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
