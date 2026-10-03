// `/_seat_lab` (S04 · S04b, dev flavor only): measurement harness for
// SeatEngineImpl. Shows the live seated boolean, per-frame latency, the
// detection rate over the last 60 s, elapsed time, battery drop, engine
// events, and lets the tester mark the real state (ground truth) and the
// protocol case; everything goes into a CSV (docs/seat-engine.md §4).
//
// The screen owns its own engine instance (not the provider's) so the
// diagnostics stream is available and the minFaceSize can be changed. The
// engine shares the lab's monotonic clock, so sample rows carry the frame's
// capture time and the detection's completion time on one time base. Each
// start → stop is a segment; one that ends abnormally (engine stopped
// itself, camera lost at the stop, error, detection outliving the stop
// bound) is marked excluded from the summary. No preview is shown — the
// status icon is the only camera feedback, as on the real measurement screen.

import 'dart:async';

import 'package:battery_plus/battery_plus.dart';
import 'package:flutter/material.dart';

import '../../../data/engines/engines.dart';
import '../../../data/export/export_service.dart';
import '../../../data/export/share_export.dart';
import '../../contracts/seat_engine.dart';
import '../../domain/clock.dart';
import '../../logging/app_logger.dart';
import '../../strings/seat_lab_strings.dart';
import '../../theme/app_theme.dart';
import '../../theme/tokens.dart';
import '../../widgets/widgets.dart';
import 'seat_lab_recorder.dart';

const String seatLabPath = '/_seat_lab';

typedef SeatLabEngineBuilder = SeatEngineImpl Function({
  required double minFaceSize,
  required MonotonicClock monotonic,
});
typedef SeatLabBatteryReader = Future<int?> Function();
typedef SeatLabShare = Future<void> Function(ExportFile file);

enum _LabState { idle, starting, running, lost }

class SeatLabScreen extends StatefulWidget {
  const SeatLabScreen({
    super.key,
    this.engineBuilder,
    this.batteryReader,
    this.share,
    this.monotonic,
    this.batteryPollInterval = const Duration(seconds: 60),
  });

  /// Test seam. Default: [SeatEngineImpl.camera].
  final SeatLabEngineBuilder? engineBuilder;

  /// Test seam. Default: `battery_plus` (`null` when the platform cannot
  /// report a level).
  final SeatLabBatteryReader? batteryReader;

  /// Test seam. Default: the system share sheet.
  final SeatLabShare? share;

  /// Lab time base, shared with the engine (test seam; default: a stopwatch).
  final MonotonicClock? monotonic;

  final Duration batteryPollInterval;

  @override
  State<SeatLabScreen> createState() => _SeatLabScreenState();
}

class _SeatLabScreenState extends State<SeatLabScreen> {
  static const List<double> _minFaceSizes = <double>[0.1, 0.15, 0.2];

  final SeatLabRecorder _recorder = SeatLabRecorder();
  final List<String> _eventLog = <String>[];
  late final MonotonicClock _mono = widget.monotonic ?? StopwatchMonotonicClock();
  late final Duration _t0 = _mono.elapsed;

  SeatEngineImpl? _engine;
  StreamSubscription<SeatDiagnostic>? _diagSub;
  StreamSubscription<SeatEngineEvent>? _eventSub;
  Timer? _uiTimer;
  Timer? _batteryTimer;

  _LabState _state = _LabState.idle;
  SeatDiagnostic? _lastDiag;
  bool _lowPower = false;
  double _minFaceSize = MlKitFacePresenceDetector.defaultMinFaceSize;
  String _caseId = '';
  String? _availability;
  String? _permission;
  bool _busy = false;
  bool _lostNow = false;
  bool _segmentHadError = false;

  bool get _running => _state == _LabState.running || _state == _LabState.lost;

  /// Lab time base: elapsed since the screen opened, on the shared clock.
  Duration get _now => _mono.elapsed - _t0;

