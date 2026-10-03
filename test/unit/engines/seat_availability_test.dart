import 'package:flutter/services.dart' show DeviceOrientation;
import 'package:flutter_test/flutter_test.dart';
import 'package:soongong/core/contracts/seat_engine.dart';
import 'package:soongong/data/engines/seat/camera_geometry.dart';
import 'package:soongong/data/engines/seat/seat_availability.dart';

void main() {
  group('mapSeatAvailability', () {
    test('permission first', () {
      for (final p in <CameraPermissionResult>[
        CameraPermissionResult.denied,
        CameraPermissionResult.permanentlyDenied,
        CameraPermissionResult.restricted,
      ]) {
        expect(
          mapSeatAvailability(permission: p, probe: null),
          SeatAvailability.permissionDenied,
        );
        expect(
          mapSeatAvailability(permission: p, probe: CameraProbeResult.busy),
          SeatAvailability.permissionDenied,
        );
      }
    });

    test('probe mapping when granted', () {
      const g = CameraPermissionResult.granted;
      expect(mapSeatAvailability(permission: g, probe: CameraProbeResult.ok), SeatAvailability.ok);
      expect(mapSeatAvailability(permission: g, probe: null), SeatAvailability.ok);
      expect(
        mapSeatAvailability(permission: g, probe: CameraProbeResult.busy),
        SeatAvailability.cameraBusy,
      );
      expect(
        mapSeatAvailability(permission: g, probe: CameraProbeResult.noCamera),
        SeatAvailability.unavailable,
      );
      expect(
        mapSeatAvailability(permission: g, probe: CameraProbeResult.failed),
        SeatAvailability.unavailable,
      );
      expect(
        mapSeatAvailability(permission: g, probe: CameraProbeResult.permissionDenied),
        SeatAvailability.permissionDenied,
      );
    });

    test('needsSettings', () {
      expect(CameraPermissionResult.denied.needsSettings, isFalse);
      expect(CameraPermissionResult.granted.needsSettings, isFalse);
      expect(CameraPermissionResult.permanentlyDenied.needsSettings, isTrue);
      expect(CameraPermissionResult.restricted.needsSettings, isTrue);
    });
  });

  group('classifyCameraFault (camera_android_camerax descriptions)', () {
    test('in use / max cameras → inUse', () {
      expect(
        classifyCameraFault(
          'The camera was already in use, possibly by a higher-priority camera client.',
        ),
        CameraFault.inUse,
      );
      expect(
        classifyCameraFault(
          'The limit number of open cameras has been reached, and more cameras cannot be opened until other instances are closed.',
        ),
        CameraFault.inUse,
      );
    });

    test('policy / DND → disabled, fatal → fatal, recoverable → recoverable', () {
      expect(
        classifyCameraFault('The camera device could not be opened due to a device policy.'),
        CameraFault.disabled,
      );
      expect(
        classifyCameraFault(
          'The camera could not be opened because "Do Not Disturb" mode is enabled.',
        ),
        CameraFault.disabled,
      );
      expect(
        classifyCameraFault('The camera was closed due to a fatal error.'),
        CameraFault.fatal,
      );
      expect(
        classifyCameraFault(
          'The camera device has encountered a recoverable error. CameraX will attempt to recover from the error.',
        ),
        CameraFault.recoverable,
      );
      expect(classifyCameraFault('Configuring the camera has failed.'), CameraFault.unknown);
    });
  });

  test('probeResultForExceptionCode', () {
    for (final code in <String>[
      'CameraAccessDenied',
      'CameraAccessDeniedWithoutPrompt',
      'CameraAccessRestricted',
      'cameraPermission',
    ]) {
      expect(probeResultForExceptionCode(code), CameraProbeResult.permissionDenied);
    }
    expect(probeResultForExceptionCode('CameraPermissionsRequestOngoing'), CameraProbeResult.failed);
    expect(probeResultForExceptionCode('anything'), CameraProbeResult.failed);
  });

  group('inputRotationDegrees', () {
    test('iOS: sensor orientation as-is', () {
      expect(
        inputRotationDegrees(
          sensorOrientation: 90,
          deviceOrientation: DeviceOrientation.landscapeLeft,
          frontFacing: true,
          isIOS: true,
        ),
        90,
      );
    });

    test('Android front camera (sensor 270) in portrait → 270, landscapeLeft → 0', () {
      expect(
        inputRotationDegrees(
          sensorOrientation: 270,
          deviceOrientation: DeviceOrientation.portraitUp,
          frontFacing: true,
          isIOS: false,
        ),
        270,
      );
      expect(
        inputRotationDegrees(
          sensorOrientation: 270,
          deviceOrientation: DeviceOrientation.landscapeLeft,
          frontFacing: true,
          isIOS: false,
        ),
        0,
      );
    });

    test('Android back camera (sensor 90) in portrait → 90, landscapeLeft → 0', () {
      expect(
        inputRotationDegrees(
          sensorOrientation: 90,
          deviceOrientation: DeviceOrientation.portraitUp,
          frontFacing: false,
          isIOS: false,
        ),
        90,
      );
      expect(
        inputRotationDegrees(
          sensorOrientation: 90,
          deviceOrientation: DeviceOrientation.landscapeLeft,
          frontFacing: false,
          isIOS: false,
        ),
        0,
      );
      expect(
        inputRotationDegrees(
          sensorOrientation: 90,
          deviceOrientation: DeviceOrientation.landscapeRight,
          frontFacing: false,
          isIOS: false,
        ),
        180,
      );
    });

    test('deviceRotationDegrees covers every orientation', () {
      expect(deviceRotationDegrees(DeviceOrientation.portraitUp), 0);
      expect(deviceRotationDegrees(DeviceOrientation.landscapeLeft), 90);
      expect(deviceRotationDegrees(DeviceOrientation.portraitDown), 180);
      expect(deviceRotationDegrees(DeviceOrientation.landscapeRight), 270);
    });
  });
}
