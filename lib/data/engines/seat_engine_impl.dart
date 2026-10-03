// SeatEngineImpl (S04 · S04b): the S01 `SeatEngine` contract on a real camera.
//
// Output is a seated boolean on a 1-second cadence plus camera state events —
// nothing else (D3, CLAUDE.md §1). The engine is deliberately dumb: the away
// threshold (60–90 s, D23) and the sensitivity level belong to S06
// (`AwayPolicy`); the only timing logic here is a short hold window
// ([SeatHysteresis], default 3 s) that suppresses single missed frames.
//
// Pieces (all injectable, see `seat/`):
//   * [SeatFrameSource]   — camera frames via a synchronous callback
//   * [PresenceDetector]  — "is a person in this frame?" (ML Kit face bbox
//                           presence; bbox/landmarks are never read)
//   * [CameraPermissionGateway] — permission status / prompt
//   * [LifecycleSource]   — background → automatic stop
//
// Event semantics (S06):
//   * `SeatCameraLost`      — no frame for [frameTimeout] while running, a
//                             fatal/in-use camera fault, or the app left the
//                             foreground (the engine stops itself; restarting
//                             is the caller's job). Never an away segment (D23).
//   * `SeatCameraRecovered` — the first frame after a Lost, whatever happened
//                             in between (self-recovery or stop/start).
//   * `SeatError(code)`     — `start` could not run (`permission_denied` ·
//                             `no_camera` · `camera_busy` · `camera_init_failed`)
//                             or the detector keeps failing (`detector_failed`).
// No sample is emitted while the stream is lost (no decision without data).
//
// S04b (design reference: byite-co/focus-engine, re-implemented in Dart):
//   * Generation: every `start()` opens a new generation ([InferenceGate]).
//     Frame and fault callbacks are tagged with the generation of the camera
//     session that produced them, and a detection result is applied only when
//     its generation is still current — a late result from a previous run
//     never reaches the next run's samples or events.
//   * Stop sequence: `stop()` = fence (no new frames, generation bumped) →
//     camera released → wait for the in-flight detection at most
//     [stopInferenceTimeout] (500 ms); a result that returns after the fence
//     is discarded either way. `detector.close()` (dispose only) is never
//     called while a detection is running: it runs when the detection returns.
//   * Time: `SeatSample.at` is the frame's capture time (the camera
//     callback's wall-clock instant); the completion time exists only in
//     [SeatDiagnostic] for the lab.

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart' show AppLifecycleState, Widget;

import '../../core/contracts/seat_engine.dart';
import '../../core/domain/clock.dart';
import '../../core/logging/app_logger.dart';
import 'seat/camera_frame_source.dart';
import 'seat/camera_permission.dart';
import 'seat/frame_cadence.dart';
import 'seat/mlkit_face_presence_detector.dart';
import 'seat/seat_availability.dart';
import 'seat/seat_frame_source.dart';
import 'seat/seat_hysteresis.dart';
import 'seat/widgets_binding_lifecycle_source.dart';
import 'seat/work_generation.dart';

/// Stable `SeatError.message` codes.
abstract final class SeatErrorCode {
  static const String permissionDenied = 'permission_denied';
  static const String noCamera = 'no_camera';
  static const String cameraBusy = 'camera_busy';
  static const String cameraInitFailed = 'camera_init_failed';
  static const String detectorFailed = 'detector_failed';
}

/// Why the engine stopped (diagnostics only).
enum SeatEngineStopReason { caller, background, disposed }

/// How the last stop went (diagnostics; the lab marks a run whose stop was
/// not clean as excluded from its summary).
@immutable
class SeatStopReport {
  const SeatStopReport({
    required this.reason,
    required this.generation,
    required this.hadInFlight,
    required this.inferenceWait,
    required this.inferenceTimedOut,
    required this.suppressedResults,
  });

  final SeatEngineStopReason reason;

  /// Generation of the run that stopped.
  final int generation;

  /// A detection was still running at the fence.
  final bool hadInFlight;

  /// How long the stop waited for that detection (zero when none).
  final Duration inferenceWait;

