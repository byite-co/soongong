// SeatEngine contract (S01). Signatures are frozen — changes require the
// CONTRACT-CHANGE procedure (CLAUDE.md §8).
//
// The camera never looks at the face: only a seated boolean is produced
// on-device; frames are never stored or transmitted (CLAUDE.md §1 · §9).

import 'package:flutter/widgets.dart';

class SeatSample {
  const SeatSample({required this.at, required this.seated, this.confidence});

  final DateTime at;
  final bool seated;
  final double? confidence;
}

enum SeatAvailability { ok, permissionDenied, cameraBusy, unavailable }

class SeatEngineConfig {
  const SeatEngineConfig({this.sampleHz = 1, this.lowPower = false});

  /// Samples per second (PRD §8: 1 Hz).
  final int sampleHz;
  final bool lowPower;
}

/// Engine events. `cameraLost` / `cameraRecovered` map to `paused`, never to
/// an away segment (D23).
sealed class SeatEngineEvent {
  const SeatEngineEvent();
}

class SeatCameraLost extends SeatEngineEvent {
  const SeatCameraLost();
}

class SeatCameraRecovered extends SeatEngineEvent {
  const SeatCameraRecovered();
}

class SeatError extends SeatEngineEvent {
  const SeatError(this.message);

  final String message;
}

abstract class SeatEngine {
  Future<SeatAvailability> checkAvailability();
  Future<void> start(SeatEngineConfig config);
  Future<void> stop();

  /// 1-second cadence, seated boolean only.
  Stream<SeatSample> get samples;

  /// cameraLost, cameraRecovered, error(msg).
  Stream<SeatEngineEvent> get events;

  /// Preview widget when one is needed (default null; frames are not stored).
  Widget? previewOrNull();
}
