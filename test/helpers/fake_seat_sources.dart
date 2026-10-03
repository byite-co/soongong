// Test doubles for the seat engine (S04): a scripted frame source, a
// detector that reads the scripted answer, a permission gateway and a
// lifecycle feed. Frames carry a `present` flag instead of pixels.

import 'dart:async';

import 'package:flutter/widgets.dart' show AppLifecycleState;
import 'package:soongong/data/engines/engines.dart';

class FakeSeatFrame extends SeatFrame {
  const FakeSeatFrame({required this.present});

  final bool present;
}

class FakeSeatFrameSource implements SeatFrameSource {
  FakeSeatFrameSource({this.probeResult = CameraProbeResult.ok, this.openError});

  CameraProbeResult probeResult;

  /// When set, [open] throws it.
  SeatFrameSourceException? openError;

  SeatFrameCallback? _onFrame;
  SeatFaultCallback? _onFault;

  /// Callbacks of the most recently closed session, so a test can replay a
  /// platform callback that arrives late (after the camera was released,
  /// possibly after the next session opened) with [emitLate] / [faultLate].
  SeatFrameCallback? _lateOnFrame;
  SeatFaultCallback? _lateOnFault;
  SeatFrameSourceConfig? lastConfig;
  int openCount = 0;
  int closeCount = 0;
  int probeCount = 0;

  @override
  bool get isOpen => _onFrame != null;

  @override
  Future<CameraProbeResult> probe() async {
    probeCount++;
    return probeResult;
  }

  @override
  Future<void> open(
    SeatFrameSourceConfig config, {
    required SeatFrameCallback onFrame,
    required SeatFaultCallback onFault,
  }) async {
    final err = openError;
    if (err != null) throw err;
    openCount++;
    lastConfig = config;
    _onFrame = onFrame;
    _onFault = onFault;
  }

  @override
  Future<void> close() async {
    if (_onFrame == null) return;
    closeCount++;
    _lateOnFrame = _onFrame;
    _lateOnFault = _onFault;
    _onFrame = null;
    _onFault = null;
  }

  /// Delivers one frame (no-op when closed, like a real camera).
  void emit({required bool present}) =>
      _onFrame?.call(FakeSeatFrame(present: present));

  void fault(CameraFault fault, [String description = 'fault']) =>
      _onFault?.call(fault, description);

  /// A frame from the previous camera session arriving after [close].
  void emitLate({required bool present}) =>
      _lateOnFrame?.call(FakeSeatFrame(present: present));

  /// A fault from the previous camera session arriving after [close].
  void faultLate(CameraFault fault, [String description = 'late fault']) =>
      _lateOnFault?.call(fault, description);
}

class FakePresenceDetector implements PresenceDetector {
  FakePresenceDetector({this.latency = Duration.zero});

  /// Simulated detector round-trip (realised with a Timer so fake_async can
  /// advance it).
  Duration latency;

  /// When set, every call throws it.
  Object? error;

  int calls = 0;
  int closeCalls = 0;
  bool closed = false;

  @override
  Future<bool> detect(SeatFrame frame) async {
    calls++;
    if (latency > Duration.zero) {
      await Future<void>.delayed(latency);
    }
    final e = error;
    if (e != null) throw e;
    return (frame as FakeSeatFrame).present;
  }

  @override
  Future<void> close() async {
    closeCalls++;
    closed = true;
  }
}

class FakeCameraPermissionGateway implements CameraPermissionGateway {
  FakeCameraPermissionGateway({
    this.current = CameraPermissionResult.granted,
    this.afterRequest,
  });

  CameraPermissionResult current;

  /// State after a prompt; `null` keeps [current].
  CameraPermissionResult? afterRequest;
  int requests = 0;
  int settingsOpened = 0;

  @override
  Future<CameraPermissionResult> status() async => current;

  @override
  Future<CameraPermissionResult> request() async {
    requests++;
    final next = afterRequest;
    if (next != null) current = next;
    return current;
  }

  @override
  Future<bool> openSettings() async {
    settingsOpened++;
    return true;
  }
}

class FakeLifecycleSource implements LifecycleSource {
  final StreamController<AppLifecycleState> _controller =
      StreamController<AppLifecycleState>.broadcast();

  @override
  Stream<AppLifecycleState> get states => _controller.stream;

  void add(AppLifecycleState state) => _controller.add(state);

  Future<void> close() => _controller.close();
}
