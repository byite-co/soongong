// PlannerRepository (S02). `planner_items` · `recurrences`. Date keys are
// local `yyyy-MM-dd`; a 기간 띠 is `kind = event` with band_start/band_end.
// Patch parameters use drift's `Value` so "unset" and "null" stay distinct.

import 'package:drift/drift.dart';

import '../../core/domain/entities/entities.dart';
import '../../core/domain/enums.dart';
import '../../core/domain/local_date.dart';
import '../db/app_database.dart';
import 'mappers.dart';
import 'sync_writer.dart';
import 'write_context.dart';

class PlannerRepository {
  PlannerRepository(this.db, this.writer);

  final AppDatabase db;
  final SyncWriter writer;

  WriteContext get ctx => writer.ctx;
  $PlannerItemsTable get _t => db.plannerItems;
  $RecurrencesTable get _r => db.recurrences;

  Expression<bool> _live($PlannerItemsTable t) =>
      t.userId.equals(ctx.userId) &
      t.deletedAt.isNull() &
      t.pendingDeleteUntil.isNull();

  Expression<bool> _liveRec($RecurrencesTable t) =>
      t.userId.equals(ctx.userId) &
      t.deletedAt.isNull() &
      t.pendingDeleteUntil.isNull();

  // ---------------------------------------------------------------------
  // Items — reads

  /// Items of one local day, including bands covering it.
  Stream<List<PlannerItem>> watchItemsOn(LocalDate day) =>
      watchItemsBetween(day, day);

  /// Items dated inside [from]..[to] plus bands overlapping the range.
  Stream<List<PlannerItem>> watchItemsBetween(LocalDate from, LocalDate to) =>
      _rangeQuery(from, to).watch().map((rows) => liveOnly(rows.map(plannerItemOf)));

  Future<List<PlannerItem>> getItemsBetween(LocalDate from, LocalDate to) async =>
      liveOnly((await _rangeQuery(from, to).get()).map(plannerItemOf));

  SimpleSelectStatement<$PlannerItemsTable, PlannerItemRow> _rangeQuery(
    LocalDate from,
    LocalDate to,
  ) =>
      db.select(_t)
        ..where(
          (t) =>
              _live(t) &
              ((t.date.isBiggerOrEqualValue(from.key) &
                      t.date.isSmallerOrEqualValue(to.key)) |
                  (t.bandStart.isSmallerOrEqualValue(to.key) &
                      t.bandEnd.isBiggerOrEqualValue(from.key))),
        )
        ..orderBy([
          (t) => OrderingTerm.asc(t.date),
          (t) => OrderingTerm.asc(t.sortOrder),
        ]);

  Stream<List<PlannerItem>> watchAllItems() => (db.select(_t)
        ..where(_live)
        ..orderBy([
          (t) => OrderingTerm.asc(t.date),
          (t) => OrderingTerm.asc(t.sortOrder),
        ]))
      .watch()
      .map((rows) => liveOnly(rows.map(plannerItemOf)));

  Future<List<PlannerItem>> getAllItems() async => liveOnly(
        (await (db.select(_t)
                  ..where(_live)
                  ..orderBy([
                    (t) => OrderingTerm.asc(t.date),
                    (t) => OrderingTerm.asc(t.sortOrder),
                  ]))
                .get())
            .map(plannerItemOf),
      );

  Stream<PlannerItem?> watchItem(String id) =>
      (db.select(_t)..where((t) => t.id.equals(id)))
          .watchSingleOrNull()
          .map((r) => r == null ? null : plannerItemOf(r));

  Future<PlannerItem?> getItem(String id) async {
    final r = await (db.select(_t)..where((t) => t.id.equals(id))).getSingleOrNull();
    return r == null ? null : plannerItemOf(r);
  }

  // ---------------------------------------------------------------------
  // Items — writes

