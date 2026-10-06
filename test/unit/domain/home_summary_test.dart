// HomeSummary · RecoveryCandidate (S05, pure Dart): facts the home shows.

import 'package:flutter_test/flutter_test.dart';
import 'package:soongong/core/domain/entities/entities.dart';
import 'package:soongong/core/domain/enums.dart';
import 'package:soongong/core/domain/local_date.dart';
import 'package:soongong/features/home/domain/home_summary.dart';
import 'package:soongong/features/home/domain/recovery_candidate.dart';
import 'package:soongong/features/home/domain/streak_calculator.dart';
import 'package:soongong/features/measure/domain/segment.dart';
import 'package:soongong/features/measure/domain/session_snapshot.dart';

final DateTime _t0 = DateTime(2026, 10, 3, 9); // local, Saturday
final LocalDate _today = LocalDate.of(_t0);

SyncStamp _stamp([DateTime? at]) => SyncStamp(
      userId: 'u1',
      createdAt: (at ?? _t0).toUtc(),
      clientUpdatedAt: (at ?? _t0).toUtc(),
      deviceId: 'dev',
    );

StudySession _session({
  required String id,
  required DateTime start,
  DateTime? end,
  int seated = 0,
  SessionKind kind = SessionKind.study,
  SessionStatus status = SessionStatus.finished,
  String? subjectId,
}) =>
    StudySession(
      id: id,
      stamp: _stamp(start),
      kind: kind,
      mode: SessionMode.camera,
      startedAt: start.toUtc(),
      endedAt: end?.toUtc(),
      status: status,
      seatedSeconds: seated,
      sensitivityLevel: 0,
      subjectId: subjectId,
    );

PlannerItem _item({
  required String id,
  required String title,
  PlannerKind kind = PlannerKind.todo,
  bool done = false,
  int sortOrder = 0,
  LocalTime? start,
  LocalTime? end,
}) =>
    PlannerItem(
      id: id,
      stamp: _stamp(),
      kind: kind,
      title: title,
      date: _today,
      isDone: done,
      sortOrder: sortOrder,
      startTime: start,
      endTime: end,
    );

