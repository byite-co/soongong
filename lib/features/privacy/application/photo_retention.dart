// PhotoRetention (S09 · S09b · S09c, D14 row 3): the 30-day photo rule on
// this device — expired files are deleted at app start, on foreground, when
// the privacy screen opens and on access; the user deletes one or all
// photos now; logout, account deletion and 모든 기록 삭제 wipe every file
// under the store (rows, derived images, the camera cache and any
// temporary capture — no age condition, [S09c]). A deleted file keeps its
// row as the "삭제됨" marker (`markPhotoDeleted`); only the wipe removes rows
// — and only the rows whose file is really gone, so a failed deletion keeps
// account + path for a retry ([S09b]). A row-less file that could not be
// deleted is counted too: the wipe leaves the `photo_sweep_pending` marker
// (account id) and the next start / foreground sweeps again, keeping the
// live rows' files. A wipe stops when its account is no longer signed in
// ([alive]) — it never deletes the next account's files. A store that
// cannot be opened or listed is a failure, not an empty store ([S09d]):
// the result says `storeUnavailable`, the marker stays, nothing is
// reported as deleted that was not seen.
//
// S10 reads photos through [fileFor]: an expired or deleted photo is never
// handed out (the file is removed on the spot); a retry never extends
// `expires_at`.

import 'dart:io';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/domain/entities/entities.dart';
import '../../../core/logging/app_logger.dart';
import '../../../data/auth/auth_gate.dart';
import '../../../data/auth/auth_mode.dart';
import '../../../data/auth/auth_providers.dart';
import '../../../data/photos/photo_store.dart';
import '../../../data/repositories/reading_repository.dart';
import '../../../data/repositories/repository_providers.dart';
import '../../../data/temp/owned_temp_store.dart';
import '../../../data/temp/temp_ownership.dart';
import '../../../data/temp/temp_providers.dart';

part 'photo_retention.g.dart';

/// Thrown by logout / account deletion when device photos could not all be
/// deleted: the rows (and the sweep marker) stay for a retry and the action
/// is not completed.
class PhotoWipeFailed implements Exception {
  const PhotoWipeFailed(this.failed, {this.storeUnavailable = false});

  /// Rows whose file stayed + row-less files that stayed (0 when the store
  /// could not be opened — the count is unknown then).
  final int failed;

  /// The store could not be opened or listed ([S09d]).
  final bool storeUnavailable;

  @override
  String toString() =>
      'PhotoWipeFailed($failed${storeUnavailable ? ' · store unavailable' : ''})';
}

class PhotoDeleteResult {
  const PhotoDeleteResult({
    required this.deleted,
    required this.failed,
    this.failedFiles = 0,
    this.storeUnavailable = false,
  });

  final List<String> deleted;
  final List<String> failed;

  /// Row-less files (cache · temporary captures · orphans) the sweep could
  /// not delete ([S09c]).
  final int failedFiles;

  /// The store could not be opened or listed, so the row-less files are
  /// unknown ([S09d]).
  final bool storeUnavailable;

  int get total => deleted.length + failed.length;
  int get failedCount => failed.length + failedFiles;
  bool get allDone => failed.isEmpty && failedFiles == 0 && !storeUnavailable;
}

class PhotoRetention {
  PhotoRetention({
    required this.reading,
    required this.store,
    required this.now,
    this.temporary,
    this.ownerAlive,
  });

  final ReadingRepository reading;
  final PhotoStore store;
  final DateTime Function() now;
  final TempOwnership? temporary;
  final bool Function()? ownerAlive;
  bool _disposed = false;

  void dispose() => _disposed = true;

  _PhotoOperation _operation({bool Function()? alive}) =>
      _PhotoOperation(this, alive);

  // Acquire an account transaction for DB snapshots/markers, not for an entire
  // filesystem operation. Existing callers may already own a transaction. The
  // synchronous fence reaches the final file mutation after filesystem awaits.
  Future<T> _owned<T>(_PhotoOperation op, Future<T> Function() action) =>
      reading.writer.runOwnedTransaction(
        () async {
          op.generation ??= reading.writer.purgeGeneration;
          op.check();
          final value = await action();
          op.check();
          return value;
        },
        alive: op.current,
        generation: op.generation,
        purgeWork: true,
      );

