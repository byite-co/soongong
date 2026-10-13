import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:soongong/data/photos/study_image_picker.dart';

void main() {
  test(
    'PICK-03 older same-path cleanup cannot delete newer selection',
    () async {
      final dir = Directory.systemTemp.createTempSync('picker-claims-');
      addTearDown(() => dir.deleteSync(recursive: true));
      final file = File('${dir.path}/same.png')..writeAsBytesSync([1]);
      final old = Completer<XFile?>();
      var requests = 0;
      final picker = StudyImagePicker(
        temporaryDirectory: () async => dir,
        pickFile: (_) async =>
            requests++ == 0 ? await old.future : XFile(file.path),
      );
      final pending = picker.pick(ImageSource.gallery);
      final fresh = (await picker.pick(ImageSource.camera))!;
      old.complete(XFile(file.path));
      await (await pending)!.cleanup();
      expect(file.existsSync(), isTrue);
      await fresh.cleanup();
      expect(file.existsSync(), isFalse);
    },
  );

  test('PICK-04 originals outside app cache are preserved', () async {
    final dir = Directory.systemTemp.createTempSync('picker-original-');
    addTearDown(() => dir.deleteSync(recursive: true));
    final cache = Directory('${dir.path}/cache')..createSync();
    final file = File('${dir.path}/original.png')..writeAsBytesSync([1]);
    final picker = StudyImagePicker(
      temporaryDirectory: () async => cache,
      pickFile: (_) async => XFile(file.path),
    );
    await (await picker.pick(ImageSource.gallery))!.cleanup();
    expect(file.readAsBytesSync(), [1]);
  });
}
