import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:soongong/data/auth/account_binding.dart';
import 'package:soongong/data/auth/auth_gate.dart';
import 'package:soongong/data/auth/auth_mode.dart';
import 'package:soongong/data/auth/auth_models.dart';
import 'package:soongong/data/db/app_database.dart';
import 'package:soongong/data/export/export_guard.dart';
import 'package:soongong/data/export/export_service.dart';
import 'package:soongong/data/export/share_export.dart';
import 'package:soongong/data/repositories/local_purge.dart';
import 'package:soongong/data/repositories/repository_providers.dart';
import 'package:soongong/features/privacy/application/privacy_providers.dart';

import '../../helpers/app_harness.dart';
import '../../helpers/fake_auth_backend.dart';

class WaitingExport extends ExportService {
  WaitingExport(AppDatabase db, {super.userId = 'local'})
    : super(db: db, encodeInBackground: false);
  final entered = Completer<void>();
  final result = Completer<ExportFile>();
  @override
  Future<ExportFile> build(ExportFormat format) {
    if (entered.isCompleted) return super.build(format);
    entered.complete();
    return result.future;
  }
}

/// Places cancellation in the caller's await gap after the real validation
/// has completed. The adapter must still check synchronously before handoff.
class CancelAfterValidation extends ExportGuard {
  CancelAfterValidation({
    required super.validate,
    required super.isCurrent,
    required this.afterWrite,
    required this.cancel,
  });
  final bool Function() afterWrite;
  final void Function() cancel;

  @override
  Future<void> check() async {
    await super.check();
    if (afterWrite()) scheduleMicrotask(cancel);
  }
}

Future<void> signedInAs(AppHarness h, String userId) async {
  final reached = Completer<void>();
  final subscription = h.container.listen<AuthGateState>(authGateProvider, (
    previous,
    state,
  ) {
    if (state is AuthGateSignedIn &&
        state.userId == userId &&
        !reached.isCompleted) {
      reached.complete();
    }
  }, fireImmediately: true);
  try {
    // An assertion deadline only: event delivery, not elapsed time, advances
    // the test. AccountBinding finishes before AuthGate emits signedIn.
    await reached.future.timeout(const Duration(seconds: 5));
  } finally {
    subscription.close();
  }
  expect(await h.container.read(accountBindingProvider).current(), userId);
}

