// drift type converters (S02). Timestamps are stored as ISO 8601 UTC text,
// enums as their wire name (docs/data-model.md §0). Every converter also
// implements the JSON side so `toJson()` on row classes (used by the export)
// emits the same representation as the DB / server.

import 'package:drift/drift.dart';

import '../../core/domain/enums.dart';

/// `DateTime` ⇄ `2026-09-30T14:03:00.000Z`. Always UTC on disk; the Dart
/// value is returned in UTC as well (convert with `toLocal()` in the UI).
class UtcDateTimeConverter extends TypeConverter<DateTime, String>
    with JsonTypeConverter<DateTime, String> {
  const UtcDateTimeConverter();

  @override
  DateTime fromSql(String fromDb) => DateTime.parse(fromDb).toUtc();

  @override
  String toSql(DateTime value) => value.toUtc().toIso8601String();
}

class NullableUtcDateTimeConverter extends TypeConverter<DateTime?, String?>
    with JsonTypeConverter<DateTime?, String?> {
  const NullableUtcDateTimeConverter();

  @override
  DateTime? fromSql(String? fromDb) =>
      fromDb == null ? null : DateTime.parse(fromDb).toUtc();

  @override
  String? toSql(DateTime? value) => value?.toUtc().toIso8601String();
}

/// Enum ⇄ wire name.
class WireEnumConverter<T extends WireEnum> extends TypeConverter<T, String>
    with JsonTypeConverter<T, String> {
  const WireEnumConverter(this.values);

  final List<T> values;

  @override
  T fromSql(String fromDb) => wireEnumFrom(values, fromDb);

  @override
  String toSql(T value) => value.wire;
}

class NullableWireEnumConverter<T extends WireEnum>
    extends TypeConverter<T?, String?>
    with JsonTypeConverter<T?, String?> {
  const NullableWireEnumConverter(this.values);

  final List<T> values;

  @override
  T? fromSql(String? fromDb) =>
      fromDb == null ? null : wireEnumFrom(values, fromDb);

  @override
  String? toSql(T? value) => value?.wire;
}

/// ISO UTC string of a [DateTime] — the single formatting rule for the DB.
String utcIso(DateTime t) => t.toUtc().toIso8601String();
