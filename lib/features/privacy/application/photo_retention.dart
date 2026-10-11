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
// ([alive]) — it never deletes the next account's files.
//
// S10 reads photos through [fileFor]: an expired or deleted photo is never
// handed out (the file is removed on the spot); a retry never extends
// `expires_at`.

import 'dart:io';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/domain/entities/entities.dart';
import '../../../core/logging/app_logger.dart';
import '../../../data/photos/photo_store.dart';
import '../../../data/repositories/reading_repository.dart';
import '../../../data/repositories/repository_providers.dart';

part 'photo_retention.g.dart';

/// Thrown by logout / account deletion when device photos could not all be
/// deleted: the rows (and the sweep marker) stay for a retry and the action
/// is not completed.
class PhotoWipeFailed implements Exception {
  const PhotoWipeFailed(this.failed);

  /// Rows whose file stayed + row-less files that stayed.
  final int failed;

  @override
  String toString() => 'PhotoWipeFailed($failed)';
}

class PhotoDeleteResult {
  const PhotoDeleteResult({required this.deleted, required this.failed, this.failedFiles = 0});

  final List<String> deleted;
  final List<String> failed;

  /// Row-less files (cache · temporary captures · orphans) the sweep could
  /// not delete ([S09c]).
  final int failedFiles;

  int get total => deleted.length + failed.length;
  int get failedCount => failed.length + failedFiles;
  bool get allDone => failed.isEmpty && failedFiles == 0;
}

class PhotoRetention {
  PhotoRetention({required this.reading, required this.store, required this.now});

  final ReadingRepository reading;
  final PhotoStore store;
  final DateTime Function() now;

  /// Deletes files past `expires_at` (rows marked), the stale camera cache,
  /// and retries a sweep a previous wipe left behind. Returns the number of
  /// expired photos removed.
  Future<int> purgeExpired() async {
    var n = 0;
    for (final p in await reading.expiredPhotos(now())) {
      if (await store.delete(p.localPath)) {
        await reading.markPhotoDeleted(p.id);
        n++;
      }
    }
    final cache = await store.clearCache(now: now());
    final left = await retryPendingSweep();
    if (n > 0 || cache > 0 || left > 0) appLog.i('photos · expired deleted=$n cache=$cache sweepLeft=$left');
    return n;
  }

  /// The readable file of [photo], or null when the photo is deleted or
  /// expired (an expired file is removed right here, D14: access purges).
  Future<File?> fileFor(Photo photo) async {
    if (photo.isDeleted) return null;
    if (!photo.expiresAt.isAfter(now())) {
      if (await store.delete(photo.localPath)) await reading.markPhotoDeleted(photo.id);
      return null;
    }
    final f = await store.fileFor(photo.localPath);
    return f != null && f.existsSync() ? f : null;
  }

  /// true when the file is gone and the row marked; false = retry later.
  Future<bool> deleteOne(Photo photo) async {
    if (!await store.delete(photo.localPath)) return false;
    await reading.markPhotoDeleted(photo.id);
    return true;
  }

  Future<PhotoDeleteResult> deleteMany(Iterable<Photo> photos) async {
    final ok = <String>[];
    final failed = <String>[];
    for (final p in photos) {
      (await deleteOne(p) ? ok : failed).add(p.id);
    }
    return PhotoDeleteResult(deleted: ok, failed: failed);
  }

  /// Logout / account deletion / 모든 기록 삭제: every row's file, then the
  /// rows of the files that are gone (markers included), then every other
  /// file under the store. A row whose file cannot be deleted keeps its
  /// row; a row-less file that stays is counted in `failedFiles` and the
  /// sweep marker stays for the retry. [alive] false stops the wipe (the
  /// account changed): what was not reached counts as failed.
  Future<PhotoDeleteResult> wipeAll({bool Function()? alive}) async {
    bool go() => alive == null || alive();
    await reading.markPhotoSweepPending();
    final all = await reading.getAllPhotos(includeDeleted: true);
    final ok = <String>[];
    final failed = <Photo>[];
    for (final p in all) {
      if (!go()) {
        failed.add(p);
        continue;
      }
      if (p.deletedAt != null || await store.delete(p.localPath)) {
        ok.add(p.id);
      } else {
        failed.add(p);
      }
    }
    if (ok.isNotEmpty && go()) await reading.purgePhotoRows(ok);
    final left = await store.sweep(keep: <String>{for (final p in failed) p.localPath}, proceed: go);
    if (failed.isEmpty && left.isEmpty && go()) await reading.clearPhotoSweepPending();
    return PhotoDeleteResult(deleted: ok, failed: <String>[for (final p in failed) p.id], failedFiles: left.length);
  }

  /// Finishes a wipe left behind (marker set): deletes every file that no
  /// live row names. Returns how many files are still there; 0 clears the
  /// marker.
  Future<int> retryPendingSweep() async {
    if (!await reading.photoSweepPending()) return 0;
    final live = await reading.getAllPhotos();
    final left = await store.sweep(keep: <String>{for (final p in live) p.localPath});
    if (left.isEmpty) await reading.clearPhotoSweepPending();
    return left.length;
  }

  /// Row-less files a previous wipe could not delete (0 when no wipe is
  /// pending) — shown on the privacy screen with a retry.
  Future<int> pendingSweepCount() async {
    if (!await reading.photoSweepPending()) return 0;
    final live = <String>{for (final p in await reading.getAllPhotos()) p.localPath};
    final files = await store.listAll();
    return files.where((f) => !live.contains(f) && !live.any((k) => _derivedOf(k, f))).length;
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

/// Rebuilt on account switch (the repository changes); keepAlive so the
/// lifecycle hook and the screens can use it across async gaps.
@Riverpod(keepAlive: true)
PhotoRetention photoRetention(Ref ref) {
  final clock = ref.watch(appClockProvider);
  return PhotoRetention(
    reading: ref.watch(readingRepositoryProvider),
    store: ref.watch(photoStoreProvider),
    now: clock.now,
  );
}