  /// The detection did not return within [SeatEngineImpl.stopInferenceTimeout];
  /// its result is discarded when it eventually returns.
  final bool inferenceTimedOut;

  /// Results discarded so far because their generation was no longer current.
  final int suppressedResults;

  /// The stop left nothing behind: no detection outlived the bound.
  bool get clean => !inferenceTimedOut;
}

/// Per-processed-frame diagnostics for the `/_seat_lab` harness. Not part of
/// the contract; S06 must not depend on it.
@immutable
class SeatDiagnostic {
  const SeatDiagnostic({
    required this.capturedAt,
    required this.completedAt,
    required this.capturedWall,
    required this.generation,
    required this.detected,
    required this.seated,
    required this.held,
  });

  /// Monotonic time the frame arrived from the camera (capture time).
  final Duration capturedAt;

  /// Monotonic time the detection returned (internal instrumentation only).
  final Duration completedAt;

  /// Wall-clock capture time — the same instant as `SeatSample.at`.
  final DateTime capturedWall;

  /// Run that produced the frame.
  final int generation;

  /// Raw detector answer for this frame.
  final bool detected;

  /// Engine output (after the hold window).
  final bool seated;

  /// `seated` only because of the hold window.
  final bool held;

  /// Detector round-trip (capture → result).
  Duration get latency => completedAt - capturedAt;
}

class SeatEngineImpl implements SeatEngine {
  SeatEngineImpl({
    required this._source,
    required this._detector,
    required this._permission,
    this._lifecycle,
    this._clock = const SystemClock(),
    MonotonicClock? monotonic,
    Duration hold = SeatHysteresis.defaultHold,
    this.frameTimeout = defaultFrameTimeout,
    this.watchdogInterval = const Duration(seconds: 1),
    this.detectorFailureLimit = 3,
    this.stopInferenceTimeout = defaultStopInferenceTimeout,
  })  : _mono = monotonic ?? StopwatchMonotonicClock(),
        _hysteresis = SeatHysteresis(hold: hold);

  /// Production wiring: front camera + ML Kit face presence +
  /// permission_handler + WidgetsBinding lifecycle.
  factory SeatEngineImpl.camera({
    double minFaceSize = MlKitFacePresenceDetector.defaultMinFaceSize,
    MonotonicClock? monotonic,
  }) =>
      SeatEngineImpl(
        source: CameraFrameSource(),
        detector: MlKitFacePresenceDetector(minFaceSize: minFaceSize),
        permission: const PermissionHandlerCameraGateway(),
        lifecycle: WidgetsBindingLifecycleSource(),
        monotonic: monotonic,
      );

  /// No frame for this long while running → `SeatCameraLost`.
  static const Duration defaultFrameTimeout = Duration(seconds: 3);

  /// Bound on how long `stop()` waits for a detection in flight (S04b).
  static const Duration defaultStopInferenceTimeout = Duration(milliseconds: 500);

  final SeatFrameSource _source;
  final PresenceDetector _detector;
  final CameraPermissionGateway _permission;
  final LifecycleSource? _lifecycle;
  final Clock _clock;
  final MonotonicClock _mono;
  final SeatHysteresis _hysteresis;
  final Duration frameTimeout;
  final Duration watchdogInterval;
  final int detectorFailureLimit;
  final Duration stopInferenceTimeout;

  final StreamController<SeatSample> _samples =
      StreamController<SeatSample>.broadcast();
  final StreamController<SeatEngineEvent> _events =
      StreamController<SeatEngineEvent>.broadcast();
  final StreamController<SeatDiagnostic> _diagnostics =
      StreamController<SeatDiagnostic>.broadcast();

  final InferenceGate _gate = InferenceGate();
  FrameCadence _cadence = FrameCadence(interval: const Duration(seconds: 1));
  SeatEngineConfig? _config;
  Future<void>? _starting;
  Future<void>? _stopping;
  Timer? _watchdog;
  StreamSubscription<AppLifecycleState>? _lifecycleSub;
  Completer<void>? _inFlightDone;
  bool _running = false;
  bool _lost = false;
  bool _disposed = false;
  bool _detectorClosed = false;
  bool _closeDetectorAfterInference = false;
  Duration _lastFrameAt = Duration.zero;
  int _framesDelivered = 0;
  int _detectorFailures = 0;
  bool _detectorErrorReported = false;
  SeatEngineStopReason? _lastStopReason;
  SeatStopReport? _lastStop;
  String? _lastFault;

