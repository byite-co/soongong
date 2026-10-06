import 'dart:async';

import 'package:battery_plus/battery_plus.dart';
import 'package:flutter/widgets.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../../../core/contracts/providers.dart';
import '../../../core/contracts/seat_engine.dart';
import '../../../core/domain/clock.dart';
import '../../../core/domain/entities/entities.dart';
import '../../../core/domain/enums.dart';
import '../../../core/domain/ids.dart';
import '../../../core/domain/local_date.dart';
import '../../../core/logging/app_logger.dart';
import '../../../core/platform/sleep_aware_clock.dart';
import '../../../data/repositories/planner_repository.dart';
import '../../../data/repositories/repository_providers.dart';
import '../../../data/repositories/session_repository.dart';
import '../../../data/repositories/settings_repository.dart';
import '../domain/away_policy.dart';
import '../domain/seated_time_calculator.dart';
import '../domain/segment.dart';
import '../domain/sensitivity_policy.dart';
import '../domain/session_clock.dart';
import '../domain/session_snapshot.dart';
import '../domain/session_timeline.dart';

part 'measure_controller.g.dart';

abstract class MeasureDevice {
  Future<void> keepAwake(bool enabled);
  Future<int?> batteryLevel();
}

class SystemMeasureDevice implements MeasureDevice {
  @override
  Future<void> keepAwake(bool enabled) => WakelockPlus.toggle(enable: enabled);
  @override
  Future<int?> batteryLevel() async {
    try {
      return await Battery().batteryLevel;
    } on Object {
      return null;
    }
  }
}

@Riverpod(keepAlive: true)
MeasureDevice measureDevice(Ref ref) => SystemMeasureDevice();

@Riverpod(keepAlive: true)
SleepAwareClock sleepAwareClock(Ref ref) => const PlatformSleepAwareClock();

/// Riverpod owns the lifetime; screens observe changes with ListenableBuilder.
/// Raw explicitly keeps the ChangeNotifier from being treated as provider state.
@Riverpod(keepAlive: true)
Raw<MeasureController> measureController(Ref ref) {
  final controller = MeasureController(
    engine: ref.watch(seatEngineProvider),
    sessions: ref.watch(sessionRepositoryProvider),
    settings: ref.watch(settingsRepositoryProvider),
    planner: ref.watch(plannerRepositoryProvider),
    wall: ref.watch(appClockProvider),
    monotonic: StopwatchMonotonicClock(),
    device: ref.watch(measureDeviceProvider),
    sleepAware: ref.watch(sleepAwareClockProvider),
  );
  WidgetsBinding.instance.addObserver(controller);
  final lifecycle = WidgetsBinding.instance.lifecycleState;
  if (lifecycle != null) controller.didChangeAppLifecycleState(lifecycle);
  ref.onDispose(() {
    WidgetsBinding.instance.removeObserver(controller);
    controller.dispose();
  });
  return controller;
}

enum MeasurePhase { setup, focus, summary, saved }

sealed class MeasureSaveState {
  const MeasureSaveState();
}

class MeasureUnsaved extends MeasureSaveState {
  const MeasureUnsaved();
}

class MeasureSaving extends MeasureSaveState {
  const MeasureSaving();
}

class MeasureSaved extends MeasureSaveState {
  const MeasureSaved();
}

class MeasureSaveFailed extends MeasureSaveState {
  const MeasureSaveFailed();
}

/// Owns one measurement, including its unsaved summary. Times are derived
/// from a session clock; engine receivedAt is deliberately never used.
class MeasureController extends ChangeNotifier with WidgetsBindingObserver {
  MeasureController({
    required this.engine,
    required this.sessions,
    required this.settings,
    required this.planner,
    required this.wall,
    required this.monotonic,
    required this.device,
    this.sleepAware = const NoSleepAwareClock(),
    this.automaticTicks = true,
  });

  final SeatEngine engine;
  final SessionRepository sessions;
  final SettingsRepository settings;
  final PlannerRepository planner;
  final Clock wall;
  final MonotonicClock monotonic;
  final MeasureDevice device;

