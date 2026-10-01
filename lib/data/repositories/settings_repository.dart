// SettingsRepository (S02). `settings` rows (key · value_json) ⇄ AppSettings.
// Missing rows fall back to the defaults in [AppSettings]. Row ids are
// deterministic (`settingId`, uuid v5 of user|key) like `activity_days`.

import 'dart:convert';

import 'package:drift/drift.dart';

import '../../core/domain/entities/entities.dart';
import '../../core/domain/enums.dart';
import '../../core/domain/ids.dart';
import '../../core/domain/local_date.dart';
import '../db/app_database.dart';
import 'sync_writer.dart';
import 'write_context.dart';

class SettingsRepository {
  SettingsRepository(this.db, this.writer);

  final AppDatabase db;
  final SyncWriter writer;

  WriteContext get ctx => writer.ctx;
  $SettingsTable get _t => db.settings;

  SimpleSelectStatement<$SettingsTable, SettingRow> _all() => db.select(_t)
    ..where((t) => t.userId.equals(ctx.userId) & t.deletedAt.isNull());

  Stream<AppSettings> watch() => _all().watch().map(_fold);

  Future<AppSettings> get() async => _fold(await _all().get());

  /// Raw value of one key (null when unset).
  Future<Object?> getRaw(String key) async {
    final r = await (db.select(_t)
          ..where((t) => t.userId.equals(ctx.userId) & t.key.equals(key) & t.deletedAt.isNull()))
        .getSingleOrNull();
    return r?.valueJson == null ? null : jsonDecode(r!.valueJson!);
  }

  /// Upserts one key. [value] must be JSON-encodable (scalar or null).
  Future<void> set(String key, Object? value) {
    assert(SettingKeys.all.contains(key), 'unknown setting $key');
    return writer.runInTransaction(() async {
      final now = ctx.nowUtc();
      final json = jsonEncode(value);
      final existing = await (db.select(_t)
            ..where((t) => t.userId.equals(ctx.userId) & t.key.equals(key) & t.deletedAt.isNull()))
          .getSingleOrNull();
      if (existing == null) {
        // Deterministic id (uuid v5 of user|key): two devices converge on
        // the same row and merge through CAS instead of colliding on pull.
        final id = settingId(ctx.userId, key);
        await db.into(_t).insert(
              SettingsCompanion.insert(
                id: id,
                userId: ctx.userId,
                createdAt: now,
                clientUpdatedAt: now,
                deviceId: ctx.deviceId,
                purgeEpoch: Value(await writer.purgeEpoch()),
                key: Value(key),
                valueJson: Value(json),
              ),
            );
        await writer.enqueue(_t.actualTableName, id);
      } else {
        if (existing.valueJson == json) return;
        await (db.update(_t)..where((t) => t.id.equals(existing.id)))
            .write(SettingsCompanion(valueJson: Value(json)));
        await writer.markUserWrite(_t, existing.id, at: now);
      }
    });
  }

  Future<void> setDailyGoalMinutes(int v) => set(SettingKeys.dailyGoalMinutes, v);
  Future<void> setWeekStart(int weekday) => set(SettingKeys.weekStart, weekday);
  Future<void> setNotifReviewTime(LocalTime? t) => set(SettingKeys.notifReviewTime, t?.key);
  Future<void> setNotifEvent10min({required bool on}) => set(SettingKeys.notifEvent10min, on);
  Future<void> setTheme(ThemeSetting t) => set(SettingKeys.theme, t.wire);
  Future<void> setSeatDetectionEnabled({required bool on}) =>
      set(SettingKeys.seatDetectionEnabled, on);
  Future<void> setSensitivityLevel(int level) =>
      set(SettingKeys.sensitivityLevel, level.clamp(0, 2));
  Future<void> setSensitivityAuto({required bool on}) => set(SettingKeys.sensitivityAuto, on);

  Future<ApplyServerReport> applyServer(Iterable<Map<String, Object?>> rows) =>
      writer.applyServer(_t, rows);

  AppSettings _fold(List<SettingRow> rows) {
    var s = const AppSettings();
    for (final r in rows) {
      if (r.key == null || r.valueJson == null) continue;
      final Object? v;
      try {
        v = jsonDecode(r.valueJson!);
      } on FormatException {
        continue;
      }
      switch (r.key) {
        case SettingKeys.dailyGoalMinutes:
          if (v is int) s = s.copyWith(dailyGoalMinutes: v);
        case SettingKeys.weekStart:
          if (v is int && v >= 1 && v <= 7) s = s.copyWith(weekStart: v);
        case SettingKeys.notifReviewTime:
          s = s.copyWith(notifReviewTime: v is String ? LocalTime.tryParse(v) : null);
        case SettingKeys.notifEvent10min:
          if (v is bool) s = s.copyWith(notifEvent10min: v);
        case SettingKeys.theme:
          final t = wireEnumFromOrNull(ThemeSetting.values, v is String ? v : null);
          if (t != null) s = s.copyWith(theme: t);
        case SettingKeys.seatDetectionEnabled:
          if (v is bool) s = s.copyWith(seatDetectionEnabled: v);
        case SettingKeys.sensitivityLevel:
          if (v is int) s = s.copyWith(sensitivityLevel: v.clamp(0, 2));
        case SettingKeys.sensitivityAuto:
          if (v is bool) s = s.copyWith(sensitivityAuto: v);
      }
    }
    return s;
  }
}
