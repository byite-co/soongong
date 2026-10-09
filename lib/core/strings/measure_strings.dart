import '../domain/enums.dart';

abstract final class MeasureStrings {
  static const setup = '집중 준비';
  static const focus = '집중 중';
  static const summary = '집중 기록';
  static const detail = '세션 상세';
  static const subject = '과목';
  static const noSubject = '과목 선택 안 함';
  static const linkedTask = '연결할 할 일';
  static const noTask = '할 일 없이 시작';
  static const overdue = '밀린 일';
  static const today = '오늘';
  static const next = '다음 할 일';
  static const camera = '카메라 착석 감지';
  static const cameraBody = '자리를 비우면 타이머가 자동으로 멈춥니다';
  static const privacy =
      '카메라를 켜기 전에: 얼굴 이미지는 기기를 떠나지 않고, 판단 직후 즉시 폐기됩니다\n'
      '저장되는 것은 착석·이탈 시각과 길이뿐입니다\n'
      '언제든 수동 모드로 바꾸거나 감지를 끌 수 있습니다';
  static const manual = '수동';
  static const manualBody = '수동 모드에서는 시작·정지를 직접 눌러 순공시간을 기록합니다';
  static const permissionDenied = '카메라 권한이 꺼져 있어요. 지금은 수동 모드로 시작할 수 있습니다';
  static const settings = '설정에서 켜기';
  static const cameraBusy = '카메라를 다른 앱에서 사용 중입니다';
  static const unavailable = '카메라에 연결할 수 없습니다';
  static const toManual = '수동 타이머로';
  static const start = '시작하기';
  static const pause = '일시정지';
  static const resume = '이어서';
  static const end = '종료';
  static const lost = '측정이 중단되었습니다';
  static String lostBody(String recorded) =>
      '카메라 연결이 끊겼습니다. 지금까지 $recorded 순공이 기록돼 있고, 끊긴 뒤 시간은 세지 않았습니다.';
  static const reconnect = '다시 연결';
  static const reconnectFailed = '다시 연결하지 못했습니다 · 수동으로 이어가거나 종료하세요';
  static const manualContinue = '수동으로 이어서';
  static const awayTitle = '자리 비움을 감지했습니다';
  static const awayBody = '돌아와 앉으면 자동으로 다시 이어서 잽니다. 이 시간은 순공시간에서 빠집니다.';
  static String awayElapsed(String hms) => '비운 시간 $hms';
  static const longAway = '자리 비움이 5분을 넘었습니다';
  static const keepGoing = '계속하기';
  static const background = '다른 앱으로 이동하거나 화면을 끄면 측정을 일시정지합니다';
  static const pure = '순공시간';
  static String todayTotal(String total, int goalMinutes) =>
      '오늘 합계 $total · 하루 목표 $goalMinutes분';
  static const goalReached = '하루 목표 도달';
  static const save = '기록 저장';
  static const saving = '저장 중';
  static const saved = '기록을 저장했습니다';
  static const failed = '저장하지 못했습니다. 입력을 유지했습니다';
  static const retry = '다시 시도';
  static const loadFailed = '기록을 불러오지 못했습니다';
  static const checkpointFailed = '임시 기록을 저장하지 못했습니다';
  static const shortTitle = '3분 미만의 기록입니다';
  static const shortBody = '이 기록을 저장할까요?';
  static const discard = '기록 버리기';
  static const discardTitle = '이 기록을 버릴까요?';
  static String discardBody({
    required String seated,
    required int corrections,
    required bool linkedTask,
  }) =>
      '순공 $seated'
      '${corrections > 0 ? '과 되돌린 구간 $corrections건' : ''}'
      '이 저장되지 않고 임시 기록도 삭제됩니다.'
      '${linkedTask ? '\n연결된 할 일은 미완료로 남습니다.' : ''}';
  static const completeTask = '연결된 할 일 완료 처리';
  static const timeline = '착석·이탈 타임라인';
  static const correct = '구간 정정';
  static const restore = '순공으로 되돌리기';
  static const corrected = '정정됨';
  static const sensitivity = '감도를 조정했습니다';
  static const history = '정정 이력 보기';
  static const historyTitle = '정정 이력';
  static const emptyHistory = '아직 되돌린 구간이 없습니다';
  static const emptyHistoryBody =
      '집중 기록에서 자리 비움 구간을 탭해 "순공으로 되돌리기"를 누르면 여기에 쌓이고, 3건마다 감도가 조정됩니다.';
  static const pastRecords = '지난 기록 보기';
  static String sensitivityStatus(int thresholdSeconds, int recent) =>
      '현재 자리 비움 판정 $thresholdSeconds초 · 최근 2주 되돌림 $recent건';
  static String sensitivityManual(int thresholdSeconds) =>
      '자리 비움 판정 $thresholdSeconds초 · 자동 조정 꺼짐';
  static const edit = '기록 정정';
  static const saveChanges = '변경 저장';
  static const cancelChanges = '변경 취소';
  static const cancelTitle = '변경을 취소할까요?';
  static String cancelBody(int corrections, String seated) =>
      '되돌린 구간 $corrections건이 저장되지 않고 원래 기록(순공 $seated)이 그대로 유지됩니다.';
  static const delete = '기록 삭제';
  static const deleteBody = '이 세션과 구간·정정 기록을 삭제합니다. 5초 안에 되돌릴 수 있습니다';
  static const deleted = '기록을 삭제했습니다';
  static const undo = '되돌리기';
  static const home = '홈으로';
  static const viewSession = '저장한 기록 보기';
  static const existing = '마무리하지 않은 측정 기록이 있습니다';
  static const startFailed = '측정을 시작하지 못했습니다. 다시 시도해 주세요';
  static const finishRecord = '기록 마무리';
  static const missing = '표시할 기록이 없습니다';
  static const lowPower = '저전력 측정';
  static String minutes(int minutes) => '$minutes분';
  static String kind(SessionKind kind) => switch (kind) {
    SessionKind.study => '공부',
    SessionKind.todo => '할 일',
    SessionKind.self => '자습',
  };
  static String segment(SegmentKind kind) => switch (kind) {
    SegmentKind.seated => '착석',
    SegmentKind.away => '자리 비움 감지됨',
    SegmentKind.manual => manual,
    SegmentKind.paused => pause,
  };
}
