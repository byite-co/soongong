import 'package:flutter_test/flutter_test.dart';
import 'package:soongong/core/domain/clock.dart';
import 'package:soongong/core/domain/enums.dart';
import 'package:soongong/features/measure/domain/away_policy.dart';
import 'package:soongong/features/measure/domain/segment.dart';
import 'package:soongong/features/measure/domain/session_clock.dart';
import 'package:soongong/features/measure/domain/session_snapshot.dart';
import 'package:soongong/features/measure/domain/session_timeline.dart';

final DateTime t0 = DateTime.utc(2026, 9, 30, 10);
DateTime at(int seconds) => t0.add(Duration(seconds: seconds));

int _n = 0;
String nextId() => 'seg${++_n}';

SessionTimeline camera({int level = 0}) => SessionTimeline.start(
      sessionId: 's1',
      mode: SessionMode.camera,
      kind: SessionKind.study,
      startedAt: t0,
      sensitivityLevel: level,
      newId: nextId,
      subjectId: 'math',
    );

SessionTimeline manual() => SessionTimeline.start(
      sessionId: 's1',
      mode: SessionMode.manual,
      kind: SessionKind.self,
      startedAt: t0,
      sensitivityLevel: 0,
      newId: nextId,
    );

SessionSnapshot snap({
  required SegmentKind openKind,
  required int openStartSec,
  required int savedAtSec,
  int? lastSeatedSec,
  int? candidateSec,
  List<Segment> closed = const <Segment>[],
  SessionMode mode = SessionMode.camera,
}) =>
    SessionSnapshot(
      sessionId: 's1',
      mode: mode,
      kind: SessionKind.study,
      startedAt: t0,
      segments: closed,
      openKind: openKind,
      openStart: at(openStartSec),
      savedAt: at(savedAtSec),
      sensitivity: 0,
      lastSeatedAt: lastSeatedSec == null ? null : at(lastSeatedSec),
      awayCandidateSince: candidateSec == null ? null : at(candidateSec),
    );

