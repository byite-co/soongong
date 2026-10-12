// Supabase 2.18.0 LocalStorage / GotrueAsyncStorage adapters. The official
// custom-storage example is the API reference; see docs/oss-integration.md.
// No token, verifier, or storage exception is logged here.

import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Separate from DeviceIdStore: authentication cleanup must never delete
/// device identifiers or a future database encryption key.
abstract interface class AuthSecretStore {
  Future<String?> read(String key);
  Future<void> write(String key, String value);
  Future<void> remove(String key);
}

class PlatformAuthSecretStore implements AuthSecretStore {
  const PlatformAuthSecretStore([this.storage = const FlutterSecureStorage()]);

  final FlutterSecureStorage storage;

  @override
  Future<String?> read(String key) => storage.read(key: key);

  @override
  Future<void> write(String key, String value) => storage.write(key: key, value: value);

  @override
  Future<void> remove(String key) => storage.delete(key: key);
}

/// The full origin (including a custom port) and flavor isolate credentials.
/// The legacy key is exactly the one used by supabase_flutter 2.18.0.
class AuthStorageKeys {
  AuthStorageKeys({required String url, required String flavor})
      : prefix = 'soongong.auth.$flavor.${sha256.convert(utf8.encode(Uri.parse(url).origin))}',
        legacySession = 'sb-${Uri.parse(url).host.split('.').first}-auth-token';

  final String prefix;
  final String legacySession;
  String get session => '$prefix.session';
  String pkce(String sdkKey) => '$prefix.pkce.${sha256.convert(utf8.encode(sdkKey))}';
}

/// SDK auth events may persist without awaiting the preceding write. Serialize
/// storage operations so an earlier write cannot resurrect a signed-out session.
class _Serial {
  Future<void> _tail = Future<void>.value();

  Future<T> run<T>(Future<T> Function() work) {
    final result = _tail.then((_) => work());
    _tail = result.then<void>((_) {}, onError: (Object _, StackTrace __) {});
    return result;
  }
}

Future<void> _verifiedWrite(AuthSecretStore secrets, String key, String value) async {
  await secrets.write(key, value);
  if (await secrets.read(key) != value) {
    // Intentionally contains neither the value nor a platform exception.
    throw StateError('auth_secure_storage_verification_failed');
  }
}

class SecureSessionStorage extends LocalStorage {
  SecureSessionStorage({required this.secrets, required this.key, required this.legacy});

  final AuthSecretStore secrets;
  final String key;
  final LocalStorage legacy;
  final _serial = _Serial();
  Future<void>? _initialized;

  @override
  Future<void> initialize() => _initialized ??= _serial.run(() async {
        await legacy.initialize();
        final current = await secrets.read(key);
        if (current == null) {
          final previous = await legacy.accessToken();
          if (previous != null) await _verifiedWrite(secrets, key, previous);
        }
        // Only remove the old copy after a secure read or a verified migration
        // succeeded. There is deliberately no plaintext persistence fallback.
        await legacy.removePersistedSession();
      });

  @override
  Future<String?> accessToken() async {
    await initialize();
    return _serial.run(() => secrets.read(key));
  }

  @override
  Future<bool> hasAccessToken() async => (await accessToken())?.isNotEmpty ?? false;

  @override
  Future<void> persistSession(String persistSessionString) async {
    await initialize();
    await _serial.run(() async {
      await _verifiedWrite(secrets, key, persistSessionString);
      await legacy.removePersistedSession();
    });
  }

  @override
  Future<void> removePersistedSession() async {
    await initialize();
    await _serial.run(() async {
      // If deleting the legacy copy fails, retain the secure copy rather than
      // allowing a later startup to import an older legacy session.
      await legacy.removePersistedSession();
      await secrets.remove(key);
    });
  }
}

class SecurePkceStorage extends GotrueAsyncStorage {
  SecurePkceStorage({required this.secrets, required this.keys, required this.legacy});

  final AuthSecretStore secrets;
  final AuthStorageKeys keys;
  final GotrueAsyncStorage legacy;
  final _serial = _Serial();

  @override
  Future<String?> getItem({required String key}) => _serial.run(() async {
        final secureKey = keys.pkce(key);
        final current = await secrets.read(secureKey);
        if (current != null) {
          await legacy.removeItem(key: key);
          return current;
        }
        final previous = await legacy.getItem(key: key);
        if (previous != null) await _verifiedWrite(secrets, secureKey, previous);
        await legacy.removeItem(key: key);
        return previous;
      });

  @override
  Future<void> setItem({required String key, required String value}) => _serial.run(() async {
        await _verifiedWrite(secrets, keys.pkce(key), value);
        await legacy.removeItem(key: key);
      });

  @override
  Future<void> removeItem({required String key}) => _serial.run(() async {
        await legacy.removeItem(key: key);
        await secrets.remove(keys.pkce(key));
      });
}
