import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:soongong/core/contracts/seat_engine.dart';
import 'package:soongong/features/measure/application/measure_controller.dart';

class TestMeasureDevice implements MeasureDevice {
  bool awake = false;
  int level = 80;
  @override
  Future<void> keepAwake(bool enabled) async {
    awake = enabled;
  }

  @override
  Future<int?> batteryLevel() async => level;
}

class TestMeasureEngine implements SeatEngine {
  final sampleBus = StreamController<SeatSample>.broadcast(sync: true);
  final eventBus = StreamController<SeatEngineEvent>.broadcast(sync: true);
  SeatAvailability availability = SeatAvailability.ok;
  int starts = 0, stops = 0;
  SeatEngineConfig? config;
  bool failStart = false;
  Completer<void>? starting;
  @override
  Future<SeatAvailability> checkAvailability() async => availability;
  @override
  Future<void> start(SeatEngineConfig config) async {
    starts++;
    this.config = config;
    if (starting != null) await starting!.future;
    if (failStart) throw StateError('camera unavailable');
  }

  @override
  Future<void> stop() async {
    stops++;
  }

  @override
  Stream<SeatSample> get samples => sampleBus.stream;
  @override
  Stream<SeatEngineEvent> get events => eventBus.stream;
  @override
  Widget? previewOrNull() => null;
  void sample(int seconds, {required bool seated}) => sampleBus.add(
    SeatSample(
      receivedAt: DateTime.utc(2099),
      sinceStart: Duration(seconds: seconds),
      seated: seated,
    ),
  );
  Future<void> close() async {
    await sampleBus.close();
    await eventBus.close();
  }
}
