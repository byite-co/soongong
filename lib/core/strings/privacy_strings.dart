// Privacy strings (S09, PRD 4.4 카메라와 개인정보 · 7장 · D14 · prototype 11 ·
// N6 · N7 · delDlg · expSheet). Facts only — what is stored, where, for how
// long. Checked by tool/check_forbidden_phrases.dart.

abstract final class PrivacyStrings {
  static const String title = '카메라와 개인정보';

  // Hero
  static const String heroOnTitle = '얼굴 이미지는 저장되지 않습니다';
  static const String heroOnBody =
      "카메라는 '지금 자리에 앉아 있는가'만 판단합니다. 판단이 끝난 프레임은 그 즉시 기기에서 삭제됩니다.";
  static const String heroOffTitle = '카메라를 사용하지 않고 있습니다';
  static const String heroOffBody = '수동 타이머로만 기록 중입니다.\n언제든 다시 켤 수 있습니다.';
  static const String howTitle = '어떻게 동작하나요';
  static const String how1Title = '기기 안에서만 분석';
  static const String how1Body = '영상이 서버로 전송되지 않습니다';
  static const String how2Title = '판단 직후 즉시 폐기';
  static const String how2Body = '프레임을 파일로 남기지 않습니다';
  static const String how3Title = '남는 것은 시간뿐';
  static const String how3Body = '착석·이탈 시각과 길이만 저장됩니다';

  // Stored data table — D14 rows as decided (data · location · retention)
  static const String storedTitle = '저장되는 데이터';
  static const String storedColumns = '데이터 · 위치 · 보관·삭제';
  static const List<(String, String, String)> d14Rows = <(String, String, String)>[
    ('착석 감지 프레임', '기기 메모리', '처리 즉시 해제 · 파일 저장·외부 전송 없음'),
    ('착석 샘플(불리언·시각)', '기기 → 계정 동기화', '세션 구간으로만 저장 · 사용자가 지울 때까지'),
    ('판독 사진·파생 이미지(압축본·크롭)', '기기', '최초 보관일 +30일 · 즉시 삭제·로그아웃 삭제 · 재시도로 연장 없음 · 앱 시작·포그라운드·접근 시 만료분 삭제'),
    ('판독 사진·파생 이미지', '자사 서버', '처리 종료 직후 삭제 시도 · 실패분 재시도 · 잔여분은 업로드 +24시간 안에 삭제'),
    ('판독 사진', '외부 AI 벤더', '전송 사실 명시 · 보관·학습 사용·로그 정책은 확정 전(확인 중)'),
    ('미저장 판독 결과', '서버 → 기기 캐시', '7일 뒤 또는 버리기 시 서버 원문 삭제 · 저장한 확정 마크는 오답 기록의 일부'),
    ('판독 결과·오답·복습·재풀이', '기기 → 계정 동기화', '사용자가 지울 때까지 · 구독 종료 시 읽기 전용'),
    ('세션·플래너·과목·설정', '기기 → 계정 동기화', '사용자가 지울 때까지'),
    ('계정(이메일·로그인 방식·동의 이력)', '서버', '계정 삭제까지 · 생년월일은 어디에도 저장하지 않음'),
    ('가입 패스', '서버', '소비 시 즉시 삭제 · 미소비는 발급 +10분 뒤 삭제 · 생년월일 미포함'),
    ('가입 승인 기록', '서버', '계정 삭제 시 삭제 · 연령 확인 결과·승인 시각·로그인 방식만'),
  ];
  static const String storedVendorPending = '외부 AI 벤더의 보관·학습·로그 조건은 확정 전입니다(확인 중).';

  // Settings rows
  static const String settingsTitle = '설정';
  static const String cameraToggle = '카메라 착석 감지';
  static const String cameraToggleHint = '끄면 수동 타이머로만 기록합니다';
  static const String corrections = '잘못 감지 정정 이력';
  static String correctionsStatus(int count, int thresholdSeconds) => '되돌린 구간 $count건 · 자리 비움 판정 $thresholdSeconds초';
  static const String correctionsOpen = '정정 이력 보기';
  static const String sensitivityAuto = '감도 자동 조정';
  static const String sensitivityAutoHint = '최근 2주 되돌림 3건마다 한 단계';
  static const String reading = '숙제 사진 · 채점 판독';
  static const String premiumBadge = '프리미엄';
  static const String readingStatusOn = '판독 사용 가능';
  static const String readingStatusOff = '판독 꺼짐 · 프리미엄에서 켤 수 있습니다';
  static const String unlock = '잠금 해제';
  static const String resubscribe = '재구독';