  Duration get _segmentElapsed =>
      _recorder.lastSegment?.durationAt(_now) ?? Duration.zero;

  SeatEngineImpl _ensureEngine() {
    final existing = _engine;
    if (existing != null) return existing;
    final build = widget.engineBuilder ??
        ({required double minFaceSize, required MonotonicClock monotonic}) =>
            SeatEngineImpl.camera(minFaceSize: minFaceSize, monotonic: monotonic);
    final engine = build(minFaceSize: _minFaceSize, monotonic: _mono);
    _diagSub = engine.diagnostics.listen(_onDiagnostic);
    _eventSub = engine.events.listen(_onEvent);
    _engine = engine;
    return engine;
  }

  Future<void> _disposeEngine() async {
    // Broadcast-subscription cancel futures complete in the root zone; not
    // awaited so this also completes under flutter_test's fake async.
    unawaited(_diagSub?.cancel());
    unawaited(_eventSub?.cancel());
    _diagSub = null;
    _eventSub = null;
    final e = _engine;
    _engine = null;
    await e?.dispose();
  }

  @override
  void dispose() {
    _uiTimer?.cancel();
    _batteryTimer?.cancel();
    unawaited(_disposeEngine());
    super.dispose();
  }

  // ── Engine callbacks ───────────────────────────────────────────────────

  void _onDiagnostic(SeatDiagnostic d) {
    // Same clock as the engine: capture and completion land on the lab base.
    _recorder.sample(
      d.capturedAt - _t0,
      detected: d.detected,
      seated: d.seated,
      held: d.held,
      completed: d.completedAt - _t0,
    );
    if (!mounted) return;
    setState(() => _lastDiag = d);
  }

  void _onEvent(SeatEngineEvent e) {
    final name = switch (e) {
      SeatCameraLost() => SeatLabStrings.eventCameraLost,
      SeatCameraRecovered() => SeatLabStrings.eventCameraRecovered,
      SeatError(:final message) => '${SeatLabStrings.eventError}: $message',
    };
    _log(name);
    if (!mounted) return;
    setState(() {
      switch (e) {
        case SeatCameraLost():
          _lostNow = true;
          _state = _LabState.lost;
        case SeatCameraRecovered():
          _lostNow = false;
          _state = _LabState.running;
        case SeatError():
          if (_running) _segmentHadError = true;
          if (!(_engine?.isRunning ?? false) && _state == _LabState.starting) {
            _state = _LabState.idle;
          }
      }
    });
    _checkSelfStop();
  }

  void _log(String name) {
    _recorder.event(_now, name);
    _logLine(name);
  }

  void _logLine(String name) {
    _eventLog.insert(0, '${_fmtElapsed(_now)} · $name');
    if (_eventLog.length > 10) _eventLog.removeLast();
  }

  /// The engine stopped on its own (background → auto stop): close the
  /// segment as abnormal so its samples leave the summary.
  void _checkSelfStop() {
    final engine = _engine;
    if (!_running || _busy || engine == null || engine.isRunning) return;
    final reason = switch (engine.lastStopReason) {
      SeatEngineStopReason.background => SeatLabStrings.reasonBackground,
      _ => SeatLabStrings.reasonSelfStop,
    };
    _finishSegment(end: SeatLabSegmentEnd.abnormal, reason: reason);
    _logLine(SeatLabStrings.eventSelfStopped);
    _stopTimers();
    if (mounted) setState(() => _state = _LabState.idle);
  }

  void _finishSegment({required SeatLabSegmentEnd end, String reason = ''}) {
    if (_recorder.currentSegment == null) return;
    _recorder.endSegment(_now, end: end, reason: reason);
  }

  void _stopTimers() {
    _uiTimer?.cancel();
    _uiTimer = null;
    _batteryTimer?.cancel();
    _batteryTimer = null;
  }

  // ── Actions ────────────────────────────────────────────────────────────

