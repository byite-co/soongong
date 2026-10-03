// SeatEngineImpl (S04 · S04b · S04c · S04d): the S01 `SeatEngine` contract on
// a real camera.
//
// Output is a seated boolean on a 1-second cadence plus camera state events —
// nothing else (D3, CLAUDE.md §1). The engine is deliberately dumb: the away
// threshold (60–90 s, D23) and the sensitivity level belong to S06
// (`AwayPolicy`); the only timing logic here is a short hold window
// ([SeatHysteresis], default 3 s) that suppresses single missed frames.
//
// Pieces (all injectable, see `seat/`):
//   * [SeatFrameSource]   — camera sessions via a synchronous frame callback;
//                           every `open()` returns the handle that owns it
//   * [PresenceDetectorFactory] — "is a person in this frame?" (ML Kit face
//                           bbox presence; bbox/landmarks are never read).
//                           A detector that stops answering is retired and
//                           replaced (S04d §2)
//   * [CameraPermissionGateway] — permission status / prompt
//   * [LifecycleSource]   — background → automatic stop
//
// Event semantics (S06):
//   * `SeatCameraLost`      — no frame for [frameTimeout] while running, a
//                             fatal/in-use camera fault, or no detector left
//                             to decide with (S04d §2). Never an away
//                             segment (D23). The detection in flight is
//                             invalidated: nothing decided on a stalled
//                             stream is published.
//   * `SeatPaused(reason)`  — the app left the foreground, while running or
//                             while `start()` was still opening the camera
//                             (S04c). The engine stopped itself and released
//                             the camera; restarting is the caller's job.
//   * `SeatCameraRecovered` — the first frame after a Lost or a Paused that
//                             the engine can decide on, whatever happened in
//                             between.
//   * `SeatError(code)`     — `start` could not run (`permission_denied` ·
//                             `no_camera` · `camera_busy` · `camera_init_failed`
//                             · `camera_init_timeout` · `detector_failed`) or
//                             the detector keeps failing (`detector_failed`).
// No sample is emitted while the stream is lost (no decision without data).
//
// Time (CONTRACT-CHANGE [S04c], reference fixed in S04d §3):
// `SeatSample.sinceStart` is the monotonic elapsed time at the frame's
// capture since the instant `start()` was CALLED — before the camera opened
// — so a caller that notes one wall-clock instant right before `start()` can
// place every sample of the run with `runStartedAt + sinceStart`.
// `receivedAt` is the wall clock at capture, informational only.
//
// Runs (S04d §1): every `start()` creates a run token. The camera handle the
// open returns belongs to that run; a late open (after the bound), an open
// that lands after `stop()` cancelled the run, or a start aborted by the
// lifecycle releases ITS OWN handle only — the run that replaced it keeps its
// camera and its stream.
//
// Bounds: camera open ≤ [openTimeout] (8 s) for both `checkAvailability` and
// `start` — on expiry the caller gets an answer at once and the late camera
// is released in the background; a detection older than
// [InferenceGate.deadline] (2 s) is given up on by the watchdog and its
// detector retired; `stop()` while running returns within
// [stopReleaseTimeout] (2 s, camera) + [stopInferenceTimeout] (500 ms,
// detection); `stop()` while the camera is still opening cancels the run and
// returns at once (S04d §6a); a new `start()` is allowed right after,
// whatever the previous run's cleanup is still doing.

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

  /// The camera did not finish opening within [SeatEngineImpl.openTimeout].
  static const String cameraInitTimeout = 'camera_init_timeout';

  /// The detector keeps throwing ([SeatEngineImpl.detectorFailureLimit] in a
  /// row), or [SeatEngineImpl.stalledDetectionLimit] retired detectors are
  /// still hanging so no new one may be created (S04d §2).
  static const String detectorFailed = 'detector_failed';
}

/// Why the engine stopped (diagnostics only).
enum SeatEngineStopReason { caller, background, disposed }

