import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:soongong/data/auth/auth_gate.dart';
import 'package:soongong/data/auth/auth_mode.dart';
import 'package:soongong/data/auth/auth_models.dart';
import 'package:soongong/data/db/app_database.dart';
import 'package:soongong/data/export/export_service.dart';
import 'package:soongong/data/repositories/local_purge.dart';
import 'package:soongong/data/repositories/repository_providers.dart';
import 'package:soongong/data/temp/owned_temp_store.dart';
import 'package:soongong/data/temp/temp_ownership.dart';
import 'package:soongong/data/temp/temp_providers.dart';
import 'package:soongong/features/privacy/application/photo_retention.dart';
import 'package:soongong/features/privacy/application/privacy_providers.dart';
import '../../helpers/app_harness.dart';
import '../../helpers/fake_auth_backend.dart';

class _WaitingExport extends ExportService {
  _WaitingExport(AppDatabase db)
    : super(db: db, userId: 'local', encodeInBackground: false);
  final entered = Completer<void>();
  final result = Completer<ExportFile>();
  @override
  Future<ExportFile> build(ExportFormat format) {
    entered.complete();
    return result.future;
  }
}

Future<OwnedTempTask> _task(AppHarness h, String kind) async {
  final writer = h.container.read(syncWriterProvider);
  final generation = await writer.refreshPurgeGeneration();
  return h.container
      .read(tempOwnershipProvider)
      .create(writer, kind, generation: generation, alive: () => true);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'DEL-06 unreadable root with no account mapping is unknown, never all done',
    () async {
      final h = AppHarness(
        mode: AuthMode.localOnly,
        temporaryStore: OwnedTempStore(() async {
          throw const TempStoreUnavailable();
        }),
      );
      addTearDown(h.dispose);
      final result = await h.container.read(photoRetentionProvider).wipeAll();
      expect(result.allDone, isFalse);
      expect(result.storeUnavailable, isTrue);
      expect(result.failedCount, 0, reason: 'unknown, not a known empty root');
    },
  );

  test(
    'DEL-05 purge revokes picker/export before await and preserves unrelated scope',
    () async {
      late _WaitingExport exporter;
      final h = AppHarness(
        mode: AuthMode.localOnly,
        exportFactory: (_, _) => exporter,
      );
      exporter = _WaitingExport(h.db);
      addTearDown(h.dispose);
      final picker = await _task(h, 'picker');
      final export = await _task(h, 'export');
      final photo = picker.file('image.jpg')..writeAsBytesSync([1, 2, 3]);
      final shared = export.file('record.json')..writeAsBytesSync([4, 5, 6]);
      export.markShared();
      export.release();
      final store = h.container.read(ownedTempStoreProvider);
      final other = await store.create(
        '11111111-1111-4111-8111-111111111111',
        'picker',
      );
      final otherFile = other.file('keep.jpg')..writeAsBytesSync([7, 8, 9]);
      final actions = h.container.read(privacyActionsProvider);
      final exporting = expectLater(
        actions.export(ExportFormat.json),
        throwsStateError,
      );
      await exporter.entered.future;
      final temporary = h.container.read(tempOwnershipProvider);
      final before = temporary.epoch('local');
      final deleting = actions.deleteAll();
      expect(
        temporary.epoch('local'),
        greaterThan(before),
        reason: 'synchronous barrier',
      );
      expect(await deleting, isA<DeleteAllDone>());
      final file = ExportFile(
        name: 'old.json',
        bytes: Uint8List.fromList([10, 11]),
        mimeType: 'application/json',
      );
      exporter.result.complete(file);
      await exporting;
      expect(h.exports, isEmpty);
      expect(file.bytes, everyElement(0));
      expect(photo.existsSync(), isFalse);
      expect(shared.existsSync(), isFalse);
      expect(otherFile.readAsBytesSync(), [7, 8, 9]);
    },
  );

  test(
    'DEL-05 temp epoch alone cancels encoding without purge generation change',
    () async {
      late _WaitingExport exporter;
      final h = AppHarness(
        mode: AuthMode.localOnly,
        exportFactory: (_, _) => exporter,
      );
      exporter = _WaitingExport(h.db);
      addTearDown(h.dispose);
      final actions = h.container.read(privacyActionsProvider);
      final rejected = expectLater(
        actions.export(ExportFormat.json),
        throwsStateError,
      );
      await exporter.entered.future;
      final writer = h.container.read(syncWriterProvider);
      final generation = writer.purgeGeneration;
      h.container.read(tempOwnershipProvider).invalidate('local');
      expect(writer.purgeGeneration, generation);
      exporter.result.complete(
        ExportFile(
          name: 'old.json',
          bytes: Uint8List.fromList([1]),
          mimeType: 'application/json',
        ),
      );
      await rejected;
      expect(h.exports, isEmpty);
    },
  );

  test(
    'DEL-07 served purge and failed durable cleanup resume locally without another server delete',
    () async {
      final dir = Directory.systemTemp.createTempSync('soongong-del-local-');
      addTearDown(() => dir.deleteSync(recursive: true));
      var unavailable = false;
      final store = OwnedTempStore(() async {
        if (unavailable) throw const TempStoreUnavailable();
        return dir;
      });
      final backend = FakeAuthBackend(
        session: const AuthSession(userId: 'u-1', email: null),
        profileRow: kProfileRowOnboardingDone,
      );
      backend.responses['purge-all'] = {'epoch': 1};
      final h = AppHarness(backend: backend, temporaryStore: store);
      addTearDown(h.dispose);
      h.container.read(authGateProvider);
      await h.settle(60);
      final task = await _task(h, 'export');
      final file = task.file('private.json')..writeAsBytesSync([1, 2]);
      final subject = await h.container
          .read(subjectRepositoryProvider)
          .create(name: 'keep until local cleanup', colorIndex: 0);
      unavailable = true;
      final actions = h.container.read(privacyActionsProvider);
      final outcome = await actions.deleteAll();
      expect(
        outcome,
        isA<DeleteAllLocalPending>().having(
          (o) => o.serverConfirmed,
          'server confirmed',
          isTrue,
        ),
      );
      expect(
        (await h.container.read(localPurgeProvider).state()).stage,
        PurgeStage.pending,
      );
      expect(
        (await h.container.read(subjectRepositoryProvider).getAll()).map(
          (s) => s.id,
        ),
        contains(subject.id),
      );
      expect(
        (await h.db.select(h.db.syncMeta).get()).map((row) => row.key),
        contains(TempOwnership.key),
      );
      expect(file.existsSync(), isTrue);
      expect(backend.callNames.where((n) => n == 'purge-all'), hasLength(1));
      unavailable = false;
      expect(await actions.resume(), isA<DeleteAllDone>());
      expect(file.existsSync(), isFalse);
      expect(backend.callNames.where((n) => n == 'purge-all'), hasLength(1));
      expect(
        (await h.container.read(localPurgeProvider).state()).stage,
        PurgeStage.none,
      );
    },
  );

  test(
    'DEL-06/08 failed payload deletion retains retry evidence; duplicate retry is harmless',
    () async {
      final dir = Directory.systemTemp.createTempSync('soongong-del-retry-');
      addTearDown(() => dir.deleteSync(recursive: true));
      var fail = true;
      final store = OwnedTempStore(
        () async => dir,
        removeFile: (file) {
          if (fail && file.path.endsWith('private.jpg')) {
            throw const FileSystemException('injected');
          }
          file.deleteSync();
        },
      );
      final h = AppHarness(mode: AuthMode.localOnly, temporaryStore: store);
      addTearDown(h.dispose);
      final task = await _task(h, 'picker');
      final file = task.file('private.jpg')..writeAsBytesSync([1, 2, 3]);
      final outcome = await h.container
          .read(privacyActionsProvider)
          .deleteAll();
      expect(
        outcome,
        isA<DeleteAllPartial>().having(
          (o) => o.storeUnavailable,
          'unknown remainder',
          isTrue,
        ),
      );
      expect(file.existsSync(), isTrue);
      expect(File('${task.directory.path}/.delete').existsSync(), isTrue);
      expect(
        File('${task.directory.parent.path}/.revoked').existsSync(),
        isTrue,
      );
      final retention = h.container.read(photoRetentionProvider);
      expect(await retention.pendingSweepCount(), isNull);
      fail = false;
      expect(await retention.retryPendingSweep(), 0);
      expect(await retention.retryPendingSweep(), 0);
      expect(file.existsSync(), isFalse);
    },
  );
}