  // ── Diagnostics (lab only) ──────────────────────────────────────────────

  bool get isRunning => _running;

  /// A `SeatCameraLost` was emitted and no frame has arrived since.
  bool get isLost => _lost;

  SeatEngineConfig? get config => _config;

  /// Current run generation (bumped by every start and every stop).
  int get generation => _gate.generation.current;

  /// Frames the camera delivered since the last `start` (processed + dropped).
  int get framesDelivered => _framesDelivered;

  int get framesProcessed => _cadence.accepted;

  int get framesDropped => _cadence.dropped;

  /// Results discarded because they returned after their run's fence.
  int get suppressedResults => _gate.suppressed;

  /// A detection is running right now.
  bool get inferenceInFlight => _gate.inFlight;

  Duration get processingInterval => _cadence.interval;

  /// Known at the stop fence (before the bounded wait finishes).
  SeatEngineStopReason? get lastStopReason => _lastStopReason;

  /// Set once the stop sequence completed.
  SeatStopReport? get lastStopReport => _lastStop;

  /// Last camera fault description (plugin text, no frame data).
  String? get lastFault => _lastFault;

  /// The engine's monotonic clock, so the lab can put its own rows on the
  /// same time base as [SeatDiagnostic].
  Duration get monotonicNow => _mono.elapsed;

  Stream<SeatDiagnostic> get diagnostics => _diagnostics.stream;

  /// The permission gateway, for callers that want the prompt helper with
  /// the same wiring as the engine.
  CameraPermissionGateway get permissionGateway => _permission;

  // ── Contract ────────────────────────────────────────────────────────────

  /// Permission (prompting when the OS still allows it) → hardware → busy.
  /// The camera is opened briefly and released; it does not stay open.
  @override
  Future<SeatAvailability> checkAvailability() async {
    var permission = await _permission.status();
    if (!permission.isGranted && !permission.needsSettings) {
      permission = await _permission.request();
    }
    if (!permission.isGranted) {
      return mapSeatAvailability(permission: permission, probe: null);
    }
    final probe = await _source.probe();
    return mapSeatAvailability(permission: permission, probe: probe);
  }

  @override
  Future<void> start(SeatEngineConfig config) {
    final pending = _starting;
    if (pending != null) return pending;
    if (_running || _disposed) return Future<void>.value();
    final f = _start(config);
    _starting = f;
    return f.whenComplete(() => _starting = null);
  }

  Future<void> _start(SeatEngineConfig config) async {
    final stopping = _stopping;
    if (stopping != null) await stopping;
    final permission = await _permission.status();
    if (!permission.isGranted) {
      _events.add(const SeatError(SeatErrorCode.permissionDenied));
      return;
    }
    _config = config;
    _cadence = FrameCadence(interval: FrameCadence.intervalFor(config));
    _hysteresis.reset();
    _framesDelivered = 0;
    _detectorFailures = 0;
    _detectorErrorReported = false;
    // New generation: callbacks of this camera session carry it, so a late
    // callback from an earlier session is told apart and dropped.
    final gen = _gate.open();
    try {
      await _source.open(
        SeatFrameSourceConfig(lowPower: config.lowPower),
        onFrame: (frame) => _onFrame(frame, gen),
        onFault: (fault, description) => _onFault(fault, description, gen),
      );
    } on SeatFrameSourceException catch (e) {
      _gate.cancel();
      appLog.w('seat engine: camera open failed (${e.code})');
      _events.add(SeatError(e.code));
      return;
    } catch (e, st) {
      _gate.cancel();
      appLog.w('seat engine: camera open failed', error: e, stackTrace: st);
      _events.add(const SeatError(SeatErrorCode.cameraInitFailed));
      return;
    }
    _running = true;
    _lastStopReason = null;
    _lastFrameAt = _mono.elapsed;
    _lifecycleSub = _lifecycle?.states.listen(_onLifecycle);
    _watchdog = Timer.periodic(watchdogInterval, (_) => _checkStream());
    appLog.d(
      'seat engine: started · gen=$gen '
      'interval=${_cadence.interval.inMilliseconds}ms lowPower=${config.lowPower}',
    );
  }

