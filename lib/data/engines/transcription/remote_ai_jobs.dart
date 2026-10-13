import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/contracts/transcription_engine.dart';

/// A caller must retain this identity across transport retries and obtain the
/// quote from study-job. Approval UI / commerce wiring is a later session.
class AiApproval {
  const AiApproval({
    required this.requestId,
    required this.quoteId,
    required this.operation,
    required this.epoch,
  });
  final String requestId, quoteId, operation;
  final int epoch;
}

typedef ApproveAi = Future<AiApproval> Function(String operation, int epoch);
typedef StudyInvoke =
    Future<Map<String, dynamic>> Function(
      String function,
      Map<String, dynamic> body,
    );

class RemoteAiJobs {
  RemoteAiJobs(SupabaseClient client, {this.approve})
    : invoke = ((function, body) async => Map<String, dynamic>.from(
        (await client.functions
                    .invoke(function, body: body)
                    .timeout(const Duration(seconds: 65)))
                .data
            as Map,
      )),
      session = (() => client.auth.currentSession);

  /// Transport seam only; envelope, approval, session and result checks remain.
  RemoteAiJobs.withTransport({
    required this.invoke,
    required this.session,
    this.approve,
  });
  final StudyInvoke invoke;
  final Object? Function() session;
  final ApproveAi? approve;

  Future<Map<String, dynamic>> execute(Map<String, dynamic> input) async {
    final owner = session();
    final authorize = approve;
    if (owner == null || authorize == null) {
      throw const StudyEngineException('ai_policy_unconfigured');
    }
    final operation = input['operation'] == 'solve'
        ? 'solve'
        : 'ocr_${input['kind']}';
    final epoch = input['purge_epoch'] as int;
    final approval = await authorize(operation, epoch);
    if (!identical(session(), owner) ||
        approval.operation != operation ||
        approval.epoch != epoch ||
        !_uuid(approval.requestId) ||
        !_uuid(approval.quoteId)) {
      throw const StudyEngineException('invalid_ai_approval');
    }
    final job = await invoke('study-infer', {
      'version': 2,
      'request_id': approval.requestId,
      'quote_id': approval.quoteId,
      'input': input,
    });
    if (!identical(session(), owner)) {
      throw const StudyEngineException('account_changed');
    }
    if (job['version'] != 2 ||
        job['request_id'] != approval.requestId ||
        job['job_id'] is! String ||
        !_uuid(job['job_id'] as String)) {
      throw const StudyEngineException('invalid_job');
    }
    if (job['state'] != 'succeeded' || job['result'] is! Map) {
      // Retain approval.requestId and explicitly query study-job; never create
      // a replacement ID or automatically repeat an unknown provider attempt.
      throw const StudyEngineException('ai_job_pending_or_unavailable');
    }
    return Map<String, dynamic>.from(job['result'] as Map);
  }

  Future<Map<String, dynamic>> status(int epoch, String requestId) async {
    final owner = session();
    if (owner == null) {
      throw const StudyEngineException('account_changed');
    }
    final result = await invoke('study-job', {
      'version': 2,
      'action': 'status',
      'purge_epoch': epoch,
      'request_id': requestId,
    });
    if (!identical(session(), owner)) {
      throw const StudyEngineException('account_changed');
    }
    return result;
  }

  static bool _uuid(String value) => RegExp(
    r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
  ).hasMatch(value);
}
