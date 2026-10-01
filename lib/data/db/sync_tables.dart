// Sync table registry (S02). Mirrors docs/data-model.md §3: which columns
// survive a tombstone and which tables support the D22 undo window.

import 'package:drift/drift.dart';

import 'app_database.dart';

/// D2 common columns (never nulled on a tombstone).
const Set<String> syncCommonColumns = <String>{
  'id',
  'user_id',
  'created_at',
  'client_updated_at',
  'deleted_at',
  'device_id',
  'client_rev',
  'base_server_version',
  'server_version',
  'server_seq',
  'purge_epoch',
  'pending_delete_until',
};

/// Columns that exist only locally and are never part of a server row.
/// `applyServer` preserves their current value.
const Set<String> localOnlyColumns = <String>{
  'client_rev',
  'base_server_version',
  'pending_delete_until',
  'confirmed_marks_json',
};

class SyncTableSpec {
  const SyncTableSpec({
    required this.name,
    this.keepKeys = const <String>{},
    this.undoable = false,
  });

  final String name;

  /// `tombstone_keep` (data-model.md §3).
  final Set<String> keepKeys;

  /// D22 5-second undo window.
  final bool undoable;
}

const Map<String, SyncTableSpec> syncTableSpecs = <String, SyncTableSpec>{
  'subjects': SyncTableSpec(name: 'subjects', undoable: true),
  'sessions': SyncTableSpec(name: 'sessions', undoable: true),
  'session_segments':
      SyncTableSpec(name: 'session_segments', keepKeys: <String>{'session_id'}),
  'corrections':
      SyncTableSpec(name: 'corrections', keepKeys: <String>{'session_id'}),
  'planner_items': SyncTableSpec(
    name: 'planner_items',
    keepKeys: <String>{'recurrence_id'},
    undoable: true,
  ),
  'recurrences': SyncTableSpec(name: 'recurrences', undoable: true),
  'reading_requests':
      SyncTableSpec(name: 'reading_requests', keepKeys: <String>{'request_id'}),
  'wrong_items':
      SyncTableSpec(name: 'wrong_items', keepKeys: <String>{'request_id'}),
  'review_entries':
      SyncTableSpec(name: 'review_entries', keepKeys: <String>{'wrong_item_id'}),
  'retry_records':
      SyncTableSpec(name: 'retry_records', keepKeys: <String>{'wrong_item_id'}),
  'settings': SyncTableSpec(name: 'settings'),
  'activity_days': SyncTableSpec(name: 'activity_days', keepKeys: <String>{'date'}),
};

extension SyncTableLookup on AppDatabase {
  /// Sync table by its SQL name.
  TableInfo<Table, Object?> syncTableNamed(String name) =>
      syncTables.firstWhere((t) => t.actualTableName == name);

  SyncTableSpec specOf(TableInfo<Table, Object?> table) =>
      syncTableSpecs[table.actualTableName]!;

  /// Content columns of [table] (nulled on a tombstone).
  List<String> contentColumnsOf(TableInfo<Table, Object?> table) {
    final keep = specOf(table).keepKeys;
    return <String>[
      for (final c in table.$columns)
        if (!syncCommonColumns.contains(c.$name) && !keep.contains(c.$name))
          c.$name,
    ];
  }
}
