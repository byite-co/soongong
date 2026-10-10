// AppHarness (S05 tests): one place for the provider overrides the gate /
// login / onboarding / home tests need — in-memory DB, fixed clock, fake
// auth backend, fake social SDK, fake camera permission, zero-delay fakes.
// Pass `db:` to share a database between two harnesses (app restart).

import 'dart:io';

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
import 'package:soongong/data/export/export_service.dart';
import 'package:soongong/data/photos/photo_store.dart';
import 'package:soongong/data/repositories/repositories.dart';
import 'package:soongong/features/onboarding/application/camera_permission.dart';
import 'package:soongong/features/privacy/application/privacy_providers.dart';

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
    FakeNotificationGateway? notifications,
    FakeNetworkStatus? network,
    this.photoStore,
    AppDatabase? db,
  })  : clock = FixedClock(now ?? kHarnessNow),
        backend = backend ?? FakeAuthBackend(),
        social = social ?? FakeSocialSignIn(),
        camera = camera ?? FakeCameraPermission(),
        notifications = notifications ?? FakeNotificationGateway(),
        network = network ?? FakeNetworkStatus(),
        db = db ?? AppDatabase.inMemory(),
        _ownsDb = db == null {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  }

  final AuthMode mode;
  final FixedClock clock;
  final FakeAuthBackend backend;
  final FakeSocialSignIn social;
  final FakeCameraPermission camera;

  /// S09: what the app scheduled on the device (permission scripted here).
  final FakeNotificationGateway notifications;

  /// S09b: device network state (문의 전송), scripted by `current`.
  final FakeNetworkStatus network;

  /// S09: the on-device photo directory (a temp dir, removed on dispose).
  late final Directory photoDir = Directory.systemTemp.createTempSync('soongong-photos-');

  /// S09b: an injected store (e.g. `FailingPhotoStore`), else a plain one on [photoDir].
  final PhotoStore? photoStore;

  /// S09: files handed to the share sheet by 내 기록 내보내기.
  final List<ExportFile> exports = <ExportFile>[];

  /// S09: when set, sharing throws it (export failure path).
  Object? shareError;

  /// Shared between harnesses to simulate an app restart on the same device.
  final AppDatabase db;
  final bool _ownsDb;

  late final ProviderContainer container = ProviderContainer(
    overrides: [
      deviceIdProvider.overrideWithValue('test-device'),
      appDatabaseProvider.overrideWithValue(db),
      appClockProvider.overrideWithValue(clock),
      authModeProvider.overrideWithValue(mode),
      authBackendProvider.overrideWithValue(backend),
      socialSignInProvider.overrideWithValue(social),
      cameraPermissionProvider.overrideWithValue(camera),
      syncEngineProvider.overrideWithValue(FakeSyncEngine(delay: Duration.zero)),
      billingGatewayProvider.overrideWithValue(FakeBillingGateway(delay: Duration.zero)),
      notificationGatewayProvider.overrideWithValue(notifications),
      networkStatusProvider.overrideWithValue(network),
      photoStoreProvider.overrideWithValue(photoStore ?? PhotoStore(() async => photoDir)),
      shareExportProvider.overrideWithValue((file) async {
        final err = shareError;
        if (err != null) throw err;
        exports.add(file);
      }),
    ],
  );

  /// Creates a photo file under [photoDir] (relative path, as the rows
  /// keep). Synchronous: widget tests run in a fake-async zone where real
  /// dart:io completions never arrive.
  Future<File> writePhoto(String relativePath) async {
    final f = File('${photoDir.path}/$relativePath');
    f.parent.createSync(recursive: true);
    f.writeAsBytesSync(<int>[1, 2, 3]);
    return f;
  }

  /// Scripts the server answers of a successful signup.
  void scriptSignup({bool allowed = true}) {
    backend.responses['age-check'] = allowed
        ? <String, dynamic>{'allowed': true, 'ticket': 't.t.t', 'expires_in': 600}
        : <String, dynamic>{'allowed': false};
    backend.responses['issue-pass'] = <String, dynamic>{
      'issued': true,
      'provider': 'google',
      'expires_at': '2099-01-01T00:00:00.000Z',
    };
    backend.responses['complete-signup'] = <String, dynamic>{'profile': kProfileRowOnboardingPending};
    backend.responses['update-consent'] = <String, dynamic>{
      'profile': <String, dynamic>{
        ...kProfileRowOnboardingPending,
        'consent_reading_version': ConsentVersions.reading,
        'consent_reading_at': '2026-10-03T01:00:00+00:00',
      },
    };
    backend.responses['rpc:profile_set_onboarding_done'] = kProfileRowOnboardingDone;
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

  /// For `tearDown` (runs outside the fake-async zone).
  Future<void> dispose() async {
    container.dispose();
    if (_ownsDb) await db.close();
    if (photoDir.existsSync()) photoDir.deleteSync(recursive: true);
  }

  /// Dispose **inside a widget test body** (before pumping a second app).
  /// Since S09 the container holds drift stream listeners beyond the
  /// widget tree (`NotificationScheduler`, keepAlive). Cancelling them
  /// makes drift schedule zero-duration timers that `db.close()` waits for,
  /// and in the fake-async zone a timer only fires on a pump — so the close
  /// is started first and pumped before it is awaited; otherwise the test
  /// body hangs.
  Future<void> disposeInTest(WidgetTester tester) async {
    container.dispose();
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    final closing = _ownsDb ? db.close() : Future<void>.value();
    await tester.pump(const Duration(seconds: 1));
    await closing;
    if (photoDir.existsSync()) photoDir.deleteSync(recursive: true);
  }
}
