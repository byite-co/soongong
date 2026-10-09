// Timetable strings (S08, PRD 4.2 · prototype 14 · userflow tt · t6 ·
// evEdit · evScope). Facts only: times, dates, counts. No evaluation,
// praise or pressure (CLAUDE.md §1). Checked by
// tool/check_forbidden_phrases.dart.

import 'planner_strings.dart';

abstract final class TimetableStrings {
  // Header
  static const String title = '타임테이블';
  static const String prevWeek = '이전 주';
  static const String nextWeek = '다음 주';
  static const String thisWeek = '이번 주';

  /// `8월 17일 – 23일` (same month) · `9월 28일 – 10월 4일`.
  static String weekRange(int m1, int d1, int m2, int d2) =>
      m1 == m2 ? '$m1월 $d1일 – $d2일' : '$m1월 $d1일 – $m2월 $d2일';
  static String weekSeated(String hm) => '순공 $hm';

  // Grid
  static String weekdayOf(int weekday) => PlannerStrings.weekdayOf(weekday);
  static String hourLabel(int hour) => hour.toString().padLeft(2, '0');
  static const String today = '오늘';
  static const String nowLine = '현재 시각';
  static const String legendSeated = '순공';
  static const String legendSelf = '자습';
  static const String legendRecurrence = '학원·수업';
  static const String legendToday = '오늘';
  static const String blockSelf = '자습';
  static const String blockStudy = '순공';
  static String blockSemantics(String name, String start, String end, String hm) =>
      '$name · $start–$end · $hm';
  static String recurrenceSemantics(String title, String start, String end) =>
      '$title · $start–$end · 반복 일정';
  static String daySemantics(String date, String hm) => '$date · 순공 $hm';

  // Empty state (prototype `ttEmpty`)
  static const String emptyTitle = '이번 주 기록이 아직 없습니다';
  static const String emptyBody =
      '집중을 시작하면 순공 블록이 요일·시간 자리에 그려집니다.\n학원·수업은 플래너에서 반복 일정으로 넣어 두세요.';
  static const String emptyStart = '집중 시작';
  static const String emptyAddRecurrence = '반복 일정 추가';

  // Recurrences section
  static const String recurrencesTitle = '반복 일정';
  static const String addInPlanner = '플래너에서 추가';
  static String recurrenceSummary(String days, String start, String end) => '매주 $days · $start–$end';
  static const String recurrencesEmpty =
      '학원·수업 같은 반복 일정을 플래너에서 추가하면 여기와 홈 타임라인에 자동으로 표시됩니다';
  static const String editRecurrence = '반복 일정 수정';
  static const String deleteRecurrence = '반복 일정 삭제';

  // evScope — whole-recurrence delete (v1 has no per-week exceptions)
  static const String deleteTitle = '반복 일정을 지울까요?';
  static const String deleteBody = '이 반복 일정이 지난 주를 포함해 모든 주에서 사라집니다.\n5초 안에 되돌릴 수 있습니다.';
  static const String deleteAll = '전체 삭제';
  static String deletedAll(String title) => '"$title" 반복 일정을 모두 지웠습니다';
  static String changedAll(String title) => '"$title" 반복 일정을 모두 바꿨습니다';
  static const String restored = '되돌렸습니다';
  static const String deleteFailed = '삭제하지 못했습니다';

  // States
  static const String loadFailed = '타임테이블을 불러오지 못했습니다';
}
