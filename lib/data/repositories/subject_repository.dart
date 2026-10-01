// SubjectRepository (S02). `subjects` — user writes go through SyncWriter
// (outbox); the default "기타" subject cannot be deleted; deleting a subject
// moves its records to the default one (subjDelN).

import 'package:drift/drift.dart';

import '../../core/domain/entities/entities.dart';
import '../../core/domain/enums.dart';
import '../../core/strings/subjects_strings.dart';
import '../db/app_database.dart';
import 'mappers.dart';
import 'sync_writer.dart';
import 'write_context.dart';

class SubjectRepository {
  SubjectRepository(this.db, this.writer);

  final AppDatabase db;
  final SyncWriter writer;

  WriteContext get ctx => writer.ctx;
  $SubjectsTable get _t => db.subjects;

  /// Colour index of the default subject (8th swatch, grey in the prototype).
  static const int defaultColorIndex = 7;

  Expression<bool> _live($SubjectsTable t) =>
      t.userId.equals(ctx.userId) &
      t.deletedAt.isNull() &
      t.pendingDeleteUntil.isNull();

  SimpleSelectStatement<$SubjectsTable, SubjectRow> _liveQuery() =>
      db.select(_t)
        ..where(_live)
        ..orderBy([(t) => OrderingTerm.asc(t.sortOrder)]);

  Stream<List<Subject>> watchAll() =>
      _liveQuery().watch().map((rows) => liveOnly(rows.map(subjectOf)));

  Future<List<Subject>> getAll() async =>
      liveOnly((await _liveQuery().get()).map(subjectOf));

  Future<Subject?> get(String id) async {
    final row = await (db.select(_t)..where((t) => t.id.equals(id))).getSingleOrNull();
    return row == null ? null : subjectOf(row);
  }

  Stream<Subject?> watch(String id) => (db.select(_t)..where((t) => t.id.equals(id)))
      .watchSingleOrNull()
      .map((r) => r == null ? null : subjectOf(r));

  Future<Subject> create({
    required String name,
    required int colorIndex,
    bool isDefault = false,
  }) {
    return writer.runInTransaction(() async {
      final now = ctx.nowUtc();
      final id = ctx.newId();
      final maxOrder = await _maxSortOrder();
      await db.into(_t).insert(
            SubjectsCompanion.insert(
              id: id,
              userId: ctx.userId,
              createdAt: now,
              clientUpdatedAt: now,
              deviceId: ctx.deviceId,
              purgeEpoch: Value(await writer.purgeEpoch()),
              name: Value(name),
              colorIndex: Value(colorIndex),
              sortOrder: Value(maxOrder + 1),
              isDefault: Value(isDefault),
            ),
          );
      await writer.enqueue(_t.actualTableName, id);
      return (await get(id))!;
    });
  }

  Future<void> update(String id, {String? name, int? colorIndex}) {
    return writer.runInTransaction(() async {
      await (db.update(_t)..where((t) => t.id.equals(id))).write(
        SubjectsCompanion(
          name: Value.absentIfNull(name),
          colorIndex: Value.absentIfNull(colorIndex),
        ),
      );
      await writer.markUserWrite(_t, id);
    });
  }

  /// Persists [orderedIds] as sort_order 0..n-1 (rows not listed keep theirs).
  Future<void> reorder(List<String> orderedIds) {
    return writer.runInTransaction(() async {
      for (var i = 0; i < orderedIds.length; i++) {
        final id = orderedIds[i];
        await (db.update(_t)..where((t) => t.id.equals(id)))
            .write(SubjectsCompanion(sortOrder: Value(i)));
        await writer.markUserWrite(_t, id);
      }
    });
  }

  /// The "기타" subject; created on first use.
  Future<Subject> ensureDefault() async {
    final existing = await (db.select(_t)
          ..where((t) => t.userId.equals(ctx.userId) & t.deletedAt.isNull() & t.isDefault.equals(true)))
        .getSingleOrNull();
    if (existing != null) {
      // A pending-delete default can't happen (guarded), but be safe.
      if (existing.pendingDeleteUntil != null) await writer.undoDelete(_t, existing.id);
      return subjectOf(existing)!;
    }
    return create(
      name: SubjectsStrings.defaultSubjectName,
      colorIndex: defaultColorIndex,
      isDefault: true,
    );
  }

