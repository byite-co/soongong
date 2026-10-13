import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:soongong/data/auth/auth_mode.dart';
import 'package:soongong/data/auth/auth_models.dart';
import 'package:soongong/data/db/app_database.dart';
import 'package:soongong/data/export/export_guard.dart';
import 'package:soongong/data/export/export_service.dart';
import 'package:soongong/data/export/share_export.dart';
import 'package:soongong/data/repositories/local_purge.dart';
import 'package:soongong/features/privacy/application/privacy_providers.dart';

import '../../helpers/app_harness.dart';

class WaitingExport extends ExportService {
  WaitingExport(AppDatabase db)
    : super(db: db, userId: 'local', encodeInBackground: false);
  final entered = Completer<void>();
  final result = Completer<ExportFile>();
  @override
  Future<ExportFile> build(ExportFormat format) {
    entered.complete();
    return result.future;
  }
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
