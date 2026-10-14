import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:soongong/data/auth/account_binding.dart';
import 'package:soongong/data/db/app_database.dart';
import 'package:soongong/data/db/database_protection.dart';
import 'package:soongong/data/db/encrypted_database.dart';
import 'package:soongong/data/repositories/local_purge.dart';
import 'package:soongong/data/repositories/sync_writer.dart';
import 'package:soongong/data/repositories/write_context.dart';
import 'package:soongong/data/temp/owned_temp_store.dart';
import 'package:soongong/data/temp/temp_ownership.dart';

void main() {
  late Directory sandbox;
  late Directory root;
  late File databaseFile;
  late AppDatabase db;
  late OwnedTempStore store;
  late TempOwnership ownership;
  var failDelete = false;
  const ownerA = 'synthetic-account-a@example.invalid';
  const ownerB = 'synthetic-account-b@example.invalid';

  setUp(() async {
    sandbox = Directory.systemTemp.createTempSync('temp-owner-test-');
    root = Directory(p.join(sandbox.path, 'soongong-owned-v1'))..createSync();
    databaseFile = File(p.join(sandbox.path, 'soongong_dev.sqlite'));
    final key = List.filled(32, '7a').join();
    DatabaseProtection(databaseFile, key).prepare();
    db = await requireReadyDatabase(
      AppDatabase(
        encryptedDatabaseFromPrepared(PreparedDatabase(databaseFile.path, key)),
      ),
    );
    failDelete = false;
    store = OwnedTempStore(
      () async => root,
      removeFile: (file) {
        if (failDelete && p.basename(file.path) == 'payload.bin') {
          throw const FileSystemException('synthetic-delete-failure');
        }
        file.deleteSync();
      },
    );
    ownership = TempOwnership(db, store);
  });
  tearDown(() async {
    ownership.dispose();
    await db.close();
    await sandbox.delete(recursive: true);
  });

  Future<SyncWriter> bind(String owner) async {
    await db
        .into(db.syncMeta)
        .insertOnConflictUpdate(
          SyncMetaCompanion.insert(
            key: SyncWriter.accountUserIdKey,
            value: owner,
          ),
        );
    final writer = SyncWriter(
      db,
      WriteContext(userId: owner, deviceId: 'synthetic-device'),
    );
    await writer.refreshPurgeGeneration();
    return writer;
  }

  Future<OwnedTempTask> create(SyncWriter writer, String kind) =>
      ownership.create(
        writer,
        kind,
        generation: writer.purgeGeneration!,
        alive: () => true,
      );

  test(
    'TMP-01 account mapping is in real encrypted DB and absent from plaintext ledger',
    () async {
      final writer = await bind(ownerA);
      final task = await create(writer, 'export');
      final mappingRow = await (db.select(
        db.syncMeta,
      )..where((row) => row.key.equals(TempOwnership.key))).getSingle();
      final mapping = jsonDecode(mappingRow.value) as Map<String, dynamic>;
      expect(mapping['owner'], ownerA);
      expect(mapping['generation'], writer.purgeGeneration);
      expect(mapping['scope'], task.scope);
      final ledgerFiles = root
          .listSync(recursive: true, followLinks: false)
          .whereType<File>();
      for (final file in ledgerFiles) {
        final text = file.readAsStringSync();
        expect(text, isNot(contains(ownerA)));
        expect(text, isNot(contains(sandbox.path)));
      }
      expect(isPlainDatabase(databaseFile), isFalse);
      expect(
        String.fromCharCodes(databaseFile.readAsBytesSync()),
        isNot(contains(ownerA)),
      );
    },
  );

  test(
    'TMP-08 DB wipe and account rebind preserve old cleanup obligation and new bytes',
    () async {
      final writerA = await bind(ownerA);
      final a = await create(writerA, 'export');
      final aFile = a.file('payload.bin')..writeAsStringSync('old-a-content');
      a.markShared();
      a.release();
      failDelete = true;
      final failed = await ownership.revoke(ownerA);
      expect(failed.complete, isFalse);
      expect(aFile.existsSync(), isTrue);
      expect(
        File(p.join(a.directory.parent.path, '.revoked')).existsSync(),
        isTrue,
      );
      await db.wipeAll();
      expect(
        await (db.select(
          db.syncMeta,
        )..where((row) => row.key.equals(TempOwnership.key))).getSingleOrNull(),
        isNull,
      );

      final writerB = await bind(ownerB);
      final b = await create(writerB, 'picker');
      final bFile = b.file('payload.bin')..writeAsStringSync('new-b-content');
      expect(a.scope, isNot(b.scope));
      expect(
        () => a.file('late-old-a.bin'),
        throwsA(isA<TempStoreUnavailable>()),
      );
      failDelete = false;
      expect((await a.cleanup()).complete, isTrue);
      expect(aFile.existsSync(), isFalse);
      expect(bFile.readAsStringSync(), 'new-b-content');

      // Simulate a fresh coordinator after restart. B is already handed off and
      // within grace; old A's independent tombstone must remain authoritative.
      b.markShared();
      b.release();
      final restarted = OwnedTempStore(() async => root);
      expect(await restarted.isRevoked(a.scope), isTrue);
      expect((await restarted.sweep()).complete, isTrue);
      expect(bFile.readAsStringSync(), 'new-b-content');
    },
  );

  test(
    'TMP-08 restart recovers failed old-scope deletion after the mapping was wiped',
    () async {
      final task = await create(await bind(ownerA), 'export');
      final file = task.file('payload.bin')
        ..writeAsStringSync('old-obligation');
      task.markShared();
      task.release();
      failDelete = true;
      expect((await ownership.revoke(ownerA)).complete, isFalse);
      await db.wipeAll();
      final restarted = OwnedTempStore(() async => root);
      expect(await restarted.isRevoked(task.scope), isTrue);
      expect((await restarted.sweep()).complete, isTrue);
      expect(file.existsSync(), isFalse);
    },
  );

  test(
    'TMP-08 failed durable revocation blocks success and retains encrypted mapping',
    () async {
      final task = await create(await bind(ownerA), 'picker');
      final file = task.file('payload.bin')
        ..writeAsStringSync('preserve-until-retry');
      final revokedPath = p.join(task.directory.parent.path, '.revoked');
      Directory(revokedPath).createSync(); // A real filesystem write conflict.
      await expectLater(
        ownership.revoke(ownerA),
        throwsA(anyOf(isA<TempStoreUnavailable>(), isA<FileSystemException>())),
      );
      expect(file.readAsStringSync(), 'preserve-until-retry');
      final row = await (db.select(
        db.syncMeta,
      )..where((m) => m.key.equals(TempOwnership.key))).getSingleOrNull();
      expect(row, isNotNull);
      Directory(revokedPath).deleteSync();
      expect((await ownership.revoke(ownerA)).complete, isTrue);
      expect(file.existsSync(), isFalse);
    },
  );

  test(
    'DEL-04 delayed old A revoke cannot collect the fresh A scope after A to B to A',
    () async {
      final old = await create(await bind(ownerA), 'export');
      old.file('payload.bin').writeAsStringSync('old-a');
      final entered = Completer<void>();
      final continueSwitch = Completer<void>();
      late OwnedTempTask fresh;
      final binding = AccountBinding(db, temporary: ownership);
      // The transaction is a real Drift executor lock. The old revoke below
      // starts outside its zone, so its mapping query cannot finish until this
      // transaction commits the new account's mapping and task.
      final switching = db.transaction(() async {
        entered.complete();
        await continueSwitch.future;
        await binding.bind(ownerB);
        await binding.bind(ownerA);
        ownership.endBoundary(ownerA);
        fresh = await create(await bind(ownerA), 'export');
        fresh.file('payload.bin').writeAsStringSync('fresh-a');
      });
      await entered.future;
      ownership.beginBoundary(ownerA);
      var oldCompleted = false;
      final delayedRevoke = ownership.revoke(ownerA).then((result) {
        oldCompleted = true;
        return result;
      });
      expect(oldCompleted, isFalse);
      continueSwitch.complete();
      await switching;
      expect((await delayedRevoke).complete, isTrue);
      expect(old.directory.existsSync(), isFalse);
      expect(fresh.scope, isNot(old.scope));
      expect(await store.isRevoked(fresh.scope), isFalse);
      expect(fresh.file('payload.bin').readAsStringSync(), 'fresh-a');
    },
  );

  test(
    'DEL-05 stale purge generation cannot allocate a task or reuse the old scope',
    () async {
      final writer = await bind(ownerA);
      final oldGeneration = writer.purgeGeneration!;
      final old = await create(writer, 'picker');
      final purge = LocalPurge(db, writer.ctx);
      await purge.markRequested('synthetic-purge-request');
      await expectLater(
        ownership.create(
          writer,
          'picker',
          generation: oldGeneration,
          alive: () => true,
        ),
        throwsA(isA<StateError>()),
      );
      await purge.clearRequested();
      final fresh = await create(writer, 'picker');
      expect(fresh.scope, isNot(old.scope));
      expect(await store.isRevoked(old.scope), isTrue);
      expect(() => old.file('late.bin'), throwsA(isA<TempStoreUnavailable>()));
      expect(fresh.file('fresh.bin').path, contains(fresh.id));
    },
  );
}