  /// Deletes files past `expires_at` (rows marked), the stale camera cache,
  /// and retries a sweep a previous wipe left behind. Returns the number of
  /// expired photos removed.
  Future<int> purgeExpired() async {
    final op = _operation();
    var n = 0;
    try {
      final expired = await _owned(op, () => reading.expiredPhotos(now()));
      for (final p in expired) {
        if (await _deleteOne(p, op)) n++;
        op.check();
      }
      final cache = await store.clearCache(now: now(), proceed: op.current);
      op.check();
      final left = await _retryPendingSweep(op);
      op.check();
      if (n > 0 || cache > 0 || left != 0) {
        appLog.i(
          'photos · expired deleted=$n cache=$cache sweepLeft=${left ?? 'unknown'}',
        );
      }
      return n;
    } on StateError {
      return 0; // A stale lifecycle action never reports the new owner's data.
    }
  }

  /// The readable file of [photo], or null when the photo is deleted or
  /// expired (an expired file is removed right here, D14: access purges).
  Future<File?> fileFor(Photo photo) async {
    final op = _operation();
    if (photo.userId != reading.ctx.userId || photo.isDeleted) return null;
    try {
      await _owned(op, () async {});
      if (!photo.expiresAt.isAfter(now())) {
        await _deleteOne(photo, op);
        return null;
      }
      final f = await store.fileFor(photo.localPath);
      op.check();
      return f != null && f.existsSync() ? f : null;
    } on StateError {
      return null;
    }
  }

  /// true when the file is gone and the row marked; false = retry later.
  Future<bool> deleteOne(Photo photo) async {
    final op = _operation();
    try {
      await _owned(op, () async {});
      return await _deleteOne(photo, op);
    } on StateError {
      return false;
    }
  }

  Future<bool> _deleteOne(Photo photo, _PhotoOperation op) async {
    op.check();
    if (photo.userId != reading.ctx.userId) return false;
    if (!await store.delete(photo.localPath, proceed: op.current)) return false;
    op.check();
    await _owned(op, () => reading.markPhotoDeleted(photo.id));
    return true;
  }

  Future<PhotoDeleteResult> deleteMany(Iterable<Photo> photos) async {
    final op = _operation();
    final ok = <String>[];
    final failed = <String>[];
    for (final p in photos) {
      try {
        await _owned(op, () async {});
        (await _deleteOne(p, op) ? ok : failed).add(p.id);
      } on StateError {
        failed.add(p.id);
      }
    }
    return PhotoDeleteResult(deleted: ok, failed: failed);
  }

  /// Logout / account deletion / 모든 기록 삭제: every row's file, then the
  /// rows of the files that are gone (markers included), then every other
  /// file under the store. A row whose file cannot be deleted keeps its
  /// row; a row-less file that stays is counted in `failedFiles` and the
  /// sweep marker stays for the retry. [alive] false stops the wipe (the
  /// account changed): throws StateError without writing the next owner's
  /// marker or reporting completion.
  Future<PhotoDeleteResult> wipeAll({bool Function()? alive}) async {
    final op = _operation(alive: alive);
    await _owned(op, () async {});
    // Persist revocation outside the DB before any caller may wipe its account
    // mapping. Failure to persist must throw, retaining the database for retry.
    var temp = const TempCleanupResult();
    if (temporary != null) {
      op.check();
      final revoking = temporary!.revoke(reading.ctx.userId);
      // revoke increments once synchronously. Accept only this operation's
      // own increment; a later account/purge/consent boundary still cancels it.
      op.followOwnRevocation();
      await revoking;
      op.check();
      // An empty account mapping does not prove the owned root is empty.
      // Count the final sweep once, including orphan/unknown obligations.
      temp = await temporary!.store.sweep();
      op.check();
    }
    final all = await _owned(op, () async {
      await reading.markPhotoSweepPending();
      return reading.getAllPhotos(includeDeleted: true);
    });
    final ok = <String>[];
    final failed = <Photo>[];
    for (final p in all) {
      op.check();
      if (p.deletedAt != null ||
          await store.delete(p.localPath, proceed: op.current)) {
        op.check();
        ok.add(p.id);
      } else {
        failed.add(p);
      }
    }
    op.check();
    if (ok.isNotEmpty) await _owned(op, () => reading.purgePhotoRows(ok));
    final sweep = await store.sweep(
      keep: <String>{for (final p in failed) p.localPath},
      proceed: op.current,
    );
    op.check();
    if (failed.isEmpty && sweep.clean) {
      await _owned(op, reading.clearPhotoSweepPending);
    }
    return PhotoDeleteResult(
      deleted: ok,
      failed: <String>[for (final p in failed) p.id],
      failedFiles: sweep.left.length + temp.remaining,
      storeUnavailable: !sweep.complete || temp.unknown,
    );
  }

