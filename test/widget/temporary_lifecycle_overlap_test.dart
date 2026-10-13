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
import '../helpers/study_race_harness.dart' show completeStudy, pumpStudy;

// Observe callers without replacing the real filesystem scanner or join logic.
class _ObservedStore extends OwnedTempStore {
  _ObservedStore(super.root, {super.beforeDelete, super.listDirectory});

  final calls = <Future<TempCleanupResult>>[];

  @override
  Future<TempCleanupResult> sweep() {
    final running = super.sweep();
    calls.add(running);
    return running;
  }
}

void main() {
  testWidgets(
    'DEL-08 startup foreground and privacy join one cleanup and preserve new tasks',
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
      var scans = 0;
      var deletionCalls = 0;
      late final String orphanId;
      final store = _ObservedStore(
        () async => dir,
        listDirectory: (directory) {
          if (directory.path == root) scans++;
          return directory.listSync(followLinks: false);
        },
        beforeDelete: (scope, task, revoke) {
          expect(scope, scopeA);
          expect(task, orphanId);
          expect(revoke, isTrue);
          deletionCalls++;
          return permitDelete.future;
        },
      );
      final h = AppHarness(mode: AuthMode.localOnly, temporaryStore: store);
      addTearDown(h.dispose);
      tester.view.physicalSize = const Size(1000, 1800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      final orphan = await completeStudy(
        tester,
        store.create(scopeA, 'picker'),
      );
      orphanId = orphan.id;
      final oldFile = orphan.file('partial.jpg')..writeAsBytesSync([1, 2]);
      orphan.release();
      final active = await completeStudy(
        tester,
        store.create(scopeB, 'export'),
      );
      final activeFile = active.file('attachment.json')
        ..writeAsBytesSync([3, 4]);

      // The real bootstrap entry starts deleting a released orphan and waits.
      final startup = runStartupTasks(h.container);
      await pumpStudy(tester);
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
      expect(store.calls.length, greaterThan(1), reason: 'privacy entry joins');
      final privacyCallCount = store.calls.length;

      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await pumpStudy(tester);
      expect(
        store.calls.length,
        greaterThan(privacyCallCount),
        reason: 'real resumed hook joins the startup and privacy cleanup',
      );
      expect(store.calls.every((call) => identical(call, startupCall)), isTrue);
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
      await completeStudy(tester, startup);
      final created = await completeStudy(tester, newTask);
      await pumpStudy(tester);

      expect(oldFile.existsSync(), isFalse);
      expect(orphan.directory.existsSync(), isFalse);
      expect(deletionCalls, 1);
      expect(activeFile.readAsBytesSync(), [3, 4]);
      expect(created.file('new.jpg').readAsBytesSync(), [5, 6]);
      expect((await completeStudy(tester, startupCall)).complete, isTrue);
      expect(find.byKey(PrivacyKeys.sweepNotice), findsNothing);
      expect(tester.takeException(), isNull);
      await h.unmount(tester);
    },
  );
}
