import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:soongong/core/contracts/seat_engine.dart';
import 'package:soongong/core/domain/clock.dart';
import 'package:soongong/core/domain/enums.dart';
import 'package:soongong/core/domain/local_date.dart';
import 'package:soongong/features/measure/application/measure_controller.dart';
import 'package:soongong/features/measure/domain/segment.dart';
import 'package:soongong/features/measure/domain/session_snapshot.dart';

import '../../helpers/measure_fakes.dart';
import '../data/db_test_helpers.dart';

void main() {
  late TestHarness h;
  late FakeMonotonicClock mono;
  late TestMeasureEngine engine;
  late TestMeasureDevice device;
  late MeasureController controller;
  MeasureController makeController() => MeasureController(
    engine: engine,
    sessions: h.sessions,
    settings: h.settings,
    planner: h.planner,
    wall: h.clock,
    monotonic: mono,
    device: device,
    automaticTicks: false,
  );
  Future<void> flush() async {
    for (var i = 0; i < 10; i++) {
      await Future<void>.delayed(Duration.zero);
    }
  }

  setUp(() {
    h = TestHarness();
    mono = FakeMonotonicClock();
    engine = TestMeasureEngine();
    device = TestMeasureDevice();
    controller = makeController();
  });
  tearDown(() async {
    controller.dispose();
    await flush();
    await engine.close();
    await h.close();
  });

  test('manual start persists active row; final save updates same id and clears checkpoint', () async {
    expect(await controller.start(mode: SessionMode.manual), isTrue);
    final id = controller.sessionId!;
    expect((await h.sessions.get(id))!.status, SessionStatus.active);
    expect(await h.sessions.daysWithSessions(), isEmpty);
    expect(device.awake, isTrue);
    mono.advance(const Duration(minutes: 4));
    h.clock.jumpTo(kT0.add(const Duration(hours: 2)));
    expect(controller.seated.inMinutes, 4);
    await controller.finish();
    expect(device.awake, isFalse);
    expect((await h.sessions.get(id))!.status, SessionStatus.interrupted);
    expect(await h.sessions.daysWithSessions(), isEmpty);
    expect(await controller.save(), isTrue);
    expect((await h.sessions.get(id))!.seatedSeconds, 240);
    expect((await h.sessions.getAll()).length, 1);
    expect(await h.sessions.daysWithSessions(), {LocalDate.of(kT0)});
    expect(await h.sessions.readSnapshot(), isNull);
  });

  test('away confirmation is retroactive, ignores received wall clock, returns automatically', () async {
    await controller.start(mode: SessionMode.camera);
    mono.advance(const Duration(seconds: 10));
    engine.sample(10, seated: true);
    mono.advance(const Duration(seconds: 1));
    engine.sample(11, seated: false);
    mono.advance(const Duration(seconds: 59));
    engine.sample(70, seated: false);
    expect(controller.currentKind, SegmentKind.seated);
    mono.advance(const Duration(seconds: 1));
    engine.sample(71, seated: false);
    expect(controller.currentKind, SegmentKind.away);
    expect(controller.seated.inSeconds, 10);
    mono.advance(const Duration(seconds: 240));
    engine.sample(311, seated: false);
    expect(controller.longAway, isTrue);
    mono.advance(const Duration(seconds: 1));
    engine.sample(312, seated: true);
    expect(controller.currentKind, SegmentKind.seated);
    expect(controller.longAway, isFalse);
    expect(
      controller.segments[1].startAt,
      kT0.add(const Duration(seconds: 10)),
    );
  });

  test('lost pauses, failed reconnect stays paused, manual continuation keeps both kinds', () async {
    await controller.start(mode: SessionMode.camera);
    mono.advance(const Duration(seconds: 20));
    engine.sample(20, seated: true);
    engine.eventBus.add(const SeatCameraLost());
    await flush();
    expect(controller.cameraLost, isTrue);
    expect(controller.paused, isTrue);
    mono.advance(const Duration(seconds: 30));
    engine.sample(50, seated: true);
    expect(controller.seated.inSeconds, 20);
    engine.availability = SeatAvailability.cameraBusy;
    await controller.resume();
    expect(controller.reconnectFailed, isTrue);
    await controller.resume(manual: true);
    mono.advance(const Duration(seconds: 10));
    expect(controller.seated.inSeconds, 30);
    expect(controller.mode, SessionMode.manual);
    await controller.finish();
    await controller.save();
    expect(
      (await h.sessions.getSegments(controller.sessionId!)).map((s) => s.kind),
      [SegmentKind.seated, SegmentKind.paused, SegmentKind.manual],
    );
  });

  test('background releases camera, repeated lifecycle notifications preserve automatic resume', () async {
    await controller.start(mode: SessionMode.camera);
    mono.advance(const Duration(seconds: 20));
    await controller.background();
    await controller.background();
    expect(device.awake, isFalse);
    expect(controller.paused, isTrue);
    mono.advance(const Duration(minutes: 1));
    await controller.foreground();
    expect(controller.paused, isFalse);
    expect(engine.starts, 2);
    mono.advance(const Duration(seconds: 10));
    expect(controller.seated.inSeconds, 30);
    await controller.pause();
    await controller.background();
    await controller.foreground();
    expect(
      controller.paused,
      isTrue,
      reason: 'explicit user pause must survive foreground',
    );
  });

  test('background while camera opens invalidates that run and releases after open', () async {
    engine.starting = Completer<void>();
    final start = controller.start(mode: SessionMode.camera);
    await flush();
    final background = controller.background();
    engine.starting!.complete();
    await start;
    await background;
    expect(controller.paused, isTrue);
    expect(device.awake, isFalse);
    mono.advance(const Duration(seconds: 20));
    engine.sample(20, seated: true);
    expect(controller.seated, Duration.zero);
  });

  test('20 percent battery restarts once with lowPower and stale samples cannot unpause', () async {
    await controller.start(mode: SessionMode.camera);
    device.level = 20;
    await controller.checkBattery();
    expect(engine.starts, 2);
    expect(engine.config!.lowPower, isTrue);
    await controller.checkBattery();
    expect(engine.starts, 2);
    await controller.pause();
    engine.sample(100, seated: true);
    expect(controller.paused, isTrue);
  });

  test('15 ticks overwrite a snapshot rather than append', () async {
    await controller.start(mode: SessionMode.manual);
    for (var i = 0; i < 30; i++) {
      mono.advance(const Duration(seconds: 1));
      controller.tick();
    }
    await flush();
    final snapshot = await h.sessions.readSnapshot();
    expect(snapshot!.savedAt, kT0.add(const Duration(seconds: 30)));
    expect((await h.db.select(h.db.sessionSnapshots).get()).length, 1);
  });

  for (final kind in SegmentKind.values) {
    test('recovery $kind stops at savedAt, save remains interrupted', () async {
      final snapshot = SessionSnapshot(
        sessionId: 'recovery',
        mode: kind == SegmentKind.manual
            ? SessionMode.manual
            : SessionMode.camera,
        kind: SessionKind.self,
        startedAt: kT0,
        segments: [],
        openKind: kind,
        openStart: kT0,
        savedAt: kT0.add(const Duration(seconds: 45)),
        sensitivity: 0,
      );
      await h.sessions.startActive(snapshot);
      h.clock.advance(const Duration(hours: 4));
      await controller.recover('recovery', continueSession: false);
      expect(controller.seated.inSeconds, kind.countsAsSeated ? 45 : 0);
      expect(await controller.save(), isTrue);
      final row = await h.sessions.get('recovery');
      expect(row!.endedAt, snapshot.savedAt);
      expect(row.status, SessionStatus.interrupted);
    });
  }

  test(
    'candidate recovery removes unconfirmed time and resumed gap stays paused',
    () async {
      await h.sessions.startActive(
        SessionSnapshot(
          sessionId: 'candidate',
          mode: SessionMode.camera,
          kind: SessionKind.self,
          startedAt: kT0,
          segments: [],
          openKind: SegmentKind.seated,
          openStart: kT0,
          savedAt: kT0.add(const Duration(seconds: 40)),
          sensitivity: 0,
          lastSeatedAt: kT0.add(const Duration(seconds: 10)),
          awayCandidateSince: kT0.add(const Duration(seconds: 11)),
        ),
      );
      h.clock.advance(const Duration(hours: 1));
      await controller.recover(
        'candidate',
        continueSession: true,
        manual: true,
      );
      mono.advance(const Duration(seconds: 20));
      expect(controller.seated.inSeconds, 30);
      expect(controller.segments.map((s) => s.kind), [
        SegmentKind.seated,
        SegmentKind.away,
        SegmentKind.paused,
        SegmentKind.manual,
      ]);
      await controller.finish();
      expect(await controller.save(), isTrue);
      expect(
        (await h.sessions.get('candidate'))!.status,
        SessionStatus.interrupted,
      );
    },
  );

  test('missing snapshot recovers zero time and discard removes snapshot and live row', () async {
    await controller.start(mode: SessionMode.manual);
    final id = controller.sessionId!;
    controller.dispose();
    await flush();
    await h.sessions.clearSnapshot();
    controller = makeController();
    h.clock.advance(const Duration(hours: 2));
    await controller.recover(id, continueSession: false);
    expect(controller.seated, Duration.zero);
    await controller.discard();
    expect(await h.sessions.readSnapshot(), isNull);
    expect(await h.sessions.get(id), isNull);
  });

  test('foreground after background realigns the clock: the sleep gap is paused, later segments keep wall time', () async {
    await controller.start(mode: SessionMode.manual);
    mono.advance(const Duration(seconds: 10));
    await controller.background();
    expect(controller.paused, isTrue);
    // The device slept: the wall clock moved 30 minutes, the monotonic clock
    // (frozen during sleep) only 60 seconds.
    h.clock.advance(const Duration(minutes: 30));
    mono.advance(const Duration(seconds: 60));
    await controller.foreground();
    expect(controller.paused, isFalse);
    mono.advance(const Duration(seconds: 20));
    final segments = controller.segments;
    expect(segments.map((s) => s.kind), [
      SegmentKind.manual,
      SegmentKind.paused,
      SegmentKind.manual,
    ]);
    expect(segments[1].startAt, kT0.add(const Duration(seconds: 10)));
    expect(segments[1].endAt, kT0.add(const Duration(minutes: 30)));
    expect(segments[2].startAt, kT0.add(const Duration(minutes: 30)));
    expect(controller.seated.inSeconds, 30);
    await controller.finish();
    expect(await controller.save(), isTrue);
    final row = await h.sessions.get(controller.sessionId!);
    expect(row!.endedAt, kT0.add(const Duration(minutes: 30, seconds: 20)));
  });

  test('a wall clock set back while in background is ignored (D23: never backwards)', () async {
    await controller.start(mode: SessionMode.manual);
    mono.advance(const Duration(seconds: 10));
    await controller.background();
    h.clock.jumpTo(kT0.subtract(const Duration(hours: 1)));
    mono.advance(const Duration(seconds: 5));
    await controller.foreground();
    mono.advance(const Duration(seconds: 5));
    final last = controller.segments.last;
    expect(last.kind, SegmentKind.manual);
    expect(last.startAt, kT0.add(const Duration(seconds: 15)));
  });

  test('resume interrupted by background is honoured on foreground', () async {
    await controller.start(mode: SessionMode.manual);
    await controller.pause();
    final resume = controller.resume();
    final background = controller.background();
    await resume;
    await background;
    expect(controller.paused, isTrue);
    await controller.foreground();
    expect(controller.paused, isFalse, reason: 'the user asked to resume');
  });

  test('todayTotal adds today\'s saved 순공 before the session (daily goal ring)', () async {
    await controller.start(mode: SessionMode.manual);
    mono.advance(const Duration(minutes: 10));
    await controller.finish();
    expect(await controller.save(), isTrue);
    controller.resetSaved();
    h.clock.advance(const Duration(hours: 1));
    await controller.start(mode: SessionMode.manual);
    mono.advance(const Duration(minutes: 5));
    expect(controller.seated.inMinutes, 5);
    expect(controller.todayTotal.inMinutes, 15);
  });

  test('recover and discard refuse to run over a live measurement', () async {
    await controller.start(mode: SessionMode.manual);
    expect(
      () => controller.recover('other', continueSession: false),
      throwsStateError,
    );
    expect(controller.isLive, isTrue);
  });

  test('save, corrections, sensitivity and linked task are one transaction; retry preserves draft', () async {
    final task = await h.planner.createItem(
      kind: PlannerKind.todo,
      title: 'task',
      date: LocalDate.of(kT0),
    );
    final segments = <Segment>[];
    for (var i = 0; i < 3; i++) {
      segments.add(
        Segment(
          id: 'away-$i',
          kind: SegmentKind.away,
          startAt: kT0.add(Duration(minutes: i)),
          endAt: kT0.add(Duration(minutes: i + 1)),
        ),
      );
    }
    await h.sessions.startActive(
      SessionSnapshot(
        sessionId: 'correct',
        mode: SessionMode.camera,
        kind: SessionKind.todo,
        plannerItemId: task.id,
        startedAt: kT0,
        segments: segments,
        openKind: SegmentKind.paused,
        openStart: kT0.add(const Duration(minutes: 3)),
        savedAt: kT0.add(const Duration(minutes: 3)),
        sensitivity: 0,
      ),
    );
    await controller.recover('correct', continueSession: false);
    for (final s in segments) {
      controller.correct(s.id);
    }
    controller.completeTask = true;
    await h.db.customStatement(
      "CREATE TRIGGER fail_task BEFORE UPDATE ON planner_items BEGIN SELECT RAISE(ABORT, 'test failure'); END",
    );
    expect(await controller.save(), isFalse);
    expect(controller.saveState, isA<MeasureSaveFailed>());
    expect(controller.correctedIds.length, 3);
    expect(await h.sessions.readSnapshot(), isNotNull);
    expect(await h.sessions.getSegments('correct'), isEmpty);
    expect(await h.sessions.correctionsSince(kT0), isEmpty);
    expect((await h.settings.get()).sensitivityLevel, 0);
    await h.db.customStatement('DROP TRIGGER fail_task');
    expect(await controller.save(), isTrue);
    expect((await h.sessions.get('correct'))!.seatedSeconds, 180);
    expect((await h.settings.get()).sensitivityLevel, 1);
    expect((await h.planner.getItem(task.id))!.isDone, isTrue);
    expect((await h.sessions.correctionsSince(kT0)).length, 3);
    expect(await h.sessions.readSnapshot(), isNull);
  });
}