/// Why the engine reported `SeatCameraLost` (diagnostics only).
abstract final class SeatLostReason {
  static const String frameTimeout = 'frame timeout';
  static const String detectorExhausted = 'detector exhausted';
}

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
    required this.cameraReleaseWait,
    required this.cameraReleaseTimedOut,
    required this.suppressedResults,
    required this.stalledDetections,
  });

  final SeatEngineStopReason reason;

  /// Generation of the run that stopped.
  final int generation;

  /// The most recently submitted detection was still running at the fence.
  final bool hadInFlight;

  /// How long the stop waited for that detection (zero when none).
  final Duration inferenceWait;

  /// The detection did not return within [SeatEngineImpl.stopInferenceTimeout];
  /// its result is discarded when it eventually returns.
  final bool inferenceTimedOut;

  /// How long the stop waited for the camera to be released.
  final Duration cameraReleaseWait;

  /// The camera release did not finish within
  /// [SeatEngineImpl.stopReleaseTimeout]; it continues in the background.
  final bool cameraReleaseTimedOut;

  /// Results discarded so far because their ticket was no longer current.
  final int suppressedResults;

  /// Retired detectors whose call had still not returned at the stop
  /// (S04d §2). They are closed when they return; a permanently hung one
  /// never is.
  final int stalledDetections;

  /// The stop left nothing behind: no detection and no camera release
  /// outlived its bound.
  bool get clean => !inferenceTimedOut && !cameraReleaseTimedOut;
}

/// Per-processed-frame diagnostics for the `/_seat_lab` harness. Not part of
/// the contract; S06 must not depend on it.
@immutable
class SeatDiagnostic {
  const SeatDiagnostic({
    required this.capturedAt,
    required this.completedAt,
    required this.capturedWall,
    required this.sinceStart,
    required this.generation,
    required this.detected,
    required this.seated,
    required this.held,
  });

  /// Monotonic time the frame arrived from the camera (capture time).
  final Duration capturedAt;

  /// Monotonic time the detection returned (internal instrumentation only).
  final Duration completedAt;

  /// Wall-clock capture time — the same instant as `SeatSample.receivedAt`.
  final DateTime capturedWall;

  /// Same value as `SeatSample.sinceStart`.
  final Duration sinceStart;

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

/// One `start()` (S04d §1). The camera handle the open returns belongs to
/// the run; a cancelled or aborted run releases its own handle only.
class _Run {
  _Run({required this.startedAt});

  /// Monotonic instant `start()` was called — the zero of `sinceStart`.
  final Duration startedAt;

  int generation = 0;
  SeatCameraHandle? camera;

  /// `stop()` / `dispose()` arrived while the camera was still opening.
  bool cancelled = false;

  /// The app left the foreground while the camera was opening.
  bool background = false;
}

/// One detector instance and the calls still running on it (S04d §2).
class _DetectorSlot {
  _DetectorSlot(this.id, this.detector);

  final int id;
  final PresenceDetector detector;

  /// Calls that have not returned.
  int pending = 0;

  /// Nothing more is submitted; the slot closes when [pending] reaches zero.
  bool retired = false;
  bool closed = false;
}

class SeatEngineImpl implements SeatEngine {
  SeatEngineImpl({
    required this._source,
    required this._detectorFactory,
    required this._permission,
    this._lifecycle,
    this._clock = const SystemClock(),
    MonotonicClock? monotonic,
    Duration hold = SeatHysteresis.defaultHold,
    this.frameTimeout = defaultFrameTimeout,
    this.watchdogInterval = const Duration(seconds: 1),
    this.detectorFailureLimit = 3,
    this.stalledDetectionLimit = defaultStalledDetectionLimit,
    this.stopInferenceTimeout = defaultStopInferenceTimeout,
    this.stopReleaseTimeout = defaultStopReleaseTimeout,
    this.openTimeout = defaultOpenTimeout,
    Duration inferenceDeadline = InferenceGate.defaultDeadline,
  })  : _mono = monotonic ?? StopwatchMonotonicClock(),
        _hysteresis = SeatHysteresis(hold: hold),
        _gate = InferenceGate(deadline: inferenceDeadline) {
    _active = _newDetectorSlot();
  }

