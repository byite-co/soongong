import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soongong/core/strings/study_strings.dart';
import 'package:soongong/core/theme/app_theme.dart';
import 'package:soongong/core/widgets/app_button.dart';
import 'package:soongong/data/auth/auth_mode.dart';
import 'package:soongong/data/photos/study_image_picker.dart';
import 'package:soongong/data/repositories/local_purge.dart';
import 'package:soongong/data/repositories/repository_providers.dart';
import 'package:soongong/data/repositories/sync_writer.dart';
import 'package:soongong/features/reading/presentation/transcription_screen.dart';

import '../helpers/app_harness.dart';

class InitialGenerationWriter extends SyncWriter {
  InitialGenerationWriter(super.db, super.ctx);
  final entered = Completer<void>();
  final resume = Completer<void>();
  @override
  Future<int> refreshPurgeGeneration() async {
    final generation = await super.refreshPurgeGeneration();
    entered.complete();
    await resume.future;
    return generation;
  }
}

Uint8List png() => base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR4nGP4z8DwHwAFAAH/iZk9HQAAAABJRU5ErkJggg==',
);

class ControlledImage implements StudyPickedImage {
  Completer<int>? lengthWait;
  Completer<Uint8List>? readWait;
  Completer<void>? cleanupWait;
  Object? cleanupError;
  final Uint8List bytes = png();
  int size = 64;
  int cleaned = 0;
  @override
  Future<int> length() async =>
      lengthWait == null ? size : await lengthWait!.future;
  @override
  Future<Uint8List> readAsBytes() async =>
      readWait == null ? bytes : await readWait!.future;
  @override
  Future<void> cleanup() async {
    cleaned++;
    await cleanupWait?.future;
    if (cleanupError != null) throw cleanupError!;
  }
}

