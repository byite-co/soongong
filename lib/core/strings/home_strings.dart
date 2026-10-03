// Home strings (S05, PRD 4.2 홈 · prototype 01). Facts only: time, counts,
// dates. No evaluation. Checked by tool/check_forbidden_phrases.dart.

abstract final class HomeStrings {
  static const String today = '오늘';
  static const String settings = '설정';
  static const String studyTime = '순공시간';
  static const String emptyHint = '집중을 시작하면 여기에 쌓입니다';
  static const String sameAsYesterday = '어제와 같음';
  static String moreThanYesterday(String duration) => '어제보다 +$duration';
  static String lessThanYesterday(String duration) => '어제보다 −$duration';
  static String remainingTodos(int n) => '남은 할 일 $n개';
  static const String noTodosLeft = '남은 할 일 없음';
  static const String startFocus = '지금 집중 시작';
  static const String todayTodos = '오늘 할 일';
  static String doneOfTotal(int done, int total) => '$done/$total';
  static const String plannerLink = '플래너';
  static const String todosEmpty = '오늘 계획한 일이 없어요';
  static const String addTodo = '할 일 추가';
  static String streakDays(int n) => '$n일 연속';
  static const String selfStudy = '자습';
  static const String todayEventsNone = '오늘 일정 없음';
  static String todayEvents(String list) => '오늘 일정 · $list';
  static const String ringSemantics = '오늘 24시간 링 · 순공 파랑 · 자습 주황 · 반복 일정 바깥 링';
  static const String toggleDone = '완료 토글';
  static const String saveFailedRetry = '저장하지 못했습니다 · 다시 시도';

  // Session recovery (PRD 4.1 · D23)
  static const String recoverTitle = '종료되지 않은 세션이 있습니다';
  static String recoverBody(String startedAt, String recorded) =>
      '$startedAt에 시작해 $recorded이 기록된 뒤 앱이 종료됐습니다. 그 뒤 시간은 세지 않았습니다.';
  static const String recoverResume = '이어서 집중하기';
  static const String recoverFinish = '여기까지 기록 마무리';
  static const String recoverDiscard = '기록 버리기';
  static const String recoverKept = '미완료 세션은 그대로 두었습니다 · 다음 실행 때 다시 묻습니다';
  static const String recoverDiscardTitle = '기록을 버릴까요?';
  static String recoverDiscardBody(String recorded) => '$recorded의 기록이 삭제됩니다. 되돌릴 수 없습니다.';
  static String recoverDiscarded(String recorded) => '미완료 세션 $recorded을 버렸습니다';
  static String recoverFinished(String recorded) => '$recorded을 기록했습니다';
  static const String recoverFailed = '처리하지 못했습니다 · 다시 시도';
  static const String yesterday = '어제';

  // Dates (local)
  static const List<String> weekdayNames = <String>['월요일', '화요일', '수요일', '목요일', '금요일', '토요일', '일요일'];
  static String fullDate(int year, int month, int day, int weekday) =>
      '$year년 $month월 $day일 ${weekdayNames[weekday - 1]}';
  static String monthDay(int month, int day) => '$month월 $day일';
}
