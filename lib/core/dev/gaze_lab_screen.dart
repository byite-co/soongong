import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../data/engines/gaze/native_gaze.dart';
import '../../data/engines/seat/camera_frame_source.dart';
import '../../data/engines/seat/camera_permission.dart';
import '../../data/engines/seat/seat_frame_source.dart';
import '../../features/measure/application/measure_controller.dart';
import '../../features/measure/domain/gaze_observation.dart';
import '../strings/gaze_strings.dart';

/// Dev-only observation harness. No DB, account data, or time accounting writes.
class GazeLabScreen extends ConsumerStatefulWidget {
  const GazeLabScreen({super.key});
  @override
  ConsumerState<GazeLabScreen> createState() => _GazeLabScreenState();
}

class _GazeLabScreenState extends ConsumerState<GazeLabScreen> with WidgetsBindingObserver {
  final _source = CameraFrameSource();
  final _engine = NativeGaze();
  final _calibration = GazeCalibration();
  final _clock = Stopwatch()..start();
  SeatCameraHandle? _handle;
  String? _run;
  bool _disposed = false;
  bool _consent = false;
  bool _opening = false;
  bool _closing = false;
  bool _inFlight = false;
  bool _releaseFailed = false;
  int _lastFrame = -200;
  GazeState _state = GazeState.unknown;
  String? _error;

  @override
  void initState() { super.initState(); WidgetsBinding.instance.addObserver(this); }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (isBackgroundState(state)) unawaited(_stop());
  }

  Future<void> _start() async {
    if (!_consent || _run != null || _opening || _closing || _releaseFailed || ref.read(measureControllerProvider).isLive) return;
    final run = const Uuid().v4();
    setState(() { _run = run; _opening = true; _error = null; _calibration.reset(); });
    try {
      final permission = await CameraPermission.request();
      if (_disposed || !mounted || _run != run) return;
      if (!permission.isGranted) throw StateError('permission');
      await _engine.open(run).timeout(const Duration(seconds: 10));
      if (_disposed || !mounted || _run != run) { await _engine.close(run); return; }
      final handle = await _source.open(const SeatFrameSourceConfig(lowPower: true),
        onFrame: (frame) { if (frame is CameraSeatFrame) unawaited(_observe(frame, run)); },
        onFault: (_, _) { if (_run == run) unawaited(_stop(error: GazeStrings.unavailable)); });
      if (_disposed || !mounted || _run != run) {
        final result = await handle.close();
        if (!result.isOk) _releaseFailed = true;
      } else { _handle = handle; }
    } catch (_) {
      if (_run == run) await _stop(error: GazeStrings.unavailable);
    } finally {
      _opening = false;
      if (!_disposed && mounted) setState(() {});
    }
  }

  Future<void> _observe(CameraSeatFrame frame, String run) async {
    final time = _clock.elapsedMilliseconds;
    if (_run != run || _inFlight || time - _lastFrame < 200) return;
    _inFlight = true; _lastFrame = time;
    try {
      final point = await _engine.observe(frame, run, time).timeout(const Duration(seconds: 2));
      if (_disposed || !mounted || _run != run) return;
      setState(() { _state = _calibration.observe(point, time / 1000); });
    } catch (_) {
      if (_run == run) await _stop(error: GazeStrings.unavailable);
    } finally { _inFlight = false; }
  }

  Future<void> _stop({String? error}) async {
    final run = _run;
    if (run == null) return;
    _run = null; _closing = true; _calibration.reset(); _state = GazeState.unknown;
    final handle = _handle; _handle = null;
    if (!_disposed && mounted) setState(() { _error = error; });
    final result = await handle?.close();
    if (result != null && !result.isOk) _releaseFailed = true;
    try { await _engine.close(run).timeout(const Duration(seconds: 2)); }
    catch (_) { _releaseFailed = true; }
    _closing = false;
    if (!_disposed && mounted) setState(() { if (_releaseFailed) _error = GazeStrings.releaseFailed; });
  }

  @override
  void dispose() {
    _disposed = true;
    WidgetsBinding.instance.removeObserver(this);
    unawaited(_stop());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final measuring = ref.watch(measureControllerProvider).isLive;
    ref.listen(measureControllerProvider, (_, next) {
      if (next.isLive) unawaited(_stop(error: GazeStrings.measuring));
    });
    return Scaffold(appBar: AppBar(title: const Text(GazeStrings.title)),
      body: ListView(padding: const EdgeInsets.all(24), children: [
        const Text(GazeStrings.description),
        CheckboxListTile(value: _consent, title: const Text(GazeStrings.consent),
          onChanged: _run != null ? null : (value) => setState(() { _consent = value ?? false; })),
        if (measuring) const Text(GazeStrings.measuring),
        if (_error != null) Text(_error!),
        Text(GazeStrings.state(_state)),
        FilledButton(onPressed: !_consent || measuring || _opening || _closing || _releaseFailed ? null : _run == null ? _start : _stop,
          child: Text(_run == null ? GazeStrings.start : GazeStrings.stop)),
        OutlinedButton(onPressed: _run == null || _opening ? null : () => setState(() { _calibration.begin(); _state = GazeState.calibrating; }),
          child: const Text(GazeStrings.calibrate)),
      ]));
  }
}
