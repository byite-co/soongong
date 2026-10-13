import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soongong/core/contracts/providers.dart';
import 'package:soongong/core/dev/gaze_lab_screen.dart';
import 'package:soongong/core/domain/clock.dart';
import 'package:soongong/core/domain/enums.dart';
import 'package:soongong/core/strings/gaze_strings.dart';
import 'package:soongong/data/auth/auth_mode.dart';
import 'package:soongong/data/engines/engines.dart';
import 'package:soongong/data/engines/gaze/native_gaze.dart';
import 'package:soongong/data/engines/seat/camera_lease.dart';
import 'package:soongong/features/measure/application/measure_controller.dart';

import '../helpers/app_harness.dart';
import '../helpers/fake_seat_sources.dart';
import '../helpers/measure_fakes.dart';
import '../helpers/study_race_harness.dart' show completeStudy, pumpStudy;

const _front = CameraDescription(
  name: 'front',
  lensDirection: CameraLensDirection.front,
  sensorOrientation: 270,
);
const _config = SeatFrameSourceConfig(lowPower: false);

class _Controller extends CameraController {
  _Controller({this.initializing, this.stopping, this.disposing})
    : super(_front, ResolutionPreset.low, enableAudio: false);
  final Completer<void>? initializing;
  final Completer<void>? stopping;
  final Completer<void>? disposing;
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
    await disposing?.future;
  }
}

CameraFrameSource _source(CameraLease lease, _Controller Function() factory) =>
    CameraFrameSource(
      lease: lease,
      listCameras: () async => [_front],
      controllerFactory:
          (_, {required int fps, ImageFormatGroup? imageFormatGroup}) =>
              factory(),
      probeWindow: Duration.zero,
    );

Future<SeatCameraHandle> _open(SeatFrameSource source) =>
    source.open(_config, onFrame: (_) {}, onFault: (_, _) {});
Matcher get _busy => isA<SeatFrameSourceException>().having(
  (e) => e.code,
  'code',
  'camera_busy',
);

class _Native extends NativeGaze {
  int opens = 0;
  int closes = 0;
  @override
  Future<void> open(String sessionId) async {
    opens++;
  }

  @override
  Future<void> close(String sessionId) async {
    closes++;
  }
}

