import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:soongong/data/db/database_protection.dart';

class _Keys implements DatabaseKeyStore {
  String? value;
  bool persist = true;
  int writes = 0;
  @override
  Future<String?> read() async => value;
  @override
  Future<void> write(String key) async { writes++; if (persist) value = key; }
}

void main() {
  final key = List.filled(32, '1a').join();
  late Directory directory;
  late File file;
  setUp(() { directory = Directory.systemTemp.createTempSync('db-protection-test-'); file = File('${directory.path}/soongong_dev.sqlite'); });
  tearDown(() { directory.deleteSync(recursive: true); });

  String seed() {
    final db = sqlite3.open(file.path);
    try {
      db.execute('PRAGMA user_version = 3');
      db.execute('CREATE TABLE sync_outbox(id INTEGER PRIMARY KEY, payload TEXT, binary BLOB)');
      db.execute('CREATE TABLE study_documents(id TEXT PRIMARY KEY, text TEXT)');
      db.execute('CREATE INDEX pending ON sync_outbox(payload) WHERE payload IS NOT NULL');
      db.execute('INSERT INTO sync_outbox VALUES(1, ?, ?)', ['private-pending-payload', Uint8List.fromList([0, 255, 31])]);
      db.execute("INSERT INTO study_documents VALUES('doc', '손글씨 원문')");
      return databaseFingerprint(db);
    } finally { db.dispose(); }
  }

  test('keys persist, are reused, and are never replaced for existing ciphertext', () async {
    final store = _Keys();
    final created = await requireDatabaseKey(store, encryptedDataExists: false);
    expect(created, matches(RegExp(r'^[0-9a-f]{64}$')));
    expect(await requireDatabaseKey(store, encryptedDataExists: true), created);
    expect(store.writes, 1);
    await expectLater(requireDatabaseKey(_Keys(), encryptedDataExists: true), throwsA(isA<DatabaseProtectionException>()));
    await expectLater(requireDatabaseKey(_Keys()..persist = false, encryptedDataExists: false), throwsA(isA<DatabaseProtectionException>()));
  });

  test('whole DB encrypted; schema, binary outbox, user version and custom table preserved', () {
    final before = seed();
    DatabaseProtection(file, key).prepare();
    expect(isPlainDatabase(file), isFalse);
    expect(String.fromCharCodes(file.readAsBytesSync()), isNot(contains('private-pending-payload')));
    final encrypted = sqlite3.open(file.path);
    try { configureDatabaseCipher(encrypted, key); expect(databaseFingerprint(encrypted), before); }
    finally { encrypted.dispose(); }
    final plain = sqlite3.open(file.path);
    try { expect(() => plain.select('SELECT * FROM sqlite_master'), throwsA(isA<SqliteException>())); }
    finally { plain.dispose(); }
    expect(File('${file.path}.plaintext').existsSync(), isFalse);
    expect(File('${file.path}.encrypting').existsSync(), isFalse);
    expect(File('${file.path}.encryption.json').existsSync(), isFalse);
    DatabaseProtection(file, key).prepare(); // Next launch does not migrate again.
  });

  test('wrong key fails without changing the encrypted file', () {
    seed(); DatabaseProtection(file, key).prepare();
    final bytes = file.readAsBytesSync();
    expect(() => DatabaseProtection(file, List.filled(32, '2b').join()).prepare(), throwsA(isA<DatabaseProtectionException>()));
    expect(file.readAsBytesSync(), bytes);
  });

  for (final crash in ['copying', 'verified', 'renamed_original', 'installed', 'cleaned']) {
    test('restart recovers after $crash without losing pending rows', () {
      final before = seed();
      expect(() => DatabaseProtection(file, key, checkpoint: (stage) {
        if (stage == crash) throw StateError('simulated_process_exit');
      }).prepare(), throwsA(isA<DatabaseProtectionException>()));
      DatabaseProtection(file, key).prepare();
      final db = sqlite3.open(file.path);
      try { configureDatabaseCipher(db, key); expect(databaseFingerprint(db), before); }
      finally { db.dispose(); }
      expect(File('${file.path}.encryption.json').existsSync(), isFalse);
      expect(File('${file.path}.plaintext').existsSync(), isFalse);
    });
  }

  test('uncheckpointed WAL is included in migrated data', () async {
    seed();
    // SQLITE_DBCONFIG_NO_CKPT_ON_CLOSE (1006) leaves committed WAL pages on
    // disk after close, reproducing the legacy interrupted-app layout.
    final writer = sqlite3.open(file.path);
    writer.execute('PRAGMA journal_mode=WAL');
    writer.execute('PRAGMA wal_autocheckpoint=0');
    writer.config.setIntConfig(1006, 1);
    writer.execute("INSERT INTO sync_outbox(id,payload) VALUES(2,'pending-in-wal')");
    final before = databaseFingerprint(writer);
    expect(File('${file.path}-wal').lengthSync(), greaterThan(0));
    writer.dispose();
    expect(File('${file.path}-wal').lengthSync(), greaterThan(0));
    DatabaseProtection(file, key).prepare();
    final db = sqlite3.open(file.path);
    try { configureDatabaseCipher(db, key); expect(databaseFingerprint(db), before); }
    finally { db.dispose(); }
  });

  test('fresh database is encrypted before schema creation', () {
    DatabaseProtection(file, key).prepare();
    expect(isPlainDatabase(file), isFalse);
    final db = sqlite3.open(file.path);
    try { configureDatabaseCipher(db, key); db.execute('CREATE TABLE first_write(id INTEGER)'); }
    finally { db.dispose(); }
  });
}
