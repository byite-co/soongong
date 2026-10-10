// PhotoRetention (S09 · S09b, D14 row 3): the 30-day photo rule on this
// device — expired files are deleted at app start, on foreground, when the
// privacy screen opens and on access; the user deletes one or all photos
// now; logout, account deletion and 모든 기록 삭제 wipe every file. A deleted
// file keeps its row as the "삭제됨" marker (`markPhotoDeleted`); only the
// wipe removes rows — and only the rows whose file is really gone, so a
// failed deletion keeps account + path for a retry ([S09b]). Derived
// images and the camera cache follow the `PhotoStore` layout contract.
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
/// deleted: the rows stay for a retry and the action is not completed.
class PhotoWipeFailed implements Exception {
  const PhotoWipeFailed(this.failed);

  final int failed;

  @override
  String toString() => 'PhotoWipeFailed($failed)';
}

class PhotoDeleteResult {
  const PhotoDeleteResult({required this.deleted, required this.failed});

  final List<String> deleted;
  final List<String> failed;

  int get total => deleted.length + failed.length;
  bool get allDone => failed.isEmpty;
}

class PhotoRetention {
  PhotoRetention({required this.reading, required this.store, required this.now});

  final ReadingRepository reading;
  final PhotoStore store;
  final DateTime Function() now;

  /// Deletes files past `expires_at` (rows marked) and the stale camera
  /// cache. Returns the number of expired photos removed.
  Future<int> purgeExpired() async {
    var n = 0;
    for (final p in await reading.expiredPhotos(now())) {
      if (await store.delete(p.localPath)) {
        await reading.markPhotoDeleted(p.id);
        n++;
      }
    }
    final cache = await store.clearCache(now: now());
    if (n > 0 || cache > 0) appLog.i('photos · expired deleted=$n cache=$cache');
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

  /// Logout / account deletion / 모든 기록 삭제: every file, then the rows of
  /// the files that are gone (markers included). A file that cannot be
  /// deleted keeps its row — the caller reports the failure.
  Future<PhotoDeleteResult> wipeAll() async {
    final all = await reading.getAllPhotos(includeDeleted: true);
    final ok = <String>[];
    final failed = <String>[];
    for (final p in all) {
      if (p.deletedAt != null || await store.delete(p.localPath)) {
        ok.add(p.id);
      } else {
        failed.add(p.id);
      }
    }
    if (ok.isNotEmpty) await reading.purgePhotoRows(ok);
    return PhotoDeleteResult(deleted: ok, failed: failed);
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