  // Photos
  static String photosButton(int n) => '보관 중 사진 $n장 보기';
  static const String photosDeleteAll = '모두 지금 삭제';
  static const String photosSheetTitle = '보관 중 사진';
  static const String photosSheetHint = '판독 후 30일이 지나면 자동 삭제됩니다.\n오답 기록은 사진을 지워도 남습니다.';
  static const String photosEmpty = '보관 중인 사진이 없습니다';
  static const String photoDelete = '삭제';
  static const String photoDeleting = '삭제 중';
  static const String photoDeleteFailed = '실패 · 다시 시도';
  static String monthDay(int month, int day) => '$month월 $day일';
  static String monthDayTime(int month, int day, String hm) => '$month월 $day일 $hm';
  static String photoShot(String when) => '$when 촬영';
  static String photoExpires(String when) => '$when 삭제 예정';
  static String photoName(String subject, String range) => '$subject · $range';
  static const String photoUnknownRequest = '판독 사진';
  static String deletePhotosTitle(int n) => '사진 $n장을 지금 삭제할까요?';
  static const String deletePhotoTitle = '이 사진을 지금 삭제할까요?';
  static const String deletePhotoBody = '사진만 지워지고 판독한 오답 기록은 남습니다.\n되돌릴 수 없습니다.';
  static const String deletePhotoConfirm = '삭제';
  static String photosDeleted(int n) => '사진 $n장을 삭제했습니다';
  static String photosPartial(int total, int ok, int failed) =>
      '$total장 중 $ok장을 삭제했습니다 · $failed장은 삭제하지 못했습니다.\n실패한 사진은 목록에 남아 있으니 다시 시도하세요.';
  static const String photosRetry = '다시 시도';

  // Export
  static const String export = '내 기록 내보내기';
  static const String exportCsv = 'CSV로 내보내기';
  static const String exportJson = 'JSON으로 내보내기';
  static const String exportHint = '세션 · 플래너 · 오답 · 과목 · 설정을 파일로 저장합니다. 사진은 포함되지 않습니다.';
  static const String exportFailed = '내보내지 못했습니다';
  static const String exportRetry = '다시 시도';
  static const String exporting = '파일 만드는 중…';

  // Delete all
  static const String deleteAll = '모든 기록 삭제';
  static const String deleteAllTitle = '모든 기록을 삭제할까요?';
  static const String deleteAllBody = '이 기기에서 다음이 모두 지워지고 되돌릴 수 없습니다.';
  static const List<String> deleteAllItems = <String>[
    '· 집중 세션 · 자리 비움 · 정정 이력',
    '· 플래너 할 일 · 반복 일정 · 기간 일정',
    '· 오답 · 복습 큐 · 재풀이 기록',
    '· 기기에 보관된 판독 사진',
    '· 직접 추가한 과목 · 앱 설정',
  ];
  static const String deleteAllKeeps = '계정의 동기화 기록도 함께 지워집니다 · 구독과 로그인은 유지';
  static const String deleteAllNext = '다음';
  static const String deleteAllFinalTitle = '정말 모든 기록을 삭제할까요?';
  static const String deleteAllFinalBody = '서버와 이 기기의 기록이 지금 지워지며 되돌릴 수 없습니다.\n로그인과 구독 상태는 유지됩니다.';
  static const String deleteAllConfirm = '삭제';
  static const String deleteAllDone = '모든 기록을 삭제했습니다';
  static String deleteAllPartial(int failed) => '기록은 삭제했습니다 · 사진 $failed장은 삭제하지 못했습니다 · 보관 중 사진에서 다시 시도';
  static const String deleteAllBlocked = '측정 중에는 삭제할 수 없습니다 · 집중을 끝낸 뒤 다시 시도';
  static const String deleteAllFailed = '삭제하지 못했습니다 · 연결을 확인한 뒤 다시 시도';

  // Footer
  static const String footer =
      '기록은 내 계정에 동기화되어 기기를 바꿔도 이어집니다.\n사진은 계정에 올라가지 않고 이 기기에만 30일 보관됩니다.\n제3자에게 기록을 넘기지 않습니다.';
  static const String loadFailed = '개인정보 화면을 불러오지 못했습니다';
}
