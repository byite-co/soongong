import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

import '../../core/domain/ids.dart';

/// Product policy, not a guarantee about when another app reads a shared URL.
class TempRetentionPolicy {
  const TempRetentionPolicy({
    this.shareGrace = const Duration(hours: 24),
    this.activeLease = const Duration(minutes: 10),
  });
  final Duration shareGrace;
  final Duration activeLease;
}

class TempCleanupResult {
  const TempCleanupResult({this.remaining = 0, this.unknown = false});
  final int remaining;
  final bool unknown;
  bool get complete => remaining == 0 && !unknown;
  TempCleanupResult plus(TempCleanupResult other) => TempCleanupResult(
    remaining: remaining + other.remaining,
    unknown: unknown || other.unknown,
  );
}

class TempStoreUnavailable implements Exception {
  const TempStoreUnavailable();
  @override
  String toString() => 'TempStoreUnavailable';
}

/// No account identifiers, user filenames, absolute paths or content are stored
/// in this ledger. The encrypted database alone maps an account to a scope.
/// Valid UUID directories under this reserved root establish ownership even
/// after a crash before marker creation. Tombstones survive database wipe.
class OwnedTempStore {
  OwnedTempStore(
    this.root, {
    DateTime Function()? now,
    this.policy = const TempRetentionPolicy(),
    this.beforeDelete,
    this.removeFile,
    this.listDirectory,
    this.legacyClean,
  }) : now = now ?? DateTime.now;

  final Future<Directory> Function() root;
  final DateTime Function() now;
  final TempRetentionPolicy policy;

  /// Native producers must report quiescence before their task is removed.
  Future<bool> Function(String scope, String task, bool revoke)? beforeDelete;
  bool Function()? recoveryReady;
  final void Function(File file)? removeFile;
  final List<FileSystemEntity> Function(Directory directory)? listDirectory;

  /// False means pre-ledger files may remain. They are never owned by a scope.
  final Future<bool> Function()? legacyClean;
  final Map<String, Stopwatch> _leases = {};
  final Map<String, ({Stopwatch clock, Duration budget})> _ages = {};
  final Set<String> _revoked = {};
  Future<void> _tail = Future<void>.value();
  Future<TempCleanupResult>? _sweep;
  bool _firstScan = true;
  static final _uuid = RegExp(
    r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$',
  );

  static bool validId(String value) => _uuid.hasMatch(value);
  Future<bool> ownsActivePayload(String scope, String path) =>
      _serial(() async {
        try {
          final base = await _root();
          _safe(base, path);
          final parts = p.split(p.relative(path, from: base.path));
          if (parts.length != 4 ||
              parts[0] != scope ||
              !validId(parts[1]) ||
              parts[2] != 'payload' ||
              !_leases.containsKey('$scope/${parts[1]}') ||
              _revoked.contains(scope))
            return false;
          final task = Directory(p.join(base.path, scope, parts[1]));
          if (File(p.join(task.path, '.delete')).existsSync() ||
              File(p.join(task.parent.path, '.revoked')).existsSync())
            return false;
          return FileSystemEntity.typeSync(path, followLinks: false) ==
              FileSystemEntityType.file;
        } on Object {
          return false;
        }
      });
  Future<T> _serial<T>(FutureOr<T> Function() work) {
    final result = _tail.then((_) => work());
    _tail = result.then<void>((_) {}, onError: (Object _, StackTrace _) {});
    return result;
  }

  Future<Directory> _root() async {
    try {
      final dir = await root();
      final absolute = p.normalize(p.absolute(dir.path));
      if (FileSystemEntity.typeSync(absolute, followLinks: false) ==
          FileSystemEntityType.notFound) {
        dir.createSync(recursive: true);
      }
      if (FileSystemEntity.typeSync(absolute, followLinks: false) !=
          FileSystemEntityType.directory) {
        throw const TempStoreUnavailable();
      }
      // /var -> /private/var on iOS is a platform alias in an ancestor;
      // the reserved root itself must be a real directory, never a link.
      return Directory(dir.resolveSymbolicLinksSync());
    } on Object {
      throw const TempStoreUnavailable();
    }
  }

