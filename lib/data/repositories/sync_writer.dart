// SyncWriter (S02 · S02b): the only place that touches the D2 bookkeeping.
//
//   user write        → client_updated_at = now · client_rev + 1 · outbox
//   softDelete        → pending_delete_until = now + 5 s (no rev, no outbox)
//   undoDelete        → pending_delete_until = null
//   commitDelete      → content columns NULL · deleted_at · rev + 1 · outbox
//   hideLocally       → deleted_at only (children of a deleted saved result —
//                       the server tombstone arrives through pull)
//   tombstoneLocally  → deleted_at + content NULL, no rev, no outbox (the
//                       server already confirmed the delete, e.g. 410)
//   deleteIfLocalOnly → physical delete, only for a row that was NEVER sent
//   applyServer       → upsert server rows; client_rev kept, base = server
//                       version, NO outbox (D2 "서버 응답·pull 적용은 outbox를
//                       거치지 않는다")
//
// Every mutating method runs in a drift transaction (S02b): the row change
// and its outbox entry commit or roll back together. Calls from inside an
// outer `runInTransaction` join that transaction (drift nests by default).

import 'dart:convert';

import 'package:drift/drift.dart';

import '../../core/domain/delete_policy.dart';
import '../db/app_database.dart';
import '../db/sync_tables.dart';
import 'write_context.dart';

class ApplyServerReport {
  const ApplyServerReport({
    required this.applied,
    required this.dirtyOverwritten,
  });

  final int applied;

  /// Rows that had an unpushed local change when the server row replaced
  /// them. S13 resolves these (LWW) before calling `applyServer`; the list is
  /// here so it can log a `sync_conflicts` entry when it did not.
  final List<String> dirtyOverwritten;
}

class SyncWriter {
  SyncWriter(this.db, this.ctx);

  final AppDatabase db;
  final WriteContext ctx;

  static const DeletePolicy _deletePolicy = DeletePolicy();

  String _q(TableInfo<Table, Object?> t) => '"${t.actualTableName}"';

  /// Runs [action] atomically. Repositories wrap multi-row operations
  /// (cascade deletes, subject reassignment) in this so every row change and
  /// every outbox entry commit together.
  Future<T> runInTransaction<T>(Future<T> Function() action) =>
      db.transaction(action);

  // ---------------------------------------------------------------------
  // User writes

  /// Call after updating a row's content: bumps the rev, stamps the time and
  /// enqueues the row — atomically.
  Future<void> markUserWrite(
    TableInfo<Table, Object?> table,
    String rowId, {
    DateTime? at,
  }) {
    return db.transaction(() async {
      final now = at ?? ctx.nowUtc();
      await db.customUpdate(
        'UPDATE ${_q(table)} SET client_updated_at = ?, client_rev = client_rev + 1 '
        'WHERE id = ?',
        variables: [Variable<String>(utcIso(now)), Variable<String>(rowId)],
        updates: {table},
      );
      await enqueue(table.actualTableName, rowId);
    });
  }

  /// Outbox upsert (one row per (table, row)). A row that was already sent
  /// gets a NEW mutation_id and becomes unsent again (edit after send); an
  /// unsent one keeps its id — the payload is read from the row at send time.
  Future<void> enqueue(String tableName, String rowId) async {
    final existing = await _outboxRow(tableName, rowId);
    final now = ctx.nowUtc();
    if (existing == null) {
      await db.into(db.syncOutbox).insert(
            SyncOutboxCompanion.insert(
              table: tableName,
              rowId: rowId,
              mutationId: ctx.newId(),
              queuedAt: now,
            ),
          );
      return;
    }
    if (existing.sentClientRev != null) {
      await (db.update(db.syncOutbox)
            ..where((o) => o.table.equals(tableName) & o.rowId.equals(rowId)))
          .write(
        SyncOutboxCompanion(
          mutationId: Value(ctx.newId()),
          sentClientRev: const Value(null),
          queuedAt: Value(now),
          attempts: const Value(0),
          lastError: const Value(null),
        ),
      );
    }
  }

  Future<bool> isDirty(String tableName, String rowId) async =>
      await _outboxRow(tableName, rowId) != null;

  Future<SyncOutboxRow?> _outboxRow(String tableName, String rowId) =>
      (db.select(db.syncOutbox)
            ..where((o) => o.table.equals(tableName) & o.rowId.equals(rowId)))
          .getSingleOrNull();

