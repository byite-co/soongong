// Auth strings (S03 → S05 screens: gate · login · consent ① · reset).
// Fact-only wording — no evaluation, praise or pressure (CLAUDE.md §1).
// Checked by tool/check_forbidden_phrases.dart.

import '../../data/auth/auth_models.dart';

abstract final class AuthStrings {
  // Age gate (D6)
  static const String ageGateTitle = '생년월일을 입력하세요';
  static const String ageGateHelp = '만 14세 이상만 가입할 수 있습니다. 생년월일은 확인 후 저장하지 않습니다.';
  static const String ageGateYear = '년';
  static const String ageGateMonth = '월';
  static const String ageGateDay = '일';
  static const String ageGateContinue = '계속';
  static const String ageGateChecking = '확인 중…';
  static const String ageGateInvalidDate = '생년월일을 확인하세요';
  static const String ageGateHaveAccount = '이미 계정이 있어요';
  static const String ageGateLogin = '로그인';
  static const String ageGateExpiredRetry = '가입 확인이 만료됐습니다 · 다시 시도';
  static const String ageGateVerified = '생년월일을 확인했습니다 · 가입할 방법을 고르세요';
  static const String ageBlockedTitle = '지금은 가입할 수 없습니다';
  static const String ageBlockedBody = '만 14세 이상만 가입할 수 있습니다.';
  static const String backendMissing = '서버 설정이 없는 빌드입니다';

  // Login (00a)
  static const String loginTagline = '앉아 있던 시간만\n정직하게 잽니다';
  static const String loginSub = '기록은 계정에 저장되어 기기를 바꿔도 이어집니다.';
  static const String loginApple = 'Apple로 계속';
  static const String loginGoogle = 'Google로 계속';
  static const String loginKakao = '카카오로 계속';
  static const String loginEmail = '이메일로 계속';
  static const String loginTerms = '계속하면 이용약관과 개인정보 처리방침에 동의하는 것입니다.';
  static const String loginTitle = '로그인';
  static const String loginSignupTitle = '계정 만들기';
  static const String loginNewAccount = '처음이에요 · 계정 만들기';
  static const String loginBusy = '로그인 중';
  static String loginChecking(String provider) => '$provider 확인 중';
  static const String loginProviderFailed = '로그인을 마치지 못했습니다 · 다시 시도하거나 다른 방법을 고르세요';
  static const String loginProviderUnavailable = '이 빌드에서는 쓸 수 없는 로그인 방법입니다';
  static const String providerApple = 'Apple';
  static const String providerGoogle = 'Google';
  static const String providerKakao = '카카오';

  // Email flow (lgEmail · lgPw · lgSignup · lgReset)
  static const String emailTitle = '이메일로 계속';
  static const String emailSub = '기록을 저장할 이메일을 입력하세요.';
  static const String emailLabel = '이메일';
  static const String emailHint = 'name@example.com';
  static const String emailFoot = '처음이면 계정을 새로 만들고, 있으면 비밀번호를 묻습니다.';
  static const String emailInvalid = '이메일 형식을 확인하세요';
  static const String passwordTitle = '비밀번호';
  static String passwordSubExisting(String email) => '$email로 로그인합니다.';
  static const String passwordLabel = '비밀번호';
  static const String passwordHint = '8자 이상';
  static const String passwordForgot = '비밀번호를 잊었어요';
  static String signupSub(String email) => '$email 계정을 새로 만듭니다.';
  static const String signupNewEmailNote = '처음 쓰는 이메일입니다. 이 비밀번호로 계정을 만듭니다.';
  static const String signupCta = '계정 만들고 시작';
  static String resetSentTo(String email) =>
      '재설정 링크를 $email로 보냈습니다.\n메일의 링크로 새 비밀번호를 정한 뒤 다시 로그인하세요.';
  static const String resetSendFailed = '재설정 메일을 보내지 못했습니다 · 다시 시도';

