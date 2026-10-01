import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soongong/core/dev/seat_lab/seat_lab_recorder.dart';
import 'package:soongong/core/dev/seat_lab/seat_lab_screen.dart';
import 'package:soongong/core/domain/clock.dart';
import 'package:soongong/core/strings/seat_lab_strings.dart';
import 'package:soongong/data/engines/engines.dart';
import 'package:soongong/data/export/export_service.dart';

import '../helpers/fake_seat_sources.dart';
import '../helpers/pump_app.dart';

void main() {
  testWidgets('seat lab: start → seated from frames → hold → not seated → mark → csv → stop',
      (tester) async {
    final source = FakeSeatFrameSource();
    final detector = FakePresenceDetector();
    final gateway = FakeCameraPermissionGateway();
    final lifecycle = FakeLifecycleSource();
    final mono = FakeMonotonicClock();
    SeatEngineImpl? engine;
    final shared = <ExportFile>[];
    var minFaceSizeUsed = 0.0;

    await pumpThemed(
      tester,
      SeatLabScreen(
        engineBuilder: ({required double minFaceSize}) {
          minFaceSizeUsed = minFaceSize;
          return engine = SeatEngineImpl(
            source: source,
            detector: detector,
            permission: gateway,
            lifecycle: lifecycle,
            monotonic: mono,
            clock: FixedClock(DateTime.utc(2026, 10, 1)),
          );
        },
        batteryReader: () async => 80,
        share: (f) async => shared.add(f),
      ),
      surfaceSize: const Size(390, 2600),
    );
    expect(find.text(SeatLabStrings.title), findsOneWidget);
    expect(find.text(SeatLabStrings.stateIdle), findsOneWidget);
    expect(find.text(SeatLabStrings.eventNone), findsOneWidget);
    expect(engine, isNull, reason: 'engine is built lazily');

    // Case + truth marks before start.
    await tester.tap(find.text('P2 고개 숙임 필기'));
    await tester.pump();
    await tester.tap(find.text(SeatLabStrings.truthSeated));
    await tester.pump();

    await tester.tap(find.text(SeatLabStrings.start));
    await tester.pump();
    await tester.pump();
    expect(engine, isNotNull);
    expect(minFaceSizeUsed, MlKitFacePresenceDetector.defaultMinFaceSize);
    expect(engine!.isRunning, isTrue);
    expect(source.isOpen, isTrue);
    expect(find.text(SeatLabStrings.stop), findsOneWidget);
    expect(find.text(SeatLabStrings.noSampleYet), findsOneWidget);

    source.emit(present: true);
    await tester.pump();
    expect(find.text(SeatLabStrings.seated), findsOneWidget);

    mono.advance(const Duration(seconds: 2));
    source.emit(present: false);
    await tester.pump();
    expect(find.text(SeatLabStrings.seated), findsOneWidget, reason: 'held for 3 s');
    expect(find.textContaining('${SeatLabStrings.heldByWindow}: ${SeatLabStrings.yes}'), findsOneWidget);

    mono.advance(const Duration(seconds: 2));
    source.emit(present: false);
    await tester.pump();
    expect(find.text(SeatLabStrings.notSeated), findsOneWidget);

    await tester.tap(find.text(SeatLabStrings.truthAway));
    await tester.pump();

    // Camera lost → status + event log.
    source.fault(CameraFault.inUse, 'The camera was already in use');
    await tester.pump();
    expect(find.text(SeatLabStrings.stateLost), findsOneWidget);
    expect(find.textContaining(SeatLabStrings.eventCameraLost), findsOneWidget);
    expect(find.text(SeatLabStrings.eventNone), findsNothing);

    await tester.tap(find.byTooltip(SeatLabStrings.exportCsv));
    await tester.pump();
    expect(shared, hasLength(1));
    expect(shared.single.name, startsWith('seat_lab_'));
    expect(shared.single.mimeType, 'text/csv');
    final csv = String.fromCharCodes(shared.single.bytes);
    expect(csv, startsWith(SeatLabRecorder.csvHeader));
    expect(csv, contains(',sample,1,1,0,'));
    expect(csv, contains(',sample,0,1,1,'));
    expect(csv, contains(',sample,0,0,0,'));
    expect(csv, contains(',mark,,,,,away,,P2,away'));
    expect(csv, contains(',event,,,,,'));
    expect(csv, contains(',battery,,,,,seated,80,P2,'));
    expect(find.text(SeatLabStrings.exported), findsOneWidget);
    await tester.pump(const Duration(seconds: 4)); // toast auto-hides
    expect(find.text(SeatLabStrings.exported), findsNothing);

    // Settings are locked while running.
    await tester.tap(find.text('0.20'));
    await tester.pump();
    expect(minFaceSizeUsed, MlKitFacePresenceDetector.defaultMinFaceSize);

    await tester.tap(find.text(SeatLabStrings.stop));
    await tester.pump();
    await tester.pump();
    expect(engine!.isRunning, isFalse);
    expect(source.isOpen, isFalse);
    expect(find.text(SeatLabStrings.start), findsOneWidget);
    expect(find.text(SeatLabStrings.stateIdle), findsOneWidget);

    // Now the detector size can change; the engine is rebuilt on next start.
    await tester.tap(find.text('0.20'));
    await tester.pump();
    final previous = engine;
    await tester.tap(find.text(SeatLabStrings.start));
    await tester.pump();
    await tester.pump();
    expect(minFaceSizeUsed, 0.2);
    expect(identical(engine, previous), isFalse);
    await tester.tap(find.text(SeatLabStrings.stop));
    await tester.pump();
    await tester.pump();

    await tester.pumpWidget(const SizedBox());
    await tester.pump();
    expect(tester.takeException(), isNull);
  });

  testWidgets('seat lab: a start failure stays idle and logs the error', (tester) async {
    final source = FakeSeatFrameSource()
      ..openError = const SeatFrameSourceException('camera_busy');
    await pumpThemed(
      tester,
      SeatLabScreen(
        engineBuilder: ({required double minFaceSize}) => SeatEngineImpl(
          source: source,
          detector: FakePresenceDetector(),
          permission: FakeCameraPermissionGateway(),
        ),
        batteryReader: () async => null,
        share: (_) async {},
      ),
      surfaceSize: const Size(390, 2600),
    );
    await tester.tap(find.text(SeatLabStrings.start));
    await tester.pump();
    await tester.pump();
    expect(find.text(SeatLabStrings.stateIdle), findsOneWidget);
    expect(find.textContaining('error: camera_busy'), findsOneWidget);
    expect(find.text(SeatLabStrings.batteryUnknown), findsOneWidget);

    await tester.tap(find.text(SeatLabStrings.checkAvailability));
    await tester.pump();
    expect(find.textContaining('${SeatLabStrings.availabilityLabel}: ok'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });
}
