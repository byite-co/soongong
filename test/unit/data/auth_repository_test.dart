// AuthRepository · AgeGateRepository (S03 · S05) against a fake backend: call
// order of the D6 signup flow (sign-in → own profile read; `complete-signup`
// only from consent ①), rejection mapping, and "birth date never logged".

import 'package:flutter_test/flutter_test.dart';
import 'package:logger/logger.dart';
import 'package:soongong/core/logging/app_logger.dart';
import 'package:soongong/core/strings/auth_strings.dart';
import 'package:soongong/data/auth/age_gate_repository.dart';
import 'package:soongong/data/auth/auth_models.dart';
import 'package:soongong/data/auth/auth_repository.dart';

import '../../helpers/fake_auth_backend.dart';

void main() {
  late FakeAuthBackend backend;
  late AgeGateRepository ageGate;
  late AuthRepository auth;

  setUp(() {
    backend = FakeAuthBackend();
    ageGate = AgeGateRepository(backend);
    auth = AuthRepository(backend, ageGate, checkEmailAppKey: 'app-key');
    backend.responses['age-check'] = <String, dynamic>{'allowed': true, 'ticket': 't.t.t', 'expires_in': 600};
    backend.responses['issue-pass'] = <String, dynamic>{'issued': true, 'provider': 'email', 'expires_at': '2026-10-01T00:10:00.000Z'};
    backend.responses['complete-signup'] = <String, dynamic>{'profile': kProfileRowOnboardingPending};
  });

  group('AgeGateRepository', () {
    test('check sends yyyy-MM-dd without a session and returns a ticket', () async {
      final out = await ageGate.check(DateTime(2010, 3, 7));
      expect(out, isA<AgeTicketIssued>());
      expect((out as AgeTicketIssued).ticket, 't.t.t');
      final call = backend.calls.single;
      expect(call.name, 'age-check');
      expect(call.body, {'birth_date': '2010-03-07'});
      expect(call.withUser, isFalse);
    });

    test('blocked → AgeBlocked, no ticket', () async {
      backend.responses['age-check'] = <String, dynamic>{'allowed': false};
      expect(await ageGate.check(DateTime(2015, 1, 1)), isA<AgeBlocked>());
    });

    test('network / server failure → AgeGateFailed with mapped reason', () async {
      backend.responses['age-check'] = const NetworkUnavailableException();
      final out = await ageGate.check(DateTime(2010, 1, 1));
      expect((out as AgeGateFailed).reason, AuthRejection.network);
      backend.responses['age-check'] = const EdgeFunctionException(429, 'rate_limited');
      expect(((await ageGate.check(DateTime(2010, 1, 1))) as AgeGateFailed).reason, AuthRejection.rateLimited);
    });

    test('issuePass: email vs id_token payloads', () async {
      await ageGate.issuePass(ticket: 't', provider: SignupProvider.email, email: 'A@x.io');
      expect(backend.calls.last.body, {'ticket': 't', 'provider': 'email', 'email': 'A@x.io'});
      await ageGate.issuePass(ticket: 't', provider: SignupProvider.apple, idToken: 'id.tok', nonce: 'n');
      expect(backend.calls.last.body, {'ticket': 't', 'provider': 'apple', 'id_token': 'id.tok', 'nonce': 'n'});
      expect(backend.calls.last.withUser, isFalse);
    });

    test('issuePass: ticket_invalid → PassFailed(ticketInvalid)', () async {
      backend.responses['issue-pass'] = const EdgeFunctionException(400, 'ticket_invalid');
      final out = await ageGate.issuePass(ticket: 'old', provider: SignupProvider.email, email: 'a@x.io');
      expect((out as PassFailed).reason, AuthRejection.ticketInvalid);
    });

    test('birth date and email never reach the log output', () async {
      final lines = <String>[];
      void listener(OutputEvent e) => lines.addAll(e.lines);
      Logger.addOutputListener(listener);
      addTearDown(() => Logger.removeOutputListener(listener));
      await ageGate.check(DateTime(2010, 3, 7));
      backend.responses['age-check'] = const EdgeFunctionException(400, 'invalid_field', detail: 'birth_date');
      await ageGate.check(DateTime(2011, 4, 8));
      await ageGate.issuePass(ticket: 't', provider: SignupProvider.email, email: 'secret@x.io');
      await auth.signUpWithEmail(ticket: 't', email: 'secret@x.io', password: 'pw-123456');
      expect(lines, isNotEmpty);
      for (final l in lines) {
        expect(l, isNot(contains('2010-03-07')));
        expect(l, isNot(contains('2011-04-08')));
        expect(l, isNot(contains('secret@x.io')));
        expect(l, isNot(contains('t.t.t')));
      }
      // appLog is the only logger in the app
      expect(appLog, isNotNull);
    });
  });

  group('AuthRepository · email', () {
    test('sign-up order: issue-pass → signUp → profile read (none yet), no complete-signup', () async {
      final out = await auth.signUpWithEmail(ticket: 't', email: ' new@x.io ', password: 'pw-123456');
      expect(out, isA<SignedIn>());
      expect((out as SignedIn).isNewUser, isTrue);
      expect(out.profile, isNull);
      expect(out.needsSignupCompletion, isTrue);
      expect(backend.callNames, ['issue-pass', 'signUp', 'fetchProfile']);
      expect(backend.calls[1].body['email'], 'new@x.io');
    });

    test('consent ① → complete-signup records the version and returns the profile', () async {
      await auth.signUpWithEmail(ticket: 't', email: 'new@x.io', password: 'pw-123456');
      backend.calls.clear();
      final out = await auth.confirmAccountConsent();
      expect((out as SignedIn).profile?.consentAccountVersion, '2026-10-01');
      expect(out.needsSignupCompletion, isFalse);
      expect(backend.callNames, ['complete-signup']);
      expect(backend.calls.single.body, {'consent_version': ConsentVersions.account});
    });

    test('pass failure stops before signUp', () async {
      backend.responses['issue-pass'] = const EdgeFunctionException(400, 'ticket_invalid');
      final out = await auth.signUpWithEmail(ticket: 'old', email: 'a@x.io', password: 'pw-123456');
      expect((out as SignInRejected).reason, AuthRejection.ticketInvalid);
      expect(backend.calls.map((c) => c.name).toList(), ['issue-pass']);
    });

    test('hook rejection on signUp → signupPassRequired, no complete-signup', () async {
      backend.signUpError = const AuthBackendException(AuthRejectionMapper.hookRejectMessage, statusCode: '400');
      final out = await auth.signUpWithEmail(ticket: 't', email: 'a@x.io', password: 'pw-123456');
      expect((out as SignInRejected).reason, AuthRejection.signupPassRequired);
      expect(backend.callNames, ['issue-pass', 'signUp']);
    });

    test('sign-in: signInWithPassword → profile read, existing user, no complete-signup', () async {
      backend.profileRow = kProfileRowOnboardingDone;
      final out = await auth.signInWithEmail(email: 'a@x.io', password: 'pw');
      expect((out as SignedIn).isNewUser, isFalse);
      expect(out.profile?.onboardingDone, isTrue);
      expect(out.needsSignupCompletion, isFalse);
      expect(backend.callNames, ['signInWithPassword', 'fetchProfile']);
    });

    test('sign-in with the profile unreadable → SignedIn(profileLoaded: false), not a rejection', () async {
      backend.profileError = const NetworkUnavailableException();
      final out = await auth.signInWithEmail(email: 'a@x.io', password: 'pw');
      expect((out as SignedIn).profileLoaded, isFalse);
      expect(out.needsSignupCompletion, isFalse);
      expect(backend.currentSession, isNotNull);
    });

    test('invalid credentials / email taken / weak password mapping', () async {
      backend.signInError = const AuthBackendException('Invalid login credentials', statusCode: '400', code: 'invalid_credentials');
      expect(((await auth.signInWithEmail(email: 'a@x.io', password: 'x')) as SignInRejected).reason, AuthRejection.invalidCredentials);
      backend.signUpError = const AuthBackendException('User already registered', statusCode: '422', code: 'user_already_exists');
      expect(((await auth.signUpWithEmail(ticket: 't', email: 'a@x.io', password: 'pw-123456')) as SignInRejected).reason, AuthRejection.emailTaken);
      backend.signUpError = const AuthBackendException('Password should be at least 8 characters', statusCode: '422', code: 'weak_password');
      expect(((await auth.signUpWithEmail(ticket: 't', email: 'a@x.io', password: 'pw')) as SignInRejected).reason, AuthRejection.weakPassword);
    });

    test('not_approved from complete-signup → sign out + notApproved', () async {
      await auth.signInWithEmail(email: 'a@x.io', password: 'pw');
      backend.calls.clear();
      backend.responses['complete-signup'] = const EdgeFunctionException(403, 'not_approved');
      final out = await auth.confirmAccountConsent();
      expect((out as SignInRejected).reason, AuthRejection.notApproved);
      expect(backend.callNames, ['complete-signup', 'signOut']);
      expect(backend.currentSession, isNull);
    });

    test('complete-signup offline → network rejection, session kept for retry', () async {
      await auth.signInWithEmail(email: 'a@x.io', password: 'pw');
      backend.responses['complete-signup'] = const NetworkUnavailableException();
      final out = await auth.confirmAccountConsent();
      expect((out as SignInRejected).reason, AuthRejection.network);
      expect(backend.currentSession, isNotNull);
    });

    test('updatePassword: null on success, mapped reason on failure', () async {
      expect(await auth.updatePassword('new-pass-123'), isNull);
      backend.updatePasswordError = const AuthBackendException('weak', code: 'weak_password');
      expect(await auth.updatePassword('short'), AuthRejection.weakPassword);
    });

    test('checkEmailExists uses the app key without a session', () async {
      backend.responses['check-email'] = <String, dynamic>{'exists': true};
      expect(await auth.checkEmailExists('A@x.io'), isTrue);
      final c = backend.calls.single;
      expect(c.headers['x-app-key'], 'app-key');
      expect(c.withUser, isFalse);
      expect(c.body, {'email': 'A@x.io'});
    });
  });

  group('AuthRepository · social', () {
    test('existing account: no ticket → signInWithIdToken → profile read', () async {
      backend.profileRow = kProfileRowOnboardingDone;
      final out = await auth.signInWithProvider(provider: SignupProvider.google, idToken: 'id');
      expect((out as SignedIn).isNewUser, isFalse);
      expect(out.profile?.onboardingDone, isTrue);
      expect(backend.callNames, ['signInWithIdToken', 'fetchProfile']);
    });

    test('new account: hook rejects → signupPassRequired; with ticket → issue-pass first', () async {
      backend.signInError = const AuthBackendException(AuthRejectionMapper.hookRejectMessage, statusCode: '400');
      final first = await auth.signInWithProvider(provider: SignupProvider.apple, idToken: 'id', nonce: 'n');
      expect((first as SignInRejected).reason, AuthRejection.signupPassRequired);
      backend
        ..signInError = null
        ..calls.clear();
      final second = await auth.signInWithProvider(provider: SignupProvider.apple, idToken: 'id', nonce: 'n', ticket: 't');
      expect((second as SignedIn).isNewUser, isTrue);
      expect(second.needsSignupCompletion, isTrue);
      expect(backend.callNames, ['issue-pass', 'signInWithIdToken', 'fetchProfile']);
      expect(backend.calls.first.body, {'ticket': 't', 'provider': 'apple', 'id_token': 'id', 'nonce': 'n'});
    });

    test('id_token rejected by issue-pass → idTokenInvalid', () async {
      backend.responses['issue-pass'] = const EdgeFunctionException(400, 'id_token_invalid');
      final out = await auth.signInWithProvider(provider: SignupProvider.kakao, idToken: 'bad', ticket: 't');
      expect((out as SignInRejected).reason, AuthRejection.idTokenInvalid);
      expect(backend.callNames, ['issue-pass']);
    });
  });

  group('AuthRepository · account', () {
    test('setOnboardingDone calls the RPC', () async {
      await auth.setOnboardingDone();
      expect(backend.calls.single.name, 'rpc:profile_set_onboarding_done');
    });

    test('updateReadingConsent grant / revoke payloads', () async {
      backend.responses['update-consent'] = <String, dynamic>{
        'profile': <String, dynamic>{...kProfileRowOnboardingPending, 'consent_reading_version': '2026-10-01', 'consent_reading_at': '2026-10-01T00:00:00.000Z'},
      };
      final p = await auth.updateReadingConsent(granted: true);
      expect(p.readingConsentActive, isTrue);
      expect(backend.calls.last.body, {'granted': true, 'consent_version': ConsentVersions.reading});
      await auth.updateReadingConsent(granted: false);
      expect(backend.calls.last.body, {'granted': false});
    });

    test('deleteAccount: delete-account then signOut', () async {
      backend.session = const AuthSession(userId: 'u-1', email: 'a@x.io');
      await auth.deleteAccount();
      expect(backend.callNames, ['delete-account', 'signOut']);
      expect(auth.currentUserId, isNull);
    });

    test('authState mirrors backend sessions', () async {
      final events = <String?>[];
      final sub = auth.authState.listen((s) => events.add(s?.userId));
      await auth.signInWithEmail(email: 'a@x.io', password: 'pw');
      await auth.signOut();
      await Future<void>.delayed(Duration.zero);
      await sub.cancel();
      expect(events, ['u-1', null]);
    });
  });

  test('every rejection has a user string (no forbidden wording is a CI check)', () {
    for (final r in AuthRejection.values) {
      expect(AuthStrings.forRejection(r), isNotEmpty);
    }
  });
}
