// SeatLabRecorder (S04 · S04b · S04c, pure Dart). Keeps the `/_seat_lab`
// measurement log: processed frames (detected / seated / latency, capture
// and completion time), engine events, manual ground-truth marks, battery
// readings, the protocol case id and the run segments (start → stop).
//
// S04c:
//   * Truth and case are change histories. A sample gets the value that was
//     in force at its CAPTURE time, so a label changed while a detection was
//     still running does not re-label the frames captured before the change.
//   * Agreement is available per run and per case, and the CSV can be
//     scoped to everything, one run or one case.
//   * Battery readings belong to the run they were taken in. A run is a
//     valid "60 minutes continuous" battery measurement only when it lasted
//     60 minutes, was never interrupted (camera lost / paused) and has a
//     reading at both ends. Runs are never summed.
//
// A segment that ended abnormally is excluded from the summary (its rows
// stay in the CSV). Facts only — no scoring, no grading.

import 'dart:convert';
import 'dart:typed_data';

/// What the person says is actually happening (ground truth for the CSV).
enum SeatLabTruth { none, seated, away }

enum SeatLabRowKind { sample, event, mark, battery }

enum SeatLabSegmentEnd { normal, abnormal }

/// Which rows a CSV export contains.
enum SeatLabCsvScope { all, run, caseId }

/// One run of the engine: start → stop.
class SeatLabSegment {
  SeatLabSegment({required this.index, required this.start});

  final int index;
  final Duration start;
  Duration? end;
  SeatLabSegmentEnd? endKind;
  String reason = '';

  /// Battery % at the first / last reading taken during this run.
  int? batteryStart;
  int? batteryEnd;

  /// A camera loss or a pause happened during the run.
  bool interrupted = false;
  String interruptReason = '';

  bool get isOpen => end == null;

  /// Ended abnormally → left out of the summary.
  bool get isExcluded => endKind == SeatLabSegmentEnd.abnormal;

  Duration durationAt(Duration now) => (end ?? now) - start;
}

/// Verdict of one run as a battery measurement (docs/seat-engine.md §5.3).
class SeatLabBatteryVerdict {
  const SeatLabBatteryVerdict({
    required this.valid,
    required this.reason,
    required this.duration,
    this.dropPct,
  });

  /// `true` only for an uninterrupted run of at least [SeatLabRecorder.batteryWindow]
  /// with a reading at both ends.
  final bool valid;

  /// `ok` · `interrupted` · `short` · `no_reading` · `open`.
  final String reason;
  final Duration duration;

  /// Start % − end % when both readings exist.
  final int? dropPct;
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

  /// Truth in force at [t] (samples: at the capture time).
  final SeatLabTruth truth;

  /// Case in force at [t].
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

  static const SeatLabAgreement empty = SeatLabAgreement(
    truthSeated: 0,
    truthSeatedAsSeated: 0,
    truthAway: 0,
    truthAwayAsSeated: 0,
  );

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

  int get total => truthSeated + truthAway;
}

class SeatLabRecorder {
  SeatLabRecorder({this.window = const Duration(seconds: 60)});

  /// Window for the live statistics (instruction §4.5: last 60 s).
  final Duration window;

  /// Length a run must reach to count as a battery measurement (PRD §8: %/h).
  static const Duration batteryWindow = Duration(minutes: 60);

  final List<SeatLabRow> _rows = <SeatLabRow>[];
  final List<SeatLabSegment> _segments = <SeatLabSegment>[];
  final List<(Duration, SeatLabTruth)> _truthChanges = <(Duration, SeatLabTruth)>[];
  final List<(Duration, String)> _caseChanges = <(Duration, String)>[];

  List<SeatLabRow> get rows => List<SeatLabRow>.unmodifiable(_rows);
  List<SeatLabSegment> get segments => List<SeatLabSegment>.unmodifiable(_segments);

  /// Current (latest) truth / case.
  SeatLabTruth get truth => _truthChanges.isEmpty ? SeatLabTruth.none : _truthChanges.last.$2;
  String get caseId => _caseChanges.isEmpty ? '' : _caseChanges.last.$2;

  /// Truth in force at [t] (the latest change at or before [t]).
  SeatLabTruth truthAt(Duration t) {
    var out = SeatLabTruth.none;
    for (final (at, v) in _truthChanges) {
      if (at > t) break;
      out = v;
    }
    return out;
  }

  /// Case in force at [t].
  String caseAt(Duration t) {
    var out = '';
    for (final (at, v) in _caseChanges) {
      if (at > t) break;
      out = v;
    }
    return out;
  }

  /// The run in progress, if any.
  SeatLabSegment? get currentSegment {
    if (_segments.isEmpty) return null;
    final last = _segments.last;
    return last.isOpen ? last : null;
  }

  /// The most recent run, open or closed.
  SeatLabSegment? get lastSegment => _segments.isEmpty ? null : _segments.last;

  SeatLabSegment? segment(int index) =>
      index >= 1 && index <= _segments.length ? _segments[index - 1] : null;

