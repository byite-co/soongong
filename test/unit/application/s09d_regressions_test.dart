// S09d regressions (GPT independent re-review of PR #8 at S09c head
// `e016313`): P1-1 a recovery run (foreground · network return) during an
// in-flight `purge-all` clears the request intent and lets ordinary writes
// through while the server is still working; P1-2 a photo store that cannot
// be opened or listed is treated as empty, so a wipe reports success and
// drops the retry marker while the files stay; P2 the store listing is
// empty on Windows (backslash paths never match the '/' prefix). Each
// `repro` test failed before the S09d fix on Linux except the P2 listing,
// which fails on Windows only — its Linux control stays here and the
// Windows-style path contract is covered by `photo_store_path_test.dart`.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:soongong/core/domain/enums.dart';
import 'package:soongong/data/auth/auth_gate.dart';
import 'package:soongong/data/auth/auth_mode.dart';
import 'package:soongong/data/auth/auth_models.dart';
import 'package:soongong/data/photos/photo_store.dart';
import 'package:soongong/data/repositories/local_purge.dart';
import 'package:soongong/data/repositories/repositories.dart';
import 'package:soongong/features/privacy/application/photo_retention.dart';
import 'package:soongong/features/privacy/application/privacy_providers.dart';
import 'package:soongong/features/settings/application/account_controller.dart';
import 'package:soongong/features/settings/application/settings_providers.dart';

import '../../helpers/app_harness.dart';
import '../../helpers/fake_auth_backend.dart';

const AuthSession kU1 = AuthSession(userId: 'u-1', email: 'a@x.io');

/// Flips the injected store between "cannot be opened" and normal.
class StoreSwitch {
  bool unavailable = true;
}

class _ListingFailsStore extends PhotoStore {
  _ListingFailsStore(super.root);

