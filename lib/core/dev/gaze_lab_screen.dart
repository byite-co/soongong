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

// A release timeout does not establish that the OS released the camera. Keep
// this latch for the app's ProviderScope lifetime, including route re-entry.
class _GazeReleaseGuard extends ChangeNotifier {
  bool failed = false;
  _GazeRun? _owner;
  bool get busy => _owner != null;

  bool claim(_GazeRun run) {
    if (failed || busy) return false;
    _owner = run;
    if (hasListeners) notifyListeners();
    return true;
  }

  void fail() {
    failed = true;
    if (hasListeners) notifyListeners();
  }

  void release(_GazeRun run) {
    if (_owner != run || run.opening || !run.stopFinished) return;
    _owner = null;
    if (hasListeners) notifyListeners();
  }
}

final _releaseGuardProvider = Provider<_GazeReleaseGuard>((ref) {
  final guard = _GazeReleaseGuard();
  ref.onDispose(guard.dispose);
  return guard;
});

class _GazeRun {
  _GazeRun(this.id);
  final String id;
  Future<void>? nativeClose;
  bool opening = true;
  bool stopFinished = false;
  bool inFlight = false;
  int lastFrame = -200;
}

/// Dev-only observation harness. No DB, account data, or time accounting writes.
class GazeLabScreen extends ConsumerStatefulWidget {
  const GazeLabScreen({super.key, this.source, this.engine});

  /// Platform boundaries only; tests still exercise this screen's lifecycle.
  @visibleForTesting
  final SeatFrameSource? source;
  @visibleForTesting
  final NativeGaze? engine;

  @override
  ConsumerState<GazeLabScreen> createState() => _GazeLabScreenState();
}

