// Camera abstraction for the seat engine (S04). The engine never touches the
// camera plugin directly: a [SeatFrameSource] delivers opaque [SeatFrame]s
// through a synchronous callback and a [PresenceDetector] answers "is a
// person in this frame?". Tests inject fakes for both.
//
// A frame is valid only inside the callback and the detection it starts.
// Nothing may keep a reference to it afterwards (CLAUDE.md §9: frames are
// never stored, copied to disk or transmitted).
//
// S04d: `open()` returns a [SeatCameraHandle] that owns exactly the camera
// session it opened. The engine keeps one handle per run, so a camera that
// finishes opening late (after its run timed out or was stopped) is released
// through its own handle and never touches the run that replaced it.
//
// S04e: `close()` reports how the release went ([CloseResult]): a platform
// dispose that threw or did not finish in time is a result the engine and
// the lab can see, not something swallowed in a log line.

import 'package:flutter/foundation.dart' show immutable;
import 'package:flutter/widgets.dart' show AppLifecycleState;

import 'seat_availability.dart';

/// Opaque frame handle. Concrete sources subclass it; detectors downcast.
abstract class SeatFrame {
  const SeatFrame();
}

class SeatFrameSourceConfig {
  const SeatFrameSourceConfig({required this.lowPower});

  final bool lowPower;

  /// Target camera frame rate requested from the platform (best effort).
  /// The engine processes far fewer frames than this (see FrameCadence); a
  /// lower sensor rate only saves power.
  int get targetFps => lowPower ? lowPowerFps : normalFps;

  static const int normalFps = 15;
  static const int lowPowerFps = 10;
}

/// Thrown by [SeatFrameSource.open]. [code] is stable and surfaces as
/// `SeatError(code)`: `permission_denied` · `no_camera` · `camera_busy` ·
/// `camera_init_failed`.
class SeatFrameSourceException implements Exception {
  const SeatFrameSourceException(this.code, [this.detail]);

  final String code;
  final String? detail;

  @override
  String toString() => 'SeatFrameSourceException($code${detail == null ? '' : ': $detail'})';
}

typedef SeatFrameCallback = void Function(SeatFrame frame);

/// Platform fault while the source is open (error description from the
/// camera plugin, already free of frame data).
typedef SeatFaultCallback = void Function(CameraFault fault, String description);

enum CloseOutcome { ok, failed, timeout }

/// How a camera session's release ended (S04e §3).
@immutable
class CloseResult {
  const CloseResult.ok()
      : outcome = CloseOutcome.ok,
        error = null,
        stackTrace = null,
        waited = null;

  /// The platform release threw [error]; the camera may still be held.
  const CloseResult.failed(Object this.error, [this.stackTrace])
      : outcome = CloseOutcome.failed,
        waited = null;

  /// The release had not finished after [waited]; it continues in the
  /// background.
  const CloseResult.timeout(Duration this.waited)
      : outcome = CloseOutcome.timeout,
        error = null,
        stackTrace = null;

  final CloseOutcome outcome;
  final Object? error;
  final StackTrace? stackTrace;
  final Duration? waited;

  bool get isOk => outcome == CloseOutcome.ok;

  @override
  String toString() => switch (outcome) {
        CloseOutcome.ok => 'CloseResult.ok',
        CloseOutcome.failed => 'CloseResult.failed($error)',
        CloseOutcome.timeout => 'CloseResult.timeout(${waited!.inMilliseconds}ms)',
      };
}

/// One opened camera session (S04d). Closing it releases the resources of
/// this session only; a session opened later is unaffected.
abstract class SeatCameraHandle {
  /// Stops the stream and releases this session's camera. Idempotent: a
  /// second call answers `ok` without doing anything. Never throws — a
  /// failing or overdue release is reported in the result (S04e §3).
  Future<CloseResult> close();

  /// `false` once [close] was called.
  bool get isOpen;
}

abstract class SeatFrameSource {
  /// Opens the camera briefly without streaming to classify hardware / busy
  /// state, then releases it. Never prompts for permission.
  Future<CameraProbeResult> probe();

  /// Opens the camera and starts delivering frames to [onFrame]. Returns the
  /// handle that owns this session. Throws [SeatFrameSourceException] when
  /// the camera cannot be opened.
  Future<SeatCameraHandle> open(
    SeatFrameSourceConfig config, {
    required SeatFrameCallback onFrame,
    required SeatFaultCallback onFault,
  });
}

abstract class PresenceDetector {
  /// `true` when a person is present in [frame]. Implementations must not
  /// retain [frame] after the returned future completes.
  Future<bool> detect(SeatFrame frame);

  Future<void> close();
}

/// Builds a fresh detector. The engine replaces a detector that stopped
/// answering (S04d §2), so it needs a factory rather than one instance.
typedef PresenceDetectorFactory = PresenceDetector Function();

/// Permission gateway (production: `permission_handler`).
abstract class CameraPermissionGateway {
  /// Current state without prompting.
  Future<CameraPermissionResult> status();

  /// Prompts when the OS still allows it; otherwise returns the current state.
  Future<CameraPermissionResult> request();

  /// Opens the OS app-settings screen. `false` when it could not be opened.
  Future<bool> openSettings();
}

/// App lifecycle feed. Production wraps `WidgetsBinding`; tests use a stream.
abstract class LifecycleSource {
  Stream<AppLifecycleState> get states;

  /// Current state when known (`null` before the first transition).
  AppLifecycleState? get current;
}

/// `true` for the states in which the engine must not hold the camera.
bool isBackgroundState(AppLifecycleState? state) => switch (state) {
      AppLifecycleState.hidden ||
      AppLifecycleState.paused ||
      AppLifecycleState.detached =>
        true,
      AppLifecycleState.resumed || AppLifecycleState.inactive || null => false,
    };
