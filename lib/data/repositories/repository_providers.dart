// Repository providers (S02 · S05). Feature sessions read these; they never
// touch the database directly. `appDatabaseProvider` is overridden with an
// in-memory database in tests. `currentUserIdProvider` follows the auth gate
// (S05): the signed-in `auth.uid`, or `kLocalUserId` in a dev build without
// backend config (the DB is bound to one account and wiped on switch, D27).

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../core/config/app_config.dart';
import '../../core/contracts/providers.dart';
import '../../core/domain/clock.dart';
import '../auth/auth_gate.dart';
import '../db/app_database.dart';
import 'activity_repository.dart';
import 'delete_settler.dart';
import 'planner_repository.dart';
import 'quota_repository.dart';
import 'reading_repository.dart';
import 'review_repository.dart';
import 'session_repository.dart';
import 'settings_repository.dart';
import 'subject_repository.dart';
import 'subscription_repository.dart';
import 'sync_writer.dart';
import 'write_context.dart';
import 'wrongs_repository.dart';

part 'repository_providers.g.dart';

/// User id of a dev build without backend config (no auth). Equals
/// [kLocalOnlyUserId]; kept for S02 callers.
const String kLocalUserId = kLocalOnlyUserId;

@Riverpod(keepAlive: true)
AppDatabase appDatabase(Ref ref) {
  final db = AppDatabase.open(flavor: AppConfig.flavor.name);
  ref.onDispose(db.close);
  return db;
}

/// The user every repository writes under. Signed out → [kLocalUserId] as a
/// placeholder; nothing user-facing runs then (the router guard holds the
/// app on the gate), and the startup/foreground tasks skip their writes.
@Riverpod(keepAlive: true)
String currentUserId(Ref ref) => ref.watch(authGateProvider).userId ?? kLocalUserId;

@Riverpod(keepAlive: true)
Clock appClock(Ref ref) => const SystemClock();

@Riverpod(keepAlive: true)
WriteContext writeContext(Ref ref) => WriteContext(
      userId: ref.watch(currentUserIdProvider),
      deviceId: ref.watch(deviceIdProvider),
      clock: ref.watch(appClockProvider),
    );

@Riverpod(keepAlive: true)
SyncWriter syncWriter(Ref ref) =>
    SyncWriter(ref.watch(appDatabaseProvider), ref.watch(writeContextProvider));

@Riverpod(keepAlive: true)
SubjectRepository subjectRepository(Ref ref) =>
    SubjectRepository(ref.watch(appDatabaseProvider), ref.watch(syncWriterProvider));

@Riverpod(keepAlive: true)
SessionRepository sessionRepository(Ref ref) =>
    SessionRepository(ref.watch(appDatabaseProvider), ref.watch(syncWriterProvider));

@Riverpod(keepAlive: true)
PlannerRepository plannerRepository(Ref ref) =>
    PlannerRepository(ref.watch(appDatabaseProvider), ref.watch(syncWriterProvider));

@Riverpod(keepAlive: true)
ReadingRepository readingRepository(Ref ref) =>
    ReadingRepository(ref.watch(appDatabaseProvider), ref.watch(syncWriterProvider));

@Riverpod(keepAlive: true)
WrongsRepository wrongsRepository(Ref ref) =>
    WrongsRepository(ref.watch(appDatabaseProvider), ref.watch(syncWriterProvider));

@Riverpod(keepAlive: true)
ReviewRepository reviewRepository(Ref ref) =>
    ReviewRepository(ref.watch(appDatabaseProvider), ref.watch(syncWriterProvider));

@Riverpod(keepAlive: true)
SettingsRepository settingsRepository(Ref ref) =>
    SettingsRepository(ref.watch(appDatabaseProvider), ref.watch(syncWriterProvider));

@Riverpod(keepAlive: true)
SubscriptionRepository subscriptionRepository(Ref ref) =>
    SubscriptionRepository(ref.watch(appDatabaseProvider), ref.watch(writeContextProvider));

@Riverpod(keepAlive: true)
QuotaRepository quotaRepository(Ref ref) =>
    QuotaRepository(ref.watch(appDatabaseProvider), ref.watch(writeContextProvider));

@Riverpod(keepAlive: true)
ActivityRepository activityRepository(Ref ref) =>
    ActivityRepository(ref.watch(appDatabaseProvider), ref.watch(syncWriterProvider));

@Riverpod(keepAlive: true)
DeleteSettler deleteSettler(Ref ref) => DeleteSettler(
      db: ref.watch(appDatabaseProvider),
      ctx: ref.watch(writeContextProvider),
      subjects: ref.watch(subjectRepositoryProvider),
      sessions: ref.watch(sessionRepositoryProvider),
      planner: ref.watch(plannerRepositoryProvider),
    );
