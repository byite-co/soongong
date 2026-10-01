import 'package:flutter_test/flutter_test.dart';
import 'package:soongong/core/domain/entities/entities.dart';
import 'package:soongong/core/domain/enums.dart';
import 'package:soongong/core/domain/local_date.dart';
import 'package:soongong/features/measure/domain/segment.dart';
import 'package:soongong/features/stats/domain/stats_aggregator.dart';

SyncStamp stamp(DateTime at) =>
    SyncStamp(userId: 'u', createdAt: at, clientUpdatedAt: at, deviceId: 'd');

StudySession session(
  String id,
  DateTime startedLocal,
  int minutes, {
  String? subject,
  SessionKind kind = SessionKind.study,
}) =>
    StudySession(
      id: id,
      stamp: stamp(startedLocal.toUtc()),
      subjectId: subject,
      kind: kind,
      mode: SessionMode.camera,
      startedAt: startedLocal.toUtc(),
      endedAt: startedLocal.add(Duration(minutes: minutes)).toUtc(),
      status: SessionStatus.finished,
      seatedSeconds: minutes * 60,
      sensitivityLevel: 0,
    );

void main() {
  const agg = StatsAggregator(); // Monday week start
  // 2026-09-30 is a Wednesday.
  final sessions = <StudySession>[
    session('a', DateTime(2026, 9, 28, 9), 60, subject: 'math'),
    session('b', DateTime(2026, 9, 28, 20), 30, subject: 'eng'),
    session('c', DateTime(2026, 9, 30, 10), 45, subject: 'math', kind: SessionKind.self),
    session('d', DateTime(2026, 9, 22, 10), 90, subject: 'math'),
    session('e', DateTime(2026, 8, 31, 10), 10),
  ];

  test('daily / weekly / monthly / bySubject / byKind / activeDays', () {
    final daily = agg.daily(sessions);
    expect(daily[LocalDate.parse('2026-09-28')], const Duration(minutes: 90));
    expect(daily[LocalDate.parse('2026-09-30')], const Duration(minutes: 45));

    final weekly = agg.weekly(sessions);
    expect(weekly[LocalDate.parse('2026-09-28')], const Duration(minutes: 135));
    expect(weekly[LocalDate.parse('2026-09-21')], const Duration(minutes: 90));
    expect(weekly[LocalDate.parse('2026-08-31')], const Duration(minutes: 10));

    final monthly = agg.monthly(sessions);
    expect(monthly['2026-09'], const Duration(minutes: 225));
    expect(monthly['2026-08'], const Duration(minutes: 10));

    final bySubject = agg.bySubject(sessions);
    expect(bySubject['math'], const Duration(minutes: 195));
    expect(bySubject['eng'], const Duration(minutes: 30));
    expect(bySubject[null], const Duration(minutes: 10));

    expect(agg.byKind(sessions)[SessionKind.self], const Duration(minutes: 45));
    expect(agg.activeDays(sessions), 4);
    expect(
      agg.totalBetween(sessions, LocalDate.parse('2026-09-28'), LocalDate.parse('2026-09-30')),
      const Duration(minutes: 135),
    );
  });

  test('compareWeeks is a fact: this week vs last week', () {
    final c = agg.compareWeeks(sessions, today: LocalDate.parse('2026-09-30'));
    expect(c.thisWeekStart, LocalDate.parse('2026-09-28'));
    expect(c.thisWeek, const Duration(minutes: 135));
    expect(c.lastWeek, const Duration(minutes: 90));
    expect(c.difference, const Duration(minutes: 45));

    const sunday = StatsAggregator(weekStart: 7);
    final s = sunday.compareWeeks(sessions, today: LocalDate.parse('2026-09-30'));
    expect(s.thisWeekStart, LocalDate.parse('2026-09-27'));
  });

  test('hourHistogram splits segments across local hour boundaries', () {
    final segs = <Segment>[
      Segment(
        id: 'a',
        kind: SegmentKind.seated,
        startAt: DateTime(2026, 9, 30, 9, 40),
        endAt: DateTime(2026, 9, 30, 10, 20),
      ),
      Segment(
        id: 'b',
        kind: SegmentKind.away,
        startAt: DateTime(2026, 9, 30, 10, 20),
        endAt: DateTime(2026, 9, 30, 10, 30),
      ),
      Segment(
        id: 'c',
        kind: SegmentKind.manual,
        startAt: DateTime(2026, 9, 30, 23, 50),
        endAt: DateTime(2026, 10, 1, 0, 10),
      ),
    ];
    final h = agg.hourHistogram(segs);
    expect(h.length, 24);
    expect(h[9], const Duration(minutes: 20));
    expect(h[10], const Duration(minutes: 20));
    expect(h[23], const Duration(minutes: 10));
    expect(h[0], const Duration(minutes: 10));
    expect(h[11], Duration.zero);
  });

  test('focusPattern merges adjacent seated runs and buckets them', () {
    DateTime t(int min) => DateTime(2026, 9, 30, 9).add(Duration(minutes: min));
    final segs = <Segment>[
      // run 1: 0–40 split by a correction at 20 (adjacent) → 40 min
      Segment(id: 'a', kind: SegmentKind.seated, startAt: t(0), endAt: t(20)),
      Segment(id: 'b', kind: SegmentKind.seated, startAt: t(20), endAt: t(40), corrected: true),
      Segment(id: 'c', kind: SegmentKind.away, startAt: t(40), endAt: t(45)),
      // run 2: 45–55 → 10 min
      Segment(id: 'd', kind: SegmentKind.seated, startAt: t(45), endAt: t(55)),
      Segment(id: 'e', kind: SegmentKind.paused, startAt: t(55), endAt: t(60)),
      // run 3: 60–140 → 80 min
      Segment(id: 'f', kind: SegmentKind.manual, startAt: t(60), endAt: t(140)),
      // run 4: 150–170 → 20 min
      Segment(id: 'g', kind: SegmentKind.seated, startAt: t(150), endAt: t(170)),
    ];
    final p = agg.focusPattern(segs);
    expect(p.under15, 1);
    expect(p.from15To30, 1);
    expect(p.from30To60, 1);
    expect(p.over60, 1);
    expect(p.runs, 4);
    expect(p.longest, const Duration(minutes: 80));
    expect(agg.focusPattern(const <Segment>[]).runs, 0);
  });
}
