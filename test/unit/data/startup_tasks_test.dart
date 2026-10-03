// Per-user startup tasks (S05b): a restored session (no login button) runs
// the D22 settlement and the activity-day upsert exactly once, through the
// same `UserStartupTasks.ensureRunFor` the manual login path calls.

import 'package:drift/drift.dart' as drift;
import 'package:flutter_test/flutter_test.dart';
import 'package:soongong/core/domain/local_date.dart';
import 'package:soongong/data/auth/auth_gate.dart';
import 'package:soongong/data/auth/auth_models.dart';
import 'package:soongong/data/repositories/repositories.dart';
import 'package:soongong/data/startup/startup_tasks.dart';

import '../../helpers/app_harness.dart';
import '../../helpers/fake_auth_backend.dart';

void main() {
  late AppHarness h;

  tearDown(() => h.dispose());

  Future<Map<String, Object?>?> raw(String id) async {
    final r = await h.db
        .customSelect('SELECT deleted_at, pending_delete_until, name FROM subjects WHERE id = ?',
            variables: [drift.Variable<String>(id)])
        .getSingleOrNull();
    return r?.data;
  }

  test('restored session → settle: expired pending delete committed, fresh one restored; activity day touched; runs once', () async {
    h = AppHarness(
      backend: FakeAuthBackend(
        session: const AuthSession(userId: 'u-1', email: null),
        profileRow: kProfileRowOnboardingDone,
      ),
    );
    final subjects = h.container.read(subjectRepositoryProvider);
    final expired = await subjects.create(name: '만료', colorIndex: 1);
    final fresh = await subjects.create(name: '유지', colorIndex: 2);
    await subjects.softDelete(expired.id); // pending until T+5s
    h.clock.advance(const Duration(seconds: 10));
    await subjects.softDelete(fresh.id); // pending until T+15s, now = T+10s
    expect((await h.container.read(deleteSettlerProvider).pending()).length, 2);

    // What bootstrap does: attach the listener; the gate resolves the stored
    // session on its own and the listener runs the tasks.
    await runStartupTasks(h.container);
    for (var i = 0; i < 100 && !h.container.read(userStartupTasksProvider).ranFor.contains('u-1'); i++) {
      await Future<void>.delayed(Duration.zero);
    }
    await h.settle(40);

    expect(h.container.read(authGateProvider), isA<AuthGateSignedIn>());
    expect(h.container.read(userStartupTasksProvider).ranFor, contains('u-1'));
    expect(await h.container.read(deleteSettlerProvider).pending(), isEmpty);

    final gone = await raw(expired.id);
    expect(gone?['deleted_at'], isNotNull, reason: 'expired window → committed (tombstone)');
    expect(gone?['name'], isNull);
    final kept = await raw(fresh.id);
    expect(kept?['deleted_at'], isNull, reason: 'window still open → restored');
    expect(kept?['pending_delete_until'], isNull);

    final today = LocalDate.of(h.clock.now());
    final days = await h.container.read(activityRepositoryProvider).watchBetween(today, today).first;
    expect(days.length, 1);

    // Second caller (manual-login path) is a no-op for the same user.
    expect(await h.container.read(userStartupTasksProvider).ensureRunFor('u-1'), isNull);
  });

  test('signed out at launch: nothing runs until a user appears', () async {
    h = AppHarness();
    await runStartupTasks(h.container);
    await h.settle();
    expect(h.container.read(userStartupTasksProvider).ranFor, isEmpty);
    h.backend
      ..profileRow = kProfileRowOnboardingDone
      ..signedInSession = const AuthSession(userId: 'u-9', email: null)
      ..emitSession(const AuthSession(userId: 'u-9', email: null));
    for (var i = 0; i < 100 && !h.container.read(userStartupTasksProvider).ranFor.contains('u-9'); i++) {
      await Future<void>.delayed(Duration.zero);
    }
    expect(h.container.read(userStartupTasksProvider).ranFor, contains('u-9'));
  });
}
