// Planner strings (S07, PRD 4.2 · prototype 08/09 "Planner Naver Style").
// Facts only: times, counts, dates. No evaluation, praise or pressure
// (CLAUDE.md §1). Checked by tool/check_forbidden_phrases.dart.

abstract final class PlannerStrings {
  // Header
  static const String title = '플래너';
  static String monthTitle(int year, int month) => '$year. $month.';
  static const String prevMonth = '이전 달';
  static const String nextMonth = '다음 달';
  static const String goToday = '오늘';
  static String planned(int done, int total) => '계획 $done/$total';
  static const String toggle3d = '순공 3D';
  static const String legendSeated = '순공 · 높이 = 시간';
  static const String legendPlanned = '계획(예정)';
  static const String legendToday = '오늘';
  static const String suggest = '제안';

  // Weekday headers (Sunday first: index 0 = 일 … 6 = 토)
  static const List<String> weekdayShort = <String>['일', '월', '화', '수', '목', '금', '토'];

  /// 0 = Monday … 6 = Sunday for `DateTime.weekday - 1`.
  static String weekdayOf(int weekday) => weekdayShort[weekday % 7];

  // Grid
  static String more(int n) => '+$n';
  static const String today = '오늘';
  static String cellSemantics(String date, int items, String seated) =>
      '$date · 항목 $items개 · 순공 $seated';
  static const String fold = '주 단위로 접기';
  static const String unfold = '월 전체 보기';

  // Day detail
  static String dayTitle(int month, int day, String weekday) => '$month. $day. $weekday';
  static String seatedSummary(String hm) => '순공 $hm';
  static const String noRecord = '기록 없음';
  static String plannedCount(int n) => '계획 $n개';
  static const String sectionStudy = '공부';
  static String studyPlanned(int minutes) => '계획 $minutes분';
  static String studyPlannedActual(int planned, int actual) => '계획 $planned분 → 실제 $actual분';
  static String studyActual(int actual) => '실제 $actual분';
  static const String sectionTodo = '할 일';
  static const String sectionSelf = '추가 자습';
  static String selfSum(int minutes) => '$minutes분';
  static const String sectionEvents = '일정';
  static const String empty = '계획이 없습니다.';
  static const String emptyAction = '추가하기';
  static const String captureSemantics = '채점 페이지 촬영';
  static const String captureHint = '채점한 페이지를 찍으면 오답이 이 할 일에 쌓입니다';
  static const String captureHintLocked = '채점 판독은 프리미엄 기능입니다';
  static String recordMinutes(int minutes) => '기록 $minutes분';
  static String recordCount(int n) => '기록 $n건';
  static const String sessionDetail = '세션 상세';
  static const String sessionsTitle = '연결된 기록';
  static String targetMinutes(int minutes) => '$minutes분';
  static String recurrenceTime(String start, String end) => '$start–$end';
  static const String toggleDone = '완료';
  static String bandRange(String from, String to) => '$from – $to';
  static const String add = '추가';

  // Sheet — titles
  static const String sheetAdd = '추가';
  static const String sheetAddSelf = '자습 추가';
  static const String sheetAddEvent = '일정 추가';
  static const String sheetEdit = '수정';
  static const String sheetEditBand = '기간 일정 수정';
  static const String sheetEditRecurrence = '반복 일정 수정';

  // Sheet — kinds
  static const String kindStudy = '공부';
  static const String kindTodo = '할 일';
  static const String kindSelf = '추가 자습';
  static const String kindEvent = '일정';
  static const String hintStudy = '계획한 공부. 과목·목표 시간을 두고 집중 기록과 묶입니다.';
  static const String hintStudyLocked = '하기로 한 공부. 과목을 정해 두면 집중 기록과 묶입니다.';
  static const String hintTodo = '체크만 하는 일. 시간을 재지 않습니다.';
  static const String hintSelf = '계획에 없던 공부. 추가해 두고 집중을 시작하면 그 시간이 자습으로 기록됩니다.';
  static const String hintEvent = '시험 기간·학원처럼 여러 날에 걸친 일. 달력 위 띠나 요일 반복으로 들어갑니다.';
  static const String placeholderStudy = '무엇을 공부할까요?';
  static const String placeholderTodo = '무엇을 해야 하나요?';
  static const String placeholderSelf = '무엇을 더 공부할까요?';
  static const String placeholderEvent = '예: 중간고사 · 수학 학원';
  static const String titleLabel = '제목';

  // Sheet — subject
  static const String subject = '과목';
  static const String noSubject = '과목 없음';
  static const String addSubject = '과목 추가';
  static const String subjectNamePlaceholder = '과목 이름 (예: 한국사)';
  static const String subjectColor = '색';
  static const String subjectAddConfirm = '추가';
  static const String subjectNameEmpty = '과목 이름을 입력하세요';

