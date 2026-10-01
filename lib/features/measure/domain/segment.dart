// Timeline segment (S02, pure Dart). Used in memory by [SessionTimeline] and
// serialised into `session_snapshot.segments_json` (D23).

import '../../../core/domain/enums.dart';

class Segment {
  const Segment({
    required this.id,
    required this.kind,
    required this.startAt,
    required this.endAt,
    this.corrected = false,
  });

  factory Segment.fromJson(Map<String, Object?> json) => Segment(
        id: json['id']! as String,
        kind: wireEnumFrom(SegmentKind.values, json['kind']! as String),
        startAt: DateTime.parse(json['start_at']! as String),
        endAt: DateTime.parse(json['end_at']! as String),
        corrected: (json['corrected'] as bool?) ?? false,
      );

  final String id;
  final SegmentKind kind;
  final DateTime startAt;
  final DateTime endAt;
  final bool corrected;

  Duration get duration {
    final d = endAt.difference(startAt);
    return d.isNegative ? Duration.zero : d;
  }

  bool get isEmpty => !endAt.isAfter(startAt);

  Segment copyWith({
    String? id,
    SegmentKind? kind,
    DateTime? startAt,
    DateTime? endAt,
    bool? corrected,
  }) =>
      Segment(
        id: id ?? this.id,
        kind: kind ?? this.kind,
        startAt: startAt ?? this.startAt,
        endAt: endAt ?? this.endAt,
        corrected: corrected ?? this.corrected,
      );

  Map<String, Object?> toJson() => <String, Object?>{
        'id': id,
        'kind': kind.wire,
        'start_at': startAt.toUtc().toIso8601String(),
        'end_at': endAt.toUtc().toIso8601String(),
        'corrected': corrected,
      };

  @override
  bool operator ==(Object other) =>
      other is Segment &&
      other.id == id &&
      other.kind == kind &&
      other.startAt.isAtSameMomentAs(startAt) &&
      other.endAt.isAtSameMomentAs(endAt) &&
      other.corrected == corrected;

  @override
  int get hashCode => Object.hash(
        id,
        kind,
        startAt.millisecondsSinceEpoch,
        endAt.millisecondsSinceEpoch,
        corrected,
      );

  @override
  String toString() =>
      'Segment(${kind.wire} ${startAt.toIso8601String()}–${endAt.toIso8601String()}'
      '${corrected ? ' corrected' : ''})';
}