  Future<PlannerItem> createItem({
    required PlannerKind kind,
    required String title,
    required LocalDate date,
    String? subjectId,
    String? rangeText,
    int? targetMinutes,
    LocalTime? startTime,
    LocalTime? endTime,
    LocalDate? bandStart,
    LocalDate? bandEnd,
    String? recurrenceId,
  }) {
    return writer.runInTransaction(() async {
      final now = ctx.nowUtc();
      final id = ctx.newId();
      await db.into(_t).insert(
            PlannerItemsCompanion.insert(
              id: id,
              userId: ctx.userId,
              createdAt: now,
              clientUpdatedAt: now,
              deviceId: ctx.deviceId,
              purgeEpoch: Value(await writer.purgeEpoch()),
              kind: Value(kind),
              title: Value(title),
              subjectId: Value(subjectId),
              rangeText: Value(rangeText),
              targetMinutes: Value(targetMinutes),
              date: Value(date.key),
              startTime: Value(startTime?.key),
              endTime: Value(endTime?.key),
              isDone: const Value(false),
              recurrenceId: Value(recurrenceId),
              bandStart: Value(bandStart?.key),
              bandEnd: Value(bandEnd?.key),
              sortOrder: Value(await _nextSortOrder(date)),
            ),
          );
      await writer.enqueue(_t.actualTableName, id);
      return (await getItem(id))!;
    });
  }

  /// Edit-mode save (`editItem`). Only the given fields change.
  Future<void> updateItem(
    String id, {
    Value<PlannerKind> kind = const Value.absent(),
    Value<String> title = const Value.absent(),
    Value<String?> subjectId = const Value.absent(),
    Value<String?> rangeText = const Value.absent(),
    Value<int?> targetMinutes = const Value.absent(),
    Value<LocalDate> date = const Value.absent(),
    Value<LocalTime?> startTime = const Value.absent(),
    Value<LocalTime?> endTime = const Value.absent(),
    Value<LocalDate?> bandStart = const Value.absent(),
    Value<LocalDate?> bandEnd = const Value.absent(),
    Value<int> sortOrder = const Value.absent(),
  }) {
    return writer.runInTransaction(() async {
      await (db.update(_t)..where((t) => t.id.equals(id))).write(
        PlannerItemsCompanion(
          kind: kind.present ? Value(kind.value) : const Value.absent(),
          title: title.present ? Value(title.value) : const Value.absent(),
          subjectId: subjectId.present ? Value(subjectId.value) : const Value.absent(),
          rangeText: rangeText.present ? Value(rangeText.value) : const Value.absent(),
          targetMinutes:
              targetMinutes.present ? Value(targetMinutes.value) : const Value.absent(),
          date: date.present ? Value(date.value.key) : const Value.absent(),
          startTime: startTime.present ? Value(startTime.value?.key) : const Value.absent(),
          endTime: endTime.present ? Value(endTime.value?.key) : const Value.absent(),
          bandStart: bandStart.present ? Value(bandStart.value?.key) : const Value.absent(),
          bandEnd: bandEnd.present ? Value(bandEnd.value?.key) : const Value.absent(),
          sortOrder: sortOrder.present ? Value(sortOrder.value) : const Value.absent(),
        ),
      );
      await writer.markUserWrite(_t, id);
    });
  }

  Future<void> setDone(String id, {required bool done}) {
    return writer.runInTransaction(() async {
      final now = ctx.nowUtc();
      await (db.update(_t)..where((t) => t.id.equals(id))).write(
        PlannerItemsCompanion(
          isDone: Value(done),
          doneAt: Value(done ? now : null),
        ),
      );
      await writer.markUserWrite(_t, id, at: now);
    });
  }

  /// Persists [orderedIds] as sort_order 0..n-1 within a day.
  Future<void> reorder(List<String> orderedIds) {
    return writer.runInTransaction(() async {
      for (var i = 0; i < orderedIds.length; i++) {
        await (db.update(_t)..where((t) => t.id.equals(orderedIds[i])))
            .write(PlannerItemsCompanion(sortOrder: Value(i)));
        await writer.markUserWrite(_t, orderedIds[i]);
      }
    });
  }

  Future<void> softDeleteItem(String id) => writer.softDelete(_t, id);
  Future<void> undoDeleteItem(String id) => writer.undoDelete(_t, id);
  Future<void> commitDeleteItem(String id) => writer.commitDelete(_t, id);

