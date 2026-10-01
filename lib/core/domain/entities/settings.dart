import 'package:freezed_annotation/freezed_annotation.dart';

import '../enums.dart';
import '../local_date.dart';

part 'settings.freezed.dart';

/// Typed view of the `settings` rows (§2.12). Defaults are the values used
/// when no row exists. Keys are in [SettingKeys].
@freezed
abstract class AppSettings with _$AppSettings {
  const factory AppSettings({
    @Default(120) int dailyGoalMinutes,

    /// 1 = Monday … 7 = Sunday.
    @Default(1) int weekStart,

    /// null = review reminder off.
    LocalTime? notifReviewTime,
    @Default(false) bool notifEvent10min,
    @Default(ThemeSetting.system) ThemeSetting theme,
    @Default(true) bool seatDetectionEnabled,
    @Default(0) int sensitivityLevel,
    @Default(true) bool sensitivityAuto,
  }) = _AppSettings;
}

abstract final class SettingKeys {
  static const String dailyGoalMinutes = 'daily_goal_minutes';
  static const String weekStart = 'week_start';
  static const String notifReviewTime = 'notif_review_time';
  static const String notifEvent10min = 'notif_event_10min';
  static const String theme = 'theme';
  static const String seatDetectionEnabled = 'seat_detection_enabled';
  static const String sensitivityLevel = 'sensitivity_level';
  static const String sensitivityAuto = 'sensitivity_auto';

  static const List<String> all = <String>[
    dailyGoalMinutes,
    weekStart,
    notifReviewTime,
    notifEvent10min,
    theme,
    seatDetectionEnabled,
    sensitivityLevel,
    sensitivityAuto,
  ];
}
