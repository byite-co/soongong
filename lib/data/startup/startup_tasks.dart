// Startup tasks (S02 · S05 · S05b).
//
// App-level (bootstrap, before the first frame): dev subject seed, then the
// per-user listener below is attached.
//
// Per-user (`UserStartupTasks.ensureRunFor`), once per app run per account:
//   1. D22 settlement of pending deletes (expired → commit, else restore)
//   2. D15 `activity_days` upsert for today
//   3. D23 unfinished-session detection (logged; the home sheet asks)
// It runs from ONE listener on the auth gate — a restored session
// (Loading → signedIn) and a manual login (`PostLoginRoutine`) both reach the
// same function; the second caller for the same user is a no-op.
// A failure is logged and never blocks the app.

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../core/config/app_config.dart';
import '../../core/contracts/providers.dart';
import '../../core/domain/ids.dart';
import '../../core/domain/local_date.dart';
import '../../core/logging/app_logger.dart';
import '../../features/home/domain/recovery_candidate.dart';
import '../../features/privacy/application/photo_retention.dart';
import '../../features/privacy/application/privacy_providers.dart';
import '../../features/settings/application/notification_scheduler.dart';
import '../auth/auth_gate.dart';
import '../repositories/repositories.dart';
import '../seed/dev_seeder.dart';

part 'startup_tasks.g.dart';

class StartupReport {
  const StartupReport({
    required this.userId,
    required this.committed,
    required this.restored,
    required this.activityCreated,
    required this.recoveryPending,
  });

  final String userId;
  final int committed;
  final int restored;
  final bool activityCreated;
  final bool recoveryPending;
}

class UserStartupTasks {
  UserStartupTasks(this._ref);

  final Ref _ref;
  final Set<String> _done = <String>{};
  final Map<String, Future<StartupReport?>> _inFlight = <String, Future<StartupReport?>>{};

  /// Users whose startup tasks ran in this app run.
  Set<String> get ranFor => Set<String>.unmodifiable(_done);

  /// Runs the per-user tasks once for [userId]; later calls return the same
  /// future (while running) or null (already done).
  Future<StartupReport?> ensureRunFor(String userId) {
    if (_done.contains(userId)) return Future<StartupReport?>.value();
    final running = _inFlight[userId];
    if (running != null) return running;
    // Block body on purpose: returning the removed Future from whenComplete
    // would make the returned future wait on itself.
    final future = _run(userId).whenComplete(() {
      _inFlight.remove(userId);
    });
    _inFlight[userId] = future;
    return future;
  }

  Future<StartupReport?> _run(String userId) async {
    _done.add(userId);
    try {
      final settled = await _ref.read(deleteSettlerProvider).settle();
      // S09: expired photos (D14 row 3) and the notification plan; S09b: a
      // local purge left pending (server already purged) is completed.
      final expiredPhotos = await _ref.read(photoRetentionProvider).purgeExpired();
      final pendingPurge = await _ref.read(privacyActionsProvider).completePending();
      if (pendingPurge != null) appLog.i('startup · pending local purge → ${pendingPurge.runtimeType}');
      _ref.read(notificationSchedulerProvider).start();
      final today = LocalDate.of(_ref.read(appClockProvider).now());
      final created = await _ref.read(activityRepositoryProvider).touch(today);
      final sessions = _ref.read(sessionRepositoryProvider);
      final candidate = RecoveryCandidate.detect(
        snapshot: await sessions.readSnapshot(),
        sessions: await sessions.getAll(),
        newId: newUuid,
        deviceId: _ref.read(deviceIdProvider),
      );
      final report = StartupReport(
        userId: userId,
        committed: settled.toCommit.length,
        restored: settled.toRestore.length,
        activityCreated: created,
        recoveryPending: candidate != null,
      );
      appLog.i(
        'startup · pending deletes committed=${report.committed} restored=${report.restored} '
        'activityCreated=${report.activityCreated} recoveryPending=${report.recoveryPending} '
        'expiredPhotos=$expiredPhotos',
      );
      return report;
    } on Object catch (e, st) {
      appLog.e('startup tasks failed', error: e, stackTrace: st);
      return null;
    }
  }
}

@Riverpod(keepAlive: true)
UserStartupTasks userStartupTasks(Ref ref) => UserStartupTasks(ref);

/// Bootstrap entry: dev seed, then the gate listener that runs the per-user
/// tasks whenever a user becomes available (restored session, local-only
/// build, or a login later in the run). Tests call this too.
Future<void> runStartupTasks(ProviderContainer container) async {
  if (AppConfig.isDev) {
    try {
      await container.read(devSeederProvider).seedSubjects();
    } on Object catch (e, st) {
      appLog.e('dev seed failed', error: e, stackTrace: st);
    }
  }
  attachStartupListener(container);
}

/// Listens to the auth gate and runs [UserStartupTasks.ensureRunFor] on every
/// transition into a signed-in / local-only state.
ProviderSubscription<AuthGateState> attachStartupListener(ProviderContainer container) {
  return container.listen<AuthGateState>(
    authGateProvider,
    (_, next) {
      final userId = next.userId;
      if (userId == null) {
        if (next is AuthGateSignedOut) {
          appLog.i('startup · no signed-in user, user writes deferred');
        }
        return;
      }
      unawaited(container.read(userStartupTasksProvider).ensureRunFor(userId));
    },
    fireImmediately: true,
  );
}
