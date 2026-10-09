// TargetTimePolicy (S07, pure Dart): the premium "예상 시간 자동 채움" of the
// register sheet (PRD 4.3 · 09 · N1) — the average 순공 of the subject's
// last five saved sessions. Free users get the fixed 30-minute default plus
// a lock hint (D25: unrelated to the daily goal). Facts only: the label
// stays "목표 시간" and the student decides.

import '../../../core/domain/entities/session.dart';
import '../../../core/domain/enums.dart';

class TargetTimeSuggestion {
  const TargetTimeSuggestion({required this.minutes, required this.sampleCount});

  final int minutes;
  final int sampleCount;
}

class TargetTimePolicy {
  const TargetTimePolicy();

  static const int freeDefaultMinutes = 30;
  static const int sampleSize = 5;

  /// Average of the latest [sampleSize] saved sessions of [subjectId]
  /// (finished or interrupted, ended, 순공 > 0). null when there is none.
  TargetTimeSuggestion? recentAverage(
    Iterable<StudySession> sessions, {
    required String subjectId,
  }) {
    final saved = sessions
        .where(
          (s) =>
              s.subjectId == subjectId &&
              s.endedAt != null &&
              s.seatedSeconds > 0 &&
              (s.status == SessionStatus.finished || s.status == SessionStatus.interrupted),
        )
        .toList()
      ..sort((a, b) => b.startedAt.compareTo(a.startedAt));
    if (saved.isEmpty) return null;
    final sample = saved.take(sampleSize).toList();
    final total = sample.fold<int>(0, (acc, s) => acc + s.seatedSeconds);
    final minutes = (total / sample.length / 60).round();
    return TargetTimeSuggestion(
      minutes: minutes < 1 ? 1 : minutes,
      sampleCount: sample.length,
    );
  }
}
