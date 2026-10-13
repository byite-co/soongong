import 'dart:async';
import 'dart:io';

import 'package:drift/drift.dart' show MigrationStrategy;
import 'package:flutter_test/flutter_test.dart';
import 'package:soongong/data/db/app_database.dart';
import 'package:soongong/data/db/database_protection.dart';
import 'package:soongong/data/db/encrypted_database.dart';
import 'package:sqlite3/sqlite3.dart';

class _MemoryKeys implements DatabaseKeyStore {
  _MemoryKeys([this.value]);
  String? value;
  int writes = 0;
  @override
  Future<String?> read() async => value;
  @override
  Future<void> write(String key) async {
    writes++;
    value = key;
  }
}

class _FailingSchemaOpen extends AppDatabase {
  _FailingSchemaOpen(super.executor);
  @override
  MigrationStrategy get migration {
    final strategy = super.migration;
    return MigrationStrategy(
      onCreate: strategy.onCreate,
      onUpgrade: strategy.onUpgrade,
      beforeOpen: (_) async {
        throw StateError('injected_schema_open_failure');
      },
    );
  }
}

void main() {
  final key = List.filled(32, '4d').join();
  late Directory directory;
  late File file;
  setUp(() {
    directory = Directory.systemTemp.createTempSync('creation-protection-');
    file = File('${directory.path}/soongong_dev.sqlite');
  });
  tearDown(() => directory.delete(recursive: true));

  Map<String, List<int>> files() => {
    for (final entry in directory.listSync().whereType<File>())
      entry.uri.pathSegments.last: entry.readAsBytesSync(),
  };

  void seed() {
    DatabaseProtection(file, key).prepare();
    final db = sqlite3.open(file.path);
    try {
      configureDatabaseCipher(db, key);
      db.execute('CREATE TABLE fixture(id INTEGER PRIMARY KEY, value TEXT)');
      db.execute("INSERT INTO fixture VALUES(1, 'synthetic-sensitive-marker')");
    } finally {
      db.close();
    }
  }

  test(
    'DB-01 existing ciphertext truncated to zero is preserved and does not write key',
    () async {
      seed();
      final store = _MemoryKeys(key);
      file.writeAsBytesSync([]);
      final before = files();
      await expectLater(
        prepareDatabaseFile(file, store),
        throwsA(isA<DatabaseProtectionException>()),
      );
      expect(file.lengthSync(), 0);
      expect(files(), before);
      expect(store.writes, 0);
      expect(store.value == key, isTrue);
      // The lower-level migration entry point must enforce the same boundary.
      expect(
        () => DatabaseProtection(file, key).prepare(),
        throwsA(isA<DatabaseProtectionException>()),
      );
      expect(file.lengthSync(), 0);
    },
  );

  test(
    'DB-02 existing empty file without key creates neither key nor database',
    () async {
      file.writeAsBytesSync([]);
      final store = _MemoryKeys();
      final before = files();
      await expectLater(
        prepareDatabaseFile(file, store),
        throwsA(isA<DatabaseProtectionException>()),
      );
      expect(files(), before);
      expect(store.value, isNull);
      expect(store.writes, 0);
    },
  );

  test(
    'DB-03 absent file with durable new key reaches real encrypted Drift schema',
    () async {
      final store = _MemoryKeys();
      final prepared = await prepareDatabaseFile(file, store);
      expect(store.writes, 1);
      expect(store.value == prepared.key, isTrue);
      expect(isPlainDatabase(file), isFalse);
      final app = await requireReadyDatabase(
        AppDatabase(encryptedDatabaseFromPrepared(prepared)),
      );
      try {
        expect(
          (await app.customSelect('PRAGMA user_version').getSingle()).read<int>(
            'user_version',
          ),
          4,
        );
      } finally {
        await app.close();
      }
      final noKey = sqlite3.open(file.path);
      try {
        expect(
          () => noKey.select('SELECT * FROM sqlite_master'),
          throwsA(isA<SqliteException>()),
        );
      } finally {
        noKey.close();
      }
      await prepareDatabaseFile(file, store);
      expect(store.writes, 1, reason: 'normal restart reuses the durable key');
    },
  );

  test(
    'DB-01 successful preparation is not reused after failed schema open',
    () async {
      final store = _MemoryKeys(key);
      final preparations = DatabasePreparations();
      var calls = 0;
      Future<PreparedDatabase> prepare() => preparations.run('synthetic', () {
        calls++;
        return prepareDatabaseFile(file, store);
      });
      final prepared = await prepare();
      await expectLater(
        requireReadyDatabase(
          _FailingSchemaOpen(encryptedDatabaseFromPrepared(prepared)),
        ),
        throwsA(isA<DatabaseProtectionException>()),
      );
      // The failed executor has closed. Damage after successful preparation
      // must be seen by bootstrap's next preparation, before any new schema SQL.
      file.writeAsBytesSync([]);
      final before = files();
      await expectLater(prepare(), throwsA(isA<DatabaseProtectionException>()));
      expect(calls, 2);
      expect(files(), before);
      expect(file.lengthSync(), 0);
      expect(store.writes, 0);
      expect(store.value == key, isTrue);
    },
  );

  for (final damage in ['empty', 'missing']) {
    test(
      'DB-01 stale prepared executor refuses $damage file at first query',
      () async {
        final store = _MemoryKeys(key);
        final prepared = await prepareDatabaseFile(file, store);
        final original = file.readAsBytesSync();
        final app = AppDatabase(encryptedDatabaseFromPrepared(prepared));
        // The public production opener must re-check even when its caller skips
        // preparation and retains an old descriptor/executor across a retry.
        if (damage == 'empty') {
          file.writeAsBytesSync([]);
        } else {
          file.deleteSync();
        }
        final before = files();
        await expectLater(
          requireReadyDatabase(app),
          throwsA(isA<DatabaseProtectionException>()),
        );
        expect(files(), before);
        expect(store.writes, 0);
        expect(store.value == key, isTrue);

        // Only fixture restoration makes the file usable again; the guard did
        // not replace it. A fresh real executor can then open the same key.
        file.writeAsBytesSync(original);
        final restored = await requireReadyDatabase(
          AppDatabase(encryptedDatabaseFromPrepared(prepared)),
        );
        expect(
          (await restored.customSelect('PRAGMA user_version').getSingle())
              .read<int>('user_version'),
          4,
        );
        await restored.close();
      },
    );
  }

  test(
    'DB-03 preparation joins only concurrent work and revalidates later success',
    () async {
      final store = _MemoryKeys();
      final preparations = DatabasePreparations();
      final release = Completer<void>();
      var calls = 0;
      Future<PreparedDatabase> prepare() =>
          preparations.run('synthetic', () async {
            calls++;
            await release.future;
            return prepareDatabaseFile(file, store);
          });
      final first = prepare();
      final concurrent = prepare();
      expect(identical(first, concurrent), isTrue);
      expect(calls, 1);
      release.complete();
      final prepared = await first;
      expect(identical(prepared, await concurrent), isTrue);
      final later = await prepare();
      expect(calls, 2);
      expect(identical(prepared, later), isFalse);
      expect(store.writes, 1);
      final app = await requireReadyDatabase(
        AppDatabase(encryptedDatabaseFromPrepared(later)),
      );
      await app.close();
      expect(isPlainDatabase(file), isFalse);
    },
  );

  for (final stage in [
    'creating',
    'created_empty',
    'created_encrypted',
    'creation_verified',
  ]) {
    test(
      'DB-04 first creation exception at $stage resumes only an absent or valid encrypted file',
      () async {
        final store = _MemoryKeys(key);
        expect(
          () => DatabaseProtection(
            file,
            key,
            checkpoint: (current) {
              if (stage == current) {
                throw StateError('injected_creation_interruption');
              }
            },
          ).prepare(),
          throwsA(isA<DatabaseProtectionException>()),
        );
        if (stage == 'created_empty') {
          expect(file.existsSync(), isTrue);
          expect(file.lengthSync(), 0);
          final before = files();
          await expectLater(
            prepareDatabaseFile(file, store),
            throwsA(isA<DatabaseProtectionException>()),
          );
          expect(
            files(),
            before,
            reason: 'ambiguous existing file is never reset',
          );
        } else {
          if (stage == 'creating') {
            expect(file.existsSync(), isFalse);
          } else {
            expect(file.lengthSync(), greaterThan(0));
            expect(isPlainDatabase(file), isFalse);
          }
          final prepared = await prepareDatabaseFile(file, store);
          final app = await requireReadyDatabase(
            AppDatabase(encryptedDatabaseFromPrepared(prepared)),
          );
          await app.close();
        }
        expect(store.writes, 0);
        expect(store.value == key, isTrue);
      },
    );
  }

  for (final fault in [
    'wrong-key',
    'missing-key',
    'truncated-nonzero',
    'bad-marker',
    'unknown-marker',
    'orphan-copy',
    'temporary-marker',
  ]) {
    test(
      'DB-05/06 real codec $fault preserves files and never generates key',
      () async {
        seed();
        final store = _MemoryKeys(key);
        switch (fault) {
          case 'wrong-key':
            store.value = List.filled(32, '5e').join();
          case 'missing-key':
            store.value = null;
          case 'truncated-nonzero':
            file.writeAsBytesSync(file.readAsBytesSync().sublist(0, 17));
          case 'bad-marker':
            File(
              '${file.path}.encryption.json',
            ).writeAsStringSync('malformed-marker');
          case 'unknown-marker':
            File(
              '${file.path}.encryption.json',
            ).writeAsStringSync('{"version":99,"stage":"verified"}');
          case 'orphan-copy':
            File(
              '${file.path}.encrypting',
            ).writeAsStringSync('synthetic-orphan');
          case 'temporary-marker':
            File(
              '${file.path}.encryption.json.tmp',
            ).writeAsStringSync('incomplete-marker');
        }
        final before = files();
        await expectLater(
          prepareDatabaseFile(file, store),
          throwsA(isA<DatabaseProtectionException>()),
        );
        expect(files(), before);
        expect(store.writes, 0);
      },
    );
  }
}
