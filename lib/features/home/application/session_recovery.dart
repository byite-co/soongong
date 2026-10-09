// SessionRecoveryHandler (S05 · D23): what the recovery sheet's three
// actions do. The default settles with the S02 domain (`SessionTimeline.
// recover` + `saveFinished(interrupted)`); S06 overrides the provider to
// resume into the measurement screen and to own the settlement.

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/domain/enums.dart';
import '../../../core/domain/ids.dart';
import '../../../core/logging/app_logger.dart';
import '../../../data/repositories/repository_providers.dart';
import '../../../data/repositories/session_repository.dart';
import '../../auth/domain/auth_redirect.dart';
import '../../measure/application/measure_controller.dart';
import '../../measure/domain/session_timeline.dart';
import '../domain/recovery_candidate.dart';

part 'session_recovery.g.dart';

abstract class SessionRecoveryHandler {
  String? get finishLocation => null;

  /// "이어서 집중하기": returns a location to open, or null when handled.
  Future<String?> resume(RecoveryCandidate candidate);

  /// "여기까지 기록 마무리": saves what the last snapshot proves (D23).
  Future<void> finish(RecoveryCandidate candidate);

  /// "기록 버리기" (after the confirm dialog): nothing is kept.
  Future<void> discard(RecoveryCandidate candidate);
}

class DefaultSessionRecoveryHandler extends SessionRecoveryHandler {
  DefaultSessionRecoveryHandler(this._sessions);

  final SessionRepository _sessions;

  @override
  Future<String?> resume(RecoveryCandidate candidate) async =>
      '${AppPaths.measureSetup}?resume=${candidate.sessionId}';

  @override
  Future<void> finish(RecoveryCandidate candidate) async {
    final snap = candidate.snapshot;
    if (snap == null) {
      // A bare row without a snapshot: nothing provable to add; S06 decides.
      await _sessions.clearSnapshot();
      appLog.w('recovery: finish without snapshot — left to S06');
      return;
    }
    final r = SessionTimeline.recover(
      snapshot: snap,
      sessionStartedAt: snap.startedAt,
      newId: newUuid,
    );
    await _sessions.saveFinished(
      id: snap.sessionId,
      kind: snap.kind,
      mode: snap.mode,
      startedAt: snap.startedAt,
      endedAt: r.endedAt,
      status: SessionStatus.interrupted,
      segments: r.segments,
      sensitivityLevel: snap.sensitivity,
      subjectId: snap.subjectId,
      plannerItemId: snap.plannerItemId,
    );
    await _sessions.clearSnapshot();
    appLog.i('recovery: finished as interrupted (${r.seatedSeconds}s)');
  }

  @override
  Future<void> discard(RecoveryCandidate candidate) async {
    await _sessions.clearSnapshot();
    if (candidate.session != null) {
      // Confirmed through a dialog → immediate commit (D22).
      await _sessions.commitDelete(candidate.sessionId);
    }
    appLog.i('recovery: discarded');
  }
}

class MeasureSessionRecoveryHandler extends DefaultSessionRecoveryHandler {
  MeasureSessionRecoveryHandler(super.sessions, this.controller);
  final MeasureController controller;

  @override
  String get finishLocation => '/measure/summary';

  @override
  Future<void> finish(RecoveryCandidate candidate) =>
      controller.recover(candidate.sessionId, continueSession: false);

  @override
  Future<void> discard(RecoveryCandidate candidate) =>
      controller.discard(candidate.sessionId);
}

@Riverpod(keepAlive: true)
SessionRecoveryHandler sessionRecoveryHandler(Ref ref) =>
    MeasureSessionRecoveryHandler(
      ref.watch(sessionRepositoryProvider),
      ref.watch(measureControllerProvider),
    );

/// Asked once per app run; a dismissed sheet is not re-shown until the next
/// launch (prototype: "다음 실행 때 다시 묻습니다").
@Riverpod(keepAlive: true)
class RecoveryPrompted extends _$RecoveryPrompted {
  @override
  bool build() => false;

  void mark() => state = true;
}
