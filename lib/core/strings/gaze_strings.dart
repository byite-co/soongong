import '../../features/measure/domain/gaze_observation.dart';

abstract final class GazeStrings {
  static const title = '시선 관측 실험';
  static const description = '기기에서 눈의 방향 변화를 관측합니다. 종이를 보는 자세와 휴대폰을 보는 자세마다 다시 보정하세요. 집중 상태를 판정하거나 순공시간에 반영하지 않습니다.';
  static const consent = '카메라의 일시적인 사용에 동의합니다. 영상과 좌표는 저장하거나 전송하지 않습니다.';
  static const start = '관측 시작';
  static const stop = '관측 종료';
  static const calibrate = '지금 보는 위치로 보정';
  static const unavailable = '관측을 시작할 수 없습니다. 권한과 기기 지원 상태를 확인해주세요.';
  static const releaseFailed = '카메라 종료를 확인하지 못했습니다. 앱을 다시 시작해주세요.';
  static const measuring = '시간 측정을 마친 뒤 사용할 수 있습니다.';
  static String state(GazeState state) => switch (state) {
    GazeState.unknown => '관측 불가',
    GazeState.uncalibrated => '보정 필요',
    GazeState.calibrating => '같은 위치를 바라보며 보정 중',
    GazeState.reference => '보정한 방향 부근',
    GazeState.outside => '보정한 방향에서 벗어남',
  };
}
