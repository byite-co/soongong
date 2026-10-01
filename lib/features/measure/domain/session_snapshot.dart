// SessionSnapshot (S02, D23): what is written to `session_snapshot` every
// 15 seconds. Closed segments + the open segment (kind · start) + camera
// bookkeeping + sensitivity + wall-clock `saved_at`. No monotonic anchor.

import 'dart:convert';

import '../../../core/domain/enums.dart';
import 'segment.dart';

class SessionSnapshot {
  const SessionSnapshot({
    required this.sessionId,
    required this.mode,
    required this.kind,
    required this.startedAt,
    required this.segments,
    required this.openKind,
    required this.openStart,
    required this.savedAt,
    required this.sensitivity,
    this.lastSeatedAt,
    this.awayCandidateSince,
    this.subjectId,
    this.plannerItemId,
  });

  final String sessionId;
  final SessionMode mode;
  final SessionKind kind;
  final DateTime startedAt;

  /// Closed segments.
  final List<Segment> segments;
  final SegmentKind openKind;
  final DateTime openStart;
  final DateTime savedAt;
  final int sensitivity;

  /// Camera mode only.
  final DateTime? lastSeatedAt;

  /// Camera mode only; unconfirmed away candidate.
  final DateTime? awayCandidateSince;
  final String? subjectId;
  final String? plannerItemId;

  static String encodeSegments(List<Segment> segments) =>
      jsonEncode(segments.map((s) => s.toJson()).toList());

  static List<Segment> decodeSegments(String json) {
    final raw = jsonDecode(json);
    if (raw is! List) return const <Segment>[];
    return raw
        .whereType<Map<String, Object?>>()
        .map(Segment.fromJson)
        .toList(growable: false);
  }

  SessionSnapshot copyWith({
    List<Segment>? segments,
    SegmentKind? openKind,
    DateTime? openStart,
    DateTime? savedAt,
    int? sensitivity,
    DateTime? lastSeatedAt,
    DateTime? awayCandidateSince,
  }) =>
      SessionSnapshot(
        sessionId: sessionId,
        mode: mode,
        kind: kind,
        startedAt: startedAt,
        segments: segments ?? this.segments,
        openKind: openKind ?? this.openKind,
        openStart: openStart ?? this.openStart,
        savedAt: savedAt ?? this.savedAt,
        sensitivity: sensitivity ?? this.sensitivity,
        lastSeatedAt: lastSeatedAt ?? this.lastSeatedAt,
        awayCandidateSince: awayCandidateSince ?? this.awayCandidateSince,
        subjectId: subjectId,
        plannerItemId: plannerItemId,
      );
}
