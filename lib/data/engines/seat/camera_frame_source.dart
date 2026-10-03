// CameraFrameSource (S04 · S04d): `camera` plugin → [SeatFrameSource].
//
// Front camera, lowest resolution preset (320×240 on Android, 352×288 on
// iOS), no audio, single-plane stream format (NV21 on Android, BGRA on iOS)
// so the detector gets the bytes without conversion. Frames are forwarded
// synchronously from the plugin callback and never retained here.
//
// S04d: every `open()` returns its own [SeatCameraHandle] wrapping the
// controller it created. Closing a handle stops and disposes that controller
// only, so a controller that finished initialising after its run was
// abandoned can be released without touching the controller of the run that
// replaced it.

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

  final Set<_CameraSession> _sessions = <_CameraSession>{};

  /// At least one session opened by this source is still open.
  bool get hasOpenSession => _sessions.isNotEmpty;

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
    if (hasOpenSession) return CameraProbeResult.ok;
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
  Future<SeatCameraHandle> open(
    SeatFrameSourceConfig config, {
    required SeatFrameCallback onFrame,
    required SeatFaultCallback onFault,
  }) async {
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

    final session = _CameraSession(this, controller, onFault);
    final sensorOrientation = camera.sensorOrientation;
    final frontFacing = camera.lensDirection == CameraLensDirection.front;
    final isIOS = _isIOS;
    try {
      await controller.startImageStream((CameraImage image) {
        if (!session.isOpen) return; // a frame queued before the close landed
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
      session._abandon();
      await _disposeQuietly(controller);
      throw SeatFrameSourceException('camera_init_failed', e.description);
    }
    _sessions.add(session);
    // An error that arrived during start-up is reported once, too.
    session._reportFault();
    return session;
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

/// One controller, owned by one engine run (S04d §1).
class _CameraSession implements SeatCameraHandle {
  _CameraSession(this._owner, this._controller, this._onFault) {
    _controller.addListener(_reportFault);
  }

  final CameraFrameSource _owner;
  final CameraController _controller;
  final SeatFaultCallback _onFault;
  String? _lastFault;
  bool _open = true;

  @override
  bool get isOpen => _open;

  void _reportFault() {
    if (!_open) return;
    final d = _controller.value.errorDescription;
    if (d == null || d == _lastFault) return;
    _lastFault = d;
    _onFault(classifyCameraFault(d), d);
  }

  /// Start-up failed before the session was handed out.
  void _abandon() {
    _open = false;
    _controller.removeListener(_reportFault);
  }

  @override
  Future<void> close() async {
    if (!_open) return;
    _open = false;
    _owner._sessions.remove(this);
    _controller.removeListener(_reportFault);
    try {
      if (_controller.value.isStreamingImages) await _controller.stopImageStream();
    } catch (_) {
      // Already stopped or the camera is gone — dispose below releases it.
    }
    await _owner._disposeQuietly(_controller);
  }
}