  Future<void> _start() async {
    if (_busy || _running) return;
    setState(() {
      _busy = true;
      _state = _LabState.starting;
    });
    final engine = _ensureEngine();
    _lostNow = false;
    _segmentHadError = false;
    _recorder.beginSegment(_now);
    _logLine(SeatLabStrings.eventStarted);
    await _readBattery();
    try {
      await engine.start(SeatEngineConfig(lowPower: _lowPower));
    } catch (e, st) {
      appLog.w('seat lab: start failed', error: e, stackTrace: st);
    }
    if (!mounted) return;
    setState(() {
      _busy = false;
      _state = engine.isRunning ? _LabState.running : _LabState.idle;
    });
    if (engine.isRunning) {
      _uiTimer ??= Timer.periodic(const Duration(seconds: 1), (_) {
        if (!mounted) return;
        setState(() {});
        _checkSelfStop();
      });
      _batteryTimer ??= Timer.periodic(widget.batteryPollInterval, (_) => _readBattery());
    } else {
      // start failed: the segment never ran
      _finishSegment(
        end: SeatLabSegmentEnd.abnormal,
        reason: SeatLabStrings.reasonError,
      );
    }
  }

  Future<void> _stop() async {
    if (_busy) return;
    setState(() => _busy = true);
    final engine = _engine;
    try {
      await engine?.stop();
    } finally {
      _stopTimers();
      final report = engine?.lastStopReport;
      final String? abnormal = report != null && report.inferenceTimedOut
          ? SeatLabStrings.reasonInferenceTimeout
          : _lostNow
              ? SeatLabStrings.reasonLost
              : _segmentHadError
                  ? SeatLabStrings.reasonError
                  : null;
      _finishSegment(
        end: abnormal == null ? SeatLabSegmentEnd.normal : SeatLabSegmentEnd.abnormal,
        reason: abnormal ?? '',
      );
      _logLine(SeatLabStrings.eventStopped);
      await _readBattery();
      if (mounted) {
        setState(() {
          _busy = false;
          _state = _LabState.idle;
        });
      }
    }
  }

  Future<void> _readBattery() async {
    int? level;
    try {
      level = await (widget.batteryReader ?? _platformBattery)();
    } catch (e) {
      appLog.d('seat lab: battery unavailable ($e)');
    }
    if (level != null) _recorder.battery(_now, level);
    if (mounted) setState(() {});
  }

  static Future<int?> _platformBattery() => Battery().batteryLevel;

  Future<void> _checkAvailability() async {
    final a = await _ensureEngine().checkAvailability();
    if (!mounted) return;
    setState(() => _availability = a.name);
  }

  Future<void> _requestPermission() async {
    final r = await _ensureEngine().permissionGateway.request();
    if (!mounted) return;
    setState(() => _permission = r.name);
  }

  Future<void> _openSettings() => _ensureEngine().permissionGateway.openSettings();

  Future<void> _export() async {
    final stamp = DateTime.now().toIso8601String().replaceAll(':', '-');
    final file = ExportFile(
      name: 'seat_lab_$stamp.csv',
      bytes: _recorder.toCsvBytes(),
      mimeType: 'text/csv',
    );
    try {
      await (widget.share ?? shareExportFile)(file);
      if (mounted) showAppToast(context, message: SeatLabStrings.exported);
    } catch (e, st) {
      appLog.w('seat lab: export failed', error: e, stackTrace: st);
      if (mounted) showAppToast(context, message: SeatLabStrings.exportFailed);
    }
  }

  void _clearLog() => setState(() {
        _recorder.clear();
        _eventLog.clear();
        _lastDiag = null;
        if (_running) _recorder.beginSegment(_now); // the run in progress stays tracked
      });

  Future<void> _setMinFaceSize(double v) async {
    if (_running || v == _minFaceSize) return;
    setState(() => _minFaceSize = v);
    await _disposeEngine(); // the detector is rebuilt with the new size on next use
  }

  void _setTruth(SeatLabTruth t) => setState(() => _recorder.mark(_now, t));

