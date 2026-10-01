// AppDatabase (S02) — drift, schema v1. Offline-first: the server is only a
// sync target (CLAUDE.md §2). Single file + `user_id` column; the whole file
// is wiped on account switch / logout / purge / epoch mismatch (D27 · D2).
//
// Schema changes: never edit an existing migration — bump [schemaVersion],
// add a step in [migration] and mark the PR `SCHEMA-CHANGE` (D27).

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:drift_flutter/drift_flutter.dart';

// The generated part references the wire enums and converters directly.
import '../../core/domain/enums.dart';
import 'converters.dart';
import 'tables.dart';

export 'converters.dart';
export 'tables.dart';

part 'app_database.g.dart';

/// Database file name (dev flavor gets its own file so a dev build never
/// opens a prod database on the same device).
String databaseNameFor(String flavor) => 'soongong_$flavor';

@DriftDatabase(
  tables: [
    Subjects,
    Sessions,
    SessionSegments,
    Corrections,
    PlannerItems,
    Recurrences,
    ReadingRequests,
    WrongItems,
    ReviewEntries,
    RetryRecords,
    Settings,
    ActivityDays,
    SubscriptionStates,
    ReadingQuotas,
    Photos,
    SyncOutbox,
    SyncMeta,
    SyncConflicts,
    SessionSnapshots,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.executor);

  /// On-device database (sqlite3 via native assets, drift_flutter).
  AppDatabase.open({required String flavor})
      : super(driftDatabase(name: databaseNameFor(flavor)));

  /// In-memory database for unit tests and the widget catalog.
  AppDatabase.inMemory() : super(NativeDatabase.memory());

  @override
  int get schemaVersion => 1;

  /// Partial unique indexes (drift `@TableIndex` cannot express `WHERE`).
  /// Same statements in the S03 DDL (docs/data-model.md §4).
  static const List<String> partialUniqueIndexes = <String>[
    'CREATE UNIQUE INDEX IF NOT EXISTS review_entries_live_wrong_item '
        'ON review_entries (wrong_item_id) WHERE deleted_at IS NULL',
  ];

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
          for (final sql in partialUniqueIndexes) {
            await customStatement(sql);
          }
        },
        beforeOpen: (details) async {
          await customStatement('PRAGMA foreign_keys = OFF');
          await customStatement('PRAGMA journal_mode = WAL');
        },
      );

  /// Sync tables in dependency order (parents first). Used by the export,
  /// `applyServer` and the full wipe.
  List<TableInfo<Table, Object?>> get syncTables => [
        subjects,
        sessions,
        sessionSegments,
        corrections,
        plannerItems,
        recurrences,
        readingRequests,
        wrongItems,
        reviewEntries,
        retryRecords,
        settings,
        activityDays,
      ];

  /// Deletes every row of every table (account switch · logout · purge-all ·
  /// epoch mismatch, D27 · D2). Photo files are deleted by the caller.
  Future<void> wipeAll() => transaction(() async {
        for (final t in allTables) {
          await delete(t).go();
        }
      });

  /// ISO UTC string helper re-exported for callers building raw SQL.
  static String iso(DateTime t) => utcIso(t);
}