  void _safe(Directory root, String path, {bool missing = false}) {
    final normal = p.normalize(p.absolute(path));
    if (!p.isWithin(root.path, normal)) throw const TempStoreUnavailable();
    var current = root.path;
    for (final part in p.split(p.relative(normal, from: root.path))) {
      current = p.join(current, part);
      final type = FileSystemEntity.typeSync(current, followLinks: false);
      if (type == FileSystemEntityType.link) throw const TempStoreUnavailable();
      if (type == FileSystemEntityType.notFound) {
        if (missing) return;
        throw const TempStoreUnavailable();
      }
      final resolved = type == FileSystemEntityType.directory
          ? Directory(current).resolveSymbolicLinksSync()
          : File(current).resolveSymbolicLinksSync();
      if (!p.isWithin(root.path, resolved)) throw const TempStoreUnavailable();
    }
  }

  void _mark(Directory root, String path, [String value = '1']) {
    _safe(root, path, missing: true);
    File(path).writeAsStringSync(value, flush: true);
  }

  List<FileSystemEntity> _list(Directory dir) =>
      listDirectory?.call(dir) ?? dir.listSync(followLinks: false);

  Future<OwnedTempTask> create(String scope, String kind) => _serial(() async {
    if (!validId(scope) || !{'picker', 'export'}.contains(kind)) {
      throw const TempStoreUnavailable();
    }
    final base = await _root();
    final owner = Directory(p.join(base.path, scope));
    _safe(base, owner.path, missing: true);
    owner.createSync();
    if (_revoked.contains(scope) ||
        File(p.join(owner.path, '.revoked')).existsSync()) {
      throw const TempStoreUnavailable();
    }
    final id = newUuid();
    final dir = Directory(p.join(owner.path, id))..createSync();
    final created = now().toUtc().millisecondsSinceEpoch;
    // Registration precedes every Dart/native payload write.
    _mark(
      base,
      p.join(dir.path, 'marker.json'),
      jsonEncode({
        'version': 1,
        'scope': scope,
        'task': id,
        'kind': kind,
        'created': created,
        'expires': created + policy.shareGrace.inMilliseconds,
      }),
    );
    Directory(p.join(dir.path, 'payload')).createSync();
    final age = Stopwatch()..start();
    _leases['$scope/$id'] = age;
    _ages['$scope/$id'] = (clock: age, budget: policy.shareGrace);
    return OwnedTempTask._(this, base, scope, id, kind, dir);
  });

  /// In-memory invalidation is synchronous; durable marking is awaited by
  /// explicit deletion before any database wipe. Forced sign-out can proceed.
  void invalidate(String scope) {
    _revoked.add(scope);
    _leases.removeWhere((key, _) => key.startsWith('$scope/'));
  }

  Future<void> markRevoked(String scope) {
    invalidate(scope);
    return _serial(() async {
      if (!validId(scope)) throw const TempStoreUnavailable();
      final base = await _root();
      final owner = Directory(p.join(base.path, scope));
      _safe(base, owner.path, missing: true);
      owner.createSync();
      _mark(base, p.join(owner.path, '.revoked'));
    });
  }

  Future<bool> isRevoked(String scope) => _serial(() async {
    if (!validId(scope)) throw const TempStoreUnavailable();
    final base = await _root();
    final marker = p.join(base.path, scope, '.revoked');
    _safe(base, marker, missing: true);
    return _revoked.contains(scope) || File(marker).existsSync();
  });

  Future<TempCleanupResult> cancelKind(String scope, String kind) =>
      _serial(() async {
        var result = const TempCleanupResult();
        try {
          if (recoveryReady != null && !recoveryReady!()) {
            return const TempCleanupResult(unknown: true);
          }
          if (!validId(scope) || !{'picker', 'export'}.contains(kind)) {
            throw const TempStoreUnavailable();
          }
          final base = await _root();
          final owner = Directory(p.join(base.path, scope));
          _safe(base, owner.path, missing: true);
          if (!owner.existsSync()) return result;
          for (final entry in _list(owner)) {
            final task = p.basename(entry.path);
            if (task == '.revoked') continue;
            _safe(base, entry.path);
            if (!validId(task) || entry is! Directory) {
              throw const TempStoreUnavailable();
            }
            final marker = File(p.join(entry.path, 'marker.json'));
            _safe(base, marker.path);
            final data =
                jsonDecode(marker.readAsStringSync()) as Map<String, dynamic>;
            if (data['scope'] != scope || data['task'] != task) {
              throw const TempStoreUnavailable();
            }
            if (data['kind'] == kind) {
              result = result.plus(await _deleteTask(base, scope, task, entry));
            }
          }
        } on Object {
          result = result.plus(const TempCleanupResult(unknown: true));
        }
        return result;
      });

