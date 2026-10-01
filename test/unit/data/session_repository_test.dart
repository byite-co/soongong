import 'package:flutter_test/flutter_test.dart';
import 'package:soongong/core/domain/enums.dart';
import 'package:soongong/core/domain/local_date.dart';
import 'package:soongong/features/measure/domain/segment.dart';
import 'package:soongong/features/measure/domain/session_snapshot.dart';

import 'db_test_helpers.dart';

DateTime at(int min) => kT0.add(Duration(minutes: min));

List<Segment> threeSegments() => <Segment>[
      Segment(id: 'seg-a', kind: SegmentKind.seated, startAt: at(0), endAt: at(20)),
      Segment(id: 'seg-b', kind: SegmentKind.away, startAt: at(20), endAt: at(25)),
      Segment(id: 'seg-c', kind: SegmentKind.seated, startAt: at(25), endAt: at(40)),
    ];

void main() {
  late TestHarness h;

  setUp(() => h = TestHarness());
  tearDown(() => h.close());

  test('saveFinished stores the session + segments, computes seated_seconds, '
      'enqueues each row and clears the snapshot', () async {
    await h.sessions.writeSnapshot(
      SessionSnapshot(
        sessionId: 'sess-1',
        mode: SessionMode.camera,
        kind: SessionKind.study,
        startedAt: at(0),
        segments: const <Segment>[],
        openKind: SegmentKind.seated,
        openStart: at(0),
        savedAt: at(39),
        sensitivity: 0,
      ),
    );
    expect(await h.sessions.readSnapshot(), isNotNull);

    final s = await h.sessions.saveFinished(
      id: 'sess-1',
      kind: SessionKind.study,
      mode: SessionMode.camera,
      startedAt: at(0),
      endedAt: at(40),
      status: SessionStatus.finished,
      segments: threeSegments(),
      sensitivityLevel: 1,
      subjectId: 'math',
      note: '메모',
    );
    expect(s.seatedSeconds, 35 * 60);
    expect(s.status, SessionStatus.finished);
    expect(s.note, '메모');
    expect((await h.sessions.getSegments('sess-1')).map((x) => x.id), <String>['seg-a', 'seg-b', 'seg-c']);
    expect((await h.outbox()).length, 4);
    expect(await h.sessions.readSnapshot(), isNull);
    expect(await h.sessions.daysWithSessions(), <LocalDate>{LocalDate.of(kT0)});
  });

  test('watchBetween filters by local date of started_at', () async {
    for (final (id, start) in <(String, DateTime)>[
      ('a', DateTime(2026, 9, 28, 9)),
      ('b', DateTime(2026, 9, 30, 23, 30)),
      ('c', DateTime(2026, 10, 1, 0, 10)),
    ]) {
      await h.sessions.saveFinished(
        id: id,
        kind: SessionKind.study,
        mode: SessionMode.manual,
        startedAt: start,
        endedAt: start.add(const Duration(minutes: 5)),
        status: SessionStatus.finished,
        segments: <Segment>[
          Segment(id: 'seg-$id', kind: SegmentKind.manual, startAt: start, endAt: start.add(const Duration(minutes: 5))),
        ],
        sensitivityLevel: 0,
      );
    }
    final rows = await h.sessions.watchBetween(LocalDate.parse('2026-09-29'), LocalDate.parse('2026-09-30')).first;
    expect(rows.map((s) => s.id), <String>['b']);
    expect((await h.sessions.getBetween(LocalDate.parse('2026-09-01'), LocalDate.parse('2026-10-31'))).length, 3);
  });

  test('applyCorrection flips the segment, records a correction and '
      'recomputes seated_seconds', () async {
    await h.sessions.saveFinished(
      id: 'sess-1',
      kind: SessionKind.study,
      mode: SessionMode.camera,
      startedAt: at(0),
      endedAt: at(40),
      status: SessionStatus.finished,
      segments: threeSegments(),
      sensitivityLevel: 0,
    );
    final out = await h.sessions.applyCorrection(
      sessionId: 'sess-1',
      segmentId: 'seg-b',
      toKind: SegmentKind.seated,
      sensitivityBefore: 0,
      sensitivityAfter: 0,
    );
    expect(out!.fromKind, SegmentKind.away);
    expect((await h.sessions.get('sess-1'))!.seatedSeconds, 40 * 60);
    final seg = (await h.sessions.getSegments('sess-1')).firstWhere((s) => s.id == 'seg-b');
    expect(seg.kind, SegmentKind.seated);
    expect(seg.corrected, isTrue);
    final corr = await h.sessions.watchCorrections('sess-1').first;
    expect(corr.single.segmentId, 'seg-b');
    expect(corr.single.toKind, SegmentKind.seated);
    expect((await h.sessions.correctionsSince(kT0.subtract(const Duration(days: 14)))).length, 1);
    // Same kind again → no-op.
    expect(
      await h.sessions.applyCorrection(
        sessionId: 'sess-1',
        segmentId: 'seg-b',
        toKind: SegmentKind.seated,
        sensitivityBefore: 0,
        sensitivityAfter: 0,
      ),
      isNull,
    );
  });

  test('commitDelete cascades to segments and corrections', () async {
    await h.sessions.saveFinished(
      id: 'sess-1',
      kind: SessionKind.study,
      mode: SessionMode.camera,
      startedAt: at(0),
      endedAt: at(40),
      status: SessionStatus.finished,
      segments: threeSegments(),
      sensitivityLevel: 0,
    );
    await h.sessions.applyCorrection(
      sessionId: 'sess-1',
      segmentId: 'seg-b',
      toKind: SegmentKind.seated,
      sensitivityBefore: 0,
      sensitivityAfter: 0,
    );
    await h.sessions.softDelete('sess-1');
    expect(await h.sessions.watchAll().first, isEmpty);
    await h.sessions.commitDelete('sess-1');
    expect(await h.sessions.getSegments('sess-1'), isEmpty);
    expect(await h.sessions.watchCorrections('sess-1').first, isEmpty);
    expect((await h.raw('session_segments', 'seg-a'))!['deleted_at'], isNotNull);
    expect((await h.raw('sessions', 'sess-1'))!['deleted_at'], isNotNull);
  });

  test('snapshot round-trips every D23 field', () async {
    final snap = SessionSnapshot(
      sessionId: 'sess-9',
      mode: SessionMode.camera,
      kind: SessionKind.todo,
      startedAt: at(0),
      segments: <Segment>[
        Segment(id: 'x', kind: SegmentKind.seated, startAt: at(0), endAt: at(10)),
      ],
      openKind: SegmentKind.away,
      openStart: at(10),
      savedAt: at(12),
      sensitivity: 2,
      lastSeatedAt: at(10),
      awayCandidateSince: null,
      subjectId: 'math',
      plannerItemId: 'p1',
    );
    await h.sessions.writeSnapshot(snap);
    await h.sessions.writeSnapshot(snap.copyWith(savedAt: at(13)));
    final read = (await h.sessions.readSnapshot())!;
    expect(read.sessionId, 'sess-9');
    expect(read.mode, SessionMode.camera);
    expect(read.kind, SessionKind.todo);
    expect(read.segments.single.endAt, at(10));
    expect(read.openKind, SegmentKind.away);
    expect(read.openStart, at(10));
    expect(read.savedAt, at(13), reason: 'single row overwritten');
    expect(read.sensitivity, 2);
    expect(read.lastSeatedAt, at(10));
    expect(read.awayCandidateSince, isNull);
    expect(read.subjectId, 'math');
    expect(read.plannerItemId, 'p1');
    expect((await h.db.select(h.db.sessionSnapshots).get()).length, 1);
    await h.sessions.clearSnapshot();
    expect(await h.sessions.watchSnapshot().first, isNull);
  });
}