  // ---------------------------------------------------------------------
  // D22 delete

  Future<void> softDelete(String id) async {
    await _guardNotDefault(id);
    await writer.softDelete(_t, id);
  }

  Future<void> undoDelete(String id) => writer.undoDelete(_t, id);

  /// Moves sessions · planner items · wrong items · reading drafts of the
  /// subject to the default subject, then tombstones it.
  Future<void> commitDelete(String id) {
    return writer.runInTransaction(() async {
      await _guardNotDefault(id);
      final fallback = await ensureDefault();
      if (fallback.id == id) throw StateError('default subject cannot be deleted');
      final now = ctx.nowUtc();

      final sessions = await (db.select(db.sessions)
            ..where((s) => s.subjectId.equals(id) & s.deletedAt.isNull()))
          .get();
      for (final s in sessions) {
        await (db.update(db.sessions)..where((t) => t.id.equals(s.id)))
            .write(SessionsCompanion(subjectId: Value(fallback.id)));
        await writer.markUserWrite(db.sessions, s.id, at: now);
      }

      final items = await (db.select(db.plannerItems)
            ..where((p) => p.subjectId.equals(id) & p.deletedAt.isNull()))
          .get();
      for (final p in items) {
        await (db.update(db.plannerItems)..where((t) => t.id.equals(p.id)))
            .write(PlannerItemsCompanion(subjectId: Value(fallback.id)));
        await writer.markUserWrite(db.plannerItems, p.id, at: now);
      }

      final recs = await (db.select(db.recurrences)
            ..where((r) => r.subjectId.equals(id) & r.deletedAt.isNull()))
          .get();
      for (final r in recs) {
        await (db.update(db.recurrences)..where((t) => t.id.equals(r.id)))
            .write(RecurrencesCompanion(subjectId: Value(fallback.id)));
        await writer.markUserWrite(db.recurrences, r.id, at: now);
      }

      final wrongs = await (db.select(db.wrongItems)
            ..where((w) => w.subjectId.equals(id) & w.deletedAt.isNull()))
          .get();
      for (final w in wrongs) {
        await (db.update(db.wrongItems)..where((t) => t.id.equals(w.id)))
            .write(WrongItemsCompanion(subjectId: Value(fallback.id)));
        await writer.markUserWrite(db.wrongItems, w.id, at: now);
      }

      // Only drafts are client-editable (D24); submitted requests keep the
      // id and the UI falls back to the default subject's name.
      final drafts = await (db.select(db.readingRequests)
            ..where(
              (r) =>
                  r.subjectId.equals(id) &
                  r.deletedAt.isNull() &
                  r.status.equalsValue(ReadingRequestStatus.selecting) &
                  r.submittedAt.isNull(),
            ))
          .get();
      for (final r in drafts) {
        await (db.update(db.readingRequests)..where((t) => t.id.equals(r.id)))
            .write(ReadingRequestsCompanion(subjectId: Value(fallback.id)));
        await writer.markUserWrite(db.readingRequests, r.id, at: now);
      }

      await writer.commitDelete(_t, id);
    });
  }

  // ---------------------------------------------------------------------
  // Server → local

  Future<ApplyServerReport> applyServer(Iterable<Map<String, Object?>> rows) =>
      writer.applyServer(_t, rows);

  Future<void> _guardNotDefault(String id) async {
    final row = await (db.select(_t)..where((t) => t.id.equals(id))).getSingleOrNull();
    if (row?.isDefault ?? false) {
      throw StateError('default subject cannot be deleted');
    }
  }

  Future<int> _maxSortOrder() async {
    final max = _t.sortOrder.max();
    final row = await (db.selectOnly(_t)
          ..addColumns([max])
          ..where(_t.userId.equals(ctx.userId) & _t.deletedAt.isNull()))
        .getSingle();
    return row.read(max) ?? -1;
  }
}
