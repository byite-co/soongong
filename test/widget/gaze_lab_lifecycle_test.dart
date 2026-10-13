import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soongong/core/dev/gaze_lab_screen.dart';
import 'package:soongong/core/strings/gaze_strings.dart';
import 'package:soongong/data/engines/gaze/native_gaze.dart';
import 'package:soongong/data/engines/seat/camera_frame_source.dart';
import 'package:soongong/data/engines/seat/camera_permission.dart';
import 'package:soongong/data/engines/seat/seat_availability.dart';
import 'package:soongong/data/engines/seat/seat_frame_source.dart';
import 'package:soongong/features/measure/application/measure_controller.dart';

import '../helpers/fake_seat_sources.dart';

// These tests mount the product screen and, for stream-stop cases, the real
// CameraFrameSource/_CameraSession. Only OS/native/measurement boundaries are
// replaced. WidgetTester controls the clock; no wall-clock sleeps are used.
class _IdleMeasurement implements MeasureController {
  @override
  bool get isLive => false;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Native extends NativeGaze {
  Future<void> Function(String run)? onOpen;
  Future<void> Function(String run)? onClose;
  final opened = <String>[];
  final closed = <String>[];

  @override
  Future<void> open(String run) {
    opened.add(run);
    return onOpen?.call(run) ?? Future<void>.value();
  }

  @override
  Future<void> close(String run) {
    closed.add(run);
    return onClose?.call(run) ?? Future<void>.value();
  }
}

const _front = CameraDescription(
  name: 'synthetic-front',
  lensDirection: CameraLensDirection.front,
  sensorOrientation: 270,
);

class _Controller extends CameraController {
  _Controller({this.initializing, this.stopping})
    : super(_front, ResolutionPreset.low, enableAudio: false);

  final Completer<void>? initializing;
  final Completer<void>? stopping;
  int opens = 0;
  int stops = 0;
  int disposals = 0;

  @override
  Future<void> initialize() async {
    opens++;
    await initializing?.future;
    value = value.copyWith(isInitialized: true);
  }

  @override
  Future<void> startImageStream(onLatestImageAvailable onAvailable) async {
    value = value.copyWith(isStreamingImages: true);
  }

  @override
  Future<void> stopImageStream() async {
    stops++;
    await stopping?.future;
    value = value.copyWith(isStreamingImages: false);
  }

  @override
  // ignore: must_call_super
  Future<void> dispose() async {
    disposals++;
  }
}

CameraFrameSource _cameraSource(_Controller controller) => CameraFrameSource(
  listCameras: () async => <CameraDescription>[_front],
  controllerFactory:
      (camera, {required int fps, ImageFormatGroup? imageFormatGroup}) =>
          controller,
);

class _Handle implements SeatCameraHandle {
  _Handle(this.action);
  final Future<CloseResult> Function() action;
  int closes = 0;

  @override
  bool get isOpen => closes == 0;

  @override
  Future<CloseResult> close() {
    closes++;
    return action();
  }
}

class _Source implements SeatFrameSource {
  _Source(this.handle);
  final SeatCameraHandle handle;
  int opens = 0;

  @override
  Future<CameraProbeResult> probe() async => CameraProbeResult.ok;

  @override
  Future<SeatCameraHandle> open(
    SeatFrameSourceConfig config, {
    required SeatFrameCallback onFrame,
    required SeatFaultCallback onFault,
  }) async {
    opens++;
    return handle;
  }
}

Future<void> _mount(
  WidgetTester tester,
  ProviderContainer container,
  SeatFrameSource source,
  NativeGaze engine, {
  Key? screenKey,
}) async {
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        home: GazeLabScreen(key: screenKey, source: source, engine: engine),
      ),
    ),
  );
  await tester.pump();
}

Future<void> _consentAndStart(WidgetTester tester) async {
  await tester.tap(find.byType(CheckboxListTile));
  await tester.pump();
  await tester.tap(find.widgetWithText(FilledButton, GazeStrings.start));
  await tester.pump();
}