  /// Sleep-inclusive elapsed time ([S06c]); never a wall clock.
  final SleepAwareClock sleepAware;
  final bool automaticTicks;
  MeasurePhase phase = MeasurePhase.setup;
  MeasureSaveState saveState = const MeasureUnsaved();
  SeatAvailability? availability;
  AppSettings preferences = const AppSettings();
  bool busy = false,
      failed = false,
      cameraLost = false,
      reconnectFailed = false;
  bool longAway = false, lowPower = false, checkpointFailed = false;
  bool sensitivityChanged = false, completeTask = false;
  bool _disposed = false, _background = false, _resumeOnForeground = false;
  bool _recovered = false;
  SessionTimeline? _timeline;
  SessionSnapshot? _draft;
  SessionClock? _clock;
  List<Segment> _original = [];
  final Set<String> correctedIds = {};
  StreamSubscription<SeatSample>? _samples;
  StreamSubscription<SeatEngineEvent>? _events;
  Timer? _ticker;
  int _generation = 0, _ticks = 0;
  Future<void>? _writes;
  Future<void>? _engineWork;
  DateTime? _runAnchor;
  Duration? _lastSample;
  int _todayBaseSeconds = 0;
  Duration? _sleepAnchorReal, _sleepAnchorMono;

  /// True once Riverpod disposed this controller (account switch, D27).
  /// Every write that follows an `await` checks it: a late write of the old
  /// account's session must never reach the database the new account now
  /// owns (the DB was wiped in between, and sync would push it as the new
  /// user).
  bool get isDisposed => _disposed;

  void _checkAlive() {
    if (_disposed) throw StateError('MeasureController disposed');
  }

  /// Every write of this controller goes through here ([S06d]): the alive
  /// and account-ownership checks run inside the transaction, after the
  /// database lock is acquired, so a write queued behind an account switch
  /// (D27 wipe + rebind) is refused instead of re-creating the old
  /// account's rows in the new account's database.
  Future<T> _owned<T>(Future<T> Function() action) =>
      sessions.writer.runOwnedTransaction(action, alive: () => !_disposed);

  String? get sessionId => _draft?.sessionId ?? _timeline?.sessionId;
  SessionMode get mode => _draft?.mode ?? _timeline?.mode ?? SessionMode.manual;
  SegmentKind get currentKind => _timeline?.openKind ?? SegmentKind.paused;
  bool get paused => _timeline?.isPaused ?? false;
  bool get isLive => phase == MeasurePhase.focus;
  bool get hasDraft => _draft != null;
  String? get plannerItemId =>
      _draft?.plannerItemId ?? _timeline?.plannerItemId;
  String? get subjectId => _draft?.subjectId ?? _timeline?.subjectId;
  SessionKind get kind => _draft?.kind ?? _timeline?.kind ?? SessionKind.self;
  DateTime get now => _clock?.now() ?? wall.now();
  List<Segment> get segments => phase == MeasurePhase.focus
      ? _timeline!.segmentsAt(now)
      : _original
            .map(
              (s) => correctedIds.contains(s.id)
                  ? s.copyWith(kind: SegmentKind.seated, corrected: true)
                  : s,
            )
            .toList();
  Duration get seated => const SeatedTimeCalculator().seated(segments);

  /// Today's saved 순공 before this session plus this session's 순공 — what
  /// the focus ring compares with the daily goal (D25). Read once at start;
  /// a session that crosses midnight keeps its start day's base.
  Duration get todayTotal => Duration(seconds: _todayBaseSeconds) + seated;

  /// Length of the open segment (e.g. how long the user has been away).
  Duration get openElapsed {
    final t = _timeline;
    if (t == null || !isLive) return Duration.zero;
    final d = now.difference(t.openStart);
    return d.isNegative ? Duration.zero : d;
  }

  /// Today's saved 순공 the way the home ring counts it: seated/manual
  /// segments of saved sessions (finished/interrupted with an end, live —
  /// not deleted, not pending delete), clipped to the local day, so a
  /// session that crossed midnight contributes its part after 00:00.
  Future<int> _todaySeatedBefore(String excludeId) async {
    final today = LocalDate.of(wall.now());
    final saved = <String>{
      for (final s in await sessions.getAll())
        if (s.id != excludeId &&
            s.endedAt != null &&
            (s.status == SessionStatus.finished ||
                s.status == SessionStatus.interrupted))
          s.id,
    };
    final segments = await sessions.getSegmentsOverlapping(today, today);
    return const SeatedTimeCalculator().seatedSecondsOn(
      segments.where((seg) => saved.contains(seg.sessionId)),
      today,
    );
  }

