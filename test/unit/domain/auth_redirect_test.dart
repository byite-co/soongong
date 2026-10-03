// resolveAuthRedirect (S05): the five guard cases of the instruction plus the
// reset deep-link exception, host normalisation and local-only mode.

import 'package:flutter_test/flutter_test.dart';
import 'package:soongong/data/auth/auth_gate.dart';
import 'package:soongong/data/auth/auth_models.dart';
import 'package:soongong/features/auth/domain/auth_redirect.dart';

ProfileSnapshot _profile({required bool onboardingDone}) => ProfileSnapshot(
      userId: 'u-1',
      onboardingDone: onboardingDone,
      purgeEpoch: 0,
    );

String? _go(AuthGateState gate, String location) =>
    resolveAuthRedirect(gate: gate, uri: Uri.parse(location));

void main() {
  const signedOut = AuthGateSignedOut();
  const noProfile = AuthGateSignedIn(userId: 'u-1', profile: null);
  final onboarding = AuthGateSignedIn(userId: 'u-1', profile: _profile(onboardingDone: false));
  final ready = AuthGateSignedIn(userId: 'u-1', profile: _profile(onboardingDone: true));

  group('case 1 · signed out', () {
    test('any app route → /gate', () {
      expect(_go(signedOut, '/home'), AppPaths.gate);
      expect(_go(signedOut, '/'), AppPaths.gate);
      expect(_go(signedOut, '/onboarding/2'), AppPaths.gate);
      expect(_go(signedOut, '/signup/complete'), AppPaths.gate);
      expect(_go(signedOut, '/settings'), AppPaths.gate);
    });

    test('gate and login routes are allowed', () {
      for (final p in <String>['/gate', '/gate/blocked', '/login', '/login/email', '/login/password', '/login/signup']) {
        expect(_go(signedOut, p), isNull, reason: p);
      }
    });
  });

  group('case 2 · password-reset deep link while signed out', () {
    test('/auth/reset opens without a session', () {
      expect(_go(signedOut, '/auth/reset'), isNull);
    });

    test('soongong://auth/reset (host auth · path /reset) is normalised', () {
      expect(_go(signedOut, 'soongong://auth/reset'), AppPaths.authReset);
      expect(_go(const AuthGateLoading(), 'soongong://auth/reset'), AppPaths.authReset);
    });

    test('reset stays reachable while loading and when signed in', () {
      expect(_go(const AuthGateLoading(), '/auth/reset'), isNull);
      expect(_go(ready, '/auth/reset'), isNull);
      expect(_go(noProfile, '/auth/reset'), isNull);
    });
  });

  group('case 3 · signed in without a profile (complete-signup pending)', () {
    test('everything → /signup/complete, which itself is allowed', () {
      expect(_go(noProfile, '/home'), AppPaths.signupComplete);
      expect(_go(noProfile, '/'), AppPaths.signupComplete);
      expect(_go(noProfile, '/onboarding/1'), AppPaths.signupComplete);
      expect(_go(noProfile, '/gate'), AppPaths.signupComplete);
      expect(_go(noProfile, '/signup/complete'), isNull);
    });
  });

  group('case 4 · onboarding_done == false', () {
    test('everything → /onboarding/1; onboarding steps allowed', () {
      expect(_go(onboarding, '/home'), AppPaths.onboardingStep(1));
      expect(_go(onboarding, '/signup/complete'), AppPaths.onboardingStep(1));
      expect(_go(onboarding, '/login'), AppPaths.onboardingStep(1));
      expect(_go(onboarding, '/onboarding/1'), isNull);
      expect(_go(onboarding, '/onboarding/3'), isNull);
    });
  });

  group('case 5 · ready', () {
    test('requested route is kept; launch/auth routes → /home', () {
      expect(_go(ready, '/home'), isNull);
      expect(_go(ready, '/planner'), isNull);
      expect(_go(ready, '/settings'), isNull);
      expect(_go(ready, '/measure/setup'), isNull);
      expect(_go(ready, '/'), AppPaths.home);
      expect(_go(ready, '/gate'), AppPaths.home);
      expect(_go(ready, '/login/email'), AppPaths.home);
      expect(_go(ready, '/signup/complete'), AppPaths.home);
      expect(_go(ready, '/onboarding/2'), AppPaths.home);
    });
  });

  group('loading · error · local-only', () {
    test('loading holds on the launch screen', () {
      expect(_go(const AuthGateLoading(), '/'), isNull);
      expect(_go(const AuthGateLoading(), '/home'), AppPaths.launch);
    });

    test('profile error holds on the launch screen (retry there)', () {
      const err = AuthGateProfileError(userId: 'u-1', reason: AuthRejection.network);
      expect(_go(err, '/home'), AppPaths.launch);
      expect(_go(err, '/'), isNull);
    });

    test('local-only dev build skips auth entirely', () {
      const local = AuthGateLocalOnly();
      expect(_go(local, '/'), AppPaths.home);
      expect(_go(local, '/gate'), AppPaths.home);
      expect(_go(local, '/login'), AppPaths.home);
      expect(_go(local, '/home'), isNull);
      expect(_go(local, '/stats'), isNull);
    });
  });
}