class _GazeLabScreenState extends ConsumerState<GazeLabScreen>
    with WidgetsBindingObserver {
  late final SeatFrameSource _source;
  late final NativeGaze _engine;
  late final _GazeReleaseGuard _releaseGuard;
  final _calibration = GazeCalibration();
  final _clock = Stopwatch()..start();
  SeatCameraHandle? _handle;
  _GazeRun? _run;
  Future<void>? _stopping;
  bool _disposed = false;
  bool _consent = false;
  bool _opening = false;
  bool _closing = false;
  bool _releaseFailed = false;
  GazeState _state = GazeState.unknown;
  String? _error;

  @override
  void initState() {
    super.initState();
    _source = widget.source ?? CameraFrameSource();
    _engine = widget.engine ?? NativeGaze();
    _releaseGuard = ref.read(_releaseGuardProvider);
    _releaseFailed = _releaseGuard.failed;
    if (_releaseFailed) _error = GazeStrings.releaseFailed;
    _releaseGuard.addListener(_releaseChanged);
    WidgetsBinding.instance.addObserver(this);
  }

  void _releaseChanged() {
    if (_disposed || !mounted) return;
    setState(() {
      _releaseFailed = _releaseGuard.failed;
      if (_releaseFailed) _error = GazeStrings.releaseFailed;
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (isBackgroundState(state)) unawaited(_stop());
  }

  Future<void> _start() async {
    if (!_consent ||
        _run != null ||
        _opening ||
        _closing ||
        _releaseFailed ||
        ref.read(measureControllerProvider).isLive) {
      return;
    }
    final run = _GazeRun(const Uuid().v4());
    if (!_releaseGuard.claim(run)) return;
    setState(() {
      _run = run;
      _opening = true;
      _error = null;
      _calibration.reset();
    });
    try {
      final permission = await CameraPermission.request();
      if (_disposed || !mounted || _run != run) return;
      if (!permission.isGranted) throw StateError('permission');
      await _engine.open(run.id).timeout(const Duration(seconds: 10));
      if (_disposed || !mounted || _run != run) {
        await _release(run, null);
        return;
      }
      final handle = await _source.open(
        const SeatFrameSourceConfig(lowPower: true),
        onFrame: (frame) {
          if (frame is CameraSeatFrame) unawaited(_observe(frame, run));
        },
        onFault: (_, _) {
          if (_run == run) unawaited(_stop(error: GazeStrings.unavailable));
        },
      );
      if (_disposed || !mounted || _run != run) {
        // Opening still owns the start gate until its late handle has been
        // released (or failed). A new run cannot acquire a second camera.
        await _release(run, handle);
      } else {
        _handle = handle;
      }
    } catch (_) {
      if (_run == run) await _stop(error: GazeStrings.unavailable);
    } finally {
      run.opening = false;
      _releaseGuard.release(run);
      _opening = false;
      if (!_disposed && mounted) setState(() {});
    }
  }

  Future<void> _observe(CameraSeatFrame frame, _GazeRun run) async {
    final time = _clock.elapsedMilliseconds;
    if (_run != run || run.inFlight || time - run.lastFrame < 200) return;
    run.inFlight = true;
    run.lastFrame = time;
    try {
      final point = await _engine
          .observe(frame, run.id, time)
          .timeout(const Duration(seconds: 2));
      if (_disposed || !mounted || _run != run) return;
      setState(() {
        _state = _calibration.observe(point, time / 1000);
      });
    } catch (_) {
      if (_run == run) await _stop(error: GazeStrings.unavailable);
    } finally {
      run.inFlight = false;
    }
  }

  void _releaseFailure() {
    _releaseFailed = true;
    _releaseGuard.fail();
    _error = GazeStrings.releaseFailed;
    if (!_disposed && mounted) setState(() {});
  }

  /// One 2 s camera budget followed by one 2 s native budget. The timeout
  /// observes failure; it does not cancel or claim success for the OS work.
  Future<void> _release(_GazeRun run, SeatCameraHandle? handle) async {
    try {
      if (handle != null) {
        final result = await Future<CloseResult>.sync(
          handle.close,
        ).timeout(const Duration(seconds: 2));
        if (!result.isOk) _releaseFailure();
      }
    } catch (_) {
      _releaseFailure();
    } finally {
      try {
        // Native calls are serial per bridge. Closing this run once also
        // queues behind an open that has not returned yet. Late open cleanup
        // joins the same close instead of issuing an unbounded second call.
        await (run.nativeClose ??= Future<void>.sync(
          () => _engine.close(run.id),
        ).timeout(const Duration(seconds: 2)));
      } catch (_) {
        _releaseFailure();
      }
    }
  }

  Future<void> _finishStop(_GazeRun run, SeatCameraHandle? handle) async {
    try {
      await _release(run, handle);
    } finally {
      run.stopFinished = true;
      _releaseGuard.release(run);
      _closing = false;
      _stopping = null;
      if (!_disposed && mounted) setState(() {});
    }
  }

  Future<void> _stop({String? error}) {
    final stopping = _stopping;
    if (stopping != null) return stopping;
    final run = _run;
    if (run == null) return Future<void>.value();
    _run = null;
    _closing = true;
    _calibration.reset();
    _state = GazeState.unknown;
    final handle = _handle;
    _handle = null;
    if (!_disposed && mounted) {
      setState(() {
        _error = error;
      });
    }
    return _stopping = _finishStop(run, handle);
  }

  @override
  void dispose() {
    _disposed = true;
    WidgetsBinding.instance.removeObserver(this);
    _releaseGuard.removeListener(_releaseChanged);
    unawaited(_stop());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final measuring = ref.watch(measureControllerProvider).isLive;
    ref.listen(measureControllerProvider, (_, next) {
      if (next.isLive) unawaited(_stop(error: GazeStrings.measuring));
    });
    return Scaffold(
      appBar: AppBar(title: const Text(GazeStrings.title)),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const Text(GazeStrings.description),
          CheckboxListTile(
            value: _consent,
            title: const Text(GazeStrings.consent),
            onChanged: _run != null
                ? null
                : (value) => setState(() {
                    _consent = value ?? false;
                  }),
          ),
          if (measuring) const Text(GazeStrings.measuring),
          if (_error != null) Text(_error!),
          Text(GazeStrings.state(_state)),
          FilledButton(
            onPressed:
                !_consent ||
                    measuring ||
                    _opening ||
                    _closing ||
                    _releaseFailed ||
                    (_run == null && _releaseGuard.busy)
                ? null
                : _run == null
                ? _start
                : _stop,
            child: Text(_run == null ? GazeStrings.start : GazeStrings.stop),
          ),
          OutlinedButton(
            onPressed: _run == null || _opening
                ? null
                : () => setState(() {
                    _calibration.begin();
                    _state = GazeState.calibrating;
                  }),
            child: const Text(GazeStrings.calibrate),
          ),
        ],
      ),
    );
  }
}
