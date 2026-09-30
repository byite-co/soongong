// deviceId (uuid v4) generated once and kept in platform secure storage
// (S01 · CLAUDE.md §5 device_id). Never logged together with user data.

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:uuid/uuid.dart';

import '../logging/app_logger.dart';

/// Minimal key/value store so tests can inject an in-memory implementation.
abstract class SecureKeyValueStore {
  Future<String?> read(String key);
  Future<void> write(String key, String value);
}

class FlutterSecureKeyValueStore implements SecureKeyValueStore {
  const FlutterSecureKeyValueStore([this._storage = const FlutterSecureStorage()]);

  final FlutterSecureStorage _storage;

  @override
  Future<String?> read(String key) => _storage.read(key: key);

  @override
  Future<void> write(String key, String value) =>
      _storage.write(key: key, value: value);
}

class InMemoryKeyValueStore implements SecureKeyValueStore {
  final Map<String, String> _map = <String, String>{};

  @override
  Future<String?> read(String key) async => _map[key];

  @override
  Future<void> write(String key, String value) async => _map[key] = value;
}

class DeviceIdStore {
  DeviceIdStore({SecureKeyValueStore? store, Uuid? uuid})
      : _store = store ?? const FlutterSecureKeyValueStore(),
        _uuid = uuid ?? const Uuid();

  static const String key = 'device_id';

  final SecureKeyValueStore _store;
  final Uuid _uuid;

  /// Returns the stored id, or creates and stores a new uuid v4. If secure
  /// storage is unavailable the id is still returned (in-memory only) and a
  /// warning is logged.
  Future<String> getOrCreate() async {
    try {
      final existing = await _store.read(key);
      if (existing != null && existing.isNotEmpty) return existing;
      final created = _uuid.v4();
      await _store.write(key, created);
      return created;
    } catch (e) {
      appLog.w('deviceId: secure storage unavailable, using volatile id ($e)');
      return _uuid.v4();
    }
  }
}
