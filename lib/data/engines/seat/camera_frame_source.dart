// CameraFrameSource (S04): `camera` plugin → [SeatFrameSource].
//
// Front camera, lowest resolution preset (320×240 on Android, 352×288 on
// iOS), no audio, single-plane stream format (NV21 on Android, BGRA on iOS)
// so the detector gets the bytes without conversion. Frames are forwarded
// synchronously from the plugin callback and never retained here.

import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';

import '../../../core/logging/app_logger.dart';
import 'camera_geometry.dart';
import 'seat_availability.dart';
import 'seat_frame_source.dart';

/// A streamed camera frame plus the rotation the detector must apply.
class CameraSeatFrame extends SeatFrame {
  const CameraSeatFrame({required this.image, required this.rotationDegrees});

  final CameraImage image;
  final int rotationDegrees;
}

class CameraFrameSource implements SeatFrameSource {
  CameraFrameSource({
    Future<List<CameraDescription>> Function()? listCameras,
    this.probeWindow = const Duration(milliseconds: 600),
    this.openTimeout = const Duration(seconds: 8),
    this.disposeTimeout = const Duration(seconds: 2),
  }) : _listCameras = listCameras ?? availableCameras;

  final Future<List<CameraDescription>> Function() _listCameras;

  /// How long the probe waits for an asynchronous "camera in use" fault
  /// after the camera opened.
  final Duration probeWindow;
  final Duration openTimeout;

  /// S04c §3a: a controller dispose that outlives this bound continues in
  /// the background (logged) instead of blocking the probe, the open or the
  /// stop sequence.
  final Duration disposeTimeout;

  CameraController? _controller;
  VoidCallback? _listener;
  String? _lastFault;

  @override
  bool get isOpen => _controller != null;

  static bool get _isIOS => defaultTargetPlatform == TargetPlatform.iOS;
  static bool get _isAndroid => defaultTargetPlatform == TargetPlatform.android;

  /// Front camera when there is one, otherwise the first camera (tablets
  /// without a front sensor still get a seated signal).
  @visibleForTesting
  static CameraDescription? pickCamera(List<CameraDescription> cameras) {
    if (cameras.isEmpty) return null;
    for (final c in cameras) {
      if (c.lensDirection == CameraLensDirection.front) return c;
    }
    return cameras.first;
  }

  static ImageFormatGroup? get _streamFormat => _isAndroid
      ? ImageFormatGroup.nv21
      : _isIOS
          ? ImageFormatGroup.bgra8888
          : null;

  CameraController _newController(CameraDescription camera, {required int fps}) =>
      CameraController(
        camera,
        ResolutionPreset.low,
        enableAudio: false,
        fps: fps,
        imageFormatGroup: _streamFormat,
      );

  @override
  Future<CameraProbeResult> probe() async {
    if (isOpen) return CameraProbeResult.ok;
    final List<CameraDescription> cameras;
    try {
      cameras = await _listCameras();
    } on CameraException catch (e) {
      return probeResultForExceptionCode(e.code);
    } catch (_) {
      return CameraProbeResult.failed;
    }
    final camera = pickCamera(cameras);
    if (camera == null) return CameraProbeResult.noCamera;

    final controller = _newController(camera, fps: SeatFrameSourceConfig.lowPowerFps);
    try {
      await controller.initialize().timeout(openTimeout);
      // CameraX reports "in use" asynchronously after the open succeeded; the
      // controller keeps the first error description.
      await Future<void>.delayed(probeWindow);
      final fault = controller.value.errorDescription;
      if (fault == null) return CameraProbeResult.ok;
      return switch (classifyCameraFault(fault)) {
        CameraFault.inUse => CameraProbeResult.busy,
        CameraFault.disabled || CameraFault.fatal => CameraProbeResult.failed,
        CameraFault.recoverable || CameraFault.unknown => CameraProbeResult.ok,
      };
    } on CameraException catch (e) {
      return probeResultForExceptionCode(e.code);
    } on TimeoutException {
      return CameraProbeResult.failed;
    } catch (_) {
      return CameraProbeResult.failed;
    } finally {
      await _disposeQuietly(controller);
    }
  }

