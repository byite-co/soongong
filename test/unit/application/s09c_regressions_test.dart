// S09c regressions (GPT independent re-review of PR #8 at S09b head
// `6beffaa`): P1-1 a same-account write parked behind 모든 기록 삭제 lands
// again under the new epoch (and the barrier applies to subjects and a new
// measurement, while resolving the recovered session stays possible);
// P1-2 a row-less camera cache file survives 로그아웃 · 계정 삭제 · 모든 기록
// 삭제; P1-3 a local purge blocked by a measurement is never retried once
// the measurement is resolved, and a server purge whose marker write was
// refused by a sign-out is lost on re-login. Each `repro` test failed before
// the S09c fix; the `control` tests passed before and must keep passing.

import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:soongong/core/domain/clock.dart';
import 'package:soongong/core/domain/enums.dart';
import 'package:soongong/data/auth/auth_gate.dart';
import 'package:soongong/data/auth/auth_mode.dart';
import 'package:soongong/data/auth/auth_models.dart';
import 'package:soongong/data/photos/photo_store.dart';
import 'package:soongong/data/repositories/local_purge.dart';
import 'package:soongong/data/repositories/repositories.dart';
import 'package:soongong/data/startup/startup_tasks.dart';
import 'package:soongong/features/measure/application/measure_controller.dart';
import 'package:soongong/features/measure/domain/segment.dart';
import 'package:soongong/features/measure/domain/session_snapshot.dart';
import 'package:soongong/features/privacy/application/photo_retention.dart';
import 'package:soongong/features/privacy/application/privacy_providers.dart';
import 'package:soongong/features/privacy/application/purge_recovery.dart';
import 'package:soongong/features/settings/application/account_controller.dart';
import 'package:soongong/features/settings/application/settings_providers.dart';
import 'package:soongong/features/subjects/application/subjects_controller.dart';
import 'package:soongong/features/subjects/domain/subject_draft.dart';

import '../../helpers/app_harness.dart';
import '../../helpers/fake_auth_backend.dart';
import '../../helpers/fake_photo_store.dart';
import '../../helpers/measure_fakes.dart';

const AuthSession kU1 = AuthSession(userId: 'u-1', email: 'a@x.io');
const AuthSession kU2 = AuthSession(userId: 'u-2', email: 'b@x.io');