  /// Production wiring: front camera + ML Kit face presence +
  /// permission_handler + WidgetsBinding lifecycle.
  factory SeatEngineImpl.camera({
    double minFaceSize = MlKitFacePresenceDetector.defaultMinFaceSize,
    MonotonicClock? monotonic,
  }) =>
      SeatEngineImpl(
        source: CameraFrameSource(),
        detectorFactory: () => MlKitFacePresenceDetector(minFaceSize: minFaceSize),
        permission: const PermissionHandlerCameraGateway(),
        lifecycle: WidgetsBindingLifecycleSource(),
        monotonic: monotonic,
      );

  /// No frame for this long while running → `SeatCameraLost`.
  static const Duration defaultFrameTimeout = Duration(seconds: 3);

  /// Bound on how long `stop()` waits for a detection in flight (S04b).
  static const Duration defaultStopInferenceTimeout = Duration(milliseconds: 500);

  /// Bound on how long `stop()` waits for the camera release (S04c §3c).
  static const Duration defaultStopReleaseTimeout = Duration(seconds: 2);

  /// Bound on opening the camera, for the probe and for `start()` (S04c §3a).
  static const Duration defaultOpenTimeout = Duration(seconds: 8);

  /// Retired detectors that may be left hanging at once (S04d §2). At the
  /// limit no new detector is created: `detector_failed` + Lost.
  static const int defaultStalledDetectionLimit = 2;

  /// Reason code of the last `unavailable` from [checkAvailability].
  static const String availabilityReasonTimeout = 'timeout';

  final SeatFrameSource _source;
  final PresenceDetectorFactory _detectorFactory;
  final CameraPermissionGateway _permission;
  final LifecycleSource? _lifecycle;
  final Clock _clock;
  final MonotonicClock _mono;
  final SeatHysteresis _hysteresis;
  final InferenceGate _gate;
  final Duration frameTimeout;
  final Duration watchdogInterval;
  final int detectorFailureLimit;
  final int stalledDetectionLimit;
  final Duration stopInferenceTimeout;
  final Duration stopReleaseTimeout;
  final Duration openTimeout;

  final StreamController<SeatSample> _samples =
      StreamController<SeatSample>.broadcast();
  final StreamController<SeatEngineEvent> _events =
      StreamController<SeatEngineEvent>.broadcast();
  final StreamController<SeatDiagnostic> _diagnostics =
      StreamController<SeatDiagnostic>.broadcast();

  FrameCadence _cadence = FrameCadence(interval: const Duration(seconds: 1));
  SeatEngineConfig? _config;
  _Run? _run;
  Future<void>? _starting;
  Future<void>? _stopping;
  Timer? _watchdog;
  StreamSubscription<AppLifecycleState>? _lifecycleSub;
  Completer<void>? _inFlightDone;
  _DetectorSlot? _active;
  final List<_DetectorSlot> _retired = <_DetectorSlot>[];
  int _detectorSeq = 0;
  int _detectorReplacements = 0;
  int _physicalInFlight = 0;
  bool _running = false;
  bool _lost = false;
  bool _disposed = false;
  Duration _runStartMono = Duration.zero;
  Duration _lastFrameAt = Duration.zero;
  int _framesDelivered = 0;
  int _detectorFailures = 0;
  bool _detectorErrorReported = false;
  SeatEngineStopReason? _lastStopReason;
  SeatStopReport? _lastStop;
  String? _lastFault;
  String? _lastLostReason;
  String? _lastAvailabilityReason;

  // ── Diagnostics (lab only) ──────────────────────────────────────────────

  bool get isRunning => _running;

  /// A `SeatCameraLost` / `SeatPaused` was emitted and no decidable frame has
  /// arrived since.
  bool get isLost => _lost;

  /// Why the last `SeatCameraLost` / `SeatPaused` happened (`frame timeout`,
  /// a camera fault name, `detector exhausted`, a pause reason).
  String? get lastLostReason => _lastLostReason;

  SeatEngineConfig? get config => _config;

  /// Current run generation (bumped by every start and every stop).
  int get generation => _gate.generation.current;

  /// Frames the camera delivered since the last `start` (processed + dropped).
  int get framesDelivered => _framesDelivered;

  int get framesProcessed => _cadence.accepted;

  int get framesDropped => _cadence.dropped;