ExportFile fixture() => ExportFile(
  name: 'same.json',
  bytes: Uint8List.fromList(utf8.encode('{"owner":"local"}')),
  mimeType: 'application/json',
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  for (final format in ExportFormat.values) {
    test('EXP-01 actual PrivacyActions shares $format once', () async {
      final h = AppHarness(mode: AuthMode.localOnly);
      addTearDown(h.dispose);
      await h.container.read(privacyActionsProvider).export(format);
      expect(h.exports, hasLength(1));
      expect(h.exports.single.bytes, isNotEmpty);
    });
  }

  for (final cancel in ['dispose', 'purge started', 'purge completed']) {
    test('EXP-02/04 $cancel while encoding never shares', () async {
      late WaitingExport exporter;
      final h = AppHarness(
        mode: AuthMode.localOnly,
        extraOverrides: [exportServiceProvider.overrideWith((ref) => exporter)],
      );
      exporter = WaitingExport(h.db);
      addTearDown(h.dispose);
      final actions = h.container.read(privacyActionsProvider);
      final pending = actions.export(ExportFormat.json);
      final rejected = expectLater(pending, throwsStateError);
      await exporter.entered.future;
      if (cancel == 'dispose') {
        actions.dispose();
      } else {
        final purge = h.container.read(localPurgeProvider);
        await purge.markPending(1);
        if (cancel == 'purge completed') {
          await purge.run(epoch: 1);
          await purge.clearPending();
        }
      }
      final bytes = fixture();
      exporter.result.complete(bytes);
      await rejected;
      expect(h.exports, isEmpty);
      expect(bytes.bytes.every((byte) => byte == 0), isTrue);
    });
  }

  test('EXP-06 a failed share can retry with freshly encoded bytes', () async {
    final h = AppHarness(mode: AuthMode.localOnly);
    addTearDown(h.dispose);
    final actions = h.container.read(privacyActionsProvider);
    h.shareError = StateError('synthetic share failure');
    await expectLater(actions.export(ExportFormat.json), throwsStateError);
    h.shareError = null;
    await actions.export(ExportFormat.json);
    expect(h.exports, hasLength(1));
    expect(jsonDecode(utf8.decode(h.exports.single.bytes)), isA<Map>());
  });

  test(
    'EXP-06 encoder failure can retry through the same real action',
    () async {
      late WaitingExport exporter;
      final h = AppHarness(
        mode: AuthMode.localOnly,
        extraOverrides: [exportServiceProvider.overrideWith((ref) => exporter)],
      );
      exporter = WaitingExport(h.db);
      addTearDown(h.dispose);
      final actions = h.container.read(privacyActionsProvider);
      final failed = actions.export(ExportFormat.json);
      final rejected = expectLater(failed, throwsStateError);
      await exporter.entered.future;
      exporter.result.completeError(StateError('synthetic encoder failure'));
      await rejected;
      expect(h.exports, isEmpty);
      await actions.export(ExportFormat.json);
      expect(h.exports, hasLength(1));
      expect(
        (jsonDecode(utf8.decode(h.exports.single.bytes)) as Map<String, dynamic>)['user_id'],
        'local',
      );
    },
  );

  test(
    'EXP-03 provider A to B to A revokes old work and binds fresh export',
    () async {
      var waitForEncoding = true;
      final h = AppHarness(
        backend: FakeAuthBackend(
          session: const AuthSession(userId: 'account-a', email: null),
          profileRow: {...kProfileRowOnboardingDone, 'user_id': 'account-a'},
        ),
        extraOverrides: [
          exportServiceProvider.overrideWith((ref) {
            final db = ref.watch(appDatabaseProvider);
            final userId = ref.watch(currentUserIdProvider);
            return waitForEncoding
                ? WaitingExport(db, userId: userId)
                : ExportService(
                    db: db,
                    userId: userId,
                    encodeInBackground: false,
                  );
          }),
        ],
      );
      addTearDown(h.dispose);
      await signedInAs(h, 'account-a');
      final old = h.container.read(privacyActionsProvider);
      final exporter = old.exporter as WaitingExport;
      final pending = old.export(ExportFormat.json);
      final rejected = expectLater(pending, throwsStateError);
      await exporter.entered.future;
      waitForEncoding = false;
      h.backend.profileRow = {
        ...kProfileRowOnboardingDone,
        'user_id': 'account-b',
      };
      h.backend.emitSession(
        const AuthSession(userId: 'account-b', email: null),
      );
      await signedInAs(h, 'account-b');
      await h.container
          .read(subjectRepositoryProvider)
          .create(name: 'belongs-only-to-b', colorIndex: 0);
      h.backend.profileRow = {
        ...kProfileRowOnboardingDone,
        'user_id': 'account-a',
      };
      h.backend.emitSession(
        const AuthSession(userId: 'account-a', email: null),
      );
      await signedInAs(h, 'account-a');
      final oldBytes = fixture();
      exporter.result.complete(oldBytes);
      await rejected;
      expect(h.exports, isEmpty);
      expect(oldBytes.bytes.every((byte) => byte == 0), isTrue);
      final fresh = h.container.read(privacyActionsProvider);
      expect(identical(fresh, old), isFalse);
      await h.container
          .read(subjectRepositoryProvider)
          .create(name: 'new-account-a-request', colorIndex: 1);
      await fresh.export(ExportFormat.json);
      expect(h.exports, hasLength(1));
      final json = utf8.decode(h.exports.single.bytes);
      expect((jsonDecode(json) as Map<String, dynamic>)['user_id'], 'account-a');
      expect(json, contains('new-account-a-request'));
      expect(json, isNot(contains('belongs-only-to-b')));
    },
  );

  for (final cancel in ['dispose', 'purge started', 'purge completed']) {
    test(
      'EXP-05 actual action and adapter cancel $cancel during file write',
      () async {
        final directory = Directory.systemTemp.createTempSync('export-owned-');
        addTearDown(() => directory.deleteSync(recursive: true));
        final entered = Completer<void>();
        final resume = Completer<void>();
        var holdWrite = false;
        final sharedPaths = <String>[];
        final buffers = <Uint8List>[];
        final h = AppHarness(
          mode: AuthMode.localOnly,
          extraOverrides: [
            shareExportProvider.overrideWithValue((
              file, {
              required guard,
            }) async {
              buffers.add(file.bytes);
              await shareExportFile(
                file,
                guard: guard,
                temporaryDirectory: () async => directory,
                writeFile: (out, bytes) async {
                  if (holdWrite) {
                    entered.complete();
                    await resume.future;
                  }
                  await out.writeAsBytes(bytes, flush: true);
                },
                shareFile: (params) async {
                  sharedPaths.add(params.files!.single.path);
                },
              );
            }),
          ],
        );
        addTearDown(h.dispose);
        final actions = h.container.read(privacyActionsProvider);
        await actions.export(ExportFormat.json);
        final originalPath = sharedPaths.single;
        final originalBytes = File(originalPath).readAsBytesSync();
        holdWrite = true;
        final pending = actions.export(ExportFormat.json);
        final rejected = expectLater(pending, throwsStateError);
        await entered.future;
        final purge = h.container.read(localPurgeProvider);
        if (cancel == 'dispose') {
          actions.dispose();
        } else {
          await purge.markPending(1);
          if (cancel == 'purge completed') {
            await purge.run(epoch: 1);
            await purge.clearPending();
          }
        }
        resume.complete();
        await rejected;
        expect(sharedPaths, [originalPath]);
        expect(File(originalPath).readAsBytesSync(), originalBytes);
        expect(directory.listSync(), hasLength(1));
        expect(
          buffers.every((bytes) => bytes.every((byte) => byte == 0)),
          isTrue,
        );

        // The cancelled operation must not poison a later current request.
        holdWrite = false;
        if (cancel == 'purge started') {
          await purge.run(epoch: 1);
          await purge.clearPending();
        }
        if (cancel == 'dispose') h.container.invalidate(privacyActionsProvider);
        await h.container
            .read(privacyActionsProvider)
            .export(ExportFormat.json);
        expect(sharedPaths, hasLength(2));
        expect(sharedPaths[1], isNot(originalPath));
        expect(File(originalPath).readAsBytesSync(), originalBytes);
        expect(
          (jsonDecode(File(sharedPaths[1]).readAsStringSync()) as Map<String, dynamic>)['user_id'],
          'local',
        );
        expect(directory.listSync(), hasLength(2));
      },
    );
  }

  test(
    'EXP-05 cancellation in the final await gap prevents OS invocation',
    () async {
      final directory = Directory.systemTemp.createTempSync(
        'export-await-gap-',
      );
      addTearDown(() => directory.deleteSync(recursive: true));
      var current = true;
      var wrote = false;
      var calls = 0;
      await expectLater(
        shareExportFile(
          fixture(),
          guard: CancelAfterValidation(
            validate: () async {},
            isCurrent: () => current,
            afterWrite: () => wrote,
            cancel: () => current = false,
          ),
          temporaryDirectory: () async => directory,
          writeFile: (out, bytes) async {
            await out.writeAsBytes(bytes);
            wrote = true;
          },
          shareFile: (_) async {
            calls++;
          },
        ),
        throwsStateError,
      );
      expect(calls, 0);
      expect(directory.listSync(), isEmpty);
    },
  );

  test(
    'EXP-03 A to B to A never revives the old action; new A can share',
    () async {
      late WaitingExport exporter;
      final h = AppHarness(mode: AuthMode.localOnly);
      addTearDown(h.dispose);
      final base = h.container.read(privacyActionsProvider);
      exporter = WaitingExport(h.db);
      h.backend.session = const AuthSession(userId: 'local', email: null);
      PrivacyActions make(ExportService service) => PrivacyActions(
        writer: base.writer,
        sessions: base.sessions,
        subjects: base.subjects,
        photos: base.photos,
        purge: base.purge,
        exporter: service,
        share: base.share,
        backend: h.backend,
        serverPurge: true,
      );
      final old = make(exporter);
      addTearDown(old.dispose);
      final pending = old.export(ExportFormat.json);
      final rejected = expectLater(pending, throwsStateError);
      await exporter.entered.future;
      h.backend.emitSession(const AuthSession(userId: 'other', email: null));
      h.backend.emitSession(const AuthSession(userId: 'local', email: null));
      exporter.result.complete(fixture());
      await rejected;
      expect(h.exports, isEmpty);
      final fresh = make(base.exporter);
      addTearDown(fresh.dispose);
      await fresh.export(ExportFormat.json);
      expect(h.exports, hasLength(1));
    },
  );

  test(
    'EXP-04 an uninitialized gate reads and refuses a pending purge',
    () async {
      final h = AppHarness(mode: AuthMode.localOnly);
      addTearDown(h.dispose);
      await h.db.customStatement(
        "INSERT INTO sync_meta(key,value) VALUES ('purge_pending_epoch','1')",
      );
      await expectLater(
        h.container.read(privacyActionsProvider).export(ExportFormat.json),
        throwsStateError,
      );
      expect(h.exports, isEmpty);
    },
  );

  test(
    'EXP-05 cancelled file write cleans only its request; normal file survives',
    () async {
      final directory = Directory.systemTemp.createTempSync('export-race-');
      addTearDown(() => directory.deleteSync(recursive: true));
      var current = true;
      var calls = 0;
      String? normalPath;
      final entered = Completer<void>();
      final resume = Completer<void>();
      final normalGuard = ExportGuard(
        validate: () async {},
        isCurrent: () => true,
      );
      await shareExportFile(
        fixture(),
        guard: normalGuard,
        temporaryDirectory: () async => directory,
        shareFile: (params) async {
          calls++;
          normalPath = params.files!.single.path;
        },
      );
      final pending = shareExportFile(
        fixture(),
        guard: ExportGuard(validate: () async {}, isCurrent: () => current),
        temporaryDirectory: () async => directory,
        writeFile: (file, bytes) async {
          entered.complete();
          await resume.future;
          await file.writeAsBytes(bytes, flush: true);
        },
        shareFile: (_) async {
          calls++;
        },
      );
      final rejected = expectLater(pending, throwsStateError);
      await entered.future;
      current = false;
      resume.complete();
      await rejected;
      expect(calls, 1);
      expect(File(normalPath!).existsSync(), isTrue);
      expect(directory.listSync(), hasLength(1));
    },
  );

  test(
    'EXP-05 synchronous invalidation after final validation blocks handoff',
    () async {
      final directory = Directory.systemTemp.createTempSync('export-guard-');
      addTearDown(() => directory.deleteSync(recursive: true));
      var current = true;
      var wrote = false;
      var calls = 0;
      await expectLater(
        shareExportFile(
          fixture(),
          guard: ExportGuard(
            isCurrent: () => current,
            validate: () async {
              if (wrote) current = false;
            },
          ),
          temporaryDirectory: () async => directory,
          writeFile: (file, bytes) async {
            await file.writeAsBytes(bytes);
            wrote = true;
          },
          shareFile: (_) async {
            calls++;
          },
        ),
        throwsStateError,
      );
      expect(calls, 0);
      expect(directory.listSync(), isEmpty);
    },
  );
}
