import 'dart:io';
import 'dart:isolate';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'database_protection.dart';

class PlatformDatabaseKeyStore implements DatabaseKeyStore {
  PlatformDatabaseKeyStore(this.name);
  final String name;
  static const _storage = FlutterSecureStorage(
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock_this_device, synchronizable: false),
  );
  // File/flavor scoped. Auth logout removes auth keys only, never this key.
  String get _key => 'soongong.database.$name.chacha20.v1';
  @override
  Future<String?> read() => _storage.read(key: _key);
  @override
  Future<void> write(String key) => _storage.write(key: _key, value: key);
}

class PreparedDatabase {
  const PreparedDatabase(this.path, this.key);
  final String path;
  final String key;
  @override
  String toString() => 'PreparedDatabase';
}

final _preparations = <String, Future<PreparedDatabase>>{};

/// Bootstrap calls this before any repositories, auth startup or DB writers.
Future<PreparedDatabase> prepareDeviceDatabase(String name) =>
    _preparations.putIfAbsent(name, () => _prepare(name).onError((Object error, StackTrace stack) {
      _preparations.remove(name);
      Error.throwWithStackTrace(error, stack);
    }));

Future<PreparedDatabase> _prepare(String name) async {
  try {
    if (!RegExp(r'^soongong_(dev|prod)$').hasMatch(name)) throw const DatabaseProtectionException('invalid_scope');
    final directory = await getApplicationDocumentsDirectory();
    // Matches drift_flutter 0.3.1's exact legacy path, including .sqlite.
    final path = p.join(directory.path, '$name.sqlite');
    if (Platform.isIOS) {
      await const MethodChannel('co.byite.soongong/storage').invokeMethod<void>('excludeDocumentsFromBackup');
    }
    final file = File(path);
    final protectedData = (file.existsSync() && !isPlainDatabase(file)) ||
        File('$path.encrypting').existsSync() || File('$path.plaintext').existsSync();
    final key = await requireDatabaseKey(PlatformDatabaseKeyStore(name), encryptedDataExists: protectedData);
    await Isolate.run(() => DatabaseProtection(File(path), key).prepare());
    return PreparedDatabase(path, key);
  } on DatabaseProtectionException { rethrow; }
  catch (_) { throw const DatabaseProtectionException('storage_unavailable'); }
}

QueryExecutor encryptedDatabase(String name) => LazyDatabase(() async {
  final prepared = await prepareDeviceDatabase(name);
  // Do not capture plugin objects/provider state into the database isolate.
  final key = prepared.key;
  return NativeDatabase.createInBackground(File(prepared.path), setup: (db) {
    configureDatabaseCipher(db, key);
    db.select('SELECT count(*) FROM sqlite_master'); // Key checked before Drift.
    db.execute('PRAGMA journal_mode = DELETE'); // Fully encrypted header on iOS.
  });
});
