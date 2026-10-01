// Wire enums (S02). `wire` is the value stored in the DB and sent to the
// server (docs/data-model.md §0). Multi-word values are snake_case.

/// An enum whose stored/transferred representation is [wire].
abstract interface class WireEnum implements Enum {
  String get wire;
}

T wireEnumFrom<T extends WireEnum>(List<T> values, String wire) =>
    values.firstWhere(
      (v) => v.wire == wire,
      orElse: () => throw ArgumentError.value(wire, 'wire', 'unknown $T'),
    );

T? wireEnumFromOrNull<T extends WireEnum>(List<T> values, String? wire) {
  if (wire == null) return null;
  for (final v in values) {
    if (v.wire == wire) return v;
  }
  return null;
}

enum SessionKind implements WireEnum {
  study('study'),
  todo('todo'),
  self('self');

  const SessionKind(this.wire);

  @override
  final String wire;
}

enum SessionMode implements WireEnum {
  camera('camera'),
  manual('manual');

  const SessionMode(this.wire);

  @override
  final String wire;
}

enum SessionStatus implements WireEnum {
  active('active'),
  paused('paused'),
  interrupted('interrupted'),
  finished('finished'),
  discarded('discarded');

  const SessionStatus(this.wire);

  @override
  final String wire;
}

enum SegmentKind implements WireEnum {
  seated('seated'),
  away('away'),
  manual('manual'),
  paused('paused');

  const SegmentKind(this.wire);

  @override
  final String wire;

  /// Counts toward 순공시간.
  bool get countsAsSeated => this == seated || this == manual;
}

enum PlannerKind implements WireEnum {
  study('study'),
  todo('todo'),
  self('self'),
  event('event');

  const PlannerKind(this.wire);

  @override
  final String wire;
}

enum ReadingOrigin implements WireEnum {
  planner('planner'),
  wrongs('wrongs'),
  home('home');

  const ReadingOrigin(this.wire);

  @override
  final String wire;
}

enum ReadingRequestStatus implements WireEnum {
  selecting('selecting'),
  sending('sending'),
  processing('processing'),
  takingLong('taking_long'),
  failed('failed'),
  cancelled('cancelled'),
  doneUnsaved('done_unsaved'),
  saved('saved'),
  discarded('discarded'),
  expired('expired');

  const ReadingRequestStatus(this.wire);

  @override
  final String wire;

  /// processing / taking_long — one per account (D17).
  bool get isActive => this == processing || this == takingLong;

  /// Blocks new requests together with [isActive] (D17).
  bool get isUnsaved => this == doneUnsaved;
}

/// Mark of a wrong item. `correct` never becomes a wrong item.
enum WrongMark implements WireEnum {
  wrong('wrong'),
  partial('partial'),
  unsolved('unsolved'),
  guessed('guessed');

  const WrongMark(this.wire);

  @override
  final String wire;
}

enum WrongItemStatus implements WireEnum {
  open('open'),
  resolved('resolved');

  const WrongItemStatus(this.wire);

  @override
  final String wire;
}

enum RetryResult implements WireEnum {
  correct('correct'),
  partial('partial'),
  wrong('wrong');

  const RetryResult(this.wire);

  @override
  final String wire;
}

enum SubscriptionSource implements WireEnum {
  sdk('sdk'),
  ledger('ledger');

  const SubscriptionSource(this.wire);

  @override
  final String wire;
}

enum ThemeSetting implements WireEnum {
  system('system'),
  light('light'),
  dark('dark');

  const ThemeSetting(this.wire);

  @override
  final String wire;
}

enum ConflictResolution implements WireEnum {
  local('local'),
  server('server'),
  deleted('deleted');

  const ConflictResolution(this.wire);

  @override
  final String wire;
}
