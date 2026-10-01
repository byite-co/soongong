// QuotaRepository (S02). `reading_quota` — read-only cache of the server
// ledger (D16 · D24). Updated only from the pull `ledger` (or a `quota`
// field of a reading-* response). No user write, no outbox, no arithmetic.

import 'package:drift/drift.dart';

import '../../core/domain/entities/entities.dart';
import '../db/app_database.dart';
import 'write_context.dart';

class QuotaRepository {
  QuotaRepository(this.db, this.ctx);

  final AppDatabase db;
  final WriteContext ctx;

  $ReadingQuotasTable get _t => db.readingQuotas;

  Stream<ReadingQuota?> watch(String month) =>
      (db.select(_t)..where((t) => t.userId.equals(ctx.userId) & t.month.equals(month)))
          .watchSingleOrNull()
          .map((r) => r == null ? null : _of(r));

  Future<ReadingQuota?> get(String month) async {
    final r = await (db.select(_t)
          ..where((t) => t.userId.equals(ctx.userId) & t.month.equals(month)))
        .getSingleOrNull();
    return r == null ? null : _of(r);
  }

  /// `{month, used, reserved, limit | quota_limit}` from the server.
  Future<void> applyLedger(Map<String, Object?> json) async {
    final month = json['month'] as String?;
    if (month == null) throw ArgumentError('reading_quota ledger without month');
    await db.into(_t).insertOnConflictUpdate(
          ReadingQuotasCompanion.insert(
            userId: ctx.userId,
            month: month,
            used: _int(json['used']),
            reserved: _int(json['reserved']),
            quotaLimit: _int(json['limit'] ?? json['quota_limit']),
          ),
        );
  }

  ReadingQuota _of(ReadingQuotaRow r) => ReadingQuota(
        userId: r.userId,
        month: r.month,
        used: r.used,
        reserved: r.reserved,
        limit: r.quotaLimit,
      );

  static int _int(Object? v) => switch (v) {
        int() => v,
        num() => v.toInt(),
        String() => int.tryParse(v) ?? 0,
        _ => 0,
      };
}
