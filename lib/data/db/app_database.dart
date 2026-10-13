// AppDatabase (S02 + EXT) — drift, local schema v3. Offline-first: the server is only a
// sync target (CLAUDE.md §2). Single file + `user_id` column; the whole file
// is wiped on account switch / purge / epoch mismatch. Logout preserves DB
// records and the device encryption key (the current S09 implementation).
//
// Schema changes: never edit an existing migration — bump [schemaVersion],
// add a step in [migration] and mark the PR `SCHEMA-CHANGE` (D27).

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:uuid/uuid.dart';

// The generated part references the wire enums and converters directly.
import '../../core/domain/enums.dart';
import 'converters.dart';
import 'database_protection.dart';
import 'encrypted_database.dart';
import 'purge_gate.dart';
import 'study_schema.dart';
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
  /// S09c: in-memory mirror of `sync_meta.purge_generation` (see `PurgeGate`).
  final PurgeGate purgeGate = PurgeGate();

  AppDatabase(super.executor);

  /// On-device encrypted database (sqlite3mc native assets, background Drift).
  AppDatabase.open({required String flavor})
    : super(encryptedDatabase(databaseNameFor(flavor)));

  /// In-memory database for unit tests and the widget catalog.
  AppDatabase.inMemory() : super(NativeDatabase.memory());

  /// v1 — S02 tables. v2 — S02c: partial unique index on
  /// `review_entries(wrong_item_id) WHERE deleted_at IS NULL` (SCHEMA-CHANGE).
  @override
  int get schemaVersion => 3;

  /// Partial unique indexes (drift `@TableIndex` cannot express `WHERE`).
  /// Same statements in the S03 DDL (docs/data-model.md §4).
  static const List<String> partialUniqueIndexes = <String>[
    'CREATE UNIQUE INDEX IF NOT EXISTS review_entries_live_wrong_item '
        'ON review_entries (wrong_item_id) WHERE deleted_at IS NULL',
  ];

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) => transaction(() async {
      await m.createAll();
      await _ensureStudyDocuments();
      for (final sql in partialUniqueIndexes) {
        await customStatement(sql);
      }
      await customStatement('PRAGMA user_version = $schemaVersion');
    }),
    onUpgrade: (m, from, to) => transaction(() async {
      if (from < 3) await _ensureStudyDocuments();
      if (from < 2) {
        await _dedupeLiveReviewEntries();
        for (final sql in partialUniqueIndexes) {
          await customStatement(sql);
        }
      }
      // Drift 2.35 writes this again AFTER beforeOpen. Persist it here,
      // with the schema, so a later failure cannot leave v3 tables at v2.
      await customStatement('PRAGMA user_version = $to');
    }),
    beforeOpen: (details) async {
      await customStatement('PRAGMA foreign_keys = OFF');
      // Journal changes cannot run inside the schema transaction. This
      // is the sole runtime journal policy, including the encrypted opener.
      final databases = await customSelect('PRAGMA database_list').get();
      final main = databases.singleWhere(
        (row) => row.read<String>('name') == 'main',
      );
      final memory = main.read<String>('file').isEmpty;
      final journal = await customSelect(
        'PRAGMA journal_mode = DELETE',
      ).getSingle();
      if (journal.read<String>('journal_mode') !=
          (memory ? 'memory' : 'delete')) {
        throw const DatabaseProtectionException('journal_policy_failed');
      }
      await customStatement('PRAGMA temp_store = MEMORY');
      final temporary = await customSelect('PRAGMA temp_store').getSingle();
      if (temporary.read<int>('temp_store') != 2) {
        throw const DatabaseProtectionException('temp_policy_failed');
      }
    },
  );

  /// Recover only the exact v3 object an older non-atomic upgrade could leave.
  /// DDL comparison includes constraints; checking column names alone would
  /// accept a different table. Extra indexes/triggers are deliberately refused.
  Future<void> _ensureStudyDocuments() async {
    final objects = await customSelect(
      "SELECT type,name,sql FROM sqlite_master "
      "WHERE name='study_documents' OR tbl_name='study_documents'",
    ).get();
    if (objects.isEmpty) {
      await customStatement(createStudyDocuments);
      return;
    }
    String normalize(String sql) => sql.replaceAll(RegExp(r'\s+'), ' ').trim();
    final tables = objects.where((row) => row.read<String>('type') == 'table');
    final indexes = objects.where((row) => row.read<String>('type') == 'index');
    if (objects.length != 2 ||
        tables.length != 1 ||
        indexes.length != 1 ||
        tables.single.read<String>('name') != 'study_documents' ||
        normalize(tables.single.readNullable<String>('sql') ?? '') !=
            normalize(createStudyDocuments) ||
        indexes.single.read<String>('name') !=
            'sqlite_autoindex_study_documents_1' ||
        indexes.single.readNullable<String>('sql') != null) {
      throw const DatabaseProtectionException('study_schema_mismatch');
    }
  }

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
    await customStatement('DELETE FROM study_documents');
    for (final t in allTables) {
      await delete(t).go();
    }
  });

  /// ISO UTC string helper re-exported for callers building raw SQL.
  static String iso(DateTime t) => utcIso(t);
}

/// Force migrations before repository/auth startup. Drift caches an open error
/// on its executor: close that instance and let a retry create a fresh one.
Future<AppDatabase> requireReadyDatabase(AppDatabase database) async {
  try {
    await database.customSelect('SELECT 1').get();
    return database;
  } catch (_) {
    try {
      await database.close();
    } catch (_) {
      /* Preserve the original file. */
    }
    throw const DatabaseProtectionException('schema_open_failed');
  }
}
