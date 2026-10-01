// SegmentCorrector (S02, pure Dart): user correction of a wrongly detected
// segment (away ↔ seated). Returns the new segment list and the data for a
// `corrections` row; 순공 is recomputed by the caller.

import '../../../core/domain/enums.dart';
import 'segment.dart';

class CorrectionOutcome {
  const CorrectionOutcome({
    required this.segments,
    required this.segmentId,
    required this.fromKind,
    required this.toKind,
  });

  final List<Segment> segments;
  final String segmentId;
  final SegmentKind fromKind;
  final SegmentKind toKind;
}

class SegmentCorrector {
  const SegmentCorrector();

  /// Changes the kind of [segmentId] to [toKind] and flags it `corrected`.
  /// Returns null when the segment is unknown or already of that kind.
  CorrectionOutcome? apply(
    List<Segment> segments, {
    required String segmentId,
    required SegmentKind toKind,
  }) {
    final idx = segments.indexWhere((s) => s.id == segmentId);
    if (idx < 0) return null;
    final target = segments[idx];
    if (target.kind == toKind) return null;
    final updated = List<Segment>.of(segments);
    updated[idx] = target.copyWith(kind: toKind, corrected: true);
    return CorrectionOutcome(
      segments: List<Segment>.unmodifiable(updated),
      segmentId: segmentId,
      fromKind: target.kind,
      toKind: toKind,
    );
  }
}
