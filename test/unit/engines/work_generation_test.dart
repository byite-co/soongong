import 'package:flutter_test/flutter_test.dart';
import 'package:soongong/data/engines/seat/work_generation.dart';

Duration ms(int v) => Duration(milliseconds: v);

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
    expect(gate.begin(ms(0)), isNull, reason: 'nothing runs before start()');
    final gen = gate.open();
    final t = gate.begin(ms(0));
    expect(t, isNotNull);
    expect(t!.generation, gen);
    expect(gate.inFlight, isTrue);
    expect(gate.begin(ms(10)), isNull, reason: 'one detection at a time');
    expect(gate.end(t), isTrue);
    expect(gate.inFlight, isFalse);
    expect(gate.suppressed, 0);
  });

  test('gate: cancel() while in flight → the late result is suppressed, later frames post nothing', () {
    final gate = InferenceGate()..open();
    final t = gate.begin(ms(0))!;
    expect(gate.cancel(), isTrue);
    expect(gate.isOpen, isFalse);
    expect(gate.inFlight, isFalse);
    expect(gate.end(t), isFalse);
    expect(gate.suppressed, 1);
    expect(gate.begin(ms(1)), isNull);
    expect(gate.cancel(), isFalse, reason: 'nothing in flight any more');
  });

  test('gate: a result from the previous run never applies to the next one', () {
    final gate = InferenceGate()..open();
    final old = gate.begin(ms(0))!;
    gate.cancel(); // stop()
    final next = gate.open(); // start()
    expect(next, greaterThan(old.generation));
    expect(gate.end(old), isFalse);
    expect(gate.suppressed, 1);
    final t = gate.begin(ms(5))!;
    expect(t.generation, next);
    expect(gate.end(t), isTrue);
  });

  test('gate: invalidate() (camera lost) drops the detection in flight but keeps the run open', () {
    final gate = InferenceGate()..open();
    final t = gate.begin(ms(0))!;
    expect(gate.invalidate(), isTrue);
    expect(gate.isOpen, isTrue);
    expect(gate.inFlight, isFalse, reason: 'the slot is free for the next frame');
    expect(gate.end(t), isFalse);
    expect(gate.suppressed, 1);
    final t2 = gate.begin(ms(100))!;
    expect(t2.generation, t.generation);
    expect(t2.epoch, t.epoch + 1);
    expect(gate.end(t2), isTrue);
    expect(gate.invalidate(), isFalse);
  });

  test('gate: a detection older than the deadline expires; its late result is suppressed', () {
    final gate = InferenceGate(deadline: ms(2000))..open();
    final t = gate.begin(ms(0))!;
    expect(gate.expireIfOverdue(ms(1999)), isNull);
    expect(gate.inFlight, isTrue);
    expect(gate.expireIfOverdue(ms(2000)), same(t));
    expect(gate.inFlight, isFalse);
    expect(gate.expired, 1);
    expect(gate.expireIfOverdue(ms(5000)), isNull, reason: 'nothing left to expire');
    final t2 = gate.begin(ms(2100))!;
    expect(gate.end(t), isFalse, reason: 'the expired one returns late');
    expect(gate.suppressed, 1);
    expect(gate.inFlight, isTrue, reason: 'the late end() of another ticket does not free the new slot');
    expect(gate.end(t2), isTrue);
  });
}
