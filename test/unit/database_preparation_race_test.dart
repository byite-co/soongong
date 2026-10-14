import 'dart:async';
import 'dart:io';
import 'dart:isolate';

import 'package:flutter_test/flutter_test.dart';
import 'package:soongong/data/db/app_database.dart';
import 'package:soongong/data/db/database_protection.dart';
import 'package:soongong/data/db/encrypted_database.dart';
import 'package:sqlite3/sqlite3.dart';

/// Secure storage is the only substituted boundary. The second write is held
/// until the first caller has opened and populated the real encrypted executor.
class _OverlappingKeys implements DatabaseKeyStore {
  String? value;
  int writes = 0;
  final releaseSecondWrite = Completer<void>();

  @override
  Future<String?> read() async => value;

  @override
  Future<void> write(String key) async {
    writes++;
    if (writes == 2) {
      await releaseSecondWrite.future;
    }
    value = key;
  }
}

class _HeldKeys implements DatabaseKeyStore {
  final entered = Completer<void>();
  final release = Completer<void>();
  String? value;
  int writes = 0;

  @override
  Future<String?> read() async {
    if (!entered.isCompleted) {
      entered.complete();
      await release.future;
    }
    return value;
  }

  @override
  Future<void> write(String key) async {
    writes++;
    value = key;
  }
}

class _ProbeKeys implements DatabaseKeyStore {
  _ProbeKeys(this.value);
  final String value;
  int reads = 0;
  int writes = 0;

  @override
  Future<String?> read() async {
    reads++;
    return value;
  }

  @override
  Future<void> write(String key) async {
    writes++;
  }
}

Future<List<Object?>> _competingOpener(String path, String key) async {
  final store = _ProbeKeys(key);
  try {
    await prepareDatabaseFile(File(path), store);
    return ['opened', store.reads, store.writes];
  } on DatabaseProtectionException catch (error) {
    return [error.code, store.reads, store.writes];
  }
}

Future<List<Object?>> _spawnCompetingOpener(String path, String key) =>
    Isolate.run(() => _competingOpener(path, key));

Future<Object> _outcome(Future<PreparedDatabase> operation) =>
    operation.then<Object>(
      (value) => value,
      onError: (Object error, StackTrace _) => error,
    );

