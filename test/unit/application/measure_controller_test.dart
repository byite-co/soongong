import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:soongong/core/contracts/seat_engine.dart';
import 'package:soongong/core/domain/clock.dart';
import 'package:soongong/core/domain/entities/entities.dart';
import 'package:soongong/core/domain/enums.dart';
import 'package:soongong/core/domain/local_date.dart';
import 'package:soongong/data/db/app_database.dart';
import 'package:soongong/data/repositories/settings_repository.dart';
import 'package:soongong/data/repositories/sync_writer.dart';
import 'package:soongong/features/home/domain/home_summary.dart';
import 'package:soongong/features/home/domain/streak_calculator.dart';
import 'package:soongong/features/measure/application/measure_controller.dart';
import 'package:soongong/features/measure/domain/segment.dart';
import 'package:soongong/features/measure/domain/session_snapshot.dart';

import '../../helpers/measure_fakes.dart';
import '../data/db_test_helpers.dart';

/// Lets a test park `start()` right after its reads (snapshot · settings)
/// and before its first write, to interleave an account switch.
class _GatedSettings extends SettingsRepository {
  _GatedSettings(super.db, super.writer);
  Completer<void>? gate;
  @override
  Future<AppSettings> get() async {
    final v = await super.get();
    final g = gate;
    if (g != null) await g.future;
    return v;
  }
}

Future<void> _bindDatabaseTo(TestHarness h, String userId) => h.db
    .into(h.db.syncMeta)
    .insertOnConflictUpdate(
      SyncMetaCompanion.insert(key: SyncWriter.accountUserIdKey, value: userId),
    );

