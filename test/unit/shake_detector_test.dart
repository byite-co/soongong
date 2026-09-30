import 'package:flutter_test/flutter_test.dart';
import 'package:soongong/core/dev/shake_detector.dart';

void main() {
  test('fires after two spikes inside the window, then cools down', () {
    var t = DateTime(2026, 1, 1, 12);
    final d = ShakeDetector(now: () => t);
    var fired = 0;
    d.onShake.listen((_) => fired++);

    expect(d.addSample(0, 9.8, 0), isFalse); // resting
    expect(d.addSample(30, 0, 0), isFalse); // 1st spike
    t = t.add(const Duration(milliseconds: 200));
    expect(d.addSample(0, 30, 0), isTrue); // 2nd spike → shake
    t = t.add(const Duration(milliseconds: 200));
    expect(d.addSample(0, 30, 0), isFalse); // cooldown
    t = t.add(const Duration(seconds: 2));
    expect(d.addSample(30, 0, 0), isFalse);
    t = t.add(const Duration(milliseconds: 100));
    expect(d.addSample(30, 0, 0), isTrue);
  });

  test('spikes outside the window do not accumulate', () {
    var t = DateTime(2026, 1, 1, 12);
    final d = ShakeDetector(now: () => t);
    expect(d.addSample(30, 0, 0), isFalse);
    t = t.add(const Duration(seconds: 2));
    expect(d.addSample(30, 0, 0), isFalse);
  });
}