void main() {
  Future<void> pumpSteps(WidgetTester tester) async {
    for (var i = 0; i < 12; i++) {
      await tester.pump(const Duration(milliseconds: 10));
    }
  }

  testWidgets(
    'PICK-03 purge during initial generation read leaves retry enabled',
    (tester) async {
      late InitialGenerationWriter writer;
      final h = AppHarness(
        mode: AuthMode.localOnly,
        extraOverrides: [syncWriterProvider.overrideWith((ref) => writer)],
      );
      writer = InitialGenerationWriter(
        h.db,
        h.container.read(writeContextProvider),
      );
      addTearDown(h.dispose);
      var picks = 0;
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: h.container,
          child: MaterialApp(
            theme: buildAppTheme(Brightness.light),
            home: TranscriptionScreen(
              pickImage: (_) async {
                picks++;
                return null;
              },
            ),
          ),
        ),
      );
      await pumpSteps(tester);
      await tester.tap(find.text(StudyStrings.select));
      await pumpSteps(tester);
      expect(writer.entered.isCompleted, isTrue);
      final purge = h.container.read(localPurgeProvider);
      final deleting = purge.markPending(1).then((_) => purge.clearPending());
      await pumpSteps(tester);
      await deleting;
      writer.resume.complete();
      await pumpSteps(tester);
      expect(picks, 0);
      final select = tester.widget<AppButton>(
        find.widgetWithText(AppButton, StudyStrings.select),
      );
      expect(select.onPressed, isNotNull);
      expect(tester.takeException(), isNull);
      await h.unmount(tester);
    },
  );

  for (final failure in [
    'oversize',
    'length',
    'read',
    'read success',
    'cleanup',
  ]) {
    testWidgets(
      'PICK-01/02/03 late $failure after purge cannot change new selection',
      (tester) async {
        final h = AppHarness(mode: AuthMode.localOnly);
        addTearDown(h.dispose);
        final old = ControlledImage();
        if (failure == 'read' || failure == 'read success') {
          old.readWait = Completer<Uint8List>();
        } else if (failure == 'cleanup') {
          old.cleanupWait = Completer<void>();
          old.cleanupError = StateError('synthetic cleanup');
        } else {
          old.lengthWait = Completer<int>();
        }
        final fresh = ControlledImage();
        var picks = 0;
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: h.container,
            child: MaterialApp(
              theme: buildAppTheme(Brightness.light),
              home: TranscriptionScreen(
                pickImage: (_) async => picks++ == 0 ? old : fresh,
              ),
            ),
          ),
        );
        await pumpSteps(tester);
        await tester.tap(find.text(StudyStrings.select));
        await pumpSteps(tester);
        expect(picks, 1);
        final purge = h.container.read(localPurgeProvider);
        final deleting = purge.markPending(1).then((_) => purge.clearPending());
        await pumpSteps(tester);
        await deleting;
        await pumpSteps(tester);
        // A's gallery AppButton still joins A; the camera button is a new
        // operation enabled by the generation reset.
        await tester.tap(find.text(StudyStrings.camera));
        await pumpSteps(tester);
        expect(picks, 2);
        expect(find.byType(Image), findsOneWidget);
        await tester.ensureVisible(find.byType(CheckboxListTile));
        await tester.tap(find.byType(CheckboxListTile));
        await tester.pump();
        expect(
          tester.widget<CheckboxListTile>(find.byType(CheckboxListTile)).value,
          isTrue,
        );
        if (failure == 'oversize') {
          old.lengthWait!.complete(4 * 1024 * 1024 + 1);
        }
        if (failure == 'length') {
          old.lengthWait!.completeError(StateError('synthetic length'));
        }
        if (failure == 'read') {
          old.readWait!.completeError(StateError('synthetic read'));
        }
        if (failure == 'read success') old.readWait!.complete(old.bytes);
        if (failure == 'cleanup') old.cleanupWait!.complete();
        await pumpSteps(tester);
        expect(
          (tester.widget<Image>(find.byType(Image)).image as MemoryImage).bytes,
          same(fresh.bytes),
        );
        expect(fresh.bytes, png());
        if (failure == 'read success') {
          expect(old.bytes, everyElement(0));
        }
        expect(
          tester.widget<CheckboxListTile>(find.byType(CheckboxListTile)).value,
          isTrue,
        );
        expect(find.text(StudyStrings.tooLarge), findsNothing);
        expect(find.text(StudyStrings.error), findsNothing);
        expect(find.text(StudyStrings.cacheCleanupFailed), findsNothing);
        expect(
          tester
              .widgetList<AppButton>(find.byType(AppButton))
              .every((b) => !b.busy),
          isTrue,
        );
        expect(old.cleaned, 1);
        expect(tester.takeException(), isNull);
        await h.unmount(tester);
      },
    );
  }

  for (final outcome in ['success', 'oversize', 'cleanup error']) {
    testWidgets('PICK-05 current selection $outcome retains normal behavior', (
      tester,
    ) async {
      final h = AppHarness(mode: AuthMode.localOnly);
      addTearDown(h.dispose);
      final selection = ControlledImage();
      if (outcome == 'oversize') selection.size = 4 * 1024 * 1024 + 1;
      if (outcome == 'cleanup error') {
        selection.cleanupError = StateError('synthetic');
      }
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: h.container,
          child: MaterialApp(
            theme: buildAppTheme(Brightness.light),
            home: TranscriptionScreen(pickImage: (_) async => selection),
          ),
        ),
      );
      await pumpSteps(tester);
      await tester.tap(find.text(StudyStrings.select));
      await pumpSteps(tester);
      expect(selection.cleaned, 1);
      if (outcome == 'success') expect(find.byType(Image), findsOneWidget);
      if (outcome == 'oversize') {
        expect(find.text(StudyStrings.tooLarge), findsOneWidget);
      }
      if (outcome == 'cleanup error') {
        expect(find.text(StudyStrings.cacheCleanupFailed), findsOneWidget);
      }
      expect(tester.takeException(), isNull);
      await h.unmount(tester);
      if (outcome == 'success') {
        expect(selection.bytes, everyElement(0));
        expect(selection.cleaned, 1);
        expect(tester.takeException(), isNull);
      }
    });
  }

  testWidgets('PICK-04 disposed screen ignores late bytes and still cleans', (
    tester,
  ) async {
    final h = AppHarness(mode: AuthMode.localOnly);
    addTearDown(h.dispose);
    final selection = ControlledImage()..readWait = Completer<Uint8List>();
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: h.container,
        child: MaterialApp(
          theme: buildAppTheme(Brightness.light),
          home: TranscriptionScreen(pickImage: (_) async => selection),
        ),
      ),
    );
    await pumpSteps(tester);
    await tester.tap(find.text(StudyStrings.select));
    await pumpSteps(tester);
    await h.unmount(tester);
    final bytes = png();
    selection.readWait!.complete(bytes);
    await pumpSteps(tester);
    expect(selection.cleaned, 1);
    expect(bytes.every((b) => b == 0), isTrue);
    expect(tester.takeException(), isNull);
  });
}