void main() {
  group('HomeSummary.build', () {
    test('today vs yesterday, arcs, todos, subject totals, events', () {
      final sessions = <StudySession>[
        _session(id: 'a', start: _t0.subtract(const Duration(hours: 2)), end: _t0.subtract(const Duration(hours: 1)), seated: 3300, subjectId: 's-math'),
        _session(id: 'b', start: _t0, end: _t0.add(const Duration(minutes: 30)), seated: 1500, kind: SessionKind.self),
        _session(id: 'y', start: _t0.subtract(const Duration(days: 1)), end: _t0.subtract(const Duration(days: 1, hours: -1)), seated: 3600),
        _session(id: 'x', start: _t0, end: _t0, seated: 999, status: SessionStatus.discarded),
      ];
      final items = <PlannerItem>[
        _item(id: 'i1', title: '수학 숙제', sortOrder: 1),
        _item(id: 'i2', title: '영어 단어', done: true, sortOrder: 0),
        _item(id: 'i3', title: '학원', kind: PlannerKind.event, start: const LocalTime(19, 0), end: const LocalTime(21, 0)),
      ];
      final recs = <Recurrence>[
        Recurrence(
          id: 'r1',
          stamp: _stamp(_t0.subtract(const Duration(days: 30))),
          title: '자율학습',
          weekdayMask: 1 << 5, // Saturday
          startTime: const LocalTime(14, 0),
          endTime: const LocalTime(16, 0),
        ),
      ];
      final s = HomeSummary.build(
        today: _today,
        sessions: sessions,
        items: items,
        recurrences: recs,
        subjects: <String, Subject>{
          's-math': Subject(id: 's-math', stamp: _stamp(), name: '수학', colorIndex: 1, sortOrder: 0),
        },
        streak: const StreakResult(current: 3, longest: 5, todayCounted: true),
        fallbackSubjectName: '기타',
      );

      expect(s.seatedToday, const Duration(seconds: 4800));
      expect(s.seatedYesterday, const Duration(hours: 1));
      expect(s.diffFromYesterday, const Duration(minutes: 20));
      expect(s.hasSeatedToday, isTrue);
      expect(s.isEmpty, isFalse);

      expect(s.todos.map((t) => t.id), <String>['i1', 'i2'], reason: 'open first, events excluded');
      expect(s.totalTodos, 2);
      expect(s.doneTodos, 1);
      expect(s.remainingTodos, 1);

      final kinds = s.arcs.map((a) => a.kind).toList();
      expect(kinds, containsAll(<HomeArcKind>[HomeArcKind.study, HomeArcKind.self, HomeArcKind.event, HomeArcKind.recurrence]));
      final self = s.arcs.firstWhere((a) => a.kind == HomeArcKind.self);
      expect(self.startHour, 9.0);
      expect(self.endHour, 9.5);
      final rec = s.arcs.firstWhere((a) => a.kind == HomeArcKind.recurrence);
      expect((rec.startHour, rec.endHour), (14.0, 16.0));

      expect(s.subjectTotals.map((t) => '${t.name}:${t.seated.inSeconds}'), <String>['수학:3300', '기타:1500']);
      expect(s.events.map((e) => e.label), <String>['자율학습 14:00–16:00', '학원 19:00–21:00']);
    });

    test('empty state when nothing happened today', () {
      final s = HomeSummary.build(
        today: _today,
        sessions: const <StudySession>[],
        items: const <PlannerItem>[],
        recurrences: const <Recurrence>[],
        subjects: const <String, Subject>{},
        streak: StreakResult.zero,
        fallbackSubjectName: '기타',
      );
      expect(s.isEmpty, isTrue);
      expect(s.seatedToday, Duration.zero);
      expect(s.remainingTodos, 0);
    });

    test('a session ending after midnight is drawn to 24h; one still open is skipped', () {
      final s = HomeSummary.build(
        today: _today,
        sessions: <StudySession>[
          _session(id: 'late', start: DateTime(2026, 10, 3, 23), end: DateTime(2026, 10, 4, 1), seated: 7200),
          _session(id: 'open', start: _t0, seated: 0, status: SessionStatus.active),
        ],
        items: const <PlannerItem>[],
        recurrences: const <Recurrence>[],
        subjects: const <String, Subject>{},
        streak: StreakResult.zero,
        fallbackSubjectName: '기타',
      );
      expect(s.arcs.length, 1);
      expect(s.arcs.single.endHour, 24.0);
    });

    test('savedDays counts finished and interrupted sessions only (D4)', () {
      final days = HomeSummary.savedDays(<StudySession>[
        _session(id: '1', start: _t0, end: _t0.add(const Duration(minutes: 1)), seated: 60),
        _session(id: '2', start: _t0.subtract(const Duration(days: 1)), end: _t0.subtract(const Duration(days: 1)).add(const Duration(seconds: 10)), seated: 10, status: SessionStatus.interrupted),
        _session(id: '3', start: _t0.subtract(const Duration(days: 2)), seated: 10, status: SessionStatus.discarded),
      ]);
      expect(days, <LocalDate>{_today, _today.addDays(-1)});
    });
  });

  group('RecoveryCandidate.detect', () {
    test('snapshot wins: seated open segment closed at saved_at (D23)', () {
      final start = _t0.subtract(const Duration(minutes: 70)).toUtc();
      final snap = SessionSnapshot(
        sessionId: 'sess',
        mode: SessionMode.camera,
        kind: SessionKind.study,
        startedAt: start,
        segments: const <Segment>[],
        openKind: SegmentKind.seated,
        openStart: start,
        savedAt: start.add(const Duration(minutes: 60)),
        sensitivity: 0,
      );
      var n = 0;
      final c = RecoveryCandidate.detect(snapshot: snap, sessions: const <StudySession>[], newId: () => 'id-${++n}');
      expect(c, isNotNull);
      expect(c!.sessionId, 'sess');
      expect(c.recordedSeconds, 3600);
      expect(c.endedAt, snap.savedAt);
      expect(c.snapshot, same(snap));
    });

    test('without a snapshot an active row is the candidate; finished rows are not', () {
      final c = RecoveryCandidate.detect(
        snapshot: null,
        sessions: <StudySession>[
          _session(id: 'done', start: _t0, end: _t0, seated: 10),
          _session(id: 'live', start: _t0.subtract(const Duration(minutes: 5)), seated: 120, status: SessionStatus.active),
        ],
        newId: () => 'x',
      );
      expect(c?.sessionId, 'live');
      expect(c?.recordedSeconds, 0);
      expect(
        RecoveryCandidate.detect(snapshot: null, sessions: <StudySession>[_session(id: 'done', start: _t0, end: _t0)], newId: () => 'x'),
        isNull,
      );
    });

    test('a row-only candidate must come from this device (synced rows of another phone are not ours)', () {
      final live = _session(id: 'live', start: _t0.subtract(const Duration(minutes: 5)), status: SessionStatus.active);
      expect(
        RecoveryCandidate.detect(snapshot: null, sessions: <StudySession>[live], newId: () => 'x', deviceId: 'other-device')
            ?.sessionId,
        isNull,
      );
      expect(
        RecoveryCandidate.detect(snapshot: null, sessions: <StudySession>[live], newId: () => 'x', deviceId: live.stamp.deviceId)
            ?.sessionId,
        'live',
      );
    });
  });
}
