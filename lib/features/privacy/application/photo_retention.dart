// PhotoRetention (S09, D14 row 3): the 30-day photo rule on this device —
// expired files are deleted at app start, on foreground and when the
// privacy screen opens; the user deletes one or all photos now; logout and
// account deletion wipe every file. A deleted file keeps its row as the
// "삭제됨" marker (`markPhotoDeleted`); only logout/purge removes rows.

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/domain/entities/entities.dart';
import '../../../core/logging/app_logger.dart';
import '../../../data/photos/photo_store.dart';
import '../../../data/repositories/reading_repository.dart';
import '../../../data/repositories/repository_providers.dart';

part 'photo_retention.g.dart';

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

  /// Deletes files past `expires_at` and marks their rows.
  Future<int> purgeExpired() async {
    var n = 0;
    for (final p in await reading.expiredPhotos(now())) {
      if (await store.delete(p.localPath)) {
        await reading.markPhotoDeleted(p.id);
        n++;
      }
    }
    if (n > 0) appLog.i('photos · expired deleted=$n');
    return n;
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

  /// Logout / account deletion / 모든 기록 삭제: every file, then every row
  /// (markers included). Files that cannot be deleted keep their row.
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
