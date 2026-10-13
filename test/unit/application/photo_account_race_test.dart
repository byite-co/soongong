import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:soongong/core/domain/entities/entities.dart';
import 'package:soongong/data/auth/auth_gate.dart';
import 'package:soongong/data/auth/auth_models.dart';
import 'package:soongong/data/photos/photo_store.dart';
import 'package:soongong/data/repositories/repository_providers.dart';
import 'package:soongong/data/repositories/local_purge.dart';
import 'package:soongong/data/temp/owned_temp_store.dart';
import 'package:soongong/data/temp/temp_providers.dart';
import 'package:soongong/features/privacy/application/photo_retention.dart';

import '../../helpers/app_harness.dart';
import '../../helpers/fake_auth_backend.dart';

class _RootGate {
  final entered = Completer<void>();
  final resume = Completer<void>();
  void release() {
    if (!resume.isCompleted) resume.complete();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late AppHarness h;
  late FakeAuthBackend backend;
  _RootGate? nextPhotoRoot;
  _RootGate? nextTempRoot;
  final gates = <_RootGate>[];
  final operations = <Future<Object?>>[];
  var fixtureOpen = true;

  Future<void> signedIn(String user) async {
    final deadline = Stopwatch()..start();
    while (deadline.elapsed < const Duration(seconds: 5)) {
      final state = h.container.read(authGateProvider);
      if (state is AuthGateSignedIn && state.userId == user) return;
      await Future<void>.delayed(const Duration(milliseconds: 1));
    }
    expect(h.container.read(authGateProvider).userId, user);
    expect(h.container.read(authGateProvider), isA<AuthGateSignedIn>());
  }

  Future<void> switchToB() async {
    backend.profileRow = {...kProfileRowOnboardingDone, 'user_id': 'u-2'};
    backend.emitSession(const AuthSession(userId: 'u-2', email: null));
    await signedIn('u-2');
  }

  Future<Photo> seedPhoto(
    String path, {
    bool expired = false,
    List<int> bytes = const [7, 8],
  }) async {
    final row = await h.container
        .read(readingRepositoryProvider)
        .addPhoto(
          localPath: path,
          takenAt: h.clock.now().subtract(Duration(days: expired ? 31 : 0)),
          width: 1,
          height: 1,
          pageIndex: 0,
        );
    final file = await h.writePhoto(path);
    file.writeAsBytesSync(bytes);
    return row;
  }

  Future<Object?> observe<T>(Future<T> pending) {
    final observed = pending.then<Object?>(
      (value) => value,
      onError: (Object error) => error,
    );
    operations.add(observed);
    return observed;
  }

  _RootGate holdPhotoRoot() {
    final gate = _RootGate();
    gates.add(gate);
    nextPhotoRoot = gate;
    return gate;
  }

  _RootGate holdTempRoot() {
    final gate = _RootGate();
    gates.add(gate);
    nextTempRoot = gate;
    return gate;
  }

  setUp(() async {
    gates.clear();
    operations.clear();
    nextPhotoRoot = null;
    nextTempRoot = null;
    fixtureOpen = true;
    backend = FakeAuthBackend(
      session: const AuthSession(userId: 'u-1', email: null),
      profileRow: kProfileRowOnboardingDone,
    );
    h = AppHarness(
      backend: backend,
      photoStore: PhotoStore(() async {
        final gate = nextPhotoRoot;
        nextPhotoRoot = null;
        if (gate != null) {
          gate.entered.complete();
          await gate.resume.future;
        }
        if (!fixtureOpen) throw const PhotoStoreUnavailable('fixture-closed');
        return h.photoDir;
      }),
      temporaryStore: OwnedTempStore(() async {
        final gate = nextTempRoot;
        nextTempRoot = null;
        if (gate != null) {
          gate.entered.complete();
          await gate.resume.future;
        }
        if (!fixtureOpen) throw const TempStoreUnavailable();
        return h.temporaryDir;
      }),
    );
    h.container.listen(authGateProvider, (_, _) {});
    await signedIn('u-1');
    await h.container.read(syncWriterProvider).refreshPurgeGeneration();
  });

  tearDown(() async {
    for (final gate in gates) {
      gate.release();
    }
    await Future.wait(operations);
    fixtureOpen = false;
    await h.dispose();
  });

  test(
    'DEL-04 late A pending photo sweep preserves B file row and pending marker',
    () async {
      final a = h.container.read(photoRetentionProvider);
      await h.container.read(readingRepositoryProvider).markPhotoSweepPending();
      final gate = holdPhotoRoot();
      final pending = observe(a.retryPendingSweep());
      await gate.entered.future;

      await switchToB();
      final readingB = h.container.read(readingRepositoryProvider);
      final row = await readingB.addPhoto(
        localPath: 'b/new.jpg',
        takenAt: h.clock.now(),
        width: 1,
        height: 1,
        pageIndex: 0,
      );
      final file = await h.writePhoto('b/new.jpg');
      file.writeAsBytesSync([2, 3, 4]);
      await readingB.markPhotoSweepPending();
      gate.release();
      final result = await pending;

      expect(file.existsSync(), isTrue);
      expect(file.readAsBytesSync(), [2, 3, 4]);
      expect((await readingB.getAllPhotos()).map((photo) => photo.id), [
        row.id,
      ]);
      expect(await readingB.photoSweepPending(), isTrue);
      expect(result, isNull, reason: 'cancelled A cleanup cannot report zero');
    },
  );

  test(
    'DEL-04 late A wipe after temporary sweep cannot overwrite B pending marker',
    () async {
      final a = h.container.read(photoRetentionProvider);
      final gate = holdTempRoot();
      final pending = observe(
        a.wipeAll(alive: () => backend.currentSession?.userId == 'u-1'),
      );
      await gate.entered.future;
      await switchToB();
      final readingB = h.container.read(readingRepositoryProvider);
      final row = await readingB.addPhoto(
        localPath: 'b/new.jpg',
        takenAt: h.clock.now(),
        width: 1,
        height: 1,
        pageIndex: 0,
      );
      final file = await h.writePhoto('b/new.jpg');
      file.writeAsBytesSync([5, 6]);
      await readingB.markPhotoSweepPending();
      gate.release();
      final result = await pending;

      expect(await readingB.photoSweepPending(), isTrue);
      expect(file.readAsBytesSync(), [5, 6]);
      expect((await readingB.getAllPhotos()).map((photo) => photo.id), [
        row.id,
      ]);
      expect(result, isA<StateError>(), reason: 'old account operation stops');
    },
  );

  for (final method in [
    'deleteOne',
    'fileFor',
    'expiredFileFor',
    'purgeExpired',
  ]) {
    test('DEL-04 late A $method cannot touch a reused B photo path', () async {
      final old = await seedPhoto(
        'shared/reused.jpg',
        expired: method == 'expiredFileFor' || method == 'purgeExpired',
      );
      final a = h.container.read(photoRetentionProvider);
      final gate = holdPhotoRoot();
      final pending = observe(switch (method) {
        'deleteOne' => a.deleteOne(old),
        'fileFor' || 'expiredFileFor' => a.fileFor(old),
        _ => a.purgeExpired(),
      });
      await gate.entered.future;
      await switchToB();
      final fresh = await seedPhoto('shared/reused.jpg', bytes: [11, 12]);
      gate.release();
      final result = await pending;
      final file = File('${h.photoDir.path}/shared/reused.jpg');
      expect(file.existsSync(), isTrue);
      expect(file.readAsBytesSync(), [11, 12]);
      expect(
        (await h.container.read(readingRepositoryProvider).getAllPhotos()).map(
          (photo) => photo.id,
        ),
        [fresh.id],
      );
      expect(result, switch (method) {
        'deleteOne' => isFalse,
        'purgeExpired' => 0,
        _ => isNull,
      });
      // Even a new provider must reject an old account's Photo object.
      final b = h.container.read(photoRetentionProvider);
      expect(await b.fileFor(old), isNull);
      expect(await b.deleteOne(old), isFalse);
      expect(file.readAsBytesSync(), [11, 12]);
    });
  }

  test('DEL-04 late A foreground cache cleanup preserves B cache', () async {
    final a = h.container.read(photoRetentionProvider);
    final gate = holdPhotoRoot(); // No expired rows: first root is clearCache.
    final pending = observe(a.purgeExpired());
    await gate.entered.future;
    await switchToB();
    final file = await h.writePhoto('cache/new.jpg');
    file.writeAsBytesSync([21, 22]);
    // Exercise an eligible cache entry, not a fresh-mtime no-op control.
    file.setLastModifiedSync(h.clock.now().subtract(const Duration(days: 2)));
    gate.release();
    expect(await pending, 0);
    expect(file.readAsBytesSync(), [21, 22]);
    expect(await h.container.read(photoRetentionProvider).purgeExpired(), 0);
    expect(file.existsSync(), isFalse, reason: 'current B still applies TTL');
  });

  test('DEL-04 late A count never reports the new B orphan count', () async {
    await h.container.read(readingRepositoryProvider).markPhotoSweepPending();
    final a = h.container.read(photoRetentionProvider);
    final gate = holdPhotoRoot();
    final pending = observe(a.pendingSweepCount());
    await gate.entered.future;
    await switchToB();
    final file = await h.writePhoto('b/orphan.jpg');
    await h.container.read(readingRepositoryProvider).markPhotoSweepPending();
    gate.release();
    expect(await pending, isNull);
    expect(file.existsSync(), isTrue);
    expect(
      await h.container.read(photoRetentionProvider).pendingSweepCount(),
      1,
    );
  });

  test('DEL-04 disposed A sweep stays cancelled after A to B to A', () async {
    await h.container.read(readingRepositoryProvider).markPhotoSweepPending();
    final old = h.container.read(photoRetentionProvider);
    final gate = holdPhotoRoot();
    final pending = observe(old.retryPendingSweep());
    await gate.entered.future;
    await switchToB();
    backend.profileRow = kProfileRowOnboardingDone;
    backend.emitSession(const AuthSession(userId: 'u-1', email: null));
    await signedIn('u-1');
    final fresh = await seedPhoto('a/fresh.jpg', bytes: [31, 32]);
    await h.container.read(readingRepositoryProvider).markPhotoSweepPending();
    gate.release();
    expect(await pending, isNull);
    expect(File('${h.photoDir.path}/a/fresh.jpg').readAsBytesSync(), [31, 32]);
    expect(
      await h.container.read(readingRepositoryProvider).photoSweepPending(),
      isTrue,
    );
    final current = h.container.read(photoRetentionProvider);
    expect(identical(current, old), isFalse);
    expect(await current.deleteOne(fresh), isTrue);
  });

  for (final boundary in ['temporary epoch', 'purge generation']) {
    test('DEL-05 photo delete captures the same-account $boundary', () async {
      final photo = await seedPhoto('a/retained.jpg');
      final retention = h.container.read(photoRetentionProvider);
      final gate = holdPhotoRoot();
      final pending = observe(retention.deleteOne(photo));
      await gate.entered.future;
      if (boundary == 'temporary epoch') {
        final temporary = h.container.read(tempOwnershipProvider);
        temporary.beginBoundary('u-1');
        temporary.endBoundary('u-1');
      } else {
        final writer = h.container.read(syncWriterProvider);
        final purge = LocalPurge(h.db, writer.ctx);
        await purge.markRequested('synthetic-photo-boundary');
        await purge.clearRequested();
      }
      final file = File('${h.photoDir.path}/a/retained.jpg')
        ..writeAsBytesSync([41, 42]);
      gate.release();
      expect(await pending, isFalse);
      expect(file.readAsBytesSync(), [41, 42]);
      expect(
        (await h.container.read(readingRepositoryProvider).getAllPhotos()).map(
          (row) => row.id,
        ),
        [photo.id],
      );
      expect(
        await retention.deleteOne(photo),
        isTrue,
        reason: 'fresh action works',
      );
    });
  }
}
