// S08 boundary tests: 순공 is the saved sessions' seated/manual segments
// clipped to local days and to the query range, in seconds. Midnight, week
// and month boundaries, sessions started before the range, excluded
// sessions, hour split, consecutive runs, and the equality of the home /
// planner / timetable / statistics totals on the same data.

import 'package:flutter_test/flutter_test.dart';
import 'package:soongong/core/domain/entities/entities.dart';
import 'package:soongong/core/domain/enums.dart';
import 'package:soongong/core/domain/local_date.dart';
import 'package:soongong/features/home/domain/home_summary.dart';
import 'package:soongong/features/home/domain/streak_calculator.dart';
import 'package:soongong/features/measure/domain/segment.dart';
import 'package:soongong/features/planner/domain/month_aggregate.dart';
import 'package:soongong/features/planner/domain/month_grid.dart';
import 'package:soongong/features/stats/domain/seated_aggregate.dart';
import 'package:soongong/features/stats/domain/seated_slices.dart';
import 'package:soongong/features/timetable/domain/week_timetable.dart';

import '../data/db_test_helpers.dart';

SyncStamp _stamp(DateTime at) => SyncStamp(userId: 'u', createdAt: at, clientUpdatedAt: at, deviceId: 'd');

StudySession _session(
  String id,
  DateTime startLocal,
  DateTime? endLocal, {
  SessionStatus status = SessionStatus.finished,
  SessionKind kind = SessionKind.study,
  String? subject,
}) =>
    StudySession(
      id: id,
      stamp: _stamp(startLocal.toUtc()),
      subjectId: subject,
      kind: kind,
      mode: SessionMode.camera,
      startedAt: startLocal.toUtc(),
      endedAt: endLocal?.toUtc(),
      status: status,
      seatedSeconds: endLocal == null ? 0 : endLocal.difference(startLocal).inSeconds,
      sensitivityLevel: 0,
    );

SessionSegment _seg(String sessionId, DateTime startLocal, DateTime endLocal, {SegmentKind kind = SegmentKind.seated}) =>
    SessionSegment(
      id: '$sessionId-${startLocal.millisecondsSinceEpoch}',
      stamp: _stamp(startLocal.toUtc()),
      sessionId: sessionId,
      kind: kind,
      startAt: startLocal.toUtc(),
      endAt: endLocal.toUtc(),
    );

/// Saved session whose whole span is one seated segment.
(StudySession, SessionSegment) _saved(String id, DateTime start, DateTime end, {SessionKind kind = SessionKind.study, String? subject}) =>
    (_session(id, start, end, kind: kind, subject: subject), _seg(id, start, end));

