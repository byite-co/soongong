// S09 application layer against the app harness: plan label (D18 facts),
// account facts (local-only · backend), sync/provider labels, the goal
// suggestion (D25), SettingsController writes, NotificationScheduler
// (plan → gateway, denied → cancel, settings change → re-plan),
// InquiryController (body shape · 429 · failure), PrivacyActions
// (export → share, delete-all blocked / done / server epoch) and
// AccountController (logout · delete account).

import 'package:flutter_test/flutter_test.dart';
import 'package:soongong/core/contracts/billing_gateway.dart';
import 'package:soongong/core/contracts/fakes/fakes.dart';
import 'package:soongong/core/contracts/notification_gateway.dart';
import 'package:soongong/core/contracts/providers.dart';
import 'package:soongong/core/contracts/reading_engine.dart';
import 'package:soongong/core/domain/enums.dart';
import 'package:soongong/core/domain/local_date.dart';
import 'package:soongong/core/strings/help_strings.dart';
import 'package:soongong/core/strings/settings_strings.dart';
import 'package:soongong/data/auth/auth_gate.dart';
import 'package:soongong/data/auth/auth_mode.dart';
import 'package:soongong/data/auth/auth_models.dart';
import 'package:soongong/data/export/export_service.dart';
import 'package:soongong/data/repositories/repositories.dart';
import 'package:soongong/features/help/application/inquiry_controller.dart';
import 'package:soongong/features/measure/domain/segment.dart';
import 'package:soongong/features/measure/domain/session_snapshot.dart';
import 'package:soongong/features/privacy/application/privacy_providers.dart';
import 'package:soongong/features/settings/application/account_controller.dart';
import 'package:soongong/features/settings/application/notification_scheduler.dart';
import 'package:soongong/features/settings/application/settings_providers.dart';

