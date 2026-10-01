// LocalDate / LocalTime value types (S02, pure Dart). Date keys are local
// `yyyy-MM-dd`, times of day `HH:mm` (docs/data-model.md §0).

class LocalDate implements Comparable<LocalDate> {
  const LocalDate(this.year, this.month, this.day);

  /// Local calendar date of [t] (converted to local time first).
  factory LocalDate.of(DateTime t) {
    final l = t.isUtc ? t.toLocal() : t;
    return LocalDate(l.year, l.month, l.day);
  }

  /// Parses `yyyy-MM-dd`.
  factory LocalDate.parse(String key) {
    final m = _re.firstMatch(key);
    if (m == null) throw FormatException('LocalDate: $key');
    return LocalDate(
      int.parse(m.group(1)!),
      int.parse(m.group(2)!),
      int.parse(m.group(3)!),
    );
  }

  static LocalDate? tryParse(String? key) {
    if (key == null) return null;
    try {
      return LocalDate.parse(key);
    } on FormatException {
      return null;
    }
  }

  static final RegExp _re = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$');

  final int year;
  final int month;
  final int day;

  /// `yyyy-MM-dd`.
  String get key => '$year-${_two(month)}-${_two(day)}';

  /// Local midnight.
  DateTime toDateTime() => DateTime(year, month, day);

  /// 1 = Monday … 7 = Sunday (ISO, same as `DateTime.weekday`).
  int get weekday => toDateTime().weekday;

  LocalDate addDays(int days) => LocalDate.of(DateTime(year, month, day + days));

  /// Calendar-day difference (independent of DST: computed on UTC dates).
  int daysUntil(LocalDate other) =>
      DateTime.utc(other.year, other.month, other.day)
          .difference(DateTime.utc(year, month, day))
          .inDays;

  bool isBefore(LocalDate o) => compareTo(o) < 0;
  bool isAfter(LocalDate o) => compareTo(o) > 0;
  bool operator <=(LocalDate o) => compareTo(o) <= 0;
  bool operator >=(LocalDate o) => compareTo(o) >= 0;

  /// First day of the week containing this date, [weekStart] = 1 (Mon) … 7.
  LocalDate startOfWeek(int weekStart) {
    final diff = (weekday - weekStart + 7) % 7;
    return addDays(-diff);
  }

  LocalDate get startOfMonth => LocalDate(year, month, 1);

  /// `yyyy-MM`.
  String get monthKey => '$year-${_two(month)}';

  @override
  int compareTo(LocalDate other) {
    if (year != other.year) return year.compareTo(other.year);
    if (month != other.month) return month.compareTo(other.month);
    return day.compareTo(other.day);
  }

  @override
  bool operator ==(Object other) =>
      other is LocalDate &&
      other.year == year &&
      other.month == month &&
      other.day == day;

  @override
  int get hashCode => Object.hash(year, month, day);

  @override
  String toString() => key;
}

class LocalTime implements Comparable<LocalTime> {
  const LocalTime(this.hour, this.minute)
      : assert(hour >= 0 && hour < 24),
        assert(minute >= 0 && minute < 60);

  factory LocalTime.of(DateTime t) {
    final l = t.isUtc ? t.toLocal() : t;
    return LocalTime(l.hour, l.minute);
  }

  /// Parses `HH:mm`.
  factory LocalTime.parse(String s) {
    final m = _re.firstMatch(s);
    if (m == null) throw FormatException('LocalTime: $s');
    return LocalTime(int.parse(m.group(1)!), int.parse(m.group(2)!));
  }

  static LocalTime? tryParse(String? s) {
    if (s == null) return null;
    try {
      return LocalTime.parse(s);
    } on FormatException {
      return null;
    }
  }

  static final RegExp _re = RegExp(r'^(\d{2}):(\d{2})$');

  final int hour;
  final int minute;

  int get minutesOfDay => hour * 60 + minute;

  /// `HH:mm`.
  String get key => '${_two(hour)}:${_two(minute)}';

  DateTime on(LocalDate d) => DateTime(d.year, d.month, d.day, hour, minute);

  @override
  int compareTo(LocalTime other) => minutesOfDay.compareTo(other.minutesOfDay);

  bool operator <(LocalTime o) => compareTo(o) < 0;
  bool operator >(LocalTime o) => compareTo(o) > 0;

  @override
  bool operator ==(Object other) =>
      other is LocalTime && other.hour == hour && other.minute == minute;

  @override
  int get hashCode => Object.hash(hour, minute);

  @override
  String toString() => key;
}

String _two(int v) => v.toString().padLeft(2, '0');
