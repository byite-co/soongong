import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:sqlite3/sqlite3.dart';

/// Deliberately never includes SQL, paths, keys, or platform exception text.
class DatabaseProtectionException implements Exception {
  const DatabaseProtectionException(this.code);
  final String code;
  @override
  String toString() => 'DatabaseProtectionException($code)';
}

abstract interface class DatabaseKeyStore {
  Future<String?> read();
  Future<void> write(String key);
}

Future<String> requireDatabaseKey(DatabaseKeyStore store, {required bool encryptedDataExists}) async {
  try {
    var key = await store.read();
    if (key == null) {
      if (encryptedDataExists) throw const DatabaseProtectionException('key_missing');
      final random = Random.secure();
      key = List.generate(32, (_) => random.nextInt(256).toRadixString(16).padLeft(2, '0')).join();
      await store.write(key);
      if (await store.read() != key) throw const DatabaseProtectionException('key_not_durable');
    }
    if (!RegExp(r'^[0-9a-f]{64}$').hasMatch(key)) throw const DatabaseProtectionException('invalid_key');
    return key;
  } on DatabaseProtectionException { rethrow; }
  catch (_) { throw const DatabaseProtectionException('key_unavailable'); }
}

/// Checks a real codec function: SQLite silently ignores unknown PRAGMAs.
void configureDatabaseCipher(Database db, String key, {bool rekey = false}) {
  if (!RegExp(r'^[0-9a-f]{64}$').hasMatch(key)) throw const DatabaseProtectionException('invalid_key');
  try {
    db.execute("PRAGMA cipher = 'chacha20'");
    final cipher = db.select('PRAGMA cipher');
    if (cipher.length != 1 || cipher.single.values.single != 'chacha20') throw const DatabaseProtectionException('codec_unavailable');
    db.execute('PRAGMA legacy = 0');
    db.execute('PRAGMA plaintext_header_size = 0');
    db.execute('PRAGMA hmac_check = 1');
    db.execute("PRAGMA ${rekey ? 'rekey' : 'key'} = 'raw:$key'");
    // SQLite >=3.48 touches the schema even for SELECT of a constant/function:
    // this probe must follow the key, never precede it.
    if (db.select("SELECT sqlite3mc_config('hmac_check')").single.values.single != 1) throw const DatabaseProtectionException('codec_unavailable');
    db.execute('PRAGMA temp_store = MEMORY');
    db.execute('PRAGMA secure_delete = ON');
    db.execute('PRAGMA busy_timeout = 3000');
  } on DatabaseProtectionException { rethrow; }
  catch (_) { throw const DatabaseProtectionException('codec_or_key_failed'); }
}

bool isPlainDatabase(File file) {
  if (!file.existsSync() || file.lengthSync() < 16) return false;
  final input = file.openSync();
  try { return utf8.decode(input.readSync(16), allowMalformed: true) == 'SQLite format 3\u0000'; }
  finally { input.closeSync(); }
}

void _integrity(Database db) {
  final rows = db.select('PRAGMA integrity_check');
  if (rows.length != 1 || rows.single.values.single != 'ok') throw const DatabaseProtectionException('integrity_failed');
  if (db.select('PRAGMA foreign_key_check').isNotEmpty) throw const DatabaseProtectionException('foreign_key_failed');
}

/// Multiset digest preserves duplicates, blobs, nulls, and numeric types; includes
/// every table (outbox, snapshots, custom tables), schema object and user_version.
String databaseFingerprint(Database db) {
  final schema = db.select('SELECT type, name, tbl_name, sql FROM sqlite_master ORDER BY type, name');
  final state = <Object?>[db.select('PRAGMA user_version').single.values.single];
  for (final object in schema) {
    state.add(object.values.toList());
    if (object['type'] != 'table') continue;
    final name = (object['name'] as String).replaceAll('"', '""');
    final statement = db.prepare('SELECT * FROM "$name"');
    var sum = BigInt.zero;
    var count = 0;
    try {
      final cursor = statement.selectCursor();
      while (cursor.moveNext()) {
        final row = cursor.current;
        final values = row.values.map((v) => switch (v) {
          Uint8List bytes => ['blob', base64Encode(bytes)],
          int n => ['int', n.toString()],
          double n => ['real', n.toString()],
          String s => ['text', s],
          null => ['null'],
          _ => throw const DatabaseProtectionException('unsupported_value'),
        }).toList();
        sum = (sum + BigInt.parse(sha256.convert(utf8.encode(jsonEncode(values))).toString(), radix: 16)) % (BigInt.one << 256);
        count++;
      }
    } finally { statement.dispose(); }
    state.add([count, sum.toRadixString(16)]);
  }
  return sha256.convert(utf8.encode(jsonEncode(state))).toString();
}

/// Runs before Drift opens, under a separate process lock. Never modifies the
/// original in place. Marker + verified copy allow process-crash recovery.
class DatabaseProtection {
  DatabaseProtection(this.file, this.key, {this.checkpoint});
  final File file;
  final String key;
  final void Function(String stage)? checkpoint;
  File get candidate => File('${file.path}.encrypting');
  File get backup => File('${file.path}.plaintext');
  File get marker => File('${file.path}.encryption.json');

