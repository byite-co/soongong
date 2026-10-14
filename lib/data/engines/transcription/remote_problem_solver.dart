import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/contracts/problem_solver.dart';
import '../../../core/contracts/transcription_engine.dart';
import 'remote_ai_jobs.dart';

class RemoteProblemSolver implements ProblemSolver {
  RemoteProblemSolver(SupabaseClient client, {ApproveAi? approve})
    : jobs = RemoteAiJobs(client, approve: approve);
  RemoteProblemSolver.withJobs(this.jobs);
  final RemoteAiJobs jobs;

  @override
  Future<ProblemSolution> solve({
    required String documentId,
    required int revision,
    required String text,
    required int epoch,
    String? referenceAnswer,
  }) async {
    final response = await jobs.execute({
      'schema_version': 1,
      'operation': 'solve',
      'document_id': documentId,
      'revision': revision,
      'text': text,
      'reference_answer': referenceAnswer,
      'purge_epoch': epoch,
      'consent_version': 'study-2026-10-13',
    });
    final solution = ProblemSolution.fromJson(response);
    if (solution.documentId != documentId ||
        solution.revision != revision ||
        solution.referenceProvided !=
            (referenceAnswer != null && referenceAnswer.isNotEmpty)) {
      throw const StudyEngineException('invalid_solution');
    }
    return solution;
  }
}
