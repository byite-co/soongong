// SeatLabRecorder (S04 · S04b, pure Dart). Keeps the `/_seat_lab` measurement
// log: processed frames (detected / seated / latency, capture and completion
// time), engine events, manual ground-truth marks, battery readings, the
// protocol case id and the run segments (start → stop). A segment that ended
// abnormally (engine stopped itself, camera lost at the stop, error, or a
// detection that outlived the stop bound) is marked excluded: its samples
// stay in the CSV but leave the summary statistics (design reference:
// focus-engine's "stop integrity" verdict — a session whose stop was not
// clean is not comparable). Facts only — no scoring, no grading.

import 'dart:convert';
import 'dart:typed_data';

/// What the person says is actually happening (ground truth for the CSV).
enum SeatLabTruth { none, seated, away }

enum SeatLabRowKind { sample, event, mark, battery }

enum SeatLabSegmentEnd { normal, abnormal }

/// One run of the engine: start → stop.
class SeatLabSegment {
  SeatLabSegment({required this.index, required this.start});

  final int index;
  final Duration start;
  Duration? end;
  SeatLabSegmentEnd? endKind;
  String reason = '';

  bool get isOpen => end == null;

  /// Ended abnormally → left out of the summary.
  bool get isExcluded => endKind == SeatLabSegmentEnd.abnormal;

  Duration durationAt(Duration now) => (end ?? now) - start;
}

class SeatLabRow {
  const SeatLabRow({
    required this.t,
    required this.kind,
    required this.truth,
    required this.caseId,
    this.segment,
    this.detected,
    this.seated,
    this.held,
    this.completed,
    this.battery,
    this.note = '',
  });

  /// Row time on the lab time base. For a sample: the frame's capture time.
  final Duration t;
  final SeatLabRowKind kind;
  final SeatLabTruth truth;
  final String caseId;

  /// Segment the row belongs to (`null` outside a run).
  final int? segment;
  final bool? detected;
  final bool? seated;
  final bool? held;

  /// Sample only: when the detection returned.
  final Duration? completed;
  final int? battery;
  final String note;

  /// Sample only: capture → result.
  Duration? get latency => completed == null ? null : completed! - t;
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
  final List<SeatLabSegment> _segments = <SeatLabSegment>[];
  SeatLabTruth _truth = SeatLabTruth.none;
  String _caseId = '';
  int? _batteryStart;
  int? _batteryLast;

  List<SeatLabRow> get rows => List<SeatLabRow>.unmodifiable(_rows);
  List<SeatLabSegment> get segments => List<SeatLabSegment>.unmodifiable(_segments);
  SeatLabTruth get truth => _truth;
  String get caseId => _caseId;
  int? get batteryStart => _batteryStart;
  int? get batteryLast => _batteryLast;

  /// The run in progress, if any.
  SeatLabSegment? get currentSegment {
    if (_segments.isEmpty) return null;
    final last = _segments.last;
    return last.isOpen ? last : null;
  }

  /// The most recent run, open or closed.
  SeatLabSegment? get lastSegment => _segments.isEmpty ? null : _segments.last;

  int get excludedSegments => _segments.where((s) => s.isExcluded).length;

  /// Battery drop since the first reading (positive = consumed).
  int? get batteryDelta {
    final a = _batteryStart;
    final b = _batteryLast;
    return a == null || b == null ? null : a - b;
  }

  int? get _segmentIndex => currentSegment?.index;

  // ── Segments ───────────────────────────────────────────────────────────

  /// Engine start. Returns the new segment.
  SeatLabSegment beginSegment(Duration t) {
    final open = currentSegment;
    if (open != null) {
      endSegment(t, end: SeatLabSegmentEnd.abnormal, reason: 'restart');
    }
    final s = SeatLabSegment(index: _segments.length + 1, start: t);
    _segments.add(s);
    _rows.add(
      SeatLabRow(
        t: t,
        kind: SeatLabRowKind.event,
        truth: _truth,
        caseId: _caseId,
        segment: s.index,
        note: 'start',
      ),
    );
    return s;
  }

  /// Engine stop. [reason] is kept on the segment and in the CSV note.
  void endSegment(Duration t, {required SeatLabSegmentEnd end, String reason = ''}) {
    final s = currentSegment;
    if (s == null) return;
    s
      ..end = t
      ..endKind = end
      ..reason = reason;
    _rows.add(
      SeatLabRow(
        t: t,
        kind: SeatLabRowKind.event,
        truth: _truth,
        caseId: _caseId,
        segment: s.index,
        note: reason.isEmpty ? 'stop · ${end.name}' : 'stop · ${end.name} · $reason',
      ),
    );
  }

  // ── Rows ───────────────────────────────────────────────────────────────

  /// One processed frame. [t] is the capture time, [completed] when the
  /// detection returned (same time base).
  void sample(
    Duration t, {
    required bool detected,
    required bool seated,
    required bool held,
    required Duration completed,
  }) =>
      _rows.add(
        SeatLabRow(
          t: t,
          kind: SeatLabRowKind.sample,
          truth: _truth,
          caseId: _caseId,
          segment: _segmentIndex,
          detected: detected,
          seated: seated,
          held: held,
          completed: completed,
        ),
      );

  void event(Duration t, String name) => _rows.add(
        SeatLabRow(
          t: t,
          kind: SeatLabRowKind.event,
          truth: _truth,
          caseId: _caseId,
          segment: _segmentIndex,
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
        segment: _segmentIndex,
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
        segment: _segmentIndex,
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
        segment: _segmentIndex,
        battery: level,
      ),
    );
  }

  void clear() {
    _rows.clear();
    _segments.clear();
    _batteryStart = null;
    _batteryLast = null;
  }

  // ── Statistics (excluded segments left out) ────────────────────────────

  bool _isExcluded(SeatLabRow r) {
    final i = r.segment;
    if (i == null) return false;
    return _segments[i - 1].isExcluded;
  }

  Iterable<SeatLabRow> get _allSamples =>
      _rows.where((r) => r.kind == SeatLabRowKind.sample);

  /// Samples that count: not in an excluded segment.
  Iterable<SeatLabRow> get _samples => _allSamples.where((r) => !_isExcluded(r));

  Iterable<SeatLabRow> _recentSamples(Duration now) {
    final floor = now - window;
    return _samples.where((r) => r.t >= floor && r.t <= now);
  }

  /// Processed frames that count (excluded segments left out).
  int get processed => _samples.length;

  /// Processed frames in excluded segments (kept in the CSV only).
  int get excludedSamples => _allSamples.where(_isExcluded).length;

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

  /// `t_ms` is the capture time for samples; `completed_ms` when the
  /// detection returned; `latency_ms` their difference. `excluded` = 1 for
  /// every row of a segment that ended abnormally.
  static const String csvHeader =
      't_ms,kind,segment,excluded,detected,seated,held,completed_ms,latency_ms,truth,battery,case,note';

  String toCsv() {
    final b = StringBuffer()..writeln(csvHeader);
    for (final r in _rows) {
      b.writeln(
        <String>[
          '${r.t.inMilliseconds}',
          r.kind.name,
          r.segment == null ? '' : '${r.segment}',
          _bool(r.segment == null ? null : _isExcluded(r)),
          _bool(r.detected),
          _bool(r.seated),
          _bool(r.held),
          r.completed == null ? '' : '${r.completed!.inMilliseconds}',
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
