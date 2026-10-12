// S09b regressions (GPT independent review of PR #8): the account boundary
// of long-running deletes (A · delete-account), in-transaction ownership of
// settings writes (B), device photo deletion failures kept as a retry state
// instead of being reported as success (C · D), review reminders gated by
// the entitlement and re-planned when it changes (E · F), the 64-entry
// device cap (G), reminders only for recurrence instances (H), and the
// default subject keeping its colour (R4). Each failed before the S09b fix.

import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:soongong/core/contracts/billing_gateway.dart';
import 'package:soongong/core/contracts/fakes/fakes.dart';
import 'package:soongong/core/contracts/providers.dart';
import 'package:soongong/core/contracts/reading_engine.dart';
import 'package:soongong/core/domain/entities/entities.dart';
import 'package:soongong/core/domain/enums.dart';
import 'package:soongong/core/domain/local_date.dart';
import 'package:soongong/data/auth/account_binding.dart';
import 'package:soongong/data/auth/auth_gate.dart';
import 'package:soongong/data/auth/auth_mode.dart';
import 'package:soongong/data/auth/auth_models.dart';
import 'package:soongong/data/repositories/repositories.dart';
import 'package:soongong/features/privacy/application/photo_retention.dart';
import 'package:soongong/features/privacy/application/privacy_providers.dart';
import 'package:soongong/features/settings/application/account_controller.dart';
import 'package:soongong/features/settings/application/notification_scheduler.dart';
import 'package:soongong/features/settings/application/settings_providers.dart';
import 'package:soongong/features/settings/domain/notification_plan.dart';
import 'package:soongong/features/subjects/application/subjects_controller.dart';
import 'package:soongong/features/subjects/domain/subject_draft.dart';

import '../../helpers/app_harness.dart';
import '../../helpers/fake_auth_backend.dart';
import '../../helpers/fake_photo_store.dart';

