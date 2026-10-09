import 'package:flutter_test/flutter_test.dart';
import 'package:soongong/core/domain/entities/entities.dart';
import 'package:soongong/core/domain/enums.dart';
import 'package:soongong/core/domain/local_date.dart';
import 'package:soongong/features/home/domain/home_summary.dart';
import 'package:soongong/features/home/domain/streak_calculator.dart';

void main() {
  final start = DateTime(2026, 10, 5, 23, 30);
  final stamp = SyncStamp(
    userId: 'u1',
    createdAt: start.toUtc(),
    clientUpdatedAt: start.toUtc(),
    deviceId: 'test',
  );
  final session = StudySession(
    id: 's',
    stamp: stamp,
    kind: SessionKind.study,
    mode: SessionMode.camera,
    startedAt: start.toUtc(),
    endedAt: start.add(const Duration(hours: 2)).toUtc(),
    status: SessionStatus.finished,
    seatedSeconds: 5400,
    sensitivityLevel: 0,
  );
  SessionSegment segment(String id, SegmentKind kind, int from, int to) =>
      SessionSegment(
        id: id,
        stamp: stamp,
        sessionId: 's',
        kind: kind,
        startAt: start.add(Duration(minutes: from)).toUtc(),
        endAt: start.add(Duration(minutes: to)).toUtc(),
      );
  HomeSummary summary(StudySession row, List<SessionSegment> segments) =>
      HomeSummary.build(
        today: const LocalDate(2026, 10, 6),
        sessions: [row],
        segments: segments,
        items: [],
        recurrences: [],
        subjects: {},
        streak: StreakResult.zero,
        fallbackSubjectName: '자습',
      );

  test(
    'midnight clips seated/manual segments; away and pause make ring gaps',
    () {
      final result = summary(session, [
        segment('a', SegmentKind.seated, 0, 45),
        segment('b', SegmentKind.away, 45, 60),
        segment('c', SegmentKind.paused, 60, 75),
        segment('d', SegmentKind.manual, 75, 120),
      ]);
      expect(result.seatedToday, const Duration(minutes: 60));
      expect(result.seatedYesterday, const Duration(minutes: 30));
      expect(result.subjectTotals.single.seated, const Duration(minutes: 60));
      expect(result.arcs.map((a) => (a.startHour, a.endHour)), [
        (0.0, .25),
        (.75, 1.5),
      ]);
    },
  );

  test(
    'unsaved interrupted session contributes neither time nor a saved day',
    () {
      final row = session.copyWith(
        status: SessionStatus.interrupted,
        endedAt: null,
      );
      final result = summary(row, [segment('a', SegmentKind.manual, 0, 120)]);
      expect(result.seatedToday, Duration.zero);
      expect(result.arcs, isEmpty);
      expect(HomeSummary.savedDays([row]), isEmpty);
    },
  );
}
