// AppDatabase (S02) — drift, schema v1. Offline-first: the server is only a
// sync target (CLAUDE.md §2). Single file + `user_id` column; the whole file
// is wiped on account switch / logout / purge / epoch mismatch (D27 · D2).
//
// Schema changes: never edit an existing migration — bump [schemaVersion],
// add a step in [migration] and mark the PR `SCHEMA-CHANGE` (D27).

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:uuid/uuid.dart';

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

  /// v1 — S02 tables. v2 — S02c: partial unique index on
  /// `review_entries(wrong_item_id) WHERE deleted_at IS NULL` (SCHEMA-CHANGE).
  @override
  int get schemaVersion => 2;

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
        onUpgrade: (m, from, to) async {
          if (from < 2) {
            // The unique index cannot be created while duplicates exist.
            await _dedupeLiveReviewEntries();
            for (final sql in partialUniqueIndexes) {
              await customStatement(sql);
            }
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

  /// v1 → v2: keeps, per `wrong_item_id`, the live entry with the latest
  /// `client_updated_at` (ties: lowest id) and turns the others into
  /// tombstones (content NULL, rev + 1) with an outbox entry so the server
  /// converges too. Returns the ids that were tombstoned.
  Future<List<String>> _dedupeLiveReviewEntries() async {
    final rows = await customSelect(
      'SELECT id, wrong_item_id FROM review_entries WHERE deleted_at IS NULL '
      'ORDER BY wrong_item_id, client_updated_at DESC, id ASC',
    ).get();
    final seen = <String>{};
    final losers = <String>[];
    for (final r in rows) {
      if (!seen.add(r.read<String>('wrong_item_id'))) {
        losers.add(r.read<String>('id'));
      }
    }
    if (losers.isEmpty) return losers;
    final now = utcIso(DateTime.now());
    for (final id in losers) {
      await customStatement(
        'UPDATE review_entries SET due_at = NULL, interval_days = NULL, '
        'consecutive_correct = NULL, last_result = NULL, deleted_at = ?, '
        'client_updated_at = ?, client_rev = client_rev + 1 WHERE id = ?',
        [now, now, id],
      );
      await customStatement(
        'INSERT OR REPLACE INTO sync_outbox '
        '(table_name, row_id, mutation_id, sent_client_rev, queued_at, attempts, last_error) '
        "VALUES ('review_entries', ?, ?, NULL, ?, 0, NULL)",
        [id, const Uuid().v4(), now],
      );
    }
    return losers;
  }

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
