import 'dart:convert';

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

/// Screen + doubles sharing one fake monotonic clock.
class LabRig {
  LabRig({this.openError});

  final SeatFrameSourceException? openError;
  late final FakeSeatFrameSource source = FakeSeatFrameSource(openError: openError);
  final FakePresenceDetector detector = FakePresenceDetector();
  final FakeCameraPermissionGateway gateway = FakeCameraPermissionGateway();
  final FakeLifecycleSource lifecycle = FakeLifecycleSource();
  final FakeMonotonicClock mono = FakeMonotonicClock();
  final List<ExportFile> shared = <ExportFile>[];
  SeatEngineImpl? engine;
  double minFaceSizeUsed = 0;
  MonotonicClock? monotonicUsed;

  Widget screen({int? battery = 80}) => SeatLabScreen(
        monotonic: mono,
        engineBuilder: ({required double minFaceSize, required MonotonicClock monotonic}) {
          minFaceSizeUsed = minFaceSize;
          monotonicUsed = monotonic;
          return engine = SeatEngineImpl(
            source: source,
            detector: detector,
            permission: gateway,
            lifecycle: lifecycle,
            monotonic: monotonic,
            clock: FixedClock(DateTime.utc(2026, 10, 1)),
          );
        },
        batteryReader: () async => battery,
        share: (f) async => shared.add(f),
      );

  String get csv => utf8.decode(shared.last.bytes);
}

Future<void> _tapStart(WidgetTester tester) async {
  await tester.tap(find.text(SeatLabStrings.start));
  await tester.pump();
  await tester.pump();
}

Future<void> _tapStop(WidgetTester tester) async {
  await tester.tap(find.text(SeatLabStrings.stop));
  await tester.pump();
  await tester.pump();
}

