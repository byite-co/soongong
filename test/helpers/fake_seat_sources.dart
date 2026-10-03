// Test doubles for the seat engine (S04 · S04d): a scripted frame source that
// hands out one handle per open, a detector that reads the scripted answer,
// a permission gateway and a lifecycle feed. Frames carry a `present` flag
// instead of pixels.

import 'dart:async';

import 'package:flutter/widgets.dart' show AppLifecycleState;
import 'package:soongong/data/engines/engines.dart';

class FakeSeatFrame extends SeatFrame {
  const FakeSeatFrame({required this.present});

  final bool present;
}

/// One camera session of [FakeSeatFrameSource]. Frames and faults can be
/// delivered through a specific handle, open or closed (a platform callback
/// that arrives late).
class FakeCameraHandle implements SeatCameraHandle {
  FakeCameraHandle(this._source, this.index, this.config, this._onFrame, this._onFault);

  final FakeSeatFrameSource _source;

  /// 1-based, in order of completed opens.
  final int index;
  final SeatFrameSourceConfig config;
  final SeatFrameCallback _onFrame;
  final SeatFaultCallback _onFault;
  bool _open = true;
  int closeCalls = 0;

  @override
  bool get isOpen => _open;

  bool get closed => !_open;

  @override
  Future<CloseResult> close() async {
    closeCalls++;
    if (!_open) return const CloseResult.ok();
    _open = false;
    _source.closeCount++;
    _source._lastClosed = this;
    if (_source.hangClose) await Completer<void>().future;
    final err = _source.closeError;
    if (err != null) return CloseResult.failed(err);
    return _source.closeResult ?? const CloseResult.ok();
  }

  void emit({required bool present}) => _onFrame(FakeSeatFrame(present: present));

  void fault(CameraFault fault, [String description = 'fault']) =>
      _onFault(fault, description);
}

class FakeSeatFrameSource implements SeatFrameSource {
  FakeSeatFrameSource({this.probeResult = CameraProbeResult.ok, this.openError});

  CameraProbeResult probeResult;

  /// When set, [open] throws it.
  SeatFrameSourceException? openError;

  /// [open] completes only after this delay (a slow camera).
  Duration openDelay = Duration.zero;

  /// [open] never completes (a camera that hangs while initialising).
  bool hangOpen = false;

  /// [probe] never completes.
  bool hangProbe = false;

  /// A handle's [FakeCameraHandle.close] never completes (the session is
  /// still marked closed at once).
  bool hangClose = false;

  /// When set, [FakeCameraHandle.close] answers `CloseResult.failed(closeError)`
  /// (the platform dispose threw).
  Object? closeError;

  /// When set (and [closeError] is not), [FakeCameraHandle.close] answers
  /// this result — e.g. the source's own `timeout`.
  CloseResult? closeResult;

  /// Every session opened so far, in order of completed opens.
  final List<FakeCameraHandle> handles = <FakeCameraHandle>[];
  FakeCameraHandle? _lastClosed;
  SeatFrameSourceConfig? lastConfig;
  int openCount = 0;
  int closeCount = 0;
  int probeCount = 0;

  /// The most recently opened session that is still open (`null` when none).
  FakeCameraHandle? get current {
    for (var i = handles.length - 1; i >= 0; i--) {
      if (handles[i].isOpen) return handles[i];
    }
    return null;
  }

  /// Any session still open.
  bool get isOpen => current != null;

  @override
  Future<CameraProbeResult> probe() async {
    probeCount++;
    if (hangProbe) await Completer<void>().future;
    return probeResult;
  }

  @override
  Future<SeatCameraHandle> open(
    SeatFrameSourceConfig config, {
    required SeatFrameCallback onFrame,
    required SeatFaultCallback onFault,
  }) async {
    final err = openError;
    if (err != null) throw err;
    if (hangOpen) await Completer<void>().future;
    if (openDelay > Duration.zero) await Future<void>.delayed(openDelay);
    openCount++;
    lastConfig = config;
    final h = FakeCameraHandle(this, handles.length + 1, config, onFrame, onFault);
    handles.add(h);
    return h;
  }

  /// Delivers one frame to the current session (no-op when none is open,
  /// like a real camera).
  void emit({required bool present}) => current?.emit(present: present);

  void fault(CameraFault fault, [String description = 'fault']) =>
      current?.fault(fault, description);

  /// A frame from the most recently closed session arriving after its close.
  void emitLate({required bool present}) => _lastClosed?.emit(present: present);

  /// A fault from the most recently closed session arriving after its close.
  void faultLate(CameraFault fault, [String description = 'late fault']) =>
      _lastClosed?.fault(fault, description);
}

class FakePresenceDetector implements PresenceDetector {
  FakePresenceDetector({this.latency = Duration.zero, this.hang = false});

  /// Simulated detector round-trip (realised with a Timer so fake_async can
  /// advance it).
  Duration latency;

  /// When set, every call throws it.
  Object? error;

  /// [detect] does not return until [releaseHung] (an unresponsive detector).
  bool hang;

  final List<Completer<void>> _hung = <Completer<void>>[];
  int calls = 0;
  int closeCalls = 0;
  bool closed = false;

  /// Calls that have not returned yet.
  int get pendingCalls => _hung.where((c) => !c.isCompleted).length;

  /// Lets every hung call continue (it then answers normally).
  void releaseHung() {
    for (final c in _hung) {
      if (!c.isCompleted) c.complete();
    }
  }

  @override
  Future<bool> detect(SeatFrame frame) async {
    calls++;
    if (hang) {
      final c = Completer<void>();
      _hung.add(c);
      await c.future;
    }
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
  FakeLifecycleSource({AppLifecycleState? initial}) : current = initial;

  final StreamController<AppLifecycleState> _controller =
      StreamController<AppLifecycleState>.broadcast();

  @override
  AppLifecycleState? current;

  @override
  Stream<AppLifecycleState> get states => _controller.stream;

  /// Records the new state and notifies listeners.
  void add(AppLifecycleState state) {
    current = state;
    _controller.add(state);
  }

  Future<void> close() => _controller.close();
}
