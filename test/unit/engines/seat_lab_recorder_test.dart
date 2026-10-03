import 'package:flutter_test/flutter_test.dart';
import 'package:soongong/core/dev/seat_lab/seat_lab_recorder.dart';

Duration s(int seconds) => Duration(seconds: seconds);
Duration m(int minutes) => Duration(minutes: minutes);
Duration ms(int v) => Duration(milliseconds: v);

void _samples(SeatLabRecorder r, {required int from, required int count, required bool seated, bool? detected}) {
  for (var i = 0; i < count; i++) {
    final t = s(from + i);
    r.sample(t, detected: detected ?? seated, seated: seated, held: false, completed: t + ms(20));
  }
}

void main() {
  test('window statistics and agreement', () {
    final r = SeatLabRecorder(window: const Duration(seconds: 10));
    r.beginSegment(s(0), batteryStart: 80);
    r.mark(s(0), SeatLabTruth.seated);
    for (var t = 1; t <= 5; t++) {
      r.sample(s(t), detected: true, seated: true, held: false, completed: s(t) + ms(20));
    }
    r.sample(s(6), detected: false, seated: true, held: true, completed: s(6) + ms(40));
    r.mark(s(7), SeatLabTruth.away);
    r.sample(s(8), detected: false, seated: false, held: false, completed: s(8) + ms(10));
    r.sample(s(9), detected: true, seated: true, held: false, completed: s(9) + ms(10));
    r.event(s(9), 'cameraLost');
    r.battery(s(10), 79);

    expect(r.processed, 8);
    expect(r.detectedCount, 6);
    expect(r.eventCount, 2, reason: 'start + cameraLost');
    expect(r.lastSegment!.batteryStart, 80);
    expect(r.lastSegment!.batteryLatest, 79, reason: 'periodic reading: latest only');
    expect(r.lastSegment!.batteryEnd, isNull, reason: 'the end is its own measurement');
    expect(r.detectionRate(s(10)), closeTo(6 / 8, 1e-9));
    expect(r.seatedRate(s(10)), closeTo(7 / 8, 1e-9));
    expect(r.meanLatency(s(10)), const Duration(milliseconds: 20));
    expect(r.detectionRate(s(20)), isNull);
    expect(r.meanLatency(s(20)), isNull);

    final a = r.agreement();
    expect(a.truthSeated, 6);
    expect(a.truthSeatedAsSeated, 6);
    expect(a.truthAway, 2);
    expect(a.truthAwayAsSeated, 1);
    expect(a.seatedDetectionRate, 1.0);
    expect(a.awayFalseSeatedRate, 0.5);
    expect(r.currentSegment!.durationAt(s(10)), s(10));
  });

  test('no truth → agreement empty, rates null', () {
    final r = SeatLabRecorder();
    expect(r.detectionRate(Duration.zero), isNull);
    final a = r.agreement();
    expect(a.seatedDetectionRate, isNull);
    expect(a.awayFalseSeatedRate, isNull);
    expect(r.currentSegment, isNull);
    expect(r.lastSegment, isNull);
    expect(r.agreementByCase(), isEmpty);
  });

  group('S04c labels from the change history', () {
    test('a sample recorded after a truth change but captured before it keeps the old truth', () {
      final r = SeatLabRecorder();
      r.beginSegment(s(0));
      r.mark(s(0), SeatLabTruth.seated);
      r.setCase(s(0), 'P1');
      r.mark(s(5), SeatLabTruth.away); // the person stood up at t=5
      r.setCase(s(5), 'N1');
      // Late inference: the frame captured at t=4 is recorded now (after the marks).
      r.sample(s(4), detected: true, seated: true, held: false, completed: s(6));
      r.sample(s(6), detected: false, seated: false, held: false, completed: s(6) + ms(30));
      final rows = r.rows.where((x) => x.kind == SeatLabRowKind.sample).toList();
      expect(rows[0].truth, SeatLabTruth.seated);
      expect(rows[0].caseId, 'P1');
      expect(rows[1].truth, SeatLabTruth.away);
      expect(rows[1].caseId, 'N1');
      expect(r.truthAt(s(4)), SeatLabTruth.seated);
      expect(r.truthAt(s(5)), SeatLabTruth.away, reason: 'a change at t applies from t');
      expect(r.caseAt(Duration.zero - s(1)), '', reason: 'nothing before the first change');
      final a = r.agreement();
      expect(a.truthSeated, 1);
      expect(a.truthSeatedAsSeated, 1);
      expect(a.truthAway, 1);
      expect(a.truthAwayAsSeated, 0);
    });

    test('per-case agreement: P1 100 % and P2 80 % stay separate; the overall is 90 %', () {
      final r = SeatLabRecorder();
      r.beginSegment(s(0));
      r.mark(s(0), SeatLabTruth.seated);
      r.setCase(s(0), 'P1');
      _samples(r, from: 1, count: 10, seated: true);
      r.setCase(s(100), 'P2');
      _samples(r, from: 101, count: 8, seated: true);
      _samples(r, from: 109, count: 2, seated: false);
      final byCase = r.agreementByCase();
      expect(byCase.keys.toList(), <String>['P1', 'P2']);
      expect(byCase['P1']!.seatedDetectionRate, 1.0);
      expect(byCase['P2']!.seatedDetectionRate, closeTo(0.8, 1e-9));
      expect(r.agreement().seatedDetectionRate, closeTo(0.9, 1e-9));
      expect(r.agreementForRun(1).truthSeated, 20);
    });

    test('per-run agreement and CSV scope (all / run / case)', () {
      final r = SeatLabRecorder();
      r.mark(s(0), SeatLabTruth.seated);
      r.setCase(s(0), 'P1');
      r.beginSegment(s(1));
      _samples(r, from: 2, count: 3, seated: true);
      r.endSegment(s(5), end: SeatLabSegmentEnd.normal);
      r.setCase(s(6), 'P2');
      r.beginSegment(s(7));
      _samples(r, from: 8, count: 2, seated: false);
      r.endSegment(s(10), end: SeatLabSegmentEnd.normal);

      expect(r.agreementForRun(1).truthSeatedAsSeated, 3);
      expect(r.agreementForRun(2).truthSeatedAsSeated, 0);
      expect(r.agreementForRun(2).truthSeated, 2);

      final all = r.toCsv().trimRight().split('\n');
      expect(all, hasLength(1 + 2 + 1 + 3 + 1 + 1 + 1 + 2 + 1)); // header, 2 marks, start, 3 samples, stop, case, start, 2 samples, stop
      final run2 = r.toCsv(scope: SeatLabCsvScope.run, segment: 2).trimRight().split('\n');
      expect(run2, hasLength(1 + 1 + 2 + 1));
      expect(run2.skip(1).every((l) => l.split(',')[2] == '2'), isTrue);
      final p1 = r.toCsv(scope: SeatLabCsvScope.caseId, caseId: 'P1').trimRight().split('\n');
      expect(p1.skip(1).every((l) => l.split(',')[11] == 'P1'), isTrue);
      expect(p1.skip(1).where((l) => l.split(',')[1] == 'sample'), hasLength(3));
      expect(r.rowsIn(scope: SeatLabCsvScope.caseId, caseId: 'P2').where((x) => x.kind == SeatLabRowKind.sample), hasLength(2));
    });
  });

  group('S04c battery per run', () {
    test('an uninterrupted 60-minute run with readings at both ends is valid; readings belong to the run', () {
      final r = SeatLabRecorder();
      r.battery(Duration.zero, 100); // before any run: logged, attributed to no run
      final seg = r.beginSegment(m(1), batteryStart: 90);
      r.battery(m(31), 86);
      r.endSegment(m(66), end: SeatLabSegmentEnd.normal, batteryEnd: 82);
      expect(seg.batteryStart, 90, reason: 'the pre-run reading does not count');
      expect(seg.batteryEnd, 82);
      expect(seg.batteryLatest, 82);
      final v = r.batteryVerdict(seg, m(70));
      expect(v.valid, isTrue);
      expect(v.reason, 'ok');
      expect(v.dropPct, 8);
      expect(v.duration, m(65));
      expect(r.rows.first.segment, isNull);
    });

    test('an interruption invalidates the run; short runs are never summed into a valid one', () {
      final r = SeatLabRecorder();
      // Run 1: 65 minutes but a camera loss in the middle.
      final s1 = r.beginSegment(m(0), batteryStart: 90);
      r.interrupt(m(20), 'cameraLost');
      r.endSegment(m(65), end: SeatLabSegmentEnd.normal, batteryEnd: 82);
      final v1 = r.batteryVerdict(s1, m(66));
      expect(v1.valid, isFalse);
      expect(v1.reason, 'interrupted');
      expect(v1.dropPct, 8, reason: 'the numbers are still reported, the verdict is not');
      expect(s1.interruptReason, 'cameraLost');

      // Runs 2 + 3: 30 minutes each, clean. Neither is a measurement.
      final s2 = r.beginSegment(m(70), batteryStart: 80);
      r.endSegment(m(100), end: SeatLabSegmentEnd.normal, batteryEnd: 76);
      final s3 = r.beginSegment(m(101), batteryStart: 76);
      r.endSegment(m(131), end: SeatLabSegmentEnd.normal, batteryEnd: 72);
      expect(r.batteryVerdict(s2, m(140)).reason, 'short');
      expect(r.batteryVerdict(s3, m(140)).reason, 'short');
      expect(r.batteryVerdict(s3, m(140)).valid, isFalse);

      // A run still open is not a verdict yet; a paused run is interrupted too.
      final s4 = r.beginSegment(m(150));
      expect(r.batteryVerdict(s4, m(151)).reason, 'open');
      r.interrupt(m(152), 'paused · background');
      r.endSegment(m(153), end: SeatLabSegmentEnd.abnormal, reason: 'background');
      expect(r.batteryVerdict(s4, m(154)).reason, 'interrupted');
      // No readings at all → no_reading even when long and clean.
      final s5 = r.beginSegment(m(160));
      r.endSegment(m(230), end: SeatLabSegmentEnd.normal);
      expect(r.batteryVerdict(s5, m(231)).reason, 'no_reading');
    });
  });

  group('S04d battery: start and end are separate measurements', () {
    test('a failed end measurement makes the run invalid; periodic readings never stand in for it', () {
      final r = SeatLabRecorder();
      final seg = r.beginSegment(m(0), batteryStart: 90);
      r.battery(m(30), 86);
      r.battery(m(60), 83);
      // End value read first (and failed), then the segment is closed at the end time.
      r.endSegment(m(65), end: SeatLabSegmentEnd.normal, batteryEnd: null);
      expect(seg.batteryStart, 90);
      expect(seg.batteryLatest, 83, reason: 'display value only');
      expect(seg.batteryEnd, isNull);
      final v = r.batteryVerdict(seg, m(66));
      expect(v.valid, isFalse);
      expect(v.reason, 'no_reading');
      expect(v.dropPct, isNull);
    });

    test('a clean 60-minute run with both measurements is valid; one reading never fills both ends', () {
      final r = SeatLabRecorder();
      final ok = r.beginSegment(m(0), batteryStart: 90);
      r.endSegment(m(65), end: SeatLabSegmentEnd.normal, batteryEnd: 82);
      expect(r.batteryVerdict(ok, m(66)).valid, isTrue);
      expect(r.batteryVerdict(ok, m(66)).dropPct, 8);

      final noStart = r.beginSegment(m(70));
      r.battery(m(70), 82); // a periodic reading at the very start is not the start measurement
      r.endSegment(m(135), end: SeatLabSegmentEnd.normal, batteryEnd: 74);
      expect(noStart.batteryStart, isNull);
      expect(r.batteryVerdict(noStart, m(136)).reason, 'no_reading');
    });

    test('an abnormal end or a camera release that outlived its bound invalidates the run', () {
      final r = SeatLabRecorder();
      final abnormal = r.beginSegment(m(0), batteryStart: 90);
      r.endSegment(m(65), end: SeatLabSegmentEnd.abnormal, reason: 'error', batteryEnd: 82);
      final va = r.batteryVerdict(abnormal, m(66));
      expect(va.valid, isFalse);
      expect(va.reason, 'abnormal');
      expect(va.dropPct, 8, reason: 'the numbers are still reported');

      final late = r.beginSegment(m(70), batteryStart: 82);
      r.endSegment(m(135), end: SeatLabSegmentEnd.normal, batteryEnd: 74, cameraReleaseTimedOut: true);
      expect(r.batteryVerdict(late, m(136)).reason, 'release_timeout');
      expect(late.isExcluded, isFalse, reason: 'the samples are fine; only the battery verdict is not');
    });

    test('CSV: the end measurement row carries the end time and comes before the stop row', () {
      final r = SeatLabRecorder();
      r.beginSegment(s(0), batteryStart: 90);
      r.endSegment(s(10), end: SeatLabSegmentEnd.normal, batteryEnd: 89);
      final lines = r.toCsv().trimRight().split('\n');
      expect(lines[1], '0,event,1,0,,,,,,none,,,start');
      expect(lines[2], '0,battery,1,0,,,,,,none,90,,');
      expect(lines[3], '10000,battery,1,0,,,,,,none,89,,');
      expect(lines[4], '10000,event,1,0,,,,,,none,,,stop · normal');
    });
  });

  test('segments: an abnormal end excludes its samples from the summary, not from the CSV', () {
    final r = SeatLabRecorder();
    r.mark(s(0), SeatLabTruth.seated);
    final s1 = r.beginSegment(s(1));
    expect(s1.index, 1);
    r.sample(s(2), detected: true, seated: true, held: false, completed: s(2) + ms(30));
    r.sample(s(3), detected: true, seated: true, held: false, completed: s(3) + ms(30));
    r.endSegment(s(4), end: SeatLabSegmentEnd.normal);
    final s2 = r.beginSegment(s(5));
    expect(s2.index, 2);
    r.sample(s(6), detected: false, seated: false, held: false, completed: s(6) + ms(30));
    r.sample(s(7), detected: false, seated: false, held: false, completed: s(7) + ms(30));
    r.endSegment(s(8), end: SeatLabSegmentEnd.abnormal, reason: 'background');
    expect(r.endSegmentIsNoOp(s(9)), isTrue);

    expect(r.segments, hasLength(2));
    expect(r.excludedSegments, 1);
    expect(r.lastSegment!.isExcluded, isTrue);
    expect(r.lastSegment!.reason, 'background');
    expect(r.processed, 2, reason: 'segment 2 left out');
    expect(r.excludedSamples, 2);
    expect(r.agreement().truthSeated, 2);
    expect(r.agreementForRun(2).truthSeated, 2, reason: 'per-run view still answers');

    final lines = r.toCsv().trimRight().split('\n');
    expect(lines.first, SeatLabRecorder.csvHeader);
    expect(lines, hasLength(10));
    expect(lines[1], '0,mark,,,,,,,,seated,,,seated');
    expect(lines[2], '1000,event,1,0,,,,,,seated,,,start');
    expect(lines[3], '2000,sample,1,0,1,1,0,2030,30,seated,,,');
    expect(lines[5], '4000,event,1,0,,,,,,seated,,,stop · normal');
    expect(lines[7], '6000,sample,2,1,0,0,0,6030,30,seated,,,');
    expect(lines[9], '8000,event,2,1,,,,,,seated,,,stop · abnormal · background');
  });

  test('beginSegment while one is open closes it as abnormal (restart); clear keeps the labels', () {
    final r = SeatLabRecorder();
    r.mark(s(0), SeatLabTruth.away);
    r.setCase(s(0), 'N3');
    r.beginSegment(s(0));
    r.beginSegment(s(5));
    expect(r.segments, hasLength(2));
    expect(r.segments.first.isExcluded, isTrue);
    expect(r.segments.first.reason, 'restart');
    expect(r.currentSegment!.index, 2);
    r.clear();
    expect(r.rows, isEmpty);
    expect(r.segments, isEmpty);
    expect(r.truth, SeatLabTruth.away);
    expect(r.caseId, 'N3');
    expect(r.truthAt(s(100)), SeatLabTruth.away);
  });

  test('csv: quoting', () {
    final r = SeatLabRecorder();
    r.setCase(s(0), 'P2');
    r.event(s(3), 'note, with "quotes"');
    r.battery(s(4), 77);
    final lines = r.toCsv().trimRight().split('\n');
    expect(lines[1], '0,mark,,,,,,,,none,,P2,case');
    expect(lines[2], '3000,event,,,,,,,,none,,P2,"note, with ""quotes"""');
    expect(lines[3], '4000,battery,,,,,,,,none,77,P2,');
    expect(r.toCsvBytes().length, r.toCsv().length);
  });
}

extension on SeatLabRecorder {
  /// `endSegment` without an open segment changes nothing.
  bool endSegmentIsNoOp(Duration t) {
    final before = rows.length;
    endSegment(t, end: SeatLabSegmentEnd.normal);
    return rows.length == before;
  }
}
