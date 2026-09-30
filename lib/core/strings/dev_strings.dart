// Strings for the dev menu (dev flavor only, S01).

abstract final class DevStrings {
  static const String title = '개발 메뉴';
  static const String subtitle = '흔들어서 열기 · dev 전용';
  static const String openGallery = '위젯 카탈로그 열기';
  static const String sectionSeat = 'SeatEngine (Fake)';
  static const String sectionReading = 'ReadingEngine (Fake)';
  static const String sectionBilling = 'BillingGateway (Fake)';
  static const String sectionSync = 'SyncEngine (Fake)';
  static const String delayLabel = '지연(ms)';
  static const String flavorLabel = '플레이버';
  static const String deviceIdLabel = '기기 ID';
  static const String backendLabel = '백엔드 설정';
  static const String backendPresent = '있음';
  static const String backendMissing = '없음 (Fake만 동작)';

  static const String seatAlwaysSeated = '계속 착석';
  static const String seatAwayAfter = '이탈 (N초 후)';
  static const String seatLostAfter = '카메라 끊김 (N초 후)';
  static const String seatPermissionDenied = '권한 거부';
  static const String seatCameraBusy = '카메라 점유';

  static const String readingSuccess = '성공';
  static const String readingSuccessZeroWrong = '성공 · 오답 0';
  static const String readingTakingLongThenSuccess = '오래 걸림 → 성공';
  static const String readingFail = '판독 실패';
  static const String readingSendFail = '전송 실패';
  static const String readingCancelRace = '취소 경합 (완료가 이김)';
  static const String readingSaveConflict = '저장 충돌 (already_saved)';

  static const String billingFree = 'free';
  static const String billingTrial = 'trial';
  static const String billingPremium = 'premium';
  static const String billingCancelPending = 'cancelPending';
  static const String billingGrace = 'grace';
  static const String billingExpired = 'expired';
  static const String billingPendingApproval = 'pendingApproval';

  static const String syncIdle = 'Idle';
  static const String syncSyncing = 'Syncing';
  static const String syncOffline = 'Offline';
  static const String syncError = 'Error';
  static const String syncFullResync = 'FullResyncRequired';
}
