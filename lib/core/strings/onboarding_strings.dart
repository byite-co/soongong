// Onboarding strings (S05, PRD 4.4 · prototype 00). Fact-only wording.
// Checked by tool/check_forbidden_phrases.dart.

abstract final class OnboardingStrings {
  static String stepOf(int step) => '$step / 3';

  // 1 · 순공 측정 (camera = seated-or-not only, nothing stored)
  static const String step1Title = '앉아 있던 시간만\n잽니다';
  static const String step1Body =
      '전면 카메라가 "지금 자리에 있는가"만 판단합니다.\n자리를 비우면 타이머가 멈추고, 돌아오면 이어서 잽니다.';
  static const String step1Fact1 = '얼굴 이미지는 저장되지 않습니다';
  static const String step1Fact2 = '기기 안에서만 처리 · 서버 전송 없음';
  static const String step1Fact3 = '언제든 끄고 수동으로 기록 가능';
  static const String next = '다음';
  static const String skip = '건너뛰기';

  // 2 · 판독 동의 ② (D6: 보호자 동의 체크 없음 — v1 은 만 14세 이상만 가입)
  static const String step2Title = '채점한 페이지를 찍으면\n오답이 쌓입니다';
  static const String step2Body = '채점 표시(O·X·△)를 읽어 틀린 문항만 모아 둡니다.';
  static const String step2CardTitle = '이 기능만 사진이 기기 밖으로 나갑니다 · 30일 뒤 삭제';
  static const String step2CardSub = '얼굴은 찍지 않고, 학습에 쓰지 않습니다.';
  static const String step2Premium = '프리미엄';
  static const String consent1 = '채점한 페이지 사진이 외부 판독 서버로 전송됩니다.';
  static const String consent2 = '사진은 판독에만 쓰이고 학습에 쓰지 않습니다.';
  static const String consent3 = '사진은 30일 뒤 삭제되며, 동의는 설정에서 언제든 철회할 수 있습니다.';
  static const String consentCheck = '확인했습니다';
  static const String consentNext = '동의하고 다음';
  static const String consentRequired = '동의가 필요합니다';
  static const String consentSkip = '지금은 건너뛰기 (판독 기능 꺼짐)';
  static const String consentSaving = '저장 중…';
  static const String consentSaveFailed = '동의를 저장하지 못했습니다 · 입력은 그대로 있습니다';

  // 3 · 카메라 권한
  static const String step3Title = '카메라 권한이\n필요합니다';
  static const String step3Body =
      '착석 감지에만 쓰입니다.\n거부하면 수동 타이머로 시작하고, 설정에서 언제든 다시 켤 수 있습니다.';
  static const String cameraAllowStart = '카메라 허용하고 시작';
  static const String manualStart = '수동 타이머로 시작';
  static const String finishing = '저장 중…';
  static const String finishFailed = '온보딩 완료를 저장하지 못했습니다 · 다시 시도';
  static const String cameraDenied = '카메라 권한이 꺼져 있습니다 · 수동 타이머로 시작합니다';
}
