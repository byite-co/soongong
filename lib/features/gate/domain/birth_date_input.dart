// BirthDateInput (S05 · D6, pure Dart): client-side range check for the age
// gate wheels. The age decision itself is the server's (`age-check`); the
// client only rejects impossible dates (future, more than 150 years ago, a
// day that does not exist). The value lives in widget state only.

class BirthDateInput {
  const BirthDateInput({required this.year, required this.month, required this.day});

  final int year;
  final int month;
  final int day;

  static const int maxYearsBack = 150;

  /// Oldest selectable year for [today].
  static int minYear(DateTime today) => today.year - maxYearsBack;

  static int daysInMonth(int year, int month) => DateTime(year, month + 1, 0).day;

  /// Default wheel position: 1 January, 15 years before [today] (a neutral
  /// start above the v1 threshold; the user always picks their own date).
  static BirthDateInput initial(DateTime today) =>
      BirthDateInput(year: today.year - 15, month: 1, day: 1);

  BirthDateInput copyWith({int? year, int? month, int? day}) {
    final y = year ?? this.year;
    final m = month ?? this.month;
    final d = (day ?? this.day).clamp(1, daysInMonth(y, m));
    return BirthDateInput(year: y, month: m, day: d);
  }

  /// null when the date is impossible for [today] (local calendar).
  DateTime? validate(DateTime today) {
    if (month < 1 || month > 12) return null;
    if (day < 1 || day > daysInMonth(year, month)) return null;
    final date = DateTime(year, month, day);
    final todayDate = DateTime(today.year, today.month, today.day);
    if (date.isAfter(todayDate)) return null;
    if (year < minYear(today)) return null;
    return date;
  }

  @override
  String toString() => 'BirthDateInput(redacted)';
}
