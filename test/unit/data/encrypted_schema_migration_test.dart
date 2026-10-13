// Real Drift + sqlite3mc regression tests. Faults are deterministic exceptions
// (including a real SQLite query_only write failure), not process/power kills.
import 'dart:io';
import 'dart:typed_data';

import 'package:drift/drift.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soongong/data/db/app_database.dart';
import 'package:soongong/data/db/database_protection.dart';
import 'package:soongong/data/db/encrypted_database.dart';
import 'package:soongong/data/db/study_schema.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite;

class _LegacyDatabase extends AppDatabase {
  _LegacyDatabase(super.executor, this.version);
  final int version;
  @override
  int get schemaVersion => version;
  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      await m.createAll();
      if (version >= 2) {
        for (final sql in AppDatabase.partialUniqueIndexes) {
          await customStatement(sql);
        }
      }
    },
  );
}

enum _Fault {
  afterDdl,
  beforeVersion,
  versionWrite,
  afterVersion,
  afterCommit,
  afterPolicy,
}

class _FaultDatabase extends AppDatabase {
  _FaultDatabase(super.executor, this.fault);
  final _Fault fault;

  @override
  Future<void> customStatement(String statement, [List<Object?>? args]) async {
    if (statement == 'PRAGMA user_version = 3') {
      if (fault == _Fault.beforeVersion)
        throw StateError('injected_before_version');
      if (fault == _Fault.versionWrite) {
        // Real SQLite rejects the version write; the product transaction must
        // roll back the DDL, dedupe, outbox and version on the actual executor.
        await super.customStatement('PRAGMA query_only = ON');
      }
      await super.customStatement(statement, args);
      if (fault == _Fault.afterVersion)
        throw StateError('injected_after_version');
      return;
    }
    await super.customStatement(statement, args);
    if (fault == _Fault.afterDdl && statement == createStudyDocuments) {
      throw StateError('injected_after_ddl');
    }
  }

  @override
  MigrationStrategy get migration {
    final strategy = super.migration;
    return MigrationStrategy(
      onCreate: strategy.onCreate,
      onUpgrade: strategy.onUpgrade,
      beforeOpen: (details) async {
        if (fault == _Fault.afterCommit)
          throw StateError('injected_after_commit');
        await strategy.beforeOpen?.call(details);
        if (fault == _Fault.afterPolicy)
          throw StateError('injected_after_policy');
      },
    );
  }
}

