import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:soongong/core/contracts/transcription_engine.dart';
import 'package:soongong/core/strings/study_strings.dart';
import 'package:soongong/core/theme/app_theme.dart';
import 'package:soongong/data/auth/auth_gate.dart';
import 'package:soongong/data/auth/auth_models.dart';
import 'package:soongong/data/photos/owned_picker_coordinator.dart';
import 'package:soongong/data/repositories/local_purge.dart';
import 'package:soongong/data/repositories/repository_providers.dart';
import 'package:soongong/data/temp/owned_temp_store.dart';
import 'package:soongong/data/temp/temp_ownership.dart';
import 'package:soongong/data/temp/temp_providers.dart';
import 'package:soongong/features/privacy/application/privacy_providers.dart';
import 'package:soongong/features/reading/application/study_providers.dart';
import 'package:soongong/features/reading/presentation/transcription_screen.dart';

import '../helpers/app_harness.dart';
import '../helpers/bounded_widget_future.dart';
import '../helpers/fake_auth_backend.dart';
import '../helpers/study_race_harness.dart'
    show pressStudy, pumpStudy, raceTranscription;

const _channel = MethodChannel('co.byite.soongong/picker_owner');
const _freshText = 'new generation confirmed text';

// The plugin/OS boundary is scripted. Bytes still come from real fixture files;
// synchronous I/O avoids dart:io futures outside the widget fake clock.
class _ObservedFile extends XFile {
  _ObservedFile(super.path);
  int lengthCalls = 0;
  int reads = 0;
  @override
  Future<int> length() async {
    lengthCalls++;
    return File(path).lengthSync();
  }

  @override
  Future<Uint8List> readAsBytes() async {
    reads++;
    return File(path).readAsBytesSync();
  }
}

class _RecoveringPicker extends ImagePicker {
  late _ObservedFile lost;
  late _ObservedFile fresh;
  late String preparedPayload;
  int recoveries = 0;
  int selections = 0;
  bool? metadataRequested;
  @override
  Future<LostDataResponse> retrieveLostData() async {
    recoveries++;
    return LostDataResponse(files: [lost]);
  }

  @override
  Future<XFile?> pickImage({
    required ImageSource source,
    double? maxWidth,
    double? maxHeight,
    int? imageQuality,
    CameraDevice preferredCameraDevice = CameraDevice.rear,
    bool requestFullMetadata = true,
  }) async {
    selections++;
    metadataRequested = requestFullMetadata;
    final file = File('$preparedPayload/new.png')
      ..writeAsBytesSync(
        base64Decode(
          'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR4nGP4z8DwHwAFAAH/iZk9HQAAAABJRU5ErkJggg==',
        ),
      );
    return fresh = _ObservedFile(file.path);
  }
}

class _CurrentTranscriber implements TranscriptionEngine {
  final inputs = <Uint8List>[];
  final epochs = <int>[];
  @override
  Future<DocumentTranscription> transcribe(
    Uint8List image,
    TranscriptionKind kind, {
    required int epoch,
  }) async {
    inputs.add(Uint8List.fromList(image));
    epochs.add(epoch);
    return const DocumentTranscription(
      kind: TranscriptionKind.text,
      blocks: [
        TranscriptionBlock(text: _freshText, box: [0, 0, 1, 1]),
      ],
      engine: 'fixture',
    );
  }
}

