import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:soongong/data/temp/owned_temp_store.dart';

const _scopeA = '00000000-0000-4000-8000-000000000001';
const _scopeB = '00000000-0000-4000-8000-000000000002';

void main() {
  late Directory sandbox;
  late Directory root;
  late DateTime now;
  setUp(() {
    sandbox = Directory.systemTemp.createTempSync('owned-temp-test-');
    root = Directory(p.join(sandbox.path, 'soongong-owned-v1'))..createSync();
    now = DateTime.utc(2026, 10, 13, 3);
  });
  tearDown(() => sandbox.delete(recursive: true));

  OwnedTempStore store({
    TempRetentionPolicy policy = const TempRetentionPolicy(),
    void Function(File)? removeFile,
    List<FileSystemEntity> Function(Directory)? listDirectory,
  }) => OwnedTempStore(
    () async => root,
    now: () => now,
    policy: policy,
    removeFile: removeFile,
    listDirectory: listDirectory,
  );

  File payload(OwnedTempTask task, String value) =>
      task.file('same-name.bin')..writeAsStringSync(value);

  test(
    'TMP-01 two account scopes and two features preserve other bytes',
    () async {
      final ledger = store();
      final aExport = await ledger.create(_scopeA, 'export');
      final aPicker = await ledger.create(_scopeA, 'picker');
      final bExport = await ledger.create(_scopeB, 'export');
      final bPicker = await ledger.create(_scopeB, 'picker');
      payload(aExport, 'a-export');
      payload(aPicker, 'a-picker');
      final b1 = payload(bExport, 'b-export');
      final b2 = payload(bPicker, 'b-picker');
      final external = File(p.join(sandbox.path, 'original.bin'))
        ..writeAsStringSync('external-original');

      expect((await ledger.revoke(_scopeA)).complete, isTrue);
      expect(aExport.directory.existsSync(), isFalse);
      expect(aPicker.directory.existsSync(), isFalse);
      expect(b1.readAsStringSync(), 'b-export');
      expect(b2.readAsStringSync(), 'b-picker');
      expect(external.readAsStringSync(), 'external-original');
      expect(
        () => aExport.file('late.bin'),
        throwsA(isA<TempStoreUnavailable>()),
      );
    },
  );

  test('TMP-02 traversal and similar prefixes are never owned', () async {
    final task = await store().create(_scopeA, 'picker');
    final external = File(p.join('${root.path}-other', 'external.bin'))
      ..parent.createSync()
      ..writeAsStringSync('external');
    expect(
      () => task.file('../external.bin'),
      throwsA(isA<TempStoreUnavailable>()),
    );
    expect(
      () => task.file(external.path),
      throwsA(isA<TempStoreUnavailable>()),
    );
    expect(task.owns(external.path), isFalse);
    expect((await task.cleanup()).complete, isTrue);
    expect(external.readAsStringSync(), 'external');
  });

  for (final position in [
    'payload-file',
    'task-directory',
    'scope-directory',
  ]) {
    test(
      'TMP-02 $position symlink never deletes its external target',
      () async {
        final ledger = store();
        final external = Directory(p.join(sandbox.path, 'outside'))
          ..createSync();
        final original = File(p.join(external.path, 'original.bin'))
          ..writeAsStringSync('outside-preserved');
        final task = await ledger.create(_scopeA, 'picker');
        if (position == 'payload-file') {
          Link(p.join(task.payloadPath, 'link.bin')).createSync(original.path);
        } else if (position == 'task-directory') {
          task.directory.deleteSync(recursive: true);
          Link(task.directory.path).createSync(external.path);
        } else {
          task.directory.parent.deleteSync(recursive: true);
          Link(task.directory.parent.path).createSync(external.path);
        }
        final result = await ledger.revoke(_scopeA);
        expect(result.complete, isFalse);
        expect(result.unknown, isTrue);
        expect(original.readAsStringSync(), 'outside-preserved');
      },
    );
  }

  test(
    'TMP-03 root lookup failure reports unknown and remains retryable',
    () async {
      final task = await store().create(_scopeA, 'picker');
      final file = payload(task, 'owned');
      var unavailable = true;
      final restarting = OwnedTempStore(() async {
        if (unavailable) {
          throw const FileSystemException('synthetic-root-failure');
        }
        return root;
      }, now: () => now);
      final failed = await restarting.sweep();
      expect(failed.complete, isFalse);
      expect(failed.unknown, isTrue);
      expect(file.readAsStringSync(), 'owned');
      unavailable = false;
      expect((await restarting.sweep()).complete, isTrue);
      expect(file.existsSync(), isFalse);
    },
  );

  test(
    'TMP-03 directory enumeration failure cannot be reported as zero remaining',
    () async {
      final task = await store().create(_scopeA, 'export');
      final file = payload(task, 'owned');
      var unavailable = true;
      final restarting = store(
        listDirectory: (dir) {
          if (unavailable && p.equals(dir.path, root.path)) {
            throw const FileSystemException('synthetic-list-failure');
          }
          return dir.listSync(followLinks: false);
        },
      );
      final failed = await restarting.sweep();
      expect(failed.unknown, isTrue);
      expect(failed.complete, isFalse);
      expect(file.existsSync(), isTrue);
      unavailable = false;
      expect((await restarting.sweep()).complete, isTrue);
      expect(file.existsSync(), isFalse);
    },
  );

  test(
    'TMP-04 failed deletion leaves evidence and joined retries converge',
    () async {
      var fail = true;
      final ledger = store(
        removeFile: (file) {
          if (fail && p.basename(file.path) == 'same-name.bin') {
            throw const FileSystemException('synthetic-delete-failure');
          }
          file.deleteSync();
        },
      );
      final task = await ledger.create(_scopeA, 'export');
      final file = payload(task, 'retry-me');
      final failed = await task.cleanup();
      expect(failed.complete, isFalse);
      expect(failed.remaining, 1);
      expect(file.readAsStringSync(), 'retry-me');
      expect(File(p.join(task.directory.path, '.delete')).existsSync(), isTrue);
      fail = false;
      final first = ledger.sweep();
      final second = ledger.sweep();
      expect(identical(first, second), isTrue);
      expect((await first).complete, isTrue);
      expect((await second).complete, isTrue);
      expect(file.existsSync(), isFalse);
      expect((await task.cleanup()).complete, isTrue);
    },
  );

  test(
    'TMP-04 native producer uncertainty keeps the obligation until quiescence',
    () async {
      final ledger = store();
      final task = await ledger.create(_scopeA, 'picker');
      final file = payload(task, 'native-still-writing');
      ledger.beforeDelete = (_, _, _) async => false;
      final pending = await task.cleanup();
      expect(pending.complete, isFalse);
      expect(pending.remaining, 1);
      expect(pending.unknown, isFalse);
      expect(file.readAsStringSync(), 'native-still-writing');
      ledger.beforeDelete = (_, _, _) async =>
          throw StateError('synthetic-channel-failure');
      final unknown = await task.cleanup();
      expect(unknown.complete, isFalse);
      expect(unknown.unknown, isTrue);
      expect(file.existsSync(), isTrue);
      ledger.beforeDelete = (_, _, _) async => true;
      expect((await ledger.sweep()).complete, isTrue);
      expect(file.existsSync(), isFalse);
    },
  );

  test(
    'TMP-05 restart finds a payload whose task marker was interrupted',
    () async {
      final task = await store().create(_scopeA, 'picker');
      final file = payload(task, 'orphan-after-interruption');
      File(p.join(task.directory.path, 'marker.json')).deleteSync();
      expect((await store().sweep()).complete, isTrue);
      expect(file.existsSync(), isFalse);
      expect(task.directory.existsSync(), isFalse);
    },
  );

  test(
    'TMP-06 durable revocation survives interruption before deletion',
    () async {
      final original = store();
      final task = await original.create(_scopeA, 'export');
      final file = payload(task, 'shared-old-owner');
      task.markShared();
      task.release();
      await original.markRevoked(_scopeA);
      expect(file.existsSync(), isTrue);
      final restarted = store();
      expect(await restarted.isRevoked(_scopeA), isTrue);
      expect((await restarted.sweep()).complete, isTrue);
      expect(file.existsSync(), isFalse);
    },
  );

  test(
    'TMP-07 payload absent before ledger removal finishes without an error loop',
    () async {
      final task = await store().create(_scopeA, 'export');
      final file = payload(task, 'already-deleted');
      File(
        p.join(task.directory.path, '.delete'),
      ).writeAsStringSync('1', flush: true);
      file.deleteSync();
      final restarted = store();
      expect((await restarted.sweep()).complete, isTrue);
      expect((await restarted.sweep()).complete, isTrue);
      expect(task.directory.existsSync(), isFalse);
    },
  );

  test(
    'EXP-05/06 delayed reader works within grace and expiry removes the owned copy',
    () async {
      final ledger = store();
      final task = await ledger.create(_scopeA, 'export');
      final file = payload(task, 'delayed-recipient');
      task.markShared();
      task.release();
      now = now.add(const Duration(hours: 23));
      expect((await ledger.sweep()).complete, isTrue);
      expect(file.readAsStringSync(), 'delayed-recipient');
      now = now.add(const Duration(hours: 1));
      expect((await ledger.sweep()).complete, isTrue);
      expect(file.existsSync(), isFalse);
    },
  );

  test(
    'EXP-07 restart recovers shared path and keeps creation-based expiry',
    () async {
      final task = await store().create(_scopeA, 'export');
      final file = payload(task, 'restart-reader');
      task.markShared();
      now = now.add(const Duration(hours: 1));
      final restarted = store();
      expect((await restarted.sweep()).complete, isTrue);
      expect(file.readAsStringSync(), 'restart-reader');
      now = now.add(const Duration(hours: 23));
      expect((await restarted.sweep()).complete, isTrue);
      expect(file.existsSync(), isFalse);
    },
  );

  test(
    'EXP-08 concurrent same-name exports have isolated paths and cleanup',
    () async {
      final ledger = store();
      final tasks = await Future.wait([
        ledger.create(_scopeA, 'export'),
        ledger.create(_scopeA, 'export'),
      ]);
      final first = payload(tasks[0], 'first');
      final second = payload(tasks[1], 'second');
      expect(first.path, isNot(second.path));
      expect(tasks[0].owns(second.path), isFalse);
      expect((await tasks[0].cleanup()).complete, isTrue);
      expect(second.readAsStringSync(), 'second');
      expect((await tasks[1].cleanup()).complete, isTrue);
    },
  );

  test(
    'EXP-10 wall-clock regression ends retention at the next sweep',
    () async {
      final ledger = store();
      final task = await ledger.create(_scopeA, 'export');
      final file = payload(task, 'rollback-clock');
      task.markShared();
      task.release();
      await ledger.sweep();
      now = now.subtract(const Duration(hours: 1));
      expect((await ledger.sweep()).complete, isTrue);
      expect(file.existsSync(), isFalse);
    },
  );

  for (final release in [true, false]) {
    test(
      'EXP-10 frozen clock has bounded retention with release=$release',
      () async {
        final ledger = store(
          policy: const TempRetentionPolicy(
            activeLease: Duration(milliseconds: 10),
            shareGrace: Duration(milliseconds: 20),
          ),
        );
        final task = await ledger.create(_scopeA, 'export');
        final file = payload(task, 'frozen-clock');
        task.markShared();
        if (release) task.release();
        await ledger.sweep();
        // Normal async test, not widget fake time. The wall clock deliberately
        // stays fixed while production monotonic elapsed time advances.
        await Future<void>.delayed(const Duration(milliseconds: 60));
        expect((await ledger.sweep()).complete, isTrue);
        expect(file.existsSync(), isFalse);
      },
    );
  }

  test(
    'EXP-10 invalid future-expiry metadata is an owned orphan, not an indefinite lease',
    () async {
      final task = await store().create(_scopeA, 'export');
      final file = payload(task, 'invalid-marker');
      task.markShared();
      final marker = File(p.join(task.directory.path, 'marker.json'));
      final data =
          jsonDecode(marker.readAsStringSync()) as Map<String, dynamic>;
      data['expires'] = now
          .add(const Duration(days: 36500))
          .millisecondsSinceEpoch;
      marker.writeAsStringSync(jsonEncode(data), flush: true);
      now = now.add(const Duration(hours: 1));
      expect((await store().sweep()).complete, isTrue);
      expect(file.existsSync(), isFalse);
    },
  );

  test(
    'EXP-10 future creation without clock history cannot retain a file indefinitely',
    () async {
      final task = await store().create(_scopeA, 'export');
      final file = payload(task, 'future-created-marker');
      task.markShared();
      final marker = File(p.join(task.directory.path, 'marker.json'));
      final data =
          jsonDecode(marker.readAsStringSync()) as Map<String, dynamic>;
      final future = now.add(const Duration(days: 36500));
      data['created'] = future.millisecondsSinceEpoch;
      data['expires'] = future
          .add(const Duration(hours: 24))
          .millisecondsSinceEpoch;
      marker.writeAsStringSync(jsonEncode(data), flush: true);
      expect(File(p.join(root.path, '.clock')).existsSync(), isFalse);
      expect((await store().sweep()).complete, isTrue);
      expect(file.existsSync(), isFalse);
    },
  );
}
