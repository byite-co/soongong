// SeatEngine contract (S01). Signatures are frozen — changes require the
// CONTRACT-CHANGE procedure (CLAUDE.md §8).
//
// CONTRACT-CHANGE [S04c] (approved before S06 started, decisions [S04c]):
//   * `SeatSample.at` → `receivedAt` (wall clock, informational) +
//     `sinceStart` (monotonic elapsed since the engine's `start()`). Callers
//     place samples with `sinceStart` only: one session reference instant
//     (the wall clock at the run's start) + a monotonic offset, so a device
//     clock change never moves a sample or an away threshold.
//   * `SeatPaused` event: the app left the foreground (also while `start()`
//     was still opening the camera); the engine stopped itself. Like
//     `cameraLost` it maps to `paused`, never to an away segment (D23).
//
// The camera never looks at the face: only a seated boolean is produced
// on-device; frames are never stored or transmitted (CLAUDE.md §1 · §9).

import 'package:flutter/widgets.dart';

class SeatSample {
  const SeatSample({
    required this.receivedAt,
    required this.sinceStart,
    required this.seated,
    this.confidence,
  });

  /// Wall-clock instant the frame was received from the camera.
  /// Informational (logs, CSV) — not for placing the sample in time.
  final DateTime receivedAt;

  /// Monotonic elapsed time since the engine's `start()` that produced this
  /// run (Stopwatch based). Strictly increasing inside a run; resets to zero
  /// on every `start()`.
  final Duration sinceStart;

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

/// Engine events. `cameraLost` / `cameraRecovered` / `paused` map to
/// `paused`, never to an away segment (D23).
sealed class SeatEngineEvent {
  const SeatEngineEvent();
}

class SeatCameraLost extends SeatEngineEvent {
  const SeatCameraLost();
}

class SeatCameraRecovered extends SeatEngineEvent {
  const SeatCameraRecovered();
}

/// Why the engine paused itself ([SeatPaused]).
enum SeatPauseReason {
  /// The app left the foreground while running.
  background,

  /// The app left the foreground while `start()` was still opening the
  /// camera; the camera was released again and the run never began.
  backgroundDuringStart,
}

/// [S04c] The engine stopped itself because the app is not in the
/// foreground. Restarting on resume is the caller's job; the first frame of
/// the next run emits [SeatCameraRecovered].
class SeatPaused extends SeatEngineEvent {
  const SeatPaused(this.reason);

  final SeatPauseReason reason;
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

  /// cameraLost, cameraRecovered, paused, error(msg).
  Stream<SeatEngineEvent> get events;

  /// Preview widget when one is needed (default null; frames are not stored).
  Widget? previewOrNull();
}
