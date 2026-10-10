// SettingsScreen (S09) flows: rows as facts, 하루 목표 시간 sheet (chips ·
// premium suggestion · save), 주 시작 요일, 테마 (MaterialApp follows), 알림
// sheet (toggles · time chips · denied-permission explanation · granted
// toast), navigation to subjects / privacy / help / paywall, the 계정 card
// in local-only and backend modes with 로그아웃 and 계정 삭제 ending at the
// gate.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soongong/core/contracts/billing_gateway.dart';
import 'package:soongong/core/contracts/fakes/fakes.dart';
import 'package:soongong/core/contracts/notification_gateway.dart';
import 'package:soongong/core/contracts/providers.dart';
import 'package:soongong/core/domain/enums.dart';
import 'package:soongong/core/domain/local_date.dart';
import 'package:soongong/core/router/app_router.dart';
import 'package:soongong/core/strings/auth_strings.dart';
import 'package:soongong/core/strings/billing_strings.dart';
import 'package:soongong/core/strings/help_strings.dart';
import 'package:soongong/core/strings/home_strings.dart';
import 'package:soongong/core/strings/privacy_strings.dart';
import 'package:soongong/core/strings/settings_strings.dart';
import 'package:soongong/core/strings/subjects_strings.dart';
import 'package:soongong/data/auth/auth_mode.dart';
import 'package:soongong/data/auth/auth_models.dart';
import 'package:soongong/data/repositories/repositories.dart';
import 'package:soongong/features/measure/domain/segment.dart';
import 'package:soongong/features/settings/presentation/settings_screen.dart';

import '../helpers/app_harness.dart';
import '../helpers/fake_auth_backend.dart';