  void prepare() {
    file.parent.createSync(recursive: true);
    final lock = File('${file.path}.encryption.lock').openSync(mode: FileMode.append);
    try {
      lock.lockSync(FileLock.exclusive);
      _prepare();
    } on DatabaseProtectionException { rethrow; }
    catch (_) { throw const DatabaseProtectionException('migration_failed'); }
    finally { lock.closeSync(); }
  }

  void _prepare() {
    if (marker.existsSync()) {
      final record = jsonDecode(marker.readAsStringSync()) as Map<String, dynamic>;
      if (record['version'] != 1) throw const DatabaseProtectionException('unknown_migration');
      if (record['stage'] == 'verified') { _promote(record['digest'] as String); return; }
      if (record['stage'] != 'copying' || !isPlainDatabase(file) || backup.existsSync()) {
        throw const DatabaseProtectionException('recovery_required');
      }
      _remove(candidate); // Original remains authoritative before verification.
    } else if (backup.existsSync() || candidate.existsSync()) {
      throw const DatabaseProtectionException('orphaned_migration');
    }
    if (!file.existsSync() || file.lengthSync() == 0) {
      final db = sqlite3.open(file.path);
      try { configureDatabaseCipher(db, key); db.execute('VACUUM'); _integrity(db); }
      finally { db.dispose(); }
      _verify(file);
      return;
    }
    if (!isPlainDatabase(file)) { _verify(file, full: false); return; }
    _writeMarker({'version': 1, 'stage': 'copying'});
    checkpoint?.call('copying');
    final source = sqlite3.open(file.path, mode: OpenMode.readWrite);
    late String digest;
    try {
      // Recover WAL first, then keep an exclusive SQLite lock during the copy.
      source.execute('PRAGMA busy_timeout = 3000');
      final wal = source.select('PRAGMA wal_checkpoint(TRUNCATE)').single;
      if (wal.values.first != 0) throw const DatabaseProtectionException('database_busy');
      if (source.select('PRAGMA journal_mode = DELETE').single.values.single != 'delete') throw const DatabaseProtectionException('database_busy');
      source.execute('PRAGMA locking_mode = EXCLUSIVE');
      source.execute('BEGIN EXCLUSIVE'); source.execute('COMMIT');
      source.execute('PRAGMA temp_store = MEMORY');
      _integrity(source);
      digest = databaseFingerprint(source);
      source.execute('VACUUM INTO ?', [candidate.path]);
      final target = sqlite3.open(candidate.path, mode: OpenMode.readWrite);
      try {
        target.execute('PRAGMA journal_mode = DELETE');
        configureDatabaseCipher(target, key, rekey: true);
        _integrity(target);
      } finally { target.dispose(); }
      if (_verify(candidate) != digest || databaseFingerprint(source) != digest) throw const DatabaseProtectionException('copy_mismatch');
      final durable = candidate.openSync(mode: FileMode.append);
      try { durable.flushSync(); } finally { durable.closeSync(); }
    } finally { source.dispose(); }
    _writeMarker({'version': 1, 'stage': 'verified', 'digest': digest});
    checkpoint?.call('verified');
    _promote(digest);
  }

  String _verify(File target, {bool full = true}) {
    if (!target.existsSync() || isPlainDatabase(target) || target.lengthSync() == 0) throw const DatabaseProtectionException('not_encrypted');
    final db = sqlite3.open(target.path, mode: OpenMode.readOnly);
    try {
      configureDatabaseCipher(db, key);
      db.select('SELECT count(*) FROM sqlite_master');
      if (!full) return ''; // Page MACs are checked on every subsequent read.
      _integrity(db);
      return databaseFingerprint(db);
    }
    finally { db.dispose(); }
  }

  void _promote(String digest) {
    if (file.existsSync() && !isPlainDatabase(file)) {
      if (_verify(file) != digest) throw const DatabaseProtectionException('recovery_mismatch');
    } else {
      if (_verify(candidate) != digest) throw const DatabaseProtectionException('recovery_mismatch');
      if (file.existsSync()) {
        if (backup.existsSync()) throw const DatabaseProtectionException('ambiguous_recovery');
        file.renameSync(backup.path);
      } else if (!backup.existsSync()) { throw const DatabaseProtectionException('source_missing'); }
      checkpoint?.call('renamed_original');
      candidate.renameSync(file.path);
      checkpoint?.call('installed');
      if (_verify(file) != digest) throw const DatabaseProtectionException('recovery_mismatch');
    }
    // A cleanup failure keeps the marker; no writes are allowed until a retry.
    _remove(backup); _remove(candidate);
    checkpoint?.call('cleaned');
    marker.deleteSync();
  }

  void _writeMarker(Map<String, Object> value) {
    final temporary = File('${marker.path}.tmp');
    temporary.writeAsStringSync(jsonEncode(value), flush: true);
    temporary.renameSync(marker.path);
  }

  void _remove(File target) {
    for (final suffix in ['', '-wal', '-shm', '-journal']) {
      final entry = File('${target.path}$suffix');
      if (entry.existsSync()) entry.deleteSync();
    }
  }
}
