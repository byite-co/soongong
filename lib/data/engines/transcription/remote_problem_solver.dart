import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/contracts/problem_solver.dart';
import '../../../core/contracts/transcription_engine.dart';

class RemoteProblemSolver implements ProblemSolver {
  RemoteProblemSolver(this.client);
  final SupabaseClient client;

  @override
  Future<ProblemSolution> solve({required String documentId, required int revision,
    required String text, required int epoch, String? referenceAnswer}) async {
    final response = await client.functions.invoke('study-infer', body: {
      'schema_version': 1, 'operation': 'solve', 'document_id': documentId, 'revision': revision,
      'text': text, 'reference_answer': referenceAnswer, 'purge_epoch': epoch, 'consent_version': 'study-2026-10-13',
    }).timeout(const Duration(seconds: 65));
    final solution = ProblemSolution.fromJson(Map<String, dynamic>.from(response.data as Map));
    if (solution.documentId != documentId || solution.revision != revision ||
        solution.referenceProvided != (referenceAnswer != null && referenceAnswer.isNotEmpty)) {
      throw const StudyEngineException('invalid_solution');
    }
    return solution;
  }
}