  @override
  Future<void> stop() => _stop(SeatEngineStopReason.caller);

  /// Stop sequence (S04b): 1 fence — no new frames, generation bumped so the
  /// in-flight result is discarded · 2 camera released · 3 bounded wait for
  /// the in-flight detection · report. Idempotent; concurrent calls share
  /// one run.
  Future<void> _stop(SeatEngineStopReason reason) {
    final pending = _stopping;
    if (pending != null) return pending;
    final f = _stopSequence(reason);
    _stopping = f;
    return f.whenComplete(() => _stopping = null);
  }

  Future<void> _stopSequence(SeatEngineStopReason reason) async {
    final pending = _starting;
    if (pending != null) await pending;
    if (!_running && !_source.isOpen && !_gate.inFlight) return;

    // 1. Fence.
    _running = false;
    _lastStopReason = reason;
    final generation = _gate.generation.current;
    final hadInFlight = _gate.cancel();
    _watchdog?.cancel();
    _watchdog = null;
    // Not awaited: a broadcast subscription's cancel future completes in the
    // root zone, which would stall the rest of this method under fake_async.
    final lifecycleSub = _lifecycleSub;
    _lifecycleSub = null;
    if (lifecycleSub != null) unawaited(lifecycleSub.cancel());

    // 2. Camera.
    try {
      await _source.close();
    } catch (e, st) {
      appLog.w('seat engine: camera close failed', error: e, stackTrace: st);
    }

    // 3. In-flight detection, bounded.
    var waited = Duration.zero;
    var timedOut = false;
    final inFlight = _inFlightDone;
    if (hadInFlight && inFlight != null && !inFlight.isCompleted) {
      final t0 = _mono.elapsed;
      timedOut = !await _awaitWithTimeout(inFlight.future, stopInferenceTimeout);
      waited = _mono.elapsed - t0;
    }
    _lastStop = SeatStopReport(
      reason: reason,
      generation: generation,
      hadInFlight: hadInFlight,
      inferenceWait: waited,
      inferenceTimedOut: timedOut,
      suppressedResults: _gate.suppressed,
    );
    appLog.d(
      'seat engine: stopped (${reason.name}) gen=$generation '
      'inFlight=$hadInFlight waited=${waited.inMilliseconds}ms timedOut=$timedOut',
    );
  }

  /// `true` when [future] completed within [timeout].
  static Future<bool> _awaitWithTimeout(Future<void> future, Duration timeout) {
    final done = Completer<bool>();
    final timer = Timer(timeout, () {
      if (!done.isCompleted) done.complete(false);
    });
    future.whenComplete(() {
      timer.cancel();
      if (!done.isCompleted) done.complete(true);
    });
    return done.future;
  }

  @override
  Stream<SeatSample> get samples => _samples.stream;

  @override
  Stream<SeatEngineEvent> get events => _events.stream;

  /// The measurement screen shows a status icon, never a preview (§4.2).
  @override
  Widget? previewOrNull() => null;

