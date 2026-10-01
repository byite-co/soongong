import 'package:freezed_annotation/freezed_annotation.dart';

import '../enums.dart';
import 'sync_stamp.dart';

part 'session.freezed.dart';

/// `sessions` (§2.2). [seatedSeconds] is the cached 순공 seconds computed by
/// `SeatedTimeCalculator`; corrections recompute it.
@freezed
abstract class StudySession with _$StudySession {
  const factory StudySession({
    required String id,
    required SyncStamp stamp,
    String? subjectId,
    String? plannerItemId,
    required SessionKind kind,
    required SessionMode mode,
    required DateTime startedAt,
    DateTime? endedAt,
    required SessionStatus status,
    required int seatedSeconds,
    required int sensitivityLevel,
    String? note,
  }) = _StudySession;

  const StudySession._();

  Duration get seated => Duration(seconds: seatedSeconds);
}

/// `session_segments` (§2.3). Saved segments are always closed.
@freezed
abstract class SessionSegment with _$SessionSegment {
  const factory SessionSegment({
    required String id,
    required SyncStamp stamp,
    required String sessionId,
    required SegmentKind kind,
    required DateTime startAt,
    required DateTime endAt,
    @Default(false) bool corrected,
  }) = _SessionSegment;

  const SessionSegment._();

  Duration get duration => endAt.difference(startAt);
}

/// `corrections` (§2.4).
@freezed
abstract class Correction with _$Correction {
  const factory Correction({
    required String id,
    required SyncStamp stamp,
    required String sessionId,
    required String segmentId,
    required SegmentKind fromKind,
    required SegmentKind toKind,
    required DateTime at,
    required int sensitivityBefore,
    required int sensitivityAfter,
  }) = _Correction;
}
