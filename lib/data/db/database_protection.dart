import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
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

/// SQLite coordinates separate connections in the same process as well as
/// other processes. dart:io advisory locks alone do not exclude Unix isolates.
/// This existing lock file contains no tables, keys, or application data.
Database _acquirePreparationLock(File file) {
  file.parent.createSync(recursive: true);
  final lock = sqlite3.open('${file.path}.encryption.lock');
  try {
    lock.execute('PRAGMA busy_timeout = 0');
    lock.execute('BEGIN EXCLUSIVE');
    return lock;
  } catch (_) {
    lock.close();
    throw const DatabaseProtectionException('database_busy');
  }
}

void _rejectExistingEmptyDatabase(File file) {
  if (file.existsSync() && file.lengthSync() == 0) {
    throw const DatabaseProtectionException('empty_existing_database');
  }
}

/// Holds the same lock from protected-data inspection through key durability
/// and file preparation. Contention fails closed before touching key storage.
Future<String> prepareProtectedDatabase(File file, DatabaseKeyStore store) async {
  Database? lock;
  try {
    // Preserve an already damaged database without creating a new lock file.
    _rejectExistingEmptyDatabase(file);
    lock = _acquirePreparationLock(file);
    _rejectExistingEmptyDatabase(file);
    final path = file.path;
    final protectedData =
        (file.existsSync() && !isPlainDatabase(file)) ||
        File('$path.encrypting').existsSync() ||
        File('$path.plaintext').existsSync() ||
        File('$path.encryption.json').existsSync() ||
        File('$path.encryption.json.tmp').existsSync();
    final key = await requireDatabaseKey(store, encryptedDataExists: protectedData);
    await _prepareWhileLocked(path, key);
    return key;
  } on DatabaseProtectionException { rethrow; }
  catch (_) { throw const DatabaseProtectionException('migration_failed'); }
  finally { lock?.close(); } // Closing rolls back and releases the empty lock DB.
}

// Keep the isolate closure free of the platform key store and the lock handle.
Future<void> _prepareWhileLocked(String path, String key) =>
    Isolate.run(() => DatabaseProtection(File(path), key)._prepare());

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
          final Uint8List bytes => ['blob', base64Encode(bytes)],
          final int n => ['int', n.toString()],
          final double n => ['real', n.toString()],
          final String s => ['text', s],
          null => ['null'],
          _ => throw const DatabaseProtectionException('unsupported_value'),
        }).toList();
        sum = (sum + BigInt.parse(sha256.convert(utf8.encode(jsonEncode(values))).toString(), radix: 16)) % (BigInt.one << 256);
        count++;
      }
    } finally { statement.close(); }
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
    Database? lock;
    try {
      lock = _acquirePreparationLock(file);
      _prepare();
    } on DatabaseProtectionException { rethrow; }
    catch (_) { throw const DatabaseProtectionException('migration_failed'); }
    finally { lock?.close(); }
  }

  void _prepare() {
    // An empty existing file has no trustworthy creation provenance. It may
    // be a damaged database: preserve it, even when a valid key still exists.
    if (file.existsSync() && file.lengthSync() == 0) {
      throw const DatabaseProtectionException('empty_existing_database');
    }
    if (File('${marker.path}.tmp').existsSync()) {
      throw const DatabaseProtectionException('incomplete_marker');
    }
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
    if (!file.existsSync()) {
      checkpoint?.call('creating');
      final db = sqlite3.open(file.path);
      try {
        checkpoint?.call('created_empty');
        configureDatabaseCipher(db, key);
        db.execute('VACUUM');
        _integrity(db);
        checkpoint?.call('created_encrypted');
      }
      finally { db.close(); }
      _verify(file);
      checkpoint?.call('creation_verified');
      return;
    }
    if (!isPlainDatabase(file)) { _verify(file, full: false); return; }
    _writeMarker({'version': 1, 'stage': 'copying'});
    checkpoint?.call('copying');
    final source = sqlite3.open(file.path, mode: OpenMode.readWrite);
    late String digest;
    try {
      _lockPlaintext(source);
      source.execute('PRAGMA temp_store = MEMORY');
      _integrity(source);
      digest = databaseFingerprint(source);
      source.execute('VACUUM INTO ?', [candidate.path]);
      final target = sqlite3.open(candidate.path, mode: OpenMode.readWrite);
      try {
        target.execute('PRAGMA journal_mode = DELETE');
        configureDatabaseCipher(target, key, rekey: true);
        _integrity(target);
      } finally { target.close(); }
      if (_verify(candidate) != digest || databaseFingerprint(source) != digest) throw const DatabaseProtectionException('copy_mismatch');
      final durable = candidate.openSync(mode: FileMode.append);
      try { durable.flushSync(); } finally { durable.closeSync(); }
      _writeMarker({'version': 1, 'stage': 'verified', 'digest': digest});
      checkpoint?.call('verified');
      // Retain the original SQLite lock until replacement and backup cleanup.
      // A plaintext writer must not commit into the verified-copy/rename gap.
      _promote(digest, source: source);
    } finally { source.close(); }
  }

  void _lockPlaintext(Database source) {
    source.execute('PRAGMA busy_timeout = 3000');
    final wal = source.select('PRAGMA wal_checkpoint(TRUNCATE)').single;
    if (wal.values.first != 0) throw const DatabaseProtectionException('database_busy');
    if (source.select('PRAGMA journal_mode = DELETE').single.values.single != 'delete') throw const DatabaseProtectionException('database_busy');
    source.execute('PRAGMA locking_mode = EXCLUSIVE');
    source.execute('BEGIN EXCLUSIVE'); source.execute('COMMIT');
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
    finally { db.close(); }
  }

  void _promote(String digest, {Database? source}) {
    Database? recoverySource;
    try {
      // Inspect the header before taking the SQLite source lock. On Unix,
      // closing a separate dart:io descriptor for the same inode drops process
      // advisory locks; never call isPlainDatabase on the locked original.
      final mainIsPlain = source != null || isPlainDatabase(file);
      if (source == null) {
        final original = backup.existsSync() ? backup : mainIsPlain ? file : null;
        if (original != null) {
          recoverySource = sqlite3.open(original.path, mode: OpenMode.readWrite);
          _lockPlaintext(recoverySource);
        }
      }
      final authoritative = source ?? recoverySource;
      // A verified marker is not proof the old plaintext file stayed frozen
      // while this process was absent. Preserve both files if it changed.
      if (authoritative != null && databaseFingerprint(authoritative) != digest) {
        throw const DatabaseProtectionException('recovery_mismatch');
      }
      _promoteLocked(digest, mainIsPlain: mainIsPlain);
    } finally { recoverySource?.close(); }
  }

  void _promoteLocked(String digest, {required bool mainIsPlain}) {
    if (file.existsSync() && !mainIsPlain) {
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
