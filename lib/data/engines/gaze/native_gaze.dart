import 'package:flutter/services.dart';

import '../../../features/measure/domain/gaze_observation.dart';
import '../seat/camera_frame_source.dart';

class NativeGaze {
  static const channel = MethodChannel('co.byite.soongong/gaze');
  Future<void> open(String run) => channel.invokeMethod<void>('open', {'run': run});
  Future<void> close(String run) => channel.invokeMethod<void>('close', {'run': run});

  Future<GazePoint?> observe(CameraSeatFrame frame, String run, int milliseconds) async {
    final image = frame.image;
    if (image.planes.length != 1 || image.width * image.height > 2000000) return null;
    final plane = image.planes.first;
    final result = await channel.invokeMapMethod<String, dynamic>('frame', {
      'run': run, 'time': milliseconds, 'width': image.width, 'height': image.height,
      'stride': plane.bytesPerRow, 'rotation': frame.rotationDegrees, 'bytes': plane.bytes,
    });
    if (result == null || result['run'] != run || result['time'] != milliseconds) return null;
    final raw = result['points'];
    if (raw is! List || raw.length != 478) return null;
    final points = <GazePoint>[];
    for (final p in raw) {
      if (p is! List || p.length != 2 || p[0] is! num || p[1] is! num) return null;
      points.add(GazePoint((p[0] as num).toDouble(), (p[1] as num).toDouble()));
    }
    return eyeSignal(points, result['faces'] is int ? result['faces'] as int : 0);
  }
}