void main() {
  testWidgets(
    'RC05-GAZE02 two sources serialize pending open and normal release',
    (tester) async {
      final lease = CameraLease();
      final initializing = Completer<void>();
      final a = _Controller(initializing: initializing);
      final b = _Controller();
      final sourceA = _source(lease, () => a);
      final sourceB = _source(lease, () => b);
      final opening = _open(sourceA);
      await tester.pump();
      expect(a.opens, 1);
      await expectLater(_open(sourceB), throwsA(_busy));
      expect(b.opens, 0);
      expect(await sourceB.probe(), CameraProbeResult.busy);
      initializing.complete();
      final handle = await opening;
      expect((await handle.close()).isOk, isTrue);
      final next = await _open(sourceB);
      expect(b.opens, 1);
      await next.close();
    },
  );

  testWidgets(
    'RC05-GAZE02 repeated close joins while other source remains excluded',
    (tester) async {
      final lease = CameraLease();
      final stopping = Completer<void>();
      final a = _Controller(stopping: stopping);
      final b = _Controller();
      final handle = await _open(_source(lease, () => a));
      final closing = handle.close();
      expect(handle.close(), same(closing));
      await tester.pump();
      await expectLater(_open(_source(lease, () => b)), throwsA(_busy));
      expect(b.opens, 0);
      stopping.complete();
      expect((await closing).isOk, isTrue);
      expect(a.stops, 1);
      expect(a.disposals, 1);
      final next = await _open(_source(lease, () => b));
      await next.close();
    },
  );

  for (final stage in ['stream stop', 'dispose']) {
    testWidgets(
      'RC05-GAZE02 $stage timeout stays closed to new owners after late completion',
      (tester) async {
        final lease = CameraLease();
        final pending = Completer<void>();
        final a = _Controller(
          stopping: stage == 'stream stop' ? pending : null,
          disposing: stage == 'dispose' ? pending : null,
        );
        final b = _Controller();
        final handle = await _open(_source(lease, () => a));
        final closing = handle.close();
        await tester.pump(const Duration(seconds: 2));
        expect((await closing).outcome, CloseOutcome.timeout);
        await expectLater(_open(_source(lease, () => b)), throwsA(_busy));
        pending.complete();
        await tester.pump();
        expect((await handle.close()).outcome, CloseOutcome.timeout);
        await expectLater(_open(_source(lease, () => b)), throwsA(_busy));
        expect(b.opens, 0);
        expect(a.disposals, 1);
      },
    );
  }

  testWidgets(
    'RC05-GAZE02 timed-out initialize cannot reopen lease on late completion',
    (tester) async {
      final lease = CameraLease();
      final pending = Completer<void>();
      final a = _Controller(initializing: pending);
      final b = _Controller();
      final failed = expectLater(
        _open(_source(lease, () => a)),
        throwsA(isA<SeatFrameSourceException>()),
      );
      await tester.pump();
      await tester.pump(const Duration(seconds: 8));
      await failed;
      pending.complete();
      await tester.pump();
      await expectLater(_open(_source(lease, () => b)), throwsA(_busy));
      expect(a.disposals, 1);
      expect(b.opens, 0);
    },
  );

  testWidgets(
    'RC05-GAZE02 probe release failure blocks future measurement camera',
    (tester) async {
      final lease = CameraLease();
      final pending = Completer<void>();
      final a = _Controller(disposing: pending);
      final b = _Controller();
      final probe = _source(lease, () => a).probe();
      await tester.pump();
      await tester.pump();
      await tester.pump(const Duration(seconds: 2));
      expect(await probe, CameraProbeResult.failed);
      pending.complete();
      await tester.pump();
      await expectLater(_open(_source(lease, () => b)), throwsA(_busy));
      expect(b.opens, 0);
    },
  );

  testWidgets(
    'RC05-GAZE02 gaze and actual measurement share camera; blocked start adds no seated time',
    (tester) async {
      final lease = CameraLease();
      final gazeCamera = _Controller();
      final measurementCameras = <_Controller>[];
      final measureSource = _source(lease, () {
        final camera = _Controller();
        measurementCameras.add(camera);
        return camera;
      });
      final engine = SeatEngineImpl(
        source: measureSource,
        detectorFactory: () => FakePresenceDetector(),
        permission: FakeCameraPermissionGateway(),
        lifecycle: FakeLifecycleSource(),
      );
      final samples = <Object>[];
      final sub = engine.samples.listen(samples.add);
      final previous = CameraPermission.gateway;
      CameraPermission.gateway = FakeCameraPermissionGateway();
      final h = AppHarness(
        mode: AuthMode.localOnly,
        extraOverrides: [
          seatEngineProvider.overrideWithValue(engine),
          measureDeviceProvider.overrideWithValue(TestMeasureDevice()),
          sleepAwareClockProvider.overrideWithValue(FakeSleepAwareClock()),
        ],
      );
      addTearDown(() async {
        CameraPermission.gateway = previous;
        await sub.cancel();
        await h.dispose();
        await engine.dispose();
      });
      final native = _Native();
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: h.container,
          child: MaterialApp(
            home: GazeLabScreen(
              source: _source(lease, () => gazeCamera),
              engine: native,
            ),
          ),
        ),
      );
      await tester.tap(find.byType(CheckboxListTile));
      await tester.pump();
      await tester.tap(find.widgetWithText(FilledButton, GazeStrings.start));
      await pumpStudy(tester);
      expect(gazeCamera.opens, 1);
      final measure = h.container.read(measureControllerProvider);
      await completeStudy(tester, measure.start(mode: SessionMode.camera));
      expect(measurementCameras, isEmpty);
      expect(measure.cameraLost, isTrue);
      expect(measure.paused, isTrue);
      expect(measure.seated, Duration.zero);
      expect(samples, isEmpty);
      expect(gazeCamera.disposals, 0);
      await tester.tap(find.widgetWithText(FilledButton, GazeStrings.stop));
      await pumpStudy(tester);
      expect(gazeCamera.disposals, 1);
      expect(native.closes, 1);
      await completeStudy(tester, measure.resume());
      expect(
        measurementCameras,
        hasLength(2),
        reason: 'one probe then one measurement session',
      );
      expect(measure.cameraLost, isFalse);
      expect(measure.seated, Duration.zero);
      // Actual measurement already owns the resource: gaze start cannot touch it.
      await tester.tap(find.widgetWithText(FilledButton, GazeStrings.start));
      await pumpStudy(tester);
      expect(gazeCamera.opens, 1);
      expect(measurementCameras.last.disposals, 0);
      expect(samples, isEmpty);
      await completeStudy(tester, measure.finish());
      await tester.pumpWidget(const SizedBox.shrink());
      expect(tester.takeException(), isNull);
    },
  );
}
