// OnboardingController (S05b): skipping step 2 revokes a consent ② the
// server currently holds (granted → back → skip) and is a no-op otherwise.

import 'package:flutter_test/flutter_test.dart';
import 'package:soongong/core/strings/onboarding_strings.dart';
import 'package:soongong/data/auth/auth_gate.dart';
import 'package:soongong/data/auth/auth_models.dart';
import 'package:soongong/features/onboarding/application/onboarding_controller.dart';

import '../../helpers/app_harness.dart';
import '../../helpers/fake_auth_backend.dart';

void main() {
  late AppHarness h;

  setUp(() {
    h = AppHarness(
      backend: FakeAuthBackend(
        session: const AuthSession(userId: 'u-1', email: null),
        profileRow: kProfileRowOnboardingPending,
      ),
    )..scriptSignup();
  });

  tearDown(() => h.dispose());

  Future<void> ready() async {
    for (var i = 0; i < 50 && h.container.read(authGateProvider) is! AuthGateSignedIn; i++) {
      await Future<void>.delayed(Duration.zero);
    }
    h.backend.calls.clear();
  }

  List<RecordedCall> consentCalls() => h.backend.calls.where((c) => c.name == 'update-consent').toList();

  test('new user skips → no server call', () async {
    await ready();
    final ctl = h.container.read(onboardingControllerProvider.notifier);
    expect(await ctl.skipReadingConsent(), isTrue);
    expect(consentCalls(), isEmpty);
  });

  test('grant → (step 3 → back) → skip revokes exactly once', () async {
    await ready();
    final ctl = h.container.read(onboardingControllerProvider.notifier)..setConsentChecked(true);
    expect(await ctl.grantReadingConsent(), isTrue);
    expect((h.container.read(authGateProvider) as AuthGateSignedIn).profile?.readingConsentActive, isTrue);

    h.backend.responses['update-consent'] = <String, dynamic>{
      'profile': <String, dynamic>{
        ...kProfileRowOnboardingPending,
        'consent_reading_version': ConsentVersions.reading,
        'consent_reading_at': '2026-10-03T01:00:00+00:00',
        'consent_reading_revoked_at': '2026-10-03T01:05:00+00:00',
      },
    };
    expect(await ctl.skipReadingConsent(), isTrue);
    final calls = consentCalls();
    expect(calls.length, 2);
    expect(calls[0].body, {'granted': true, 'consent_version': ConsentVersions.reading});
    expect(calls[1].body, {'granted': false});
    expect((h.container.read(authGateProvider) as AuthGateSignedIn).profile?.readingConsentActive, isFalse);
    expect(h.container.read(onboardingControllerProvider).consentChecked, isFalse);

    // Skipping again: nothing to revoke any more.
    expect(await ctl.skipReadingConsent(), isTrue);
    expect(consentCalls().length, 2);
  });

  test('revoke fails offline → stays on step 2 with a retry sentence', () async {
    await ready();
    final ctl = h.container.read(onboardingControllerProvider.notifier)..setConsentChecked(true);
    expect(await ctl.grantReadingConsent(), isTrue);
    h.backend.responses['update-consent'] = const NetworkUnavailableException();
    expect(await ctl.skipReadingConsent(), isFalse);
    expect(h.container.read(onboardingControllerProvider).error, OnboardingStrings.consentSaveFailed);
    expect((h.container.read(authGateProvider) as AuthGateSignedIn).profile?.readingConsentActive, isTrue);
  });
}