  @override
  Future<List<String>> listAll() async {
    await root();
    throw const PhotoStoreUnavailable('FileSystemException');
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late AppHarness h;

  tearDown(() => h.dispose());

  Future<void> signedIn(FakeAuthBackend backend, {PhotoStore Function()? store}) async {
    h = AppHarness(backend: backend, photoStore: store?.call());
    h.container.listen(authGateProvider, (_, _) {});
    await h.settle(40);
    expect(h.container.read(currentUserIdProvider), 'u-1');
  }

  Future<void> localOnly({PhotoStore Function()? store}) async {
    h = AppHarness(mode: AuthMode.localOnly, photoStore: store?.call());
    h.container.listen(authGateProvider, (_, _) {});
    await h.settle();
  }

  bool fileExists(String rel) => File('${h.photoDir.path}/$rel').existsSync();
  int purgeCalls(FakeAuthBackend b) => b.callNames.where((n) => n == 'purge-all').length;
  Future<PurgeStage> stage() async => (await h.container.read(localPurgeProvider).state()).stage;

  group('P1-1 in-flight purge-all vs recovery', () {
    test('repro: resume() while purge-all is still in flight keeps the intent and the barrier; the answer completes that same request (one call)', () async {
      final backend = GatedAuthBackend(session: kU1, profileRow: kProfileRowOnboardingDone); // server epoch 0
      await signedIn(backend);
      final settings = h.container.read(settingsControllerProvider);
      await h.container.read(subjectRepositoryProvider).create(name: '수학', colorIndex: 0);
      final gate = backend.hold('purge-all');
      final deleting = h.container.read(privacyActionsProvider).deleteAll();
      await h.settle();
      expect(purgeCalls(backend), 1);
      expect(await stage(), PurgeStage.requested);

      // foreground / network return while the server is still working
      final recovered = await h.container.read(privacyActionsProvider).resume();
      expect(recovered, isA<DeleteAllUnconfirmed>(), reason: 'the request is still running: not cleared, not re-sent');
      expect(await stage(), PurgeStage.requested, reason: 'intent kept');
      expect(await settings.setTheme(ThemeSetting.dark), isFalse, reason: 'ordinary writes stay refused');
      expect(purgeCalls(backend), 1, reason: 'no second server purge');

      gate.complete(<String, dynamic>{'epoch': 9});
      expect(await deleting, isA<DeleteAllDone>());
      await h.settle();
      expect(await stage(), PurgeStage.none);
      expect(await h.container.read(syncWriterProvider).purgeEpoch(), 9);
      expect(purgeCalls(backend), 1);
      expect((await h.container.read(subjectRepositoryProvider).getAll()).map((s) => s.isDefault), <bool>[true]);
      expect(await settings.setTheme(ThemeSetting.dark), isTrue, reason: 'writes resume once the purge finished');
    });
  });

  group('P1-1 request settlement', () {
    String? requestIdOf(FakeAuthBackend b) => b.calls.where((c) => c.name == 'purge-all').last.body['request_id'] as String?;

    test('lost answer → unconfirmed (intent kept, writes refused, no second call); the server served it late → settled from the profile, one call in total', () async {
      final backend = FakeAuthBackend(session: kU1, profileRow: kProfileRowOnboardingDone);
      await signedIn(backend);
      await h.container.read(subjectRepositoryProvider).create(name: '수학', colorIndex: 0);
      final settings = h.container.read(settingsControllerProvider);
      backend.responses['purge-all'] = Exception('connection reset'); // answer lost
      expect(await h.container.read(privacyActionsProvider).deleteAll(), isA<DeleteAllUnconfirmed>());
      final id = requestIdOf(backend)!;
      expect(await stage(), PurgeStage.requested);
      expect(await settings.setTheme(ThemeSetting.dark), isFalse);
      for (var i = 0; i < 3; i++) {
        expect(await h.container.read(privacyActionsProvider).resume(), isA<DeleteAllUnconfirmed>(), reason: 'same epoch + id not served + inside the server window → still unknown');
      }
      expect(purgeCalls(backend), 1, reason: 'recovery never re-sends');

      // the server executed the call whose answer was lost
      backend.profileRow = <String, dynamic>{...kProfileRowOnboardingDone, 'purge_epoch': 9, 'purge_request_id': id};
      expect(await h.container.read(privacyActionsProvider).resume(), isA<DeleteAllDone>());
      expect(await stage(), PurgeStage.none);
      expect(await h.container.read(syncWriterProvider).purgeEpoch(), 9);
      expect((await h.container.read(subjectRepositoryProvider).getAll()).map((s) => s.isDefault), <bool>[true]);
      expect(purgeCalls(backend), 1);
      expect(await settings.setTheme(ThemeSetting.dark), isTrue);
    });

    test('lost answer, then the user retries → the SAME request id is re-sent (replayed by the server), never a new purge', () async {
      final backend = FakeAuthBackend(session: kU1, profileRow: kProfileRowOnboardingDone);
      await signedIn(backend);
      backend.responses['purge-all'] = Exception('timeout');
      expect(await h.container.read(privacyActionsProvider).deleteAll(), isA<DeleteAllUnconfirmed>());
      final id = requestIdOf(backend)!;
      backend.responses['purge-all'] = <String, dynamic>{'epoch': 9, 'replayed': true};
      expect(await h.container.read(privacyActionsProvider).deleteAll(), isA<DeleteAllDone>());
      expect(purgeCalls(backend), 2);
      expect(requestIdOf(backend), id, reason: 'the retry carries the original id');
      expect(await h.container.read(syncWriterProvider).purgeEpoch(), 9);
      expect(await stage(), PurgeStage.none);
    });

    test('confirmed rejection (4xx) → intent cleared, writes resume, no retry by the recovery', () async {
      final backend = FakeAuthBackend(session: kU1, profileRow: kProfileRowOnboardingDone);
      await signedIn(backend);
      final settings = h.container.read(settingsControllerProvider);
      backend.responses['purge-all'] = const EdgeFunctionException(403, 'no_profile');
      final outcome = await h.container.read(privacyActionsProvider).deleteAll();
      expect(outcome, isA<DeleteAllFailed>());
      expect((outcome as DeleteAllFailed).error, isA<EdgeFunctionException>());
      expect(await stage(), PurgeStage.none);
      expect(await settings.setTheme(ThemeSetting.dark), isTrue);
      expect(await h.container.read(privacyActionsProvider).resume(), isNull);
      expect(purgeCalls(backend), 1);
    });

    test('lost answer, server reachable, id not served: cleared only after the server execution window passed', () async {
      final backend = FakeAuthBackend(session: kU1, profileRow: kProfileRowOnboardingDone);
      await signedIn(backend);
      final settings = h.container.read(settingsControllerProvider);
      backend.responses['purge-all'] = Exception('connection reset');
      expect(await h.container.read(privacyActionsProvider).deleteAll(), isA<DeleteAllUnconfirmed>());
      expect(await h.container.read(privacyActionsProvider).resume(), isA<DeleteAllUnconfirmed>(), reason: 'inside the window the request may still be executing');
      expect(await settings.setTheme(ThemeSetting.dark), isFalse);

      h.clock.advance(kPurgeRequestSettleWindow + const Duration(seconds: 1));
      expect(await h.container.read(privacyActionsProvider).resume(), isNull, reason: 'window passed · epoch unchanged · id not on the profile → never served');
      expect(await stage(), PurgeStage.none);
      expect(await settings.setTheme(ThemeSetting.dark), isTrue);
      expect(purgeCalls(backend), 1);
    });

    test('the same account signs in again while its purge-all is still in flight: the new instance waits (no clear, no second call); the late answer settles it', () async {
      final backend = GatedAuthBackend(session: kU1, profileRow: kProfileRowOnboardingDone);
      await signedIn(backend);
      await h.container.read(subjectRepositoryProvider).create(name: '수학', colorIndex: 0);
      final gate = backend.hold('purge-all');
      final first = h.container.read(privacyActionsProvider);
      final deleting = first.deleteAll();
      await h.settle();
      final id = requestIdOf(backend)!;

      backend.emitSession(null); // session dropped → the u-1 actions are disposed
      await h.settle(40);
      backend.emitSession(kU1); // same account again (profile still epoch 0: the call has not finished)
      await h.settle(60);
      final second = h.container.read(privacyActionsProvider);
      expect(identical(first, second), isFalse);
      expect(await second.resume(), isA<DeleteAllUnconfirmed>(), reason: 'the call for this id is still running in this process');
      expect(await stage(), PurgeStage.requested);
      expect(purgeCalls(backend), 1);

      backend.profileRow = <String, dynamic>{...kProfileRowOnboardingDone, 'purge_epoch': 9, 'purge_request_id': id};
      gate.complete(<String, dynamic>{'epoch': 9});
      expect(await deleting, isA<DeleteAllFailed>(), reason: 'the first instance is disposed; its answer is kept for the account');
      expect(await second.resume(), isA<DeleteAllDone>());
      expect(await stage(), PurgeStage.none);
      expect(await h.container.read(syncWriterProvider).purgeEpoch(), 9);
      expect((await h.container.read(subjectRepositoryProvider).getAll()).map((s) => s.isDefault), <bool>[true]);
      expect(purgeCalls(backend), 1);
    });

    test('a second deleteAll while one is running joins it (one operation per account)', () async {
      final backend = GatedAuthBackend(session: kU1, profileRow: kProfileRowOnboardingDone);
      await signedIn(backend);
      final gate = backend.hold('purge-all');
      final a = h.container.read(privacyActionsProvider).deleteAll();
      await h.settle();
      final b = h.container.read(privacyActionsProvider).deleteAll();
      await h.settle();
      expect(purgeCalls(backend), 1);
      gate.complete(<String, dynamic>{'epoch': 2});
      expect(await a, isA<DeleteAllDone>());
      expect(await b, isA<DeleteAllDone>());
      expect(purgeCalls(backend), 1);
    });
  });

  group('P1-2 photo store access failure', () {
    test('repro: a store that cannot be opened is not an empty store — wipeAll reports failure, keeps the retry marker and the file; the retry after recovery deletes it', () async {
      final sw = StoreSwitch();
      await localOnly(
        store: () => PhotoStore(() async {
          if (sw.unavailable) throw FileSystemException('store unavailable', h.photoDir.path);
          return h.photoDir;
        }),
      );
      await h.writePhoto('cache/private-photo.jpg'); // real file, no row
      final retention = h.container.read(photoRetentionProvider);
      final reading = h.container.read(readingRepositoryProvider);

      final r = await retention.wipeAll();
      expect(r.allDone, isFalse, reason: 'files could not be enumerated → not a success');
      expect(await reading.photoSweepPending(), isTrue, reason: 'retry state kept');
      expect(fileExists('cache/private-photo.jpg'), isTrue);

      sw.unavailable = false;
      expect(await retention.retryPendingSweep(), 0);
      expect(fileExists('cache/private-photo.jpg'), isFalse);
      expect(await reading.photoSweepPending(), isFalse);
    });

    test('repro: 모든 기록 삭제 with an unreachable store is partial, logout with it does not sign out', () async {
      final sw = StoreSwitch();
      final backend = FakeAuthBackend(session: kU1, profileRow: kProfileRowOnboardingDone);
      await signedIn(
        backend,
        store: () => PhotoStore(() async {
          if (sw.unavailable) throw FileSystemException('store unavailable', h.photoDir.path);
          return h.photoDir;
        }),
      );
      await h.writePhoto('cache/private-photo.jpg');
      backend.responses['purge-all'] = <String, dynamic>{'epoch': 1};
      expect(await h.container.read(privacyActionsProvider).deleteAll(), isA<DeleteAllPartial>());
      expect(await h.container.read(readingRepositoryProvider).photoSweepPending(), isTrue);
      await expectLater(h.container.read(accountControllerProvider).logout(), throwsA(isA<PhotoWipeFailed>()));
      expect(backend.callNames, isNot(contains('signOut')));
      expect(fileExists('cache/private-photo.jpg'), isTrue);
    });
  });

  group('P1-2 more store failures', () {
    test('a listing that fails half-way is not a success either; a normal empty store is', () async {
      await localOnly(store: () => _ListingFailsStore(() async => h.photoDir));
      await h.writePhoto('cache/private-photo.jpg');
      final retention = h.container.read(photoRetentionProvider);
      final r = await retention.wipeAll();
      expect(r.allDone, isFalse);
      expect(r.storeUnavailable, isTrue);
      expect(await h.container.read(readingRepositoryProvider).photoSweepPending(), isTrue);
      expect(await retention.pendingSweepCount(), isNull, reason: 'unknown, not 0');
    });

    test('control: an empty, readable store wipes clean and clears the marker', () async {
      await localOnly();
      final retention = h.container.read(photoRetentionProvider);
      final r = await retention.wipeAll();
      expect(r.allDone, isTrue);
      expect(await h.container.read(readingRepositoryProvider).photoSweepPending(), isFalse);
      expect(await retention.pendingSweepCount(), 0);
    });
  });

  group('P2 store listing', () {
    test('control (Linux): listAll sees a row-less cache file as a relative path with forward slashes', () async {
      await localOnly();
      await h.writePhoto('cache/orphan.jpg');
      final store = h.container.read(photoStoreProvider);
      expect(await store.listAll(), contains('cache/orphan.jpg'));
    });
  });
}