  // Sheet — range · target
  static const String range = '범위 (선택)';
  static const String rangePlaceholder = '예: p.10–20 · 3단원';
  static String rangeCount(int n, int max) => '$n/$max';
  static const String target = '목표 시간';
  static const String targetCustom = '직접 입력';
  static const String targetCustomUnit = '분';
  static String expected(String subject, int minutes) => '예상 시간 · 최근 $subject 5회 평균 $minutes분';
  static const String expectedBasis = '기록으로 계산';
  static const String expectedFirst = '첫 기록 · 30분으로 시작';
  static const String expectedLocked = '예상 시간은 기록으로 자동 계산';
  static const String premium = '프리미엄';

  // Sheet — date
  static String dateButton(int month, int day) => '$month월 $day일';
  static String dateButtonToday(int month, int day) => '$month월 $day일 (오늘)';
  static String pickerMonth(int year, int month) => '$year년 $month월';
  static const String pickerToday = '오늘';
  static const String pickerTomorrow = '내일';
  static const String pickerPrev = '이전 달';
  static const String pickerNext = '다음 달';

  // Sheet — event
  static const String eventKind = '종류';
  static const String eventPeriod = '기간 (시험·행사)';
  static const String eventRepeat = '반복 (학원·수업)';
  static const String periodStart = '시작';
  static const String periodEnd = '끝';
  static String periodLength(int days) => '$days일간 · 달력 위에 띠로 표시됩니다';
  static const String dayBefore = '하루 앞';
  static const String dayAfter = '하루 뒤';
  static const String halfHourBefore = '30분 앞';
  static const String halfHourAfter = '30분 뒤';
  static const String repeatEnd = '종료';
  static const String repeatEndNever = '계속';
  static const String repeatEndMonth = '이달까지';
  static const String repeatEndDate = '날짜 지정';
  static String repeatSummary(String days, String start, String end) =>
      '매주 $days $start–$end · 홈·타임테이블에 자동 표시';
  static const String repeatPickDays = '요일을 골라주세요';
  static const String repeatWholeOnly = '반복 일정은 전체에 적용됩니다 · 이번 주만 바꾸기는 지원하지 않습니다';

  // Sheet — buttons
  static const String btnAdd = '추가하기';
  static const String btnAddSelf = '자습 추가하기';
  static const String btnAddPeriod = '기간 추가하기';
  static const String btnAddRepeat = '반복 일정 추가하기';
  static const String btnSave = '저장';
  static const String btnSaving = '저장 중…';
  static const String deleteItem = '이 항목 삭제';
  static const String deleteBand = '이 기간 일정 삭제';
  static const String deleteRecurrence = '이 반복 일정 삭제';

  // Validation (fact)
  static const String titleEmpty = '제목을 입력하세요';
  static String rangeTooLong(int max) => '범위는 $max자까지입니다';
  static const String targetInvalid = '목표 시간은 1분 이상이어야 합니다';
  static const String bandOrder = '끝 날짜는 시작보다 앞설 수 없습니다';
  static const String noWeekday = '요일을 골라주세요';
  static const String timeOrder = '끝 시각은 시작보다 뒤여야 합니다';

  // Confirmations
  static const String discardTitle = '작성 중인 내용을 버릴까요?';
  static const String discardBody = '입력한 제목과 설정이 저장되지 않습니다.';
  static const String discardKeep = '계속 작성';
  static const String discardDo = '버리기';
  static const String cancelEditTitle = '변경을 취소할까요?';
  static const String cancelEditBody = '바꾼 제목·과목·시간·날짜가 저장되지 않고 원래 항목이 그대로 남습니다.';
  static const String cancelEditKeep = '계속 수정';
  static const String cancelEditDo = '변경 취소';
  static const String deleteItemTitle = '이 항목을 지울까요?';
  static const String deleteItemBody = '연결된 집중 기록은 남고, 이 항목만 플래너에서 사라집니다. 5초 안에 되돌릴 수 있습니다.';
  static const String deleteBandTitle = '이 기간 일정을 지울까요?';
  static const String deleteBandBody = '달력 위의 띠가 사라집니다. 5초 안에 되돌릴 수 있습니다.';
  static const String deleteRecurrenceTitle = '이 반복 일정을 지울까요?';
  static const String deleteRecurrenceBody =
      '모든 요일의 반복이 함께 사라집니다(전체 삭제). 홈 링과 타임테이블에서도 빠집니다. 5초 안에 되돌릴 수 있습니다.';

  // Toasts · states
  static const String added = '추가했습니다';
  static const String saved = '저장했습니다';
  static const String deleted = '삭제했습니다';
  static const String restored = '되돌렸습니다';
  static const String saveFailed = '저장하지 못했습니다 · 입력은 그대로 있습니다';
  static const String deleteFailed = '삭제하지 못했습니다';
  static const String loadFailed = '플래너를 불러오지 못했습니다';
  static const String doneFailed = '저장하지 못했습니다 · 다시 시도';

  // Time formatting
  static String hm(int seconds) {
    final m = seconds ~/ 60;
    final h = m ~/ 60;
    final mm = m % 60;
    if (h == 0) return '$mm분';
    return mm == 0 ? '$h시간' : '$h시간 $mm분';
  }
}
