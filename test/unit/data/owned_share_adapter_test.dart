import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soongong/data/export/export_guard.dart';
import 'package:soongong/data/export/export_service.dart';
import 'package:soongong/data/export/share_export.dart';
import 'package:soongong/data/temp/owned_temp_store.dart';

const _scopeA = '10000000-0000-4000-8000-000000000001';
const _scopeB = '10000000-0000-4000-8000-000000000002';
const _channel = MethodChannel('co.byite.soongong/owned_share');

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory root;
  late OwnedTempStore store;
  late DateTime now;
  late OwnedTempTask task;
  var calls = 0;
  var failDelete = false;
  var current = true;
  ExportGuard guard() =>
      ExportGuard(validate: () async {}, isCurrent: () => current);
  ExportFile file([int value = 42]) => ExportFile(
    name: 'same.json',
    bytes: Uint8List.fromList([value]),
    mimeType: 'application/json',
  );
  Future<OwnedTempTask> create([String scope = _scopeA]) async =>
      task = await store.create(scope, 'export');
  File payload() => File('${task.payloadPath}/attachment.json');
  setUp(() {
    root = Directory.systemTemp.createTempSync('owned-share-');
    now = DateTime.utc(2026, 10, 13);
    calls = 0;
    current = true;
    failDelete = false;
    store = OwnedTempStore(
      () async => root,
      now: () => now,
      removeFile: (f) {
        if (failDelete && f.path.endsWith('attachment.json'))
          throw const FileSystemException('synthetic');
        f.deleteSync();
      },
    );
  });
  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_channel, null);
    root.deleteSync(recursive: true);
  });

  for (final result in ['success', 'dismissed', 'unavailable']) {
    test(
      'EXP-03/05 actual owned-share adapter retains $result for delayed reader',
      () async {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(_channel, (call) async {
              calls++;
              expect(call.method, 'share');
              expect(call.arguments['relativeName'], 'attachment.json');
              expect(call.arguments['scope'], _scopeA);
              expect(
                File('${task.directory.path}/.shared').existsSync(),
                isTrue,
              );
              return result;
            });
        await shareExportFile(file(), guard: guard(), createTask: create);
        now = now.add(const Duration(hours: 23));
        expect((await store.sweep()).complete, isTrue);
        expect(payload().readAsBytesSync(), [42]);
        expect(calls, 1);
        now = now.add(const Duration(hours: 1));
        expect((await store.sweep()).complete, isTrue);
        expect(payload().existsSync(), isFalse);
      },
    );
  }

  for (final timeout in [false, true]) {
    test(
      'EXP-04 attempted share ${timeout ? 'timeout' : 'throw'} retains ambiguity ledger',
      () async {
        final pending = Completer<void>();
        await expectLater(
          shareExportFile(
            file(),
            guard: guard(),
            createTask: create,
            handoffTimeout: const Duration(milliseconds: 5),
            shareFile: (_) {
              calls++;
              if (!timeout) throw StateError('synthetic-share-error');
              return pending.future;
            },
          ),
          throwsA(timeout ? isA<TimeoutException>() : isA<StateError>()),
        );
        expect(payload().readAsBytesSync(), [42]);
        expect(File('${task.directory.path}/.shared').existsSync(), isTrue);
        if (timeout) pending.complete();
        now = now.add(const Duration(hours: 24));
        await store.sweep();
        expect(payload().existsSync(), isFalse);
        expect(calls, 1);
      },
    );
  }

  test(
    'EXP-01/02 account revoked during paused write never reaches OS and late bytes are cleaned',
    () async {
      final started = Completer<void>();
      final resume = Completer<void>();
      final call = shareExportFile(
        file(),
        guard: guard(),
        createTask: create,
        writeFile: (out, bytes) async {
          started.complete();
          await resume.future;
          out.writeAsBytesSync(bytes);
        },
        shareFile: (_) async {
          calls++;
        },
      );
      final rejected = expectLater(call, throwsStateError);
      await started.future;
      current = false;
      // Real async writer can finish before cleanup; guard must stop handoff.
      resume.complete();
      await rejected;
      expect(calls, 0);
      expect(payload().existsSync(), isFalse);
    },
  );

  test(
    'EXP-02/09 failed partial write keeps retry ledger and retry never shares',
    () async {
      failDelete = true;
      await expectLater(
        shareExportFile(
          file(),
          guard: guard(),
          createTask: create,
          writeFile: (out, bytes) async {
            out.writeAsBytesSync(bytes);
            throw StateError('synthetic-write-error');
          },
          shareFile: (_) async {
            calls++;
          },
        ),
        throwsA(isA<TempStoreUnavailable>()),
      );
      expect(payload().existsSync(), isTrue);
      expect(File('${task.directory.path}/.delete').existsSync(), isTrue);
      failDelete = false;
      expect((await store.sweep()).complete, isTrue);
      expect((await store.sweep()).complete, isTrue);
      expect(payload().existsSync(), isFalse);
      expect(calls, 0);
    },
  );

  test(
    'EXP-07/08 handoff kill and concurrent A/B same-name exports recover without cross deletion',
    () async {
      final tasks = <OwnedTempTask>[];
      Future<void> share(String scope, int value) => shareExportFile(
        file(value),
        guard: guard(),
        createTask: () async {
          final t = await store.create(scope, 'export');
          tasks.add(t);
          return t;
        },
        shareFile: (_) async {
          calls++;
        },
      );
      await Future.wait([share(_scopeA, 11), share(_scopeB, 22)]);
      expect(tasks[0].directory.path, isNot(tasks[1].directory.path));
      final restarted = OwnedTempStore(() async => root, now: () => now);
      await restarted.revoke(_scopeA);
      final b = tasks.singleWhere((t) => t.scope == _scopeB);
      expect(File('${b.payloadPath}/attachment.json').readAsBytesSync(), [22]);
      now = now.add(const Duration(hours: 24));
      expect((await restarted.sweep()).complete, isTrue);
      expect(File('${b.payloadPath}/attachment.json').existsSync(), isFalse);
      expect(calls, 2);
    },
  );
}
