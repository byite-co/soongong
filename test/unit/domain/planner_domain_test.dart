// S07 planner domain: month grid, density scale, band layout, draft
// validation/dirtiness, target-time suggestion and the month aggregate.

import 'package:flutter_test/flutter_test.dart';
import 'package:soongong/core/domain/entities/entities.dart';
import 'package:soongong/core/domain/enums.dart';
import 'package:soongong/core/domain/local_date.dart';
import 'package:soongong/features/planner/domain/band_layout.dart';
import 'package:soongong/features/planner/domain/density_scale.dart';
import 'package:soongong/features/planner/domain/month_aggregate.dart';
import 'package:soongong/features/planner/domain/month_grid.dart';
import 'package:soongong/features/planner/domain/planner_draft.dart';
import 'package:soongong/features/planner/domain/target_time_suggestion.dart';

final SyncStamp _stamp = SyncStamp(
  userId: 'u',
  createdAt: DateTime.utc(2026, 9, 1),
  clientUpdatedAt: DateTime.utc(2026, 9, 1),
  deviceId: 'd',
);

PlannerItem item(
  String id, {
  required String date,
  PlannerKind kind = PlannerKind.study,
  String title = 't',
  String? subjectId,
  int? target,
  bool done = false,
  int sortOrder = 0,
  String? bandStart,
  String? bandEnd,
}) =>
    PlannerItem(
      id: id,
      stamp: _stamp,
      kind: kind,
      title: title,
      subjectId: subjectId,
      targetMinutes: target,
      date: LocalDate.parse(date),
      isDone: done,
      sortOrder: sortOrder,
      bandStart: bandStart == null ? null : LocalDate.parse(bandStart),
      bandEnd: bandEnd == null ? null : LocalDate.parse(bandEnd),
    );

PlannerItem band(String id, String from, String to, {String title = 'b'}) =>
    item(id, date: from, kind: PlannerKind.event, title: title, bandStart: from, bandEnd: to);

StudySession session(
  String id, {
  required DateTime start,
  required int seatedSeconds,
  String? subjectId,
  String? itemId,
  SessionStatus status = SessionStatus.finished,
  bool ended = true,
}) =>
    StudySession(
      id: id,
      stamp: _stamp,
      subjectId: subjectId,
      plannerItemId: itemId,
      kind: SessionKind.study,
      mode: SessionMode.manual,
      startedAt: start.toUtc(),
      endedAt: ended ? start.add(Duration(seconds: seatedSeconds)).toUtc() : null,
      status: status,
      seatedSeconds: seatedSeconds,
      sensitivityLevel: 0,
    );

SessionSegment segment(String sessionId, DateTime start, DateTime end, {SegmentKind kind = SegmentKind.seated}) =>
    SessionSegment(
      id: '$sessionId-${start.millisecondsSinceEpoch}',
      stamp: _stamp,
      sessionId: sessionId,
      kind: kind,
      startAt: start.toUtc(),
      endAt: end.toUtc(),
    );

