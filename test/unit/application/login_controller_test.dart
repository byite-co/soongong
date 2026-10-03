// LoginController (S05): social + e-mail flows against fakes — ticket
// expiry returns to the gate without touching the SDK, hook rejection paths,
// existing-account post-login (pull · refresh · toast), e-mail branching.

import 'package:flutter_test/flutter_test.dart';
import 'package:soongong/core/strings/auth_strings.dart';
import 'package:soongong/data/auth/auth_gate.dart';
import 'package:soongong/data/auth/auth_models.dart';
import 'package:soongong/data/auth/social/social_sign_in.dart';
import 'package:soongong/features/auth/application/login_controller.dart';
import 'package:soongong/features/auth/application/post_login.dart';
import 'package:soongong/features/auth/application/signup_flow.dart';

import '../../helpers/app_harness.dart';
import '../../helpers/fake_auth_backend.dart';

void main() {
  late AppHarness h;

  setUp(() {
    h = AppHarness()..scriptSignup();
  });

  tearDown(() => h.dispose());

  LoginController ctl() => h.container.read(loginControllerProvider.notifier);
  SignupFlow flow() => h.container.read(signupFlowProvider.notifier);
  SignupFlowState flowState() => h.container.read(signupFlowProvider);

  group('social', () {
    test('expired ticket → back to the gate, provider SDK never called', () async {
      flow().ticketIssued('old', h.clock.now().subtract(const Duration(minutes: 1)));
      final next = await ctl().signInWithSocial(SignupProvider.google);
      expect(next, LoginNext.gate);
      expect(h.social.callCount, 0);
      expect(h.backend.calls, isEmpty);
      expect(flowState().hasTicket, isFalse);
      expect(flowState().notice, AuthStrings.rejectTicketInvalid);
    });

    test('valid ticket → issue-pass → signInWithIdToken (same nonce) → consent ①', () async {
      flow().ticketIssued('t.t.t', h.clock.now().add(const Duration(minutes: 10)));
      final next = await ctl().signInWithSocial(SignupProvider.apple);
      expect(next, LoginNext.consent);
      expect(h.social.calls, <SignupProvider>[SignupProvider.apple]);
      expect(h.backend.callNames, <String>['issue-pass', 'signInWithIdToken', 'fetchProfile']);
      expect(h.backend.calls[0].body['nonce'], 'fake-nonce');
      expect(h.backend.calls[1].body['nonce'], 'fake-nonce');
      expect(flowState().hasTicket, isFalse, reason: 'flow reset after sign-in');
      expect((h.container.read(authGateProvider) as AuthGateSignedIn).needsSignupCompletion, isTrue);
    });

    test('no ticket + hook rejection → gate with the provider remembered', () async {
      h.backend.signInError =
          const AuthBackendException(AuthRejectionMapper.hookRejectMessage, statusCode: '400');
      final next = await ctl().signInWithSocial(SignupProvider.google);
      expect(next, LoginNext.gate);
      expect(h.backend.callNames, <String>['signInWithIdToken']);
      expect(flowState().pendingProvider, SignupProvider.google);
      expect(flowState().notice, AuthStrings.rejectSignupPassRequired);
    });

    test('ticket + hook rejection (pass expired) → gate, ticket cleared', () async {
      flow().ticketIssued('t.t.t', h.clock.now().add(const Duration(minutes: 10)));
      h.backend.signInError =
          const AuthBackendException(AuthRejectionMapper.hookRejectMessage, statusCode: '400');
      final next = await ctl().signInWithSocial(SignupProvider.kakao);
      expect(next, LoginNext.gate);
      expect(flowState().hasTicket, isFalse);
      expect(flowState().notice, AuthStrings.ageGateExpiredRetry);
    });

    test('existing account → pull · refresh · home with the one-line toast', () async {
      h.backend.profileRow = kProfileRowOnboardingDone;
      final next = await ctl().signInWithSocial(SignupProvider.google);
      expect(next, LoginNext.home);
      expect(h.backend.callNames, <String>['signInWithIdToken', 'fetchProfile']);
      expect(h.container.read(pendingToastProvider), AuthStrings.loadedSummary(0, 0));
      expect((h.container.read(authGateProvider) as AuthGateSignedIn).ready, isTrue);
    });

    test('profile with onboarding pending → onboarding', () async {
      h.backend.profileRow = kProfileRowOnboardingPending;
      expect(await ctl().signInWithSocial(SignupProvider.google), LoginNext.onboarding);
      expect(h.container.read(pendingToastProvider), isNull);
    });

    test('cancelled → nothing; unavailable → one sentence; failure → one sentence', () async {
      h.social.outcome = const SocialTokenCancelled();
      expect(await ctl().signInWithSocial(SignupProvider.google), LoginNext.none);
      expect(h.container.read(loginControllerProvider).error, isNull);

      h.social.available.remove(SignupProvider.kakao);
      expect(await ctl().signInWithSocial(SignupProvider.kakao), LoginNext.none);
      expect(h.container.read(loginControllerProvider).error, AuthStrings.loginProviderUnavailable);

      h.social.outcome = const SocialTokenFailed('x', network: true);
      expect(await ctl().signInWithSocial(SignupProvider.google), LoginNext.none);
      expect(h.container.read(loginControllerProvider).error, AuthStrings.rejectNetwork);
      expect(h.backend.calls, isEmpty);
    });

    test('invalid credentials style rejections keep the screen with a sentence', () async {
      h.backend.signInError = const AuthBackendException('bad', statusCode: '400', code: 'invalid_credentials');
      expect(await ctl().signInWithSocial(SignupProvider.google), LoginNext.none);
      expect(h.container.read(loginControllerProvider).error, AuthStrings.rejectInvalidCredentials);
    });
  });

  group('email', () {
    test('format check keeps the input', () async {
      expect(await ctl().submitEmail('nope'), LoginNext.none);
      expect(h.container.read(loginControllerProvider).error, AuthStrings.emailInvalid);
      expect(h.backend.calls, isEmpty);
    });

    test('existing e-mail → password screen', () async {
      h.backend.responses['check-email'] = <String, dynamic>{'exists': true};
      expect(await ctl().submitEmail(' me@x.io '), LoginNext.password);
      expect(flowState().pendingEmail, 'me@x.io');
    });

    test('new e-mail → gate first, or signup when a ticket is already valid', () async {
      expect(await ctl().submitEmail('new@x.io'), LoginNext.gate);
      flow().ticketIssued('t', h.clock.now().add(const Duration(minutes: 5)));
      expect(await ctl().submitEmail('new@x.io'), LoginNext.signup);
    });

    test('signup: short password rejected locally; ok → issue-pass → signUp → consent', () async {
      flow()
        ..setPendingEmail('new@x.io')
        ..ticketIssued('t', h.clock.now().add(const Duration(minutes: 5)));
      expect(await ctl().signUpWithPassword('short'), LoginNext.none);
      expect(h.container.read(loginControllerProvider).error, AuthStrings.rejectWeakPassword);
      expect(await ctl().signUpWithPassword('long-enough-1'), LoginNext.consent);
      expect(h.backend.callNames, <String>['issue-pass', 'signUp', 'fetchProfile']);
    });

    test('signup without any ticket → gate', () async {
      flow().setPendingEmail('new@x.io');
      expect(await ctl().signUpWithPassword('long-enough-1'), LoginNext.gate);
      expect(h.backend.calls, isEmpty);
    });

    test('reset mail sets resetSent; password sign-in → home for an onboarded account', () async {
      flow().setPendingEmail('me@x.io');
      expect(await ctl().sendPasswordReset(), isTrue);
      expect(h.container.read(loginControllerProvider).resetSent, isTrue);
      expect(h.backend.calls.last.name, 'reset');
      h.backend.profileRow = kProfileRowOnboardingDone;
      expect(await ctl().signInWithPassword('pw-123456'), LoginNext.home);
      expect(h.backend.callNames.where((n) => n == 'fetchProfile').length, 1);
    });
  });
}