void main() {
  late AppHarness h;

  setUp(() => h = AppHarness(mode: AuthMode.localOnly));
  tearDown(() => h.dispose());

  Future<void> openSettings(WidgetTester tester) async {
    await h.pumpApp(tester);
    await tester.tap(find.byTooltip(HomeStrings.settings));
    await tester.pumpAndSettle();
    expect(find.text(SettingsStrings.title), findsOneWidget);
  }

  Future<void> tapRow(WidgetTester tester, Key key) async {
    await tester.ensureVisible(find.byKey(key));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(key));
    await tester.pumpAndSettle();
  }

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

  testWidgets('rows show facts; local-only account card; version footer', (tester) async {
    await openSettings(tester);
    expect(find.text('2시간'), findsOneWidget);
    expect(find.text(SettingsStrings.monday), findsOneWidget);
    expect(find.text(SettingsStrings.cameraOn), findsOneWidget);
    expect(find.text(SettingsStrings.readingLocked), findsOneWidget);
    expect(find.text(SettingsStrings.localOnlyTitle), findsOneWidget);
    expect(find.byKey(SettingsKeys.logout), findsNothing);
    await tester.ensureVisible(find.byKey(SettingsKeys.version));
    await tester.pumpAndSettle();
    expect(find.text(SettingsStrings.notifOff), findsOneWidget);
    expect(find.text(SettingsStrings.planFree), findsOneWidget);
    expect(find.text(SettingsStrings.version('0.1.0')), findsOneWidget);
    await h.unmount(tester);
  });

  testWidgets('하루 목표 시간: free shows the premium lock, chip + save → row, toast, DB', (tester) async {
    await openSettings(tester);
    await tapRow(tester, SettingsKeys.goalRow);
    expect(find.text(SettingsStrings.goalHint), findsOneWidget);
    expect(find.text(SettingsStrings.goalSuggestedLocked), findsOneWidget);
    expect(find.byKey(SettingsKeys.goalApply), findsNothing);
    await tester.tap(find.byKey(SettingsKeys.goalChip(180)));
    await tester.pumpAndSettle();
    expect(find.text(SettingsStrings.goalSave('3시간')), findsOneWidget);
    await tester.ensureVisible(find.byKey(SettingsKeys.goalSave));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(SettingsKeys.goalSave));
    await tester.pumpAndSettle();
    expect(find.text(SettingsStrings.goalHint), findsNothing);
    expect(find.text(SettingsStrings.saved), findsOneWidget);
    expect(find.text('3시간'), findsOneWidget);
    expect((await h.container.read(settingsRepositoryProvider).get()).dailyGoalMinutes, 180);
    await h.unmount(tester);
  });

  testWidgets('하루 목표 시간: premium shows the 4-week mean and fills it (D25)', (tester) async {
    (h.container.read(billingGatewayProvider) as FakeBillingGateway).force(EntitlementStatus.premium);
    await seedSession('a', DateTime(2026, 9, 20, 9), const Duration(minutes: 100));
    await seedSession('b', DateTime(2026, 9, 25, 9), const Duration(minutes: 200));
    await openSettings(tester);
    expect(find.text(SettingsStrings.readingOn), findsOneWidget);
    await tapRow(tester, SettingsKeys.goalRow);
    await tester.ensureVisible(find.byKey(SettingsKeys.goalApply));
    await tester.pumpAndSettle();
    expect(find.text(SettingsStrings.goalSuggested('2시간 30분')), findsOneWidget);
    await tester.tap(find.byKey(SettingsKeys.goalApply));
    await tester.pumpAndSettle();
    expect(find.text(SettingsStrings.goalSave('2시간 30분')), findsOneWidget);
    await h.unmount(tester);
  });

  testWidgets('주 시작 요일: 일요일 → saved and shown', (tester) async {
    await openSettings(tester);
    await tapRow(tester, SettingsKeys.weekStartRow);
    expect(find.text(SettingsStrings.sundayHint), findsOneWidget);
    await tester.tap(find.byKey(SettingsKeys.weekSunday));
    await tester.pumpAndSettle();
    expect(find.text(SettingsStrings.sundayHint), findsNothing);
    expect(find.text(SettingsStrings.sunday), findsOneWidget);
    expect((await h.container.read(settingsRepositoryProvider).get()).weekStart, DateTime.sunday);
    await h.unmount(tester);
  });

  testWidgets('테마: 다크 → MaterialApp themeMode and the setting', (tester) async {
    await openSettings(tester);
    expect(tester.widget<MaterialApp>(find.byType(MaterialApp)).themeMode, ThemeMode.system);
    await tester.ensureVisible(find.byKey(SettingsKeys.themeChoice));
    await tester.pumpAndSettle();
    await tester.tap(find.text(SettingsStrings.themeDark));
    await tester.pumpAndSettle();
    expect(tester.widget<MaterialApp>(find.byType(MaterialApp)).themeMode, ThemeMode.dark);
    expect((await h.container.read(settingsRepositoryProvider).get()).theme, ThemeSetting.dark);
    await h.unmount(tester);
  });

  testWidgets('알림 sheet: toggles save and plan; denied permission → explanation → 기기 설정 열기', (tester) async {
    h.notifications.permission = NotificationPermission.denied;
    await openSettings(tester);
    await tapRow(tester, SettingsKeys.notifRow);
    expect(find.text(SettingsStrings.notifPermissionOff), findsOneWidget);
    await tester.tap(find.byKey(SettingsKeys.notifReviewSwitch));
    await tester.pumpAndSettle();
    expect((await h.container.read(settingsRepositoryProvider).get()).notifReviewTime, LocalTime.parse(kDefaultReviewTime));
    expect(find.text(SettingsStrings.notifDeniedTitle), findsOneWidget, reason: 'saved, then explained (nfDenied)');
    await tester.tap(find.text(SettingsStrings.notifOpenSettings));
    await tester.pumpAndSettle();
    expect(h.notifications.openSettingsCalls, 1);
    expect(find.text(SettingsStrings.notifDeniedTitle), findsNothing);

    await tester.tap(find.byKey(SettingsKeys.notifTime('20:00')));
    await tester.pumpAndSettle();
    expect((await h.container.read(settingsRepositoryProvider).get()).notifReviewTime, const LocalTime(20, 0));
    await tester.tap(find.byKey(SettingsKeys.notifEventSwitch));
    await tester.pumpAndSettle();
    expect(find.text(SettingsStrings.notifDeniedTitle), findsOneWidget);
    await tester.tap(find.text(SettingsStrings.notifLater));
    await tester.pumpAndSettle();
    expect((await h.container.read(settingsRepositoryProvider).get()).notifEvent10min, isTrue);
    expect(h.notifications.scheduled, isEmpty, reason: 'denied → nothing scheduled on the device');

    h.container.read(appRouterProvider).pop();
    await tester.pumpAndSettle();
    expect(find.text('${SettingsStrings.notifReviewAt('20:00')} · ${SettingsStrings.notifEventShort}'), findsOneWidget);
    await h.unmount(tester);
  });

  testWidgets('알림 sheet: unknown permission → request on toggle; granted → toast', (tester) async {
    h.notifications.permission = NotificationPermission.unknown;
    h.notifications.requestResult = NotificationPermission.granted;
    await openSettings(tester);
    await tapRow(tester, SettingsKeys.notifRow);
    expect(find.text(SettingsStrings.notifPermissionUnknown), findsOneWidget);
    await tester.tap(find.byKey(SettingsKeys.notifReviewSwitch));
    await tester.pumpAndSettle();
    expect(h.notifications.requestCalls, 1);
    expect(find.text(SettingsStrings.notifPermissionOn), findsOneWidget);
    expect(find.text(SettingsStrings.notifEnabledToast(kDefaultReviewTime)), findsOneWidget);
    expect(find.text(SettingsStrings.notifDeniedTitle), findsNothing);
    await h.unmount(tester);
  });

  testWidgets('rows navigate: 과목 관리 · 카메라와 개인정보 · 요금제 · 도움말', (tester) async {
    await openSettings(tester);
    await tapRow(tester, SettingsKeys.subjectsRow);
    expect(find.text(SubjectsStrings.title), findsOneWidget);
    h.container.read(appRouterProvider).pop();
    await tester.pumpAndSettle();
    await tapRow(tester, SettingsKeys.privacyRow);
    expect(find.text(PrivacyStrings.title), findsOneWidget);
    h.container.read(appRouterProvider).pop();
    await tester.pumpAndSettle();
    await tapRow(tester, SettingsKeys.planRow);
    expect(find.text(BillingStrings.paywallTitle), findsWidgets);
    h.container.read(appRouterProvider).pop();
    await tester.pumpAndSettle();
    await tapRow(tester, SettingsKeys.helpRow);
    expect(find.text(HelpStrings.title), findsOneWidget);
    await h.unmount(tester);
  });

  group('backend account', () {
    setUp(() async {
      await h.dispose();
      h = AppHarness(
        backend: FakeAuthBackend(session: const AuthSession(userId: 'u-1', email: 'a@x.io'), profileRow: kProfileRowOnboardingDone)
          ..provider = 'google',
      );
    });

    testWidgets('card shows email · provider · sync fact; 로그아웃 → gate', (tester) async {
      await openSettings(tester);
      expect(find.text('a@x.io'), findsOneWidget);
      expect(find.text('A'), findsOneWidget);
      expect(find.textContaining(SettingsStrings.providerGoogle), findsOneWidget);
      expect(find.text(SettingsStrings.localOnlyTitle), findsNothing);
      await tapRow(tester, SettingsKeys.logout);
      expect(find.text(SettingsStrings.logoutTitle), findsOneWidget);
      await tester.tap(find.text(SettingsStrings.logoutConfirm).last);
      await tester.pumpAndSettle();
      expect(h.backend.callNames, contains('signOut'));
      expect(find.text(AuthStrings.ageGateTitle), findsOneWidget);
      await h.unmount(tester);
    });

    testWidgets('계정 삭제 → delete-account → gate; a failure keeps the modal with a retry line', (tester) async {
      await openSettings(tester);
      h.backend.responses['delete-account'] = Exception('offline');
      await tapRow(tester, SettingsKeys.deleteAccount);
      expect(find.text(SettingsStrings.deleteAccountTitle), findsOneWidget);
      await tester.tap(find.text(SettingsStrings.deleteAccountConfirm).last);
      await tester.pumpAndSettle();
      expect(find.text(SettingsStrings.deleteAccountTitle), findsOneWidget, reason: 'kept open');
      h.backend.responses.remove('delete-account');
      await tester.tap(find.text(SettingsStrings.deleteAccountConfirm).last);
      await tester.pumpAndSettle();
      expect(h.backend.callNames, containsAllInOrder(<String>['delete-account', 'signOut']));
      expect(find.text(AuthStrings.ageGateTitle), findsOneWidget);
      await h.unmount(tester);
    });
  });
}
