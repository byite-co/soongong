// MonthGrid (S07, pure Dart): the 6-week × 7-day calendar grid of one month
// (PRD 4.2 "네이버 캘린더식 월간 격자"). Always 42 cells so the rows never
// jump between months; the first column is the user's week-start setting.

import '../../../core/domain/local_date.dart';

class MonthGrid {
  MonthGrid._({
    required this.year,
    required this.month,
    required this.weekStart,
    required this.days,
  });

  /// [weekStart] 1 = Monday … 7 = Sunday (settings `week_start`).
  factory MonthGrid.of(int year, int month, {required int weekStart}) {
    assert(month >= 1 && month <= 12, 'month 1..12');
    assert(weekStart >= 1 && weekStart <= 7, 'weekStart 1..7');
    final first = LocalDate(year, month, 1).startOfWeek(weekStart);
    return MonthGrid._(
      year: year,
      month: month,
      weekStart: weekStart,
      days: List<LocalDate>.unmodifiable(
        List<LocalDate>.generate(cellCount, first.addDays),
      ),
    );
  }

  static const int rows = 6;
  static const int columns = 7;
  static const int cellCount = rows * columns;

  final int year;
  final int month;
  final int weekStart;

  /// 42 consecutive local dates, row-major.
  final List<LocalDate> days;

  LocalDate get first => days.first;
  LocalDate get last => days.last;
  LocalDate get firstOfMonth => LocalDate(year, month, 1);
  LocalDate get lastOfMonth => LocalDate(year, month, daysInMonth(year, month));

  bool inMonth(LocalDate d) => d.year == year && d.month == month;

  bool contains(LocalDate d) => d >= first && d <= last;

  /// Row (0..5) of [d], or -1 when outside the grid.
  int rowOf(LocalDate d) => contains(d) ? first.daysUntil(d) ~/ columns : -1;

  /// Column (0..6) of [d], or -1 when outside the grid.
  int colOf(LocalDate d) => contains(d) ? first.daysUntil(d) % columns : -1;

  /// Index (0..41) of [d], or -1.
  int indexOf(LocalDate d) => contains(d) ? first.daysUntil(d) : -1;

  /// The 7 dates of [row].
  List<LocalDate> week(int row) => days.sublist(row * columns, row * columns + columns);

  /// Weekday (1 = Monday … 7 = Sunday) of each column.
  List<int> get columnWeekdays =>
      List<int>.generate(columns, (i) => (weekStart - 1 + i) % 7 + 1);

  MonthGrid previous() =>
      month == 1 ? MonthGrid.of(year - 1, 12, weekStart: weekStart) : MonthGrid.of(year, month - 1, weekStart: weekStart);

  MonthGrid next() =>
      month == 12 ? MonthGrid.of(year + 1, 1, weekStart: weekStart) : MonthGrid.of(year, month + 1, weekStart: weekStart);

  MonthGrid withWeekStart(int weekStart) => MonthGrid.of(year, month, weekStart: weekStart);

  static int daysInMonth(int year, int month) =>
      month == 12 ? 31 : LocalDate(year, month + 1, 1).addDays(-1).day;

  /// `yyyy-MM`.
  String get key => firstOfMonth.monthKey;

  @override
  bool operator ==(Object other) =>
      other is MonthGrid && other.year == year && other.month == month && other.weekStart == weekStart;

  @override
  int get hashCode => Object.hash(year, month, weekStart);

  @override
  String toString() => 'MonthGrid($key, weekStart $weekStart)';
}
