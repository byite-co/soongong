// MlKitFacePresenceDetector (S04): google_mlkit_face_detection in fast mode
// with landmarks · classification · contours · tracking all OFF. The only
// thing read from the result is whether the list of faces is non-empty.
// Bounding boxes, landmarks and angles are never read, logged, stored or
// transmitted (instruction §6; CLAUDE.md §9).

import 'dart:ui' show Size;

import 'package:camera/camera.dart' show CameraImage;
import 'package:flutter/foundation.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

import 'camera_frame_source.dart';
import 'seat_frame_source.dart';

class SeatDetectorException implements Exception {
  const SeatDetectorException(this.code);

  final String code;

  @override
  String toString() => 'SeatDetectorException($code)';
}

class MlKitFacePresenceDetector implements PresenceDetector {
  MlKitFacePresenceDetector({this.minFaceSize = defaultMinFaceSize})
      : _detector = FaceDetector(
          options: FaceDetectorOptions(
            performanceMode: FaceDetectorMode.fast,
            minFaceSize: minFaceSize,
            // Presence only — every extra classifier stays off.
            enableLandmarks: false,
            enableClassification: false,
            enableContours: false,
            enableTracking: false,
          ),
        );

  /// ML Kit default: head width ≥ 10 % of the frame width. A seated user at
  /// 50–80 cm fills 15–25 % of a 320 px frame; the lab lets QA try 0.15 /
  /// 0.20 against the poster / photo negatives.
  static const double defaultMinFaceSize = 0.1;

  final double minFaceSize;
  final FaceDetector _detector;

  @override
  Future<bool> detect(SeatFrame frame) async {
    if (frame is! CameraSeatFrame) {
      throw const SeatDetectorException('unsupported_frame');
    }
    final input = inputImageFromCamera(frame.image, frame.rotationDegrees);
    if (input == null) throw const SeatDetectorException('unsupported_format');
    final faces = await _detector.processImage(input);
    return faces.isNotEmpty;
  }

  @override
  Future<void> close() => _detector.close();
}

/// Wraps a streamed [CameraImage] for ML Kit without copying. Only the
/// single-plane formats the source asks for are accepted (NV21 on Android,
/// BGRA8888 on iOS); anything else returns `null`.
@visibleForTesting
InputImage? inputImageFromCamera(CameraImage image, int rotationDegrees) {
  final rotation = InputImageRotationValue.fromRawValue(rotationDegrees);
  if (rotation == null) return null;
  final raw = image.format.raw;
  if (raw is! int) return null;
  final format = InputImageFormatValue.fromRawValue(raw);
  if (format == null) return null;
  final android = defaultTargetPlatform == TargetPlatform.android;
  if (android && format != InputImageFormat.nv21) return null;
  if (!android && format != InputImageFormat.bgra8888) return null;
  if (image.planes.length != 1) return null;
  final plane = image.planes.first;
  return InputImage.fromBytes(
    bytes: plane.bytes,
    metadata: InputImageMetadata(
      size: Size(image.width.toDouble(), image.height.toDouble()),
      rotation: rotation,
      format: format,
      bytesPerRow: plane.bytesPerRow,
    ),
  );
}
