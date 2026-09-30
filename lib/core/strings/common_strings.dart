// Common UI strings (S01). Fact-only wording — no evaluation, praise or
// pressure (CLAUDE.md §1). Checked by tool/check_forbidden_phrases.dart.

abstract final class CommonStrings {
  static const String appName = '순공';

  static const String confirm = '확인';
  static const String cancel = '취소';
  static const String close = '닫기';
  static const String retry = '다시 시도';
  static const String save = '저장';
  static const String delete = '삭제';
  static const String undo = '되돌리기';
  static const String next = '다음';
  static const String back = '뒤로';
  static const String done = '완료';

  // Save 3-state (CLAUDE.md §5)
  static const String saving = '저장 중…';
  static const String saved = '저장했습니다';
  static const String saveFailedKeepInput =
      '저장하지 못했습니다 · 입력은 그대로 있습니다';

  // Modal confirm failure (input is kept; user may retry or cancel)
  static const String actionFailedRetry = '실행하지 못했습니다 · 다시 시도할 수 있습니다';

  // Delete
  static const String deleted = '삭제했습니다';
  static const String deleteFailed = '삭제하지 못했습니다';

  // State panel defaults
  static const String loading = '불러오는 중…';
  static const String emptyTitle = '아직 기록이 없습니다';
  static const String errorTitle = '불러오지 못했습니다';
  static const String errorBody = '연결을 확인한 뒤 다시 시도하세요.';
  static const String offlineTitle = '인터넷 연결이 없습니다';
  static const String offlineBody =
      '순공 측정과 플래너는 오프라인에서도 됩니다.\n사진 판독만 연결 후 이어집니다.';

  // Premium lock hint
  static const String premiumLocked = '프리미엄에서 쓸 수 있습니다';
  static const String premiumSeePlans = '요금제 보기';

  // Time chip
  static const String minuteUnit = '분';
  static const String hourUnit = '시간';

  // Temporary splash (S01; replaced by S05 router + S02 onboarding)
  static const String splashPreparing = '준비 중…';
}
