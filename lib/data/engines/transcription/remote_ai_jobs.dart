import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/contracts/transcription_engine.dart';

/// Server quote + explicit, scoped UI approval. Identity is persisted before HTTP.
class AiApproval {
  const AiApproval({
    required this.requestId,
    required this.quoteId,
    required this.operation,
    required this.epoch,
    this.generation = 0,
  });
  final String requestId, quoteId, operation;
  final int epoch;
  final int generation;
}

class AiJobUnavailable extends StudyEngineException {
  const AiJobUnavailable(this.job) : super('ai_job_unavailable');
  final Map<String, dynamic> job;
}

typedef ApproveAi = Future<AiApproval> Function(String operation, int epoch);
typedef StudyInvoke =
    Future<Map<String, dynamic>> Function(
      String function,
      Map<String, dynamic> body,
    );

class RemoteAiJobs {
  RemoteAiJobs(
    SupabaseClient client, {
    this.approve,
    this.beforeSend,
    this.onJob,
    this.checkCurrent,
  }) : invoke = ((function, body) async => Map<String, dynamic>.from(
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
    this.beforeSend,
    this.onJob,
    this.checkCurrent,
  });
  final StudyInvoke invoke;
  final Object? Function() session;
  final ApproveAi? approve;
  final Future<void> Function(AiApproval, Map<String, dynamic>)? beforeSend;
  final Future<void> Function(String, Map<String, dynamic>)? onJob;
  final void Function()? checkCurrent;

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
    checkCurrent?.call();
    if (!identical(session(), owner) ||
        approval.operation != operation ||
        approval.epoch != epoch ||
        !_uuid(approval.requestId) ||
        !_uuid(approval.quoteId)) {
      throw const StudyEngineException('invalid_ai_approval');
    }
    await beforeSend?.call(approval, input);
    checkCurrent?.call();
    if (!identical(session(), owner))
      throw const StudyEngineException('account_changed');
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
    await onJob?.call(approval.requestId, job);
    if (job['state'] != 'succeeded' || job['result'] is! Map) {
      // Retain approval.requestId and explicitly query study-job; never create
      // a replacement ID or automatically repeat an unknown provider attempt.
      throw AiJobUnavailable(job);
    }
    return Map<String, dynamic>.from(job['result'] as Map);
  }

  Future<Map<String, dynamic>> status(
    int epoch,
    String requestId, {
    bool cancel = false,
  }) async {
    final owner = session();
    if (owner == null) {
      throw const StudyEngineException('account_changed');
    }
    final result = await invoke('study-job', {
      'version': 2,
      'action': cancel ? 'cancel' : 'status',
      'purge_epoch': epoch,
      'request_id': requestId,
    });
    if (!identical(session(), owner)) {
      throw const StudyEngineException('account_changed');
    }
    await onJob?.call(requestId, result);
    return result;
  }

  Future<Map<String, dynamic>> quote(String operation, int epoch) async {
    final owner = session();
    if (owner == null) throw const StudyEngineException('account_changed');
    final result = await invoke('study-job', {
      'version': 2,
      'action': 'quote',
      'purge_epoch': epoch,
      'operation': operation,
    });
    if (!identical(session(), owner))
      throw const StudyEngineException('account_changed');
    return result;
  }

  static bool _uuid(String value) => RegExp(
    r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
  ).hasMatch(value);
}
