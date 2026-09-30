// Fake SeatEngine (S01). Scenario is chosen in the dev menu.

import 'dart:async';

import 'package:flutter/widgets.dart';

import '../seat_engine.dart';

enum FakeSeatScenario {
  alwaysSeated,
  awayAfter,
  lostAfter,
  permissionDenied,
  cameraBusy,
}

class FakeSeatEngine implements SeatEngine {
  FakeSeatEngine({
    this.scenario = FakeSeatScenario.alwaysSeated,
    this.afterSeconds = 10,
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now;

  FakeSeatScenario scenario;

  /// Seconds before the `awayAfter` / `lostAfter` scenario triggers.
  int afterSeconds;

  final DateTime Function() _now;
  final StreamController<SeatSample> _samples =
      StreamController<SeatSample>.broadcast();
  final StreamController<SeatEngineEvent> _events =
      StreamController<SeatEngineEvent>.broadcast();

  Timer? _timer;
  int _tick = 0;
  bool _running = false;
  bool _lost = false;

  bool get isRunning => _running;

  @override
  Future<SeatAvailability> checkAvailability() async => switch (scenario) {
        FakeSeatScenario.permissionDenied => SeatAvailability.permissionDenied,
        FakeSeatScenario.cameraBusy => SeatAvailability.cameraBusy,
        _ => SeatAvailability.ok,
      };

  @override
  Future<void> start(SeatEngineConfig config) async {
    if (_running) return;
    _running = true;
    _tick = 0;
    _lost = false;
    final hz = config.sampleHz <= 0 ? 1 : config.sampleHz;
    _timer = Timer.periodic(
      Duration(milliseconds: 1000 ~/ hz),
      (_) => _onTick(),
    );
  }

  void _onTick() {
    _tick++;
    final seconds = _tick;
    switch (scenario) {
      case FakeSeatScenario.lostAfter:
        if (!_lost && seconds >= afterSeconds) {
          _lost = true;
          _events.add(const SeatCameraLost());
        } else if (_lost && seconds >= afterSeconds + 10) {
          _lost = false;
          _events.add(const SeatCameraRecovered());
          _tick = 0;
        }
        if (!_lost) {
          _samples.add(SeatSample(at: _now(), seated: true, confidence: 0.96));
        }
      case FakeSeatScenario.awayAfter:
        final seated = seconds < afterSeconds;
        _samples.add(
          SeatSample(at: _now(), seated: seated, confidence: seated ? 0.95 : 0.1),
        );
      case FakeSeatScenario.alwaysSeated:
      case FakeSeatScenario.permissionDenied:
      case FakeSeatScenario.cameraBusy:
        _samples.add(SeatSample(at: _now(), seated: true, confidence: 0.97));
    }
  }

  @override
  Future<void> stop() async {
    _timer?.cancel();
    _timer = null;
    _running = false;
  }

  @override
  Stream<SeatSample> get samples => _samples.stream;

  @override
  Stream<SeatEngineEvent> get events => _events.stream;

  @override
  Widget? previewOrNull() => null;

  Future<void> dispose() async {
    await stop();
    await _samples.close();
    await _events.close();
  }
}
