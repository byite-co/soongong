// PhotoStore (S09 · S09b · S09c · S09d): the on-device photo directory
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
// Paths ([S09d]): relative paths are stored and compared with '/' on every
// platform; a file's relative path is derived with `package:path`
// (`isWithin` · `relative`), never by string prefix, so a Windows
// backslash path is listed like any other. A store that cannot be opened
// or listed is NOT an empty store: `listAll` and `sweep` throw
// [PhotoStoreUnavailable] / report `complete == false`, so a wipe never
// reports success for files it could not see.
//
// File operations are the synchronous dart:io calls on purpose: a delete
// of one small file is microseconds, and the widget tests run inside
// flutter_test's fake-async zone where an asynchronous dart:io completion
// never arrives (the app would wait forever). The async signatures stay so
// the root lookup (a platform channel) can be awaited.
//
// Logging: only the failure kind (exception type) — never the exception
// itself (a `FileSystemException` carries the path), never a path.

import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../core/logging/app_logger.dart';

part 'photo_store.g.dart';

/// The store could not be opened or listed (root lookup · directory
/// enumeration). Carries the failure kind only — no path.
class PhotoStoreUnavailable implements Exception {
  const PhotoStoreUnavailable(this.kind);

  /// The exception type that caused it (`FileSystemException`, …).
  final String kind;

  @override
  String toString() => 'PhotoStoreUnavailable($kind)';
}

/// Outcome of [PhotoStore.sweep].
class SweepResult {
  const SweepResult({required this.left, required this.complete});

  /// Relative paths that are still there (could not be deleted, or were not
  /// reached because [complete] is false). Never logged.
  final List<String> left;

  /// true when every file under the store was seen; false when the store
  /// could not be opened or listed, or the sweep was stopped (`proceed`).
  final bool complete;

  /// Nothing but the kept files remains, and that is known for sure.
  bool get clean => complete && left.isEmpty;
}

class PhotoStore {
  PhotoStore(this._root);

  final Future<Directory> Function() _root;

  /// Camera / picker scratch files (not rows).
  static const String cacheDir = 'cache';

  Future<Directory> root() => _root();

  /// The store-relative path ('/'-separated) of [fullPath] under
  /// [rootPath], or null when it is not inside the root. [context] is the
  /// platform's path style (tests pass `p.windows` / `p.posix`).
  static String? relativeOf(String rootPath, String fullPath, {p.Context? context}) {
    final c = context ?? p.context;
    final root = c.normalize(c.absolute(rootPath));
    final full = c.normalize(c.absolute(fullPath));
    if (!c.isWithin(root, full)) return null;
    return c.split(c.relative(full, from: root)).join('/');
  }

