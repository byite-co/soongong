// ActivityRepository (S02). `activity_days` (D15 · D24): one row per local
// day the app was in the foreground, with a deterministic uuid v5 id so two
// devices converge on the same row.

import 'package:drift/drift.dart';

import '../../core/domain/entities/entities.dart';
import '../../core/domain/ids.dart';
import '../../core/domain/local_date.dart';
import '../db/app_database.dart';
import 'mappers.dart';
import 'sync_writer.dart';
import 'write_context.dart';

class ActivityRepository {
  ActivityRepository(this.db, this.writer);

  final AppDatabase db;
  final SyncWriter writer;

  WriteContext get ctx => writer.ctx;
  $ActivityDaysTable get _t => db.activityDays;

  /// Upserts today's row. Returns true when a row was created.
  Future<bool> touch(LocalDate date) {
    return writer.runInTransaction(() async {
      final id = activityDayId(ctx.userId, date);
      final existing =
          await (db.select(_t)..where((t) => t.id.equals(id))).getSingleOrNull();
      if (existing != null) return false;
      final now = ctx.nowUtc();
      await db.into(_t).insert(
            ActivityDaysCompanion.insert(
              id: id,
              userId: ctx.userId,
              createdAt: now,
              clientUpdatedAt: now,
              deviceId: ctx.deviceId,
              purgeEpoch: Value(await writer.purgeEpoch()),
              date: date.key,
            ),
          );
      await writer.enqueue(_t.actualTableName, id);
      return true;
    });
  }

  Future<List<ActivityDay>> getAll() async => liveOnly(
        (await (db.select(_t)
                  ..where((t) => t.userId.equals(ctx.userId) & t.deletedAt.isNull())
                  ..orderBy([(t) => OrderingTerm.asc(t.date)]))
                .get())
            .map(activityDayOf),
      );

  Stream<List<ActivityDay>> watchBetween(LocalDate from, LocalDate to) =>
      (db.select(_t)
            ..where(
              (t) =>
                  t.userId.equals(ctx.userId) &
                  t.deletedAt.isNull() &
                  t.date.isBiggerOrEqualValue(from.key) &
                  t.date.isSmallerOrEqualValue(to.key),
            )
            ..orderBy([(t) => OrderingTerm.asc(t.date)]))
          .watch()
          .map((rows) => liveOnly(rows.map(activityDayOf)));

  Future<ApplyServerReport> applyServer(Iterable<Map<String, Object?>> rows) =>
      writer.applyServer(_t, rows);
}
