import 'package:flutter_test/flutter_test.dart';
import 'package:soongong/core/contracts/problem_solver.dart';
import 'package:soongong/core/contracts/transcription_engine.dart';

void main() {
  Map<String, dynamic> payload() => {
    'schema_version': 1, 'document_id': 'document', 'revision': 2, 'answer': '1/2',
    'explanation': '분수 계산', 'verification': 'verified', 'model': 'fixture', 'reference_provided': true,
  };
  test('numeric verification is qualified by a supplied reference', () {
    final result = ProblemSolution.fromJson(payload());
    expect(result.verification, SolutionVerification.verified);
    expect(ProblemSolution.fromJson(Map<String, dynamic>.from(result.toJson())).revision, 2);
    expect(() => ProblemSolution.fromJson(payload()..['reference_provided'] = false), throwsA(isA<StudyEngineException>()));
  });
  test('oversized explanations and unsupported response schema are rejected', () {
    expect(() => ProblemSolution.fromJson(payload()..['schema_version'] = 2), throwsA(isA<StudyEngineException>()));
    expect(() => ProblemSolution.fromJson(payload()..['explanation'] = 'x' * 16001), throwsA(isA<StudyEngineException>()));
  });
}
