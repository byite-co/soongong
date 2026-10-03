import 'package:flutter_test/flutter_test.dart';
import 'package:soongong/core/dev/seat_lab/seat_lab_recorder.dart';

Duration s(int seconds) => Duration(seconds: seconds);
Duration ms(int v) => Duration(milliseconds: v);

void main() {
  test('window statistics and agreement', () {
    final r = SeatLabRecorder(window: const Duration(seconds: 10));
    r.beginSegment(s(0));
    r.battery(s(0), 80);
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
    expect(r.batteryStart, 80);
    expect(r.batteryLast, 79);
    expect(r.batteryDelta, 1);
    expect(r.detectionRate(s(10)), closeTo(6 / 8, 1e-9));
    expect(r.seatedRate(s(10)), closeTo(7 / 8, 1e-9));
    expect(r.meanLatency(s(10)), const Duration(milliseconds: 20));
    // window of 10 s ending at 20 s → only t ≥ 10 → nothing
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
  });

  test('segments: an abnormal end excludes its samples from the summary, not from the CSV', () {
    final r = SeatLabRecorder();
    r.mark(s(0), SeatLabTruth.seated);
    // Segment 1: normal.
    final s1 = r.beginSegment(s(1));
    expect(s1.index, 1);
    r.sample(s(2), detected: true, seated: true, held: false, completed: s(2) + ms(30));
    r.sample(s(3), detected: true, seated: true, held: false, completed: s(3) + ms(30));
    r.endSegment(s(4), end: SeatLabSegmentEnd.normal);
    // Segment 2: abnormal (engine stopped itself).
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
    expect(r.lastSegment!.durationAt(s(99)), s(3));
    expect(r.processed, 2, reason: 'segment 2 left out');
    expect(r.excludedSamples, 2);
    expect(r.detectedCount, 2);
    expect(r.agreement().truthSeated, 2);
    expect(r.agreement().seatedDetectionRate, 1.0);
    expect(r.detectionRate(s(10)), 1.0);

    final lines = r.toCsv().trimRight().split('\n');
    expect(lines.first, SeatLabRecorder.csvHeader);
    expect(lines, hasLength(10));
    expect(lines[1], '0,mark,,,,,,,,seated,,,seated');
    expect(lines[2], '1000,event,1,0,,,,,,seated,,,start');
    expect(lines[3], '2000,sample,1,0,1,1,0,2030,30,seated,,,');
    expect(lines[5], '4000,event,1,0,,,,,,seated,,,stop · normal');
    expect(lines[6], '5000,event,2,1,,,,,,seated,,,start');
    expect(lines[7], '6000,sample,2,1,0,0,0,6030,30,seated,,,');
    expect(lines[9], '8000,event,2,1,,,,,,seated,,,stop · abnormal · background');
  });

  test('beginSegment while one is open closes it as abnormal (restart)', () {
    final r = SeatLabRecorder();
    r.beginSegment(s(0));
    r.beginSegment(s(5));
    expect(r.segments, hasLength(2));
    expect(r.segments.first.isExcluded, isTrue);
    expect(r.segments.first.reason, 'restart');
    expect(r.currentSegment!.index, 2);
  });

  test('csv: quoting and clear', () {
    final r = SeatLabRecorder();
    r.setCase(s(0), 'P2');
    r.event(s(3), 'note, with "quotes"');
    r.battery(s(4), 77);
    final lines = r.toCsv().trimRight().split('\n');
    expect(lines[1], '0,mark,,,,,,,,none,,P2,case');
    expect(lines[2], '3000,event,,,,,,,,none,,P2,"note, with ""quotes"""');
    expect(lines[3], '4000,battery,,,,,,,,none,77,P2,');
    expect(r.toCsvBytes().length, r.toCsv().length);
    r.clear();
    expect(r.rows, isEmpty);
    expect(r.segments, isEmpty);
    expect(r.batteryStart, isNull);
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
