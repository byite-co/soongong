import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:share_plus/share_plus.dart';

import '../../core/domain/ids.dart';
import '../temp/owned_temp_store.dart';
import 'export_guard.dart';
import 'export_service.dart';

Future<void> shareExportFile(
  ExportFile file, {
  required ExportGuard guard,
  Future<OwnedTempTask> Function()? createTask,
  // Adapter test seams; production always supplies createTask.
  Future<Directory> Function()? temporaryDirectory,
  Future<void> Function(File, List<int>)? writeFile,
  Future<void> Function(ShareParams)? shareFile,
  Duration handoffTimeout = const Duration(seconds: 30),
  MethodChannel channel = const MethodChannel('co.byite.soongong/owned_share'),
}) async {
  OwnedTempTask? task;
  var attempted = false;
  try {
    await guard.check();
    if (createTask != null) {
      task = await createTask();
    } else if (temporaryDirectory != null && shareFile != null) {
      final dir = await temporaryDirectory();
      final store = OwnedTempStore(
        () async => Directory(p.join(dir.path, 'soongong-owned-v1')),
      );
      task = await store.create(newUuid(), 'export');
    } else {
      throw StateError('owned export scope required');
    }
    // Every export is another expiry/retry opportunity; active task is leased.
    final cleanup = await task.store.sweep();
    if (cleanup.unknown) throw const TempStoreUnavailable();
    await guard.check();
    task.check();
    final extension = switch (file.mimeType) {
      'application/json' => '.json',
      'text/csv' => '.csv',
      'application/zip' => '.zip',
      _ => '.txt',
    };
    final relativeName = 'attachment$extension';
    final out = task.file(relativeName);
    if (writeFile == null) {
      // Registered first; no event-loop ownership change during this write.
      out.writeAsBytesSync(file.bytes, flush: true);
    } else {
      await writeFile(out, file.bytes);
    }
    await guard.check();
    task.check();
    final params = ShareParams(
      files: [
        XFile(out.path, mimeType: file.mimeType, name: p.basename(file.name)),
      ],
      subject: p.basename(file.name),
    );
    // Every OS result, including throw/timeout, has the same bounded grace.
    task.markShared();
    guard.checkNow(); // No await between final guard and platform invocation.
    attempted = true;
    final call = shareFile != null
        ? shareFile(params)
        : channel.invokeMethod<void>('share', {
            ...task.nativeArguments,
            'relativeName': relativeName,
            'name': p.basename(file.name),
            'mimeType': file.mimeType,
          });
    await call.timeout(handoffTimeout);
  } finally {
    if (task != null) {
      task.release();
      if (!attempted && !(await task.cleanup()).complete) {
        throw const TempStoreUnavailable();
      }
    }
  }
}