  /// Finishes a wipe left behind (marker set): deletes every file that no
  /// live row names. Returns how many files are still there — 0 clears the
  /// marker; null when the store could not be opened or listed (the marker
  /// stays, nothing is known).
  Future<int?> retryPendingSweep() async {
    final op = _operation();
    try {
      await _owned(op, () async {});
      return await _retryPendingSweep(op);
    } on StateError {
      return null;
    }
  }

  Future<int?> _retryPendingSweep(_PhotoOperation op) async {
    op.check();
    final temp = await temporary?.store.sweep() ?? const TempCleanupResult();
    op.check();
    final pending = await _owned(op, reading.photoSweepPending);
    if (!pending) {
      return temp.unknown ? null : temp.remaining;
    }
    final live = await _owned(op, reading.getAllPhotos);
    final sweep = await store.sweep(
      keep: <String>{for (final p in live) p.localPath},
      proceed: op.current,
    );
    op.check();
    if (!sweep.complete || temp.unknown) return null;
    if (sweep.left.isEmpty) await _owned(op, reading.clearPhotoSweepPending);
    return sweep.left.length + temp.remaining;
  }

  /// Row-less files a previous wipe could not delete (0 when no wipe is
  /// pending; null when the store cannot be listed) — shown on the privacy
  /// screen with a retry.
  Future<int?> pendingSweepCount() async {
    final op = _operation();
    try {
      await _owned(op, () async {});
      final temp = await temporary?.store.sweep() ?? const TempCleanupResult();
      op.check();
      if (temp.unknown) return null;
      if (!await _owned(op, reading.photoSweepPending)) return temp.remaining;
      final live = <String>{
        for (final p in await _owned(op, reading.getAllPhotos)) p.localPath,
      };
      final files = await store.listAll();
      op.check();
      return temp.remaining +
          files
              .where(
                (f) => !live.contains(f) && !live.any((k) => _derivedOf(k, f)),
              )
              .length;
    } on PhotoStoreUnavailable {
      return null;
    } on StateError {
      return null;
    }
  }

  static bool _derivedOf(String original, String candidate) {
    final slash = original.lastIndexOf('/');
    final dir = slash < 0 ? '' : original.substring(0, slash + 1);
    final name = original.substring(slash + 1);
    final dot = name.lastIndexOf('.');
    final stem = dot <= 0 ? name : name.substring(0, dot);
    return candidate != original && candidate.startsWith('$dir$stem.');
  }
}

/// A single snapshot is shared by the whole operation (including batch and
/// foreground substeps). A-B-A and same-account purge cannot renew old work.
class _PhotoOperation {
  _PhotoOperation(this.owner, this.alive)
    : generation = owner.reading.writer.purgeGeneration,
      _epoch = owner.temporary?.epoch(owner.reading.ctx.userId);

  final PhotoRetention owner;
  final bool Function()? alive;
  int? generation;
  int? _epoch;

  bool current() =>
      !owner._disposed &&
      (owner.ownerAlive?.call() ?? true) &&
      (alive?.call() ?? true) &&
      (generation == null ||
          generation == owner.reading.writer.purgeGeneration) &&
      _epoch == owner.temporary?.epoch(owner.reading.ctx.userId);

  void check() {
    if (!current()) throw StateError('photo operation cancelled');
  }

  void followOwnRevocation() {
    if (_epoch != null) _epoch = _epoch! + 1;
  }
}

/// Rebuilt on account switch (the repository changes); keepAlive so the
/// lifecycle hook and the screens can use it across async gaps.
@Riverpod(keepAlive: true)
PhotoRetention photoRetention(Ref ref) {
  final clock = ref.watch(appClockProvider);
  final reading = ref.watch(readingRepositoryProvider);
  final mode = ref.watch(authModeProvider);
  final backend = ref.watch(authBackendProvider);
  final retention = PhotoRetention(
    reading: reading,
    store: ref.watch(photoStoreProvider),
    now: clock.now,
    temporary: ref.watch(tempOwnershipProvider),
    ownerAlive: () =>
        ref.mounted &&
        ref.read(authGateProvider).userId == reading.ctx.userId &&
        (mode != AuthMode.backend ||
            backend.currentSession?.userId == reading.ctx.userId),
  );
  ref.onDispose(retention.dispose);
  ref.listen(authGateProvider, (before, after) {
    if (before?.userId != after.userId) {
      retention.dispose();
      // A lazy dependency can coalesce A -> B -> A to the same user id.
      // Disposal alone would then leave the old cancelled object cached.
      ref.invalidateSelf();
    }
  });
  return retention;
}
