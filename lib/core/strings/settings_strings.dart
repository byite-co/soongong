// Settings strings (S09, PRD 4.4 · 4.3c · prototype 12 · N1 · N2 · D14 ·
// N-로그아웃/계정 삭제/알림 권한 거부). Facts only: times, counts, states.
// No evaluation, praise or pressure (CLAUDE.md §1). Checked by
// tool/check_forbidden_phrases.dart.

abstract final class SettingsStrings {
  static const String title = '설정';
  static const String back = '뒤로';

  // Sections
  static const String sectionStudy = '공부';
  static const String sectionCameraData = '카메라 · 데이터';
  static const String sectionAccount = '계정';
  static const String sectionNotifications = '알림';
  static const String sectionDisplay = '화면';
  static const String sectionUse = '이용';

  // Rows
  static const String dailyGoal = '하루 목표 시간';
  static const String subjects = '과목 관리';
  static const String weekStart = '주 시작 요일';
  static const String privacy = '카메라와 개인정보';
  static const String cameraOn = '착석 감지 켬';
  static const String cameraOff = '수동';
  static const String reading = '숙제 사진 · 채점 판독';
  static const String readingOn = '켬 · 30일 보관';
  static const String readingLocked = '잠김';
  static const String exportDelete = '내 기록 내보내기 · 삭제';
  static const String notifications = '알림';
  static const String theme = '테마';
  static const String themeSystem = '시스템';
  static const String themeLight = '라이트';
  static const String themeDark = '다크';
  static const String plan = '요금제';
  static const String help = '도움말 · 문의';
  static const String premiumBadge = '프리미엄';
  static String version(String v) => '순공 $v';

  // 앱 정보 (원본 §4.1-1)
  static const String sectionAppInfo = '앱 정보';
  static const String versionLabel = '버전';
  static const String licenses = '오픈소스 라이선스';

  // 계정 화면 (원본 §4.2 · S09b)
  static const String account = '계정';
  static const String accountTitle = '계정';
  static const String consentSection = '동의';
  static const String consentAccount = '동의 ① · 계정과 기록 저장';
  static const String consentReading = '동의 ② · 판독 사진 외부 전송';
  static String consentVersionAt(String version, String at) => '버전 $version · $at';
  static const String consentNone = '동의 전';
  static String consentRevokedAt(String at) => '철회함 · $at';
  static const String consentRevoke = '동의 ② 철회';
  static const String consentRevokeTitle = '판독 사진 전송 동의를 철회할까요?';
  static const String consentRevokeBody = '철회하면 사진 판독이 꺼집니다. 저장된 오답 기록은 남습니다.';
  static const String consentRevokeConfirm = '철회';
  static const String consentRevoked = '동의 ②를 철회했습니다';
  static const String syncSection = '동기화';
  static const String syncLast = '마지막 동기화';
  static const String syncLastNone = '—';
  static const String syncNow = '지금 동기화';
  static const String syncNotConnected = '동기화 미연결';

  // Plan labels (facts)
  static const String planFree = '무료 · 순공 측정 · 플래너 · 통계';
  static const String planPremium = '프리미엄';
  static const String planTrial = '프리미엄 · 체험 중';
  static const String planCancelPending = '프리미엄 · 종료 예정';
  static const String planGrace = '프리미엄 · 결제 확인 중';
  static const String planPendingApproval = '무료 · 승인 대기';
  static String planExpiredReadOnly(int wrongs) => '무료 · 오답 $wrongs문항 읽기 전용';

  // Week start
  static const String monday = '월요일';
  static const String sunday = '일요일';
  static const String mondayHint = '학교 주간과 같음';
  static const String sundayHint = '달력 앱과 같음';

