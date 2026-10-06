// RecoveryCandidate (S05 · D23 · PRD 4.1, pure Dart): "is there an
// unfinished session to ask about?" The primary signal is the single
// `session_snapshot` row (written every 15 s while measuring); a session row
// still `active`/`paused` (or `interrupted` without an end) counts too.
// The numbers shown come from `SessionTimeline.recover` — time after the last
// snapshot is never added.

import '../../../core/domain/entities/entities.dart';
import '../../../core/domain/enums.dart';
import '../../measure/domain/session_snapshot.dart';
import '../../measure/domain/session_timeline.dart';

class RecoveryCandidate {
  const RecoveryCandidate({
    required this.sessionId,
    required this.startedAt,
    required this.recordedSeconds,
    required this.endedAt,
    this.snapshot,
    this.session,
  });

  final String sessionId;

  /// UTC.
  final DateTime startedAt;

  /// Seated seconds that would be kept by "기록 마무리".
  final int recordedSeconds;

  /// UTC — never later than the last snapshot (D23).
  final DateTime endedAt;

  final SessionSnapshot? snapshot;
  final StudySession? session;

  Duration get recorded => Duration(seconds: recordedSeconds);

  static RecoveryCandidate? detect({
    required SessionSnapshot? snapshot,
    required List<StudySession> sessions,
    required String Function() newId,
  }) {
    if (snapshot != null) {
      final r = SessionTimeline.recover(
        snapshot: snapshot,
        sessionStartedAt: snapshot.startedAt,
        newId: newId,
      );
      StudySession? row;
      for (final s in sessions) {
        if (s.id == snapshot.sessionId) row = s;
      }
      return RecoveryCandidate(
        sessionId: snapshot.sessionId,
        startedAt: snapshot.startedAt,
        recordedSeconds: r.seatedSeconds,
        endedAt: r.endedAt,
        snapshot: snapshot,
        session: row,
      );
    }
    StudySession? open;
    for (final s in sessions) {
      final unfinished =
          s.status == SessionStatus.active ||
          s.status == SessionStatus.paused ||
          (s.status == SessionStatus.interrupted && s.endedAt == null);
      if (!unfinished) continue;
      if (open == null || s.startedAt.isAfter(open.startedAt)) open = s;
    }
    if (open == null) return null;
    return RecoveryCandidate(
      sessionId: open.id,
      startedAt: open.startedAt,
      recordedSeconds: 0,
      endedAt: open.startedAt,
      session: open,
    );
  }
}
