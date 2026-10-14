// Subject strings (S02 · S09, PRD 4.4 과목 관리 · prototype 13 · N11 · B8).
// Facts only. Checked by tool/check_forbidden_phrases.dart.

abstract final class SubjectsStrings {
  /// The catch-all subject that cannot be deleted; records of a deleted
  /// subject move here (`subjDelN`).
  static const String defaultSubjectName = '기타';

  /// dev flavor seed (S02 §4.5).
  static const List<String> devSeedNames = <String>['국어', '수학', '영어', '과학', '사회'];

  // Screen (13)
  static const String title = '과목 관리';
  static const String add = '과목 추가';
  static const String noRecord = '기록 없음';
  static String thisWeek(String hm) => '이번 주 $hm';
  static const String defaultBadge = '기본';
  static const String loadFailed = '과목을 불러오지 못했습니다';
  static String colorsFull(int max) => '과목은 색 수만큼 $max개까지 둘 수 있습니다';

  // Sheet (N11)
  static const String sheetAdd = '과목 추가';
  static const String sheetEdit = '과목 편집';
  static const String name = '이름';
  static const String namePlaceholder = '예: 한국사';
  static const String color = '색';
  static const String colorTaken = '다른 과목이 쓰는 색';
  static const String save = '저장';
  static const String create = '추가';
  static const String saving = '저장 중…';
  static const String nameEmpty = '과목 이름을 입력하세요';
  static const String nameDuplicate = '같은 이름의 과목이 있습니다';
  static const String nameTooLong = '과목 이름은 20자까지입니다';
  static const int nameMaxLength = 20;
  static const String deleteRow = "과목 삭제 · 기록은 '기타'로 이동";
  static const String defaultColorLocked = "'기타'의 색은 바꿀 수 없습니다 · 이름만 바꿀 수 있습니다";
  static const String defaultCannotDelete = "'기타'는 지울 수 없습니다 · 다른 과목의 기록이 모이는 곳";

  // Delete (B8 · D22)
  static String deleteTitle(String name) => '$name 과목을 지울까요?';
  static const String deleteBody = '이 과목의 기록·할 일·오답은 모두 「기타」로 옮겨집니다.\n5초 안에 되돌릴 수 있습니다.';
  static const String deleteConfirm = '삭제';
  static String deleted(String name) => '$name 과목을 지웠습니다';
  static const String restored = '되돌렸습니다';
  static const String added = '추가했습니다';
  static const String saved = '저장했습니다';
  static const String saveFailed = '저장하지 못했습니다 · 입력은 그대로 있습니다';
  static const String deleteFailed = '삭제하지 못했습니다';
}
