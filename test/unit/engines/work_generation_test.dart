import 'package:flutter_test/flutter_test.dart';
import 'package:soongong/data/engines/seat/work_generation.dart';

void main() {
  test('WorkGeneration: bump invalidates earlier generations', () {
    final g = WorkGeneration();
    final first = g.current;
    expect(g.isCurrent(first), isTrue);
    expect(g.bump(), first + 1);
    expect(g.isCurrent(first), isFalse);
    expect(g.isCurrent(first + 1), isTrue);
  });

  test('gate: closed until open(); a normal detection passes and frees the gate', () {
    final gate = InferenceGate();
    expect(gate.isOpen, isFalse);
    expect(gate.begin(), isNull, reason: 'nothing runs before start()');
    final gen = gate.open();
    final f = gate.begin();
    expect(f, gen);
    expect(gate.inFlight, isTrue);
    expect(gate.begin(), isNull, reason: 'one detection at a time');
    expect(gate.end(f!), isTrue);
    expect(gate.inFlight, isFalse);
    expect(gate.suppressed, 0);
  });

  test('gate: cancel() while in flight → the late result is suppressed, later frames post nothing', () {
    final gate = InferenceGate()..open();
    final f = gate.begin()!;
    expect(gate.cancel(), isTrue);
    expect(gate.isOpen, isFalse);
    expect(gate.end(f), isFalse);
    expect(gate.suppressed, 1);
    expect(gate.begin(), isNull);
    expect(gate.cancel(), isFalse, reason: 'nothing in flight any more');
  });

  test('gate: a result from the previous run never applies to the next one', () {
    final gate = InferenceGate()..open();
    final old = gate.begin()!;
    gate.cancel(); // stop()
    final next = gate.open(); // start()
    expect(next, greaterThan(old));
    // The old detection returns after the restart.
    expect(gate.end(old), isFalse);
    expect(gate.suppressed, 1);
    // New frames run on the new generation.
    final f = gate.begin()!;
    expect(f, next);
    expect(gate.end(f), isTrue);
  });
}