  Future<TempCleanupResult> revoke(String scope) {
    invalidate(scope);
    return _serial(() async {
      try {
        if (!validId(scope)) throw const TempStoreUnavailable();
        final base = await _root();
        final owner = Directory(p.join(base.path, scope));
        _safe(base, owner.path, missing: true);
        owner.createSync();
        _mark(base, p.join(owner.path, '.revoked'));
        return await _cleanScope(base, owner, force: true, clockBad: false);
      } on Object {
        return const TempCleanupResult(unknown: true);
      }
    });
  }

  /// Joined by startup, foreground, privacy retry and the next export.
  Future<TempCleanupResult> sweep() => _sweep ??=
      _serial(() async {
        var result = const TempCleanupResult();
        try {
          if (recoveryReady != null && !recoveryReady!()) {
            return const TempCleanupResult(unknown: true);
          }
          try {
            if (legacyClean != null && !await legacyClean!()) {
              result = result.plus(const TempCleanupResult(unknown: true));
            }
          } on Object {
            result = result.plus(const TempCleanupResult(unknown: true));
          }
          final base = await _root();
          final clock = File(p.join(base.path, '.clock'));
          _safe(base, clock.path, missing: true);
          final current = now().toUtc().millisecondsSinceEpoch;
          final previous = clock.existsSync()
              ? int.tryParse(clock.readAsStringSync())
              : null;
          final bad =
              previous != null &&
              (current < previous || (_firstScan && current <= previous));
          _firstScan = false;
          _mark(
            base,
            clock.path,
            '${previous != null && previous > current ? previous : current}',
          );
          for (final entry in _list(base)) {
            final name = p.basename(entry.path);
            if (name == '.clock') continue;
            if (!validId(name)) {
              result = result.plus(const TempCleanupResult(unknown: true));
              continue;
            }
            try {
              _safe(base, entry.path);
              if (entry is! Directory) throw const TempStoreUnavailable();
              final force =
                  _revoked.contains(name) ||
                  File(p.join(entry.path, '.revoked')).existsSync();
              result = result.plus(
                await _cleanScope(base, entry, force: force, clockBad: bad),
              );
            } on Object {
              result = result.plus(const TempCleanupResult(unknown: true));
            }
          }
        } on Object {
          result = result.plus(const TempCleanupResult(unknown: true));
        }
        return result;
      }).whenComplete(() {
        _sweep = null;
      });

  Future<TempCleanupResult> _cleanScope(
    Directory base,
    Directory owner, {
    required bool force,
    required bool clockBad,
  }) async {
    var result = const TempCleanupResult();
    for (final entity in _list(owner)) {
      final id = p.basename(entity.path);
      if (id == '.revoked') continue;
      if (!validId(id)) {
        result = result.plus(const TempCleanupResult(unknown: true));
        continue;
      }
      try {
        _safe(base, entity.path);
        if (entity is! Directory) throw const TempStoreUnavailable();
        final scope = p.basename(owner.path);
        final key = '$scope/$id';
        final lease = _leases[key];
        final active = lease != null && lease.elapsed < policy.activeLease;
        final deletion = File(p.join(entity.path, '.delete')).existsSync();
        if (active && !force && !deletion) continue;
        final marker = File(p.join(entity.path, 'marker.json'));
        Map<String, dynamic>? data;
        if (marker.existsSync()) {
          _safe(base, marker.path);
          try {
            data =
                jsonDecode(marker.readAsStringSync()) as Map<String, dynamic>;
          } on Object {
            /* owned orphan */
          }
        }
        final shared = File(p.join(entity.path, '.shared')).existsSync();
        final expires = data?['expires'];
        final created = data?['created'];
        final current = now().toUtc().millisecondsSinceEpoch;
        final valid =
            data?['version'] == 1 &&
            data?['scope'] == scope &&
            data?['task'] == id &&
            {'picker', 'export'}.contains(data?['kind']) &&
            created is int &&
            created <= current &&
            expires is int &&
            expires >= created &&
            expires - created <= policy.shareGrace.inMilliseconds;
        final retain =
            shared &&
            !force &&
            !deletion &&
            !clockBad &&
            valid &&
            current < expires &&
            _withinGrace(key, expires - current);
        if (retain) continue;
        result = result.plus(await _deleteTask(base, scope, id, entity));
      } on Object {
        result = result.plus(
          const TempCleanupResult(remaining: 1, unknown: true),
        );
      }
    }
    return result;
  }