void main() {
  final key = List.filled(32, '3c').join();
  late Directory directory;
  late File file;

  setUp(() {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
    directory = Directory.systemTemp.createTempSync('encrypted-schema-');
    file = File('${directory.path}/soongong_dev.sqlite');
  });
  tearDown(() => directory.delete(recursive: true));

  QueryExecutor executor() =>
      encryptedDatabaseFromPrepared(PreparedDatabase(file.path, key));

  T inspect<T>(T Function(sqlite.Database db) read) {
    final db = sqlite.sqlite3.open(file.path, mode: sqlite.OpenMode.readOnly);
    try {
      configureDatabaseCipher(db, key);
      return read(db);
    } finally {
      db.close();
    }
  }

  Future<void> seed(int version, {bool duplicateReviews = false}) async {
    DatabaseProtection(file, key).prepare();
    final db = _LegacyDatabase(executor(), version);
    try {
      await db.customStatement(
        'CREATE TABLE fixture(id INTEGER PRIMARY KEY AUTOINCREMENT, value TEXT, payload BLOB)',
      );
      await db.customStatement('CREATE INDEX fixture_value ON fixture(value)');
      await db.customStatement(
        'CREATE VIEW fixture_view AS SELECT value FROM fixture',
      );
      await db.customStatement(
        'CREATE TRIGGER fixture_trigger AFTER UPDATE ON fixture BEGIN SELECT 1; END',
      );
      await db.customStatement(
        'INSERT INTO fixture(value,payload) VALUES(?,?)',
        [
          'synthetic 한글\n',
          Uint8List.fromList([0, 255, 31]),
        ],
      );
      await db
          .into(db.syncOutbox)
          .insert(
            SyncOutboxCompanion.insert(
              table: 'subjects',
              rowId: 'pending',
              mutationId: 'fixture-mutation',
              queuedAt: DateTime.utc(2026),
            ),
          );
      if (duplicateReviews) {
        for (final id in ['old', 'new']) {
          await db
              .into(db.reviewEntries)
              .insert(
                ReviewEntriesCompanion.insert(
                  id: id,
                  userId: 'synthetic-owner',
                  createdAt: DateTime.utc(2026),
                  clientUpdatedAt: DateTime.utc(2026, 1, id == 'old' ? 1 : 2),
                  deviceId: 'fixture-device',
                  wrongItemId: 'same-wrong',
                  dueAt: Value(DateTime.utc(2026)),
                  intervalDays: const Value(2),
                ),
              );
        }
      }
    } finally {
      await db.close();
    }
  }

  Future<void> assertReady(AppDatabase db) async {
    await requireReadyDatabase(db);
    expect(
      (await db.customSelect('PRAGMA user_version').getSingle()).read<int>(
        'user_version',
      ),
      3,
    );
    expect(
      (await db.customSelect('PRAGMA journal_mode').getSingle()).read<String>(
        'journal_mode',
      ),
      'delete',
    );
    expect(
      (await db.customSelect('PRAGMA temp_store').getSingle()).read<int>(
        'temp_store',
      ),
      2,
    );
  }

  for (final version in [0, 1, 2]) {
    test(
      'MIG-01/JRN-01 real encrypted opener: v$version, schema/version, data and final policy',
      () async {
        if (version == 0) {
          DatabaseProtection(file, key).prepare();
        } else {
          await seed(version);
        }
        final db = AppDatabase(executor());
        try {
          await assertReady(db);
          final objects = await db
              .customSelect(
                "SELECT name FROM sqlite_master WHERE name='study_documents'",
              )
              .get();
          expect(objects, hasLength(1));
          if (version != 0) {
            final row = await db
                .customSelect('SELECT * FROM fixture')
                .getSingle();
            expect(row.read<String>('value'), 'synthetic 한글\n');
            expect(row.read<Uint8List>('payload'), [0, 255, 31]);
            expect(
              (await db.select(db.syncOutbox).get()).single.mutationId,
              'fixture-mutation',
            );
            expect(
              (await db
                  .customSelect(
                    "SELECT name FROM sqlite_master WHERE name IN ('fixture_value','fixture_view','fixture_trigger')",
                  )
                  .get()),
              hasLength(3),
            );
            await db.customStatement(
              "INSERT INTO fixture(value) VALUES('next')",
            );
            expect(
              (await db
                      .customSelect('SELECT max(id) AS id FROM fixture')
                      .getSingle())
                  .read<int>('id'),
              2,
            );
          }
        } finally {
          await db.close();
        }
        expect(isPlainDatabase(file), isFalse);
        final noKey = sqlite.sqlite3.open(file.path);
        try {
          expect(
            () => noKey.select('SELECT * FROM sqlite_master'),
            throwsA(isA<sqlite.SqliteException>()),
          );
        } finally {
          noKey.close();
        }
      },
    );
  }

  for (final version in [0, 1, 2]) {
    for (final fault in [
      _Fault.afterDdl,
      _Fault.beforeVersion,
      _Fault.versionWrite,
      _Fault.afterVersion,
    ]) {
      test(
        'MIG-02/04 v$version $fault rolls back schema and version; new executor retries',
        () async {
          if (version == 0) {
            DatabaseProtection(file, key).prepare();
          } else {
            await seed(version, duplicateReviews: version == 1);
          }
          final before = inspect(databaseFingerprint);
          await expectLater(
            requireReadyDatabase(_FaultDatabase(executor(), fault)),
            throwsA(isA<DatabaseProtectionException>()),
          );
          expect(inspect(databaseFingerprint), before);
          expect(inspect((db) => db.userVersion), version);
          expect(
            inspect(
              (db) => db.select(
                "SELECT name FROM sqlite_master WHERE name='study_documents'",
              ),
            ),
            isEmpty,
          );
          final retry = AppDatabase(executor());
          try {
            await assertReady(retry);
            if (version == 1) {
              final reviews = await retry.select(retry.reviewEntries).get();
              expect(reviews.singleWhere((r) => r.id == 'old').clientRev, 2);
              expect(reviews.singleWhere((r) => r.id == 'new').clientRev, 1);
              final outbox = await retry.select(retry.syncOutbox).get();
              expect(outbox.where((r) => r.rowId == 'old'), hasLength(1));
            }
          } finally {
            await retry.close();
          }
        },
      );
    }
  }

  for (final version in [0, 1, 2]) {
    for (final fault in [_Fault.afterCommit, _Fault.afterPolicy]) {
      test(
        'MIG-03 v$version $fault leaves completed v3 and retries without duplicate mutation',
        () async {
          if (version == 0) {
            DatabaseProtection(file, key).prepare();
          } else {
            await seed(version, duplicateReviews: version == 1);
          }
          await expectLater(
            requireReadyDatabase(_FaultDatabase(executor(), fault)),
            throwsA(isA<DatabaseProtectionException>()),
          );
          expect(inspect((db) => db.userVersion), 3);
          final committed = inspect(databaseFingerprint);
          final retry = AppDatabase(executor());
          try {
            await assertReady(retry);
          } finally {
            await retry.close();
          }
          expect(
            inspect(databaseFingerprint),
            committed,
            reason: 'no second dedupe, rev bump or outbox mutation',
          );
        },
      );
    }
  }

  test(
    'MIG-05 known partial v2 plus exact study table recovers without changing rows',
    () async {
      await seed(2);
      final raw = sqlite.sqlite3.open(file.path);
      try {
        configureDatabaseCipher(raw, key);
        raw.execute(createStudyDocuments);
        raw.execute(
          "INSERT INTO study_documents(id,user_id,purge_epoch,revision,kind,text,transcription_json,updated_at) VALUES('doc','synthetic-owner',0,1,'text','synthetic','{}','2026-01-01')",
        );
      } finally {
        raw.close();
      }
      final db = AppDatabase(executor());
      try {
        await assertReady(db);
        expect(
          (await db
                  .customSelect('SELECT text FROM study_documents')
                  .getSingle())
              .read<String>('text'),
          'synthetic',
        );
      } finally {
        await db.close();
      }
    },
  );

  final invalidSchemas = <String, List<String>>{
    'same name view': [
      "CREATE VIEW study_documents AS SELECT 'synthetic' AS text",
    ],
    'wrong type': [
      createStudyDocuments.replaceFirst(
        'purge_epoch INTEGER',
        'purge_epoch TEXT',
      ),
    ],
    'missing constraint': [
      createStudyDocuments.replaceFirst(' CHECK (revision > 0)', ''),
    ],
    'extra index': [
      createStudyDocuments,
      'CREATE INDEX unexpected_study_index ON study_documents(text)',
    ],
    'extra trigger': [
      createStudyDocuments,
      'CREATE TRIGGER unexpected_study_trigger AFTER INSERT ON study_documents BEGIN SELECT 1; END',
    ],
  };
  for (final fixture in invalidSchemas.entries) {
    test(
      'MIG-05 rejects ${fixture.key} without changing schema/data/version',
      () async {
        await seed(2);
        final raw = sqlite.sqlite3.open(file.path);
        try {
          configureDatabaseCipher(raw, key);
          for (final sql in fixture.value) {
            raw.execute(sql);
          }
        } finally {
          raw.close();
        }
        final before = file.readAsBytesSync();
        await expectLater(
          requireReadyDatabase(AppDatabase(executor())),
          throwsA(isA<DatabaseProtectionException>()),
        );
        expect(file.readAsBytesSync(), before);
        expect(inspect((db) => db.userVersion), 2);
      },
    );
  }

  test(
    'JRN-02 real encrypted writes and repeated reopen keep DELETE and MEMORY',
    () async {
      DatabaseProtection(file, key).prepare();
      for (var run = 0; run < 3; run++) {
        final db = AppDatabase(executor());
        try {
          await assertReady(db);
          await db.customStatement(
            'INSERT OR REPLACE INTO sync_meta(key,value) VALUES(?,?)',
            ['fixture', '$run'],
          );
        } finally {
          await db.close();
        }
        expect(File('${file.path}-wal').existsSync(), isFalse);
        expect(File('${file.path}-journal').existsSync(), isFalse);
      }
      expect(
        inspect(
          (db) => db
              .select("SELECT value FROM sync_meta WHERE key='fixture'")
              .single['value'],
        ),
        '2',
      );
    },
  );

  test(
    'JRN-01 in-memory DB retains valid memory journal and MEMORY temp store',
    () async {
      final db = AppDatabase.inMemory();
      try {
        await requireReadyDatabase(db);
        expect(
          (await db.customSelect('PRAGMA journal_mode').getSingle())
              .read<String>('journal_mode'),
          'memory',
        );
        expect(
          (await db.customSelect('PRAGMA temp_store').getSingle()).read<int>(
            'temp_store',
          ),
          2,
        );
      } finally {
        await db.close();
      }
    },
  );
}