  // ---------------------------------------------------------------------
  // D22 delete

  Future<void> softDelete(TableInfo<Table, Object?> table, String rowId) {
    assert(db.specOf(table).undoable, '${table.actualTableName} is not undoable');
    return db.transaction(() async {
      final until = _deletePolicy.deadline(ctx.nowUtc());
      await db.customUpdate(
        'UPDATE ${_q(table)} SET pending_delete_until = ? '
        'WHERE id = ? AND deleted_at IS NULL',
        variables: [Variable<String>(utcIso(until)), Variable<String>(rowId)],
        updates: {table},
      );
    });
  }

  Future<void> undoDelete(TableInfo<Table, Object?> table, String rowId) {
    return db.transaction(() async {
      await db.customUpdate(
        'UPDATE ${_q(table)} SET pending_delete_until = NULL WHERE id = ?',
        variables: [Variable<String>(rowId)],
        updates: {table},
      );
    });
  }

  /// Tombstones the row (content NULL, keep keys kept) and enqueues it —
  /// atomically.
  Future<void> commitDelete(TableInfo<Table, Object?> table, String rowId) {
    return db.transaction(() async {
      final now = utcIso(ctx.nowUtc());
      final spec = db.specOf(table);
      final nulls = db.contentColumnsOf(table).map((c) => '"$c" = NULL');
      final sets = <String>[
        ...nulls,
        'deleted_at = ?',
        'client_updated_at = ?',
        'client_rev = client_rev + 1',
        if (spec.undoable) 'pending_delete_until = NULL',
      ];
      await db.customUpdate(
        'UPDATE ${_q(table)} SET ${sets.join(', ')} WHERE id = ? AND deleted_at IS NULL',
        variables: [
          Variable<String>(now),
          Variable<String>(now),
          Variable<String>(rowId),
        ],
        updates: {table},
      );
      await enqueue(table.actualTableName, rowId);
    });
  }

  /// Optimistic local hide (no rev, no outbox). The authoritative tombstone
  /// comes back through pull.
  Future<void> hideLocally(TableInfo<Table, Object?> table, String rowId) {
    return db.transaction(() async {
      await db.customUpdate(
        'UPDATE ${_q(table)} SET deleted_at = ? WHERE id = ? AND deleted_at IS NULL',
        variables: [Variable<String>(utcIso(ctx.nowUtc())), Variable<String>(rowId)],
        updates: {table},
      );
    });
  }

  /// Server-confirmed delete (e.g. 410 request_deleted): the row becomes a
  /// tombstone locally — content and local-only payload columns NULL, keep
  /// keys kept. No rev bump, no outbox.
  Future<void> tombstoneLocally(TableInfo<Table, Object?> table, String rowId) {
    return db.transaction(() async {
      final spec = db.specOf(table);
      final nulls = db.contentColumnsOf(table).map((c) => '"$c" = NULL');
      final sets = <String>[
        ...nulls,
        'deleted_at = COALESCE(deleted_at, ?)',
        if (spec.undoable) 'pending_delete_until = NULL',
      ];
      await db.customUpdate(
        'UPDATE ${_q(table)} SET ${sets.join(', ')} WHERE id = ?',
        variables: [Variable<String>(utcIso(ctx.nowUtc())), Variable<String>(rowId)],
        updates: {table},
      );
    });
  }

  /// Physically removes a row (with its outbox entry) ONLY when the server
  /// can never have seen it: no `server_version` AND no send attempt
  /// (`sent_client_rev` null or no outbox row). A row whose push may have
  /// reached the server with the response lost is left alone — the caller
  /// must tombstone it through [commitDelete] instead. Returns true when the
  /// row was removed (or never existed).
  Future<bool> deleteIfLocalOnly(
    TableInfo<Table, Object?> table,
    String rowId,
  ) {
    return db.transaction(() async {
      final raw = await _rawRow(table, rowId);
      if (raw == null) return true;
      if (raw['server_version'] != null) return false;
      final outbox = await _outboxRow(table.actualTableName, rowId);
      if (outbox != null && outbox.sentClientRev != null) return false;
      await db.customUpdate(
        'DELETE FROM ${_q(table)} WHERE id = ?',
        variables: [Variable<String>(rowId)],
        updates: {table},
        updateKind: UpdateKind.delete,
      );
      await (db.delete(db.syncOutbox)
            ..where(
              (o) => o.table.equals(table.actualTableName) & o.rowId.equals(rowId),
            ))
          .go();
      return true;
    });
  }