  /// Stops, then closes the detector — never while a detection is running:
  /// a detection that outlived the stop bound closes it when it returns.
  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    await _stop(SeatEngineStopReason.disposed);
    await _closeDetectorWhenIdle();
    await _samples.close();
    await _events.close();
    await _diagnostics.close();
  }

  Future<void> _closeDetectorWhenIdle() async {
    if (_detectorClosed) return;
    if (_gate.inFlight) {
      _closeDetectorAfterInference = true;
      return;
    }
    _detectorClosed = true;
    await _detector.close();
  }

  // ── Frames ──────────────────────────────────────────────────────────────

  /// Camera callback. Runs synchronously; the frame is either handed to the
  /// detector right away or dropped — it is never stored. [gen] is the
  /// generation of the camera session that delivered the frame.
  void _onFrame(SeatFrame frame, int gen) {
    if (!_running || !_gate.generation.isCurrent(gen)) return;
    final capturedAt = _mono.elapsed;
    final capturedWall = _clock.now();
    _lastFrameAt = capturedAt;
    _framesDelivered++;
    if (_lost) {
      _lost = false;
      _events.add(const SeatCameraRecovered());
    }
    if (!_cadence.accept(capturedAt)) return;
    final frameGeneration = _gate.begin();
    if (frameGeneration == null) {
      _cadence.release();
      return;
    }
    final done = Completer<void>();
    _inFlightDone = done;
    unawaited(_process(frame, frameGeneration, capturedAt, capturedWall, done));
  }

  Future<void> _process(
    SeatFrame frame,
    int frameGeneration,
    Duration capturedAt,
    DateTime capturedWall,
    Completer<void> done,
  ) async {
    bool? detected;
    Object? error;
    StackTrace? stack;
    try {
      detected = await _detector.detect(frame);
    } catch (e, st) {
      error = e;
      stack = st;
    }
    _cadence.release();
    final current = _gate.end(frameGeneration);
    final completedAt = _mono.elapsed;
    done.complete();
    if (_closeDetectorAfterInference && !_detectorClosed) {
      _detectorClosed = true;
      unawaited(_closeDetectorQuietly());
    }
    if (!current) return; // the run ended (stop / restart): discarded
    if (error != null) {
      _onDetectorFailure(error, stack!);
      return;
    }
    _detectorFailures = 0;
    _detectorErrorReported = false;
    final seated = _hysteresis.observe(at: capturedAt, detected: detected!);
    _samples.add(SeatSample(at: capturedWall, seated: seated));
    if (_diagnostics.hasListener) {
      _diagnostics.add(
        SeatDiagnostic(
          capturedAt: capturedAt,
          completedAt: completedAt,
          capturedWall: capturedWall,
          generation: frameGeneration,
          detected: detected,
          seated: seated,
          held: seated && !detected,
        ),
      );
    }
  }

  Future<void> _closeDetectorQuietly() async {
    try {
      await _detector.close();
    } catch (e, st) {
      appLog.w('seat engine: detector close failed', error: e, stackTrace: st);
    }
  }

  void _onDetectorFailure(Object e, StackTrace st) {
    _detectorFailures++;
    // Message only — never the frame.
    appLog.w('seat engine: detector failed (${_detectorFailures}x)', error: e, stackTrace: st);
    if (_detectorFailures >= detectorFailureLimit && !_detectorErrorReported) {
      _detectorErrorReported = true;
      _events.add(const SeatError(SeatErrorCode.detectorFailed));
    }
  }

  // ── Camera health ───────────────────────────────────────────────────────

  void _checkStream() {
    if (!_running || _lost) return;
    if (_mono.elapsed - _lastFrameAt > frameTimeout) _markLost('frame timeout');
  }

  void _onFault(CameraFault fault, String description, int gen) {
    if (!_gate.generation.isCurrent(gen)) return; // a closed camera session
    _lastFault = description;
    appLog.w('seat engine: camera fault ${fault.name}: $description');
    switch (fault) {
      case CameraFault.inUse:
      case CameraFault.fatal:
      case CameraFault.disabled:
        if (_running) _markLost(fault.name);
      case CameraFault.recoverable:
      case CameraFault.unknown:
        break; // the watchdog decides
    }
  }

  void _markLost(String why) {
    if (_lost) return;
    _lost = true;
    appLog.d('seat engine: camera lost ($why)');
    _events.add(const SeatCameraLost());
  }

  // ── Lifecycle ───────────────────────────────────────────────────────────

  void _onLifecycle(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.hidden:
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
        unawaited(_onBackground());
      case AppLifecycleState.resumed:
      case AppLifecycleState.inactive:
        break;
    }
  }

  /// Background: release the camera at once (no stream without a foreground
  /// activity) and tell the caller. Restarting on resume is S06's job.
  Future<void> _onBackground() async {
    if (!_running) return;
    _markLost('background');
    await _stop(SeatEngineStopReason.background);
  }
}
