// Subject strings (S02). Fact-only wording.

abstract final class SubjectsStrings {
  /// The catch-all subject that cannot be deleted; records of a deleted
  /// subject move here (`subjDelN`).
  static const String defaultSubjectName = '기타';

  /// dev flavor seed (S02 §4.5).
  static const List<String> devSeedNames = <String>['국어', '수학', '영어', '과학', '사회'];
}
