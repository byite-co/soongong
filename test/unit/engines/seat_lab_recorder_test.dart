import 'package:flutter_test/flutter_test.dart';
import 'package:soongong/core/dev/seat_lab/seat_lab_recorder.dart';

Duration s(int seconds) => Duration(seconds: seconds);

void main() {
  test('window statistics and agreement', () {
    final r = SeatLabRecorder(window: const Duration(seconds: 10));
    r.battery(s(0), 80);
    r.mark(s(0), SeatLabTruth.seated);
    for (var t = 1; t <= 5; t++) {
      r.sample(s(t), detected: true, seated: true, held: false, latency: const Duration(milliseconds: 20));
    }
    r.sample(s(6), detected: false, seated: true, held: true, latency: const Duration(milliseconds: 40));
    r.mark(s(7), SeatLabTruth.away);
    r.sample(s(8), detected: false, seated: false, held: false, latency: const Duration(milliseconds: 10));
    r.sample(s(9), detected: true, seated: true, held: false, latency: const Duration(milliseconds: 10));
    r.event(s(9), 'cameraLost');
    r.battery(s(10), 79);

    expect(r.processed, 8);
    expect(r.detectedCount, 6);
    expect(r.eventCount, 1);
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
  });

  test('no truth → agreement empty, rates null', () {
    final r = SeatLabRecorder();
    expect(r.detectionRate(Duration.zero), isNull);
    final a = r.agreement();
    expect(a.seatedDetectionRate, isNull);
    expect(a.awayFalseSeatedRate, isNull);
  });

  test('csv: header, one line per row, quoting', () {
    final r = SeatLabRecorder();
    r.setCase(s(0), 'P2');
    r.sample(s(1), detected: true, seated: true, held: false, latency: const Duration(milliseconds: 23));
    r.mark(s(2), SeatLabTruth.away);
    r.event(s(3), 'note, with "quotes"');
    r.battery(s(4), 77);
    final lines = r.toCsv().trimRight().split('\n');
    expect(lines.first, SeatLabRecorder.csvHeader);
    expect(lines, hasLength(6));
    expect(lines[1], '0,mark,,,,,none,,P2,case');
    expect(lines[2], '1000,sample,1,1,0,23,none,,P2,');
    expect(lines[3], '2000,mark,,,,,away,,P2,away');
    expect(lines[4], '3000,event,,,,,away,,P2,"note, with ""quotes"""');
    expect(lines[5], '4000,battery,,,,,away,77,P2,');
    expect(r.toCsvBytes().length, r.toCsv().length);
    r.clear();
    expect(r.rows, isEmpty);
    expect(r.batteryStart, isNull);
  });
}