void main() {
  testWidgets('seat lab: start → seated → hold → not seated → mark → csv → stop → minFaceSize rebuild',
      (tester) async {
    final r = LabRig();
    await pumpThemed(tester, r.screen(), surfaceSize: const Size(390, 2800));
    expect(find.text(SeatLabStrings.title), findsOneWidget);
    expect(find.text(SeatLabStrings.stateIdle), findsOneWidget);
    expect(find.text(SeatLabStrings.eventNone), findsOneWidget);
    expect(r.engine, isNull, reason: 'engine is built lazily');

    // Case + truth marks before start (outside any segment).
    await tester.tap(find.text('P2 고개 숙임 필기'));
    await tester.pump();
    await tester.tap(find.text(SeatLabStrings.truthSeated));
    await tester.pump();

    r.mono.advance(const Duration(seconds: 1));
    await _tapStart(tester);
    expect(r.engine, isNotNull);
    expect(identical(r.monotonicUsed, r.mono), isTrue, reason: 'one time base for lab and engine');
    expect(r.minFaceSizeUsed, MlKitFacePresenceDetector.defaultMinFaceSize);
    expect(r.engine!.isRunning, isTrue);
    expect(r.source.isOpen, isTrue);
    expect(find.text(SeatLabStrings.stop), findsOneWidget);
    expect(find.text(SeatLabStrings.noSampleYet), findsOneWidget);

    r.mono.advance(const Duration(seconds: 1)); // t = 2 s
    r.source.emit(present: true);
    await tester.pump();
    expect(find.text(SeatLabStrings.seated), findsOneWidget);

    r.mono.advance(const Duration(seconds: 2)); // t = 4 s
    r.source.emit(present: false);
    await tester.pump();
    expect(find.text(SeatLabStrings.seated), findsOneWidget, reason: 'held for 3 s');
    expect(find.textContaining('${SeatLabStrings.heldByWindow}: ${SeatLabStrings.yes}'), findsOneWidget);

    r.mono.advance(const Duration(seconds: 2)); // t = 6 s
    r.source.emit(present: false);
    await tester.pump();
    expect(find.text(SeatLabStrings.notSeated), findsOneWidget);

    await tester.tap(find.text(SeatLabStrings.truthAway));
    await tester.pump();

    // Camera lost → status + event log.
    r.source.fault(CameraFault.inUse, 'The camera was already in use');
    await tester.pump();
    expect(find.text(SeatLabStrings.stateLost), findsOneWidget);
    expect(find.textContaining(SeatLabStrings.eventCameraLost), findsOneWidget);
    expect(find.text(SeatLabStrings.eventNone), findsNothing);

    await tester.tap(find.byTooltip(SeatLabStrings.exportCsv));
    await tester.pump();
    expect(r.shared, hasLength(1));
    expect(r.shared.single.name, startsWith('seat_lab_'));
    expect(r.shared.single.mimeType, 'text/csv');
    final csv = r.csv;
    expect(csv, startsWith(SeatLabRecorder.csvHeader));
    // capture time = completion time with the instant fake detector → latency 0
    expect(csv, contains('\n2000,sample,1,0,1,1,0,2000,0,seated,,P2,\n'));
    expect(csv, contains('\n4000,sample,1,0,0,1,1,4000,0,seated,,P2,\n'));
    expect(csv, contains('\n6000,sample,1,0,0,0,0,6000,0,seated,,P2,\n'));
    expect(csv, contains(',mark,1,0,,,,,,away,,P2,away'));
    expect(csv, contains(',event,1,0,,,,,,seated,,P2,start'));
    expect(csv, contains(',battery,1,0,,,,,,seated,80,P2,'));
    expect(find.text(SeatLabStrings.exported), findsOneWidget);
    await tester.pump(const Duration(seconds: 4)); // toast auto-hides
    expect(find.text(SeatLabStrings.exported), findsNothing);

    // Settings are locked while running.
    await tester.tap(find.text('0.20'));
    await tester.pump();
    expect(r.minFaceSizeUsed, MlKitFacePresenceDetector.defaultMinFaceSize);

    // Stop while the camera is lost → the segment is excluded.
    await _tapStop(tester);
    expect(r.engine!.isRunning, isFalse);
    expect(r.source.isOpen, isFalse);
    expect(find.text(SeatLabStrings.start), findsOneWidget);
    expect(find.text(SeatLabStrings.stateIdle), findsOneWidget);
    expect(find.text('1 (1)'), findsOneWidget, reason: '구간 1, 제외 1');
    expect(
      find.text('${SeatLabStrings.segmentAbnormal} · ${SeatLabStrings.reasonLost}'),
      findsOneWidget,
    );

    // Now the detector size can change; the engine is rebuilt on next start.
    await tester.tap(find.text('0.20'));
    await tester.pump();
    final previous = r.engine;
    await _tapStart(tester);
    expect(r.minFaceSizeUsed, 0.2);
    expect(identical(r.engine, previous), isFalse);
    r.mono.advance(const Duration(seconds: 1));
    r.source.emit(present: true);
    await tester.pump();
    await _tapStop(tester);
    expect(find.text('2 (1)'), findsOneWidget, reason: 'second segment ended normally');
    expect(find.text(SeatLabStrings.segmentNormal), findsOneWidget);

    await tester.tap(find.byTooltip(SeatLabStrings.exportCsv));
    await tester.pump();
    expect(r.csv, contains(',event,1,1,,,,,,away,,P2,stop · abnormal · ${SeatLabStrings.reasonLost}'));
    expect(r.csv, contains(',event,2,0,,,,,,away,,P2,stop · normal'));
    expect(r.csv, contains(',sample,1,1,1,1,0,'), reason: 'excluded samples stay in the CSV');
    await tester.pump(const Duration(seconds: 4));

    await tester.pumpWidget(const SizedBox());
    await tester.pump();
    expect(tester.takeException(), isNull);
  });

  testWidgets('seat lab: background stop → segment excluded with its reason, lab back to idle',
      (tester) async {
    final r = LabRig();
    await pumpThemed(tester, r.screen(), surfaceSize: const Size(390, 2800));
    await _tapStart(tester);
    r.mono.advance(const Duration(seconds: 1));
    r.source.emit(present: true);
    await tester.pump();
    expect(find.text(SeatLabStrings.seated), findsOneWidget);

    r.lifecycle.add(AppLifecycleState.hidden);
    await tester.pump();
    await tester.pump();
    expect(r.engine!.isRunning, isFalse);
    expect(r.engine!.lastStopReason, SeatEngineStopReason.background);
    expect(find.text(SeatLabStrings.stateIdle), findsOneWidget);
    expect(find.text(SeatLabStrings.start), findsOneWidget);
    expect(find.text('1 (1)'), findsOneWidget);
    expect(
      find.text('${SeatLabStrings.segmentAbnormal} · ${SeatLabStrings.reasonBackground}'),
      findsOneWidget,
    );
    expect(find.textContaining(SeatLabStrings.eventSelfStopped), findsOneWidget);
    expect(find.textContaining(SeatLabStrings.eventCameraLost), findsOneWidget);

    await tester.tap(find.byTooltip(SeatLabStrings.exportCsv));
    await tester.pump();
    expect(r.csv, contains('stop · abnormal · ${SeatLabStrings.reasonBackground}'));
    expect(r.csv, contains(',sample,1,1,1,1,0,'));
    await tester.pump(const Duration(seconds: 4));
    await tester.pumpWidget(const SizedBox());
    expect(tester.takeException(), isNull);
  });

  testWidgets('seat lab: a start failure stays idle, logs the error and excludes the segment',
      (tester) async {
    final r = LabRig(openError: const SeatFrameSourceException('camera_busy'));
    await pumpThemed(tester, r.screen(battery: null), surfaceSize: const Size(390, 2800));
    await _tapStart(tester);
    expect(find.text(SeatLabStrings.stateIdle), findsOneWidget);
    expect(find.textContaining('error: camera_busy'), findsOneWidget);
    expect(find.text(SeatLabStrings.batteryUnknown), findsOneWidget);
    expect(find.text('1 (1)'), findsOneWidget);

    await tester.tap(find.text(SeatLabStrings.checkAvailability));
    await tester.pump();
    expect(find.textContaining('${SeatLabStrings.availabilityLabel}: ok'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });
}
