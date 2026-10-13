import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soongong/core/contracts/transcription_engine.dart';
import 'package:soongong/core/strings/common_strings.dart';
import 'package:soongong/core/strings/settings_strings.dart';
import 'package:soongong/core/strings/study_strings.dart';
import 'package:soongong/core/theme/app_theme.dart';
import 'package:soongong/core/widgets/app_modal.dart';
import 'package:soongong/data/auth/auth_gate.dart';
import 'package:soongong/data/auth/auth_models.dart';
import 'package:soongong/data/export/export_service.dart';
import 'package:soongong/data/export/share_export.dart';
import 'package:soongong/data/photos/study_image_picker.dart';
import 'package:soongong/data/repositories/repository_providers.dart';
import 'package:soongong/data/temp/owned_temp_store.dart';
import 'package:soongong/data/temp/temp_providers.dart';
import 'package:soongong/features/privacy/application/privacy_providers.dart';
import 'package:soongong/features/reading/application/study_providers.dart';
import 'package:soongong/features/reading/presentation/transcription_screen.dart';
import 'package:soongong/features/settings/presentation/account_screen.dart';

import '../helpers/app_harness.dart';
import '../helpers/fake_auth_backend.dart';
import '../helpers/study_race_harness.dart'
    show completeStudy, pressStudy, pumpStudy, raceTranscription;

class _OwnedImage implements StudyPickedImage {
  _OwnedImage(this.task);
  final OwnedTempTask task;
  late final Uint8List bytes;
  int cleanups = 0;
  File get file => task.file('input.png');
  @override
  Future<int> length() async => file.lengthSync();
  @override
  Future<Uint8List> readAsBytes() async => bytes = file.readAsBytesSync();
  @override
  Future<void> cleanup() async {
    cleanups++;
    if (!(await task.cleanup()).complete) throw const TempStoreUnavailable();
  }
}

class _WaitingTranscriber implements TranscriptionEngine {
  final result = Completer<DocumentTranscription>();
  final inputs = <Uint8List>[];
  @override
  Future<DocumentTranscription> transcribe(
    Uint8List image,
    TranscriptionKind kind, {
    required int epoch,
  }) {
    inputs.add(image);
    return result.future;
  }
}

