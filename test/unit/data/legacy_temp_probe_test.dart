import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:soongong/data/export/export_guard.dart';
import 'package:soongong/data/export/export_service.dart';
import 'package:soongong/data/export/share_export.dart';
import 'package:soongong/data/temp/legacy_temp_probe.dart';
import 'package:soongong/data/temp/owned_temp_store.dart';

const _scopeA = '00000000-0000-4000-8000-000000000001';
const _scopeB = '00000000-0000-4000-8000-000000000002';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory sandbox;
  late Directory cache;
  late Directory owned;
  setUp(() {
    sandbox = Directory.systemTemp.createTempSync('legacy-temp-probe-');
    cache = Directory(p.join(sandbox.path, 'cache'))..createSync();
    owned = Directory(p.join(cache.path, 'soongong-owned-v1'))..createSync();
  });
  tearDown(() => sandbox.deleteSync(recursive: true));

  LegacyTempProbe probe({bool android = false}) =>
      LegacyTempProbe(() async => cache, android: android);

  for (final name in [
    'soongong-export-old',
    'soongong-20261013-0915.json',
    'soongong-20261013-0915.zip',
    'seat_lab_2026-10-13T09-15-00.000.csv',
    'seat_lab_2026-10-13T09-15-00.000_run2.csv',
  ]) {
    for (final directory in [false, true]) {
      test(
        'TMP legacy $name as ${directory ? 'directory' : 'file'} stays unowned and unknown',
        () async {
          final path = p.join(cache.path, name);
          final payload = directory
              ? File(p.join(path, 'synthetic.bin'))
              : File(path);
          payload.parent.createSync(recursive: true);
          payload.writeAsBytesSync([11, 12, 13]);
          expect(await probe().isClean(), isFalse);
          expect(payload.readAsBytesSync(), [11, 12, 13]);
          expect(owned.listSync(), isEmpty);
        },
      );
    }
  }

  test('TMP Android share_plus cache is uncertainty only on Android', () async {
    final payload = File(p.join(cache.path, 'share_plus', 'same.json'))
      ..parent.createSync()
      ..writeAsBytesSync([21, 22]);
    expect(await probe(android: true).isClean(), isFalse);
    expect(await probe().isClean(), isTrue);
    expect(payload.readAsBytesSync(), [21, 22]);
  });

  test(
    'TMP legacy probe scans immediate entries and preserves other features',
    () async {
      final unrelated = File(p.join(cache.path, 'notes.csv'))
        ..writeAsStringSync('unrelated-csv');
      final similar = File(
        p.join(cache.path, 'soongong-20261013-0915.json.bak'),
      )..writeAsStringSync('unrelated-suffix');
      final nested =
          File(
              p.join(
                cache.path,
                'other-feature',
                'soongong-export-nested',
                'raw.bin',
              ),
            )
            ..parent.createSync(recursive: true)
            ..writeAsStringSync('other-feature');
      final outside = File(p.join(sandbox.path, 'soongong-export-outside'))
        ..writeAsStringSync('external-original');
      var lists = 0;
      final reader = LegacyTempProbe(
        () async => cache,
        android: true,
        listDirectory: (directory) {
          lists++;
          expect(directory.path, cache.resolveSymbolicLinksSync());
          return directory.listSync(followLinks: false);
        },
      );
      expect(await reader.isClean(), isTrue);
      expect(lists, 1);
      expect(unrelated.readAsStringSync(), 'unrelated-csv');
      expect(similar.readAsStringSync(), 'unrelated-suffix');
      expect(nested.readAsStringSync(), 'other-feature');
      expect(outside.readAsStringSync(), 'external-original');
    },
  );

  test(
    'TMP legacy root failure missing root and listing failure stay unknown',
    () async {
      final unavailable = LegacyTempProbe(
        () async => throw const FileSystemException('synthetic-root'),
        android: false,
      );
      final missing = LegacyTempProbe(
        () async => Directory(p.join(sandbox.path, 'absent')),
        android: false,
      );
      final unreadable = LegacyTempProbe(
        () async => cache,
        android: false,
        listDirectory: (_) => throw const FileSystemException('synthetic-list'),
      );
      expect(await unavailable.isClean(), isFalse);
      expect(await missing.isClean(), isFalse);
      expect(await unreadable.isClean(), isFalse);
      expect(Directory(p.join(sandbox.path, 'absent')).existsSync(), isFalse);
    },
  );

  test(
    'TMP legacy child stat failure and vanished entry stay unknown',
    () async {
      final file = File(p.join(cache.path, 'notes.txt'))
        ..writeAsStringSync('unrelated');
      final unreadable = LegacyTempProbe(
        () async => cache,
        android: false,
        entryType: (path) {
          if (p.basename(path) == 'notes.txt') {
            throw const FileSystemException('synthetic-stat');
          }
          return FileSystemEntity.typeSync(path, followLinks: false);
        },
      );
      final vanished = LegacyTempProbe(
        () async => cache,
        android: false,
        listDirectory: (_) => [File(p.join(cache.path, 'absent.txt'))],
      );
      expect(await unreadable.isClean(), isFalse);
      expect(await vanished.isClean(), isFalse);
      expect(file.readAsStringSync(), 'unrelated');
    },
  );

  test(
    'TMP legacy links are not followed and a linked root stays unknown',
    () async {
      final outside = Directory(p.join(sandbox.path, 'outside'))..createSync();
      final original = File(p.join(outside.path, 'original.bin'))
        ..writeAsBytesSync([31, 32]);
      final candidate = Link(p.join(cache.path, 'soongong-export-linked'))
        ..createSync(outside.path);
      expect(await probe().isClean(), isFalse);
      candidate.deleteSync();
      Link(p.join(cache.path, 'unrelated-link')).createSync(outside.path);
      expect(await probe().isClean(), isTrue);
      final rootLink = Link(p.join(sandbox.path, 'root-link'))
        ..createSync(cache.path);
      expect(
        await LegacyTempProbe(
          () async => Directory(rootLink.path),
          android: false,
        ).isClean(),
        isFalse,
      );
      expect(original.readAsBytesSync(), [31, 32]);
    },
    skip: Platform.isWindows,
  );

  test(
    'TMP legacy uncertainty continues owned cleanup and retry preserves new B task',
    () async {
      final legacy = File(p.join(cache.path, 'soongong-export-old', 'raw.bin'))
        ..parent.createSync()
        ..writeAsBytesSync([41, 42]);
      final external = File(p.join(sandbox.path, 'original.bin'))
        ..writeAsBytesSync([51, 52]);
      final store = OwnedTempStore(
        () async => owned,
        legacyClean: probe().isClean,
      );
      final old = await store.create(_scopeA, 'export');
      old.file('old.bin').writeAsBytesSync([61]);
      old.release();
      final current = await store.create(_scopeB, 'picker');
      final currentBytes = current.file('new.bin')..writeAsBytesSync([71]);

      final pending = await store.sweep();
      expect(pending.complete, isFalse);
      expect(pending.unknown, isTrue);
      expect(pending.remaining, 0, reason: 'no fabricated legacy file count');
      expect(old.directory.existsSync(), isFalse);
      expect(currentBytes.readAsBytesSync(), [71]);
      expect(legacy.readAsBytesSync(), [41, 42]);
      expect(external.readAsBytesSync(), [51, 52]);

      // Explicit fixture/operator action, never application cleanup or adoption.
      legacy.parent.deleteSync(recursive: true);
      expect((await store.sweep()).complete, isTrue);
      expect(currentBytes.readAsBytesSync(), [71]);
      expect(external.readAsBytesSync(), [51, 52]);
    },
  );

  test('TMP throwing legacy probe still cleans owned orphan', () async {
    final store = OwnedTempStore(
      () async => owned,
      legacyClean: () async => throw const FileSystemException('synthetic'),
    );
    final task = await store.create(_scopeA, 'export');
    task.file('payload.bin').writeAsBytesSync([81]);
    task.release();
    final result = await store.sweep();
    expect(result.unknown, isTrue);
    expect(result.complete, isFalse);
    expect(task.directory.existsSync(), isFalse);
  });

  test(
    'EXP legacy uncertainty prevents a new OS share and cleans only its task',
    () async {
      final legacy = File(p.join(cache.path, 'soongong-20261013-0915.json'))
        ..writeAsBytesSync([91]);
      final store = OwnedTempStore(
        () async => owned,
        legacyClean: probe().isClean,
      );
      var calls = 0;
      late OwnedTempTask task;
      await expectLater(
        shareExportFile(
          ExportFile(
            name: 'new.json',
            bytes: Uint8List.fromList([92]),
            mimeType: 'application/json',
          ),
          guard: ExportGuard(validate: () async {}, isCurrent: () => true),
          createTask: () async => task = await store.create(_scopeB, 'export'),
          shareFile: (_) async {
            calls++;
          },
        ),
        throwsA(isA<TempStoreUnavailable>()),
      );
      expect(calls, 0);
      expect(task.directory.existsSync(), isFalse);
      expect(legacy.readAsBytesSync(), [91]);
    },
  );
}
