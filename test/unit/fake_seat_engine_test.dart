import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soongong/core/contracts/contracts.dart';
import 'package:soongong/core/contracts/fakes/fakes.dart';

void main() {
  test('availability follows the scenario', () async {
    expect(
      await FakeSeatEngine(scenario: FakeSeatScenario.permissionDenied)
          .checkAvailability(),
      SeatAvailability.permissionDenied,
    );
    expect(
      await FakeSeatEngine(scenario: FakeSeatScenario.cameraBusy)
          .checkAvailability(),
      SeatAvailability.cameraBusy,
    );
    expect(await FakeSeatEngine().checkAvailability(), SeatAvailability.ok);
  });

  test('awayAfter(3): seated for 2 samples, away from the 3rd', () {
    fakeAsync((async) {
      final e = FakeSeatEngine(
        scenario: FakeSeatScenario.awayAfter,
        afterSeconds: 3,
      );
      final seen = <bool>[];
      e.samples.listen((s) => seen.add(s.seated));
      e.start(const SeatEngineConfig());
      async.elapse(const Duration(seconds: 5));
      expect(seen, <bool>[true, true, false, false, false]);
      e.stop();
      async.elapse(const Duration(seconds: 3));
      expect(seen.length, 5);
      expect(e.previewOrNull(), isNull);
    });
  });

  test('lostAfter(2): CameraLost then CameraRecovered, no samples while lost',
      () {
    fakeAsync((async) {
      final e = FakeSeatEngine(
        scenario: FakeSeatScenario.lostAfter,
        afterSeconds: 2,
      );
      final events = <SeatEngineEvent>[];
      var samples = 0;
      e.events.listen(events.add);
      e.samples.listen((_) => samples++);
      e.start(const SeatEngineConfig());
      async.elapse(const Duration(seconds: 3));
      expect(events.single, isA<SeatCameraLost>());
      expect(samples, 1);
      async.elapse(const Duration(seconds: 10));
      expect(events.last, isA<SeatCameraRecovered>());
      e.stop();
    });
  });

  test('[S04d] lostAfter: sinceStart stays monotonic across Lost → Recovered', () {
    fakeAsync((async) {
      final e = FakeSeatEngine(
        scenario: FakeSeatScenario.lostAfter,
        afterSeconds: 2,
      );
      final sinceStart = <Duration>[];
      final events = <SeatEngineEvent>[];
      e.events.listen(events.add);
      e.samples.listen((s) => sinceStart.add(s.sinceStart));
      e.start(const SeatEngineConfig());
      async.elapse(const Duration(seconds: 13)); // the scenario would loop into a second loss at 14 s
      expect(events.map((x) => x.runtimeType).toList(), <Type>[SeatCameraLost, SeatCameraRecovered]);
      // 1 sample before the loss (t=1 s), then from the recovery tick on (t=12 s …).
      expect(sinceStart.first, const Duration(seconds: 1));
      expect(sinceStart[1], const Duration(seconds: 12), reason: 'the run\'s elapsed time, not the scenario counter');
      for (var i = 1; i < sinceStart.length; i++) {
        expect(sinceStart[i], greaterThan(sinceStart[i - 1]), reason: 'index $i');
      }
      e.stop();
    });
  });
}
