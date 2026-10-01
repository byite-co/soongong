// Schema upgrade v1 → v2 (S02c): a database file created with the v1 schema
// (no partial unique index on review_entries) is opened by the current
// AppDatabase. Data survives, the index exists, and pre-existing duplicate
// live entries are reduced to one per wrong item (losers become tombstones
// with an outbox entry). Separate from the onCreate path, which the
// wrongs_review_repository_test covers.

import 'dart:io';

import 'package:drift/drift.dart' show MigrationStrategy, Value, driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soongong/data/db/app_database.dart';

/// The v1 schema: same tables, no partial unique index, user_version 1.
class _LegacyV1Database extends AppDatabase {
  _LegacyV1Database(super.executor);

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) => m.createAll(),
      );
}

void main() {
  late Directory dir;
  late File file;

  setUp(() async {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
    dir = await Directory.systemTemp.createTemp('soongong_schema_');
    file = File('${dir.path}/legacy.sqlite');
  });

  tearDown(() => dir.delete(recursive: true));

  Future<void> insertEntry(
    AppDatabase db,
    String id,
    String wrongItemId,
    DateTime updatedAt,
  ) =>
      db.into(db.reviewEntries).insert(
            ReviewEntriesCompanion.insert(
              id: id,
              userId: 'u1',
              createdAt: DateTime.utc(2026, 9, 1),
              clientUpdatedAt: updatedAt,
              deviceId: 'd',
              wrongItemId: wrongItemId,
              dueAt: Value(updatedAt),
              intervalDays: const Value(2),
              consecutiveCorrect: const Value(1),
            ),
          );

  Future<int> userVersion(AppDatabase db) async =>
      (await db.customSelect('PRAGMA user_version').getSingle()).read<int>('user_version');

  Future<List<String>> indexNames(AppDatabase db) async => (await db
          .customSelect(
            "SELECT name FROM sqlite_master WHERE type = 'index' AND tbl_name = 'review_entries'",
          )
          .get())
      .map((r) => r.read<String>('name'))
      .toList();

  test('v1 file → v2: rows kept, partial unique index created, user_version 2',
      () async {
    final legacy = _LegacyV1Database(NativeDatabase(file));
    await insertEntry(legacy, 'e1', 'w1', DateTime.utc(2026, 9, 10));
    await insertEntry(legacy, 'e2', 'w2', DateTime.utc(2026, 9, 11));
    await legacy.into(legacy.subjects).insert(
          SubjectsCompanion.insert(
            id: 's1',
            userId: 'u1',
            createdAt: DateTime.utc(2026, 9, 1),
            clientUpdatedAt: DateTime.utc(2026, 9, 1),
            deviceId: 'd',
            name: const Value('수학'),
            colorIndex: const Value(1),
            sortOrder: const Value(0),
            isDefault: const Value(false),
          ),
        );
    expect(await userVersion(legacy), 1);
    expect(await indexNames(legacy), isNot(contains('review_entries_live_wrong_item')));
    await legacy.close();

    final db = AppDatabase(NativeDatabase(file));
    addTearDown(db.close);
    expect(await userVersion(db), 2);
    expect(await indexNames(db), contains('review_entries_live_wrong_item'));
    final entries = await db.select(db.reviewEntries).get();
    expect(entries.map((e) => e.id), containsAll(<String>['e1', 'e2']));
    expect(entries.every((e) => e.deletedAt == null), isTrue);
    expect((await db.select(db.subjects).get()).single.name, '수학');
    expect(await db.select(db.syncOutbox).get(), isEmpty, reason: 'nothing to fix');

    // The index is enforced from now on.
    await expectLater(
      insertEntry(db, 'e1-dup', 'w1', DateTime.utc(2026, 9, 12)),
      throwsA(isA<Exception>()),
    );
  });

  test('v1 file with duplicate live entries: the latest per wrong item is kept, '
      'the rest become tombstones with an outbox entry', () async {
    final legacy = _LegacyV1Database(NativeDatabase(file));
    await insertEntry(legacy, 'old', 'w1', DateTime.utc(2026, 9, 10));
    await insertEntry(legacy, 'newest', 'w1', DateTime.utc(2026, 9, 12));
    await insertEntry(legacy, 'mid', 'w1', DateTime.utc(2026, 9, 11));
    await insertEntry(legacy, 'tie-b', 'w2', DateTime.utc(2026, 9, 5));
    await insertEntry(legacy, 'tie-a', 'w2', DateTime.utc(2026, 9, 5));
    await insertEntry(legacy, 'solo', 'w3', DateTime.utc(2026, 9, 5));
    expect((await legacy.select(legacy.reviewEntries).get()).length, 6, reason: 'v1 allows duplicates');
    await legacy.close();

    final db = AppDatabase(NativeDatabase(file));
    addTearDown(db.close);
    expect(await userVersion(db), 2);
    expect(await indexNames(db), contains('review_entries_live_wrong_item'));

    final rows = await db.select(db.reviewEntries).get();
    expect(rows.length, 6, reason: 'nothing is removed physically');
    final live = rows.where((r) => r.deletedAt == null).map((r) => r.id).toSet();
    expect(live, <String>{'newest', 'tie-a', 'solo'});
    final dead = rows.where((r) => r.deletedAt != null).toList();
    expect(dead.map((r) => r.id).toSet(), <String>{'old', 'mid', 'tie-b'});
    for (final r in dead) {
      expect(r.dueAt, isNull, reason: 'tombstone content nulled');
      expect(r.intervalDays, isNull);
      expect(r.wrongItemId, isNotEmpty, reason: 'keep key');
      expect(r.clientRev, 2);
    }
    final outbox = await db.select(db.syncOutbox).get();
    expect(outbox.map((o) => o.rowId).toSet(), <String>{'old', 'mid', 'tie-b'});
    expect(outbox.every((o) => o.table == 'review_entries' && o.sentClientRev == null), isTrue);
  });
}