  // ---------------------------------------------------------------------
  // Server → local (D2 applyServer path)

  /// Upserts server rows (snake_case keys, JSON values). Tombstones are
  /// stored as they come (content null) and also drop the local-only payload
  /// columns (`confirmed_marks_json`, `pending_delete_until`). Live rows keep
  /// their local-only columns; `base_server_version` becomes the row's
  /// server version.
  Future<ApplyServerReport> applyServer(
    TableInfo<Table, Object?> table,
    Iterable<Map<String, Object?>> rows,
  ) {
    return db.transaction(() async {
      final columns = table.$columns.map((c) => c.$name).toSet();
      var applied = 0;
      final dirty = <String>[];
      for (final raw in rows) {
        final id = raw['id'];
        if (id is! String) continue;
        final existing = await _rawRow(table, id);
        final deleted = raw['deleted_at'] != null;
        final data = <String, Object?>{for (final c in columns) c: null};
        if (existing != null) {
          for (final c in localOnlyColumns) {
            if (!columns.contains(c)) continue;
            if (deleted && c != 'client_rev' && c != 'base_server_version') continue;
            data[c] = existing[c];
          }
          if (await isDirty(table.actualTableName, id)) dirty.add(id);
        }
        for (final e in raw.entries) {
          if (!columns.contains(e.key)) continue;
          data[e.key] = normalizeServerValue(e.value);
        }
        data['client_rev'] = existing?['client_rev'] ?? 1;
        data['base_server_version'] = data['server_version'];
        final entity = table.map(data) as Insertable<Object?>;
        // Delete + insert rather than ON CONFLICT DO UPDATE: drift's upsert
        // treats null columns as "absent", which would keep stale content on
        // a row that the server turned into a tombstone.
        if (existing != null) {
          await db.customUpdate(
            'DELETE FROM ${_q(table)} WHERE id = ?',
            variables: [Variable<String>(id)],
            updates: {table},
            updateKind: UpdateKind.delete,
          );
        }
        await db.into(table).insert(entity);
        applied++;
      }
      return ApplyServerReport(applied: applied, dirtyOverwritten: dirty);
    });
  }

  /// Partial server update of one row (reading-* responses). Only the given
  /// columns change; when `server_version` is among them,
  /// `base_server_version` follows it. No rev bump, no outbox.
  Future<int> applyServerColumns(
    TableInfo<Table, Object?> table,
    String rowId,
    Map<String, Object?> columns,
  ) {
    if (columns.isEmpty) return Future<int>.value(0);
    return db.transaction(() async {
      final sets = <String>[];
      final vars = <Variable<Object>>[];
      for (final e in columns.entries) {
        sets.add('"${e.key}" = ?');
        vars.add(Variable<Object>(normalizeServerValue(e.value)));
      }
      if (columns.containsKey('server_version')) {
        sets.add('base_server_version = ?');
        vars.add(Variable<Object>(columns['server_version']));
      }
      vars.add(Variable<Object>(rowId));
      return db.customUpdate(
        'UPDATE ${_q(table)} SET ${sets.join(', ')} WHERE id = ?',
        variables: vars,
        updates: {table},
      );
    });
  }

  /// JSON → SQL representation: nested JSON becomes text, bools become 0/1,
  /// DateTime becomes ISO UTC text.
  static Object? normalizeServerValue(Object? v) {
    if (v is Map || v is List) return jsonEncode(v);
    if (v is bool) return v ? 1 : 0;
    if (v is DateTime) return utcIso(v);
    return v;
  }

  Future<Map<String, Object?>?> _rawRow(
    TableInfo<Table, Object?> table,
    String id,
  ) async {
    final row = await db
        .customSelect(
          'SELECT * FROM ${_q(table)} WHERE id = ?',
          variables: [Variable<String>(id)],
          readsFrom: {table},
        )
        .getSingleOrNull();
    return row?.data;
  }

  // ---------------------------------------------------------------------
  // sync_meta

  Future<int> purgeEpoch() async {
    final row = await (db.select(db.syncMeta)..where((m) => m.key.equals('purge_epoch')))
        .getSingleOrNull();
    return int.tryParse(row?.value ?? '') ?? 0;
  }
}