  /// Results discarded because they returned after their run's fence, after
  /// a camera loss, or after their deadline.
  int get suppressedResults => _gate.suppressed;

  /// Detections the watchdog gave up on (S04c §3b).
  int get inferenceTimeouts => _gate.expired;

  /// At least one detection is physically running right now (its result may
  /// already be doomed). A detector call that never returns keeps this true
  /// for good.
  bool get inferenceInFlight => _physicalInFlight > 0;

  /// Retired detectors whose call has not returned (S04d §2).
  int get stalledDetections => _retired.where((s) => s.pending > 0).length;

  /// Detectors created to replace a retired one.
  int get detectorReplacements => _detectorReplacements;

  /// A detector can take the next frame (or one may still be created).
  bool get detectorAvailable {
    final a = _active;
    if (a != null && !a.retired) return true;
    return !_disposed && stalledDetections < stalledDetectionLimit;
  }

  Duration get processingInterval => _cadence.interval;

  /// Known at the stop fence (before the bounded waits finish).
  SeatEngineStopReason? get lastStopReason => _lastStopReason;

  /// Set once the stop sequence completed.
  SeatStopReport? get lastStopReport => _lastStop;

  /// Last camera fault description (plugin text, no frame data).
  String? get lastFault => _lastFault;

  /// Why the last [checkAvailability] answered `unavailable` (`timeout`, or
  /// the probe result name).
  String? get lastAvailabilityReason => _lastAvailabilityReason;

  /// The engine's monotonic clock, so the lab can put its own rows on the
  /// same time base as [SeatDiagnostic].
  Duration get monotonicNow => _mono.elapsed;

  Stream<SeatDiagnostic> get diagnostics => _diagnostics.stream;

  /// The permission gateway, for callers that want the prompt helper with
  /// the same wiring as the engine.
  CameraPermissionGateway get permissionGateway => _permission;

  // ── Contract ────────────────────────────────────────────────────────────

  /// Permission (prompting when the OS still allows it) → hardware → busy.
  /// The camera is opened briefly and released; it does not stay open. A
  /// probe that does not answer within [openTimeout] is `unavailable`
  /// (`lastAvailabilityReason == 'timeout'`); its camera is released by the
  /// source in the background.
  @override
  Future<SeatAvailability> checkAvailability() async {
    _lastAvailabilityReason = null;
    var permission = await _permission.status();
    if (!permission.isGranted && !permission.needsSettings) {
      permission = await _permission.request();
    }
    if (!permission.isGranted) {
      return mapSeatAvailability(permission: permission, probe: null);
    }
    final probe = await _boundedProbe();
    if (probe == null) {
      _lastAvailabilityReason = availabilityReasonTimeout;
      appLog.w('seat engine: camera probe timed out after ${openTimeout.inSeconds}s');
      return SeatAvailability.unavailable;
    }
    final out = mapSeatAvailability(permission: permission, probe: probe);
    if (out == SeatAvailability.unavailable) _lastAvailabilityReason = probe.name;
    return out;
  }

  Future<CameraProbeResult?> _boundedProbe() {
    final done = Completer<CameraProbeResult?>();
    final timer = Timer(openTimeout, () {
      if (!done.isCompleted) done.complete(null);
    });
    _source.probe().then(
      (r) {
        timer.cancel();
        if (!done.isCompleted) done.complete(r);
      },
      onError: (Object e, StackTrace st) {
        timer.cancel();
        appLog.w('seat engine: camera probe failed', error: e, stackTrace: st);
        if (!done.isCompleted) done.complete(CameraProbeResult.failed);
      },
    );
    return done.future;
  }

  @override
  Future<void> start(SeatEngineConfig config) {
    final pending = _starting;
    final current = _run;
    // A start still opening the camera is shared — unless stop() already
    // cancelled that run, in which case a new run begins (S04d §6a).
    if (pending != null && current != null && !current.cancelled) return pending;
    if (_running || _disposed) return Future<void>.value();
    // S04d §3: the run's time base is the call instant, before the camera.
    final run = _Run(startedAt: _mono.elapsed);
    _run = run;
    final f = _start(config, run);
    _starting = f;
    return f.whenComplete(() {
      if (identical(_starting, f)) _starting = null;
    });
  }

