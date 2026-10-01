import 'package:flutter_test/flutter_test.dart';
import 'package:soongong/core/domain/entities/entities.dart';
import 'package:soongong/core/domain/enums.dart';
import 'package:soongong/features/measure/domain/seated_time_calculator.dart';
import 'package:soongong/features/measure/domain/segment.dart';

final DateTime t0 = DateTime.utc(2026, 9, 30, 10);

Segment seg(String id, SegmentKind k, int fromMin, int toMin) => Segment(
      id: id,
      kind: k,
      startAt: t0.add(Duration(minutes: fromMin)),
      endAt: t0.add(Duration(minutes: toMin)),
    );

SyncStamp stamp() => SyncStamp(
      userId: 'u',
      createdAt: t0,
      clientUpdatedAt: t0,
      deviceId: 'd',
    );

StudySession session(SessionKind kind, int seatedMinutes) => StudySession(
      id: kind.name,
      stamp: stamp(),
      kind: kind,
      mode: SessionMode.camera,
      startedAt: t0,
      status: SessionStatus.finished,
      seatedSeconds: seatedMinutes * 60,
      sensitivityLevel: 0,
    );

void main() {
  const calc = SeatedTimeCalculator();

  test('seated = seated + manual; away and paused are excluded', () {
    final segments = <Segment>[
      seg('a', SegmentKind.seated, 0, 10),
      seg('b', SegmentKind.away, 10, 12),
      seg('c', SegmentKind.seated, 12, 30),
      seg('d', SegmentKind.paused, 30, 35),
      seg('e', SegmentKind.manual, 35, 40),
    ];
    expect(calc.seated(segments), const Duration(minutes: 33));
    expect(calc.seatedSeconds(segments), 33 * 60);
    expect(calc.away(segments), const Duration(minutes: 2));
    expect(calc.paused(segments), const Duration(minutes: 5));
  });

  test('a corrected away→seated segment counts; clipEnd trims', () {
    final segments = <Segment>[
      seg('a', SegmentKind.seated, 0, 10),
      seg('b', SegmentKind.away, 10, 12).copyWith(
        kind: SegmentKind.seated,
        corrected: true,
      ),
      seg('c', SegmentKind.seated, 12, 30),
    ];
    expect(calc.seated(segments), const Duration(minutes: 30));
    expect(
      calc.seated(segments, clipEnd: t0.add(const Duration(minutes: 20))),
      const Duration(minutes: 20),
    );
    // Empty / negative segments contribute nothing.
    expect(calc.seated(<Segment>[seg('z', SegmentKind.seated, 5, 5)]), Duration.zero);
  });

  test('byKind / total use the cached seated seconds of sessions', () {
    final sessions = <StudySession>[
      session(SessionKind.study, 50),
      session(SessionKind.todo, 20),
      session(SessionKind.self, 15),
    ];
    final byKind = calc.byKind(sessions);
    expect(byKind[SessionKind.study], const Duration(minutes: 50));
    expect(byKind[SessionKind.todo], const Duration(minutes: 20));
    expect(byKind[SessionKind.self], const Duration(minutes: 15));
    expect(calc.total(sessions), const Duration(minutes: 85));
    expect(calc.byKind(const <StudySession>[])[SessionKind.study], Duration.zero);
  });
}