void main() {
  final key = List.filled(32, '6f').join();
  late Directory directory;
  late File file;
  setUp(() {
    directory = Directory.systemTemp.createTempSync('preparation-race-');
    file = File('${directory.path}/soongong_dev.sqlite');
  });
  tearDown(() => directory.delete(recursive: true));

  test(
    'RC05 another isolate is rejected before key access while preparation holds the lock',
    () async {
      final store = _HeldKeys();
      final first = _outcome(prepareDatabaseFile(file, store));
      await store.entered.future.timeout(const Duration(seconds: 10));
      late Object firstResult;
      try {
        final contender = await _spawnCompetingOpener(
          file.path,
          key,
        ).timeout(const Duration(seconds: 10));
        expect(contender, ['database_busy', 0, 0]);
        expect(file.existsSync(), isFalse);
      } finally {
        store.release.complete();
        firstResult = await first.timeout(const Duration(seconds: 10));
      }
      expect(firstResult, isA<PreparedDatabase>());
      expect(store.writes, 1);
      final prepared = firstResult as PreparedDatabase;
      final app = await requireReadyDatabase(
        AppDatabase(encryptedDatabaseFromPrepared(prepared)),
      );
      await app.close();
      final afterRelease = await _spawnCompetingOpener(file.path, prepared.key);
      expect(afterRelease, ['opened', 1, 0]);
      expect(
        File('${file.path}.encryption.lock').lengthSync(),
        0,
        reason: 'coordination stores no schema, keys, or application records',
      );
    },
  );

  test(
    'RC05 two independent openers never replace the first usable durable key',
    () async {
      final store = _OverlappingKeys();
      final first = _outcome(prepareDatabaseFile(file, store));
      final second = _outcome(prepareDatabaseFile(file, store));
      final firstResult = await first.timeout(const Duration(seconds: 10));
      try {
        expect(firstResult, isA<PreparedDatabase>());
        final prepared = firstResult as PreparedDatabase;
        final app = await requireReadyDatabase(
          AppDatabase(encryptedDatabaseFromPrepared(prepared)),
        );
        try {
          await app.customStatement(
            'CREATE TABLE synthetic_race(id INTEGER PRIMARY KEY, value TEXT)',
          );
          await app.customStatement(
            "INSERT INTO synthetic_race VALUES(1, 'first-acknowledged-write')",
          );
        } finally {
          await app.close();
        }
        store.releaseSecondWrite.complete();
        final secondResult = await second.timeout(const Duration(seconds: 10));
        expect(
          store.value == prepared.key,
          isTrue,
          reason: 'a second opener must not overwrite a key already in use',
        );
        expect(store.writes, 1);
        expect(
          secondResult,
          anyOf(isA<PreparedDatabase>(), isA<DatabaseProtectionException>()),
        );
        // Contention may reject an opener; a fresh preparation must still use
        // the one durable key and recover every acknowledged first write.
        final retry = await prepareDatabaseFile(file, store);
        final reopened = await requireReadyDatabase(
          AppDatabase(encryptedDatabaseFromPrepared(retry)),
        );
        try {
          expect(
            (await reopened
                    .customSelect(
                      'SELECT value FROM synthetic_race WHERE id = 1',
                    )
                    .getSingle())
                .read<String>('value'),
            'first-acknowledged-write',
          );
        } finally {
          await reopened.close();
        }
      } finally {
        if (!store.releaseSecondWrite.isCompleted) {
          store.releaseSecondWrite.complete();
        }
        await second.timeout(const Duration(seconds: 10));
      }
    },
  );

  Database seedPlaintext() {
    final writer = sqlite3.open(file.path);
    writer.execute('CREATE TABLE synthetic_race(id INTEGER PRIMARY KEY)');
    writer.execute('INSERT INTO synthetic_race VALUES(1)');
    writer.execute('PRAGMA busy_timeout = 0');
    return writer;
  }

  test(
    'RC05 an old plaintext writer cannot acknowledge a row omitted by promotion',
    () {
      final writer = seedPlaintext();
      var acknowledged = false;
      try {
        DatabaseProtection(
          file,
          key,
          checkpoint: (stage) {
            if (stage == 'verified') {
              try {
                writer.execute('INSERT INTO synthetic_race VALUES(2)');
                acknowledged = true;
              } on SqliteException catch (error) {
                expect(error.resultCode, 5, reason: 'the writer must be busy');
              }
            }
          },
        ).prepare();
        expect(
          () => writer.execute('INSERT INTO synthetic_race VALUES(3)'),
          throwsA(isA<SqliteException>()),
          reason: 'the stale plaintext handle cannot write after replacement',
        );
      } finally {
        writer.close();
      }
      final encrypted = sqlite3.open(file.path);
      try {
        configureDatabaseCipher(encrypted, key);
        expect(
          encrypted
              .select('SELECT id FROM synthetic_race ORDER BY id')
              .map((row) => row['id'])
              .toList(),
          acknowledged ? [1, 2] : [1],
          reason: 'successfully committed plaintext rows must not disappear',
        );
      } finally {
        encrypted.close();
      }
    },
  );

  test(
    'RC05 verified recovery refuses a source changed after interruption',
    () {
      final writer = seedPlaintext();
      try {
        expect(
          () => DatabaseProtection(
            file,
            key,
            checkpoint: (stage) {
              if (stage == 'verified') {
                throw StateError('synthetic-interruption');
              }
            },
          ).prepare(),
          throwsA(isA<DatabaseProtectionException>()),
        );
        writer.execute('INSERT INTO synthetic_race VALUES(2)');
      } finally {
        writer.close();
      }
      final originalBytes = file.readAsBytesSync();
      final candidate = File('${file.path}.encrypting');
      final candidateBytes = candidate.readAsBytesSync();
      expect(
        () => DatabaseProtection(file, key).prepare(),
        throwsA(isA<DatabaseProtectionException>()),
      );
      expect(file.readAsBytesSync(), originalBytes);
      expect(candidate.readAsBytesSync(), candidateBytes);
      expect(File('${file.path}.plaintext').existsSync(), isFalse);
      expect(File('${file.path}.encryption.json').existsSync(), isTrue);
    },
  );
}