void main() {
  setUp(() => _n = 0);

  group('live timeline', () {
    test('camera: away confirmed closes the seated segment retroactively and '
        'opens away; return re-opens seated', () {
      final tl = camera();
      expect(tl.openKind, SegmentKind.seated);
      for (var s = 1; s <= 30; s++) {
        expect(tl.onSeatSample(at: at(s), seated: true), isEmpty);
      }
      for (var s = 31; s < 90; s++) {
        expect(tl.onSeatSample(at: at(s), seated: false), isEmpty);
      }
      final confirmed = tl.onSeatSample(at: at(91), seated: false).single;
      expect(confirmed, isA<AwayConfirmed>());
      expect(tl.closedSegments.single.kind, SegmentKind.seated);
      expect(tl.closedSegments.single.endAt, at(30), reason: 'last seated');
      expect(tl.openKind, SegmentKind.away);
      expect(tl.openStart, at(30));
      expect(tl.seatedAt(at(91)), const Duration(seconds: 30));

      final returned = tl.onSeatSample(at: at(120), seated: true).single;
      expect(returned, isA<AwayReturned>());
      expect(tl.openKind, SegmentKind.seated);
      expect(tl.closedSegments.last.kind, SegmentKind.away);
      expect(tl.closedSegments.last.duration, const Duration(seconds: 90));

      final segments = tl.end(at(200));
      expect(segments.map((s) => s.kind), <SegmentKind>[
        SegmentKind.seated,
        SegmentKind.away,
        SegmentKind.seated,
      ]);
      expect(tl.seatedAt(at(200)), const Duration(seconds: 30 + 80));
      expect(tl.isEnded, isTrue);
      // end() is idempotent.
      expect(tl.end(at(300)).length, 3);
    });

    test('camera loss is paused, not away; samples are ignored while paused; '
        'resume re-seats', () {
      final tl = camera();
      tl.onSeatSample(at: at(10), seated: true);
      tl.pause(at(20));
      expect(tl.openKind, SegmentKind.paused);
      expect(tl.closedSegments.single.kind, SegmentKind.seated);
      // Not-seated samples during the pause never confirm away.
      for (var s = 21; s < 200; s++) {
        expect(tl.onSeatSample(at: at(s), seated: false), isEmpty);
      }
      expect(tl.isAway, isFalse);
      tl.pause(at(210)); // no-op
      tl.resume(at(220));
      expect(tl.openKind, SegmentKind.seated);
      expect(tl.lastSeatedAt, at(220));
      final segs = tl.end(at(250));
      expect(segs.map((s) => s.kind), <SegmentKind>[
        SegmentKind.seated,
        SegmentKind.paused,
        SegmentKind.seated,
      ]);
      expect(tl.seatedAt(at(250)), const Duration(seconds: 20 + 30));
    });

    test('manual mode: manual ↔ paused; seat samples are ignored', () {
      final tl = manual();
      expect(tl.openKind, SegmentKind.manual);
      expect(tl.onSeatSample(at: at(5), seated: false), isEmpty);
      tl.pause(at(60));
      tl.resume(at(120));
      expect(tl.openKind, SegmentKind.manual);
      final segs = tl.end(at(180));
      expect(segs.map((s) => s.kind), <SegmentKind>[
        SegmentKind.manual,
        SegmentKind.paused,
        SegmentKind.manual,
      ]);
      expect(tl.seatedAt(at(180)), const Duration(seconds: 120));
      expect(tl.lastSeatedAt, isNull);
    });

    test('snapshot carries closed segments, open segment, camera bookkeeping '
        'and no monotonic anchor; fromSnapshot continues the timeline', () {
      final tl = camera(level: 1);
      tl.onSeatSample(at: at(10), seated: true);
      tl.onSeatSample(at: at(20), seated: false); // candidate since 20
      final s = tl.snapshot(at(25));
      expect(s.sessionId, 's1');
      expect(s.mode, SessionMode.camera);
      expect(s.segments, isEmpty);
      expect(s.openKind, SegmentKind.seated);
      expect(s.openStart, t0);
      expect(s.lastSeatedAt, at(10));
      expect(s.awayCandidateSince, at(20));
      expect(s.sensitivity, 1);
      expect(s.savedAt, at(25));
      expect(s.subjectId, 'math');

      final json = SessionSnapshot.encodeSegments(<Segment>[
        Segment(id: 'a', kind: SegmentKind.seated, startAt: t0, endAt: at(5)),
      ]);
      final decoded = SessionSnapshot.decodeSegments(json);
      expect(decoded.single.kind, SegmentKind.seated);
      expect(decoded.single.endAt, at(5));

      final resumed = SessionTimeline.fromSnapshot(s, newId: nextId);
      expect(resumed.openKind, SegmentKind.seated);
      expect(resumed.awayCandidateSince, at(20));
      // The candidate window continues: threshold 75 s from 20 → 95.
      expect(resumed.onSeatSample(at: at(94), seated: false), isEmpty);
      expect(
        resumed.onSeatSample(at: at(95), seated: false).single,
        isA<AwayConfirmed>(),
      );
      expect(resumed.openStart, at(10));
    });
  });

  group('recover (D23)', () {
    test('seated, no candidate → closed at saved_at, seated counts', () {
      final r = SessionTimeline.recover(
        snapshot: snap(openKind: SegmentKind.seated, openStartSec: 0, savedAtSec: 600),
        sessionStartedAt: t0,
        newId: nextId,
      );
      expect(r.segments.single.kind, SegmentKind.seated);
      expect(r.segments.single.endAt, at(600));
      expect(r.seatedSeconds, 600);
      expect(r.endedAt, at(600));
      expect(r.status, SessionStatus.interrupted);
    });

    test('seated with away candidate → seated until last_seated_at, away after',
        () {
      final r = SessionTimeline.recover(
        snapshot: snap(
          openKind: SegmentKind.seated,
          openStartSec: 0,
          savedAtSec: 600,
          lastSeatedSec: 550,
          candidateSec: 551,
        ),
        sessionStartedAt: t0,
        newId: nextId,
      );
      expect(r.segments.map((s) => s.kind), <SegmentKind>[
        SegmentKind.seated,
        SegmentKind.away,
      ]);
      expect(r.segments[0].endAt, at(550));
      expect(r.segments[1].startAt, at(550));
      expect(r.segments[1].endAt, at(600));
      expect(r.seatedSeconds, 550);
    });

    test('manual → closed at saved_at, counts', () {
      final r = SessionTimeline.recover(
        snapshot: snap(
          openKind: SegmentKind.manual,
          openStartSec: 100,
          savedAtSec: 400,
          mode: SessionMode.manual,
          closed: <Segment>[
            Segment(id: 'a', kind: SegmentKind.manual, startAt: t0, endAt: at(50)),
            Segment(id: 'b', kind: SegmentKind.paused, startAt: at(50), endAt: at(100)),
          ],
        ),
        sessionStartedAt: t0,
        newId: nextId,
      );
      expect(r.segments.length, 3);
      expect(r.segments.last.kind, SegmentKind.manual);
      expect(r.seatedSeconds, 50 + 300);
    });

    test('away → closed at saved_at, excluded', () {
      final r = SessionTimeline.recover(
        snapshot: snap(
          openKind: SegmentKind.away,
          openStartSec: 300,
          savedAtSec: 450,
          closed: <Segment>[
            Segment(id: 'a', kind: SegmentKind.seated, startAt: t0, endAt: at(300)),
          ],
        ),
        sessionStartedAt: t0,
        newId: nextId,
      );
      expect(r.segments.last.kind, SegmentKind.away);
      expect(r.segments.last.endAt, at(450));
      expect(r.seatedSeconds, 300);
    });

    test('paused → closed at saved_at, excluded', () {
      final r = SessionTimeline.recover(
        snapshot: snap(
          openKind: SegmentKind.paused,
          openStartSec: 120,
          savedAtSec: 130,
          closed: <Segment>[
            Segment(id: 'a', kind: SegmentKind.seated, startAt: t0, endAt: at(120)),
          ],
        ),
        sessionStartedAt: t0,
        newId: nextId,
      );
      expect(r.segments.last.kind, SegmentKind.paused);
      expect(r.seatedSeconds, 120);
      expect(r.endedAt, at(130));
    });

    test('no snapshot → closed at session start, 0 minutes', () {
      final r = SessionTimeline.recover(
        snapshot: null,
        sessionStartedAt: t0,
        newId: nextId,
      );
      expect(r.segments, isEmpty);
      expect(r.seatedSeconds, 0);
      expect(r.endedAt, t0);
    });

    test('never adds time past saved_at (loss cap 15 s), empty segments '
        'dropped', () {
      final r = SessionTimeline.recover(
        snapshot: snap(
          openKind: SegmentKind.seated,
          openStartSec: 100,
          savedAtSec: 100,
          closed: <Segment>[
            Segment(id: 'a', kind: SegmentKind.seated, startAt: t0, endAt: at(100)),
            Segment(id: 'z', kind: SegmentKind.seated, startAt: at(100), endAt: at(100)),
          ],
        ),
        sessionStartedAt: t0,
        newId: nextId,
      );
      expect(r.segments.length, 1);
      expect(r.seatedSeconds, 100);
      expect(r.endedAt, at(100));
    });
  });

  group('SessionClock (D23)', () {
    test('timestamps follow the monotonic clock, not wall-clock jumps', () {
      final wall = FixedClock(t0);
      final mono = FakeMonotonicClock();
      final clock = SessionClock(wall: wall, monotonic: mono);
      expect(clock.isStarted, isFalse);
      expect(clock.start(), t0);
      mono.advance(const Duration(seconds: 30));
      wall.jumpTo(t0.add(const Duration(hours: 2))); // NTP jump
      expect(clock.now(), at(30));
      expect(clock.elapsed, const Duration(seconds: 30));
      wall.jumpTo(t0.subtract(const Duration(days: 1)));
      mono.advance(const Duration(seconds: 15));
      expect(clock.now(), at(45));
    });
  });
}