void main() {
  late TestHarness h;
  late FakeMonotonicClock mono;
  late TestMeasureEngine engine;
  late TestMeasureDevice device;
  late FakeSleepAwareClock sleepAware;
  late MeasureController controller;
  MeasureController makeController() => MeasureController(
    engine: engine,
    sessions: h.sessions,
    settings: h.settings,
    planner: h.planner,
    wall: h.clock,
    monotonic: mono,
    device: device,
    sleepAware: sleepAware,
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
    sleepAware = FakeSleepAwareClock();
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

  test('device sleep in background: the sleep-aware clock extends the paused gap, later segments keep their true time', () async {
    await controller.start(mode: SessionMode.manual);
    mono.advance(const Duration(seconds: 10));
    await controller.background();
    expect(controller.paused, isTrue);
    // The device slept 29 minutes: the sleep-aware clock counted 30 minutes,
    // the Stopwatch (frozen during sleep) only 60 seconds. The wall clock is
    // left untouched on purpose — it plays no part (D23).
    sleepAware.advance(const Duration(minutes: 30));
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
    expect(segments[1].endAt, kT0.add(const Duration(minutes: 30, seconds: 10)));
    expect(segments[2].startAt, kT0.add(const Duration(minutes: 30, seconds: 10)));
    expect(controller.seated.inSeconds, 30);
    await controller.finish();
    expect(await controller.save(), isTrue);
    final row = await h.sessions.get(controller.sessionId!);
    expect(row!.endedAt, kT0.add(const Duration(minutes: 30, seconds: 30)));
  });

  test('a device time change in background does not move anything (D23: wall clock ignored both ways)', () async {
    await controller.start(mode: SessionMode.manual);
    mono.advance(const Duration(seconds: 10));
    await controller.background();
    // User sets the clock +1 h, then −3 h; no sleep happened.
    h.clock.jumpTo(kT0.add(const Duration(hours: 1)));
    sleepAware.advance(const Duration(seconds: 5));
    mono.advance(const Duration(seconds: 5));
    await controller.foreground();
    mono.advance(const Duration(seconds: 5));
    expect(controller.segments.last.kind, SegmentKind.manual);
    expect(controller.segments.last.startAt, kT0.add(const Duration(seconds: 15)));
    await controller.background();
    h.clock.jumpTo(kT0.subtract(const Duration(hours: 2)));
    sleepAware.advance(const Duration(seconds: 5));
    mono.advance(const Duration(seconds: 5));
    await controller.foreground();
    mono.advance(const Duration(seconds: 5));
    expect(controller.segments.last.startAt, kT0.add(const Duration(seconds: 25)));
  });

  test('without a platform answer the session clock is left alone', () async {
    sleepAware.elapsed = null;
    await controller.start(mode: SessionMode.manual);
    mono.advance(const Duration(seconds: 10));
    await controller.background();
    mono.advance(const Duration(seconds: 60));
    await controller.foreground();
    mono.advance(const Duration(seconds: 5));
    expect(controller.segments.last.startAt, kT0.add(const Duration(seconds: 70)));
  });

  test('dispose (account switch) during a pending save: nothing is written, the save reports failure', () async {
    await controller.start(mode: SessionMode.manual);
    final id = controller.sessionId!;
    mono.advance(const Duration(minutes: 5));
    await controller.finish();
    final entered = Completer<void>();
    final release = Completer<void>();
    final blocker = h.writer.runInTransaction(() async {
      entered.complete();
      await release.future;
    });
    await entered.future;
    final saving = controller.save();
    controller.dispose(); // Riverpod rebuilt the provider for another account
    release.complete();
    await blocker;
    expect(await saving, isFalse);
    final row = await h.sessions.get(id);
    expect(row!.status, SessionStatus.interrupted);
    expect(row.endedAt, isNull, reason: 'the final save never ran');
    expect(await h.sessions.getSegments(id), isEmpty);
    expect(await h.sessions.readSnapshot(), isNotNull, reason: 'the snapshot stays for recovery');
  });

  test('P1: account switch committed while start() waits for the DB lock → nothing of u1 is written', () async {
    final gated = _GatedSettings(h.db, h.writer)..gate = Completer<void>();
    controller.dispose();
    controller = MeasureController(
      engine: engine,
      sessions: h.sessions,
      settings: gated,
      planner: h.planner,
      wall: h.clock,
      monotonic: mono,
      device: device,
      sleepAware: sleepAware,
      automaticTicks: false,
    );
    // 1. start(): snapshot + settings reads complete, parked before its write.
    final starting = controller.start(mode: SessionMode.manual);
    await flush();
    // 2. The account switch takes the DB: wipe + rebind to u2, commit pending.
    final entered = Completer<void>();
    final release = Completer<void>();
    final switching = h.writer.runInTransaction(() async {
      await h.db.wipeAll();
      await _bindDatabaseTo(h, 'u2');
      entered.complete();
      await release.future;
    });
    await entered.future;
    // 3. start() continues: the pre-write alive check passes, startActive
    //    queues behind the switch transaction.
    gated.gate!.complete();
    await flush();
    // 4. The old controller is disposed, then the switch commits.
    controller.dispose();
    release.complete();
    await switching;
    expect(await starting, isFalse);
    expect(await h.db.customSelect('SELECT id FROM sessions').get(), isEmpty,
        reason: 'u1 active row must not be re-created in u2\'s database');
    expect(await h.sessions.readSnapshot(), isNull);
  });

  test('P1: database already bound to another account → every write refuses even before dispose', () async {
    await controller.start(mode: SessionMode.manual);
    final id = controller.sessionId!;
    mono.advance(const Duration(seconds: 20));
    await controller.checkpoint();
    expect(controller.checkpointFailed, isFalse);
    final before = (await h.sessions.readSnapshot())!.savedAt;
    await _bindDatabaseTo(h, 'u2'); // AccountBinding.bind('u2') landed; Riverpod rebuild still pending
    mono.advance(const Duration(seconds: 20));
    await controller.checkpoint();
    expect(controller.checkpointFailed, isTrue);
    expect((await h.sessions.readSnapshot())!.savedAt, before, reason: 'snapshot not overwritten');
    await controller.finish();
    expect((await h.sessions.get(id))!.status, SessionStatus.active, reason: 'markInterrupted refused');
    expect(await controller.save(), isFalse);
    expect((await h.sessions.get(id))!.endedAt, isNull);
    await expectLater(controller.discard(id), throwsStateError);
    expect(await h.sessions.get(id), isNotNull);
    await _bindDatabaseTo(h, 'u1'); // back on the owner: writes work again
    expect(await controller.save(), isTrue);
  });

  test('P2: "수동으로 이어서" interrupted by background resumes in manual mode on foreground', () async {
    await controller.start(mode: SessionMode.camera);
    mono.advance(const Duration(seconds: 20));
    engine.sample(20, seated: true);
    engine.eventBus.add(const SeatCameraLost());
    await flush();
    expect(controller.cameraLost, isTrue);
    engine.availability = SeatAvailability.cameraBusy; // still held by another app
    final resuming = controller.resume(manual: true);
    final background = controller.background();
    await resuming;
    await background;
    expect(controller.mode, SessionMode.manual, reason: 'the decision survives the interruption');
    expect(controller.paused, isTrue);
    await controller.foreground();
    expect(controller.paused, isFalse);
    expect(controller.mode, SessionMode.manual);
    expect(controller.currentKind, SegmentKind.manual);
    expect(controller.cameraLost, isFalse);
    expect(controller.reconnectFailed, isFalse);
    expect(engine.starts, 1, reason: 'no camera restart in manual mode');
    mono.advance(const Duration(seconds: 10));
    expect(controller.seated.inSeconds, 30);
    expect((await h.sessions.readSnapshot())!.mode, SessionMode.manual);
  });

  test('P3: todayTotal counts the part after local midnight of a saved session, like the home ring', () async {
    final today = LocalDate.of(h.clock.now());
    final midnight = today.toDateTime();
    final nightStart = midnight.subtract(const Duration(minutes: 10)).toUtc();
    final nightEnd = midnight.add(const Duration(minutes: 10)).toUtc();
    await h.sessions.saveFinished(
      id: 'night',
      kind: SessionKind.self,
      mode: SessionMode.manual,
      startedAt: nightStart,
      endedAt: nightEnd,
      status: SessionStatus.finished,
      segments: [Segment(id: 'n', kind: SegmentKind.manual, startAt: nightStart, endAt: nightEnd)],
      sensitivityLevel: 0,
    );
    // Excluded like the home: a pending-delete session and an unsaved row.
    final goneStart = midnight.add(const Duration(hours: 1)).toUtc();
    await h.sessions.saveFinished(
      id: 'gone',
      kind: SessionKind.self,
      mode: SessionMode.manual,
      startedAt: goneStart,
      endedAt: goneStart.add(const Duration(hours: 1)),
      status: SessionStatus.finished,
      segments: [Segment(id: 'g', kind: SegmentKind.manual, startAt: goneStart, endAt: goneStart.add(const Duration(hours: 1)))],
      sensitivityLevel: 0,
    );
    await h.sessions.softDelete('gone');
    final openStart = midnight.add(const Duration(hours: 3)).toUtc();
    await h.sessions.startActive(
      SessionSnapshot(
        sessionId: 'open',
        mode: SessionMode.manual,
        kind: SessionKind.self,
        startedAt: openStart,
        segments: [Segment(id: 'o', kind: SegmentKind.manual, startAt: openStart, endAt: openStart.add(const Duration(hours: 1)))],
        openKind: SegmentKind.paused,
        openStart: openStart.add(const Duration(hours: 1)),
        savedAt: openStart.add(const Duration(hours: 1)),
        sensitivity: 0,
      ),
    );
    await h.sessions.markInterrupted('open');
    await h.sessions.clearSnapshot();

    expect(await controller.start(mode: SessionMode.manual), isTrue);
    expect(controller.todayTotal, const Duration(minutes: 10));

    final home = HomeSummary.build(
      today: today,
      sessions: await h.sessions.getAll(),
      segments: await h.sessions.getSegmentsOverlapping(today.addDays(-1), today),
      items: const [],
      recurrences: const [],
      subjects: const {},
      streak: StreakResult.zero,
      fallbackSubjectName: '자습',
    );
    expect(home.seatedToday, controller.todayTotal, reason: 'home and focus agree');
  });

  test('dispose before finish / discard / corrections: late calls do not write', () async {
    await controller.start(mode: SessionMode.manual);
    final id = controller.sessionId!;
    mono.advance(const Duration(minutes: 1));
    controller.dispose();
    await controller.finish();
    expect((await h.sessions.get(id))!.status, SessionStatus.active, reason: 'finish wrote nothing');
    expect(() => controller.discard(id), throwsStateError);
    expect(await h.sessions.get(id), isNotNull);
    expect(() => controller.persistCorrections(id, ['x']), throwsStateError);
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
