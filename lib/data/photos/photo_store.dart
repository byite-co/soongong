// PhotoStore (S09 · S09b · S09c): the on-device photo directory
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
// Whatever else S10 keeps under the root (temporary captures) is part of
// the store too: `sweep` removes every file under it ([S09c]) — the full
// wipes (logout · account deletion · 모든 기록 삭제) use it with no age
// condition, the orphan retry keeps the live rows' files.
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

  /// Every file under the store as a relative path (any age).
  Future<List<String>> listAll() async {
    try {
      final dir = await _root();
      if (!dir.existsSync()) return const <String>[];
      final prefix = '${dir.path}/';
      return <String>[
        for (final e in dir.listSync(recursive: true))
          if (e is File && e.path.startsWith(prefix)) e.path.substring(prefix.length).replaceAll('\\', '/'),
      ];
    } on Object catch (e) {
      appLog.w('photo list failed', error: e);
      return const <String>[];
    }
  }

  /// Deletes every file under the store except the files of [keep] (row
  /// paths) and their derived siblings — no age condition. [proceed] is
  /// asked before each file; false stops the sweep (account switch). Returns
  /// the relative paths that are still there afterwards (never logged):
  /// empty = the store holds nothing but [keep].
  Future<List<String>> sweep({Set<String> keep = const <String>{}, bool Function()? proceed}) async {
    final left = <String>[];
    try {
      final dir = await _root();
      if (!dir.existsSync()) return left;
      final files = await listAll();
      final kept = <String>{};
      for (final k in keep) {
        final f = await fileFor(k);
        if (f == null) continue;
        kept.add(k);
        for (final d in _derivedOf(f)) {
          kept.add(d.path.substring(dir.path.length + 1).replaceAll('\\', '/'));
        }
      }
      for (final rel in files) {
        if (kept.contains(rel)) continue;
        if (proceed != null && !proceed()) {
          left.add(rel);
          continue;
        }
        if (!File('${dir.path}/$rel').existsSync()) continue; // went with a sibling
        // Through [delete] (siblings included) so a subclass that scripts
        // failures sees every file the sweep touches.
        if (!await delete(rel)) left.add(rel);
      }
      _removeEmptyDirs(dir, keepRoot: true);
    } on Object catch (e) {
      appLog.w('photo sweep failed', error: e);
    }
    return left;
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

  static void _removeEmptyDirs(Directory dir, {required bool keepRoot}) {
    for (final e in dir.listSync()) {
      if (e is Directory) _removeEmptyDirs(e, keepRoot: false);
    }
    if (!keepRoot && dir.listSync().isEmpty) {
      try {
        dir.deleteSync();
      } on Object {
        // Left in place: an empty directory holds no data.
      }
    }
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
