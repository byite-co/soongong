// Gate → login → consent ① → onboarding → home (S05) through the real router
// against fakes: blocked (provider SDK untouched), the full new-account path,
// hook rejection on an existing-account attempt, the reset deep link while
// signed out, and restored sessions landing on the right step.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soongong/core/router/app_router.dart';
import 'package:soongong/core/strings/auth_strings.dart';
import 'package:soongong/core/strings/home_strings.dart';
import 'package:soongong/core/strings/onboarding_strings.dart';
import 'package:soongong/data/auth/auth_models.dart';
import 'package:soongong/data/auth/password_recovery.dart';
import 'package:soongong/features/auth/application/signup_flow.dart';

import '../helpers/app_harness.dart';
import '../helpers/fake_auth_backend.dart';

void main() {
  late AppHarness h;

  tearDown(() => h.dispose());

  Future<void> tapText(WidgetTester tester, String text) async {
    await tester.ensureVisible(find.text(text));
    await tester.tap(find.text(text));
    await tester.pumpAndSettle();
  }

  testWidgets('signed out → age gate first; blocked → /gate/blocked, SDK call count 0', (tester) async {
    h = AppHarness()..scriptSignup(allowed: false);
    await h.pumpApp(tester);
    expect(find.text(AuthStrings.ageGateTitle), findsOneWidget);

    await tapText(tester, AuthStrings.ageGateContinue);
    expect(find.text(AuthStrings.ageBlockedTitle), findsOneWidget);
    expect(find.text(AuthStrings.ageBlockedBody), findsOneWidget);
    expect(h.social.callCount, 0);
    expect(h.backend.callNames, <String>['age-check']);
    expect(h.backend.calls.single.body.keys, <String>['birth_date']);

    await tapText(tester, '닫기');
    expect(find.text(AuthStrings.ageGateTitle), findsOneWidget);
    await h.unmount(tester);
  });

  testWidgets('new account: gate → Google → consent ① → onboarding 3 steps → home (empty)', (tester) async {
    h = AppHarness()..scriptSignup();
    await h.pumpApp(tester);

    await tapText(tester, AuthStrings.ageGateContinue);
    expect(find.text(AuthStrings.loginSignupTitle), findsOneWidget);
    expect(find.text(AuthStrings.ageGateVerified), findsOneWidget);

    await tapText(tester, AuthStrings.loginGoogle);
    expect(h.social.calls, <SignupProvider>[SignupProvider.google]);
    expect(find.text(AuthStrings.consentAccountTitle), findsOneWidget);
    expect(h.backend.callNames.sublist(0, 4), <String>['age-check', 'issue-pass', 'signInWithIdToken', 'fetchProfile']);

    // Consent ① must be ticked before complete-signup can run.
    expect(find.text(AuthStrings.consentAccountRequired), findsOneWidget);
    await tapText(tester, AuthStrings.consentAccountCheck);
    await tapText(tester, AuthStrings.consentAccountCta);
    expect(h.backend.callNames, contains('complete-signup'));
    expect(find.text(OnboardingStrings.step1Title), findsOneWidget);

    await tapText(tester, OnboardingStrings.next);
    expect(find.text(OnboardingStrings.step2Title), findsOneWidget);
    expect(find.text(OnboardingStrings.consentRequired), findsOneWidget);
    await tapText(tester, OnboardingStrings.consentCheck);
    await tapText(tester, OnboardingStrings.consentNext);
    expect(h.backend.calls.last.name, 'update-consent');
    expect(h.backend.calls.last.body, {'granted': true, 'consent_version': ConsentVersions.reading});
    expect(find.text(OnboardingStrings.step3Title), findsOneWidget);

    await tapText(tester, OnboardingStrings.manualStart);
    expect(h.camera.calls, 0, reason: '수동 타이머로 시작 does not ask for the camera');
    expect(h.backend.calls.last.name, 'rpc:profile_set_onboarding_done');
    expect(find.text(HomeStrings.todayTodos), findsOneWidget);
    expect(find.text(HomeStrings.todosEmpty), findsOneWidget);
    expect(find.text(HomeStrings.emptyHint), findsOneWidget);
    await h.unmount(tester);
  });

  testWidgets('onboarding: RPC failure keeps step 3 with a retry; camera request runs once', (tester) async {
    h = AppHarness(
      backend: FakeAuthBackend(
        session: const AuthSession(userId: 'u-1', email: 'a@x.io'),
        profileRow: kProfileRowOnboardingPending,
      ),
    )..scriptSignup();
    h.backend.responses['rpc:profile_set_onboarding_done'] = const NetworkUnavailableException();
    await h.pumpApp(tester);
    expect(find.text(OnboardingStrings.step1Title), findsOneWidget, reason: 'restored session, onboarding pending');

    await tapText(tester, OnboardingStrings.skip);
    await tapText(tester, OnboardingStrings.consentSkip);
    expect(h.backend.callNames, isNot(contains('update-consent')));
    await tapText(tester, OnboardingStrings.cameraAllowStart);
    expect(h.camera.calls, 1);
    expect(find.text(OnboardingStrings.finishFailed), findsOneWidget);
    expect(find.text(OnboardingStrings.step3Title), findsOneWidget);

    h.backend.responses['rpc:profile_set_onboarding_done'] = kProfileRowOnboardingDone;
    await tapText(tester, OnboardingStrings.cameraAllowStart);
    expect(h.camera.calls, 1, reason: 'permission is not asked twice');
    expect(find.text(HomeStrings.todayTodos), findsOneWidget);
    await h.unmount(tester);
  });

  testWidgets('existing-account attempt rejected by the hook → gate with the reason', (tester) async {
    h = AppHarness()..scriptSignup();
    h.backend.signInError =
        const AuthBackendException(AuthRejectionMapper.hookRejectMessage, statusCode: '400');
    await h.pumpApp(tester);

    await tapText(tester, AuthStrings.ageGateLogin);
    expect(find.text(AuthStrings.loginTitle), findsOneWidget);
    expect(find.text(AuthStrings.loginNewAccount), findsOneWidget);

    await tapText(tester, AuthStrings.loginGoogle);
    expect(find.text(AuthStrings.ageGateTitle), findsOneWidget);
    expect(find.text(AuthStrings.rejectSignupPassRequired), findsOneWidget);
    expect(h.container.read(signupFlowProvider).pendingProvider, SignupProvider.google);
    expect(h.backend.callNames, <String>['signInWithIdToken']);
    await h.unmount(tester);
  });

  testWidgets('existing account signs in → home with the one-line load toast', (tester) async {
    h = AppHarness()..scriptSignup();
    h.backend.profileRow = kProfileRowOnboardingDone;
    await h.pumpApp(tester);
    await tapText(tester, AuthStrings.ageGateLogin);
    await tapText(tester, AuthStrings.loginGoogle);
    expect(find.text(HomeStrings.todayTodos), findsOneWidget);
    expect(find.text(AuthStrings.loadedSummary(0, 0)), findsOneWidget);
    await h.unmount(tester);
  });

  testWidgets('/auth/reset opens while signed out (no bounce to the gate)', (tester) async {
    h = AppHarness();
    await h.pumpApp(tester);
    h.container.read(appRouterProvider).go('/auth/reset');
    await tester.pumpAndSettle();
    expect(find.text(AuthStrings.resetTitle), findsOneWidget);
    expect(find.text(AuthStrings.resetLinkInvalid), findsOneWidget);
    expect(find.text(AuthStrings.ageGateTitle), findsNothing);
    await h.unmount(tester);
  });

  testWidgets('SDK exchanged a recovery link → /auth/reset form → new password → home (S05b)', (tester) async {
    h = AppHarness()..scriptSignup();
    h.backend.profileRow = kProfileRowOnboardingDone;
    await h.pumpApp(tester);
    expect(find.text(AuthStrings.ageGateTitle), findsOneWidget);

    h.backend.emitPasswordRecovery(session: const AuthSession(userId: 'u-1', email: 'a@x.io'));
    await tester.pumpAndSettle();
    expect(find.text(AuthStrings.resetTitle), findsOneWidget);
    expect(find.text(AuthStrings.resetCta), findsOneWidget, reason: 'session present → form, not the invalid-link panel');
    expect(h.container.read(passwordRecoveryProvider), isTrue);

    await tester.enterText(find.byType(TextField), 'new-password-1');
    await tapText(tester, AuthStrings.resetCta);
    expect(h.backend.callNames, contains('updatePassword'));
    expect(h.container.read(passwordRecoveryProvider), isFalse);
    expect(find.text(AuthStrings.resetDone), findsOneWidget);
    expect(find.text(HomeStrings.todayTodos), findsOneWidget);
    await h.unmount(tester);
  });

  testWidgets('restored session without a profile lands on consent ①; with one → home', (tester) async {
    h = AppHarness(backend: FakeAuthBackend(session: const AuthSession(userId: 'u-1', email: null)));
    await h.pumpApp(tester);
    expect(find.text(AuthStrings.consentAccountTitle), findsOneWidget);
    await h.unmount(tester);
    await h.dispose();

    h = AppHarness(
      backend: FakeAuthBackend(
        session: const AuthSession(userId: 'u-1', email: null),
        profileRow: kProfileRowOnboardingDone,
      ),
    );
    await h.pumpApp(tester);
    expect(find.text(HomeStrings.todayTodos), findsOneWidget);
    await h.unmount(tester);
  });
}