void main() {
  testWidgets(
    'DEL-01/02 logout retry cancels actual in-flight OCR and export without late display save or share',
    (tester) async {
      final directory = Directory.systemTemp.createTempSync('logout-work-');
      var unavailable = false;
      var fixtureOpen = true;
      final store = OwnedTempStore(() async {
        if (unavailable || !fixtureOpen) throw const TempStoreUnavailable();
        return directory;
      });
      final backend = FakeAuthBackend(
        session: const AuthSession(userId: 'u-1', email: null),
        profileRow: {
          ...kProfileRowOnboardingDone,
          'consent_reading_version': ConsentVersions.reading,
          'consent_reading_at': '2026-10-03T01:00:00+00:00',
        },
      );
      final transcriber = _WaitingTranscriber();
      final writeEntered = Completer<void>();
      final resumeWrite = Completer<void>();
      var shares = 0;
      late OwnedTempTask exportTask;
      late final AppHarness h;
      h = AppHarness(
        backend: backend,
        temporaryStore: store,
        extraOverrides: [
          transcriptionEngineProvider.overrideWithValue(transcriber),
        ],
        shareExportCallback: (file, {required guard}) async {
          final writer = h.container.read(syncWriterProvider);
          final temporary = h.container.read(tempOwnershipProvider);
          await shareExportFile(
            file,
            guard: guard,
            createTask: () async => exportTask = await temporary.create(
              writer,
              'export',
              generation: writer.purgeGeneration!,
              alive: guard.isCurrent,
            ),
            writeFile: (out, bytes) async {
              out.writeAsBytesSync(bytes.take(1).toList(), flush: true);
              writeEntered.complete();
              await resumeWrite.future;
              out.writeAsBytesSync(bytes, flush: true);
            },
            shareFile: (_) async {
              shares++;
            },
          );
        },
      );
      addTearDown(() async {
        fixtureOpen = false;
        await h.dispose();
        directory.deleteSync(recursive: true);
      });
      h.container.listen(authGateProvider, (_, _) {});
      await pumpStudy(tester);
      expect(h.container.read(authGateProvider), isA<AuthGateSignedIn>());
      tester.view.physicalSize = const Size(1000, 1800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final navigator = GlobalKey<NavigatorState>();
      late _OwnedImage image;
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: h.container,
          child: MaterialApp(
            navigatorKey: navigator,
            theme: buildAppTheme(Brightness.light),
            home: TranscriptionScreen(
              pickImage: (_) async {
                final writer = h.container.read(syncWriterProvider);
                final task = await h.container
                    .read(tempOwnershipProvider)
                    .create(
                      writer,
                      'picker',
                      generation: writer.purgeGeneration!,
                      alive: () => backend.currentSession?.userId == 'u-1',
                    );
                image = _OwnedImage(task);
                image.file.writeAsBytesSync(
                  base64Decode(
                    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR4nGP4z8DwHwAFAAH/iZk9HQAAAABJRU5ErkJggg==',
                  ),
                );
                return image;
              },
            ),
          ),
        ),
      );
      await pumpStudy(tester);
      await pressStudy(tester, StudyStrings.select);
      expect(image.cleanups, 1);
      expect(image.task.directory.existsSync(), isFalse);
      await tester.ensureVisible(find.byType(CheckboxListTile));
      await tester.tap(find.byType(CheckboxListTile));
      await pumpStudy(tester);
      await pressStudy(tester, StudyStrings.recognize);
      expect(transcriber.inputs, hasLength(1));
      expect(transcriber.inputs.single, same(image.bytes));

      final exporting = h.container
          .read(privacyActionsProvider)
          .export(ExportFormat.json);
      final rejected = expectLater(
        exporting,
        throwsA(anyOf(isA<StateError>(), isA<FileSystemException>())),
      );
      await pumpStudy(tester);
      expect(writeEntered.isCompleted, isTrue);
      final partial = File('${exportTask.payloadPath}/attachment.json');
      expect(partial.lengthSync(), 1);
      unawaited(
        navigator.currentState!.push<void>(
          MaterialPageRoute(builder: (_) => const AccountScreen()),
        ),
      );
      await tester.pumpAndSettle();
      unavailable = true;
      await tester.ensureVisible(find.byKey(AccountKeys.logout));
      await tester.tap(find.byKey(AccountKeys.logout));
      await pumpStudy(tester);
      await tester.tap(find.text(SettingsStrings.logoutConfirm).last);
      await pumpStudy(tester);
      expect(find.byType(AppModal), findsOneWidget);
      expect(find.text(SettingsStrings.logoutCleanupPending), findsOneWidget);
      expect(find.text(CommonStrings.actionFailedRetry), findsNothing);
      expect(backend.currentSession?.userId, 'u-1');
      expect(backend.callNames, isNot(contains('signOut')));
      expect(partial.existsSync(), isTrue);
      expect(image.bytes, everyElement(0));

      unavailable = false;
      await tester.tap(find.text(SettingsStrings.logoutConfirm).last);
      await tester.pumpAndSettle(
        const Duration(milliseconds: 20),
        EnginePhase.sendSemanticsUpdate,
        const Duration(seconds: 5),
      );
      expect(find.byType(AppModal), findsNothing);
      expect(backend.currentSession, isNull);
      expect(
        backend.callNames.where((call) => call == 'signOut'),
        hasLength(1),
      );
      expect(exportTask.directory.existsSync(), isFalse);

      resumeWrite.complete();
      transcriber.result.complete(raceTranscription);
      await completeStudy(tester, rejected);
      navigator.currentState!.pop();
      await tester.pumpAndSettle();
      expect(find.byType(Image), findsNothing);
      expect(find.text(raceTranscription.text), findsNothing);
      expect(find.text(StudyStrings.confirm), findsNothing);
      expect(find.text(StudyStrings.saved), findsNothing);
      expect(
        await completeStudy(
          tester,
          h.db.customSelect('SELECT id FROM study_documents').get(),
        ),
        isEmpty,
      );
      expect(transcriber.inputs, hasLength(1));
      expect(shares, 0);
      expect(exportTask.directory.existsSync(), isFalse);
      expect(tester.takeException(), isNull);
      await h.unmount(tester);
    },
  );
}