SessionSnapshot snapshotOf(String id, DateTime at) => SessionSnapshot(
      sessionId: id,
      mode: SessionMode.manual,
      kind: SessionKind.self,
      startedAt: at,
      segments: const <Segment>[],
      openKind: SegmentKind.manual,
      openStart: at,
      savedAt: at,
      sensitivity: 0,
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late AppHarness h;

  tearDown(() => h.dispose());

  Future<int> count(String sql) async => (await h.db.customSelect(sql).getSingle()).read<int>('n');
  Future<int> rows(String table, String userId) => count("SELECT COUNT(*) AS n FROM $table WHERE user_id = '$userId'");

  Future<void> localOnly({PhotoStoreFactory? store}) async {
    h = AppHarness(mode: AuthMode.localOnly, photoStore: store?.call());
    h.container.listen(authGateProvider, (_, _) {});
    await h.settle();
  }

  Future<void> signedIn(FakeAuthBackend backend, {PhotoStoreFactory? store}) async {
    h = AppHarness(backend: backend, photoStore: store?.call());
    h.container.listen(authGateProvider, (_, _) {});
    await h.settle(40);
    expect(h.container.read(currentUserIdProvider), 'u-1');
  }

  Future<void> switchToU2(FakeAuthBackend backend) async {
    backend.profileRow = <String, dynamic>{...kProfileRowOnboardingDone, 'user_id': 'u-2'};
    backend.emitSession(kU2);
    await h.settle(60);
    expect(h.container.read(currentUserIdProvider), 'u-2');
  }

  Future<void> seedPhoto(String rel) async {
    await h.container.read(readingRepositoryProvider).addPhoto(localPath: rel, takenAt: kHarnessNow, width: 1, height: 1, pageIndex: 0);
    await h.writePhoto(rel);
  }

  bool fileExists(String rel) => File('${h.photoDir.path}/$rel').existsSync();

  group('P1-1 purge generation barrier', () {
    test('repro: a settings write parked behind the delete-all lock is refused (theme stays system); a write started afterwards lands', () async {
      late GatedPhotoStore store;
      await localOnly(store: () => store = GatedPhotoStore(() async => h.photoDir));
      final controller = h.container.read(settingsControllerProvider);
      final settingsRepo = h.container.read(settingsRepositoryProvider);
      await seedPhoto('p/1.jpg');
      final gate = store.hold('p/1.jpg');

      final deleting = h.container.read(privacyActionsProvider).deleteAll();
      await gate.entered; // the wipe runs inside the owned transaction → lock held
      final parked = controller.setTheme(ThemeSetting.dark); // queued behind the lock
      await h.settle();
      gate.release();

      expect(await deleting, isA<DeleteAllDone>());
      expect(await parked, isFalse, reason: 'a write of the generation before the purge must not land');
      expect((await settingsRepo.get()).theme, ThemeSetting.system);
      expect(await count("SELECT COUNT(*) AS n FROM settings WHERE key = 'theme'"), 0, reason: 'no theme row re-created under the new epoch');

      // control: a write the user starts after the purge completed is allowed
      expect(await controller.setTheme(ThemeSetting.dark), isTrue);
      expect((await settingsRepo.get()).theme, ThemeSetting.dark);
      expect(await h.container.read(syncWriterProvider).purgeEpoch(), 1);
    });

    test('repro: a subject save parked behind the delete-all lock is refused; a later save lands', () async {
      late GatedPhotoStore store;
      await localOnly(store: () => store = GatedPhotoStore(() async => h.photoDir));
      final subjects = h.container.read(subjectRepositoryProvider);
      final c = h.container.read(subjectsControllerProvider);
      await subjects.create(name: '수학', colorIndex: 0);
      await seedPhoto('p/1.jpg');
      final gate = store.hold('p/1.jpg');

      final deleting = h.container.read(privacyActionsProvider).deleteAll();
      await gate.entered;
      final parked = c.save(const SubjectDraft(name: '영어', colorIndex: 1));
      await h.settle();
      gate.release();

      expect(await deleting, isA<DeleteAllDone>());
      expect(await parked, isA<SubjectSaveFailed>());
      expect((await subjects.getAll()).map((s) => s.isDefault), <bool>[true], reason: 'only 기타 after the purge');

      expect(await c.save(const SubjectDraft(name: '영어', colorIndex: 1)), isA<SubjectSaved>());
      expect((await subjects.getAll()).length, 2);
    });

    test('repro: while a local purge is pending a new measurement cannot start; discarding the recovered session is still allowed', () async {
      await localOnly();
      final sessions = h.container.read(sessionRepositoryProvider);
      final purge = h.container.read(localPurgeProvider);
      final engine = TestMeasureEngine();
      final controller = MeasureController(
        engine: engine,
        sessions: sessions,
        settings: h.container.read(settingsRepositoryProvider),
        planner: h.container.read(plannerRepositoryProvider),
        wall: h.clock,
        monotonic: FakeMonotonicClock(),
        device: TestMeasureDevice(),
        automaticTicks: false,
      );
      addTearDown(() async {
        controller.dispose();
        await h.settle();
        await engine.close();
      });

      await purge.markPending(9); // server purged · local steps not finished
      expect(await controller.start(mode: SessionMode.manual), isFalse, reason: 'no new record while the purge is pending');
      expect(await rows('sessions', 'local'), 0);

      await sessions.writeSnapshot(snapshotOf('live', kHarnessNow));
      await controller.discard('live');
      expect(await sessions.readSnapshot(), isNull, reason: 'the recovery path (discard) resolves the snapshot during the pending purge');
    });
  });

  group('P1-2 row-less photo files', () {
    test('repro: logout removes a fresh camera cache file that has no row', () async {
      await signedIn(FakeAuthBackend(session: kU1, profileRow: kProfileRowOnboardingDone));
      await h.writePhoto('cache/recent-camera.jpg');
      await h.container.read(accountControllerProvider).logout();
      expect(h.backend.callNames, contains('signOut'));
      expect(fileExists('cache/recent-camera.jpg'), isFalse);
    });

    test('repro: account deletion removes a fresh camera cache file that has no row', () async {
      await signedIn(FakeAuthBackend(session: kU1, profileRow: kProfileRowOnboardingDone));
      await h.writePhoto('cache/recent-camera.jpg');
      await h.container.read(accountControllerProvider).deleteAccount();
      expect(h.backend.callNames, containsAllInOrder(<String>['delete-account', 'signOut']));
      expect(fileExists('cache/recent-camera.jpg'), isFalse);
    });

    test('repro: 모든 기록 삭제 removes a fresh camera cache file that has no row (and derived files · an old cache file)', () async {
      await localOnly();
      await seedPhoto('p/1.jpg');
      await h.writePhoto('p/1.compressed.jpg');
      await h.writePhoto('cache/recent-camera.jpg');
      final old = await h.writePhoto('cache/old.jpg');
      old.setLastModifiedSync(kHarnessNow.subtract(const Duration(days: 2)));
      expect(await h.container.read(privacyActionsProvider).deleteAll(), isA<DeleteAllDone>());
      expect(h.photoDir.listSync(recursive: true).whereType<File>(), isEmpty, reason: 'every file under the store is gone');
    });

    test('repro: a cache file that cannot be deleted is a partial result, not success; the retry at the next start removes it', () async {
      late FailingPhotoStore store;
      await localOnly(store: () => store = FailingPhotoStore(() async => h.photoDir, failing: <String>{'cache/stuck.jpg'}));
      await seedPhoto('p/1.jpg');
      await h.writePhoto('cache/stuck.jpg');
      final outcome = await h.container.read(privacyActionsProvider).deleteAll();
      expect(outcome, isA<DeleteAllPartial>(), reason: 'a row-less file that stayed behind is reported');
      expect((outcome as DeleteAllPartial).failedPhotos, 1);
      expect(fileExists('cache/stuck.jpg'), isTrue);
      expect(fileExists('p/1.jpg'), isFalse);

      store.failing.clear();
      await h.container.read(photoRetentionProvider).purgeExpired(); // app start · foreground
      expect(fileExists('cache/stuck.jpg'), isFalse, reason: 'the retry sweeps what the wipe could not delete');
    });

    test('repro: logout with an undeletable cache file does not sign out', () async {
      await signedIn(
        FakeAuthBackend(session: kU1, profileRow: kProfileRowOnboardingDone),
        store: () => FailingPhotoStore(() async => h.photoDir, failing: <String>{'cache/stuck.jpg'}),
      );
      await h.writePhoto('cache/stuck.jpg');
      await expectLater(h.container.read(accountControllerProvider).logout(), throwsA(isA<PhotoWipeFailed>()));
      expect(h.backend.callNames, isNot(contains('signOut')));
    });

    test('control: a wipe interrupted by an account switch never deletes the next account\'s photo', () async {
      late GatedPhotoStore store;
      final backend = FakeAuthBackend(session: kU1, profileRow: kProfileRowOnboardingDone);
      await signedIn(backend, store: () => store = GatedPhotoStore(() async => h.photoDir));
      await seedPhoto('q/1.jpg');
      final gate = store.hold('q/1.jpg');
      final logout = h.container.read(accountControllerProvider).logout();
      await gate.entered;

      await switchToU2(backend);
      await seedPhoto('r/2.jpg');
      gate.release();
      await logout.then((_) {}, onError: (_) {});
      await h.settle();
      expect(fileExists('r/2.jpg'), isTrue, reason: 'u-2 keeps its photo');
      expect(await rows('photos', 'u-2'), 1);
    });
  });

  group('P1-3 pending purge recovery', () {
    Future<void> seedRestartState({required bool withSnapshot}) async {
      h = AppHarness(mode: AuthMode.localOnly);
      final seed = AppHarness(mode: AuthMode.localOnly, db: h.db);
      seed.container.listen(authGateProvider, (_, _) {});
      await seed.settle();
      await seed.container.read(subjectRepositoryProvider).create(name: '수학', colorIndex: 0);
      if (withSnapshot) await seed.container.read(sessionRepositoryProvider).writeSnapshot(snapshotOf('live', kHarnessNow));
      await seed.container.read(localPurgeProvider).markPending(9);
      seed.container.dispose();
      h.container.listen(authGateProvider, (_, _) {});
      await h.settle();
    }

    test('repro 1: a pending purge blocked by a snapshot completes once the measurement is resolved — same app run, no restart', () async {
      await seedRestartState(withSnapshot: true);
      final startup = h.container.read(userStartupTasksProvider);
      final purge = h.container.read(localPurgeProvider);
      final subjects = h.container.read(subjectRepositoryProvider);

      await startup.ensureRunFor('local');
      await h.settle(40);
      expect(await purge.pendingEpoch(), 9, reason: 'blocked by the measurement');
      expect((await subjects.getAll()).map((s) => s.name), contains('수학'));

      await h.container.read(sessionRepositoryProvider).clearSnapshot(); // 마무리 / 버리기
      await h.settle(60);
      await startup.ensureRunFor('local');
      await h.settle(60);

      expect(await purge.pendingEpoch(), isNull, reason: 'the local purge continued after the snapshot was resolved');
      expect((await subjects.getAll()).map((s) => s.isDefault), <bool>[true]);
      expect(await h.container.read(syncWriterProvider).purgeEpoch(), 9);
    });

    test('control: a pending purge without a snapshot completes at start', () async {
      await seedRestartState(withSnapshot: false);
      await h.container.read(userStartupTasksProvider).ensureRunFor('local');
      await h.settle(40);
      expect(await h.container.read(localPurgeProvider).pendingEpoch(), isNull);
      expect((await h.container.read(subjectRepositoryProvider).getAll()).map((s) => s.isDefault), <bool>[true]);
    });

    test('repro 2: a purge-all success whose marker write was refused by a sign-out converges when the same account signs in again', () async {
      final backend = GatedAuthBackend(session: kU1, profileRow: kProfileRowOnboardingDone);
      await signedIn(backend);
      final subjects = h.container.read(subjectRepositoryProvider);
      await subjects.create(name: '수학', colorIndex: 0);
      final gate = backend.hold('purge-all');
      final pending = h.container.read(privacyActionsProvider).deleteAll();
      await h.settle();
      expect(backend.callNames, contains('purge-all'));

      // another transaction holds the lock while the response arrives
      final entered = Completer<void>();
      final release = Completer<void>();
      final holding = h.container.read(syncWriterProvider).runInTransaction(() async {
        entered.complete();
        await release.future;
      });
      await entered.future;
      gate.complete(<String, dynamic>{'epoch': 9});
      await h.settle();

      backend.emitSession(null); // session dropped → the u-1 actions are disposed
      await h.settle(40);
      release.complete();
      await holding;
      expect(await pending, isA<DeleteAllFailed>(), reason: 'the marker write was refused after the dispose');

      // u-1 signs in again; the server profile carries the new epoch
      backend.profileRow = <String, dynamic>{...kProfileRowOnboardingDone, 'purge_epoch': 9};
      backend.emitSession(kU1);
      await h.settle(60);
      expect(h.container.read(currentUserIdProvider), 'u-1');
      await h.container.read(userStartupTasksProvider).ensureRunFor('u-1');
      await h.settle(60);

      expect((await h.container.read(subjectRepositoryProvider).getAll()).map((s) => s.name), isNot(contains('수학')), reason: 'rows the server already purged do not survive on the device');
      expect(await h.container.read(syncWriterProvider).purgeEpoch(), 9);
      expect(await h.container.read(localPurgeProvider).pendingEpoch(), isNull);
    });

    test('request stage: purge-all throws and the profile is unreadable → unconfirmed, writes refused; the profile (epoch unchanged) clears it and writes resume', () async {
      final backend = FakeAuthBackend(session: kU1, profileRow: kProfileRowOnboardingDone);
      await signedIn(backend);
      final settings = h.container.read(settingsControllerProvider);
      backend.responses['purge-all'] = Exception('offline');
      backend.profileError = Exception('offline');
      expect(await h.container.read(privacyActionsProvider).deleteAll(), isA<DeleteAllUnconfirmed>());
      expect((await h.container.read(localPurgeProvider).state()).stage, PurgeStage.requested);
      expect(await settings.setTheme(ThemeSetting.dark), isFalse, reason: 'nothing is written until the server answers');

      backend.profileError = null; // reachable again · purge_epoch 0 == local 0 → the call never purged
      expect(await h.container.read(purgeRecoveryProvider).resume(), isNull);
      expect((await h.container.read(localPurgeProvider).state()).stage, PurgeStage.none);
      expect(await settings.setTheme(ThemeSetting.dark), isTrue);
      expect(backend.callNames.where((n) => n == 'purge-all').length, 1, reason: 'the server purge is not retried by the recovery');
    });

    test('request stage: purge-all throws but the server profile already carries the new epoch → completed from the profile, no second purge-all', () async {
      final backend = FakeAuthBackend(session: kU1, profileRow: kProfileRowOnboardingDone);
      await signedIn(backend);
      await h.container.read(subjectRepositoryProvider).create(name: '수학', colorIndex: 0);
      backend.responses['purge-all'] = Exception('timeout after the server processed');
      backend.profileRow = <String, dynamic>{...kProfileRowOnboardingDone, 'purge_epoch': 3};
      expect(await h.container.read(privacyActionsProvider).deleteAll(), isA<DeleteAllDone>());
      expect(await h.container.read(syncWriterProvider).purgeEpoch(), 3);
      expect((await h.container.read(subjectRepositoryProvider).getAll()).map((s) => s.isDefault), <bool>[true]);
      expect(backend.callNames.where((n) => n == 'purge-all').length, 1);
    });

    test('snapshot trigger: with PurgeRecovery started, clearing the snapshot completes the pending purge; the resolved session (new epoch) survives, old rows go', () async {
      await localOnly();
      final sessions = h.container.read(sessionRepositoryProvider);
      final subjects = h.container.read(subjectRepositoryProvider);
      final old = await subjects.create(name: '수학', colorIndex: 0);
      await sessions.writeSnapshot(snapshotOf('live', kHarnessNow));
      await h.container.read(localPurgeProvider).markPending(9);
      final recovery = h.container.read(purgeRecoveryProvider)..start();
      expect(await recovery.resume(), isA<DeleteAllBlocked>());
      expect(h.container.read(purgeRecoveryStatusProvider), isA<PurgeRecoveryBlocked>());

      // 여기까지 기록 마무리: the recovered session is saved (new generation) and the snapshot goes
      final engine = TestMeasureEngine();
      final controller = MeasureController(
        engine: engine,
        sessions: sessions,
        settings: h.container.read(settingsRepositoryProvider),
        planner: h.container.read(plannerRepositoryProvider),
        wall: h.clock,
        monotonic: FakeMonotonicClock(),
        device: TestMeasureDevice(),
        automaticTicks: false,
      );
      addTearDown(() async {
        controller.dispose();
        await h.settle();
        await engine.close();
      });
      await controller.recover('live', continueSession: false);
      expect(await controller.save(), isTrue, reason: 'resolving the measurement is allowed during the pending purge');
      await h.settle(60);

      expect(h.container.read(purgeRecoveryStatusProvider), isA<PurgeRecoveryIdle>());
      expect(await h.container.read(localPurgeProvider).pendingEpoch(), isNull);
      expect(await subjects.get(old.id), isNull, reason: 'old generation purged');
      final kept = await sessions.getAll();
      expect(kept.map((s) => s.id), <String>['live'], reason: 'the session finished after the server purge carries the new epoch and stays');
      expect(kept.single.stamp.purgeEpoch, 9);
    });

    test('control: a purge left pending by a kill after the marker completes at the next start (N16)', () async {
      await seedRestartState(withSnapshot: false);
      await h.container.read(userStartupTasksProvider).ensureRunFor('local');
      await h.settle(40);
      expect(await h.container.read(localPurgeProvider).pendingEpoch(), isNull);
      expect(await rows('subjects', 'local'), 1);
    });
  });
}

typedef PhotoStoreFactory = PhotoStore Function();