  void _emit() {
    if (!_disposed) notifyListeners();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(foreground());
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden ||
        state == AppLifecycleState.detached) {
      unawaited(background());
    }
  }

  void _resumePending() {
    if (!_disposed && isLive && !busy && !_background && _resumeOnForeground) {
      _resumeOnForeground = false;
      unawaited(resume());
    }
  }

  Future<void> prepare({bool requestCamera = false}) async {
    if (busy || isLive || hasDraft) return;
    busy = true;
    failed = false;
    _emit();
    try {
      preferences = await settings.get();
      availability = preferences.seatDetectionEnabled || requestCamera
          ? await engine.checkAvailability()
          : null;
    } on Object {
      failed = true;
      availability = SeatAvailability.unavailable;
    } finally {
      busy = false;
      _emit();
      _resumePending();
    }
  }

  Future<bool> start({
    required SessionMode mode,
    String? subjectId,
    PlannerItem? task,
  }) async {
    if (busy || isLive || hasDraft) return false;
    busy = true;
    failed = false;
    _emit();
    try {
      if (await sessions.readSnapshot() != null) {
        throw StateError('Recovery pending');
      }
      preferences = await settings.get();
      _clock = SessionClock(wall: wall, monotonic: monotonic);
      final at = _clock!.start();
      _timeline = SessionTimeline.start(
        sessionId: newUuid(),
        mode: mode,
        kind: task == null
            ? SessionKind.self
            : switch (task.kind) {
                PlannerKind.study => SessionKind.study,
                PlannerKind.todo => SessionKind.todo,
                _ => SessionKind.self,
              },
        startedAt: at,
        sensitivityLevel: preferences.sensitivityLevel,
        newId: newUuid,
        subjectId: subjectId,
        plannerItemId: task?.id,
      );
      final first = _timeline!.snapshot(at);
      await _owned(() => sessions.startActive(first));
      _todayBaseSeconds = await _todaySeatedBefore(_timeline!.sessionId);
      if (_disposed) return false;
      phase = MeasurePhase.focus;
      _recovered = false;
      saveState = const MeasureUnsaved();
      cameraLost = false;
      reconnectFailed = false;
      longAway = false;
      await _activate();
      return true;
    } on Object {
      failed = true;
      return false;
    } finally {
      busy = false;
      _emit();
      _resumePending();
    }
  }

  Future<void> _activate() async {
    if (_disposed) return;
    await _wake(!_background);
    lowPower = (await device.batteryLevel() ?? 100) <= 20;
    if (_disposed) return;
    if (automaticTicks) {
      _ticker?.cancel();
      _ticker = Timer.periodic(const Duration(seconds: 1), (_) => tick());
    }
    if (_background) {
      _timeline!.pause(now);
      _resumeOnForeground = true;
    } else if (mode == SessionMode.camera) {
      await _startEngine();
    }
    await checkpoint();
  }

  Future<void> _wake(bool on) async {
    try {
      await device.keepAwake(on);
    } on Object {
      /* Platform may lack wakelock. */
    }
  }

  Future<void> _stopEngine() {
    _generation++;
    _runAnchor = null;
    unawaited(_samples?.cancel());
    _samples = null;
    unawaited(_events?.cancel());
    _events = null;
    // stop() must invalidate an opening camera immediately (S04c). Waiting
    // for start() to resolve would keep the camera open in the background.
    final next = engine.stop();
    _engineWork = Future.wait([?_engineWork, next])
        .then<void>((_) {})
        .catchError((Object _) {});
    return _engineWork!;
  }

  Future<void> _startEngine() async {
    await _stopEngine();
    if (!isLive || _background || _disposed) return;
    final token = ++_generation;
    _lastSample = null;
    _runAnchor = now;
    _samples = engine.samples.listen((sample) {
      if (token != _generation || !isLive || _background || paused) return;
      if (sample.sinceStart.isNegative ||
          (_lastSample != null && sample.sinceStart <= _lastSample!)) {
        return;
      }
      _lastSample = sample.sinceStart;
      var at = _runAnchor!.add(sample.sinceStart);
      if (at.isAfter(now)) at = now;
      if (at.isBefore(_timeline!.openStart)) return;
      final events = _timeline!.onSeatSample(at: at, seated: sample.seated);
      if (events.any((e) => e is AwayLong)) longAway = true;
      if (sample.seated) longAway = false;
      _emit();
    });
    _events = engine.events.listen((event) {
      if (token != _generation || !isLive) return;
      if (event is SeatCameraLost || event is SeatError) {
        cameraLost = true;
        _timeline!.pause(now);
        unawaited(_stopEngine());
        unawaited(checkpoint());
      } else if (event is SeatPaused) {
        _timeline!.pause(now);
        _resumeOnForeground = true;
        unawaited(_stopEngine());
        unawaited(checkpoint());
      }
      _emit();
    });
    final next = engine.start(SeatEngineConfig(lowPower: lowPower));
    try {
      await next;
    } on Object {
      if (token == _generation) {
        cameraLost = true;
        _timeline!.pause(now);
        await _stopEngine();
      }
    }
  }

  /// Public tick permits deterministic tests without wall-clock waiting.
  void tick() {
    if (!isLive || _disposed) return;
    _ticks++;
    if (_ticks % 15 == 0) unawaited(checkpoint());
    if (_ticks % 60 == 0) unawaited(checkBattery());
    _emit();
  }

  Future<void> checkBattery() async {
    final level = await device.batteryLevel();
    if (!isLive || busy || level == null || level > 20 || lowPower) return;
    lowPower = true;
    if (mode == SessionMode.camera && !paused) {
      _resumeOnForeground = true;
      _timeline!.pause(now);
      await _stopEngine();
      if (!isLive || _background) return;
      _timeline!.resume(now);
      _resumeOnForeground = false;
      await _startEngine();
    }
    _emit();
  }

  Future<void> checkpoint() async {
    if (!isLive || _timeline == null) return;
    final snapshot = _timeline!.snapshot(now);
    final write = (_writes ?? Future<void>.value()).then((_) async {
      if (!_disposed) await _owned(() => sessions.writeSnapshot(snapshot));
    });
    _writes = write.catchError((Object _) {});
    try {
      await write;
      checkpointFailed = false;
    } on Object {
      checkpointFailed = true;
    }
    _emit();
  }

  Future<void> pause() async {
    if (!isLive || busy) return;
    _resumeOnForeground = false;
    _timeline!.pause(now);
    _emit();
    await _stopEngine();
    await checkpoint();
  }

  Future<void> resume({bool manual = false}) async {
    if (!isLive || busy || _background) return;
    busy = true;
    failed = false;
    _emit();
    try {
      // "수동으로 이어서" is a mode decision, not just a resume: apply it before
      // the first await so a background interruption keeps it ([S06d]) —
      // the foreground resume then continues in manual mode.
      if (manual && mode == SessionMode.camera) _switchToManual();
      await _stopEngine();
      if (_disposed) return;
      if (_background) {
        // The user asked to resume and then left; honour it on return.
        _resumeOnForeground = true;
        return;
      }
      if (mode == SessionMode.camera &&
          await engine.checkAvailability() != SeatAvailability.ok) {
        cameraLost = true;
        reconnectFailed = true;
        return;
      }
      if (_disposed) return;
      if (_background) {
        _resumeOnForeground = true;
        return;
      }
      cameraLost = false;
      reconnectFailed = false;
      _timeline!.resume(now);
      if (mode == SessionMode.camera) await _startEngine();
      if (cameraLost) reconnectFailed = true;
      await checkpoint();
    } on Object {
      cameraLost = true;
      reconnectFailed = true;
      _timeline!.pause(now);
    } finally {
      busy = false;
      _emit();
      _resumePending();
    }
  }

  void _switchToManual() {
    final s = _timeline!.snapshot(now);
    _timeline = SessionTimeline.fromSnapshot(
      SessionSnapshot(
        sessionId: s.sessionId,
        mode: SessionMode.manual,
        kind: s.kind,
        startedAt: s.startedAt,
        segments: s.segments,
        openKind: s.openKind,
        openStart: s.openStart,
        savedAt: s.savedAt,
        sensitivity: s.sensitivity,
        subjectId: s.subjectId,
        plannerItemId: s.plannerItemId,
      ),
      newId: newUuid,
    );
  }

  Future<void> background() async {
    _background = true;
    if (!isLive) return;
    _resumeOnForeground = _resumeOnForeground || !paused;
    _timeline!.pause(now);
    _emit();
    await _stopEngine();
    await _wake(false);
    await checkpoint();
    await _markSleepAnchor();
  }

  Future<void> _markSleepAnchor() async {
    final real = await sleepAware.elapsedRealtime();
    _sleepAnchorMono = monotonic.elapsed;
    _sleepAnchorReal = real;
  }

  /// Time the device slept since [_markSleepAnchor]: what the sleep-aware
  /// clock counted beyond the Stopwatch. Zero without a platform answer.
  Future<Duration> _sleepShift() async {
    final anchorReal = _sleepAnchorReal;
    final anchorMono = _sleepAnchorMono;
    _sleepAnchorReal = null;
    _sleepAnchorMono = null;
    if (anchorReal == null || anchorMono == null) return Duration.zero;
    final realNow = await sleepAware.elapsedRealtime();
    if (realNow == null) return Duration.zero;
    final shift = (realNow - anchorReal) - (monotonic.elapsed - anchorMono);
    return shift > Duration.zero ? shift : Duration.zero;
  }

  Future<void> foreground() async {
    _background = false;
    if (!isLive) return;
    final shift = await _sleepShift();
    if (_disposed || !isLive) return;
    if (shift > Duration.zero && paused && !_background) {
      // The Stopwatch stood still while the device slept; the paused gap
      // absorbs the difference so later segments keep their true time. The
      // wall clock is never consulted (D23: device time changes are ignored).
      _clock?.advance(shift);
      if (shift > const Duration(seconds: 1)) {
        appLog.i('measure · session clock advanced by sleep ${shift.inSeconds}s');
      }
    }
    await _wake(true);
    if (_resumeOnForeground) {
      if (!busy) {
        _resumeOnForeground = false;
        await resume();
      }
    }
  }

  Future<void> finish() async {
    if (!isLive || busy) return;
    busy = true;
    _emit();
    try {
      final at = now;
      _original = _timeline!.end(at);
      final s = _timeline!.snapshot(at);
      _draft = s.copyWith(
        segments: _original,
        openKind: SegmentKind.paused,
        openStart: at,
      );
      phase = MeasurePhase.summary;
      _ticker?.cancel();
      correctedIds.clear();
      completeTask = false;
      await _stopEngine();
      await _wake(false);
      await _writes;
      if (_disposed) return;
      try {
        await _owned(() async {
          await sessions.writeSnapshot(_draft!);
          await sessions.markInterrupted(s.sessionId);
        });
      } on Object {
        checkpointFailed = true;
      }
    } finally {
      busy = false;
      _emit();
    }
  }

  Future<void> recover(
    String id, {
    required bool continueSession,
    bool manual = false,
  }) async {
    if (busy || isLive) throw StateError('Measurement in progress');
    busy = true;
    failed = false;
    _emit();
    try {
      final stored = await sessions.readSnapshot();
      final row = await sessions.get(id);
      final snapshot = stored?.sessionId == id ? stored : null;
      if (snapshot == null && row == null) throw StateError('Missing session');
      final started = snapshot?.startedAt ?? row!.startedAt;
      final recovered = SessionTimeline.recover(
        snapshot: snapshot,
        sessionStartedAt: started,
        newId: newUuid,
      );
      preferences = await settings.get();
      _original = recovered.segments;
      correctedIds.clear();
      saveState = const MeasureUnsaved();
      completeTask = false;
      final recoveryMode = manual
          ? SessionMode.manual
          : snapshot?.mode ?? row!.mode;
      _draft = SessionSnapshot(
        sessionId: id,
        mode: recoveryMode,
        kind: snapshot?.kind ?? row!.kind,
        startedAt: started,
        segments: _original,
        openKind: SegmentKind.paused,
        openStart: recovered.endedAt,
        savedAt: recovered.endedAt,
        sensitivity: snapshot?.sensitivity ?? row!.sensitivityLevel,
        subjectId: snapshot?.subjectId ?? row?.subjectId,
        plannerItemId: snapshot?.plannerItemId ?? row?.plannerItemId,
      );
      final draft = _draft!;
      await _owned(() async {
        if (row == null) await sessions.startActive(draft);
        await sessions.markInterrupted(id);
      });
      phase = MeasurePhase.summary;
      _recovered = true;
      if (continueSession) {
        // A new process gets a fresh monotonic anchor; the unobserved gap is paused.
        final anchor = wall.now().isBefore(recovered.endedAt)
            ? recovered.endedAt
            : wall.now();
        _clock = SessionClock(wall: FixedClock(anchor), monotonic: monotonic)
          ..start();
        _timeline = SessionTimeline.fromSnapshot(_draft!, newId: newUuid);
        _timeline!.resume(now);
        _todayBaseSeconds = await _todaySeatedBefore(id);
        _draft = null;
        phase = MeasurePhase.focus;
        cameraLost = false;
        reconnectFailed = false;
        await _activate();
      }
    } on Object {
      failed = true;
      rethrow;
    } finally {
      busy = false;
      _emit();
      _resumePending();
    }
  }

  void correct(String id) {
    if (busy || saveState is MeasureSaved) return;
    if (_original.any((s) => s.id == id && s.kind == SegmentKind.away)) {
      correctedIds.add(id);
      saveState = const MeasureUnsaved();
      _emit();
    }
  }

  Future<bool> save() async {
    if (busy || _draft == null || saveState is MeasureSaved) return false;
    busy = true;
    saveState = const MeasureSaving();
    _emit();
    final draft = _draft!;
    try {
      await _writes;
      await _owned(() async {
        await sessions.saveFinished(
          id: draft.sessionId,
          kind: draft.kind,
          mode: draft.mode,
          startedAt: draft.startedAt,
          endedAt: draft.savedAt,
          status: _recovered
              ? SessionStatus.interrupted
              : SessionStatus.finished,
          segments: _original,
          sensitivityLevel: draft.sensitivity,
          subjectId: draft.subjectId,
          plannerItemId: draft.plannerItemId,
        );
        await persistCorrections(draft.sessionId, correctedIds);
        if (completeTask &&
            draft.plannerItemId != null &&
            await planner.getItem(draft.plannerItemId!) != null) {
          _checkAlive();
          await planner.setDone(draft.plannerItemId!, done: true);
        }
        _checkAlive(); // nothing commits for a disposed controller
      });
      saveState = const MeasureSaved();
      phase = MeasurePhase.saved;
      _draft = null;
      return true;
    } on Object {
      saveState = const MeasureSaveFailed();
      try {
        await _owned(() => sessions.markInterrupted(draft.sessionId));
      } on Object {
        /* disposed, other account, or DB error: snapshot remains */
      }
      return false;
    } finally {
      busy = false;
      _emit();
    }
  }

  /// Records corrections (+ sensitivity). Runs in its own owned transaction;
  /// inside [save] it joins the outer one.
  Future<void> persistCorrections(String id, Iterable<String> ids) =>
      _owned(() => _persistCorrections(id, ids));

  Future<void> _persistCorrections(String id, Iterable<String> ids) async {
    var prefs = await settings.get();
    sensitivityChanged = false;
    final at = wall.now();
    final history = (await sessions.correctionsSince(
      at.subtract(SensitivityPolicy.window),
    )).map((c) => c.at).toList();
    for (final segmentId in ids) {
      final adjustment = const SensitivityPolicy().evaluate(
        currentLevel: prefs.sensitivityLevel,
        correctionsAt: [...history, at],
        now: at,
        auto: prefs.sensitivityAuto,
      );
      _checkAlive();
      final applied = await sessions.applyCorrection(
        sessionId: id,
        segmentId: segmentId,
        toKind: SegmentKind.seated,
        sensitivityBefore: prefs.sensitivityLevel,
        sensitivityAfter: adjustment.level,
      );
      if (applied == null) continue;
      history.add(at);
      if (adjustment.changed) {
        _checkAlive();
        await settings.setSensitivityLevel(adjustment.level);
        prefs = prefs.copyWith(sensitivityLevel: adjustment.level);
        sensitivityChanged = true;
      }
    }
  }

  Future<void> discard([String? id]) async {
    if (busy) throw StateError('Measurement busy');
    busy = true;
    _emit();
    try {
      final target = id ?? sessionId;
      _ticker?.cancel();
      await _stopEngine();
      await _wake(false);
      await _writes;
      if (target != null) await _owned(() => sessions.discard(target));
      _draft = null;
      _timeline = null;
      _original = [];
      correctedIds.clear();
      phase = MeasurePhase.setup;
      saveState = const MeasureUnsaved();
    } finally {
      busy = false;
      _emit();
    }
  }

  void resetSaved() {
    if (phase != MeasurePhase.saved) return;
    _timeline = null;
    _original = [];
    correctedIds.clear();
    sensitivityChanged = false;
    phase = MeasurePhase.setup;
    saveState = const MeasureUnsaved();
    _emit();
  }

  @override
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _ticker?.cancel();
    unawaited(_stopEngine());
    unawaited(_wake(false));
    super.dispose();
  }
}