  /// Resolves [relativePath] inside the store; null when it would escape it.
  Future<File?> fileFor(String relativePath) async {
    final normalized = relativePath.replaceAll('\\', '/');
    if (normalized.isEmpty || normalized.startsWith('/') || normalized.split('/').contains('..')) {
      return null;
    }
    final dir = await _root();
    final file = File(p.join(dir.path, p.joinAll(normalized.split('/'))));
    if (relativeOf(dir.path, file.path) == null) return null;
    return file;
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
      appLog.w('photo delete failed (${e.runtimeType})');
      return false;
    }
  }

  Future<bool> exists(String relativePath) async {
    final file = await fileFor(relativePath);
    return file != null && file.existsSync();
  }

  /// Every file under the store as a relative path (any age). Throws
  /// [PhotoStoreUnavailable] when the store cannot be opened or listed — an
  /// unknown number of files is never reported as none.
  Future<List<String>> listAll() async {
    final Directory dir;
    try {
      dir = await _root();
      if (!dir.existsSync()) return const <String>[];
    } on Object catch (e) {
      appLog.w('photo store unavailable (${e.runtimeType})');
      throw PhotoStoreUnavailable('${e.runtimeType}');
    }
    try {
      final out = <String>[];
      for (final e in dir.listSync(recursive: true)) {
        if (e is! File) continue;
        final rel = relativeOf(dir.path, e.path);
        if (rel != null) out.add(rel);
      }
      return out;
    } on Object catch (e) {
      appLog.w('photo store listing failed (${e.runtimeType})');
      throw PhotoStoreUnavailable('${e.runtimeType}');
    }
  }

  /// Deletes every file under the store except the files of [keep] (row
  /// paths) and their derived siblings — no age condition. [proceed] is
  /// asked before each file; false stops the sweep (account switch). The
  /// result says what is still there and whether the whole store was seen;
  /// a store that cannot be opened or listed gives `complete == false`
  /// (nothing deleted, nothing assumed).
  Future<SweepResult> sweep({Set<String> keep = const <String>{}, bool Function()? proceed}) async {
    final List<String> files;
    final Directory dir;
    try {
      dir = await _root();
      if (!dir.existsSync()) return const SweepResult(left: <String>[], complete: true);
      files = await listAll();
    } on PhotoStoreUnavailable {
      return const SweepResult(left: <String>[], complete: false);
    } on Object catch (e) {
      appLog.w('photo store unavailable (${e.runtimeType})');
      return const SweepResult(left: <String>[], complete: false);
    }
    final kept = <String>{};
    for (final k in keep) {
      final f = await fileFor(k);
      if (f == null) continue;
      kept.add(k);
      for (final d in _derivedOf(f)) {
        final rel = relativeOf(dir.path, d.path);
        if (rel != null) kept.add(rel);
      }
    }
    final left = <String>[];
    var complete = true;
    for (final rel in files) {
      if (kept.contains(rel)) continue;
      if (proceed != null && !proceed()) {
        left.add(rel);
        complete = false;
        continue;
      }
      final f = await fileFor(rel);
      if (f == null || !f.existsSync()) continue; // went with a sibling
      // Through [delete] (siblings included) so a subclass that scripts
      // failures sees every file the sweep touches.
      if (!await delete(rel)) left.add(rel);
    }
    _removeEmptyDirs(dir, keepRoot: true);
    return SweepResult(left: left, complete: complete);
  }

  /// Removes cache files older than [olderThan] relative to [now].
  Future<int> clearCache({required DateTime now, Duration olderThan = const Duration(hours: 24)}) async {
    var n = 0;
    try {
      final dir = Directory(p.join((await _root()).path, cacheDir));
      if (!dir.existsSync()) return 0;
      for (final e in dir.listSync(recursive: true)) {
        if (e is! File) continue;
        if (now.difference(e.statSync().modified) >= olderThan && _deleteFile(e)) n++;
      }
    } on Object catch (e) {
      appLog.w('photo cache clear failed (${e.runtimeType})');
    }
    return n;
  }

  static bool _deleteFile(File f) {
    if (f.existsSync()) f.deleteSync();
    return !f.existsSync();
  }

  static void _removeEmptyDirs(Directory dir, {required bool keepRoot}) {
    try {
      for (final e in dir.listSync()) {
        if (e is Directory) _removeEmptyDirs(e, keepRoot: false);
      }
      if (!keepRoot && dir.listSync().isEmpty) dir.deleteSync();
    } on Object {
      // Left in place: an empty directory holds no data.
    }
  }

  /// `<stem>.<anything>` siblings of `<stem>.<ext>` in the same directory.
  static List<File> _derivedOf(File original) {
    final dir = original.parent;
    if (!dir.existsSync()) return const <File>[];
    final name = p.basename(original.path);
    final dot = name.lastIndexOf('.');
    final stem = dot <= 0 ? name : name.substring(0, dot);
    return <File>[
      for (final e in dir.listSync())
        if (e is File && e.path != original.path && p.basename(e.path).startsWith('$stem.')) e,
    ];
  }
}

@Riverpod(keepAlive: true)
PhotoStore photoStore(Ref ref) => PhotoStore(() async {
      final base = await getApplicationSupportDirectory();
      final dir = Directory(p.join(base.path, 'photos'));
      if (!dir.existsSync()) dir.createSync(recursive: true);
      return dir;
    });