  int get excludedSegments => _segments.where((s) => s.isExcluded).length;

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
        truth: truth,
        caseId: caseId,
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
        truth: truth,
        caseId: caseId,
        segment: s.index,
        note: reason.isEmpty ? 'stop · ${end.name}' : 'stop · ${end.name} · $reason',
      ),
    );
  }

  /// Camera lost / paused during the run: the run is no longer a continuous
  /// measurement (battery verdict). Also logs the event.
  void interrupt(Duration t, String name) {
    final s = currentSegment;
    if (s != null && !s.interrupted) {
      s
        ..interrupted = true
        ..interruptReason = name;
    }
    event(t, name);
  }

  // ── Rows ───────────────────────────────────────────────────────────────

  /// One processed frame. [t] is the capture time, [completed] when the
  /// detection returned (same time base). Truth and case are the ones in
  /// force at [t].
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
          truth: truthAt(t),
          caseId: caseAt(t),
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
          truth: truth,
          caseId: caseId,
          segment: _segmentIndex,
          note: name,
        ),
      );

  void mark(Duration t, SeatLabTruth truth) {
    _truthChanges.add((t, truth));
    _rows.add(
      SeatLabRow(
        t: t,
        kind: SeatLabRowKind.mark,
        truth: truth,
        caseId: caseId,
        segment: _segmentIndex,
        note: truth.name,
      ),
    );
  }

  void setCase(Duration t, String caseId) {
    _caseChanges.add((t, caseId));
    _rows.add(
      SeatLabRow(
        t: t,
        kind: SeatLabRowKind.mark,
        truth: truth,
        caseId: caseId,
        segment: _segmentIndex,
        note: 'case',
      ),
    );
  }

  /// Battery reading. Attributed to the run in progress (first → start,
  /// latest → end); readings outside a run are logged only.
  void battery(Duration t, int level) {
    final s = currentSegment;
    if (s != null) {
      s.batteryStart ??= level;
      s.batteryEnd = level;
    }
    _rows.add(
      SeatLabRow(
        t: t,
        kind: SeatLabRowKind.battery,
        truth: truth,
        caseId: caseId,
        segment: _segmentIndex,
        battery: level,
      ),
    );
  }

  /// Clears rows and runs. The current truth / case labels are kept (they
  /// describe the situation, not the log).
  void clear() {
    final t = truth;
    final c = caseId;
    _rows.clear();
    _segments.clear();
    _truthChanges
      ..clear()
      ..add((Duration.zero, t));
    _caseChanges
      ..clear()
      ..add((Duration.zero, c));
  }

  // ── Battery (per run, never summed) ────────────────────────────────────

  SeatLabBatteryVerdict batteryVerdict(SeatLabSegment s, Duration now) {
    final d = s.durationAt(now);
    final int? drop = s.batteryStart == null || s.batteryEnd == null
        ? null
        : s.batteryStart! - s.batteryEnd!;
    if (s.isOpen) {
      return SeatLabBatteryVerdict(valid: false, reason: 'open', duration: d, dropPct: drop);
    }
    if (s.interrupted) {
      return SeatLabBatteryVerdict(valid: false, reason: 'interrupted', duration: d, dropPct: drop);
    }
    if (d < batteryWindow) {
      return SeatLabBatteryVerdict(valid: false, reason: 'short', duration: d, dropPct: drop);
    }
    if (drop == null) {
      return SeatLabBatteryVerdict(valid: false, reason: 'no_reading', duration: d);
    }
    return SeatLabBatteryVerdict(valid: true, reason: 'ok', duration: d, dropPct: drop);
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

  static SeatLabAgreement _agree(Iterable<SeatLabRow> samples) {
    var ts = 0, tss = 0, ta = 0, tas = 0;
    for (final r in samples) {
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

  /// All counted samples.
  SeatLabAgreement agreement() => _agree(_samples);

  /// One run (included or not — the caller decides what to show).
  SeatLabAgreement agreementForRun(int segment) =>
      _agree(_allSamples.where((r) => r.segment == segment));

  /// Per case, counted samples only, in first-seen order.
  Map<String, SeatLabAgreement> agreementByCase() {
    final byCase = <String, List<SeatLabRow>>{};
    for (final r in _samples) {
      if (r.caseId.isEmpty) continue;
      byCase.putIfAbsent(r.caseId, () => <SeatLabRow>[]).add(r);
    }
    return <String, SeatLabAgreement>{
      for (final e in byCase.entries) e.key: _agree(e.value),
    };
  }

  // ── CSV ────────────────────────────────────────────────────────────────

  /// `t_ms` is the capture time for samples; `completed_ms` when the
  /// detection returned; `latency_ms` their difference. `excluded` = 1 for
  /// every row of a segment that ended abnormally.
  static const String csvHeader =
      't_ms,kind,segment,excluded,detected,seated,held,completed_ms,latency_ms,truth,battery,case,note';

  Iterable<SeatLabRow> rowsIn({
    SeatLabCsvScope scope = SeatLabCsvScope.all,
    int? segment,
    String? caseId,
  }) =>
      switch (scope) {
        SeatLabCsvScope.all => _rows,
        SeatLabCsvScope.run => _rows.where((r) => r.segment == segment),
        SeatLabCsvScope.caseId => _rows.where((r) => r.caseId == caseId),
      };

  String toCsv({
    SeatLabCsvScope scope = SeatLabCsvScope.all,
    int? segment,
    String? caseId,
  }) {
    final b = StringBuffer()..writeln(csvHeader);
    for (final r in rowsIn(scope: scope, segment: segment, caseId: caseId)) {
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

  Uint8List toCsvBytes({
    SeatLabCsvScope scope = SeatLabCsvScope.all,
    int? segment,
    String? caseId,
  }) =>
      Uint8List.fromList(utf8.encode(toCsv(scope: scope, segment: segment, caseId: caseId)));

  static String _bool(bool? v) => v == null ? '' : (v ? '1' : '0');

  static String _csvField(String v) {
    if (v.isEmpty) return '';
    if (v.contains(',') || v.contains('"') || v.contains('\n')) {
      return '"${v.replaceAll('"', '""')}"';
    }
    return v;
  }
}
