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

  // Stored data table (D14)
  static const String storedTitle = '저장되는 데이터';
  static const String storedFocus = '집중';
  static const String storedFocusBody = '시작 시각 · 종료 시각 · 과목';
  static const String storedAway = '이탈';
  static const String storedAwayBody = '시작 시각 · 종료 시각';
  static const String storedCorrection = '정정';
  static const String storedCorrectionBody = '되돌린 구간 · 되돌린 시각';
  static const String storedReading = '판독';
  static const String storedReadingBody = '문항별 마크 · 판독 시각 · 사진(기기 30일)';
  static const String storedAccount = '계정';
  static const String storedAccountBody = '로그인 이메일 · 구독 상태 · 동기화 시각';
  static const String storedNever = '저장하지 않는 것';
  static const String storedNeverBody = '카메라 영상·얼굴 특징 · 위치 · 연락처 · 생년월일';

  // Settings rows
  static const String settingsTitle = '설정';
  static const String cameraToggle = '카메라 착석 감지';
  static const String cameraToggleHint = '끄면 수동 타이머로만 기록합니다';
  static const String corrections = '잘못 감지 정정 이력';
  static String correctionsStatus(int count, bool auto) =>
      '되돌린 구간 $count건 · ${auto ? '감도 자동 조정' : '감도 수동'}';
  static const String reading = '숙제 사진 · 채점 판독';
  static const String premiumBadge = '프리미엄';
  static const String readingOnBody = '유일하게 기기 밖으로 나가는 데이터. 외부 AI 전송 · 30일 뒤 삭제 · 학습 미사용';
  static const String readingOffBody = '꺼져 있음 · 켜면 채점 페이지 사진만 외부 AI로 전송됩니다 (30일 뒤 삭제)';
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
  static const String deleteAllConfirm = '삭제';
  static const String deleteAllDone = '모든 기록을 삭제했습니다';
  static const String deleteAllBlocked = '측정 중에는 삭제할 수 없습니다 · 집중을 끝낸 뒤 다시 시도';
  static const String deleteAllFailed = '삭제하지 못했습니다 · 연결을 확인한 뒤 다시 시도';

  // Footer
  static const String footer =
      '기록은 내 계정에 동기화되어 기기를 바꿔도 이어집니다.\n사진은 계정에 올라가지 않고 이 기기에만 30일 보관됩니다.\n제3자에게 기록을 넘기지 않습니다.';
  static const String loadFailed = '개인정보 화면을 불러오지 못했습니다';
}
