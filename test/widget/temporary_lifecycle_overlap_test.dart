import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soongong/core/lifecycle/foreground_activity_hook.dart';
import 'package:soongong/core/theme/app_theme.dart';
import 'package:soongong/data/auth/auth_mode.dart';
import 'package:soongong/data/startup/startup_tasks.dart';
import 'package:soongong/data/temp/owned_temp_store.dart';
import 'package:soongong/features/privacy/presentation/privacy_screen.dart';

import '../helpers/app_harness.dart';
import '../helpers/bounded_widget_future.dart';
import '../helpers/study_race_harness.dart' show pumpStudy;

// Observe callers without replacing the real filesystem scanner or join logic.
class _ObservedStore extends OwnedTempStore {
  _ObservedStore(
    super.root, {
    super.beforeDelete,
    super.listDirectory,
    super.now,
  });

  final calls = <Future<TempCleanupResult>>[];

  @override
  Future<TempCleanupResult> sweep() {
    final running = super.sweep();
    calls.add(running);
    return running;
  }
}

void main() {
  for (final kind in ['picker', 'export']) {
    testWidgets(
      'DEL-08/EXP-06 startup foreground and privacy join one cleanup and preserve new tasks ($kind)',
      (tester) async {
        // flutter-test runs the production desktop-host startup/foreground branch.
        // beforeDelete models a slow native-quiescence boundary, not an OS picker.
        // Android/iOS recovery and actual process lifecycle remain DEVICE checks.
        final dir = Directory.systemTemp.createTempSync('soongong-overlap-');
        addTearDown(() => dir.deleteSync(recursive: true));
        final root = dir.resolveSymbolicLinksSync();
        const scopeA = '11111111-1111-4111-8111-111111111111';
        const scopeB = '22222222-2222-4222-8222-222222222222';
        final permitDelete = Completer<bool>();
        final deleteEntered = Completer<void>();
        final deletionOwners = <({String scope, String task, bool revoke})>[];
        var scans = 0;
        var deletionCalls = 0;
        var now = DateTime.utc(2026, 10, 13);
        late final String orphanId;
        final store = _ObservedStore(
          () async => dir,
          now: () => now,
          listDirectory: (directory) {
            if (directory.path == root) scans++;
            return directory.listSync(followLinks: false);
          },
          beforeDelete: (scope, task, revoke) {
            // Flutter expect() checks the tester's async guard. This callback
            // runs while pump is outstanding and the store intentionally
            // catches failures: assertions here become unknown cleanup rather
            // than useful test failures. Observe first, assert in the body.
            deletionOwners.add((scope: scope, task: task, revoke: revoke));
            deletionCalls++;
            if (!deleteEntered.isCompleted) deleteEntered.complete();
            return permitDelete.future;
          },
        );
        final h = AppHarness(mode: AuthMode.localOnly, temporaryStore: store);
        addTearDown(h.dispose);
        tester.view.physicalSize = const Size(1000, 1800);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);

        final orphan = await completeWidgetFuture(
          tester,
          store.create(scopeA, kind),
          'create orphan',
        );
        orphanId = orphan.id;
        final oldFile = orphan.file('partial.jpg')..writeAsBytesSync([1, 2]);
        if (kind == 'export') orphan.markShared();
        orphan.release();
        now = now.add(const Duration(hours: 24));
        final active = await completeWidgetFuture(
          tester,
          store.create(scopeB, 'export'),
          'create active export',
        );
        final activeFile = active.file('attachment.json')
          ..writeAsBytesSync([3, 4]);

        // The real bootstrap entry starts deleting a released orphan and waits.
        final startup = runStartupTasks(h.container);
        try {
          for (var i = 0; i < 100 && !deleteEntered.isCompleted; i++) {
            await tester.pump(const Duration(milliseconds: 10));
          }
          expect(deleteEntered.isCompleted, isTrue);
          expect(deletionOwners, [
            (scope: scopeA, task: orphanId, revoke: true),
          ]);
          expect(deletionCalls, 1);
          expect(scans, 1);
          expect(store.calls, hasLength(1));
          expect(oldFile.existsSync(), isTrue);

          final startupCall = store.calls.single;
          await tester.pumpWidget(
            UncontrolledProviderScope(
              container: h.container,
              child: MaterialApp(
                theme: buildAppTheme(Brightness.light),
                home: const ForegroundActivityHook(child: PrivacyScreen()),
              ),
            ),
          );
          await pumpStudy(tester);
          expect(
            store.calls.length,
            greaterThan(1),
            reason: 'privacy entry joins',
          );
          final privacyCallCount = store.calls.length;

          tester.binding.handleAppLifecycleStateChanged(
            AppLifecycleState.paused,
          );
          tester.binding.handleAppLifecycleStateChanged(
            AppLifecycleState.resumed,
          );
          await pumpStudy(tester);
          expect(
            store.calls.length,
            greaterThan(privacyCallCount),
            reason: 'real resumed hook joins the startup and privacy cleanup',
          );
          expect(
            store.calls.every((call) => identical(call, startupCall)),
            isTrue,
          );
          expect(scans, 1);
          expect(deletionCalls, 1);
          expect(activeFile.readAsBytesSync(), [3, 4]);

          // A new task requested during cleanup serializes behind it; it must not
          // get collected by later per-user startup/foreground/privacy sweeps.
          var newTaskFinished = false;
          final newTask = store.create(scopeB, 'picker').then((task) {
            task.file('new.jpg').writeAsBytesSync([5, 6]);
            newTaskFinished = true;
            return task;
          });
          await pumpStudy(tester);
          expect(newTaskFinished, isFalse);
          permitDelete.complete(true);
          await completeWidgetFuture(
            tester,
            startup,
            'startup after cleanup release',
          );
          final created = await completeWidgetFuture(
            tester,
            newTask,
            'new task after sweep',
          );
          await pumpStudy(tester);

          expect(oldFile.existsSync(), isFalse);
          expect(orphan.directory.existsSync(), isFalse);
          expect(deletionCalls, 1);
          expect(activeFile.readAsBytesSync(), [3, 4]);
          expect(created.file('new.jpg').readAsBytesSync(), [5, 6]);
          expect(
            (await completeWidgetFuture(
              tester,
              startupCall,
              'joined cleanup result',
            )).complete,
            isTrue,
          );
          expect(find.byKey(PrivacyKeys.sweepNotice), findsNothing);
          expect(tester.takeException(), isNull);
        } finally {
          // Also release a failed assertion's gate before the test body leaves
          // its fake zone. A teardown-only await cannot drive those timers.
          if (!permitDelete.isCompleted) permitDelete.complete(false);
          await completeWidgetFuture(
            tester,
            startup,
            'startup cleanup after test body',
          );
          await h.unmount(tester);
        }
      },
      timeout: const Timeout(Duration(seconds: 60)),
    );
  }
}
