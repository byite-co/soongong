import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:soongong/data/auth/account_binding.dart';
import 'package:soongong/data/auth/auth_gate.dart';
import 'package:soongong/data/auth/auth_models.dart';
import 'package:soongong/data/temp/legacy_temp_probe.dart';
import 'package:soongong/data/temp/owned_temp_store.dart';
import 'package:soongong/features/privacy/application/photo_retention.dart';
import 'package:soongong/features/settings/application/account_controller.dart';

import '../../helpers/app_harness.dart';
import '../../helpers/fake_auth_backend.dart';

void main() {
  test(
    'DEL legacy uncertainty prevents logout completion until explicit removal',
    () async {
      final sandbox = Directory.systemTemp.createTempSync('legacy-account-');
      final cache = Directory(p.join(sandbox.path, 'cache'))..createSync();
      final legacy = File(p.join(cache.path, 'soongong-export-old', 'raw.bin'))
        ..parent.createSync()
        ..writeAsBytesSync([101, 102]);
      final external = File(p.join(sandbox.path, 'original.bin'))
        ..writeAsBytesSync([111, 112]);
      var fixtureOpen = true;
      final store = OwnedTempStore(
        () async {
          if (!fixtureOpen) throw const TempStoreUnavailable();
          return Directory(p.join(cache.path, 'soongong-owned-v1'));
        },
        legacyClean: LegacyTempProbe(() async => cache, android: true).isClean,
      );
      final backend = FakeAuthBackend(
        session: const AuthSession(userId: 'u-1', email: null),
        profileRow: kProfileRowOnboardingDone,
      );
      final h = AppHarness(backend: backend, temporaryStore: store);
      addTearDown(() async {
        fixtureOpen = false;
        await h.dispose();
        sandbox.deleteSync(recursive: true);
      });
      h.container.listen(authGateProvider, (_, _) {});
      final deadline = Stopwatch()..start();
      while (h.container.read(authGateProvider) is! AuthGateSignedIn &&
          deadline.elapsed < const Duration(seconds: 5)) {
        await Future<void>.delayed(const Duration(milliseconds: 1));
      }
      expect(h.container.read(authGateProvider), isA<AuthGateSignedIn>());
      final controller = h.container.read(accountControllerProvider);
      await expectLater(
        controller.logout(),
        throwsA(
          isA<PhotoWipeFailed>().having(
            (error) => error.storeUnavailable,
            'unknown cleanup',
            isTrue,
          ),
        ),
      );
      expect(backend.currentSession?.userId, 'u-1');
      expect(backend.callNames, isNot(contains('signOut')));
      expect(await h.container.read(accountBindingProvider).current(), 'u-1');
      expect(legacy.readAsBytesSync(), [101, 102]);
      expect(external.readAsBytesSync(), [111, 112]);

      // A fixture/operator removes the unowned legacy directory explicitly.
      legacy.parent.deleteSync(recursive: true);
      await controller.logout();
      expect(backend.currentSession, isNull);
      expect(
        backend.callNames.where((name) => name == 'signOut'),
        hasLength(1),
      );
      expect(external.readAsBytesSync(), [111, 112]);
    },
  );
}
