import 'transcription_engine.dart';

enum SolutionVerification { verified, contradicted, inconclusive, unsupported }

class ProblemSolution {
  const ProblemSolution({required this.documentId, required this.revision, required this.answer,
    required this.explanation, required this.verification, required this.model, required this.referenceProvided});
  final String documentId;
  final int revision;
  final String answer;
  final String explanation;
  final SolutionVerification verification;
  final String model;
  final bool referenceProvided;

  factory ProblemSolution.fromJson(Map<String, dynamic> json) {
    if (json['schema_version'] != 1 || json['document_id'] is! String || json['revision'] is! int ||
        (json['revision'] as int) < 1 || json['answer'] is! String || (json['answer'] as String).length > 200 ||
        json['explanation'] is! String || (json['explanation'] as String).length > 16000 ||
        json['model'] is! String || (json['model'] as String).length > 200 || json['reference_provided'] is! bool) {
      throw const StudyEngineException('invalid_solution');
    }
    final verification = SolutionVerification.values.byName(json['verification'] as String);
    if (verification == SolutionVerification.verified && json['reference_provided'] != true) {
      throw const StudyEngineException('invalid_solution');
    }
    return ProblemSolution(documentId: json['document_id'] as String, revision: json['revision'] as int,
      answer: json['answer'] as String, explanation: json['explanation'] as String,
      verification: verification, model: json['model'] as String, referenceProvided: json['reference_provided'] as bool);
  }

  Map<String, Object?> toJson() => {
    'schema_version': 1, 'document_id': documentId, 'revision': revision, 'answer': answer,
    'explanation': explanation, 'verification': verification.name, 'model': model, 'reference_provided': referenceProvided,
  };
}

abstract interface class ProblemSolver {
  Future<ProblemSolution> solve({required String documentId, required int revision,
    required String text, required int epoch, String? referenceAnswer});
}
