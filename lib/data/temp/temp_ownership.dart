import 'dart:async';
import 'dart:convert';

import '../../core/domain/ids.dart';
import '../db/app_database.dart';
import '../repositories/sync_writer.dart';
import 'owned_temp_store.dart';

/// Account mapping is encrypted with the database. Revocations are first
/// persisted independently, so wiping sync_meta cannot erase an obligation.
class TempOwnership {
  TempOwnership(this.db, this.store);
  final AppDatabase db;
  final OwnedTempStore store;
  static const key = 'owned_temporary_scope_v1';
  final Map<String, int> _epochs = {};
  final Map<String, Set<String>> _known = {};
  final Set<String> _boundaries = {};
  final _invalidations = StreamController<String>.broadcast(sync: true);
  Stream<String> get invalidations => _invalidations.stream;
  void dispose() => _invalidations.close();

  int epoch(String userId) => _epochs[userId] ?? 0;
  void beginBoundary(String userId) {
    _boundaries.add(userId);
    invalidate(userId);
  }

  void endBoundary(String userId) {
    _epochs[userId] = epoch(userId) + 1;
    _boundaries.remove(userId);
  }

  void invalidate(String userId) {
    _epochs[userId] = epoch(userId) + 1;
    _invalidations.add(userId);
    for (final scope in _known[userId] ?? <String>{}) {
      store.invalidate(scope);
    }
  }

  Future<Map<String, dynamic>?> _mapping() async {
    final row = await (db.select(
      db.syncMeta,
    )..where((m) => m.key.equals(key))).getSingleOrNull();
    if (row == null) return null;
    try {
      final data = jsonDecode(row.value) as Map<String, dynamic>;
      if (data['owner'] is! String ||
          data['generation'] is! int ||
          data['scope'] is! String ||
          !OwnedTempStore.validId(data['scope'] as String)) {
        throw const TempStoreUnavailable();
      }
      return data;
    } on Object {
      throw const TempStoreUnavailable();
    }
  }

  Future<bool> ownsFile(SyncWriter writer, String path) async {
    final token = epoch(writer.ctx.userId);
    final mapping = await _mapping();
    if (mapping == null ||
        mapping['owner'] != writer.ctx.userId ||
        mapping['generation'] != writer.purgeGeneration ||
        _boundaries.contains(writer.ctx.userId)) {
      return false;
    }
    final owned = await store.ownsActivePayload(
      mapping['scope'] as String,
      path,
    );
    return owned && token == epoch(writer.ctx.userId);
  }

  Future<OwnedTempTask> create(
    SyncWriter writer,
    String kind, {
    required int generation,
    required bool Function() alive,
  }) async {
    final owner = writer.ctx.userId;
    final token = epoch(owner);
    bool current() =>
        alive() &&
        !_boundaries.contains(owner) &&
        epoch(owner) == token &&
        writer.purgeGeneration == generation;
    final scope = await writer.runOwnedTransaction(
      () async {
        if (!current()) throw StateError('temporary operation cancelled');
        final old = await _mapping();
        var id = old?['scope'] as String?;
        if (old?['owner'] != owner ||
            old?['generation'] != generation ||
            id == null ||
            await store.isRevoked(id)) {
          if (id != null) await store.markRevoked(id);
          id = newUuid();
          await db
              .into(db.syncMeta)
              .insertOnConflictUpdate(
                SyncMetaCompanion.insert(
                  key: key,
                  value: jsonEncode({
                    'owner': owner,
                    'generation': generation,
                    'scope': id,
                  }),
                ),
              );
        }
        if (!current()) throw StateError('temporary operation cancelled');
        (_known[owner] ??= {}).add(id);
        return id;
      },
      alive: current,
      generation: generation,
    );
    if (!current()) throw StateError('temporary operation cancelled');
    final task = await store.create(scope, kind);
    if (!current()) {
      await task.cleanup();
      throw StateError('temporary operation cancelled');
    }
    return task;
  }

  /// Throws if durable revocation cannot be recorded. Call before DB wipe.
  /// Known cleanup failures are returned and remain independently retryable.
  Future<TempCleanupResult> revoke(String userId) async {
    invalidate(userId);
    final token = epoch(userId);
    final scopes = {...?_known[userId]};
    final mapping = await _mapping();
    if (epoch(userId) == token && mapping?['owner'] == userId) {
      scopes.add(mapping!['scope'] as String);
    }
    for (final scope in scopes) {
      await store.markRevoked(scope);
    }
    var result = const TempCleanupResult();
    for (final scope in scopes) {
      result = result.plus(await store.revoke(scope));
    }
    return result;
  }

  Future<TempCleanupResult> cancelPicker(String userId) async {
    _epochs[userId] = epoch(userId) + 1;
    _invalidations.add(userId);
    final token = epoch(userId);
    final scopes = {...?_known[userId]};
    final mapping = await _mapping();
    if (epoch(userId) == token && mapping?['owner'] == userId) {
      scopes.add(mapping!['scope'] as String);
    }
    var result = const TempCleanupResult();
    for (final scope in scopes) {
      result = result.plus(await store.cancelKind(scope, 'picker'));
    }
    return result;
  }
}
