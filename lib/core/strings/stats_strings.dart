// Stats strings (S08, PRD 4.2 통계 · 4.3 오답 누적 · prototype 10 · userflow
// t1 · s11 · s12 · statsP · statsF · cross). Facts only: times, counts,
// dates. No evaluation, praise, pressure or ranking (CLAUDE.md §1).
// Checked by tool/check_forbidden_phrases.dart.

abstract final class StatsStrings {
  // Header
  static const String title = '통계';
  static const String periodWeek = '주간';
  static const String periodMonth = '월간';
  static const String prevWeek = '이전 주';
  static const String nextWeek = '다음 주';
  static const String prevMonth = '이전 달';
  static const String nextMonth = '다음 달';
  static const String goToday = '오늘';

  // Summary card
  static const String thisWeekSeated = '이번 주 순공시간';
  static const String lastWeekSeated = '지난주 순공시간';
  static String weekSeated(String range) => '$range 순공시간';
  static const String thisMonthSeated = '이번 달 순공시간';
  static String monthSeated(int year, int month) => '$year년 $month월 순공시간';
  static String weekRange(int m1, int d1, int m2, int d2) =>
      m1 == m2 ? '$m1월 $d1일 – $d2일' : '$m1월 $d1일 – $m2월 $d2일';
  static String monthRange(int month, int lastDay) => '$month월 1일 – $lastDay일';
  static String recordedDays(int n) => '기록일 $n일';
  static String dailyAverage(String hm) => '일평균 $hm';
  static const String noRecord = '기록 없음';

  // Week comparison (facts only)
  static String compareMore(String d) => '지난주 같은 요일까지 +$d';
  static String compareLess(String d) => '지난주 같은 요일까지 −$d';
  static const String compareSame = '지난주 같은 요일까지와 같음';
  static String compareFullMore(String d) => '지난주 대비 +$d';
  static String compareFullLess(String d) => '지난주 대비 −$d';
  static const String compareFullSame = '지난주와 같음';
  static const String compareNone = '비교할 지난주 기록 없음';

  // Bars
  static const String chartWeekSemantics = '요일별 순공 막대 · 과목색 분할';
  static const String chartMonthSemantics = '주차별 순공 막대 · 과목색 분할';
  static String weekOfMonth(int n) => '$n주';
  static String barValue(String label, String hm) => '$label · $hm';
  static const String futureDay = '아직 오지 않은 날';

  // Subjects
  static const String bySubject = '과목별';
  static String subjectTotal(String hm) => '합계 $hm';
  static String subjectSplit(String planned, String self) => '할 일 $planned / 자습 $self';
  static const String none = '없음';
  static String percent(int p) => '$p%';

  // Hours
  static const String hours = '시간대';
  static const String hoursSemantics = '0시부터 23시까지 시간대별 순공';
  static const List<String> hourBands = <String>['새벽·아침 05–09', '오전 09–12', '오후 12–18', '저녁 18–22', '밤 22–05'];
  static String hourLabel(int hour) => '$hour시';

  // Focus pattern (연속 착석 분포)
  static const String focus = '집중 패턴';
  static const String bucketUnder15 = '15분 미만';
  static const String bucket15To30 = '15–30분';
  static const String bucket30To60 = '30–60분';
  static const String bucketOver60 = '60분 이상';
  static String runs(int n) => '$n회';
  static String longestRun(String hm) => '가장 긴 연속 착석 $hm';
  static String averageSession(String hm) => '평균 세션 길이 $hm';
  static String sessionCount(int n) => '세션 $n회';
  static const String noRuns = '연속 착석 기록 없음';

  // Sparse (기록일 3일 미만, userflow s11) · loading (s12)
  static const String sparseTitle = '기록일이 3일 미만입니다';
  static const String sparseBody = '3일 이상 기록이 쌓이면 주간·월간 통계가 표시됩니다';
  static String sparseSoFar(String hm) => '지금까지 $hm';
  static const String sparseAction = '집중 시작';
  static const String loadFailed = '통계를 불러오지 못했습니다';

  // Wrongs section (PRD 4.3 A4 · A6 · 4.4 구독 종료)
  static const String wrongsTitle = '오답';
  static const String premiumBadge = '프리미엄';
  static const String seeAll = '전체 보기';
  static String wrongsOpen(int n) => '미해결 $n문항';
  static String wrongsResolved(int n) => '해결 $n문항';
  static const String thisWeek = '이번 주';
  static const String lastWeek = '지난주';
  static const String thisMonth = '이번 달';
  static String retriesIn(String range, int n) => '$range 재풀이 $n회';
  static String readingsIn(String range, int n) => '$range 판독 $n회';
  static String wrongsCount(int n) => '$n문항';
  static const String wrongsTeaserTitle = '틀린 문항이 여기에 모입니다';
  static const String wrongsTeaserBody = '채점 판독을 켜면 과목·범위별 오답과 시간 대비 비율이 여기에 표시됩니다';
  static const String wrongsEmptyTitle = '저장된 오답이 아직 없습니다';
  static const String wrongsEmptyBody = '채점 페이지를 판독해 저장하면 여기에 쌓입니다';
  static String wrongsExpired(int items, int ranges) => '오답 $items문항 · $ranges개 범위';
  static const String readOnly = '읽기 전용';
  static const String wrongsExpiredBody = '구독 종료 후 새 오답은 쌓이지 않습니다 · 재구독하면 이어집니다';
  static const String resubscribe = '재구독';
  static String viewExistingWrongs(int n) => '기존 오답 $n문항 보기';

  // Cross view (PRD 4.3 P1, hidden in v1)
  static const String crossHidden = '시간 대비 오답 비율은 4주 데이터가 쌓이면 표시됩니다';
}
