// Availability mapping (S04, pure Dart). Permission state × camera probe
// → the contract's [SeatAvailability] (권한 거부 / 카메라 점유 / 하드웨어 없음).

import '../../../core/contracts/seat_engine.dart';

/// Camera permission as seen through the permission gateway
/// (`permission_handler` in production).
enum CameraPermissionResult {
  granted,

  /// Denied, the system may still prompt again.
  denied,

  /// Denied for good — only the OS settings screen can change it.
  permanentlyDenied,

  /// Blocked by a device policy / parental control (iOS `restricted`).
  restricted,
}

extension CameraPermissionResultX on CameraPermissionResult {
  bool get isGranted => this == CameraPermissionResult.granted;

  /// The prompt cannot help; the user has to open the OS settings.
  bool get needsSettings =>
      this == CameraPermissionResult.permanentlyDenied ||
      this == CameraPermissionResult.restricted;
}

/// Result of opening the camera briefly without streaming.
enum CameraProbeResult {
  ok,

  /// No camera hardware at all (simulators, some tablets).
  noCamera,

  /// Another (higher-priority) client holds the camera.
  busy,

  /// The OS denied access at open time (the gateway said granted, but the
  /// camera plugin disagreed — treated as a permission problem).
  permissionDenied,

  /// Any other failure (fatal hardware error, device policy, timeout).
  failed,
}

/// Coarse classification of a camera plugin error description.
enum CameraFault { inUse, disabled, fatal, recoverable, unknown }

/// Classifies the free-text error descriptions emitted by
/// `camera_android_camerax` (CameraState errors) and `camera_avfoundation`.
/// The strings are plugin-version dependent; unknown text maps to
/// [CameraFault.unknown], which the engine treats like a stalled stream (the
/// frame watchdog decides).
CameraFault classifyCameraFault(String description) {
  final d = description.toLowerCase();
  if (d.contains('in use') || d.contains('limit number of open cameras')) {
    return CameraFault.inUse;
  }
  if (d.contains('device policy') ||
      d.contains('do not disturb') ||
      d.contains('disabled')) {
    return CameraFault.disabled;
  }
  if (d.contains('fatal')) return CameraFault.fatal;
  if (d.contains('recoverable')) return CameraFault.recoverable;
  return CameraFault.unknown;
}

/// Maps a camera exception code (`CameraException.code`) raised while opening
/// the camera. Android (camerax) and iOS (avfoundation) codes are covered.
CameraProbeResult probeResultForExceptionCode(String code) {
  switch (code) {
    case 'CameraAccessDenied':
    case 'CameraAccessDeniedWithoutPrompt':
    case 'CameraAccessRestricted':
    case 'cameraPermission':
      return CameraProbeResult.permissionDenied;
    case 'CameraPermissionsRequestOngoing':
      return CameraProbeResult.failed;
    default:
      return CameraProbeResult.failed;
  }
}

/// Permission first, then hardware/busy. [probe] is `null` when the probe
/// was skipped because permission is missing.
SeatAvailability mapSeatAvailability({
  required CameraPermissionResult permission,
  required CameraProbeResult? probe,
}) {
  if (!permission.isGranted) return SeatAvailability.permissionDenied;
  return switch (probe) {
    null || CameraProbeResult.ok => SeatAvailability.ok,
    CameraProbeResult.busy => SeatAvailability.cameraBusy,
    CameraProbeResult.permissionDenied => SeatAvailability.permissionDenied,
    CameraProbeResult.noCamera ||
    CameraProbeResult.failed =>
      SeatAvailability.unavailable,
  };
}