  // New password (/auth/reset)
  static const String resetTitle = '새 비밀번호';
  static const String resetSub = '새 비밀번호를 정하면 로그인된 상태로 이어집니다.';
  static const String resetCta = '비밀번호 바꾸기';
  static const String resetDone = '비밀번호를 바꿨습니다';
  static const String resetLinkInvalid = '재설정 링크를 확인하지 못했습니다 · 재설정 메일을 다시 요청하세요';
  static const String resetRequestAgain = '재설정 메일 다시 요청';
  static const String resetChecking = '링크 확인 중…';

  // Consent ① (/signup/complete)
  static const String consentAccountIntro = '계정을 만들려면 아래 처리에 동의가 필요합니다.';
  static const String consentAccountItem1 = '세션·플래너·오답 기록이 계정에 저장되어 기기를 바꿔도 이어집니다.';
  static const String consentAccountItem2 = '생년월일은 확인 즉시 폐기되며 어디에도 저장되지 않습니다.';
  static const String consentAccountItem3 = '판독 사진은 이 기기에만 30일 보관되고 계정에는 저장되지 않습니다.';
  static const String consentAccountCheck = '확인했습니다';
  static const String consentAccountCta = '동의하고 시작';
  static const String consentAccountRequired = '동의가 필요합니다';
  static String consentVersionLabel(String version) => '동의 문구 버전 $version';
  static const String consentSwitchAccount = '다른 계정으로 로그인';

  // Launch (/) — profile read failed
  static const String profileLoadFailedTitle = '계정 정보를 불러오지 못했습니다';

  // Post-login (PRD 4.3c: 첫 불러오기 결과 토스트 1줄)
  static String loadedSummary(int sessions, int wrongs) => '기록 $sessions세션 · 오답 $wrongs문항을 불러왔습니다';

  // Consent
  static const String consentAccountTitle = '계정·학습 기록 처리 동의';
  static const String consentReadingTitle = '사진 외부 판독 전송 동의';

  // Rejections (AuthRejection → one sentence, input is kept)
  static const String rejectSignupPassRequired = '가입 확인이 필요합니다 · 생년월일 확인부터 다시 진행합니다';
  static const String rejectNotApproved = '가입 확인 기록이 없습니다 · 처음부터 다시 가입하세요';
  static const String rejectTicketInvalid = '확인 시간이 지났습니다 · 생년월일을 다시 입력하세요';
  static const String rejectIdTokenInvalid = '로그인 정보를 확인하지 못했습니다 · 다시 시도하세요';
  static const String rejectInvalidCredentials = '이메일 또는 비밀번호가 맞지 않습니다';
  static const String rejectEmailTaken = '이미 가입된 이메일입니다 · 로그인으로 이어집니다';
  static const String rejectWeakPassword = '비밀번호는 8자 이상이어야 합니다';
  static const String rejectRateLimited = '요청이 많습니다 · 잠시 후 다시 시도하세요';
  static const String rejectNetwork = '인터넷 연결이 없습니다 · 연결 후 다시 시도하세요';
  static const String rejectUnknown = '로그인하지 못했습니다 · 다시 시도하세요';

  static String forRejection(AuthRejection r) => switch (r) {
        AuthRejection.signupPassRequired => rejectSignupPassRequired,
        AuthRejection.notApproved => rejectNotApproved,
        AuthRejection.ticketInvalid => rejectTicketInvalid,
        AuthRejection.idTokenInvalid => rejectIdTokenInvalid,
        AuthRejection.invalidCredentials => rejectInvalidCredentials,
        AuthRejection.emailTaken => rejectEmailTaken,
        AuthRejection.weakPassword => rejectWeakPassword,
        AuthRejection.rateLimited => rejectRateLimited,
        AuthRejection.network => rejectNetwork,
        AuthRejection.unknown => rejectUnknown,
      };

  // Account (PRD 4.3c)
  static const String signOutConfirm = '기록은 계정에 남습니다 · 이 기기의 판독 사진은 삭제됩니다';
  static const String deleteAccountConfirm = '동기화된 기록 전체가 삭제됩니다 · 구독은 스토어에서 별도로 해지합니다';
  static const String passwordResetSent = '재설정 링크를 보냈습니다 · 메일함을 확인하세요';
}
