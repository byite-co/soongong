// Help strings (S09, PRD 4.4 도움말 · 문의 예외 · prototype N4 · N-문의 전송
// 실패). FAQ answers state what the app actually does (S02–S08 rules) —
// facts only. Checked by tool/check_forbidden_phrases.dart.

class FaqEntry {
  const FaqEntry(this.question, this.answer);

  final String question;
  final String answer;
}

abstract final class HelpStrings {
  static const String title = '도움말 · 문의';
  static const String faqTitle = '자주 묻는 질문';
  static const List<FaqEntry> faq = <FaqEntry>[
    FaqEntry(
      '구독은 어디에 저장되나요?',
      '로그인 계정에 묶여 있어 기기를 바꿔도 로그인만 하면 이어집니다. 해지해도 종료일까지 판독을 쓸 수 있고, 쌓인 오답은 읽기 전용으로 남습니다. 순공 측정·플래너·타임테이블·통계는 계속 무료입니다.',
    ),
    FaqEntry(
      '판독 횟수는 언제 초기화되나요?',
      '매달 1일에 20회로 채워지고 잔여분은 이월되지 않습니다. 여러 페이지를 한 번에 요청하면 1회로 칩니다. 실패한 판독은 횟수를 쓰지 않습니다.',
    ),
    FaqEntry(
      '앱이 저장하는 정보는 무엇인가요?',
      '세션·이탈·정정, 플래너, 오답·복습·재풀이, 과목·설정, 계정(이메일·구독 상태·동기화 시각)이 전부입니다. 영상·위치·연락처·생년월일은 저장하지 않습니다. 판독 사진만 이 기기에 30일 보관됩니다.',
    ),
    FaqEntry(
      '정정하면 통계에 어떻게 반영되나요?',
      '되돌린 구간의 시간은 순공에 그대로 더해지고 통계에 정정 표시는 남지 않습니다. 최근 2주의 정정 3건마다 감도가 한 단계 조정됩니다.',
    ),
    FaqEntry(
      '과목 색은 어디에 쓰이나요?',
      '플래너·타임테이블·통계·오답 표시에 쓰이고 두 과목이 같은 색을 쓸 수 없습니다. 8색 모두 색각 이상 검증을 거친 조합이며 색 옆에는 항상 이름이 함께 보입니다.',
    ),
    FaqEntry(
      '알림은 어떤 것이 오나요?',
      '복습 큐 시각 알림과 반복 일정 10분 전 알림 두 가지뿐입니다. 공부를 재촉하거나 결과를 평가하는 알림은 없습니다.',
    ),
    FaqEntry(
      '주 시작 요일을 바꾸면?',
      '플래너·타임테이블·통계의 주 구분이 함께 바뀝니다.',
    ),
    FaqEntry(
      '카메라가 자리 비움을 잘못 잡아요',
      '집중 기록에서 자리 비움 구간을 되돌리면 감도가 자동으로 조정됩니다. 카메라는 책상 위 45도, 얼굴이 아닌 손·책이 보이게 두면 됩니다.',
    ),
    FaqEntry(
      '사진은 어디에 저장되나요?',
      '판독을 위해 외부 AI로 전송되고, 자사 서버에서는 처리 직후, 이 기기에서는 30일 뒤 삭제됩니다. 계정에는 올라가지 않습니다. 오답 기록은 사진 없이 남습니다.',
    ),
    FaqEntry(
      '무료로 쓸 수 있는 건 무엇인가요?',
      '순공 측정·플래너·타임테이블·통계·하루 목표 시간은 계속 무료입니다. 사진 판독과 오답·복습, 기록 기반 예상 시간만 프리미엄입니다.',
    ),
    FaqEntry(
      '기록을 다른 기기로 옮길 수 있나요?',
      '기록은 계정에 동기화되어 새 기기에서 로그인하면 그대로 보입니다. 사진은 기기에만 있어 옮겨지지 않습니다. 카메라와 개인정보 › 내 기록 내보내기로 CSV·JSON 파일을 따로 보관할 수 있습니다.',
    ),
  ];

  // Inquiry
  static const String inquiryTitle = '문의';
  static const List<String> kinds = <String>['오류', '제안', '결제', '기타'];
  static const String bodyLabel = '내용';
  static const String bodyPlaceholder = '무엇이 불편했는지 적어 주세요.\n최근 7일 기록 요약이 함께 전송됩니다 (사진 제외).';
  static const int bodyMaxLength = 2000;
  static const String replyEmailLabel = '답장 받을 이메일 (선택)';
  static const String replyEmailHint = '비워 두면 로그인 이메일로 답장합니다';
  static const String replyEmailLocalHint = '계정이 없어 이걸로만 답장합니다';
  static const String replyEmailInvalid = '이메일 형식을 확인하세요';
  static const String bodyEmpty = '내용을 입력하세요';
  static const String send = '보내기';
  static const String sending = '보내는 중…';
  static const String resend = '다시 보내기';
  static const String sent = '보냈습니다 · 보통 하루 안에 답장합니다';
  static const String sendFailed =
      '전송에 실패했습니다. 작성한 내용은 그대로 남아 있으니 연결을 확인하고 다시 보내 주세요. 계속 실패하면 아래 주소로 메일 앱에서 보낼 수 있습니다.';
  static const String sendRateLimited = '오늘 보낼 수 있는 문의 수(10건)를 넘었습니다 · 내일 다시 보낼 수 있습니다';
  static const String supportEmail = 'help@soongong.app';
  static const String replyTime = '보통 하루 안에 답장합니다';
  static String summaryLine(int sessions, String seated, String platform, String version) =>
      '최근 7일 · 세션 $sessions회 · 순공 $seated · $platform · 순공 $version';
  static String bodyWithKind(String kind, String body) => '[$kind] $body';
}
