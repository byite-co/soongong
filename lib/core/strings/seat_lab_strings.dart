// Strings for the dev-only seat detection harness (`/_seat_lab`, S04).
// Facts only: counts, times, rates — no evaluation (CLAUDE.md §1).

abstract final class SeatLabStrings {
  static const String title = '착석 감지 실험실';
  static const String subtitle = 'dev 전용 · 프레임은 저장되지 않습니다';

  // Status
  static const String sectionStatus = '상태';
  static const String stateIdle = '대기';
  static const String stateStarting = '시작 중…';
  static const String stateRunning = '실행 중';
  static const String stateLost = '카메라 끊김';
  static const String seated = '착석';
  static const String notSeated = '미검출';
  static const String noSampleYet = '샘플 없음';
  static const String lastFrameDetected = '최근 프레임 검출';
  static const String heldByWindow = '유지 구간(3초)';
  static const String yes = '예';
  static const String no = '아니오';

  // Numbers
  static const String sectionNumbers = '수치';
  static const String elapsed = '경과';
  static const String framesProcessed = '처리 / 전달 프레임';
  static const String framesDropped = '드롭';
  static const String interval = '처리 주기';
  static const String detectionRate60 = '검출률 (최근 60초)';
  static const String seatedRate60 = '착석 비율 (최근 60초)';
  static const String latency60 = '평균 지연 (최근 60초)';
  static const String battery = '배터리 (시작 → 현재)';
  static const String batteryUnknown = '읽을 수 없음';
  static const String events = '이벤트 수';
  static const String agreementSeated = '정답 착석 중 착석 판정';
  static const String agreementAway = '정답 이탈 중 착석 판정';
  static const String segments = '구간 (제외)';
  static const String runAgreement = '이 실행 · 정답 착석 중 착석 / 이탈 중 착석';
  static const String caseAgreement = '케이스별 · 정답 착석 중 착석 / 이탈 중 착석';
  static const String caseAgreementNone = '케이스 라벨이 붙은 샘플 없음';
  static const String batteryRun = '이 실행 배터리 (시작 → 끝)';
  static const String batteryValid60 = '60분 연속 배터리 측정';
  static const String batteryValidYes = '유효';
  static const String batteryValidNo = '유효하지 않음';
  static const String batteryReasonOpen = '실행 중';
  static const String batteryReasonInterrupted = '실행 중 끊김/일시정지';
  static const String batteryReasonShort = '60분 미만';
  static const String batteryReasonNoReading = '배터리 읽음 없음 (시작 또는 종료)';
  static const String batteryReasonAbnormal = '비정상 종료';
  static const String batteryReasonReleaseTimeout = '카메라 해제 지연';
  static const String batteryNoSum = '실행끼리 합산하지 않음';
  static const String csvScope = 'CSV 범위';
  static const String csvScopeAll = '전체';
  static const String csvScopeRun = '이 실행';
  static const String csvScopeCase = '이 케이스';
  static const String excludedSamples = '제외된 샘플';
  static const String suppressedResults = '폐기된 늦은 결과';
  static const String detectorReplacements = '검출기 교체';
  static const String stalledDetections = '미완료 추론 (폐기된 검출기)';
  static const String lastStop = '마지막 종료';
  static const String summaryNote = '제외 구간은 요약 집계에서 빠집니다 (CSV 에는 남음)';
  static const String noData = '—';

  // Segment end
  static const String segmentNormal = '정상';
  static const String segmentAbnormal = '비정상';
  static const String reasonBackground = '백그라운드로 엔진이 멈춤';
  static const String reasonLost = '카메라 끊긴 채 종료';
  static const String reasonError = '구간 중 오류';
  static const String reasonInferenceTimeout = '추론 대기 초과 (500ms)';
  static const String reasonSelfStop = '엔진이 스스로 멈춤';

  // Settings
  static const String sectionSettings = '실험 설정';
  static const String lowPower = '저전력 (1프레임/2초)';
  static const String minFaceSize = '최소 얼굴 크기 (minFaceSize)';
  static const String settingsLockedWhileRunning = '정지 후 바꿀 수 있습니다';
  static const String caseLabel = '프로토콜 케이스';
  static const String caseNone = '없음';

  // Truth marking
  static const String sectionTruth = '실제 상태 표시 (정답 라벨)';
  static const String truthSeated = '실제 착석';
  static const String truthAway = '실제 이탈';
  static const String truthNone = '표시 안 함';

  // Controls
  static const String sectionControls = '제어';
  static const String checkAvailability = '가용성 확인';
  static const String requestPermission = '권한 요청';
  static const String openSettings = '설정 열기';
  static const String start = '시작';
  static const String stop = '정지';
  static const String exportCsv = 'CSV 내보내기';
  static const String clearLog = '기록 지우기';
  static const String exported = '공유 시트를 열었습니다';
  static const String exportFailed = '내보내지 못했습니다';
  static const String availabilityLabel = '가용성';
  static const String permissionLabel = '권한';

  static const String availabilityOk = 'ok';
  static const String availabilityPermissionDenied = 'permissionDenied';
  static const String availabilityCameraBusy = 'cameraBusy';
  static const String availabilityUnavailable = 'unavailable';

  // Events
  static const String sectionEvents = '이벤트 (최근 10)';
  static const String eventNone = '아직 없음';
  static const String eventCameraLost = 'cameraLost';
  static const String eventCameraRecovered = 'cameraRecovered';
  static const String eventError = 'error';
  static const String eventStarted = 'start';
  static const String eventStopped = 'stop';
  static const String eventSelfStopped = 'self-stop';
  static const String eventPaused = 'paused';

  // Protocol cases (docs/seat-engine.md §3) — id · short name
  static const List<(String, String)> cases = <(String, String)>[
    ('P1', '정면'),
    ('P2', '고개 숙임 필기'),
    ('P3', '측면'),
    ('P4', '저조도'),
    ('N1', '빈 자리'),
    ('N2', '의자에 걸린 옷'),
    ('N3', '벽 포스터 얼굴'),
    ('N4', '사진 속 얼굴'),
    ('N5', '반려동물'),
    ('N6', '조명 급변'),
    ('N7', '카메라 가림'),
    ('N8', '화면 끄기'),
    ('N9', '전화 수신'),
    ('N10', '다른 앱 카메라 점유'),
  ];
}
