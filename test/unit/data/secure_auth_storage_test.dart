import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:soongong/data/auth/secure_auth_storage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MemorySecrets implements AuthSecretStore {
  final values = <String, String>{};
  bool failWrites = false;
  bool dropWrites = false;
  Completer<void>? writeGate;

  @override
  Future<String?> read(String key) async => values[key];
  @override
  Future<void> write(String key, String value) async {
    if (failWrites) throw StateError('unavailable');
    await writeGate?.future;
    if (!dropWrites) values[key] = value;
  }
  @override
  Future<void> remove(String key) async => values.remove(key);
}

class LegacySession extends LocalStorage {
  LegacySession(this.value);
  String? value;
  bool failRemove = false;
  @override
  Future<void> initialize() async {}
  @override
  Future<String?> accessToken() async => value;
  @override
  Future<bool> hasAccessToken() async => value != null;
  @override
  Future<void> persistSession(String persistSessionString) async => value = persistSessionString;
  @override
  Future<void> removePersistedSession() async {
    if (failRemove) throw StateError('legacy_unavailable');
    value = null;
  }
}

class LegacyPkce extends GotrueAsyncStorage {
  final values = <String, String>{};
  @override
  Future<String?> getItem({required String key}) async => values[key];
  @override
  Future<void> setItem({required String key, required String value}) async => values[key] = value;
  @override
  Future<void> removeItem({required String key}) async => values.remove(key);
}

void main() {
  late MemorySecrets secrets;
  late LegacySession legacy;
  late SecureSessionStorage session;
  setUp(() {
    secrets = MemorySecrets();
    legacy = LegacySession('old-session');
    session = SecureSessionStorage(secrets: secrets, key: 'session', legacy: legacy);
  });

  test('migrates a legacy session only after read-back verification', () async {
    await session.initialize();
    expect(await session.accessToken(), 'old-session');
    expect(await session.hasAccessToken(), isTrue);
    expect(legacy.value, isNull);
    await session.initialize();
    expect(await session.accessToken(), 'old-session');
  });

  test('secure session wins over stale plaintext', () async {
    secrets.values['session'] = 'current-session';
    expect(await session.accessToken(), 'current-session');
    expect(legacy.value, isNull);
  });

  for (final drop in [false, true]) {
    test('failed migration retains old copy and does not fall back (drop=$drop)', () async {
      secrets.failWrites = !drop;
      secrets.dropWrites = drop;
      await expectLater(session.initialize(), throwsStateError);
      expect(legacy.value, 'old-session');
      expect(secrets.values, isEmpty);
    });
  }

  test('logout follows in-flight persistence and leaves unrelated keys intact', () async {
    await session.initialize();
    secrets.values['device_id'] = 'device';
    secrets.values['other-project'] = 'other';
    secrets.writeGate = Completer<void>();
    final persist = session.persistSession('new-session');
    final logout = session.removePersistedSession();
    secrets.writeGate!.complete();
    await Future.wait([persist, logout]);
    expect(await session.accessToken(), isNull);
    expect(legacy.value, isNull);
    expect(secrets.values, {'session': '', 'device_id': 'device', 'other-project': 'other'});
    legacy.value = 'restored-stale-session';
    final restarted = SecureSessionStorage(secrets: secrets, key: 'session', legacy: legacy);
    expect(await restarted.hasAccessToken(), isFalse);
  });

  test('logout tombstone survives failed legacy cleanup and blocks later re-import', () async {
    await session.initialize();
    legacy.value = 'stale-session';
    legacy.failRemove = true;
    await expectLater(session.removePersistedSession(), throwsStateError);
    expect(await session.hasAccessToken(), isFalse);
    expect(legacy.value, 'stale-session');
    legacy.failRemove = false;
    final restarted = SecureSessionStorage(secrets: secrets, key: 'session', legacy: legacy);
    expect(await restarted.accessToken(), isNull);
    expect(legacy.value, isNull);
    await restarted.persistSession('signed-in-again');
    expect(await restarted.accessToken(), 'signed-in-again');
  });

  test('keys isolate flavor, full origin and SDK PKCE key', () {
    final dev = AuthStorageKeys(url: 'https://project.supabase.co', flavor: 'dev');
    final prod = AuthStorageKeys(url: 'https://project.supabase.co', flavor: 'prod');
    final custom = AuthStorageKeys(url: 'https://project.example:8443', flavor: 'dev');
    expect(dev.legacySession, 'sb-project-auth-token');
    expect({dev.session, prod.session, custom.session}.length, 3);
    expect(dev.pkce('a'), isNot(dev.pkce('b')));
  });

  test('PKCE migrates, overwrites and removes only the requested verifier', () async {
    final keys = AuthStorageKeys(url: 'https://project.supabase.co', flavor: 'dev');
    final old = LegacyPkce()..values['verifier'] = 'old-code';
    final pkce = SecurePkceStorage(secrets: secrets, keys: keys, legacy: old);
    expect(await pkce.getItem(key: 'verifier'), 'old-code');
    expect(old.values, isEmpty);
    await pkce.setItem(key: 'other', value: 'keep');
    await pkce.setItem(key: 'verifier', value: 'new-code');
    expect(await pkce.getItem(key: 'verifier'), 'new-code');
    await pkce.removeItem(key: 'verifier');
    expect(await pkce.getItem(key: 'verifier'), isNull);
    expect(await pkce.getItem(key: 'other'), 'keep');
  });

  test('PKCE failed migration does not consume the legacy verifier', () async {
    secrets.dropWrites = true;
    final old = LegacyPkce()..values['verifier'] = 'old-code';
    final pkce = SecurePkceStorage(
      secrets: secrets,
      keys: AuthStorageKeys(url: 'https://project.supabase.co', flavor: 'dev'),
      legacy: old,
    );
    await expectLater(pkce.getItem(key: 'verifier'), throwsStateError);
    expect(old.values['verifier'], 'old-code');
  });
}