  void _setCase(String id) => setState(() {
        _caseId = id;
        _recorder.setCase(_now, id);
      });

  // ── Build ──────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Scaffold(
      appBar: AppBar(
        title: const Text(SeatLabStrings.title),
        actions: <Widget>[
          IconButton(
            tooltip: SeatLabStrings.exportCsv,
            icon: const LucideIcon(LucideIcons.share),
            onPressed: _export,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.page,
          AppSpacing.s8,
          AppSpacing.page,
          AppSpacing.sheetBottom,
        ),
        children: <Widget>[
          Text(SeatLabStrings.subtitle, style: AppTypography.caption.copyWith(color: c.tx3)),
          const SizedBox(height: AppSpacing.s12),
          _Card(title: SeatLabStrings.sectionStatus, child: _statusBody(c)),
          _Card(title: SeatLabStrings.sectionNumbers, child: _numbersBody(c)),
          _Card(title: SeatLabStrings.sectionControls, child: _controlsBody(c)),
          _Card(title: SeatLabStrings.sectionTruth, child: _truthBody(c)),
          _Card(title: SeatLabStrings.sectionSettings, child: _settingsBody(c)),
          _Card(title: SeatLabStrings.sectionEvents, child: _eventsBody(c)),
        ],
      ),
    );
  }

  Widget _statusBody(AppColors c) {
    final d = _lastDiag;
    final (IconData icon, String text, Color color) = switch (_state) {
      _LabState.idle => (LucideIcons.cameraOff, SeatLabStrings.stateIdle, c.tx3),
      _LabState.starting => (LucideIcons.camera, SeatLabStrings.stateStarting, c.tx2),
      _LabState.lost => (LucideIcons.cameraOff, SeatLabStrings.stateLost, c.accTx),
      _LabState.running => d == null
          ? (LucideIcons.camera, SeatLabStrings.noSampleYet, c.tx2)
          : d.seated
              ? (LucideIcons.userCheck, SeatLabStrings.seated, c.priTx)
              : (LucideIcons.userX, SeatLabStrings.notSeated, c.tx2),
    };
    return Row(
      children: <Widget>[
        LucideIcon(icon, size: AppIcon.sizeLarge, color: color),
        const SizedBox(width: AppSpacing.s12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(text, style: AppTypography.title.copyWith(color: color)),
              const SizedBox(height: AppSpacing.s4),
              Text(
                '${SeatLabStrings.lastFrameDetected}: ${_yesNo(d?.detected)} · '
                '${SeatLabStrings.heldByWindow}: ${_yesNo(d?.held)}',
                style: AppTypography.caption.copyWith(color: c.tx3),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _numbersBody(AppColors c) {
    final e = _engine;
    final now = _now;
    final rate = _recorder.detectionRate(now);
    final seatedRate = _recorder.seatedRate(now);
    final latency = _recorder.meanLatency(now);
    final agreement = _recorder.agreement();
    final bStart = _recorder.batteryStart;
    final bLast = _recorder.batteryLast;
    final battery = bStart == null || bLast == null
        ? SeatLabStrings.batteryUnknown
        : '$bStart% → $bLast% (−${bStart - bLast}%p)';
    final last = _recorder.lastSegment;
    final String lastStop;
    if (last == null || last.isOpen) {
      lastStop = SeatLabStrings.noData;
    } else {
      final kind = last.isExcluded ? SeatLabStrings.segmentAbnormal : SeatLabStrings.segmentNormal;
      lastStop = last.reason.isEmpty ? kind : '$kind · ${last.reason}';
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _Kv(SeatLabStrings.elapsed, _fmtElapsed(_segmentElapsed), c),
        _Kv(
          SeatLabStrings.framesProcessed,
          e == null ? SeatLabStrings.noData : '${e.framesProcessed} / ${e.framesDelivered}',
          c,
        ),
        _Kv(SeatLabStrings.framesDropped, e == null ? SeatLabStrings.noData : '${e.framesDropped}', c),
        _Kv(
          SeatLabStrings.interval,
          e == null ? SeatLabStrings.noData : '${e.processingInterval.inMilliseconds} ms',
          c,
        ),
        _Kv(SeatLabStrings.detectionRate60, _pct(rate), c),
        _Kv(SeatLabStrings.seatedRate60, _pct(seatedRate), c),
        _Kv(SeatLabStrings.latency60, latency == null ? SeatLabStrings.noData : '${latency.inMilliseconds} ms', c),
        _Kv(SeatLabStrings.battery, battery, c),
        _Kv(SeatLabStrings.events, '${_recorder.eventCount}', c),
        _Kv(
          SeatLabStrings.agreementSeated,
          '${agreement.truthSeatedAsSeated} / ${agreement.truthSeated} (${_pct(agreement.seatedDetectionRate)})',
          c,
        ),
        _Kv(
          SeatLabStrings.agreementAway,
          '${agreement.truthAwayAsSeated} / ${agreement.truthAway} (${_pct(agreement.awayFalseSeatedRate)})',
          c,
        ),
        _Kv(
          SeatLabStrings.segments,
          '${_recorder.segments.length} (${_recorder.excludedSegments})',
          c,
        ),
        _Kv(SeatLabStrings.excludedSamples, '${_recorder.excludedSamples}', c),
        _Kv(
          SeatLabStrings.suppressedResults,
          e == null ? SeatLabStrings.noData : '${e.suppressedResults}',
          c,
        ),
        _Kv(SeatLabStrings.lastStop, lastStop, c),
        const SizedBox(height: AppSpacing.s6),
        Text(SeatLabStrings.summaryNote, style: AppTypography.caption.copyWith(color: c.tx3)),
      ],
    );
  }

  Widget _controlsBody(AppColors c) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Wrap(
            spacing: AppSpacing.s8,
            runSpacing: AppSpacing.s8,
            children: <Widget>[
              AppButton.secondary(
                label: SeatLabStrings.checkAvailability,
                size: AppButtonSize.small,
                expand: false,
                onPressed: _checkAvailability,
              ),
              AppButton.secondary(
                label: SeatLabStrings.requestPermission,
                size: AppButtonSize.small,
                expand: false,
                onPressed: _requestPermission,
              ),
              AppButton.secondary(
                label: SeatLabStrings.openSettings,
                size: AppButtonSize.small,
                expand: false,
                onPressed: _openSettings,
              ),
              AppButton.secondary(
                label: SeatLabStrings.exportCsv,
                size: AppButtonSize.small,
                expand: false,
                onPressed: _export,
              ),
              AppButton.secondary(
                label: SeatLabStrings.clearLog,
                size: AppButtonSize.small,
                expand: false,
                onPressed: _clearLog,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.s8),
          Text(
            '${SeatLabStrings.availabilityLabel}: ${_availability ?? SeatLabStrings.noData} · '
            '${SeatLabStrings.permissionLabel}: ${_permission ?? SeatLabStrings.noData}',
            style: AppTypography.caption.copyWith(color: c.tx2),
          ),
          const SizedBox(height: AppSpacing.s12),
          AppButton(
            label: _running ? SeatLabStrings.stop : SeatLabStrings.start,
            variant: _running ? AppButtonVariant.destructive : AppButtonVariant.primary,
            busy: _busy,
            onPressed: _running ? _stop : _start,
          ),
        ],
      );

  Widget _truthBody(AppColors c) => _Choices<SeatLabTruth>(
        value: _recorder.truth,
        onChanged: _setTruth,
        items: const <(SeatLabTruth, String)>[
          (SeatLabTruth.seated, SeatLabStrings.truthSeated),
          (SeatLabTruth.away, SeatLabStrings.truthAway),
          (SeatLabTruth.none, SeatLabStrings.truthNone),
        ],
      );

  Widget _settingsBody(AppColors c) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(SeatLabStrings.lowPower, style: AppTypography.body.copyWith(color: c.tx)),
              ),
              Switch.adaptive(
                value: _lowPower,
                onChanged: _running ? null : (v) => setState(() => _lowPower = v),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.s8),
          Text(SeatLabStrings.minFaceSize, style: AppTypography.label.copyWith(color: c.tx2)),
          const SizedBox(height: AppSpacing.s6),
          _Choices<double>(
            value: _minFaceSize,
            onChanged: _running ? null : _setMinFaceSize,
            items: <(double, String)>[
              for (final v in _minFaceSizes) (v, v.toStringAsFixed(2)),
            ],
          ),
          if (_running)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.s6),
              child: Text(
                SeatLabStrings.settingsLockedWhileRunning,
                style: AppTypography.caption.copyWith(color: c.tx3),
              ),
            ),
          const SizedBox(height: AppSpacing.s12),
          Text(SeatLabStrings.caseLabel, style: AppTypography.label.copyWith(color: c.tx2)),
          const SizedBox(height: AppSpacing.s6),
          _Choices<String>(
            value: _caseId,
            onChanged: _setCase,
            items: <(String, String)>[
              ('', SeatLabStrings.caseNone),
              for (final (id, name) in SeatLabStrings.cases) (id, '$id $name'),
            ],
          ),
        ],
      );

  Widget _eventsBody(AppColors c) {
    if (_eventLog.isEmpty) {
      return Text(SeatLabStrings.eventNone, style: AppTypography.caption.copyWith(color: c.tx3));
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        for (final line in _eventLog)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.s2),
            child: Text(line, style: AppTypography.caption.copyWith(color: c.tx2)),
          ),
      ],
    );
  }

  static String _yesNo(bool? v) =>
      v == null ? SeatLabStrings.noData : (v ? SeatLabStrings.yes : SeatLabStrings.no);

  static String _pct(double? v) =>
      v == null ? SeatLabStrings.noData : '${(v * 100).toStringAsFixed(0)}%';

  static String _fmtElapsed(Duration d) {
    final m = d.inMinutes.toString().padLeft(2, '0');
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.s16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            title,
            style: AppTypography.withWeight(AppTypography.label, 600).copyWith(color: c.tx3),
          ),
          const SizedBox(height: AppSpacing.s8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.s16),
            decoration: BoxDecoration(
              color: c.surface,
              borderRadius: BorderRadius.circular(AppRadius.card),
              border: Border.all(color: c.line),
              boxShadow: c.shadow,
            ),
            child: child,
          ),
        ],
      ),
    );
  }
}