void main() {
  testWidgets(
    'PICK-07 same-account deleteAll discards old-generation lost data and saves only a fresh selection',
    (tester) async {
      final root = Directory.systemTemp.createTempSync('picker-purge-');
      final store = OwnedTempStore(() async => root);
      final picker = _RecoveringPicker();
      final transcriber = _CurrentTranscriber();
      late OwnedPickerCoordinator coordinator;
      final backend = FakeAuthBackend(
        session: const AuthSession(userId: 'u-1', email: null),
        profileRow: {
          ...kProfileRowOnboardingDone,
          'consent_reading_version': ConsentVersions.reading,
          'consent_reading_at': '2026-10-03T01:00:00+00:00',
        },
      );
      backend.responses['purge-all'] = <String, dynamic>{'epoch': 1};
      final h = AppHarness(
        backend: backend,
        temporaryStore: store,
        extraOverrides: [
          ownedPickerCoordinatorProvider.overrideWith((_) => coordinator),
          transcriptionEngineProvider.overrideWithValue(transcriber),
        ],
      );
      addTearDown(() async {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(_channel, null);
        await h.dispose();
        root.deleteSync(recursive: true);
      });
      tester.view.physicalSize = const Size(1000, 1800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      h.container.listen(authGateProvider, (_, _) {});
      await pumpStudy(tester);
      expect(h.container.read(authGateProvider), isA<AuthGateSignedIn>());
      final writer = h.container.read(syncWriterProvider);
      final temporary = h.container.read(tempOwnershipProvider);
      final before = await completeWidgetFuture(
        tester,
        writer.refreshPurgeGeneration(),
        'initial purge generation',
      );
      final old = await completeWidgetFuture(
        tester,
        temporary.create(
          writer,
          'picker',
          generation: before,
          alive: () => true,
        ),
        'old account-owned picker task',
      );
      final oldFile = old.file('old.png')..writeAsBytesSync([91, 92, 93]);
      picker.lost = _ObservedFile(oldFile.path);
      old.release(); // Simulated interrupted picker: only plugin metadata survives.
      await completeWidgetFuture(
        tester,
        h.container
            .read(studyRepositoryProvider)
            .save(
              transcription: raceTranscription,
              text: 'old generation document',
              generation: before,
            ),
        'old document seed',
      );

      final outcome = await completeWidgetFuture(
        tester,
        h.container.read(privacyActionsProvider).deleteAll(),
        'actual same-account deleteAll',
      );
      expect(outcome, isA<DeleteAllDone>());
      expect(backend.currentSession?.userId, 'u-1');
      expect(h.container.read(authGateProvider).userId, 'u-1');
      expect(oldFile.existsSync(), isFalse);
      final after = await completeWidgetFuture(
        tester,
        LocalPurge.readState(h.db),
        'completed purge generation',
      );
      expect(after.generation, greaterThan(before));
      expect(after.inProgress, isFalse);
      final current = await completeWidgetFuture(
        tester,
        temporary.create(
          writer,
          'picker',
          generation: after.generation,
          alive: () => true,
        ),
        'new scope under the same account',
      );
      expect(current.scope, isNot(old.scope));
      final preserved = current.file('current.bin')..writeAsBytesSync([7, 8]);
      final mapping = await completeWidgetFuture(
        tester,
        (h.db.select(
          h.db.syncMeta,
        )..where((row) => row.key.equals(TempOwnership.key))).getSingle(),
        'encrypted mapping row after purge',
      );
      final owner = jsonDecode(mapping.value) as Map<String, dynamic>;
      expect(owner['owner'], 'u-1');
      expect(owner['generation'], after.generation);
      expect(owner['scope'], current.scope);

      String? selectedScope;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(_channel, (call) async {
            if (call.method == 'prepare') {
              final args = Map<String, dynamic>.from(call.arguments as Map);
              selectedScope = args['scope'] as String;
              picker.preparedPayload =
                  '${root.path}/${args['scope']}/${args['task']}/payload';
            }
            return {'active': false, 'unknown': false};
          });
      coordinator = OwnedPickerCoordinator(
        store: store,
        picker: picker,
        android: true,
      );
      expect(
        await completeWidgetFuture(
          tester,
          coordinator.recover(),
          'lost-data recovery',
        ),
        PickerRecoveryState.reselect,
      );
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: h.container,
          child: MaterialApp(
            theme: buildAppTheme(Brightness.light),
            home: const TranscriptionScreen(),
          ),
        ),
      );
      await pumpStudy(tester);
      expect(picker.recoveries, 1);
      expect(picker.selections, 0);
      expect(picker.lost.lengthCalls, 0);
      expect(picker.lost.reads, 0);
      expect(transcriber.inputs, isEmpty);
      expect(find.byType(Image), findsNothing);
      expect(find.text(StudyStrings.confirm), findsNothing);
      expect(
        await completeWidgetFuture(
          tester,
          h.db.customSelect('SELECT id FROM study_documents').get(),
          'no restored old document',
        ),
        isEmpty,
      );
      expect(preserved.readAsBytesSync(), [7, 8]);

      await pressStudy(tester, StudyStrings.select);
      expect(picker.selections, 1);
      expect(selectedScope, current.scope);
      expect(picker.metadataRequested, isFalse);
      expect(picker.fresh.lengthCalls, 1);
      expect(picker.fresh.reads, 1);
      expect(File(picker.fresh.path).existsSync(), isFalse);
      expect(find.byType(Image), findsOneWidget);
      final displayed = Uint8List.fromList(
        (tester.widget<Image>(find.byType(Image)).image as MemoryImage).bytes,
      );
      expect(
        transcriber.inputs,
        isEmpty,
        reason: 'fresh image still requires consent',
      );
      await tester.ensureVisible(find.byType(CheckboxListTile));
      await tester.tap(find.byType(CheckboxListTile));
      await pumpStudy(tester);
      await pressStudy(tester, StudyStrings.recognize);
      expect(transcriber.inputs, hasLength(1));
      expect(transcriber.inputs.single, displayed);
      expect(transcriber.epochs, [after.epoch]);
      expect(find.text(_freshText), findsOneWidget);
      await pressStudy(tester, StudyStrings.confirm);
      expect(find.text(StudyStrings.saved), findsOneWidget);
      final saved = await completeWidgetFuture(
        tester,
        h.db
            .customSelect(
              'SELECT user_id, purge_epoch, text FROM study_documents',
            )
            .get(),
        'fresh UI confirmation saved in the current generation',
      );
      expect(saved, hasLength(1));
      expect(saved.single.read<String>('user_id'), 'u-1');
      expect(saved.single.read<int>('purge_epoch'), after.epoch);
      expect(saved.single.read<String>('text'), _freshText);
      expect(picker.lost.lengthCalls, 0);
      expect(picker.lost.reads, 0);
      expect(preserved.readAsBytesSync(), [7, 8]);
      expect(tester.takeException(), isNull);
      await h.unmount(tester);
    },
    timeout: const Timeout(Duration(seconds: 60)),
  );
}
