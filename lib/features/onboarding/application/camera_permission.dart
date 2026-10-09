// CameraPermission (S05, onboarding step 3): a seam so the onboarding screen
// can be tested without a platform channel. Denial never blocks onboarding
// (PRD 4.4: 거부하면 수동 타이머로 시작).
//
// The system implementation delegates to S04's `CameraPermission` gateway
// (`data/engines/seat/camera_permission.dart`), the single place that talks to
// permission_handler, so onboarding and setupOn see the same prompt rules.

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../data/engines/seat/camera_permission.dart' as seat;

part 'camera_permission.g.dart';

enum CameraPermissionResult { granted, denied, permanentlyDenied }

abstract class CameraPermission {
  Future<CameraPermissionResult> request();
}

class SystemCameraPermission implements CameraPermission {
  const SystemCameraPermission();

  @override
  Future<CameraPermissionResult> request() async {
    final result = await seat.CameraPermission.request();
    return switch (result) {
      seat.CameraPermissionResult.granted => CameraPermissionResult.granted,
      seat.CameraPermissionResult.permanentlyDenied ||
      seat.CameraPermissionResult.restricted =>
        CameraPermissionResult.permanentlyDenied,
      seat.CameraPermissionResult.denied => CameraPermissionResult.denied,
    };
  }
}

class FakeCameraPermission implements CameraPermission {
  FakeCameraPermission([this.result = CameraPermissionResult.granted]);

  CameraPermissionResult result;
  int calls = 0;

  @override
  Future<CameraPermissionResult> request() async {
    calls++;
    return result;
  }
}

@Riverpod(keepAlive: true)
CameraPermission cameraPermission(Ref ref) => const SystemCameraPermission();
