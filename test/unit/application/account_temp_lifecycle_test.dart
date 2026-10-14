import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:soongong/data/auth/account_binding.dart';
import 'package:soongong/data/auth/auth_gate.dart';
import 'package:soongong/data/auth/auth_models.dart';
import 'package:soongong/data/repositories/repositories.dart';
import 'package:soongong/data/temp/owned_temp_store.dart';
import 'package:soongong/data/temp/temp_providers.dart';
import 'package:soongong/features/auth/domain/auth_redirect.dart';
import 'package:soongong/features/privacy/application/photo_retention.dart';
import 'package:soongong/features/settings/application/account_controller.dart';

import '../../helpers/app_harness.dart';
import '../../helpers/fake_auth_backend.dart';

const _a = AuthSession(userId: 'u-1', email: null);
const _b = AuthSession(userId: 'u-2', email: null);

void main() {
  late Directory directory;
  late OwnedTempStore store;
  late GatedAuthBackend backend;
  late AppHarness h;
  var rootUnavailable = false;

  Future<void> waitUntil(bool Function() matches) async {
    final deadline = Stopwatch()..start();
    while (deadline.elapsed < const Duration(seconds: 5)) {
      if (matches()) return;
      await Future<void>.delayed(const Duration(milliseconds: 1));
    }
    expect(matches(), isTrue);
  }

  Future<void> waitFor(bool Function(AuthGateState) matches) async {
    await waitUntil(() => matches(h.container.read(authGateProvider)));
  }

  setUp(() async {
    directory = Directory.systemTemp.createTempSync('account-temp-lifecycle-');
    rootUnavailable = false;
    store = OwnedTempStore(() async {
      if (rootUnavailable) {
        throw const FileSystemException('synthetic-root-failure');
      }
      return directory;
    });
    backend = GatedAuthBackend(
      session: _a,
      profileRow: kProfileRowOnboardingDone,
    );
    h = AppHarness(backend: backend, temporaryStore: store);
    h.container.listen(authGateProvider, (_, _) {});
    await waitFor((state) => state is AuthGateSignedIn);
    expect(h.container.read(authGateProvider), isA<AuthGateSignedIn>());
  });
  tearDown(() async {
    // Forced sign-out deliberately does not wait for its best-effort cleanup.
    // Close the fixture root before disposal so a late revoke cannot recreate
    // it while the fixture itself is being removed.
    rootUnavailable = true;
    await h.dispose();
    directory.deleteSync(recursive: true);
  });

  Future<OwnedTempTask> create(String kind) async {
    final writer = h.container.read(syncWriterProvider);
    final generation = await writer.refreshPurgeGeneration();
    final task = await h.container
        .read(tempOwnershipProvider)
        .create(
          writer,
          kind,
          generation: generation,
          alive: () => backend.currentSession?.userId == writer.ctx.userId,
        );
    task.file('payload.bin').writeAsStringSync('$kind-owned-content');
    return task;
  }

  test(
    'DEL-01 logout synchronously invalidates pending picker and export then removes both',
    () async {
      final picker = await create('picker');
      final export = await create('export');
      final controller = h.container.read(accountControllerProvider);
      final pending = controller.logout();
      expect(
        () => picker.file('late.bin'),
        throwsA(isA<TempStoreUnavailable>()),
      );
      expect(
        () => export.file('late.bin'),
        throwsA(isA<TempStoreUnavailable>()),
      );
      await pending;
      expect(picker.directory.existsSync(), isFalse);
      expect(export.directory.existsSync(), isFalse);
      expect(backend.callNames.where((name) => name == 'signOut').length, 1);
    },
  );

  test(
    'DEL-02 explicit logout on unknown cleanup stays signed in and can retry',
    () async {
      final task = await create('export');
      task.markShared();
      task.release();
      rootUnavailable = true;
      final controller = h.container.read(accountControllerProvider);
      await expectLater(
        controller.logout(),
        throwsA(
          isA<PhotoWipeFailed>().having(
            (error) => error.storeUnavailable,
            'unknown',
            isTrue,
          ),
        ),
      );
      expect(backend.currentSession?.userId, _a.userId);
      expect(backend.callNames, isNot(contains('signOut')));
      expect(task.directory.existsSync(), isTrue);
      rootUnavailable = false;
      await controller.logout();
      expect(task.directory.existsSync(), isFalse);
      expect(backend.currentSession, isNull);
    },
  );

  test(
    'DEL-03 forced sign-out gates access despite cleanup failure and durable owner remains',
    () async {
      final task = await create('export');
      task.markShared();
      task.release();
      rootUnavailable = true;
      backend.emitSession(null);
      await waitFor((state) => state is AuthGateSignedOut);
      expect(() => task.file('late.bin'), throwsA(isA<TempStoreUnavailable>()));
      expect(task.directory.existsSync(), isTrue);
      expect(
        await h.container.read(accountBindingProvider).current(),
        _a.userId,
      );
      rootUnavailable = false;
      expect(
        (await h.container.read(tempOwnershipProvider).revoke(_a.userId))
            .complete,
        isTrue,
      );
      expect(task.directory.existsSync(), isFalse);
    },
  );

  test(
    'DEL-04 failed durable revocation blocks account B binding and cached sign-in',
    () async {
      final task = await create('export');
      final marker = Directory(p.join(task.directory.parent.path, '.revoked'))
        ..createSync();
      backend.profileRow = {...kProfileRowOnboardingDone, 'user_id': _b.userId};
      backend.emitSession(_b);
      await waitFor((state) => state is AuthGateProfileError);
      final error = h.container.read(authGateProvider) as AuthGateProfileError;
      expect(error.storageBlocked, isTrue);
      expect(error.userId, isNull);
      expect(error.hasUser, isFalse);
      expect(
        resolveAuthRedirect(gate: error, uri: Uri.parse(AppPaths.home)),
        AppPaths.launch,
      );
      expect(
        await h.container.read(accountBindingProvider).current(),
        _a.userId,
      );
      expect(task.directory.existsSync(), isTrue);
      marker.deleteSync();
      await h.container.read(authGateProvider.notifier).retry();
      await waitFor(
        (state) => state is AuthGateSignedIn && state.userId == _b.userId,
      );
      final bTask = await create('export');
      final bBytes = bTask.file('payload.bin').readAsBytesSync();
      expect((await task.cleanup()).complete, isTrue);
      expect(bTask.file('payload.bin').readAsBytesSync(), bBytes);
    },
  );

  test('DEL-04 old controller stays cancelled across A to B to A', () async {
    final old = h.container.read(accountControllerProvider);
    backend.profileRow = {...kProfileRowOnboardingDone, 'user_id': _b.userId};
    backend.emitSession(_b);
    await waitFor(
      (state) => state is AuthGateSignedIn && state.userId == _b.userId,
    );
    backend.profileRow = kProfileRowOnboardingDone;
    backend.emitSession(_a);
    await waitFor(
      (state) => state is AuthGateSignedIn && state.userId == _a.userId,
    );
    final task = await create('export');
    final bytes = task.file('payload.bin').readAsBytesSync();
    await expectLater(old.logout(), throwsStateError);
    expect(task.file('payload.bin').readAsBytesSync(), bytes);
    expect(backend.currentSession?.userId, _a.userId);
  });

  test(
    'DEL-07 server acknowledgement and local failure persist distinct receipt and retry only local work',
    () async {
      final controller = h.container.read(accountControllerProvider);
      final gate = backend.hold('delete-account');
      final pending = controller.deleteAccount();
      final observed = expectLater(
        pending,
        throwsA(isA<AccountDeleteLocalCleanupFailed>()),
      );
      await waitUntil(() => backend.callNames.contains('delete-account'));
      expect(backend.callNames, contains('delete-account'));
      // A new operation cannot obtain a fresh epoch while deletion is pending.
      await expectLater(create('export'), throwsStateError);
      rootUnavailable = true;
      gate.complete({});
      await observed;
      expect(controller.serverDeleted, isTrue);
      expect(
        await h.container.read(accountBindingProvider).deletedAccount(),
        _a.userId,
      );
      expect(backend.callNames, isNot(contains('signOut')));
      rootUnavailable = false;
      await controller.retryLocalCleanup();
      expect(
        await h.container.read(accountBindingProvider).deletedAccount(),
        isNull,
      );
      expect(
        backend.callNames.where((name) => name == 'delete-account').length,
        1,
      );
      expect(backend.currentSession, isNull);
    },
  );

  test(
    'DEL-07 new controller reads confirmed receipt and never repeats server deletion',
    () async {
      final binding = h.container.read(accountBindingProvider);
      await binding.rememberDeletion(_a.userId);
      final task = await create('export');
      final controller = h.container.read(accountControllerProvider);
      await controller.deleteAccount();
      expect(backend.callNames, isNot(contains('delete-account')));
      expect(task.directory.existsSync(), isFalse);
      expect(backend.currentSession, isNull);
    },
  );

  test(
    'DEL-07 failed sign-out keeps receipt and a rebuilt gate refuses deleted cached session',
    () async {
      final controller = h.container.read(accountControllerProvider);
      backend.signOutError = StateError('synthetic-sign-out-failure');
      await expectLater(
        controller.deleteAccount(),
        throwsA(isA<AccountDeleteLocalCleanupFailed>()),
      );
      final binding = h.container.read(accountBindingProvider);
      expect(await binding.current(), isNull);
      expect(await binding.deletedAccount(), _a.userId);
      h.container.invalidate(authGateProvider);
      await waitFor((state) => state is AuthGateSignedOut);
      expect(await binding.deletedAccount(), _a.userId);
      expect(
        backend.callNames.where((name) => name == 'delete-account').length,
        1,
      );
      backend.signOutError = null;
      await controller.retryLocalCleanup();
      expect(backend.currentSession, isNull);
      expect(await binding.deletedAccount(), isNull);
      expect(
        backend.callNames.where((name) => name == 'delete-account').length,
        1,
      );
    },
  );

  test(
    'DEL-07 old acknowledged response cannot wipe or sign out newly bound B',
    () async {
      final controller = h.container.read(accountControllerProvider);
      final gate = backend.hold('delete-account');
      final pending = controller.deleteAccount();
      await waitUntil(() => backend.callNames.contains('delete-account'));
      backend.profileRow = {...kProfileRowOnboardingDone, 'user_id': _b.userId};
      backend.emitSession(_b);
      await waitFor(
        (state) => state is AuthGateSignedIn && state.userId == _b.userId,
      );
      final bTask = await create('export');
      final bytes = bTask.file('payload.bin').readAsBytesSync();
      gate.complete({});
      await pending;
      expect(backend.currentSession?.userId, _b.userId);
      expect(
        await h.container.read(accountBindingProvider).current(),
        _b.userId,
      );
      expect(bTask.file('payload.bin').readAsBytesSync(), bytes);
      expect(
        await h.container.read(accountBindingProvider).deletedAccount(),
        isNull,
      );
    },
  );
}
