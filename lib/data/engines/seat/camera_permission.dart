// Camera permission flow helper (S04 §4.4). `CameraPermission.request()` is
// what onboarding / setupOn call before starting the engine; `setupDen` uses
// `needsSettings` + `openSettings()`.
//
// Platform notes (permission_handler 12.x):
//   * iOS reports a not-yet-asked permission as `denied`; `request()` shows
//     the prompt once, afterwards the state is `permanentlyDenied`.
//   * Android: a permanent denial is only reliably visible in the result of
//     `request()`.
//   * Info.plist carries NSCameraUsageDescription; with Swift Package
//     Manager permission_handler_apple compiles the camera strategy in
//     because that key is present (no Podfile macro needed).

import 'package:permission_handler/permission_handler.dart';

import 'seat_availability.dart';
import 'seat_frame_source.dart';

export 'seat_availability.dart' show CameraPermissionResult, CameraPermissionResultX;

class PermissionHandlerCameraGateway implements CameraPermissionGateway {
  const PermissionHandlerCameraGateway();

  @override
  Future<CameraPermissionResult> status() async =>
      _map(await Permission.camera.status);

  @override
  Future<CameraPermissionResult> request() async =>
      _map(await Permission.camera.request());

  @override
  Future<bool> openSettings() => openAppSettings();

  static CameraPermissionResult _map(PermissionStatus s) => switch (s) {
        PermissionStatus.granted ||
        PermissionStatus.limited ||
        PermissionStatus.provisional =>
          CameraPermissionResult.granted,
        PermissionStatus.permanentlyDenied =>
          CameraPermissionResult.permanentlyDenied,
        PermissionStatus.restricted => CameraPermissionResult.restricted,
        PermissionStatus.denied => CameraPermissionResult.denied,
      };
}

/// Static convenience over a swappable gateway (tests replace [gateway]).
abstract final class CameraPermission {
  static CameraPermissionGateway gateway = const PermissionHandlerCameraGateway();

  /// Current state without prompting.
  static Future<CameraPermissionResult> status() => gateway.status();

  /// Prompts when the OS still allows it. Returns the resulting state; when
  /// [CameraPermissionResultX.needsSettings] the UI offers [openSettings].
  static Future<CameraPermissionResult> request() => gateway.request();

  static Future<bool> openSettings() => gateway.openSettings();
}
