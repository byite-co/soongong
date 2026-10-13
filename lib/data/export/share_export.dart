// shareExportFile (S02): writes an [ExportFile] to the temp directory and
// hands it to the system share sheet (share_plus). On failure the caller
// shows a toast whose retry re-runs the SAME format (PRD 4.4).

import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import 'export_guard.dart';
import 'export_service.dart';

Future<void> shareExportFile(
  ExportFile file, {
  required ExportGuard guard,
  Future<Directory> Function()? temporaryDirectory,
  Future<void> Function(File, List<int>)? writeFile,
  Future<void> Function(ShareParams)? shareFile,
}) async {
  Directory? owned;
  var handedOff = false;
  try {
    await guard.check();
    final dir = await (temporaryDirectory ?? getTemporaryDirectory)();
    await guard.check();
    // The directory belongs only to this request, even for identical names.
    owned = await dir.createTemp('soongong-export-');
    await guard.check();
    final out = File('${owned.path}/${file.name}');
    if (writeFile == null) {
      await out.writeAsBytes(file.bytes, flush: true);
    } else {
      await writeFile(out, file.bytes);
    }
    await guard.check();
    final params = ShareParams(
      files: <XFile>[XFile(out.path, mimeType: file.mimeType, name: file.name)],
      subject: file.name,
    );
    guard.checkNow(); // No await between this check and platform invocation.
    handedOff = true;
    await (shareFile == null
        ? SharePlus.instance.share(params)
        : shareFile(params));
  } finally {
    // A platform call may have consumed/retained the file even if it throws.
    // Do not remove an OS-owned attachment based on a share-sheet return.
    // Cancelled preparations, however, are exclusively ours to delete.
    if (!handedOff && owned != null && await owned.exists()) {
      await owned.delete(recursive: true);
    }
  }
}
