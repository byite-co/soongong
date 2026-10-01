// SeatLabRecorder (S04, pure Dart). Keeps the `/_seat_lab` measurement log:
// processed frames (detected / seated / latency), engine events, manual
// ground-truth marks, battery readings and the protocol case id. Produces
// window statistics for the screen and a CSV for QA. Facts only — no
// scoring, no grading.

import 'dart:convert';
import 'dart:typed_data';

/// What the person says is actually happening (ground truth for the CSV).
enum SeatLabTruth { none, seated, away }

enum SeatLabRowKind { sample, event, mark, battery }

class SeatLabRow {
  const SeatLabRow({
    required this.t,
    required this.kind,
    required this.truth,
    required this.caseId,
    this.detected,
    this.seated,
    this.held,
    this.latency,
    this.battery,
    this.note = '',
  });

  /// Elapsed since the recording started.
  final Duration t;
  final SeatLabRowKind kind;
  final SeatLabTruth truth;
  final String caseId;
  final bool? detected;
  final bool? seated;
  final bool? held;
  final Duration? latency;
  final int? battery;
  final String note;
}

/// Agreement between the engine's `seated` output and the manual truth.
class SeatLabAgreement {
  const SeatLabAgreement({
    required this.truthSeated,
    required this.truthSeatedAsSeated,
    required this.truthAway,
    required this.truthAwayAsSeated,
  });

  /// Samples taken while the truth was `seated`, and how many of them came
  /// out seated.
  final int truthSeated;
  final int truthSeatedAsSeated;

  /// Samples taken while the truth was `away`, and how many of them came out
  /// seated anyway (false positives for the (a) negatives).
  final int truthAway;
  final int truthAwayAsSeated;

  double? get seatedDetectionRate =>
      truthSeated == 0 ? null : truthSeatedAsSeated / truthSeated;

  double? get awayFalseSeatedRate =>
      truthAway == 0 ? null : truthAwayAsSeated / truthAway;
}

class SeatLabRecorder {
  SeatLabRecorder({this.window = const Duration(seconds: 60)});

  /// Window for the live statistics (instruction §4.5: last 60 s).
  final Duration window;

  final List<SeatLabRow> _rows = <SeatLabRow>[];
  SeatLabTruth _truth = SeatLabTruth.none;
  String _caseId = '';
  int? _batteryStart;
  int? _batteryLast;

  List<SeatLabRow> get rows => List<SeatLabRow>.unmodifiable(_rows);
  SeatLabTruth get truth => _truth;
  String get caseId => _caseId;
  int? get batteryStart => _batteryStart;
  int? get batteryLast => _batteryLast;

  /// Battery drop since the first reading (positive = consumed).
  int? get batteryDelta {
    final a = _batteryStart;
    final b = _batteryLast;
    return a == null || b == null ? null : a - b;
  }

  void sample(
    Duration t, {
    required bool detected,
    required bool seated,
    required bool held,
    required Duration latency,
  }) =>
      _rows.add(
        SeatLabRow(
          t: t,
          kind: SeatLabRowKind.sample,
          truth: _truth,
          caseId: _caseId,
          detected: detected,
          seated: seated,
          held: held,
          latency: latency,
        ),
      );

  void event(Duration t, String name) => _rows.add(
        SeatLabRow(
          t: t,
          kind: SeatLabRowKind.event,
          truth: _truth,
          caseId: _caseId,
          note: name,
        ),
      );

  void mark(Duration t, SeatLabTruth truth) {
    _truth = truth;
    _rows.add(
      SeatLabRow(
        t: t,
        kind: SeatLabRowKind.mark,
        truth: truth,
        caseId: _caseId,
        note: truth.name,
      ),
    );
  }

  void setCase(Duration t, String caseId) {
    _caseId = caseId;
    _rows.add(
      SeatLabRow(
        t: t,
        kind: SeatLabRowKind.mark,
        truth: _truth,
        caseId: caseId,
        note: 'case',
      ),
    );
  }

  void battery(Duration t, int level) {
    _batteryStart ??= level;
    _batteryLast = level;
    _rows.add(
      SeatLabRow(
        t: t,
        kind: SeatLabRowKind.battery,
        truth: _truth,
        caseId: _caseId,
        battery: level,
      ),
    );
  }

  void clear() {
    _rows.clear();
    _batteryStart = null;
    _batteryLast = null;
  }

  // ── Statistics ─────────────────────────────────────────────────────────

  Iterable<SeatLabRow> get _samples =>
      _rows.where((r) => r.kind == SeatLabRowKind.sample);

  Iterable<SeatLabRow> _recentSamples(Duration now) {
    final floor = now - window;
    return _samples.where((r) => r.t >= floor && r.t <= now);
  }

  int get processed => _samples.length;

  int get detectedCount => _samples.where((r) => r.detected ?? false).length;

  int get eventCount => _rows.where((r) => r.kind == SeatLabRowKind.event).length;

  /// Detected frames / processed frames inside the window; `null` when the
  /// window holds no sample.
  double? detectionRate(Duration now) {
    final recent = _recentSamples(now).toList();
    if (recent.isEmpty) return null;
    return recent.where((r) => r.detected ?? false).length / recent.length;
  }

  /// Seated output / processed frames inside the window.
  double? seatedRate(Duration now) {
    final recent = _recentSamples(now).toList();
    if (recent.isEmpty) return null;
    return recent.where((r) => r.seated ?? false).length / recent.length;
  }

  Duration? meanLatency(Duration now) {
    final recent = _recentSamples(now).toList();
    if (recent.isEmpty) return null;
    var total = 0;
    for (final r in recent) {
      total += r.latency?.inMicroseconds ?? 0;
    }
    return Duration(microseconds: total ~/ recent.length);
  }

  SeatLabAgreement agreement() {
    var ts = 0, tss = 0, ta = 0, tas = 0;
    for (final r in _samples) {
      switch (r.truth) {
        case SeatLabTruth.seated:
          ts++;
          if (r.seated ?? false) tss++;
        case SeatLabTruth.away:
          ta++;
          if (r.seated ?? false) tas++;
        case SeatLabTruth.none:
          break;
      }
    }
    return SeatLabAgreement(
      truthSeated: ts,
      truthSeatedAsSeated: tss,
      truthAway: ta,
      truthAwayAsSeated: tas,
    );
  }

  // ── CSV ────────────────────────────────────────────────────────────────

  static const String csvHeader =
      't_ms,kind,detected,seated,held,latency_ms,truth,battery,case,note';

  String toCsv() {
    final b = StringBuffer()..writeln(csvHeader);
    for (final r in _rows) {
      b.writeln(
        <String>[
          '${r.t.inMilliseconds}',
          r.kind.name,
          _bool(r.detected),
          _bool(r.seated),
          _bool(r.held),
          r.latency == null ? '' : '${r.latency!.inMilliseconds}',
          r.truth.name,
          r.battery == null ? '' : '${r.battery}',
          _csvField(r.caseId),
          _csvField(r.note),
        ].join(','),
      );
    }
    return b.toString();
  }

  Uint8List toCsvBytes() => Uint8List.fromList(utf8.encode(toCsv()));

  static String _bool(bool? v) => v == null ? '' : (v ? '1' : '0');

  static String _csvField(String v) {
    if (v.isEmpty) return '';
    if (v.contains(',') || v.contains('"') || v.contains('\n')) {
      return '"${v.replaceAll('"', '""')}"';
    }
    return v;
  }
}
