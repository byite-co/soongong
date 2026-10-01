// SeatEngineImpl (S04): the S01 `SeatEngine` contract on a real camera.
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

/// Stable `SeatError.message` codes.
abstract final class SeatErrorCode {
  static const String permissionDenied = 'permission_denied';
  static const String noCamera = 'no_camera';
  static const String cameraBusy = 'camera_busy';
  static const String cameraInitFailed = 'camera_init_failed';
  static const String detectorFailed = 'detector_failed';
}

/// Why the engine stopped on its own (diagnostics only).
enum SeatEngineStopReason { caller, background, disposed }

/// Per-processed-frame diagnostics for the `/_seat_lab` harness. Not part of
/// the contract; S06 must not depend on it.
@immutable
class SeatDiagnostic {
  const SeatDiagnostic({
    required this.at,
    required this.detected,
    required this.seated,
    required this.held,
    required this.latency,
  });

  /// Monotonic time of the frame.
  final Duration at;

  /// Raw detector answer for this frame.
  final bool detected;

  /// Engine output (after the hold window).
  final bool seated;

  /// `seated` only because of the hold window.
  final bool held;

  /// Detector round-trip.
  final Duration latency;
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
  })  : _mono = monotonic ?? StopwatchMonotonicClock(),
        _hysteresis = SeatHysteresis(hold: hold);

  /// Production wiring: front camera + ML Kit face presence +
  /// permission_handler + WidgetsBinding lifecycle.
  factory SeatEngineImpl.camera({
    double minFaceSize = MlKitFacePresenceDetector.defaultMinFaceSize,
  }) =>
      SeatEngineImpl(
        source: CameraFrameSource(),
        detector: MlKitFacePresenceDetector(minFaceSize: minFaceSize),
        permission: const PermissionHandlerCameraGateway(),
        lifecycle: WidgetsBindingLifecycleSource(),
      );

  /// No frame for this long while running → `SeatCameraLost`.
  static const Duration defaultFrameTimeout = Duration(seconds: 3);

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

  final StreamController<SeatSample> _samples =
      StreamController<SeatSample>.broadcast();
  final StreamController<SeatEngineEvent> _events =
      StreamController<SeatEngineEvent>.broadcast();
  final StreamController<SeatDiagnostic> _diagnostics =
      StreamController<SeatDiagnostic>.broadcast();

  FrameCadence _cadence = FrameCadence(interval: const Duration(seconds: 1));
  SeatEngineConfig? _config;
  Future<void>? _starting;
  Timer? _watchdog;
  StreamSubscription<AppLifecycleState>? _lifecycleSub;
  bool _running = false;
  bool _lost = false;
  bool _disposed = false;
  Duration _lastFrameAt = Duration.zero;
  int _framesDelivered = 0;
  int _detectorFailures = 0;
  bool _detectorErrorReported = false;
  SeatEngineStopReason? _lastStopReason;
  String? _lastFault;

  // ── Diagnostics (lab only) ──────────────────────────────────────────────

  bool get isRunning => _running;

  /// A `SeatCameraLost` was emitted and no frame has arrived since.
  bool get isLost => _lost;

  SeatEngineConfig? get config => _config;

  /// Frames the camera delivered since the last `start` (processed + dropped).
  int get framesDelivered => _framesDelivered;

  int get framesProcessed => _cadence.accepted;

  int get framesDropped => _cadence.dropped;

  Duration get processingInterval => _cadence.interval;

  SeatEngineStopReason? get lastStopReason => _lastStopReason;

  /// Last camera fault description (plugin text, no frame data).
  String? get lastFault => _lastFault;

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
    try {
      await _source.open(
        SeatFrameSourceConfig(lowPower: config.lowPower),
        onFrame: _onFrame,
        onFault: _onFault,
      );
    } on SeatFrameSourceException catch (e) {
      appLog.w('seat engine: camera open failed (${e.code})');
      _events.add(SeatError(e.code));
      return;
    } catch (e, st) {
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
      'seat engine: started · interval=${_cadence.interval.inMilliseconds}ms '
      'lowPower=${config.lowPower}',
    );
  }

  @override
  Future<void> stop() => _stop(SeatEngineStopReason.caller);

  Future<void> _stop(SeatEngineStopReason reason) async {
    final pending = _starting;
    if (pending != null) await pending;
    if (!_running && !_source.isOpen) return;
    _running = false;
    _lastStopReason = reason;
    _watchdog?.cancel();
    _watchdog = null;
    // Not awaited: a broadcast subscription's cancel future completes in the
    // root zone, which would stall the rest of this method under fake_async.
    final lifecycleSub = _lifecycleSub;
    _lifecycleSub = null;
    if (lifecycleSub != null) unawaited(lifecycleSub.cancel());
    try {
      await _source.close();
    } catch (e, st) {
      appLog.w('seat engine: camera close failed', error: e, stackTrace: st);
    }
    appLog.d('seat engine: stopped (${reason.name})');
  }

  @override
  Stream<SeatSample> get samples => _samples.stream;

  @override
  Stream<SeatEngineEvent> get events => _events.stream;

  /// The measurement screen shows a status icon, never a preview (§4.2).
  @override
  Widget? previewOrNull() => null;

  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    await _stop(SeatEngineStopReason.disposed);
    await _detector.close();
    await _samples.close();
    await _events.close();
    await _diagnostics.close();
  }

  // ── Frames ──────────────────────────────────────────────────────────────

  /// Camera callback. Runs synchronously; the frame is either handed to the
  /// detector right away or dropped — it is never stored.
  void _onFrame(SeatFrame frame) {
    if (!_running) return;
    final now = _mono.elapsed;
    _lastFrameAt = now;
    _framesDelivered++;
    if (_lost) {
      _lost = false;
      _events.add(const SeatCameraRecovered());
    }
    if (!_cadence.accept(now)) return;
    unawaited(_process(frame, now));
  }

  Future<void> _process(SeatFrame frame, Duration at) async {
    bool detected;
    try {
      detected = await _detector.detect(frame);
    } catch (e, st) {
      _cadence.release();
      _onDetectorFailure(e, st);
      return;
    }
    _cadence.release();
    _detectorFailures = 0;
    _detectorErrorReported = false;
    if (!_running) return;
    final seated = _hysteresis.observe(at: at, detected: detected);
    _samples.add(SeatSample(at: _clock.now(), seated: seated));
    if (_diagnostics.hasListener) {
      _diagnostics.add(
        SeatDiagnostic(
          at: at,
          detected: detected,
          seated: seated,
          held: seated && !detected,
          latency: _mono.elapsed - at,
        ),
      );
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

  void _onFault(CameraFault fault, String description) {
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