void main() {
  // 2026-10-03 is a Saturday; Monday week start → week 2026-09-28 … 10-04.
  const monday = LocalDate(2026, 9, 28);
  const sunday = LocalDate(2026, 10, 4);

  group('boundaries', () {
    test('midnight: a segment 23:30–00:30 is 1800 s on each day, never double counted', () {
      final (s, seg) = _saved('a', DateTime(2026, 9, 30, 23, 30), DateTime(2026, 10, 1, 0, 30));
      final agg = SeatedAggregate.build(from: monday, to: sunday, segments: [seg], sessions: [s]);
      expect(agg.seatedOn(const LocalDate(2026, 9, 30)), 1800);
      expect(agg.seatedOn(const LocalDate(2026, 10, 1)), 1800);
      expect(agg.totalSeconds, 3600);
      expect(agg.recordedDays, 2);
      expect(agg.sessionCount, 1, reason: 'one session, counted once');
    });

    test('week boundary: Sunday 23:00 → Monday 01:00 splits 3600/3600 between the two weeks', () {
      final (s, seg) = _saved('a', DateTime(2026, 10, 4, 23), DateTime(2026, 10, 5, 1));
      final thisWeek = SeatedAggregate.build(from: monday, to: sunday, segments: [seg], sessions: [s]);
      final nextWeek = SeatedAggregate.build(from: sunday.addDays(1), to: sunday.addDays(7), segments: [seg], sessions: [s]);
      expect(thisWeek.totalSeconds, 3600);
      expect(thisWeek.daily.last, 3600);
      expect(nextWeek.totalSeconds, 3600);
      expect(nextWeek.daily.first, 3600);
      expect(thisWeek.totalSeconds + nextWeek.totalSeconds, seg.duration.inSeconds);
    });

    test('month boundary: Sep 30 23:00 → Oct 1 01:00 gives September and October 3600 s each', () {
      final (s, seg) = _saved('a', DateTime(2026, 9, 30, 23), DateTime(2026, 10, 1, 1));
      final sep = SeatedAggregate.build(from: const LocalDate(2026, 9, 1), to: const LocalDate(2026, 9, 30), segments: [seg], sessions: [s]);
      final oct = SeatedAggregate.build(from: const LocalDate(2026, 10, 1), to: const LocalDate(2026, 10, 31), segments: [seg], sessions: [s]);
      expect(sep.totalSeconds, 3600);
      expect(sep.seatedOn(const LocalDate(2026, 9, 30)), 3600);
      expect(oct.totalSeconds, 3600);
      expect(oct.seatedOn(const LocalDate(2026, 10, 1)), 3600);
    });

    test('session started before the range: only the inside parts count, the outside part never does', () {
      // Started Saturday 9/26 (previous week), paused over the weekend, seated again on Tuesday 9/29.
      final s = _session('a', DateTime(2026, 9, 26, 20), DateTime(2026, 9, 29, 11));
      final outside = _seg('a', DateTime(2026, 9, 26, 20), DateTime(2026, 9, 26, 21));
      final inside = _seg('a', DateTime(2026, 9, 29, 10), DateTime(2026, 9, 29, 11));
      final paused = _seg('a', DateTime(2026, 9, 26, 21), DateTime(2026, 9, 29, 10), kind: SegmentKind.paused);
      final agg = SeatedAggregate.build(from: monday, to: sunday, segments: [outside, paused, inside], sessions: [s]);
      expect(agg.totalSeconds, 3600);
      expect(agg.seatedOn(const LocalDate(2026, 9, 29)), 3600);
      expect(agg.sessionCount, 1);
      expect(agg.recordedDays, 1);
    });

    test('a segment overlapping the range start is clipped to the range, not dropped', () {
      final (s, seg) = _saved('a', DateTime(2026, 9, 27, 23, 0), DateTime(2026, 9, 28, 0, 45));
      final agg = SeatedAggregate.build(from: monday, to: sunday, segments: [seg], sessions: [s]);
      expect(agg.totalSeconds, 45 * 60);
      expect(agg.daily.first, 45 * 60);
    });

    test('excluded: active, paused, discarded, no end, away/paused segments', () {
      final active = _session('active', DateTime(2026, 9, 29, 9), null, status: SessionStatus.active);
      final paused = _session('paused', DateTime(2026, 9, 29, 9), null, status: SessionStatus.paused);
      final discarded = _session('discarded', DateTime(2026, 9, 29, 9), DateTime(2026, 9, 29, 10), status: SessionStatus.discarded);
      final noEnd = _session('noend', DateTime(2026, 9, 29, 9), null, status: SessionStatus.finished);
      final (ok, okSeg) = _saved('ok', DateTime(2026, 9, 29, 12), DateTime(2026, 9, 29, 13));
      final interrupted = _session('int', DateTime(2026, 9, 30, 9), DateTime(2026, 9, 30, 9, 30), status: SessionStatus.interrupted);
      final segs = <SessionSegment>[
        _seg('active', DateTime(2026, 9, 29, 9), DateTime(2026, 9, 29, 10)),
        _seg('paused', DateTime(2026, 9, 29, 9), DateTime(2026, 9, 29, 10)),
        _seg('discarded', DateTime(2026, 9, 29, 9), DateTime(2026, 9, 29, 10)),
        _seg('noend', DateTime(2026, 9, 29, 9), DateTime(2026, 9, 29, 10)),
        _seg('unknown', DateTime(2026, 9, 29, 9), DateTime(2026, 9, 29, 10)),
        okSeg,
        _seg('ok', DateTime(2026, 9, 29, 13), DateTime(2026, 9, 29, 14), kind: SegmentKind.away),
        _seg('ok', DateTime(2026, 9, 29, 14), DateTime(2026, 9, 29, 15), kind: SegmentKind.paused),
        _seg('int', DateTime(2026, 9, 30, 9), DateTime(2026, 9, 30, 9, 30), kind: SegmentKind.manual),
      ];
      final agg = SeatedAggregate.build(
        from: monday,
        to: sunday,
        segments: segs,
        sessions: [active, paused, discarded, noEnd, ok, interrupted],
      );
      expect(agg.totalSeconds, 3600 + 1800, reason: 'finished seated + interrupted manual only');
      expect(agg.sessionCount, 2);
    });

    test('pending-delete sessions drop out of the live reads and the aggregate, undo brings them back', () async {
      final h = TestHarness();
      addTearDown(h.close);
      final day = LocalDate.of(kT0.toLocal());
      Future<void> save(String id, int fromMin, int toMin) => h.sessions.saveFinished(
            id: id,
            kind: SessionKind.study,
            mode: SessionMode.camera,
            startedAt: kT0.add(Duration(minutes: fromMin)),
            endedAt: kT0.add(Duration(minutes: toMin)),
            status: SessionStatus.finished,
            segments: <Segment>[SegmentFixture('$id-s', fromMin, toMin).toSegment()],
            sensitivityLevel: 0,
          );
      await save('keep', 0, 60);
      await save('gone', 120, 150);
      Future<int> total() async => SeatedAggregate.build(
            from: day,
            to: day,
            segments: await h.sessions.getSegmentsOverlapping(day, day),
            sessions: await h.sessions.getAll(),
          ).totalSeconds;
      expect(await total(), 90 * 60);
      await h.sessions.softDelete('gone');
      expect(await total(), 60 * 60, reason: 'pending delete is not live');
      await h.sessions.undoDelete('gone');
      expect(await total(), 90 * 60);
      await h.sessions.softDelete('gone');
      h.clock.advance(const Duration(seconds: 6));
      await h.sessions.commitDelete('gone');
      expect(await total(), 60 * 60);
    });
  });

  group('equality across screens', () {
    test('home today · planner daily · timetable week · stats week agree on the same data', () {
      const today = LocalDate(2026, 10, 3);
      final fixtures = <(StudySession, SessionSegment)>[
        _saved('a', DateTime(2026, 10, 2, 23, 20), DateTime(2026, 10, 3, 0, 40), subject: 'math'),
        _saved('b', DateTime(2026, 10, 3, 9), DateTime(2026, 10, 3, 10, 15), kind: SessionKind.self),
        _saved('c', DateTime(2026, 9, 27, 23), DateTime(2026, 9, 28, 1), subject: 'eng'),
        _saved('d', DateTime(2026, 10, 4, 23, 30), DateTime(2026, 10, 5, 0, 10)),
      ];
      final sessions = [for (final f in fixtures) f.$1];
      final segments = [for (final f in fixtures) f.$2];

      final home = HomeSummary.build(
        today: today,
        sessions: sessions,
        segments: segments,
        items: const [],
        recurrences: const [],
        subjects: const {},
        streak: const StreakResult(current: 0, longest: 0, todayCounted: false),
        fallbackSubjectName: '기타',
      );
      final statsDay = SeatedAggregate.build(from: today, to: today, segments: segments, sessions: sessions);
      expect(statsDay.totalSeconds, home.seatedToday.inSeconds);
      expect(statsDay.totalSeconds, 40 * 60 + 75 * 60);

      final week = SeatedAggregate.build(from: monday, to: sunday, segments: segments, sessions: sessions);
      final planner = MonthAggregate.dailySeated(from: monday, to: sunday, segments: segments, sessions: sessions);
      expect(week.daily, planner);
      final timetable = WeekTimetable.build(weekStart: monday, segments: segments, sessions: sessions, recurrences: const []);
      expect(timetable.totalSeconds, week.totalSeconds);
      for (final d in timetable.days) {
        expect(timetable.seatedOn(d), week.seatedOn(d), reason: d.key);
      }
      expect(week.totalSeconds, 60 * 60 + 80 * 60 + 75 * 60 + 30 * 60, reason: 'a = 40 min on 10/2 + 40 min on 10/3');

      final grid = MonthGrid.of(2026, 10, weekStart: 1);
      final month = MonthAggregate.build(grid: grid, items: const [], recurrences: const [], segments: segments, sessions: sessions);
      final october = SeatedAggregate.build(from: const LocalDate(2026, 10, 1), to: const LocalDate(2026, 10, 31), segments: segments, sessions: sessions);
      for (var i = 0; i < 31; i++) {
        final d = const LocalDate(2026, 10, 1).addDays(i);
        expect(month.days[d]?.seatedSeconds ?? 0, october.seatedOn(d), reason: d.key);
      }
      expect(october.totalSeconds, 80 * 60 + 75 * 60 + 30 * 60 + 10 * 60);
    });

    test('weekly total = sum of the seven daily aggregates (no per-session rounding)', () {
      final fixtures = <(StudySession, SessionSegment)>[
        _saved('a', DateTime(2026, 9, 28, 9, 0, 10), DateTime(2026, 9, 28, 9, 0, 55)),
        _saved('b', DateTime(2026, 9, 29, 23, 59, 30), DateTime(2026, 9, 30, 0, 0, 20)),
        _saved('c', DateTime(2026, 10, 3, 10, 0, 1), DateTime(2026, 10, 3, 10, 1, 0)),
      ];
      final sessions = [for (final f in fixtures) f.$1];
      final segments = [for (final f in fixtures) f.$2];
      final week = SeatedAggregate.build(from: monday, to: sunday, segments: segments, sessions: sessions);
      var sum = 0;
      for (var i = 0; i < 7; i++) {
        final d = monday.addDays(i);
        sum += SeatedAggregate.build(from: d, to: d, segments: segments, sessions: sessions).totalSeconds;
      }
      expect(week.totalSeconds, sum);
      expect(week.totalSeconds, 45 + 50 + 59);
    });
  });

  group('derived facts', () {
    test('hour histogram splits at local hour boundaries and at midnight', () {
      final (a, segA) = _saved('a', DateTime(2026, 9, 29, 9, 50), DateTime(2026, 9, 29, 10, 10));
      final (b, segB) = _saved('b', DateTime(2026, 9, 29, 23, 30), DateTime(2026, 9, 30, 0, 15));
      final agg = SeatedAggregate.build(from: monday, to: sunday, segments: [segA, segB], sessions: [a, b]);
      expect(agg.hourHistogram[9], 600);
      expect(agg.hourHistogram[10], 600);
      expect(agg.hourHistogram[23], 1800);
      expect(agg.hourHistogram[0], 900);
      expect(agg.hourHistogram.reduce((x, y) => x + y), agg.totalSeconds);
      expect(agg.hourBands, [0, 1200, 0, 0, 2700]);
    });

    test('focus runs: adjacent segments merge, away splits, runs clip to the range', () {
      final s = _session('a', DateTime(2026, 9, 29, 9), DateTime(2026, 9, 29, 12));
      final segs = <SessionSegment>[
        _seg('a', DateTime(2026, 9, 29, 9), DateTime(2026, 9, 29, 9, 20)),
        _seg('a', DateTime(2026, 9, 29, 9, 20), DateTime(2026, 9, 29, 9, 50), kind: SegmentKind.manual), // merged → 50 min
        _seg('a', DateTime(2026, 9, 29, 9, 50), DateTime(2026, 9, 29, 10), kind: SegmentKind.away),
        _seg('a', DateTime(2026, 9, 29, 10), DateTime(2026, 9, 29, 10, 10)), // 10 min
        _seg('a', DateTime(2026, 9, 29, 10, 10), DateTime(2026, 9, 29, 10, 30), kind: SegmentKind.paused),
        _seg('a', DateTime(2026, 9, 29, 10, 30), DateTime(2026, 9, 29, 12)), // 90 min
      ];
      final (b, segB) = _saved('b', DateTime(2026, 10, 4, 23, 40), DateTime(2026, 10, 5, 0, 20)); // 40 min, 20 inside
      final agg = SeatedAggregate.build(from: monday, to: sunday, segments: [...segs, segB], sessions: [s, b]);
      expect(agg.focus.under15, 1);
      expect(agg.focus.from15To30, 1, reason: 'the midnight run clipped to 20 min inside the week');
      expect(agg.focus.from30To60, 1);
      expect(agg.focus.over60, 1);
      expect(agg.focus.runCount, 4);
      expect(agg.focus.longestSeconds, 90 * 60);
      final nextWeek = SeatedAggregate.build(from: sunday.addDays(1), to: sunday.addDays(7), segments: [segB], sessions: [b]);
      expect(nextWeek.focus.from15To30, 1, reason: '20 min of the same run inside the next week');
    });

    test('subject split by kind, average session length, recorded days, 일평균, secondsThrough', () {
      final fixtures = <(StudySession, SessionSegment)>[
        _saved('a', DateTime(2026, 9, 28, 9), DateTime(2026, 9, 28, 10), subject: 'math'),
        _saved('b', DateTime(2026, 9, 28, 20), DateTime(2026, 9, 28, 20, 30), subject: 'math', kind: SessionKind.self),
        _saved('c', DateTime(2026, 9, 30, 9), DateTime(2026, 9, 30, 9, 45), subject: 'eng', kind: SessionKind.todo),
        _saved('d', DateTime(2026, 10, 2, 9), DateTime(2026, 10, 2, 9, 15)),
      ];
      final sessions = [for (final f in fixtures) f.$1];
      final segments = [for (final f in fixtures) f.$2];
      final agg = SeatedAggregate.build(from: monday, to: sunday, segments: segments, sessions: sessions);
      expect(agg.bySubject.map((s) => s.subjectId), ['math', 'eng', null]);
      expect(agg.bySubject.first.planned, 3600);
      expect(agg.bySubject.first.self, 1800);
      expect(agg.bySubject[1].planned, 45 * 60);
      expect(agg.bySubject[1].self, 0);
      expect(agg.totalSeconds, 150 * 60);
      expect(agg.dailyBySubject[0], {'math': 90 * 60});
      expect(agg.dailyBySubject[2], {'eng': 45 * 60});
      expect(agg.dailyBySubject[4], {null: 15 * 60});
      expect(agg.sessionCount, 4);
      expect(agg.averageSessionSeconds, 150 * 60 ~/ 4);
      expect(agg.recordedDays, 3);
      expect(agg.averagePerRecordedDay, 50 * 60);
      expect(agg.secondsThrough(const LocalDate(2026, 9, 30)), 135 * 60);
      expect(agg.secondsThrough(const LocalDate(2026, 10, 31)), 150 * 60, reason: 'clamped');
      expect(agg.secondsThrough(const LocalDate(2026, 9, 1)), 0);
    });

    test('week comparison: partial through today, full for past weeks, none without last-week record', () {
      final fixtures = <(StudySession, SessionSegment)>[
        _saved('a', DateTime(2026, 9, 21, 9), DateTime(2026, 9, 21, 10)), // last Mon 60
        _saved('b', DateTime(2026, 9, 26, 9), DateTime(2026, 9, 26, 11)), // last Sat 120
        _saved('c', DateTime(2026, 9, 29, 9), DateTime(2026, 9, 29, 9, 30)), // this Tue 30
      ];
      final sessions = [for (final f in fixtures) f.$1];
      final segments = [for (final f in fixtures) f.$2];
      final current = SeatedAggregate.build(from: monday, to: sunday, segments: segments, sessions: sessions);
      final previous = SeatedAggregate.build(from: monday.addDays(-7), to: monday.addDays(-1), segments: segments, sessions: sessions);
      final partial = WeekComparison.of(current: current, previous: previous, today: const LocalDate(2026, 9, 30));
      expect(partial.partial, isTrue);
      expect(partial.thisSeconds, 30 * 60);
      expect(partial.lastSeconds, 60 * 60, reason: 'last Mon..Wed only');
      expect(partial.diffSeconds, -30 * 60);
      final full = WeekComparison.of(current: current, previous: previous, today: const LocalDate(2026, 10, 10));
      expect(full.partial, isFalse);
      expect(full.lastSeconds, 180 * 60);
      final none = WeekComparison.of(
        current: previous,
        previous: SeatedAggregate.build(from: monday.addDays(-14), to: monday.addDays(-8), segments: segments, sessions: sessions),
        today: const LocalDate(2026, 9, 30),
      );
      expect(none.hasLast, isFalse);
    });

    test('empty range and reversed range are harmless', () {
      final agg = SeatedAggregate.build(from: monday, to: sunday, segments: const [], sessions: const []);
      expect(agg.totalSeconds, 0);
      expect(agg.hasRecord, isFalse);
      expect(agg.averagePerRecordedDay, 0);
      expect(agg.averageSessionSeconds, 0);
      expect(agg.focus.runCount, 0);
      expect(agg.focus.longestSeconds, 0);
      final reversed = SeatedAggregate.build(from: sunday, to: monday, segments: const [], sessions: const []);
      expect(reversed.daily, isEmpty);
      expect(SeatedSlices.clip(from: sunday, to: monday, segments: const [], sessions: const []), isEmpty);
    });
  });

  group('week timetable', () {
    test('blocks per day, merge of gaps ≤ 1 min, exact seconds, recurrence instances', () {
      final s = _session('a', DateTime(2026, 9, 29, 9), DateTime(2026, 9, 29, 10, 30), subject: 'math');
      final segs = <SessionSegment>[
        _seg('a', DateTime(2026, 9, 29, 9), DateTime(2026, 9, 29, 9, 30)),
        _seg('a', DateTime(2026, 9, 29, 9, 30), DateTime(2026, 9, 29, 9, 30, 40), kind: SegmentKind.away),
        _seg('a', DateTime(2026, 9, 29, 9, 30, 40), DateTime(2026, 9, 29, 10)), // 40 s gap → merged
        _seg('a', DateTime(2026, 9, 29, 10), DateTime(2026, 9, 29, 10, 5), kind: SegmentKind.away),
        _seg('a', DateTime(2026, 9, 29, 10, 5), DateTime(2026, 9, 29, 10, 30)), // 5 min gap → new block
      ];
      final (b, segB) = _saved('b', DateTime(2026, 9, 30, 23, 30), DateTime(2026, 10, 1, 0, 30), kind: SessionKind.self);
      final rec = Recurrence(
        id: 'r',
        stamp: _stamp(DateTime(2026, 9, 1).toUtc()),
        title: '수학 학원',
        weekdayMask: Recurrence.maskOf([2, 4]),
        startTime: const LocalTime(16, 0),
        endTime: const LocalTime(17, 30),
      );
      final week = WeekTimetable.build(weekStart: monday, segments: [...segs, segB], sessions: [s, b], recurrences: [rec]);
      final tue = week.blocks[const LocalDate(2026, 9, 29)]!;
      expect(tue.length, 2);
      expect(tue.first.seconds, 30 * 60 + 29 * 60 + 20, reason: 'gap excluded from the seconds');
      expect(tue.first.startMinutes, 9 * 60);
      expect(tue.first.endMinutes, 10 * 60);
      expect(tue.last.seconds, 25 * 60);
      expect(week.blocks[const LocalDate(2026, 9, 30)]!.single.endMinutes, 1440);
      expect(week.blocks[const LocalDate(2026, 10, 1)]!.single.startMinutes, 0);
      expect(week.blocks[const LocalDate(2026, 10, 1)]!.single.isSelf, isTrue);
      expect(week.totalSeconds, 84 * 60 + 20 + 60 * 60);
      expect(week.hasBlocks, isTrue);
      expect(week.recurrences[const LocalDate(2026, 9, 29)]!.single.title, '수학 학원');
      expect(week.recurrences[const LocalDate(2026, 10, 1)]!.length, 1);
      expect(week.recurrences[const LocalDate(2026, 9, 30)], isEmpty);
      expect(week.hasRecurrences, isTrue);
      expect(week.days.length, 7);
      expect(week.weekEnd, sunday);
    });

    test('empty week', () {
      final week = WeekTimetable.build(weekStart: monday, segments: const [], sessions: const [], recurrences: const []);
      expect(week.hasBlocks, isFalse);
      expect(week.hasRecurrences, isFalse);
      expect(week.blocks.length, 7);
    });
  });
}