  // Goal sheet (N1 · D25)
  static const String goalSheetTitle = '하루 목표 시간';
  static const String goalHint = '목표는 직접 정합니다. 통계·플래너의 기준값으로만 쓰입니다.';
  static String goalSuggested(String hm) => '최근 4주 평균 $hm · 기록으로 계산';
  static const String goalSuggestedApply = '평균으로 채우기';
  static const String goalSuggestedNone = '최근 4주 기록 없음';
  static const String goalSuggestedLocked = '기록 기반 기본값은 프리미엄에서 채워집니다';
  static String goalSave(String hm) => '$hm으로 저장';

  // Notifications sheet (D14)
  static const String notifSheetTitle = '알림';
  static const String notifPermissionOn = '기기 알림 권한 켜짐';
  static const String notifPermissionOff = '기기 알림 권한 꺼짐 · 탭해서 안내 보기';
  static const String notifPermissionUnknown = '기기 알림 권한 확인 전 · 탭해서 요청';
  static const String notifReview = '복습 큐 알림';
  static const String notifReviewHint = '오늘 복습할 문항이 있을 때 하루 한 번';
  static const String notifEvent = '반복 일정 10분 전';
  static const String notifEventHint = '학원·수업 등 타임테이블 일정';
  static const String notifOff = '꺼짐';
  static String notifReviewAt(String time) => '복습 $time';
  static const String notifEventShort = '일정';
  static const List<String> notifTimes = <String>['19:00', '20:00', '21:00', '22:00'];
  static const String notifPickTime = '다른 시각 선택';
  static const String notifDeniedTitle = '기기 알림이 꺼져 있습니다';
  static const String notifDeniedBody =
      '앱 안 설정은 저장됐지만 기기에서 막혀 있어 울리지 않습니다.\n기기 설정에서 켠 뒤 돌아오면 자동으로 반영됩니다.';
  static const String notifOpenSettings = '기기 설정 열기';
  static const String notifLater = '나중에';
  static String notifEnabledToast(String time) => '기기 알림이 켜졌습니다 · 복습 $time';
  static const String notifEnabledToastNoReview = '기기 알림이 켜졌습니다';

  // Notification content (facts)
  static const String channelName = '순공 알림';
  static const String channelDescription = '복습 큐 시각 · 반복 일정 10분 전';
  static const String reviewTitle = '복습 큐';
  static String reviewBody(int n) => '복습할 문항 $n개가 있습니다';
  static String eventBody(String start) => '10분 뒤 시작 · $start';

  // Account (12 설정 · 계정)
  static const String accountEmailUnknown = '이메일 없음';
  static const String providerEmail = '이메일 계정';
  static const String providerGoogle = 'Google 로그인';
  static const String providerApple = 'Apple 로그인';
  static const String providerKakao = '카카오 로그인';
  static const String providerUnknown = '로그인 계정';
  static const String syncNever = '아직 동기화 전';
  static const String syncJustNow = '방금 동기화됨';
  static String syncMinutesAgo(int m) => '$m분 전 동기화';
  static String syncHoursAgo(int h) => '$h시간 전 동기화';
  static String syncDaysAgo(int d) => '$d일 전 동기화';
  static const String localOnlyTitle = '로컬 전용 모드';
  static const String localOnlyBody = '계정 없이 이 기기에만 기록합니다';
  static const String logout = '로그아웃';
  static const String deleteAccount = '계정 삭제';
  static const String logoutTitle = '로그아웃할까요?';
  static const String logoutBody = '기록은 계정에 저장되어 있어 다시 로그인하면 그대로 보입니다.\n이 기기의 판독 사진은 로그아웃 시 삭제됩니다.';
  static const String deleteAccountTitle = '계정을 삭제할까요?';
  static const String deleteAccountBody =
      '계정과 동기화된 모든 기록(세션·플래너·오답·과목·설정)이 지워지고 되돌릴 수 없습니다.\n구독은 스토어에서 따로 해지해야 합니다.';
  static const String deleteAccountConfirm = '삭제';
  static const String logoutConfirm = '로그아웃';

  // Save states
  static const String saved = '저장했습니다';
  static const String saveFailed = '저장하지 못했습니다 · 다시 시도';
  static const String loadFailed = '설정을 불러오지 못했습니다';
}