  Future<ApplyServerReport> applyServerItems(Iterable<Map<String, Object?>> rows) =>
      writer.applyServer(_t, rows);

  Future<int> _nextSortOrder(LocalDate date) async {
    final max = _t.sortOrder.max();
    final row = await (db.selectOnly(_t)
          ..addColumns([max])
          ..where(_live(_t) & _t.date.equals(date.key)))
        .getSingle();
    return (row.read(max) ?? -1) + 1;
  }

  // ---------------------------------------------------------------------
  // Recurrences

  Stream<List<Recurrence>> watchRecurrences() => (db.select(_r)
        ..where(_liveRec)
        ..orderBy([(t) => OrderingTerm.asc(t.startTime)]))
      .watch()
      .map((rows) => liveOnly(rows.map(recurrenceOf)));

  Future<List<Recurrence>> getRecurrences() async => liveOnly(
        (await (db.select(_r)
                  ..where(_liveRec)
                  ..orderBy([(t) => OrderingTerm.asc(t.startTime)]))
                .get())
            .map(recurrenceOf),
      );

  Future<Recurrence?> getRecurrence(String id) async {
    final r = await (db.select(_r)..where((t) => t.id.equals(id))).getSingleOrNull();
    return r == null ? null : recurrenceOf(r);
  }

  Future<Recurrence> createRecurrence({
    required String title,
    required int weekdayMask,
    required LocalTime startTime,
    required LocalTime endTime,
    String? subjectId,
    LocalDate? endsOn,
  }) {
    assert(weekdayMask > 0 && weekdayMask < 128, 'weekday mask 1..127');
    assert(endTime > startTime, 'end after start');
    return writer.runInTransaction(() async {
      final now = ctx.nowUtc();
      final id = ctx.newId();
      await db.into(_r).insert(
            RecurrencesCompanion.insert(
              id: id,
              userId: ctx.userId,
              createdAt: now,
              clientUpdatedAt: now,
              deviceId: ctx.deviceId,
              purgeEpoch: Value(await writer.purgeEpoch()),
              title: Value(title),
              subjectId: Value(subjectId),
              weekdayMask: Value(weekdayMask),
              startTime: Value(startTime.key),
              endTime: Value(endTime.key),
              endsOn: Value(endsOn?.key),
              active: const Value(true),
            ),
          );
      await writer.enqueue(_r.actualTableName, id);
      return (await getRecurrence(id))!;
    });
  }

  /// Whole-recurrence edit (v1: no per-occurrence exceptions).
  Future<void> updateRecurrence(
    String id, {
    Value<String> title = const Value.absent(),
    Value<String?> subjectId = const Value.absent(),
    Value<int> weekdayMask = const Value.absent(),
    Value<LocalTime> startTime = const Value.absent(),
    Value<LocalTime> endTime = const Value.absent(),
    Value<LocalDate?> endsOn = const Value.absent(),
    Value<bool> active = const Value.absent(),
  }) {
    return writer.runInTransaction(() async {
      await (db.update(_r)..where((t) => t.id.equals(id))).write(
        RecurrencesCompanion(
          title: title.present ? Value(title.value) : const Value.absent(),
          subjectId: subjectId.present ? Value(subjectId.value) : const Value.absent(),
          weekdayMask: weekdayMask.present ? Value(weekdayMask.value) : const Value.absent(),
          startTime: startTime.present ? Value(startTime.value.key) : const Value.absent(),
          endTime: endTime.present ? Value(endTime.value.key) : const Value.absent(),
          endsOn: endsOn.present ? Value(endsOn.value?.key) : const Value.absent(),
          active: active.present ? Value(active.value) : const Value.absent(),
        ),
      );
      await writer.markUserWrite(_r, id);
    });
  }

  Future<void> softDeleteRecurrence(String id) => writer.softDelete(_r, id);
  Future<void> undoDeleteRecurrence(String id) => writer.undoDelete(_r, id);
  Future<void> commitDeleteRecurrence(String id) => writer.commitDelete(_r, id);

  Future<ApplyServerReport> applyServerRecurrences(
    Iterable<Map<String, Object?>> rows,
  ) =>
      writer.applyServer(_r, rows);
}
