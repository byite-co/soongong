import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;
import '../temp/owned_temp_store.dart';

/// Crop coordinates are normalized in the rotated image, clockwise quarter
/// turns from the decoded original. The caller retains the user's original.
Future<Uint8List> cropStudyImage(
  Uint8List bytes,
  ui.Rect crop,
  int turns,
  OwnedTempTask task,
) async {
  task.check();
  if (bytes.isEmpty ||
      bytes.length > 4 * 1024 * 1024 ||
      turns < 0 ||
      turns > 3 ||
      ![
        crop.left,
        crop.top,
        crop.right,
        crop.bottom,
      ].every((n) => n.isFinite && n >= 0 && n <= 1) ||
      crop.width <= 0 ||
      crop.height <= 0) {
    throw const FormatException('invalid_crop');
  }
  final buffer = await ui.ImmutableBuffer.fromUint8List(bytes);
  ui.ImageDescriptor? descriptor;
  ui.Codec? codec;
  ui.Image? source;
  ui.Image? output;
  ui.Picture? picture;
  try {
    descriptor = await ui.ImageDescriptor.encoded(buffer);
    if (descriptor.width * descriptor.height > 12000000)
      throw const FormatException('image_too_large');
    codec = await descriptor.instantiateCodec();
    if (codec.frameCount != 1) throw const FormatException('invalid_image');
    source = (await codec.getNextFrame()).image;
    final width = turns.isOdd ? source.height : source.width;
    final height = turns.isOdd ? source.width : source.height;
    final outWidth = math.max(1, (width * crop.width).round());
    final outHeight = math.max(1, (height * crop.height).round());
    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder);
    canvas.translate(-crop.left * width, -crop.top * height);
    switch (turns) {
      case 1:
        canvas.translate(width.toDouble(), 0);
      case 2:
        canvas.translate(width.toDouble(), height.toDouble());
      case 3:
        canvas.translate(0, height.toDouble());
    }
    canvas.rotate(turns * math.pi / 2);
    canvas.drawImage(source, ui.Offset.zero, ui.Paint());
    picture = recorder.endRecording();
    output = await picture.toImage(outWidth, outHeight);
    final encoded = await output.toByteData(format: ui.ImageByteFormat.png);
    if (encoded == null || encoded.lengthInBytes > 4 * 1024 * 1024)
      throw const FormatException('image_too_large');
    task.check();
    final file = task.file('crop.png');
    await file.writeAsBytes(encoded.buffer.asUint8List(), flush: true);
    task.check();
    return file.readAsBytes();
  } finally {
    output?.dispose();
    picture?.dispose();
    source?.dispose();
    codec?.dispose();
    descriptor?.dispose();
    buffer.dispose();
  }
}
