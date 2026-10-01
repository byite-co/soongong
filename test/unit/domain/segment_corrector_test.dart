import 'package:flutter_test/flutter_test.dart';
import 'package:soongong/core/domain/enums.dart';
import 'package:soongong/features/measure/domain/seated_time_calculator.dart';
import 'package:soongong/features/measure/domain/segment.dart';
import 'package:soongong/features/measure/domain/segment_corrector.dart';

final DateTime t0 = DateTime.utc(2026, 9, 30, 10);
DateTime at(int min) => t0.add(Duration(minutes: min));

void main() {
  const corrector = SegmentCorrector();
  final segments = <Segment>[
    Segment(id: 'a', kind: SegmentKind.seated, startAt: at(0), endAt: at(10)),
    Segment(id: 'b', kind: SegmentKind.away, startAt: at(10), endAt: at(13)),
    Segment(id: 'c', kind: SegmentKind.seated, startAt: at(13), endAt: at(30)),
  ];

  test('away → seated flags the segment corrected and restores 순공', () {
    final out = corrector.apply(segments, segmentId: 'b', toKind: SegmentKind.seated)!;
    expect(out.fromKind, SegmentKind.away);
    expect(out.toKind, SegmentKind.seated);
    expect(out.segmentId, 'b');
    expect(out.segments[1].corrected, isTrue);
    expect(out.segments[1].kind, SegmentKind.seated);
    expect(const SeatedTimeCalculator().seated(out.segments), const Duration(minutes: 30));
    // Original list untouched.
    expect(segments[1].kind, SegmentKind.away);
    expect(segments[1].corrected, isFalse);
  });

  test('unknown id or same kind → null', () {
    expect(corrector.apply(segments, segmentId: 'zz', toKind: SegmentKind.seated), isNull);
    expect(corrector.apply(segments, segmentId: 'a', toKind: SegmentKind.seated), isNull);
  });
}