  @override
  Future<void> open(
    SeatFrameSourceConfig config, {
    required SeatFrameCallback onFrame,
    required SeatFaultCallback onFault,
  }) async {
    if (isOpen) return;
    final List<CameraDescription> cameras;
    try {
      cameras = await _listCameras();
    } on CameraException catch (e) {
      throw SeatFrameSourceException(_openCode(e.code), e.description);
    } catch (e) {
      throw SeatFrameSourceException('camera_init_failed', '$e');
    }
    final camera = pickCamera(cameras);
    if (camera == null) throw const SeatFrameSourceException('no_camera');

    final controller = _newController(camera, fps: config.targetFps);
    try {
      await controller.initialize().timeout(openTimeout);
    } on CameraException catch (e) {
      await _disposeQuietly(controller);
      throw SeatFrameSourceException(_openCode(e.code), e.description);
    } on TimeoutException {
      await _disposeQuietly(controller);
      throw const SeatFrameSourceException('camera_init_failed', 'timeout');
    } catch (e) {
      await _disposeQuietly(controller);
      throw SeatFrameSourceException('camera_init_failed', '$e');
    }

    _lastFault = null;
    void listener() {
      final d = controller.value.errorDescription;
      if (d == null || d == _lastFault) return;
      _lastFault = d;
      onFault(classifyCameraFault(d), d);
    }

    controller.addListener(listener);
    _listener = listener;

    final sensorOrientation = camera.sensorOrientation;
    final frontFacing = camera.lensDirection == CameraLensDirection.front;
    final isIOS = _isIOS;
    try {
      await controller.startImageStream((CameraImage image) {
        onFrame(
          CameraSeatFrame(
            image: image,
            rotationDegrees: inputRotationDegrees(
              sensorOrientation: sensorOrientation,
              deviceOrientation: controller.value.deviceOrientation,
              frontFacing: frontFacing,
              isIOS: isIOS,
            ),
          ),
        );
      });
    } on CameraException catch (e) {
      controller.removeListener(listener);
      _listener = null;
      await _disposeQuietly(controller);
      throw SeatFrameSourceException('camera_init_failed', e.description);
    }
    _controller = controller;
    // An error that arrived during start-up is reported once, too.
    listener();
  }

  @override
  Future<void> close() async {
    final controller = _controller;
    if (controller == null) return;
    _controller = null;
    final listener = _listener;
    if (listener != null) controller.removeListener(listener);
    _listener = null;
    try {
      if (controller.value.isStreamingImages) await controller.stopImageStream();
    } catch (_) {
      // Already stopped or the camera is gone — dispose below releases it.
    }
    await _disposeQuietly(controller);
  }

  /// Dispose bounded by [disposeTimeout]; a late or failing dispose is only
  /// logged (no frame data in the message).
  Future<void> _disposeQuietly(CameraController controller) {
    final done = Completer<void>();
    final timer = Timer(disposeTimeout, () {
      if (done.isCompleted) return;
      appLog.w('camera source: dispose still pending after ${disposeTimeout.inMilliseconds}ms');
      done.complete();
    });
    controller.dispose().then(
      (_) {
        timer.cancel();
        if (!done.isCompleted) done.complete();
      },
      onError: (Object e, StackTrace st) {
        timer.cancel();
        appLog.w('camera source: dispose failed', error: e, stackTrace: st);
        if (!done.isCompleted) done.complete();
      },
    );
    return done.future;
  }

  static String _openCode(String exceptionCode) =>
      switch (probeResultForExceptionCode(exceptionCode)) {
        CameraProbeResult.permissionDenied => 'permission_denied',
        CameraProbeResult.busy => 'camera_busy',
        CameraProbeResult.noCamera => 'no_camera',
        CameraProbeResult.ok || CameraProbeResult.failed => 'camera_init_failed',
      };
}
