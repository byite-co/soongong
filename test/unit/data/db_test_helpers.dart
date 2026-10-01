// Shared helpers for repository tests (S02): in-memory drift database, a
// fixed clock, sequential ids and raw-row inspection.

import 'package:drift/drift.dart';
import 'package:soongong/core/contracts/reading_engine.dart';
import 'package:soongong/core/domain/clock.dart';
import 'package:soongong/core/domain/enums.dart';
import 'package:soongong/data/db/app_database.dart';
import 'package:soongong/data/repositories/repositories.dart';
import 'package:soongong/features/measure/domain/segment.dart';

final DateTime kT0 = DateTime.utc(2026, 9, 30, 3); // 12:00 KST

class TestHarness {
  TestHarness._(this.db, this.clock, this.ctx, this.writer);

  factory TestHarness({String userId = 'u1', String deviceId = 'dev-a'}) {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
    final db = AppDatabase.inMemory();
    final clock = FixedClock(kT0);
    var n = 0;
    final ctx = WriteContext(
      userId: userId,
      deviceId: deviceId,
      clock: clock,
      newId: () => 'id-${(++n).toString().padLeft(3, '0')}',
    );
    final writer = SyncWriter(db, ctx);
    return TestHarness._(db, clock, ctx, writer);
  }

  final AppDatabase db;
  final FixedClock clock;
  final WriteContext ctx;
  final SyncWriter writer;

  late final SubjectRepository subjects = SubjectRepository(db, writer);
  late final SessionRepository sessions = SessionRepository(db, writer);
  late final PlannerRepository planner = PlannerRepository(db, writer);
  late final ReadingRepository reading = ReadingRepository(db, writer);
  late final WrongsRepository wrongs = WrongsRepository(db, writer);
  late final ReviewRepository review = ReviewRepository(db, writer);
  late final SettingsRepository settings = SettingsRepository(db, writer);
  late final SubscriptionRepository subscription = SubscriptionRepository(db, ctx);
  late final QuotaRepository quota = QuotaRepository(db, ctx);
  late final ActivityRepository activity = ActivityRepository(db, writer);
  late final DeleteSettler settler = DeleteSettler(
    db: db,
    ctx: ctx,
    subjects: subjects,
    sessions: sessions,
    planner: planner,
  );

  Future<void> close() => db.close();

  /// Raw SQL row (column name → value) or null.
  Future<Map<String, Object?>?> raw(String table, String id) async {
    final r = await db
        .customSelect(
          'SELECT * FROM "$table" WHERE id = ?',
          variables: [Variable<String>(id)],
        )
        .getSingleOrNull();
    return r?.data;
  }

  Future<List<SyncOutboxRow>> outbox([String? table]) => (db.select(db.syncOutbox)
        ..where((o) => table == null ? const Constant(true) : o.table.equals(table)))
      .get();

  Future<SyncOutboxRow?> outboxRow(String table, String id) => (db.select(db.syncOutbox)
        ..where((o) => o.table.equals(table) & o.rowId.equals(id)))
      .getSingleOrNull();

  /// Marks the outbox entry as sent (what S13 does before a push).
  Future<void> markSent(String table, String id, int clientRev) =>
      (db.update(db.syncOutbox)
            ..where((o) => o.table.equals(table) & o.rowId.equals(id)))
          .write(SyncOutboxCompanion(sentClientRev: Value(clientRev)));
}

/// A minimal server row for [table] with D2 common fields; [content] is
/// merged in. Pass `deleted: true` for a tombstone (content omitted).
Map<String, Object?> serverRow(
  String id, {
  required String userId,
  int serverVersion = 1,
  int serverSeq = 1,
  bool deleted = false,
  Map<String, Object?> content = const <String, Object?>{},
}) =>
    <String, Object?>{
      'id': id,
      'user_id': userId,
      'created_at': '2026-09-01T00:00:00.000Z',
      'client_updated_at': '2026-09-01T00:00:00.000Z',
      'deleted_at': deleted ? '2026-09-02T00:00:00.000Z' : null,
      'device_id': 'dev-b',
      'server_version': serverVersion,
      'server_seq': serverSeq,
      'purge_epoch': 0,
      ...content,
    };

/// Seated segment [fromMin]..[toMin] after [kT0].
class SegmentFixture {
  const SegmentFixture(this.id, this.fromMin, this.toMin);

  final String id;
  final int fromMin;
  final int toMin;

  Segment toSegment() => Segment(
        id: id,
        kind: SegmentKind.seated,
        startAt: kT0.add(Duration(minutes: fromMin)),
        endAt: kT0.add(Duration(minutes: toMin)),
      );
}

class WrongItemDraftFixture {
  const WrongItemDraftFixture(this.id, {this.number = 3, this.page = 0});

  final String id;
  final int number;
  final int page;

  WrongItemDraft toDraft() => WrongItemDraft(
        id: id,
        pageIndex: page,
        number: number,
        mark: Mark.wrong,
        confidence: 0.5,
        userConfirmed: true,
      );
}