FilledButton _action(WidgetTester tester) =>
    tester.widget<FilledButton>(find.byType(FilledButton));

// Calling the actual button callback preserves its returned stop Future. This
// lets the tests observe completion/join semantics without private-state access.
Future<void> _invoke(VoidCallback callback) =>
    Function.apply(callback, const <Object?>[]) as Future<void>;

void main() {
  late CameraPermissionGateway previousPermission;
  late ProviderContainer container;
  setUp(() {
    previousPermission = CameraPermission.gateway;
    CameraPermission.gateway = FakeCameraPermissionGateway();
    container = ProviderContainer(
      overrides: [
        measureControllerProvider.overrideWithValue(_IdleMeasurement()),
      ],
    );
  });
  tearDown(() {
    CameraPermission.gateway = previousPermission;
    container.dispose();
  });

  testWidgets('normal stop closes camera/native once and allows a new run', (
    tester,
  ) async {
    final camera = _Controller();
    final native = _Native();
    final source = _cameraSource(camera);
    await _mount(tester, container, source, native);
    await _consentAndStart(tester);
    expect(native.opened, hasLength(1));
    expect(camera.opens, 1);

    final stop = _invoke(_action(tester).onPressed!);
    await tester.pump();
    await stop;
    expect(camera.stops, 1);
    expect(camera.disposals, 1);
    expect(native.closed, native.opened);
    expect(find.text(GazeStrings.releaseFailed), findsNothing);
    expect(_action(tester).onPressed, isNotNull);

    await tester.tap(find.widgetWithText(FilledButton, GazeStrings.start));
    await tester.pump();
    expect(native.opened, hasLength(2));
    expect(native.opened[0], isNot(native.opened[1]));
    expect(camera.opens, 2);
    final second = _invoke(_action(tester).onPressed!);
    await tester.pump();
    await second;
    expect(native.closed, native.opened);
    expect(camera.disposals, 2);
    await tester.pumpWidget(const SizedBox.shrink());
    expect(tester.takeException(), isNull);
  });

  testWidgets('stream stop has 2 s then native close has its own 2 s budget', (
    tester,
  ) async {
    final streamStop = Completer<void>();
    final nativeStop = Completer<void>();
    final camera = _Controller(stopping: streamStop);
    final native = _Native()..onClose = (_) => nativeStop.future;
    final source = _cameraSource(camera);
    await _mount(tester, container, source, native);
    await _consentAndStart(tester);
    var finished = false;
    final stop = _invoke(_action(tester).onPressed!);
    unawaited(
      stop.then((_) {
        finished = true;
      }),
    );
    await tester.pump();

    await tester.pump(const Duration(milliseconds: 1999));
    expect(camera.stops, 1);
    expect(camera.disposals, 0);
    expect(native.closed, isEmpty);
    expect(finished, isFalse);
    await tester.pump(const Duration(milliseconds: 1));
    expect(native.closed, hasLength(1));
    expect(finished, isFalse);
    expect(find.text(GazeStrings.releaseFailed), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 1999));
    expect(finished, isFalse);
    await tester.pump(const Duration(milliseconds: 1));
    await stop;
    expect(
      finished,
      isTrue,
      reason: 'the stop Future settles within 2 s + 2 s',
    );
    expect(_action(tester).onPressed, isNull);

    // A timeout never becomes a successful release when the OS answers late.
    streamStop.complete();
    nativeStop.complete();
    await tester.pump();
    expect(camera.disposals, 1);
    expect(native.closed, hasLength(1));
    expect(find.text(GazeStrings.releaseFailed), findsOneWidget);
    expect(_action(tester).onPressed, isNull);

    // Re-entering this dev route cannot bypass the failed-release latch.
    await _mount(
      tester,
      container,
      source,
      native,
      screenKey: const ValueKey('reentry'),
    );
    await tester.tap(find.byType(CheckboxListTile));
    await tester.pump();
    expect(_action(tester).onPressed, isNull);
    expect(native.opened, hasLength(1));
    expect(find.text(GazeStrings.releaseFailed), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
    expect(tester.takeException(), isNull);
  });

  testWidgets('camera close throwing still attempts native close', (
    tester,
  ) async {
    final handle = _Handle(() => throw StateError('synthetic close failure'));
    final native = _Native();
    await _mount(tester, container, _Source(handle), native);
    await _consentAndStart(tester);
    final stop = _invoke(_action(tester).onPressed!);
    await tester.pump();
    await stop;
    expect(handle.closes, 1);
    expect(native.closed, hasLength(1));
    expect(find.text(GazeStrings.releaseFailed), findsOneWidget);
    expect(_action(tester).onPressed, isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    expect(tester.takeException(), isNull);
  });

  testWidgets('failed camera CloseResult keeps the failure latch', (
    tester,
  ) async {
    final handle = _Handle(
      () async => CloseResult.failed(StateError('synthetic close failure')),
    );
    final native = _Native();
    await _mount(tester, container, _Source(handle), native);
    await _consentAndStart(tester);
    final stop = _invoke(_action(tester).onPressed!);
    await tester.pump();
    await stop;
    expect(handle.closes, 1);
    expect(native.closed, hasLength(1));
    expect(find.text(GazeStrings.releaseFailed), findsOneWidget);
    expect(_action(tester).onPressed, isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    expect(tester.takeException(), isNull);
  });

  for (final synchronous in <bool>[true, false]) {
    testWidgets('native close throw (sync=$synchronous) settles safely', (
      tester,
    ) async {
      final camera = _Controller();
      final native = _Native()
        ..onClose = synchronous
            ? (_) => throw StateError('synthetic native failure')
            : (_) => Future<void>.error(StateError('synthetic native failure'));
      await _mount(tester, container, _cameraSource(camera), native);
      await _consentAndStart(tester);
      final stop = _invoke(_action(tester).onPressed!);
      await tester.pump();
      await stop;
      expect(camera.disposals, 1);
      expect(native.closed, hasLength(1));
      expect(find.text(GazeStrings.releaseFailed), findsOneWidget);
      expect(_action(tester).onPressed, isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('native pending after clean camera release times out at 2 s', (
    tester,
  ) async {
    final nativeStop = Completer<void>();
    final camera = _Controller();
    final native = _Native()..onClose = (_) => nativeStop.future;
    await _mount(tester, container, _cameraSource(camera), native);
    await _consentAndStart(tester);
    var finished = false;
    final stop = _invoke(_action(tester).onPressed!);
    unawaited(
      stop.then((_) {
        finished = true;
      }),
    );
    await tester.pump();
    expect(camera.disposals, 1);
    expect(native.closed, hasLength(1));
    await tester.pump(const Duration(milliseconds: 1999));
    expect(finished, isFalse);
    await tester.pump(const Duration(milliseconds: 1));
    await stop;
    expect(finished, isTrue);
    expect(find.text(GazeStrings.releaseFailed), findsOneWidget);
    nativeStop.completeError(StateError('late synthetic native failure'));
    await tester.pump();
    expect(_action(tester).onPressed, isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    expect(tester.takeException(), isNull);
  });

  testWidgets('repeated stop, background, and dispose join the same close', (
    tester,
  ) async {
    final nativeStop = Completer<void>();
    final camera = _Controller();
    final native = _Native()..onClose = (_) => nativeStop.future;
    await _mount(tester, container, _cameraSource(camera), native);
    await _consentAndStart(tester);
    final callback = _action(tester).onPressed!;
    final first = _invoke(callback);
    final second = _invoke(callback);
    expect(identical(first, second), isTrue);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump();
    await tester.pumpWidget(const SizedBox.shrink());
    expect(camera.stops, 1);
    expect(native.closed, hasLength(1));
    nativeStop.complete();
    await tester.pump();
    await first;
    expect(camera.disposals, 1);
    expect(native.closed, hasLength(1));
    expect(tester.takeException(), isNull, reason: 'no setState after dispose');
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
  });

  testWidgets(
    'a late camera open is bounded and blocks another route acquisition',
    (tester) async {
      final opening = Completer<void>();
      final streamStop = Completer<void>();
      final firstCamera = _Controller(
        initializing: opening,
        stopping: streamStop,
      );
      final firstNative = _Native();
      await _mount(tester, container, _cameraSource(firstCamera), firstNative);
      await _consentAndStart(tester);
      expect(firstCamera.opens, 1);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      await tester.pump();
      expect(firstNative.closed, hasLength(1));
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);

      final nextCamera = _Controller();
      final nextNative = _Native();
      await _mount(
        tester,
        container,
        _cameraSource(nextCamera),
        nextNative,
        screenKey: const ValueKey('while-opening'),
      );
      await tester.tap(find.byType(CheckboxListTile));
      await tester.pump();
      expect(_action(tester).onPressed, isNull);
      expect(nextCamera.opens, 0);

      opening.complete();
      await tester.pump();
      expect(firstCamera.stops, 1);
      await tester.pump(const Duration(milliseconds: 1999));
      expect(_action(tester).onPressed, isNull);
      expect(nextCamera.opens, 0);
      await tester.pump(const Duration(milliseconds: 1));
      expect(find.text(GazeStrings.releaseFailed), findsOneWidget);
      expect(
        firstNative.closed,
        hasLength(1),
        reason: 'native cleanup is joined',
      );
      expect(nextCamera.opens, 0);
      streamStop.complete();
      await tester.pump();
      expect(firstCamera.disposals, 1);
      expect(
        _action(tester).onPressed,
        isNull,
        reason: 'late success is not reset',
      );
      await tester.pumpWidget(const SizedBox.shrink());
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('successful late-open cleanup releases the next route gate', (
    tester,
  ) async {
    final opening = Completer<void>();
    final oldCamera = _Controller(initializing: opening);
    final oldNative = _Native();
    await _mount(tester, container, _cameraSource(oldCamera), oldNative);
    await _consentAndStart(tester);
    expect(oldCamera.opens, 1);

    final nextCamera = _Controller();
    final nextNative = _Native();
    await _mount(
      tester,
      container,
      _cameraSource(nextCamera),
      nextNative,
      screenKey: const ValueKey('after-dispose'),
    );
    await tester.tap(find.byType(CheckboxListTile));
    await tester.pump();
    expect(_action(tester).onPressed, isNull);
    expect(nextCamera.opens, 0);
    opening.complete();
    await tester.pump();
    expect(oldCamera.stops, 1);
    expect(oldCamera.disposals, 1);
    expect(oldNative.closed, hasLength(1));
    expect(find.text(GazeStrings.releaseFailed), findsNothing);
    expect(_action(tester).onPressed, isNotNull);

    await tester.tap(find.widgetWithText(FilledButton, GazeStrings.start));
    await tester.pump();
    expect(nextCamera.opens, 1);
    expect(nextNative.opened, hasLength(1));
    expect(oldNative.closed, hasLength(1));
    final stop = _invoke(_action(tester).onPressed!);
    await tester.pump();
    await stop;
    await tester.pumpWidget(const SizedBox.shrink());
    expect(tester.takeException(), isNull);
  });

  testWidgets('late native open after dispose never acquires a camera', (
    tester,
  ) async {
    final opening = Completer<void>();
    final camera = _Controller();
    // Match the real bridge's serialized open/close ordering.
    final native = _Native();
    native.onOpen = (_) => opening.future;
    native.onClose = (_) => opening.future;
    await _mount(tester, container, _cameraSource(camera), native);
    await _consentAndStart(tester);
    expect(native.opened, hasLength(1));
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 2));
    expect(native.closed, hasLength(1));
    opening.complete();
    await tester.pump();
    expect(camera.opens, 0);
    expect(native.closed, hasLength(1));
    expect(tester.takeException(), isNull);
  });
}