  Future<void> _start(SeatEngineConfig config, _Run run) async {
    final stopping = _stopping;
    if (stopping != null) await stopping;
    if (_disposed || run.cancelled) return;

    // Lifecycle first (S04c §2): subscribe before touching the camera and
    // refuse to open it while the app is not in the foreground.
    _lifecycleSub ??= _lifecycle?.states.listen(_onLifecycle);
    if (isBackgroundState(_lifecycle?.current)) {
      _abortStart(SeatPauseReason.backgroundDuringStart);
      return;
    }

    final permission = await _permission.status();
    if (run.cancelled) return;
    if (!permission.isGranted) {
      _detachLifecycle();
      _events.add(const SeatError(SeatErrorCode.permissionDenied));
      return;
    }
    // S04d §2: a detector must be available. A retired one is replaced here
    // unless the stalled-call limit forbids a new one — then recovery has to
    // wait for a hung call to return.
    if (_detectorForWork() == null) {
      _detachLifecycle();
      appLog.w('seat engine: start refused — $stalledDetections detector(s) still hanging');
      _events.add(const SeatError(SeatErrorCode.detectorFailed));
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
    run.generation = gen;
    final SeatCameraHandle? camera;
    try {
      camera = await _openBounded(
        run,
        _source.open(
          SeatFrameSourceConfig(lowPower: config.lowPower),
          onFrame: (frame) => _onFrame(frame, gen),
          onFault: (fault, description) => _onFault(fault, description, gen),
        ),
      );
    } on SeatFrameSourceException catch (e) {
      _failStart(run, e.code, 'camera open failed (${e.code})');
      return;
    } catch (e, st) {
      _failStart(run, SeatErrorCode.cameraInitFailed, 'camera open failed', e, st);
      return;
    }
    if (camera == null) {
      _failStart(
        run,
        SeatErrorCode.cameraInitTimeout,
        'camera open timed out after ${openTimeout.inSeconds}s',
      );
      return;
    }
    if (run.cancelled) {
      // stop() / dispose() arrived while the camera was opening (S04d §6a):
      // the run is already over; release this run's camera in the background.
      appLog.d('seat engine: camera opened for a cancelled run (gen=$gen) — releasing it');
      unawaited(_closeHandleBounded(camera, 'cancelled start'));
      return;
    }
    // Re-check (S04c §2): the app may have left the foreground while the
    // camera was opening — release it again and report a pause instead of
    // running in the background.
    if (run.background || isBackgroundState(_lifecycle?.current)) {
      _gate.cancel();
      run.camera = camera;
      await _closeRunCamera(run, 'start aborted');
      _abortStart(SeatPauseReason.backgroundDuringStart);
      return;
    }
    run.camera = camera;
    _running = true;
    _lastStopReason = null;
    _runStartMono = run.startedAt;
    _lastFrameAt = _mono.elapsed; // the frame watchdog counts from the open
    _watchdog = Timer.periodic(watchdogInterval, (_) => _watchdogTick());
    appLog.d(
      'seat engine: started · gen=$gen '
      'interval=${_cadence.interval.inMilliseconds}ms lowPower=${config.lowPower} '
      'openTook=${(_mono.elapsed - run.startedAt).inMilliseconds}ms',
    );
  }

  /// A start that could not run. Nothing is reported for a run `stop()`
  /// already cancelled.
  void _failStart(_Run run, String code, String why, [Object? e, StackTrace? st]) {
    if (run.cancelled) {
      appLog.d('seat engine: $why (run already cancelled)');
      return;
    }
    _gate.cancel();
    _detachLifecycle();
    appLog.w('seat engine: $why', error: e, stackTrace: st);
    _events.add(SeatError(code));
  }

  /// Opens with a bound. A camera that finishes opening after the bound is
  /// released again in the background through its own handle (S04d §1); its
  /// callbacks carry a cancelled generation and post nothing.
  Future<SeatCameraHandle?> _openBounded(_Run run, Future<SeatCameraHandle> open) {
    final done = Completer<SeatCameraHandle?>();
    final timer = Timer(openTimeout, () {
      if (!done.isCompleted) done.complete(null);
    });
    open.then(
      (handle) {
        timer.cancel();
        if (!done.isCompleted) {
          done.complete(handle);
        } else {
          appLog.w('seat engine: camera opened after the bound (gen=${run.generation}) — releasing it');
          unawaited(_closeHandleBounded(handle, 'late open'));
        }
      },
      onError: (Object e, StackTrace st) {
        timer.cancel();
        if (!done.isCompleted) {
          done.completeError(e, st);
        } else {
          appLog.w('seat engine: late camera open failed', error: e, stackTrace: st);
        }
      },
    );
    return done.future;
  }

  void _abortStart(SeatPauseReason reason) {
    _detachLifecycle();
    _lost = true; // the next run's first frame reports a recovery
    _lastLostReason = reason.name;
    _events.add(SeatPaused(reason));
    appLog.d('seat engine: start aborted (${reason.name})');
  }

  void _detachLifecycle() {
    // Not awaited: a broadcast subscription's cancel future completes in the
    // root zone, which would stall the caller under fake_async.
    final sub = _lifecycleSub;
    _lifecycleSub = null;
    if (sub != null) unawaited(sub.cancel());
  }

  @override
  Future<void> stop() => _stop(SeatEngineStopReason.caller);

  /// Stop sequence (S04b · S04c · S04d): 1 fence — no new frames, generation
  /// bumped so the in-flight result is discarded · 2 this run's camera
  /// release, at most [stopReleaseTimeout] · 3 in-flight detection, at most
  /// [stopInferenceTimeout] · report. Idempotent; concurrent calls share one
  /// run. Whatever outlives its bound finishes in the background and does not
  /// block the next `start()`.
  ///
  /// While the camera is still opening (S04d §6a) the run token is cancelled
  /// and the call returns at once; the open releases its own camera when it
  /// lands.
  Future<void> _stop(SeatEngineStopReason reason) {
    final pending = _stopping;
    if (pending != null) return pending;
    final run = _run;
    if (!_running && _starting != null && run != null && !run.cancelled) {
      run.cancelled = true;
      _lastStopReason = reason;
      _gate.cancel();
      _detachLifecycle();
      appLog.d('seat engine: stop during start (${reason.name}) — run gen=${run.generation} cancelled');
      return Future<void>.value();
    }
    final f = _stopSequence(reason, run);
    _stopping = f;
    return f.whenComplete(() => _stopping = null);
  }

  Future<void> _stopSequence(SeatEngineStopReason reason, _Run? run) async {
    if (!_running && run?.camera == null && !inferenceInFlight) return;

    // 1. Fence.
    _running = false;
    _lastStopReason = reason;
    final generation = _gate.generation.current;
    // The most recently submitted detection, if it has not returned yet —
    // whether or not the gate already gave up on it.
    final latest = _inFlightDone;
    final pendingDetection = latest != null && !latest.isCompleted ? latest : null;
    final hadInFlight = pendingDetection != null;
    _gate.cancel();
    _watchdog?.cancel();
    _watchdog = null;
    _detachLifecycle();

    // 2. This run's camera, bounded.
    final tRelease = _mono.elapsed;
    final releaseTimedOut = run != null && !await _closeRunCamera(run, 'stop');
    final releaseWait = _mono.elapsed - tRelease;

    // 3. In-flight detection, bounded.
    var waited = Duration.zero;
    var timedOut = false;
    if (pendingDetection != null) {
      final t0 = _mono.elapsed;
      timedOut = !await _awaitWithTimeout(pendingDetection.future, stopInferenceTimeout);
      waited = _mono.elapsed - t0;
    }
    _lastStop = SeatStopReport(
      reason: reason,
      generation: generation,
      hadInFlight: hadInFlight,
      inferenceWait: waited,
      inferenceTimedOut: timedOut,
      cameraReleaseWait: releaseWait,
      cameraReleaseTimedOut: releaseTimedOut,
      suppressedResults: _gate.suppressed,
      stalledDetections: stalledDetections,
    );
    appLog.d(
      'seat engine: stopped (${reason.name}) gen=$generation '
      'release=${releaseWait.inMilliseconds}ms${releaseTimedOut ? ' (timed out)' : ''} '
      'inFlight=$hadInFlight waited=${waited.inMilliseconds}ms timedOut=$timedOut '
      'stalled=$stalledDetections',
    );
  }

  /// Releases the run's camera (if it has one), waiting at most
  /// [stopReleaseTimeout]. `false` when the release is still running in the
  /// background.
  Future<bool> _closeRunCamera(_Run run, String why) {
    final handle = run.camera;
    run.camera = null;
    if (handle == null) return Future<bool>.value(true);
    return _closeHandleBounded(handle, why);
  }

  /// Closes one camera handle — that session only — with a bound.
  Future<bool> _closeHandleBounded(SeatCameraHandle handle, String why) {
    final close = handle.close().then(
          (_) {},
          onError: (Object e, StackTrace st) =>
              appLog.w('seat engine: camera close failed ($why)', error: e, stackTrace: st),
        );
    return _awaitWithTimeout(close, stopReleaseTimeout).then((ok) {
      if (!ok) {
        appLog.w('seat engine: camera release still pending after ${stopReleaseTimeout.inMilliseconds}ms ($why)');
      }
      return ok;
    });
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

  /// Stops, then retires the detector — it is closed at once when idle,
  /// otherwise by its returning call. Never while a detection is running.
  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    await _stop(SeatEngineStopReason.disposed);
    _retireActive('disposed');
    await _samples.close();
    await _events.close();
    await _diagnostics.close();
  }

  // ── Detectors (S04d §2) ─────────────────────────────────────────────────

  _DetectorSlot _newDetectorSlot() => _DetectorSlot(++_detectorSeq, _detectorFactory());

  /// The detector the next frame goes to. A retired detector is replaced by
  /// a fresh one unless [stalledDetectionLimit] retired detectors are still
  /// hanging — then `null`: no decision is possible until one returns.
  _DetectorSlot? _detectorForWork() {
    final a = _active;
    if (a != null && !a.retired) return a;
    if (_disposed || stalledDetections >= stalledDetectionLimit) return null;
    final slot = _newDetectorSlot();
    _active = slot;
    _detectorReplacements++;
    appLog.d('seat engine: detector #${slot.id} created (stalled=$stalledDetections)');
    return slot;
  }

  /// Nothing more is submitted to the active detector. It is closed now when
  /// idle, otherwise by the call that is still running on it.
  void _retireActive(String why) {
    final a = _active;
    if (a == null || a.retired) return;
    a.retired = true;
    _active = null;
    if (a.pending > 0) {
      _retired.add(a);
      appLog.w('seat engine: detector #${a.id} retired ($why), ${a.pending} call(s) still running');
    } else {
      _closeSlot(a);
    }
  }

  /// A call on [slot] returned.
  void _settleSlot(_DetectorSlot slot) {
    if (!slot.retired || slot.pending > 0 || slot.closed) return;
    _retired.remove(slot);
    _closeSlot(slot);
  }

  void _closeSlot(_DetectorSlot slot) {
    if (slot.closed) return;
    slot.closed = true;
    unawaited(_closeDetectorQuietly(slot));
  }

  Future<void> _closeDetectorQuietly(_DetectorSlot slot) async {
    try {
      await slot.detector.close();
    } catch (e, st) {
      appLog.w('seat engine: detector #${slot.id} close failed', error: e, stackTrace: st);
    }
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
    final slot = _detectorForWork();
    if (slot == null) return; // no detector left: frames arrive, nothing can be decided
    if (_lost) {
      _lost = false;
      _lastLostReason = null;
      _detectorFailures = 0;
      _detectorErrorReported = false;
      _events.add(const SeatCameraRecovered());
    }
    if (!_cadence.accept(capturedAt)) return;
    final ticket = _gate.begin(capturedAt);
    if (ticket == null) {
      _cadence.release();
      return;
    }
    final done = Completer<void>();
    _inFlightDone = done;
    _physicalInFlight++;
    slot.pending++;
    unawaited(_process(frame, ticket, slot, capturedWall, done));
  }

  Future<void> _process(
    SeatFrame frame,
    InferenceTicket ticket,
    _DetectorSlot slot,
    DateTime capturedWall,
    Completer<void> done,
  ) async {
    bool? detected;
    Object? error;
    StackTrace? stack;
    try {
      detected = await slot.detector.detect(frame);
    } catch (e, st) {
      error = e;
      stack = st;
    }
    slot.pending--;
    _physicalInFlight--;
    // Only the detection that still owns the slot frees the cadence; an
    // expired or invalidated one already did.
    final ownsSlot = identical(_gate.current, ticket);
    final current = _gate.end(ticket);
    if (ownsSlot) _cadence.release();
    final completedAt = _mono.elapsed;
    done.complete();
    _settleSlot(slot);
    // Publish only when the run, the epoch and the stream are all still the
    // ones this frame came from (S04c §1).
    if (!current || _lost || !_running) return;
    if (error != null) {
      _onDetectorFailure(error, stack!);
      return;
    }
    _detectorFailures = 0;
    _detectorErrorReported = false;
    final capturedAt = ticket.startedAt;
    final seated = _hysteresis.observe(at: capturedAt, detected: detected!);
    final sinceStart = capturedAt - _runStartMono;
    _samples.add(
      SeatSample(receivedAt: capturedWall, sinceStart: sinceStart, seated: seated),
    );
    if (_diagnostics.hasListener) {
      _diagnostics.add(
        SeatDiagnostic(
          capturedAt: capturedAt,
          completedAt: completedAt,
          capturedWall: capturedWall,
          sinceStart: sinceStart,
          generation: ticket.generation,
          detected: detected,
          seated: seated,
          held: seated && !detected,
        ),
      );
    }
  }

  void _onDetectorFailure(Object e, StackTrace st) {
    _detectorFailures++;
    // Message only — never the frame.
    appLog.w('seat engine: detector failed (${_detectorFailures}x)', error: e, stackTrace: st);
    if (_detectorFailures >= detectorFailureLimit) _reportDetectorFailed();
  }

  void _reportDetectorFailed() {
    if (_detectorErrorReported) return;
    _detectorErrorReported = true;
    _events.add(const SeatError(SeatErrorCode.detectorFailed));
  }

  // ── Camera health ───────────────────────────────────────────────────────

  void _watchdogTick() {
    if (!_running) return;
    final now = _mono.elapsed;
    // S04c §3b · S04d §2: a detection that never returns must not block the
    // cadence; its detector is retired and replaced.
    final expired = _gate.expireIfOverdue(now);
    if (expired != null) {
      _cadence.release();
      appLog.w('seat engine: inference overdue (${(now - expired.startedAt).inMilliseconds}ms) — detector retired');
      _retireActive('inference deadline');
      if (_detectorForWork() == null) {
        _reportDetectorFailed();
        _markLost(SeatLostReason.detectorExhausted);
      }
    }
    if (!_lost && now - _lastFrameAt > frameTimeout) _markLost(SeatLostReason.frameTimeout);
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

  /// Camera lost: the detection in flight (if any) is invalidated — nothing
  /// decided on a stalled stream is published (S04c §1).
  void _markLost(String why) {
    if (_lost) return;
    _lost = true;
    _lastLostReason = why;
    if (_gate.invalidate()) _cadence.release();
    appLog.d('seat engine: camera lost ($why)');
    _events.add(const SeatCameraLost());
  }

  // ── Lifecycle ───────────────────────────────────────────────────────────

  void _onLifecycle(AppLifecycleState state) {
    if (!isBackgroundState(state)) return;
    if (_running) {
      unawaited(_onBackground());
      return;
    }
    final run = _run;
    if (run != null && _starting != null && !run.cancelled) {
      run.background = true; // start() re-checks after the open
    }
  }

  /// Background: release the camera at once (no stream without a foreground
  /// activity) and tell the caller. Restarting on resume is S06's job.
  Future<void> _onBackground() async {
    if (!_running) return;
    _lost = true; // no more samples; the next run's first frame reports a recovery
    _lastLostReason = SeatPauseReason.background.name;
    if (_gate.invalidate()) _cadence.release();
    appLog.d('seat engine: paused (background)');
    _events.add(const SeatPaused(SeatPauseReason.background));
    await _stop(SeatEngineStopReason.background);
  }
}