const AuthSession kU1 = AuthSession(userId: 'u-1', email: 'a@x.io');
const AuthSession kU2 = AuthSession(userId: 'u-2', email: 'b@x.io');

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late AppHarness h;

  tearDown(() => h.dispose());

  Future<int> rows(String table, String userId) async =>
      (await h.db.customSelect("SELECT COUNT(*) AS n FROM $table WHERE user_id = '$userId'").getSingle()).read<int>('n');

  Future<void> signedIn(FakeAuthBackend backend) async {
    h = AppHarness(backend: backend);
    h.container.listen(authGateProvider, (_, _) {});
    await h.settle(40);
    expect(h.container.read(currentUserIdProvider), 'u-1');
  }

  /// Another account signs in: the gate resolves it and the binding wipes.
  Future<void> switchToU2(FakeAuthBackend backend) async {
    backend.profileRow = <String, dynamic>{...kProfileRowOnboardingDone, 'user_id': 'u-2'};
    backend.emitSession(kU2);
    await h.settle(60);
    expect(h.container.read(currentUserIdProvider), 'u-2');
    expect(await AccountBinding(h.db).current(), 'u-2');
  }

  Future<void> seedWrong() => h.container.read(wrongsRepositoryProvider).applySaved(
        requestId: 'req-1',
        subjectId: 'm',
        rangeText: 'p.1',
        items: const <WrongItemDraft>[WrongItemDraft(id: 'w1', pageIndex: 0, number: 1, mark: Mark.wrong, confidence: 0.5, userConfirmed: true)],
        entries: <ReviewEntryDraft>[ReviewEntryDraft(id: 'e1', wrongItemId: 'w1', dueAt: kHarnessNow, intervalDays: 1, consecutiveCorrect: 0)],
      );

  group('P1 account boundary', () {
    test('A: 모든 기록 삭제 started as u-1 is abandoned once u-2 is bound — u-2 rows and epoch untouched', () async {
      final backend = GatedAuthBackend(session: kU1, profileRow: kProfileRowOnboardingDone);
      await signedIn(backend);
      await h.container.read(subjectRepositoryProvider).create(name: '수학', colorIndex: 0);
      final gate = backend.hold('purge-all');
      final pending = h.container.read(privacyActionsProvider).deleteAll();
      await h.settle();
      expect(backend.callNames, contains('purge-all'));

      await switchToU2(backend);
      final subjects2 = h.container.read(subjectRepositoryProvider);
      final eng = await subjects2.create(name: '영어', colorIndex: 1);
      final epochBefore = await h.container.read(syncWriterProvider).purgeEpoch();

      gate.complete(<String, dynamic>{'epoch': 9});
      final outcome = await pending;
      expect(outcome, isA<DeleteAllFailed>(), reason: 'the u-1 operation must not complete against u-2');
      expect((await subjects2.getAll()).map((s) => s.id), contains(eng.id));
      expect(await h.container.read(syncWriterProvider).purgeEpoch(), epochBefore);
      expect(await rows('subjects', 'u-2'), 1);
    });

    test('A2: a delete-account response arriving after u-2 signed in neither signs u-2 out nor wipes its rows', () async {
      final backend = GatedAuthBackend(session: kU1, profileRow: kProfileRowOnboardingDone);
      await signedIn(backend);
      final gate = backend.hold('delete-account');
      final pending = h.container.read(accountControllerProvider).deleteAccount();
      await h.settle();
      await switchToU2(backend);
      final eng = await h.container.read(subjectRepositoryProvider).create(name: '영어', colorIndex: 1);
      final signOutsBefore = backend.callNames.where((n) => n == 'signOut').length;

      gate.complete(<String, dynamic>{});
      await pending.then((_) {}, onError: (_) {});
      await h.settle();
      expect(backend.callNames.where((n) => n == 'signOut').length, signOutsBefore, reason: 'u-2 stays signed in');
      expect(h.container.read(currentUserIdProvider), 'u-2');
      expect(await rows('subjects', 'u-2'), 1);
      expect((await h.container.read(subjectRepositoryProvider).get(eng.id))?.name, '영어');
    });

    test('B: a settings write queued behind the account-switch transaction is refused (no u-1 row, no outbox)', () async {
      final backend = FakeAuthBackend(session: kU1, profileRow: kProfileRowOnboardingDone);
      await signedIn(backend);
      final controller = h.container.read(settingsControllerProvider);
      final writer = h.container.read(syncWriterProvider);
      final entered = Completer<void>();
      final release = Completer<void>();
      final switching = writer.runInTransaction(() async {
        await h.db.wipeAll();
        await AccountBinding(h.db).bind('u-2');
        entered.complete();
        await release.future;
      });
      await entered.future;
      final write = controller.setTheme(ThemeSetting.dark); // parks behind the lock
      await h.settle();
      release.complete();
      await switching;
      expect(await write, isFalse);
      expect(await rows('settings', 'u-1'), 0);
      expect((await h.db.customSelect('SELECT COUNT(*) AS n FROM sync_outbox').getSingle()).read<int>('n'), 0);
    });
  });

  group('P1 photo deletion failure', () {
    test('C: 모든 기록 삭제 with one undeletable photo → partial outcome, the row and file stay for a retry, records gone', () async {
      h = AppHarness(mode: AuthMode.localOnly, photoStore: FailingPhotoStore(() async => h.photoDir, failing: <String>{'p/1.jpg'}));
      final reading = h.container.read(readingRepositoryProvider);
      final stuck = await reading.addPhoto(localPath: 'p/1.jpg', takenAt: kHarnessNow, width: 1, height: 1, pageIndex: 0);
      await reading.addPhoto(localPath: 'p/2.jpg', takenAt: kHarnessNow, width: 1, height: 1, pageIndex: 1);
      await h.writePhoto('p/1.jpg');
      await h.writePhoto('p/2.jpg');
      await h.container.read(subjectRepositoryProvider).create(name: '수학', colorIndex: 0);

      final outcome = await h.container.read(privacyActionsProvider).deleteAll();
      expect(outcome, isA<DeleteAllPartial>());
      expect((outcome as DeleteAllPartial).failedPhotos, 1);
      final left = await reading.getAllPhotos();
      expect(left.map((p) => p.id), [stuck.id], reason: 'the failed row keeps account + path for the retry');
      expect(File('${h.photoDir.path}/p/1.jpg').existsSync(), isTrue);
      expect(File('${h.photoDir.path}/p/2.jpg').existsSync(), isFalse);
      expect((await h.container.read(subjectRepositoryProvider).getAll()).map((s) => s.isDefault), [true]);
      expect(await h.container.read(syncWriterProvider).purgeEpoch(), 1);
    });

    test('D: logout with an undeletable photo does not sign out; the row stays for a retry', () async {
      h = AppHarness(
        backend: FakeAuthBackend(session: kU1, profileRow: kProfileRowOnboardingDone),
        photoStore: FailingPhotoStore(() async => h.photoDir, failing: <String>{'q/1.jpg'}),
      );
      h.container.listen(authGateProvider, (_, _) {});
      await h.settle(40);
      final reading = h.container.read(readingRepositoryProvider);
      await reading.addPhoto(localPath: 'q/1.jpg', takenAt: kHarnessNow, width: 1, height: 1, pageIndex: 0);
      await h.writePhoto('q/1.jpg');

      await expectLater(h.container.read(accountControllerProvider).logout(), throwsA(isA<PhotoWipeFailed>()));
      expect(h.backend.callNames, isNot(contains('signOut')));
      expect(await rows('photos', 'u-1'), 1);
      expect(File('${h.photoDir.path}/q/1.jpg').existsSync(), isTrue);
    });
  });

  group('P2 notifications', () {
    Future<void> localOnly() async {
      h = AppHarness(mode: AuthMode.localOnly);
      h.container.listen(authGateProvider, (_, _) {});
      await h.settle();
    }

    FakeBillingGateway billing() => h.container.read(billingGatewayProvider) as FakeBillingGateway;
    Iterable<int> reviewIds() => h.notifications.scheduled.map((n) => n.id).where((id) => id < NotificationPlan.eventIdBase);

    test('E: free account → no review reminders even with a due queue and a review time', () async {
      await localOnly();
      await seedWrong();
      await h.container.read(settingsRepositoryProvider).setNotifReviewTime(const LocalTime(21, 0));
      final scheduler = h.container.read(notificationSchedulerProvider)..start();
      await h.settle();
      await scheduler.reschedule();
      expect(reviewIds(), isEmpty);
    });

    test('F: premium → 7 review reminders; entitlement expires → re-planned without them (no manual call)', () async {
      await localOnly();
      await seedWrong();
      await h.container.read(settingsRepositoryProvider).setNotifReviewTime(const LocalTime(21, 0));
      billing().force(EntitlementStatus.premium);
      final scheduler = h.container.read(notificationSchedulerProvider)..start();
      await h.settle(40);
      await scheduler.reschedule();
      expect(reviewIds().length, 7);
      billing().force(EntitlementStatus.expired);
      await h.settle(60);
      expect(reviewIds(), isEmpty, reason: 'the entitlement stream is an input of the plan');
    });

    test('G: 10 daily recurrences over 7 days → at most 64 entries, the soonest kept', () async {
      await localOnly();
      final planner = h.container.read(plannerRepositoryProvider);
      for (var i = 0; i < 10; i++) {
        await planner.createRecurrence(
          title: '일정 $i',
          weekdayMask: Recurrence.maskOf(const <int>[1, 2, 3, 4, 5, 6, 7]),
          startTime: LocalTime(11 + i, 0),
          endTime: LocalTime(11 + i, 30),
        );
      }
      await h.container.read(settingsRepositoryProvider).setNotifEvent10min(on: true);
      final scheduler = h.container.read(notificationSchedulerProvider)..start();
      await h.settle(40);
      await scheduler.reschedule();
      final at = h.notifications.scheduled.map((n) => n.at).toList();
      expect(at.length, NotificationPlan.deviceLimit);
      expect(at.length, 64);
      expect(at, orderedEquals(<DateTime>[...at]..sort()));
      expect(at.last.isBefore(DateTime(2026, 10, 9, 17)), isTrue, reason: 'the latest instances of the week were dropped');
    });

    test('H: a plain planner event with a start time gets no reminder (recurrence instances only)', () async {
      await localOnly();
      final planner = h.container.read(plannerRepositoryProvider);
      await planner.createItem(kind: PlannerKind.event, title: '모의고사', date: LocalDate.of(kHarnessNow).addDays(1), startTime: const LocalTime(9, 0));
      await h.container.read(settingsRepositoryProvider).setNotifEvent10min(on: true);
      final scheduler = h.container.read(notificationSchedulerProvider)..start();
      await h.settle(40);
      await scheduler.reschedule();
      expect(h.notifications.scheduled, isEmpty);
    });
  });

  group('R4 default subject', () {
    test('the default subject keeps its colour; only the name changes', () async {
      h = AppHarness(mode: AuthMode.localOnly);
      final subjects = h.container.read(subjectRepositoryProvider);
      final def = await subjects.ensureDefault();
      final c = h.container.read(subjectsControllerProvider);
      expect(await c.save(const SubjectDraft(name: '그 외', colorIndex: 2), id: def.id), isA<SubjectSaved>());
      final row = (await subjects.get(def.id))!;
      expect(row.name, '그 외');
      expect(row.colorIndex, SubjectRepository.defaultColorIndex);
    });
  });
}
