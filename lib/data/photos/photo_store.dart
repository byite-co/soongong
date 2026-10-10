// PhotoStore (S09): the on-device photo directory (`ApplicationSupport/
// photos/`, data-model.md §2.8 — rows keep a RELATIVE path, never logged).
// S10 writes files here; S09 deletes them (individual · bulk · 30-day
// expiry · logout · account deletion). Tests inject a temp directory.
//
// File operations are the synchronous dart:io calls on purpose: a delete
// of one small file is microseconds, and the widget tests run inside
// flutter_test's fake-async zone where an asynchronous dart:io completion
// never arrives (the app would wait forever). The async signatures stay so
// the root lookup (a platform channel) can be awaited.

import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../core/logging/app_logger.dart';

part 'photo_store.g.dart';

class PhotoStore {
  PhotoStore(this._root);

  final Future<Directory> Function() _root;

  Future<Directory> root() => _root();

  /// Resolves [relativePath] inside the store; null when it would escape it.
  Future<File?> fileFor(String relativePath) async {
    final normalized = relativePath.replaceAll('\\', '/');
    if (normalized.isEmpty || normalized.startsWith('/') || normalized.split('/').contains('..')) {
      return null;
    }
    final dir = await _root();
    return File('${dir.path}/$normalized');
  }

  /// Deletes the file. true when it is gone afterwards (absent counts as
  /// gone); false when the deletion failed — the caller keeps the row and
  /// shows "실패 · 다시 시도".
  Future<bool> delete(String relativePath) async {
    try {
      final file = await fileFor(relativePath);
      if (file == null) return true;
      if (file.existsSync()) file.deleteSync();
      return !file.existsSync();
    } on Object catch (e) {
      appLog.w('photo delete failed', error: e); // path never logged
      return false;
    }
  }

  Future<bool> exists(String relativePath) async {
    final file = await fileFor(relativePath);
    return file != null && file.existsSync();
  }
}

@Riverpod(keepAlive: true)
PhotoStore photoStore(Ref ref) => PhotoStore(() async {
      final base = await getApplicationSupportDirectory();
      final dir = Directory('${base.path}/photos');
      if (!dir.existsSync()) dir.createSync(recursive: true);
      return dir;
    });