import '../../helpers/app_harness.dart';
import '../../helpers/fake_auth_backend.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late AppHarness h;

  setUp(() => h = AppHarness(mode: AuthMode.localOnly));
  tearDown(() => h.dispose());

  Future<void> seedSession(String id, DateTime start, Duration len) => h.container.read(sessionRepositoryProvider).saveFinished(
        id: id,
        kind: SessionKind.study,
        mode: SessionMode.manual,
        startedAt: start,
        endedAt: start.add(len),
        status: SessionStatus.finished,
        segments: <Segment>[Segment(id: '$id-seg', kind: SegmentKind.manual, startAt: start.toUtc(), endAt: start.add(len).toUtc())],
        sensitivityLevel: 0,
      );

  Future<void> seedWrong() => h.container.read(wrongsRepositoryProvider).applySaved(
        requestId: 'req-1',
        subjectId: 'm',
        rangeText: 'p.1',
        items: const <WrongItemDraft>[WrongItemDraft(id: 'w1', pageIndex: 0, number: 1, mark: Mark.wrong, confidence: 0.5, userConfirmed: true)],
        entries: <ReviewEntryDraft>[ReviewEntryDraft(id: 'e1', wrongItemId: 'w1', dueAt: kHarnessNow, intervalDays: 1, consecutiveCorrect: 0)],
      );

  group('labels', () {
    test('syncLabelOf · providerLabelOf', () {
      final now = kHarnessNow;
      expect(syncLabelOf(null, now), SettingsStrings.syncNever);
      expect(syncLabelOf(now.subtract(const Duration(seconds: 30)), now), SettingsStrings.syncJustNow);
      expect(syncLabelOf(now.subtract(const Duration(minutes: 5)), now), SettingsStrings.syncMinutesAgo(5));
      expect(syncLabelOf(now.subtract(const Duration(hours: 3)), now), SettingsStrings.syncHoursAgo(3));
      expect(syncLabelOf(now.subtract(const Duration(days: 2, hours: 1)), now), SettingsStrings.syncDaysAgo(2));
      expect(providerLabelOf('email'), SettingsStrings.providerEmail);
      expect(providerLabelOf('google'), SettingsStrings.providerGoogle);
      expect(providerLabelOf('apple'), SettingsStrings.providerApple);
      expect(providerLabelOf('kakao'), SettingsStrings.providerKakao);
      expect(providerLabelOf(null), SettingsStrings.providerUnknown);
    });

    test('planLabel follows the entitlement; expired + saved wrongs → 읽기 전용 fact (D18)', () async {
      final billing = h.container.read(billingGatewayProvider) as FakeBillingGateway;
      h.container.listen(planLabelProvider, (_, _) {});
      h.container.listen(settingsWrongsProvider, (_, _) {});
      await h.settle();
      expect(h.container.read(planLabelProvider), SettingsStrings.planFree);
      billing.force(EntitlementStatus.premium);
      await h.settle();
      expect(h.container.read(planLabelProvider), SettingsStrings.planPremium);
      billing.force(EntitlementStatus.trial);
      await h.settle();
      expect(h.container.read(planLabelProvider), SettingsStrings.planTrial);
      billing.force(EntitlementStatus.expired);
      await h.settle();
      expect(h.container.read(planLabelProvider), SettingsStrings.planFree, reason: 'no wrongs → plain free');
      await seedWrong();
      await h.settle();
      expect(h.container.read(planLabelProvider), SettingsStrings.planExpiredReadOnly(1));
    });

    test('accountInfo: local-only has no account; backend reports email · provider · sync time', () async {
      expect(h.container.read(accountInfoProvider).localOnly, isTrue);
      await h.dispose();
      h = AppHarness(
        backend: FakeAuthBackend(session: const AuthSession(userId: 'u-1', email: 'a@x.io'), profileRow: kProfileRowOnboardingDone)
          ..provider = 'google',
      );
      h.container.listen(accountInfoProvider, (_, _) {});
      await h.settle();
      final info = h.container.read(accountInfoProvider);
      expect(info.localOnly, isFalse);
      expect(info.email, 'a@x.io');
      expect(info.initial, 'A');
      expect(info.providerLabel, SettingsStrings.providerGoogle);
    });
  });

  group('goal suggestion (D25)', () {
    test('null without records; mean per recorded day over 28 days rounded to 30 min', () async {
      h.container.listen(goalSuggestionMinutesProvider, (_, _) {});
      await h.settle();
      expect(h.container.read(goalSuggestionMinutesProvider), isNull);
      await seedSession('a', DateTime(2026, 9, 20, 9), const Duration(minutes: 100));
      await seedSession('b', DateTime(2026, 9, 25, 9), const Duration(minutes: 140));
      await seedSession('old', DateTime(2026, 8, 1, 9), const Duration(hours: 9));
      await h.settle();
      expect(h.container.read(goalSuggestionMinutesProvider), 120, reason: '(100+140)/2 = 120');
      await seedSession('c', DateTime(2026, 10, 1, 9), const Duration(minutes: 10));
      await h.settle();
      expect(h.container.read(goalSuggestionMinutesProvider), 90, reason: '250/3 = 83 → 90');
    });
  });

  group('SettingsController', () {
    test('writes land in the repository; notification writes re-plan', () async {
      final c = h.container.read(settingsControllerProvider);
      final repo = h.container.read(settingsRepositoryProvider);
      expect(await c.setDailyGoal(180), isTrue);
      expect(await c.setWeekStart(DateTime.sunday), isTrue);
      expect(await c.setTheme(ThemeSetting.dark), isTrue);
      expect(await c.setSeatDetection(on: false), isTrue);
      await seedWrong();
      expect(await c.setNotifReviewTime(const LocalTime(21, 0)), isTrue);
      final s = await repo.get();
      expect(s.dailyGoalMinutes, 180);
      expect(s.weekStart, 7);
      expect(s.theme, ThemeSetting.dark);
      expect(s.seatDetectionEnabled, isFalse);
      expect(s.notifReviewTime, const LocalTime(21, 0));
      expect(h.notifications.replaceCalls, greaterThan(0));
      expect(h.notifications.scheduled.map((n) => n.id), contains(100));
    });
  });

  group('NotificationScheduler', () {
    test('start plans from the current data; a settings change re-plans; denied → cancelAll', () async {
      await seedWrong();
      await h.container.read(plannerRepositoryProvider).createRecurrence(
            title: '학원',
            weekdayMask: 1 << 5 | 1 << 6,
            startTime: const LocalTime(16, 0),
            endTime: const LocalTime(17, 0),
          );
      final scheduler = h.container.read(notificationSchedulerProvider);
      scheduler.start();
      await scheduler.reschedule();
      expect(h.notifications.cancelCalls, greaterThan(0), reason: 'nothing on yet → empty plan → cancel');
      expect(h.notifications.scheduled, isEmpty);

      await h.container.read(settingsRepositoryProvider).setNotifEvent10min(on: true);
      await h.settle();
      await scheduler.reschedule();
      expect(h.notifications.scheduled.map((n) => n.at), contains(DateTime(2026, 10, 3, 15, 50)));

      await h.container.read(settingsRepositoryProvider).setNotifReviewTime(const LocalTime(21, 0));
      await h.settle();
      await scheduler.reschedule();
      expect(h.notifications.scheduled.map((n) => n.id), contains(100));

      h.notifications.permission = NotificationPermission.denied;
      final before = h.notifications.cancelCalls;
      await scheduler.reschedule();
      expect(h.notifications.cancelCalls, before + 1);
      expect(h.notifications.scheduled, isEmpty);
    });

    test('permission state: refresh · request → reschedules', () async {
      h.notifications.permission = NotificationPermission.unknown;
      final n = h.container.read(notificationPermissionStateProvider.notifier);
      expect(await n.refresh(), NotificationPermission.unknown);
      h.notifications.requestResult = NotificationPermission.granted;
      expect(await n.request(), NotificationPermission.granted);
      expect(h.container.read(notificationPermissionStateProvider), NotificationPermission.granted);
      expect(h.notifications.requestCalls, 1);
      await n.openSystemSettings();
      expect(h.notifications.openSettingsCalls, 1);
    });
  });

  group('InquiryController', () {
    test('sent: [kind] body + 7-day summary line, reply email only when given', () async {
      await seedSession('a', DateTime(2026, 10, 1, 9), const Duration(minutes: 90));
      final c = h.container.read(inquiryControllerProvider);
      expect(await c.send(kind: '오류', body: ' 화면이 멈춰요 ', replyEmail: ' me@x.io '), isA<InquirySent>());
      final call = h.backend.calls.single;
      expect(call.name, 'submit-inquiry');
      expect(call.body['reply_email'], 'me@x.io');
      final body = call.body['body'] as String;
      expect(body, startsWith(HelpStrings.bodyWithKind('오류', '화면이 멈춰요')));
      expect(body, contains('세션 1회'));
      expect(body, contains('1시간 30분'));
      expect(body.length, lessThanOrEqualTo(HelpStrings.bodyMaxLength));

      expect(await c.send(kind: '기타', body: 'x'), isA<InquirySent>());
      expect(h.backend.calls.last.body.containsKey('reply_email'), isFalse);
      expect(InquiryController.isValidEmail('a@b.co'), isTrue);
      expect(InquiryController.isValidEmail('a@b'), isFalse);
    });

    test('429 rate_limited → InquiryRateLimited; other failures → InquiryFailed', () async {
      final c = h.container.read(inquiryControllerProvider);
      h.backend.responses['submit-inquiry'] = const EdgeFunctionException(429, 'rate_limited');
      expect(await c.send(kind: '제안', body: 'x'), isA<InquiryRateLimited>());
      h.backend.responses['submit-inquiry'] = const EdgeFunctionException(500, 'internal');
      expect(await c.send(kind: '제안', body: 'x'), isA<InquiryFailed>());
      h.backend.responses['submit-inquiry'] = Exception('offline');
      expect(await c.send(kind: '제안', body: 'x'), isA<InquiryFailed>());
    });
  });

  group('PrivacyActions', () {
    test('export builds the file and hands it to share; a share failure throws', () async {
      final a = h.container.read(privacyActionsProvider);
      await a.export(ExportFormat.csv);
      await a.export(ExportFormat.json);
      expect(h.exports.map((f) => f.mimeType), ['application/zip', 'application/json'], reason: 'CSV = zip of tables');
      h.shareError = Exception('no share target');
      expect(() => a.export(ExportFormat.csv), throwsException);
    });

    test('deleteAll: blocked while measuring; otherwise purges and recreates 기타 (local-only, no server call)', () async {
      final sessions = h.container.read(sessionRepositoryProvider);
      final subjects = h.container.read(subjectRepositoryProvider);
      await subjects.create(name: '수학', colorIndex: 0);
      await seedSession('a', DateTime(2026, 10, 1, 9), const Duration(minutes: 30));
      await h.container.read(readingRepositoryProvider).addPhoto(localPath: 'p/1.jpg', takenAt: kHarnessNow, width: 1, height: 1, pageIndex: 0);
      await h.writePhoto('p/1.jpg');
      await sessions.writeSnapshot(
        SessionSnapshot(
          sessionId: 'live',
          mode: SessionMode.manual,
          kind: SessionKind.self,
          startedAt: kHarnessNow,
          segments: const <Segment>[],
          openKind: SegmentKind.manual,
          openStart: kHarnessNow,
          savedAt: kHarnessNow,
          sensitivity: 0,
        ),
      );
      final a = h.container.read(privacyActionsProvider);
      expect(await a.deleteAll(), isA<DeleteAllBlocked>());
      expect((await subjects.getAll()).length, 1, reason: 'nothing touched');

      await sessions.clearSnapshot();
      final done = await a.deleteAll();
      expect(done, isA<DeleteAllDone>(), reason: done is DeleteAllFailed ? '${done.error}' : '');
      expect(h.backend.calls, isEmpty, reason: 'local-only: no purge-all');
      expect(await sessions.getAll(), isEmpty);
      expect(await h.container.read(readingRepositoryProvider).getAllPhotos(includeDeleted: true), isEmpty);
      expect(h.photoDir.listSync(recursive: true).whereType<dynamic>().where((e) => e.toString().endsWith('.jpg')), isEmpty);
      final left = await subjects.getAll();
      expect(left.map((s) => s.isDefault), [true]);
      expect(await h.container.read(syncWriterProvider).purgeEpoch(), 1);
    });

    test('deleteAll in backend mode calls purge-all and stores the server epoch', () async {
      await h.dispose();
      h = AppHarness(backend: FakeAuthBackend(session: const AuthSession(userId: 'u-1', email: 'a@x.io'), profileRow: kProfileRowOnboardingDone));
      h.container.listen(authGateProvider, (_, _) {});
      await h.settle();
      h.backend.responses['purge-all'] = <String, dynamic>{'epoch': 9};
      expect(await h.container.read(privacyActionsProvider).deleteAll(), isA<DeleteAllDone>());
      expect(h.backend.callNames, contains('purge-all'));
      expect(await h.container.read(syncWriterProvider).purgeEpoch(), 9);

      h.backend.responses['purge-all'] = Exception('offline');
      expect(await h.container.read(privacyActionsProvider).deleteAll(), isA<DeleteAllFailed>());
    });
  });

  group('AccountController (backend)', () {
    setUp(() async {
      await h.dispose();
      h = AppHarness(backend: FakeAuthBackend(session: const AuthSession(userId: 'u-1', email: 'a@x.io'), profileRow: kProfileRowOnboardingDone));
      h.container.listen(authGateProvider, (_, _) {});
      await h.settle();
      await h.container.read(readingRepositoryProvider).addPhoto(localPath: 'q/1.jpg', takenAt: kHarnessNow, width: 1, height: 1, pageIndex: 0);
      await h.writePhoto('q/1.jpg');
      await h.container.read(subjectRepositoryProvider).create(name: '수학', colorIndex: 0);
    });

    Future<int> rows(String table) async =>
        (await h.db.customSelect("SELECT COUNT(*) AS n FROM $table WHERE user_id = 'u-1'").getSingle()).read<int>('n');

    test('logout: photos wiped, records kept, signed out', () async {
      expect(await rows('subjects'), 1);
      await h.container.read(accountControllerProvider).logout();
      expect(h.backend.callNames, contains('signOut'));
      expect(await rows('photos'), 0);
      expect(h.photoDir.listSync(recursive: true).where((e) => e.path.endsWith('.jpg')), isEmpty);
      expect(await rows('subjects'), 1, reason: 'records stay on the device (D27: wiped only when another account signs in)');
    });

    test('delete account: delete-account → photos → local DB wiped; a server failure changes nothing', () async {
      h.backend.responses['delete-account'] = Exception('offline');
      expect(() => h.container.read(accountControllerProvider).deleteAccount(), throwsException);
      expect(await h.container.read(subjectRepositoryProvider).getAll(), isNotEmpty);
      h.backend.responses.remove('delete-account');
      await h.container.read(accountControllerProvider).deleteAccount();
      expect(h.backend.callNames, containsAllInOrder(<String>['delete-account', 'signOut']));
      expect(await rows('subjects'), 0);
      expect(await rows('photos'), 0);
      expect(h.photoDir.listSync(recursive: true).where((e) => e.path.endsWith('.jpg')), isEmpty);
    });
  });
}
