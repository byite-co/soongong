import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:soongong/data/auth/auth_gate.dart';
import 'package:soongong/data/auth/auth_models.dart';
import 'package:soongong/data/photos/photo_store.dart';
import 'package:soongong/data/repositories/repository_providers.dart';
import 'package:soongong/data/temp/owned_temp_store.dart';
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
}
