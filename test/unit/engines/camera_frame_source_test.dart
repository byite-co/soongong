// S04e §3: the real CameraFrameSource boundary — a controller whose dispose
// throws or never completes is returned as a CloseResult, not swallowed.

import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soongong/data/engines/engines.dart';

const CameraDescription _front = CameraDescription(
  name: 'front',
  lensDirection: CameraLensDirection.front,
  sensorOrientation: 270,
);

/// A controller that never touches the platform.
class _FakeController extends CameraController {
  _FakeController(CameraDescription camera, {this.onDispose})
      : super(camera, ResolutionPreset.low, enableAudio: false);

  final Future<void> Function()? onDispose;
  int disposeCalls = 0;

  @override
  Future<void> initialize() async {}

  @override
  Future<void> startImageStream(onLatestImageAvailable onAvailable) async {}

  @override
  Future<void> stopImageStream() async {}

  // The platform release is what this fake stands in for; ChangeNotifier's
  // own dispose is irrelevant to the boundary under test.
  @override
  // ignore: must_call_super
  Future<void> dispose() {
    disposeCalls++;
    return onDispose?.call() ?? Future<void>.value();
  }
}

CameraFrameSource _source(_FakeController controller, {Duration disposeTimeout = const Duration(seconds: 2)}) =>
    CameraFrameSource(
      listCameras: () async => <CameraDescription>[_front],
      controllerFactory: (camera, {required int fps, ImageFormatGroup? imageFormatGroup}) => controller,
      disposeTimeout: disposeTimeout,
    );

const SeatFrameSourceConfig _cfg = SeatFrameSourceConfig(lowPower: false);

void main() {
  test('a clean dispose answers ok and the session is gone', () async {
    final c = _FakeController(_front);
    final src = _source(c);
    final h = await src.open(_cfg, onFrame: (_) {}, onFault: (_, _) {});
    expect(h.isOpen, isTrue);
    expect(src.hasOpenSession, isTrue);
    final r = await h.close();
    expect(r.isOk, isTrue);
    expect(c.disposeCalls, 1);
    expect(h.isOpen, isFalse);
    expect(src.hasOpenSession, isFalse);
    expect((await h.close()).isOk, isTrue, reason: 'idempotent');
    expect(c.disposeCalls, 1);
  });

  test('a dispose that throws is returned as failed with the error', () async {
    final boom = CameraException('disposeFailed', 'native release failed');
    final c = _FakeController(_front, onDispose: () async => throw boom);
    final src = _source(c);
    final h = await src.open(_cfg, onFrame: (_) {}, onFault: (_, _) {});
    final r = await h.close();
    expect(r.outcome, CloseOutcome.failed);
    expect(r.error, same(boom));
    expect(h.isOpen, isFalse, reason: 'the session is over either way');
    expect(src.hasOpenSession, isFalse);
  });

  test('a dispose that throws synchronously is returned as failed too', () async {
    final c = _FakeController(_front, onDispose: () => throw StateError('sync'));
    final src = _source(c);
    final h = await src.open(_cfg, onFrame: (_) {}, onFault: (_, _) {});
    final r = await h.close();
    expect(r.outcome, CloseOutcome.failed);
    expect(r.error, isA<StateError>());
  });

  test('a dispose that never completes is returned as timeout after disposeTimeout', () async {
    final c = _FakeController(_front, onDispose: () => Completer<void>().future);
    final src = _source(c, disposeTimeout: const Duration(milliseconds: 50));
    final h = await src.open(_cfg, onFrame: (_) {}, onFault: (_, _) {});
    final sw = Stopwatch()..start();
    final r = await h.close();
    expect(r.outcome, CloseOutcome.timeout);
    expect(r.waited, const Duration(milliseconds: 50));
    expect(sw.elapsed, greaterThanOrEqualTo(const Duration(milliseconds: 45)));
    expect(h.isOpen, isFalse);
  });

  test('a late dispose completing after the timeout changes nothing', () async {
    final late = Completer<void>();
    final c = _FakeController(_front, onDispose: () => late.future);
    final src = _source(c, disposeTimeout: const Duration(milliseconds: 20));
    final h = await src.open(_cfg, onFrame: (_) {}, onFault: (_, _) {});
    final r = await h.close();
    expect(r.outcome, CloseOutcome.timeout);
    late.complete();
    await Future<void>.delayed(Duration.zero);
    expect(c.disposeCalls, 1);
    expect((await h.close()).isOk, isTrue);
  });
}
