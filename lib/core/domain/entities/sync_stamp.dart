// D2 common fields carried by every synchronised entity (S02). Timestamps
// are UTC. `pendingDeleteUntil` exists only on D22 tables and is null for a
// live row that is not in its undo window.

import 'package:freezed_annotation/freezed_annotation.dart';

part 'sync_stamp.freezed.dart';

@freezed
abstract class SyncStamp with _$SyncStamp {
  const factory SyncStamp({
    required String userId,
    required DateTime createdAt,
    required DateTime clientUpdatedAt,
    required String deviceId,
    @Default(1) int clientRev,
    int? baseServerVersion,
    int? serverVersion,
    int? serverSeq,
    @Default(0) int purgeEpoch,
    DateTime? pendingDeleteUntil,
  }) = _SyncStamp;

  const SyncStamp._();

  /// Never confirmed by the server yet.
  bool get isLocalOnly => serverVersion == null;
}

/// A deleted row (D2): only the common fields and the table's keep keys are
/// known. Never decoded into an entity.
class Tombstone {
  const Tombstone({
    required this.table,
    required this.id,
    required this.deletedAt,
    this.keepKeys = const <String, String?>{},
  });

  final String table;
  final String id;
  final DateTime deletedAt;

  /// e.g. `{'request_id': '…'}` for `wrong_items`.
  final Map<String, String?> keepKeys;

  @override
  String toString() => 'Tombstone($table/$id)';
}
