import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:soongong/data/photos/photo_store.dart';

void main() {
  test(
    'TMP-02 legacy PhotoStore never follows external directory or derived symlinks',
    () async {
      final sandbox = Directory.systemTemp.createTempSync('photo-safe-');
      addTearDown(() => sandbox.deleteSync(recursive: true));
      final root = Directory('${sandbox.path}/photos')..createSync();
      final external = Directory('${sandbox.path}/external')..createSync();
      final original = File('${external.path}/photo.jpg')
        ..writeAsBytesSync([9]);
      Link('${root.path}/linked').createSync(external.path);
      final store = PhotoStore(() async => root);
      expect(await store.delete('linked/photo.jpg'), isFalse);
      expect((await store.sweep()).complete, isFalse);
      expect(original.readAsBytesSync(), [9]);
      Link('${root.path}/linked').deleteSync();
      final owned = File('${root.path}/own.jpg')..writeAsBytesSync([1]);
      Link('${root.path}/own.derived.jpg').createSync(original.path);
      await store.delete('own.jpg');
      expect(owned.existsSync(), isFalse);
      expect(original.readAsBytesSync(), [9]);
    },
  );

  test(
    'DEL-04 deletion rechecks owner after asynchronous root resolution',
    () async {
      final root = Directory.systemTemp.createTempSync('photo-owner-');
      addTearDown(() => root.deleteSync(recursive: true));
      final file = File('${root.path}/reused.jpg')..writeAsBytesSync([1]);
      final paused = Completer<Directory>();
      final store = PhotoStore(() => paused.future);
      var current = true;
      final removal = store.delete('reused.jpg', proceed: () => current);
      current = false;
      file.writeAsBytesSync([2]);
      paused.complete(root);
      expect(await removal, isFalse);
      expect(file.readAsBytesSync(), [2]);
    },
  );

  test(
    'TMP-03 legacy cache root failure is unknown rather than zero cleaned',
    () async {
      final store = PhotoStore(
        () async => throw const FileSystemException('synthetic'),
      );
      await expectLater(
        store.clearCache(now: DateTime.utc(2026)),
        throwsA(isA<PhotoStoreUnavailable>()),
      );
    },
  );
}