class _Kv extends StatelessWidget {
  const _Kv(this.label, this.value, this.c);

  final String label;
  final String value;
  final AppColors c;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.s4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Expanded(child: Text(label, style: AppTypography.label.copyWith(color: c.tx2))),
            const SizedBox(width: AppSpacing.s12),
            Text(
              value,
              style: AppTypography.label.copyWith(
                color: c.tx,
                fontFeatures: AppTypography.tabularFigures,
              ),
            ),
          ],
        ),
      );
}

class _Choices<T> extends StatelessWidget {
  const _Choices({required this.items, required this.value, required this.onChanged});

  final List<(T, String)> items;
  final T value;
  final ValueChanged<T>? onChanged;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Wrap(
      spacing: AppSpacing.s6,
      runSpacing: AppSpacing.s6,
      children: <Widget>[
        for (final (v, label) in items)
          ChoiceChip(
            label: Text(label),
            selected: v == value,
            onSelected: onChanged == null ? null : (_) => onChanged!(v),
            labelStyle: AppTypography.caption.copyWith(color: v == value ? c.priTx : c.tx2),
            selectedColor: c.priWeak,
            backgroundColor: c.sunk,
            side: BorderSide(color: v == value ? c.pri : c.line),
            showCheckmark: false,
          ),
      ],
    );
  }
}
