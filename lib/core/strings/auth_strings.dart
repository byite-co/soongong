// Auth strings (S03 → S05 screens). Fact-only wording — no evaluation, praise
// or pressure (CLAUDE.md §1). Checked by tool/check_forbidden_phrases.dart.

import '../../data/auth/auth_models.dart';

abstract final class AuthStrings {
  // Age gate (D6)
  static const String ageGateTitle = '생년월일을 입력하세요';
  static const String ageGateHelp = '만 14세 이상만 가입할 수 있습니다. 생년월일은 확인 후 저장하지 않습니다.';
  static const String ageBlockedTitle = '지금은 가입할 수 없습니다';
  static const String ageBlockedBody = '만 14세 이상만 가입할 수 있습니다.';

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
