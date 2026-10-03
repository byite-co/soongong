// Camera geometry helpers (S04, pure Dart). ML Kit needs the image rotation
// relative to the upright device; the recipe follows the google_mlkit
// example (sensor orientation ± device orientation, mirrored for the front
// camera on Android, sensor orientation alone on iOS).

import 'package:flutter/services.dart' show DeviceOrientation;

/// Degrees the device is rotated from portrait-up, per [DeviceOrientation].
int deviceRotationDegrees(DeviceOrientation orientation) => switch (orientation) {
      DeviceOrientation.portraitUp => 0,
      DeviceOrientation.landscapeLeft => 90,
      DeviceOrientation.portraitDown => 180,
      DeviceOrientation.landscapeRight => 270,
    };

/// Rotation (0 · 90 · 180 · 270) to apply to a streamed frame so that faces
/// are upright for the detector.
int inputRotationDegrees({
  required int sensorOrientation,
  required DeviceOrientation deviceOrientation,
  required bool frontFacing,
  required bool isIOS,
}) {
  if (isIOS) return _normalize(sensorOrientation);
  final device = deviceRotationDegrees(deviceOrientation);
  if (frontFacing) return _normalize(sensorOrientation + device);
  return _normalize(sensorOrientation - device + 360);
}

int _normalize(int degrees) {
  final d = degrees % 360;
  return d < 0 ? d + 360 : d;
}
