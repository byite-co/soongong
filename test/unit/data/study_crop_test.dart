import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';
import 'package:soongong/data/photos/study_crop.dart';
import 'package:soongong/data/temp/owned_temp_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'A13 clockwise crop uses rotated coordinates and keeps original bytes',
    () async {
      final dir = await Directory.systemTemp.createTemp('crop-test-');
      final store = OwnedTempStore(() async => Directory('${dir.path}/owned'));
      final task = await store.create(
        '00000000-0000-4000-8000-000000000001',
        'picker',
      );
      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);
      canvas.drawRect(
        const ui.Rect.fromLTWH(0, 0, 4, 4),
        ui.Paint()..color = const ui.Color(0xFFFF0000),
      );
      canvas.drawRect(
        const ui.Rect.fromLTWH(4, 0, 4, 4),
        ui.Paint()..color = const ui.Color(0xFF0000FF),
      );
      final picture = recorder.endRecording();
      final image = await picture.toImage(8, 4);
      final source = (await image.toByteData(
        format: ui.ImageByteFormat.png,
      ))!.buffer.asUint8List();
      final original = File('${dir.path}/user-original.png')
        ..writeAsBytesSync(source);
      try {
        final output = await cropStudyImage(
          source,
          const ui.Rect.fromLTRB(0, 0, 1, .5),
          1,
          task,
        );
        final codec = await ui.instantiateImageCodec(output);
        final rotated = (await codec.getNextFrame()).image;
        expect(rotated.width, 4);
        expect(rotated.height, 4);
        final pixels = await rotated.toByteData();
        expect(pixels!.getUint8(0), 255);
        expect(pixels.getUint8(2), 0);
        rotated.dispose();
        codec.dispose();
        await expectLater(
          cropStudyImage(source, const ui.Rect.fromLTRB(1, 0, 0, 1), 0, task),
          throwsFormatException,
        );
        await task.cleanup();
        expect(original.readAsBytesSync(), source);
      } finally {
        image.dispose();
        picture.dispose();
        await task.cleanup();
        await dir.delete(recursive: true);
      }
    },
  );
}
