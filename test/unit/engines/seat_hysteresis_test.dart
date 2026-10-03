import 'package:flutter_test/flutter_test.dart';
import 'package:soongong/data/engines/seat/seat_hysteresis.dart';

Duration s(double seconds) => Duration(milliseconds: (seconds * 1000).round());

void main() {
  test('detected → seated; never detected → not seated', () {
    final h = SeatHysteresis();
    expect(h.observe(at: s(0), detected: false), isFalse);
    expect(h.observe(at: s(1), detected: true), isTrue);
    expect(h.lastDetectedAt, s(1));
  });

  test('a miss inside the 3 s hold window stays seated, after it does not', () {
    final h = SeatHysteresis();
    expect(h.observe(at: s(0), detected: true), isTrue);
    expect(h.observe(at: s(1), detected: false), isTrue);
    expect(h.observe(at: s(2), detected: false), isTrue);
    expect(h.observe(at: s(3), detected: false), isTrue); // inclusive
    expect(h.isHoldingAt(s(3)), isTrue);
    expect(h.observe(at: s(3.001), detected: false), isFalse);
    expect(h.isHoldingAt(s(3.001)), isFalse);
    expect(h.observe(at: s(4), detected: false), isFalse);
  });

  test('frame sequence → seated sequence (1 Hz, head-bowed blink of 2 s)', () {
    final h = SeatHysteresis();
    const frames = <bool>[true, true, false, false, true, false, false, false, false];
    final out = <bool>[
      for (var i = 0; i < frames.length; i++)
        h.observe(at: s(i.toDouble()), detected: frames[i]),
    ];
    // 2 s gap (t=2,3) is bridged; after t=4 the misses at 5,6,7 are held,
    // t=8 (4 s after the last detection) is not.
    expect(out, <bool>[true, true, true, true, true, true, true, true, false]);
  });

  test('custom hold and reset', () {
    final h = SeatHysteresis(hold: const Duration(seconds: 1));
    expect(h.observe(at: s(0), detected: true), isTrue);
    expect(h.observe(at: s(1), detected: false), isTrue);
    expect(h.observe(at: s(1.5), detected: false), isFalse);
    h.reset();
    expect(h.lastDetectedAt, isNull);
    expect(h.observe(at: s(1.6), detected: false), isFalse);
  });
}
