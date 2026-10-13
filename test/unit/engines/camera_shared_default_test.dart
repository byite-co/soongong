import 'package:camera/camera.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soongong/data/engines/engines.dart';

const _front = CameraDescription(
  name: 'front',
  lensDirection: CameraLensDirection.front,
  sensorOrientation: 270,
);

class _Controller extends CameraController {
  _Controller() : super(_front, ResolutionPreset.low, enableAudio: false);
  int opens = 0;
  @override
  Future<void> initialize() async {
    opens++;
  }

  @override
  Future<void> startImageStream(onLatestImageAvailable onAvailable) async {}
  @override
  // ignore: must_call_super
  Future<void> dispose() async {}
}

// This regression also compiles against d55bbfe: it uses the existing public
// CameraFrameSource constructor, so CI can demonstrate the before/after change
// on the actual product source without copying its implementation into a test.
void main() {
  test(
    'RC05-GAZE02 default camera sources never initialize a second owner',
    () async {
      final a = _Controller();
      final b = _Controller();
      CameraFrameSource source(_Controller controller) => CameraFrameSource(
        listCameras: () async => [_front],
        controllerFactory:
            (_, {required int fps, ImageFormatGroup? imageFormatGroup}) =>
                controller,
      );
      Future<SeatCameraHandle> open(SeatFrameSource source) => source.open(
        const SeatFrameSourceConfig(lowPower: false),
        onFrame: (_) {},
        onFault: (_, _) {},
      );
      final first = await open(source(a));
      SeatCameraHandle? accidental;
      try {
        await expectLater(
          open(source(b)).then((h) {
            accidental = h;
            return h;
          }),
          throwsA(
            isA<SeatFrameSourceException>().having(
              (e) => e.code,
              'code',
              'camera_busy',
            ),
          ),
        );
        expect(b.opens, 0);
      } finally {
        await accidental?.close();
        await first.close();
      }
      final next = await open(source(b));
      expect(b.opens, 1);
      await next.close();
    },
  );
}
