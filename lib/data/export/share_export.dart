// shareExportFile (S02): writes an [ExportFile] to the temp directory and
// hands it to the system share sheet (share_plus). On failure the caller
// shows a toast whose retry re-runs the SAME format (PRD 4.4).

import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import 'export_service.dart';

Future<void> shareExportFile(ExportFile file) async {
  final dir = await getTemporaryDirectory();
  final out = File('${dir.path}/${file.name}');
  await out.writeAsBytes(file.bytes, flush: true);
  await SharePlus.instance.share(
    ShareParams(
      files: <XFile>[XFile(out.path, mimeType: file.mimeType, name: file.name)],
      subject: file.name,
    ),
  );
}
