// PhotoStore (S09 · S09b): the on-device photo directory
// (`ApplicationSupport/photos/`, data-model.md §2.8 — rows keep a RELATIVE
// path, never logged). S10 writes files here; S09 deletes them (individual
// · bulk · 30-day expiry · logout · account deletion). Tests inject a temp
// directory.
//
// Layout contract for S10 ([S09b]): a photo's row path names its original
// (`<request>/<id>.jpg`); derived images (압축본·크롭) sit next to it with the
// same stem and an extra suffix (`<id>.compressed.jpg`, `<id>.crop.jpg`) so
// `delete` removes the original and every derived file in one call; the
// camera cache lives under `cache/` and is cleared by `clearCache`.
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

  /// Camera / picker scratch files (not rows).
  static const String cacheDir = 'cache';

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

  /// Deletes the file and its derived siblings (same stem, extra suffix).
  /// true when they are gone afterwards (absent counts as gone); false when
  /// a deletion failed — the caller keeps the row and shows "실패 · 다시 시도".
  Future<bool> delete(String relativePath) async {
    try {
      final file = await fileFor(relativePath);
      if (file == null) return true;
      var ok = _deleteFile(file);
      for (final d in _derivedOf(file)) {
        ok = _deleteFile(d) && ok;
      }
      return ok;
    } on Object catch (e) {
      appLog.w('photo delete failed', error: e); // path never logged
      return false;
    }
  }

  Future<bool> exists(String relativePath) async {
    final file = await fileFor(relativePath);
    return file != null && file.existsSync();
  }

  /// Removes cache files older than [olderThan] relative to [now].
  Future<int> clearCache({required DateTime now, Duration olderThan = const Duration(hours: 24)}) async {
    var n = 0;
    try {
      final dir = Directory('${(await _root()).path}/$cacheDir');
      if (!dir.existsSync()) return 0;
      for (final e in dir.listSync(recursive: true)) {
        if (e is! File) continue;
        if (now.difference(e.statSync().modified) >= olderThan && _deleteFile(e)) n++;
      }
    } on Object catch (e) {
      appLog.w('photo cache clear failed', error: e);
    }
    return n;
  }

  static bool _deleteFile(File f) {
    if (f.existsSync()) f.deleteSync();
    return !f.existsSync();
  }

  /// `<stem>.<anything>` siblings of `<stem>.<ext>` in the same directory.
  static List<File> _derivedOf(File original) {
    final dir = original.parent;
    if (!dir.existsSync()) return const <File>[];
    final name = original.uri.pathSegments.last;
    final dot = name.lastIndexOf('.');
    final stem = dot <= 0 ? name : name.substring(0, dot);
    return <File>[
      for (final e in dir.listSync())
        if (e is File && e.path != original.path && e.uri.pathSegments.last.startsWith('$stem.')) e,
    ];
  }
}

@Riverpod(keepAlive: true)
PhotoStore photoStore(Ref ref) => PhotoStore(() async {
      final base = await getApplicationSupportDirectory();
      final dir = Directory('${base.path}/photos');
      if (!dir.existsSync()) dir.createSync(recursive: true);
      return dir;
    });
