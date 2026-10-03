// AppHarness (S05 tests): one place for the provider overrides the gate /
// login / onboarding / home tests need — in-memory DB, fixed clock, fake
// auth backend, fake social SDK, fake camera permission, zero-delay fakes.

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soongong/app.dart';
import 'package:soongong/core/contracts/fakes/fakes.dart';
import 'package:soongong/core/contracts/providers.dart';
import 'package:soongong/core/domain/clock.dart';
import 'package:soongong/data/auth/auth_mode.dart';
import 'package:soongong/data/auth/auth_models.dart';
import 'package:soongong/data/auth/auth_providers.dart';
import 'package:soongong/data/auth/social/social_sign_in.dart';
import 'package:soongong/data/db/app_database.dart';
import 'package:soongong/data/repositories/repositories.dart';
import 'package:soongong/features/onboarding/application/camera_permission.dart';

import 'fake_auth_backend.dart';

/// 2026-10-03 (Saturday) 10:00 local.
final DateTime kHarnessNow = DateTime(2026, 10, 3, 10);

const Size kPhone = Size(390, 844);
const Size kTablet = Size(1024, 768);

class AppHarness {
  AppHarness({
    this.mode = AuthMode.backend,
    DateTime? now,
    FakeAuthBackend? backend,
    FakeSocialSignIn? social,
    FakeCameraPermission? camera,
  }) : clock = FixedClock(now ?? kHarnessNow),
       backend = backend ?? FakeAuthBackend(),
       social = social ?? FakeSocialSignIn(),
       camera = camera ?? FakeCameraPermission() {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  }

  final AuthMode mode;
  final FixedClock clock;
  final FakeAuthBackend backend;
  final FakeSocialSignIn social;
  final FakeCameraPermission camera;
  final AppDatabase db = AppDatabase.inMemory();

  late final ProviderContainer container = ProviderContainer(
    overrides: [
      deviceIdProvider.overrideWithValue('test-device'),
      appDatabaseProvider.overrideWithValue(db),
      appClockProvider.overrideWithValue(clock),
      authModeProvider.overrideWithValue(mode),
      authBackendProvider.overrideWithValue(backend),
      socialSignInProvider.overrideWithValue(social),
      cameraPermissionProvider.overrideWithValue(camera),
      syncEngineProvider.overrideWithValue(
        FakeSyncEngine(delay: Duration.zero),
      ),
      billingGatewayProvider.overrideWithValue(
        FakeBillingGateway(delay: Duration.zero),
      ),
    ],
  );

  /// Scripts the server answers of a successful signup.
  void scriptSignup({bool allowed = true}) {
    backend.responses['age-check'] = allowed
        ? <String, dynamic>{
            'allowed': true,
            'ticket': 't.t.t',
            'expires_in': 600,
          }
        : <String, dynamic>{'allowed': false};
    backend.responses['issue-pass'] = <String, dynamic>{
      'issued': true,
      'provider': 'google',
      'expires_at': '2099-01-01T00:00:00.000Z',
    };
    backend.responses['complete-signup'] = <String, dynamic>{
      'profile': kProfileRowOnboardingPending,
    };
    backend.responses['update-consent'] = <String, dynamic>{
      'profile': <String, dynamic>{
        ...kProfileRowOnboardingPending,
        'consent_reading_version': ConsentVersions.reading,
        'consent_reading_at': '2026-10-03T01:00:00+00:00',
      },
    };
    backend.responses['rpc:profile_set_onboarding_done'] =
        kProfileRowOnboardingDone;
    backend.responses['check-email'] = <String, dynamic>{'exists': false};
  }

  Future<void> pumpApp(WidgetTester tester, {Size size = kPhone}) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const SoongongApp(),
      ),
    );
    await tester.pumpAndSettle();
  }

  /// Tears the widget tree down and flushes its timers (toast · drift stream
  /// close) so flutter_test's pending-timer check passes. Call at the end of
  /// every widget test that used [pumpApp].
  Future<void> unmount(WidgetTester tester) async {
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 1));
  }

  /// Lets async provider work (streams, futures) complete in pure Dart tests.
  Future<void> settle([int rounds = 20]) async {
    for (var i = 0; i < rounds; i++) {
      await Future<void>.delayed(Duration.zero);
    }
  }

  Future<void> dispose() async {
    container.dispose();
    await db.close();
  }
}
