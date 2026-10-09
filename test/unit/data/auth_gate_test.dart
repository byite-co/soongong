// AuthGate (S05): session → profile → state, retry, and the account-switch
// wipe (D27) through AccountBinding.

import 'package:flutter_test/flutter_test.dart';
import 'package:soongong/data/auth/account_binding.dart';
import 'package:soongong/data/auth/auth_gate.dart';
import 'package:soongong/data/auth/auth_mode.dart';
import 'package:soongong/data/auth/auth_models.dart';
import 'package:soongong/data/auth/profile_cache.dart';
import 'package:soongong/data/db/app_database.dart';
import 'package:soongong/data/repositories/repositories.dart';

import '../../helpers/app_harness.dart';
import '../../helpers/fake_auth_backend.dart';

void main() {
  late AppHarness h;

  tearDown(() => h.dispose());

  Future<AuthGateState> waitFor(bool Function(AuthGateState) test) async {
    for (var i = 0; i < 50; i++) {
      final s = h.container.read(authGateProvider);
      if (test(s)) return s;
      await Future<void>.delayed(Duration.zero);
    }
    return h.container.read(authGateProvider);
  }

  test('no session → signedOut; currentUserId falls back to the placeholder', () {
    h = AppHarness();
    expect(h.container.read(authGateProvider), isA<AuthGateSignedOut>());
    expect(h.container.read(currentUserIdProvider), kLocalUserId);
  });

  test('local-only mode never touches the backend', () {
    h = AppHarness(mode: AuthMode.localOnly);
    expect(h.container.read(authGateProvider), isA<AuthGateLocalOnly>());
    expect(h.container.read(currentUserIdProvider), kLocalOnlyUserId);
    expect(h.backend.calls, isEmpty);
  });

  test('restored session + profile → signedIn(ready) and binds the database', () async {
    h = AppHarness(
      backend: FakeAuthBackend(
        session: const AuthSession(userId: 'u-1', email: 'a@x.io'),
        profileRow: kProfileRowOnboardingDone,
      ),
    );
    expect(h.container.read(authGateProvider), isA<AuthGateLoading>());
    final s = await waitFor((s) => s is AuthGateSignedIn) as AuthGateSignedIn;
    expect(s.ready, isTrue);
    expect(h.container.read(currentUserIdProvider), 'u-1');
    expect(await h.container.read(accountBindingProvider).current(), 'u-1');
  });

  test('restored session without a profile → needsSignupCompletion', () async {
    h = AppHarness(backend: FakeAuthBackend(session: const AuthSession(userId: 'u-1', email: null)));
    final s = await waitFor((s) => s is AuthGateSignedIn) as AuthGateSignedIn;
    expect(s.needsSignupCompletion, isTrue);
  });

  test('profile read failure → profileError; retry recovers', () async {
    h = AppHarness(
      backend: FakeAuthBackend(session: const AuthSession(userId: 'u-1', email: null))
        ..profileError = const NetworkUnavailableException(),
    );
    final err = await waitFor((s) => s is AuthGateProfileError) as AuthGateProfileError;
    expect(err.reason, AuthRejection.network);
    h.backend
      ..profileError = null
      ..profileRow = kProfileRowOnboardingPending;
    await h.container.read(authGateProvider.notifier).retry();
    final s = h.container.read(authGateProvider) as AuthGateSignedIn;
    expect(s.needsOnboarding, isTrue);
  });

  test('sign-out event → signedOut; a different account signing in wipes the local DB', () async {
    h = AppHarness(
      backend: FakeAuthBackend(
        session: const AuthSession(userId: 'u-1', email: null),
        profileRow: kProfileRowOnboardingDone,
      ),
    );
    await waitFor((s) => s is AuthGateSignedIn);
    await h.container.read(subjectRepositoryProvider).create(name: '수학', colorIndex: 0);
    expect((await h.container.read(subjectRepositoryProvider).getAll()).length, 1);

    h.backend.emitSession(null);
    await h.settle();
    expect(h.container.read(authGateProvider), isA<AuthGateSignedOut>());
    // Sign-out keeps the rows (they belong to u-1 and come back on re-login).
    expect(await h.container.read(accountBindingProvider).current(), 'u-1');

    h.backend
      ..signedInSession = const AuthSession(userId: 'u-2', email: null)
      ..emitSession(const AuthSession(userId: 'u-2', email: null));
    final s = await waitFor((s) => s is AuthGateSignedIn && s.userId == 'u-2');
    expect(s.userId, 'u-2');
    expect(await h.container.read(accountBindingProvider).current(), 'u-2');
    expect(h.container.read(currentUserIdProvider), 'u-2');
    expect(await h.container.read(subjectRepositoryProvider).getAll(), isEmpty, reason: 'wiped on switch');
  });

  group('S05b · offline restart with a cached profile', () {
    late AppDatabase sharedDb;
    AppHarness? second;

    setUp(() => sharedDb = AppDatabase.inMemory());
    tearDown(() async {
      await second?.dispose();
      second = null;
      await sharedDb.close();
    });

    Future<AuthGateState> waitIn(AppHarness hh, bool Function(AuthGateState) test) async {
      for (var i = 0; i < 50; i++) {
        final s = hh.container.read(authGateProvider);
        if (test(s)) return s;
        await Future<void>.delayed(Duration.zero);
      }
      return hh.container.read(authGateProvider);
    }

    test('first run caches the confirmed profile; offline restart → signedIn(ready) from cache, refresh later', () async {
      h = AppHarness(
        db: sharedDb,
        backend: FakeAuthBackend(
          session: const AuthSession(userId: 'u-1', email: null),
          profileRow: kProfileRowOnboardingDone,
        ),
      );
      final first = await waitIn(h, (s) => s is AuthGateSignedIn) as AuthGateSignedIn;
      expect(first.fromCache, isFalse);
      final cached = await h.container.read(profileCacheProvider).read();
      expect(cached?.userId, 'u-1');
      expect(cached?.onboardingDone, isTrue);
      h.container.dispose();

      // Restart: same device, same stored session, server unreachable.
      second = AppHarness(
        db: sharedDb,
        backend: FakeAuthBackend(session: const AuthSession(userId: 'u-1', email: null))
          ..profileError = const NetworkUnavailableException(),
      );
      final s2 = second!;
      final restored = await waitIn(s2, (s) => s is AuthGateSignedIn) as AuthGateSignedIn;
      expect(restored.fromCache, isTrue);
      expect(restored.ready, isTrue, reason: 'home-capable without the server');
      expect(s2.container.read(currentUserIdProvider), 'u-1');
      expect(s2.backend.callNames.where((n) => n == 'fetchProfile').length, 1);

      // Back online: the background refresh replaces the cached profile.
      s2.backend
        ..profileError = null
        ..profileRow = kProfileRowOnboardingPending;
      await s2.container.read(authGateProvider.notifier).refreshProfile();
      final refreshed = s2.container.read(authGateProvider) as AuthGateSignedIn;
      expect(refreshed.fromCache, isFalse);
      expect(refreshed.needsOnboarding, isTrue);
      expect((await s2.container.read(profileCacheProvider).read())?.onboardingDone, isFalse);
    });

    test('no cache + offline → profileError (launch screen keeps the retry)', () async {
      h = AppHarness(
        db: sharedDb,
        backend: FakeAuthBackend(session: const AuthSession(userId: 'u-1', email: null))
          ..profileError = const NetworkUnavailableException(),
      );
      final s = await waitIn(h, (s) => s is AuthGateProfileError) as AuthGateProfileError;
      expect(s.reason, AuthRejection.network);
      expect(await h.container.read(profileCacheProvider).read(), isNull);
    });

    test('cache of u-1, stored session of u-2 → wipe, no cached sign-in, then the normal guard', () async {
      h = AppHarness(
        db: sharedDb,
        backend: FakeAuthBackend(
          session: const AuthSession(userId: 'u-1', email: null),
          profileRow: kProfileRowOnboardingDone,
        ),
      );
      await waitIn(h, (s) => s is AuthGateSignedIn);
      await h.container.read(subjectRepositoryProvider).create(name: '수학', colorIndex: 0);
      h.container.dispose();

      second = AppHarness(
        db: sharedDb,
        backend: FakeAuthBackend(session: const AuthSession(userId: 'u-2', email: null))
          ..profileError = const NetworkUnavailableException(),
      );
      final s2 = second!;
      final offline = await waitIn(s2, (s) => s is AuthGateProfileError);
      expect(offline, isA<AuthGateProfileError>(), reason: 'another account\'s cache is never used');
      expect(await s2.container.read(accountBindingProvider).current(), 'u-2');
      expect(await s2.container.read(subjectRepositoryProvider).getAll(), isEmpty, reason: 'wiped on switch');
      expect(await s2.container.read(profileCacheProvider).read(), isNull);

      s2.backend
        ..profileError = null
        ..profileRow = <String, dynamic>{...kProfileRowOnboardingPending, 'user_id': 'u-2'};
      await s2.container.read(authGateProvider.notifier).retry();
      final online = s2.container.read(authGateProvider) as AuthGateSignedIn;
      expect(online.userId, 'u-2');
      expect(online.needsOnboarding, isTrue);
      expect((await s2.container.read(profileCacheProvider).read())?.userId, 'u-2');
    });
  });

  test('applyProfile updates the state in place', () async {
    h = AppHarness(backend: FakeAuthBackend(session: const AuthSession(userId: 'u-1', email: null)));
    await waitFor((s) => s is AuthGateSignedIn);
    h.container.read(authGateProvider.notifier).applyProfile(
          ProfileSnapshot.fromJson(kProfileRowOnboardingDone),
        );
    expect((h.container.read(authGateProvider) as AuthGateSignedIn).ready, isTrue);
  });
}
