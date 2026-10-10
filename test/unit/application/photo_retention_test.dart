// PhotoRetention (S09, D14): expired files are deleted and their rows
// marked; deleteOne / deleteMany remove files and mark rows (an absent file
// counts as gone); wipeAll removes files and every row, markers included.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:soongong/data/photos/photo_store.dart';
import 'package:soongong/features/privacy/application/photo_retention.dart';

import '../data/db_test_helpers.dart';

void main() {
  late TestHarness h;
  late Directory dir;
  late PhotoRetention r;

  setUp(() {
    h = TestHarness();
    dir = Directory.systemTemp.createTempSync('soongong-photo-test-');
    r = PhotoRetention(reading: h.reading, store: PhotoStore(() async => dir), now: h.clock.now);
  });
  tearDown(() async {
    await h.close();
    if (dir.existsSync()) dir.deleteSync(recursive: true);
  });

  Future<File> file(String rel) async {
    final f = File('${dir.path}/$rel');
    await f.parent.create(recursive: true);
    return f.writeAsBytes(<int>[1]);
  }

  test('purgeExpired: only photos past 30 days, file gone and row marked', () async {
    final old = await h.reading.addPhoto(localPath: 'a/old.jpg', takenAt: kT0.subtract(const Duration(days: 31)), width: 1, height: 1, pageIndex: 0);
    final fresh = await h.reading.addPhoto(localPath: 'a/fresh.jpg', takenAt: kT0.subtract(const Duration(days: 29)), width: 1, height: 1, pageIndex: 0);
    await file('a/old.jpg');
    await file('a/fresh.jpg');

    expect(await r.purgeExpired(), 1);
    expect(File('${dir.path}/a/old.jpg').existsSync(), isFalse);
    expect(File('${dir.path}/a/fresh.jpg').existsSync(), isTrue);
    final live = await h.reading.getAllPhotos();
    expect(live.map((p) => p.id), [fresh.id]);
    final all = await h.reading.getAllPhotos(includeDeleted: true);
    expect(all.firstWhere((p) => p.id == old.id).deletedAt, isNotNull, reason: '삭제됨 marker kept');
    expect(await r.purgeExpired(), 0, reason: 'idempotent');
  });

  test('deleteOne · deleteMany: files removed, rows marked; a missing file still counts as deleted', () async {
    final a = await h.reading.addPhoto(localPath: 'b/a.jpg', takenAt: kT0, width: 1, height: 1, pageIndex: 0);
    final b = await h.reading.addPhoto(localPath: 'b/b.jpg', takenAt: kT0, width: 1, height: 1, pageIndex: 1);
    final missing = await h.reading.addPhoto(localPath: 'b/never-written.jpg', takenAt: kT0, width: 1, height: 1, pageIndex: 2);
    await file('b/a.jpg');
    await file('b/b.jpg');

    expect(await r.deleteOne(a), isTrue);
    expect(File('${dir.path}/b/a.jpg').existsSync(), isFalse);
    expect((await h.reading.getAllPhotos()).map((p) => p.id), [b.id, missing.id]);

    final res = await r.deleteMany([b, missing]);
    expect(res.deleted, [b.id, missing.id]);
    expect(res.failed, isEmpty);
    expect(res.allDone, isTrue);
    expect(await h.reading.getAllPhotos(), isEmpty);
    expect((await h.reading.getAllPhotos(includeDeleted: true)).length, 3);
  });

  test('wipeAll: every file and every row, markers included', () async {
    final a = await h.reading.addPhoto(localPath: 'c/a.jpg', takenAt: kT0, width: 1, height: 1, pageIndex: 0);
    await h.reading.addPhoto(localPath: 'c/b.jpg', takenAt: kT0, width: 1, height: 1, pageIndex: 1);
    await file('c/a.jpg');
    await file('c/b.jpg');
    await r.deleteOne(a); // marker row

    final res = await r.wipeAll();
    expect(res.total, 2);
    expect(res.allDone, isTrue);
    expect(File('${dir.path}/c/b.jpg').existsSync(), isFalse);
    expect(await h.reading.getAllPhotos(includeDeleted: true), isEmpty);
  });

  test('store refuses paths that escape the directory', () async {
    final store = PhotoStore(() async => dir);
    expect(await store.fileFor('../x.jpg'), isNull);
    expect(await store.fileFor('/abs.jpg'), isNull);
    expect(await store.fileFor(''), isNull);
    expect(await store.delete('../x.jpg'), isTrue, reason: 'nothing to delete inside the store');
    expect((await store.fileFor('ok/1.jpg'))!.path, '${dir.path}/ok/1.jpg');
  });
}
