import 'dart:io';

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
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
      synchronizable: false,
    ),
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

/// Coalesces concurrent preparation only. A later open/retry must inspect the
/// file and durable key again, even after an earlier preparation succeeded.
class DatabasePreparations {
  final _pending = <String, Future<PreparedDatabase>>{};

  Future<PreparedDatabase> run(
    String name,
    Future<PreparedDatabase> Function() prepare,
  ) => _pending.putIfAbsent(
    name,
    () => Future<PreparedDatabase>.sync(prepare).whenComplete(() {
      _pending.remove(name);
    }),
  );
}

final _preparations = DatabasePreparations();

/// Bootstrap calls this before any repositories, auth startup or DB writers.
Future<PreparedDatabase> prepareDeviceDatabase(String name) =>
    _preparations.run(name, () => _prepare(name));

Future<PreparedDatabase> _prepare(String name) async {
  try {
    if (!RegExp(r'^soongong_(dev|prod)$').hasMatch(name)) {
      throw const DatabaseProtectionException('invalid_scope');
    }
    final directory = await getApplicationDocumentsDirectory();
    // Matches drift_flutter 0.3.1's exact legacy path, including .sqlite.
    final path = p.join(directory.path, '$name.sqlite');
    if (Platform.isIOS) {
      await const MethodChannel(
        'co.byite.soongong/storage',
      ).invokeMethod<void>('excludeDocumentsFromBackup');
    }
    return await prepareDatabaseFile(
      File(path),
      PlatformDatabaseKeyStore(name),
    );
  } on DatabaseProtectionException {
    rethrow;
  } catch (_) {
    throw const DatabaseProtectionException('storage_unavailable');
  }
}

/// The production preparation boundary, injectable only at key storage and
/// file location for synthetic codec tests. No plugin or codec is substituted.
Future<PreparedDatabase> prepareDatabaseFile(
  File file,
  DatabaseKeyStore store,
) async {
  final key = await prepareProtectedDatabase(file, store);
  return PreparedDatabase(file.path, key);
}

QueryExecutor encryptedDatabase(String name) => LazyDatabase(() async {
  final prepared = await prepareDeviceDatabase(name);
  return encryptedDatabaseFromPrepared(prepared);
});

/// Also used by codec integration tests with a prepared synthetic file, without
/// replacing the production Drift executor or its cipher setup with a fake.
QueryExecutor encryptedDatabaseFromPrepared(PreparedDatabase prepared) {
  // Do not capture plugin objects/provider state into the database isolate.
  final key = prepared.key;
  final path = prepared.path;
  return LazyDatabase(() {
    // A prepared descriptor is not proof the file is still intact. Check when
    // the executor actually opens, not only when the descriptor was issued.
    _requirePreparedFile(path);
    return NativeDatabase.createInBackground(
      File(path),
      setup: (db) {
        // Check again in the background connection before any cipher/schema
        // SQL can turn an empty file into a new database.
        _requirePreparedFile(path);
        configureDatabaseCipher(db, key);
        db.select(
          'SELECT count(*) FROM sqlite_master',
        ); // Key checked before Drift.
      },
    );
  });
}

void _requirePreparedFile(String path) {
  try {
    final file = File(path);
    if (!file.existsSync()) {
      throw const DatabaseProtectionException('prepared_database_missing');
    }
    if (file.lengthSync() == 0) {
      throw const DatabaseProtectionException('empty_existing_database');
    }
  } on DatabaseProtectionException {
    rethrow;
  } catch (_) {
    throw const DatabaseProtectionException('storage_unavailable');
  }
}