void main() {
  group('MonthGrid', () {
    test('42 cells, Monday start: 2026-10 begins on 09-28', () {
      final g = MonthGrid.of(2026, 10, weekStart: 1);
      expect(g.days.length, 42);
      expect(g.first.key, '2026-09-28');
      expect(g.last.key, '2026-11-08');
      expect(g.inMonth(LocalDate.parse('2026-10-01')), isTrue);
      expect(g.inMonth(LocalDate.parse('2026-09-30')), isFalse);
      expect(g.rowOf(LocalDate.parse('2026-10-01')), 0);
      expect(g.colOf(LocalDate.parse('2026-10-01')), 3); // Thursday
      expect(g.rowOf(LocalDate.parse('2026-10-31')), 4);
      expect(g.columnWeekdays, <int>[1, 2, 3, 4, 5, 6, 7]);
      expect(g.week(0).map((d) => d.day), <int>[28, 29, 30, 1, 2, 3, 4]);
    });

    test('Sunday start moves the first column; previous/next wrap the year', () {
      final g = MonthGrid.of(2026, 10, weekStart: 7);
      expect(g.first.key, '2026-09-27');
      expect(g.columnWeekdays, <int>[7, 1, 2, 3, 4, 5, 6]);
      expect(g.colOf(LocalDate.parse('2026-10-01')), 4);
      expect(MonthGrid.of(2026, 1, weekStart: 1).previous().key, '2025-12');
      expect(MonthGrid.of(2026, 12, weekStart: 1).next().key, '2027-01');
      expect(MonthGrid.daysInMonth(2028, 2), 29);
      expect(g.indexOf(LocalDate.parse('2026-12-01')), -1);
    });
  });

  group('DensityScale', () {
    test('reference = top-10% boundary of positive days; 4 levels', () {
      // 20 positive days 1..20 minutes → rank ceil(18) = 18 → 18 min.
      final scale = DensityScale.fromDaily(<int>[
        for (var i = 1; i <= 20; i++) i * 60,
        0,
        0,
      ]);
      expect(scale.referenceSeconds, 18 * 60);
      expect(scale.levelOf(0), 0);
      expect(scale.levelOf(60), 1); // 1/18 → ceil(0.22) = 1
      expect(scale.levelOf(9 * 60), 2); // 0.5 → 2
      expect(scale.levelOf(10 * 60), 3); // 0.55 → 3
      expect(scale.levelOf(18 * 60), 4);
      expect(scale.levelOf(60 * 60), 4, reason: 'capped above the reference');
      expect(scale.ratioOf(60 * 60), 1.0);
    });

    test('no positive day → no density; a single day is its own reference', () {
      expect(DensityScale.fromDaily(<int>[0, 0]).levelOf(100), 0);
      final one = DensityScale.fromDaily(<int>[1800]);
      expect(one.referenceSeconds, 1800);
      expect(one.levelOf(1800), 4);
      expect(one.levelOf(450), 1);
    });
  });

  group('BandLayout', () {
    final grid = MonthGrid.of(2026, 10, weekStart: 1);

    test('splits a band per row and keeps its lane; 2 lanes max, overflow counted per day', () {
      final layout = BandLayout.compute(<PlannerItem>[
        band('exam', '2026-10-01', '2026-10-06', title: '중간고사'),
        band('perf', '2026-10-03', '2026-10-03', title: '수행평가'),
        band('trip', '2026-10-02', '2026-10-04', title: '수학여행'),
      ], grid);
      final exam = layout.spans.where((s) => s.item.id == 'exam').toList();
      expect(exam.length, 2, reason: '10/1(목)–10/4(일) and 10/5–10/6');
      expect(exam.first.row, 0);
      expect(exam.first.colStart, 3);
      expect(exam.first.colEnd, 6);
      expect(exam.first.continuesAfter, isTrue);
      expect(exam.last.row, 1);
      expect(exam.last.colStart, 0);
      expect(exam.last.colEnd, 1);
      expect(exam.last.continuesBefore, isTrue);
      expect(exam.every((s) => s.lane == 0), isTrue);
      // trip (longer) is placed before perf → lane 1; perf has no free lane.
      expect(layout.spans.where((s) => s.item.id == 'trip').single.lane, 1);
      expect(layout.spans.any((s) => s.item.id == 'perf'), isFalse);
      expect(layout.hiddenOn(LocalDate.parse('2026-10-03')), 1);
      expect(layout.hiddenOn(LocalDate.parse('2026-10-02')), 0);
      expect(layout.lanesOn(LocalDate.parse('2026-10-02')), 2);
      expect(layout.lanesOn(LocalDate.parse('2026-10-05')), 1);
      expect(layout.lanesOn(LocalDate.parse('2026-10-20')), 0);
    });

    test('bands outside the grid are ignored, overlapping ones clipped', () {
      final layout = BandLayout.compute(<PlannerItem>[
        band('old', '2026-08-01', '2026-08-03'),
        band('long', '2026-09-20', '2026-11-20'),
      ], grid);
      expect(layout.spans.where((s) => s.item.id == 'old'), isEmpty);
      final long = layout.spans.where((s) => s.item.id == 'long').toList();
      expect(long.length, 6);
      expect(long.first.continuesBefore, isTrue);
      expect(long.last.continuesAfter, isTrue);
    });
  });

  group('PlannerDraft', () {
    final day = LocalDate.parse('2026-10-09');

    test('create defaults, kind switch keeps title and applies target rules', () {
      final d = PlannerDraft.create(date: day);
      expect(d.kind, PlannerKind.study);
      expect(d.targetMinutes, 30);
      expect(d.bandStart, day);
      expect(d.bandEnd, day);
      final todo = d.copyWith(title: '단어').withKind(PlannerKind.todo);
      expect(todo.targetMinutes, isNull);
      expect(todo.title, '단어');
      expect(todo.withKind(PlannerKind.self).targetMinutes, 30);
      expect(d.copyWith(targetMinutes: 45).withKind(PlannerKind.self).targetMinutes, 45);
    });

    test('validation: title, range 40, target ≥ 1, band order, weekdays, time order', () {
      final d = PlannerDraft.create(date: day);
      expect(d.validate(), <DraftError>[DraftError.titleEmpty]);
      expect(d.copyWith(title: ' 수학 ').isValid, isTrue);
      expect(d.copyWith(title: 'a', rangeText: 'x' * 41).validate(), contains(DraftError.rangeTooLong));
      expect(d.copyWith(title: 'a', rangeText: 'x' * 40).isValid, isTrue);
      expect(d.copyWith(title: 'a', targetMinutes: 0).validate(), contains(DraftError.targetInvalid));
      final period = d.copyWith(title: 'a').withKind(PlannerKind.event).copyWith(
            bandStart: LocalDate.parse('2026-10-10'),
            bandEnd: LocalDate.parse('2026-10-09'),
          );
      expect(period.validate(), <DraftError>[DraftError.bandOrder]);
      final repeat = period.copyWith(eventMode: DraftEventMode.repeat, weekdays: <int>{});
      expect(repeat.validate(), <DraftError>[DraftError.noWeekday]);
      expect(
        repeat.copyWith(weekdays: <int>{1}, startTime: const LocalTime(20, 0), endTime: const LocalTime(19, 0)).validate(),
        <DraftError>[DraftError.timeOrder],
      );
    });

    test('dirty: only fields that apply to the kind count; new entry = any input', () {
      final original = PlannerDraft.fromItem(item('i', date: '2026-10-09', title: '수학', target: 30, subjectId: 's1'));
      expect(original.differsFrom(original), isFalse);
      expect(original.copyWith(title: '수학 ').differsFrom(original), isFalse, reason: 'trimmed');
      expect(original.copyWith(title: '영어').differsFrom(original), isTrue);
      expect(original.copyWith(targetMinutes: 45).differsFrom(original), isTrue);
      expect(original.copyWith(date: LocalDate.parse('2026-10-10')).differsFrom(original), isTrue);
      expect(original.copyWith(weekdays: <int>{1}).differsFrom(original), isFalse, reason: 'repeat fields do not apply to study');
      final todo = original.withKind(PlannerKind.todo);
      expect(todo.differsFrom(original), isTrue);
      expect(PlannerDraft.create(date: day).hasInput, isFalse);
      expect(PlannerDraft.create(date: day).copyWith(title: ' ').hasInput, isFalse);
      expect(PlannerDraft.create(date: day).copyWith(title: 'x').hasInput, isTrue);
    });

    test('recurrence round trip and end options', () {
      final r = Recurrence(
        id: 'r',
        stamp: _stamp,
        title: '학원',
        subjectId: 's1',
        weekdayMask: Recurrence.maskOf(<int>[1, 3]),
        startTime: const LocalTime(19, 0),
        endTime: const LocalTime(21, 0),
      );
      final d = PlannerDraft.fromRecurrence(r, date: day);
      expect(d.isRepeat, isTrue);
      expect(d.weekdays, <int>{1, 3});
      expect(d.endOption, RecurrenceEndOption.never);
      expect(d.resolvedEndsOn(), isNull);
      expect(d.copyWith(endOption: RecurrenceEndOption.endOfMonth).resolvedEndsOn(), LocalDate.parse('2026-10-31'));
      expect(
        d.copyWith(endOption: RecurrenceEndOption.date, endsOn: LocalDate.parse('2026-12-20')).resolvedEndsOn(),
        LocalDate.parse('2026-12-20'),
      );
      expect(d.copyWith(endOption: RecurrenceEndOption.endOfMonth).differsFrom(d), isTrue);
      expect(d.copyWith(weekdays: <int>{3, 1}).differsFrom(d), isFalse);
      final withEnd = PlannerDraft.fromRecurrence(
        r.copyWith(endsOn: LocalDate.parse('2026-11-30')),
        date: day,
      );
      expect(withEnd.endOption, RecurrenceEndOption.date);
      expect(withEnd.resolvedEndsOn(), LocalDate.parse('2026-11-30'));
    });
  });

  group('TargetTimePolicy', () {
    const policy = TargetTimePolicy();
    test('average of the latest 5 saved sessions of the subject', () {
      final sessions = <StudySession>[
        for (var i = 0; i < 8; i++)
          session('s$i', start: DateTime(2026, 10, 1 + i, 9), seatedSeconds: (i + 1) * 600, subjectId: 'math'),
        session('eng', start: DateTime(2026, 10, 20, 9), seatedSeconds: 7200, subjectId: 'eng'),
        session('open', start: DateTime(2026, 10, 21, 9), seatedSeconds: 7200, subjectId: 'math', ended: false, status: SessionStatus.interrupted),
        session('zero', start: DateTime(2026, 10, 22, 9), seatedSeconds: 0, subjectId: 'math'),
      ];
      final s = policy.recentAverage(sessions, subjectId: 'math')!;
      // latest 5 by start: i = 3..7 → 40,50,60,70,80 min → 60.
      expect(s.minutes, 60);
      expect(s.sampleCount, 5);
      expect(policy.recentAverage(sessions, subjectId: 'sci'), isNull);
      final two = policy.recentAverage(sessions.take(2), subjectId: 'math')!;
      expect(two.minutes, 15);
      expect(two.sampleCount, 2);
    });
  });

  group('MonthAggregate', () {
    final grid = MonthGrid.of(2026, 10, weekStart: 1);
    test('daily 순공 clipped at local midnight; unsaved sessions excluded; counts; links', () {
      final a = session('a', start: DateTime(2026, 10, 1, 23, 50), seatedSeconds: 1200, itemId: 'i1');
      final live = session('live', start: DateTime(2026, 10, 3, 10), seatedSeconds: 3600, status: SessionStatus.active, ended: false);
      final b = session('b', start: DateTime(2026, 10, 3, 11), seatedSeconds: 600, itemId: 'i1');
      final agg = MonthAggregate.build(
        grid: grid,
        items: <PlannerItem>[
          item('i1', date: '2026-10-01', title: '수학', target: 30, done: true, sortOrder: 1),
          item('i0', date: '2026-10-01', kind: PlannerKind.todo, title: '프린트', sortOrder: 0),
          item('e', date: '2026-10-01', kind: PlannerKind.event, title: '학교 행사', sortOrder: 2),
          item('sep', date: '2026-09-29', title: '지난달'),
          band('exam', '2026-10-05', '2026-10-07'),
        ],
        recurrences: <Recurrence>[
          Recurrence(
            id: 'r',
            stamp: _stamp,
            title: '학원',
            weekdayMask: Recurrence.maskOf(<int>[4]), // Thursday
            startTime: const LocalTime(19, 0),
            endTime: const LocalTime(21, 0),
          ),
        ],
        segments: <SessionSegment>[
          segment('a', DateTime(2026, 10, 1, 23, 50), DateTime(2026, 10, 2, 0, 10)),
          segment('live', DateTime(2026, 10, 3, 10), DateTime(2026, 10, 3, 11)),
          segment('b', DateTime(2026, 10, 3, 11), DateTime(2026, 10, 3, 11, 10)),
          segment('b', DateTime(2026, 10, 3, 11, 10), DateTime(2026, 10, 3, 11, 20), kind: SegmentKind.away),
        ],
        sessions: <StudySession>[a, live, b],
      );
      expect(agg.seatedOn(LocalDate.parse('2026-10-01')), 600);
      expect(agg.seatedOn(LocalDate.parse('2026-10-02')), 600);
      expect(agg.seatedOn(LocalDate.parse('2026-10-03')), 600, reason: 'active session and away excluded');
      final d1 = agg.dayOf(LocalDate.parse('2026-10-01'));
      expect(d1.items.map((i) => i.id), <String>['i0', 'i1', 'e']);
      expect(d1.plannedMinutes, 30);
      expect(d1.recurrences.single.title, '학원');
      expect(agg.dayOf(LocalDate.parse('2026-10-02')).recurrences, isEmpty);
      expect(agg.plannedCount, 2, reason: 'event and last month excluded');
      expect(agg.doneCount, 1);
      expect(agg.bands.single.id, 'exam');
      expect(agg.bandLayout.spans.single.colStart, 0);
      expect(agg.sessionsByItem['i1']!.map((s) => s.id), <String>['b', 'a']);
      expect(agg.actualMinutes(d1.items[1]), 30);
      expect(agg.actualMinutes(d1.items[0]), 0);
    });

    test('dailySeated window', () {
      final s = session('a', start: DateTime(2026, 10, 1, 9), seatedSeconds: 1800);
      final daily = MonthAggregate.dailySeated(
        from: LocalDate.parse('2026-09-30'),
        to: LocalDate.parse('2026-10-02'),
        segments: <SessionSegment>[segment('a', DateTime(2026, 10, 1, 9), DateTime(2026, 10, 1, 9, 30))],
        sessions: <StudySession>[s],
      );
      expect(daily, <int>[0, 1800, 0]);
      expect(MonthAggregate.dailySeated(from: LocalDate.parse('2026-10-02'), to: LocalDate.parse('2026-10-01'), segments: const <SessionSegment>[], sessions: const <StudySession>[]), isEmpty);
    });
  });
}