  bool _withinGrace(String key, int remainingMilliseconds) {
    // Restored files have no process-local age. Capture only their original
    // remaining grace once, so a later wall-clock freeze cannot extend it.
    final age = _ages.putIfAbsent(
      key,
      () => (
        clock: Stopwatch()..start(),
        budget: Duration(milliseconds: remainingMilliseconds),
      ),
    );
    return age.clock.elapsed < age.budget;
  }

  Future<TempCleanupResult> _deleteTask(
    Directory base,
    String scope,
    String id,
    Directory dir,
  ) async {
    try {
      final type = FileSystemEntity.typeSync(dir.path, followLinks: false);
      if (type == FileSystemEntityType.notFound) {
        return const TempCleanupResult();
      }
      if (type != FileSystemEntityType.directory) {
        throw const TempStoreUnavailable();
      }
      _mark(base, p.join(dir.path, '.delete'));
      if (beforeDelete != null && !await beforeDelete!(scope, id, true)) {
        return const TempCleanupResult(remaining: 1);
      }
      // Recheck after native await; never use recursive delete across links.
      _safe(base, dir.path);
      _removeTree(base, dir);
      _leases.remove('$scope/$id');
      _ages.remove('$scope/$id');
      return const TempCleanupResult();
    } on Object {
      return const TempCleanupResult(remaining: 1, unknown: true);
    }
  }

  void _removeTree(Directory base, Directory dir) {
    _safe(base, dir.path);
    final children = _list(dir);
    // Payload first; ledger and tombstone last, preserving retry evidence.
    children.sort(
      (a, b) => (p.basename(a.path) == 'payload' ? -1 : 1).compareTo(
        p.basename(b.path) == 'payload' ? -1 : 1,
      ),
    );
    for (final child in children) {
      _safe(base, child.path);
      if (child is Directory) {
        _removeTree(base, child);
      } else if (child is File) {
        if (removeFile == null) {
          child.deleteSync();
        } else {
          removeFile!(child);
        }
      } else {
        throw const TempStoreUnavailable();
      }
    }
    dir.deleteSync();
  }
}

class OwnedTempTask {
  OwnedTempTask._(
    this.store,
    this.base,
    this.scope,
    this.id,
    this.kind,
    this.directory,
  );
  final OwnedTempStore store;
  final Directory base;
  final String scope;
  final String id;
  final String kind;
  final Directory directory;
  String get payloadPath => p.join(directory.path, 'payload');
  Map<String, String> get nativeArguments => {'scope': scope, 'task': id};

  void check() {
    store._safe(base, directory.path);
    if (store._revoked.contains(scope) ||
        File(p.join(directory.parent.path, '.revoked')).existsSync() ||
        File(p.join(directory.path, '.delete')).existsSync()) {
      throw const TempStoreUnavailable();
    }
  }

  File file(String name) {
    check();
    if (p.basename(name) != name || name == '.' || name == '..') {
      throw const TempStoreUnavailable();
    }
    final path = p.join(payloadPath, name);
    store._safe(base, path, missing: true);
    return File(path);
  }

  bool owns(String path) {
    try {
      check();
      final normal = p.normalize(p.absolute(path));
      if (!p.isWithin(payloadPath, normal)) return false;
      store._safe(base, normal);
      return FileSystemEntity.typeSync(normal, followLinks: false) ==
          FileSystemEntityType.file;
    } on Object {
      return false;
    }
  }

  void markShared() {
    check();
    store._mark(base, p.join(directory.path, '.shared'));
  }

  void release() => store._leases.remove('$scope/$id');
  Future<TempCleanupResult> cleanup() =>
      store._serial(() => store._deleteTask(base, scope, id, directory));
}
