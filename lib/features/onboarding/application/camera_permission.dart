// CameraPermission (S05, onboarding step 3): a seam over permission_handler
// so the onboarding screen can be tested without a platform channel. Denial
// never blocks onboarding (PRD 4.4: 거부하면 수동 타이머로 시작).

import 'package:permission_handler/permission_handler.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'camera_permission.g.dart';

enum CameraPermissionResult { granted, denied, permanentlyDenied }

abstract class CameraPermission {
  Future<CameraPermissionResult> request();
}

class SystemCameraPermission implements CameraPermission {
  const SystemCameraPermission();

  @override
  Future<CameraPermissionResult> request() async {
    final status = await Permission.camera.request();
    if (status.isGranted || status.isLimited) return CameraPermissionResult.granted;
    if (status.isPermanentlyDenied || status.isRestricted) {
      return CameraPermissionResult.permanentlyDenied;
    }
    return CameraPermissionResult.denied;
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
