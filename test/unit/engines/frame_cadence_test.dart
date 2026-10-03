import 'package:flutter_test/flutter_test.dart';
import 'package:soongong/core/contracts/seat_engine.dart';
import 'package:soongong/data/engines/seat/frame_cadence.dart';

Duration ms(int v) => Duration(milliseconds: v);

void main() {
  test('intervalFor: 1 Hz default, 2 Hz max, lowPower = 2 s', () {
    expect(FrameCadence.intervalFor(const SeatEngineConfig()), ms(1000));
    expect(FrameCadence.intervalFor(const SeatEngineConfig(sampleHz: 2)), ms(500));
    expect(FrameCadence.intervalFor(const SeatEngineConfig(sampleHz: 5)), ms(500));
    expect(FrameCadence.intervalFor(const SeatEngineConfig(sampleHz: 0)), ms(1000));
    expect(
      FrameCadence.intervalFor(const SeatEngineConfig(sampleHz: 2, lowPower: true)),
      ms(2000),
    );
  });

  test('accepts at most one frame per interval; the rest are dropped', () {
    final c = FrameCadence(interval: ms(1000));
    final accepted = <int>[];
    for (var t = 0; t < 3000; t += 66) {
      if (c.accept(ms(t))) {
        accepted.add(t);
        c.release();
      }
    }
    expect(accepted, <int>[0, 1056, 2112]);
    expect(c.accepted, 3);
    expect(c.dropped, 46 - 3);
  });

  test('drops frames while a detection is in flight', () {
    final c = FrameCadence(interval: ms(1000));
    expect(c.accept(ms(0)), isTrue);
    expect(c.isBusy, isTrue);
    expect(c.accept(ms(1500)), isFalse); // due, but busy
    c.release();
    expect(c.accept(ms(1600)), isTrue);
    expect(c.dropped, 1);
  });

  test('reset clears timing and counters', () {
    final c = FrameCadence(interval: ms(1000));
    c.accept(ms(0));
    c.reset();
    expect(c.isBusy, isFalse);
    expect(c.accepted, 0);
    expect(c.accept(ms(10)), isTrue);
  });
}
