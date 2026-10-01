// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'settings.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$AppSettings {

 int get dailyGoalMinutes;/// 1 = Monday … 7 = Sunday.
 int get weekStart;/// null = review reminder off.
 LocalTime? get notifReviewTime; bool get notifEvent10min; ThemeSetting get theme; bool get seatDetectionEnabled; int get sensitivityLevel; bool get sensitivityAuto;
/// Create a copy of AppSettings
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AppSettingsCopyWith<AppSettings> get copyWith => _$AppSettingsCopyWithImpl<AppSettings>(this as AppSettings, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as AppSettings;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AppSettings&&(identical(other.dailyGoalMinutes, _this.dailyGoalMinutes) || other.dailyGoalMinutes == _this.dailyGoalMinutes)&&(identical(other.weekStart, _this.weekStart) || other.weekStart == _this.weekStart)&&(identical(other.notifReviewTime, _this.notifReviewTime) || other.notifReviewTime == _this.notifReviewTime)&&(identical(other.notifEvent10min, _this.notifEvent10min) || other.notifEvent10min == _this.notifEvent10min)&&(identical(other.theme, _this.theme) || other.theme == _this.theme)&&(identical(other.seatDetectionEnabled, _this.seatDetectionEnabled) || other.seatDetectionEnabled == _this.seatDetectionEnabled)&&(identical(other.sensitivityLevel, _this.sensitivityLevel) || other.sensitivityLevel == _this.sensitivityLevel)&&(identical(other.sensitivityAuto, _this.sensitivityAuto) || other.sensitivityAuto == _this.sensitivityAuto));
}


@override
int get hashCode {
  final _this = this as AppSettings;
  return Object.hash(runtimeType,_this.dailyGoalMinutes,_this.weekStart,_this.notifReviewTime,_this.notifEvent10min,_this.theme,_this.seatDetectionEnabled,_this.sensitivityLevel,_this.sensitivityAuto);
}

@override
String toString() {
  final _this = this as AppSettings;
  return 'AppSettings(dailyGoalMinutes: ${_this.dailyGoalMinutes}, weekStart: ${_this.weekStart}, notifReviewTime: ${_this.notifReviewTime}, notifEvent10min: ${_this.notifEvent10min}, theme: ${_this.theme}, seatDetectionEnabled: ${_this.seatDetectionEnabled}, sensitivityLevel: ${_this.sensitivityLevel}, sensitivityAuto: ${_this.sensitivityAuto})';
}


}

/// @nodoc
abstract mixin class $AppSettingsCopyWith<$Res>  {
  factory $AppSettingsCopyWith(AppSettings value, $Res Function(AppSettings) _then) = _$AppSettingsCopyWithImpl;
@useResult
$Res call({
 int dailyGoalMinutes, int weekStart, LocalTime? notifReviewTime, bool notifEvent10min, ThemeSetting theme, bool seatDetectionEnabled, int sensitivityLevel, bool sensitivityAuto
});




}
/// @nodoc
class _$AppSettingsCopyWithImpl<$Res>
    implements $AppSettingsCopyWith<$Res> {
  _$AppSettingsCopyWithImpl(this._self, this._then);

  final AppSettings _self;
  final $Res Function(AppSettings) _then;

/// Create a copy of AppSettings
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? dailyGoalMinutes = null,Object? weekStart = null,Object? notifReviewTime = freezed,Object? notifEvent10min = null,Object? theme = null,Object? seatDetectionEnabled = null,Object? sensitivityLevel = null,Object? sensitivityAuto = null,}) {
  return _then(AppSettings(
dailyGoalMinutes: null == dailyGoalMinutes ? _self.dailyGoalMinutes : dailyGoalMinutes // ignore: cast_nullable_to_non_nullable
as int,weekStart: null == weekStart ? _self.weekStart : weekStart // ignore: cast_nullable_to_non_nullable
as int,notifReviewTime: freezed == notifReviewTime ? _self.notifReviewTime : notifReviewTime // ignore: cast_nullable_to_non_nullable
as LocalTime?,notifEvent10min: null == notifEvent10min ? _self.notifEvent10min : notifEvent10min // ignore: cast_nullable_to_non_nullable
as bool,theme: null == theme ? _self.theme : theme // ignore: cast_nullable_to_non_nullable
as ThemeSetting,seatDetectionEnabled: null == seatDetectionEnabled ? _self.seatDetectionEnabled : seatDetectionEnabled // ignore: cast_nullable_to_non_nullable
as bool,sensitivityLevel: null == sensitivityLevel ? _self.sensitivityLevel : sensitivityLevel // ignore: cast_nullable_to_non_nullable
as int,sensitivityAuto: null == sensitivityAuto ? _self.sensitivityAuto : sensitivityAuto // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [AppSettings].
extension AppSettingsPatterns on AppSettings {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AppSettings value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AppSettings() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AppSettings value)  $default,){
final _that = this;
switch (_that) {
case _AppSettings():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AppSettings value)?  $default,){
final _that = this;
switch (_that) {
case _AppSettings() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int dailyGoalMinutes,  int weekStart,  LocalTime? notifReviewTime,  bool notifEvent10min,  ThemeSetting theme,  bool seatDetectionEnabled,  int sensitivityLevel,  bool sensitivityAuto)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AppSettings() when $default != null:
return $default(_that.dailyGoalMinutes,_that.weekStart,_that.notifReviewTime,_that.notifEvent10min,_that.theme,_that.seatDetectionEnabled,_that.sensitivityLevel,_that.sensitivityAuto);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int dailyGoalMinutes,  int weekStart,  LocalTime? notifReviewTime,  bool notifEvent10min,  ThemeSetting theme,  bool seatDetectionEnabled,  int sensitivityLevel,  bool sensitivityAuto)  $default,) {final _that = this;
switch (_that) {
case _AppSettings():
return $default(_that.dailyGoalMinutes,_that.weekStart,_that.notifReviewTime,_that.notifEvent10min,_that.theme,_that.seatDetectionEnabled,_that.sensitivityLevel,_that.sensitivityAuto);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int dailyGoalMinutes,  int weekStart,  LocalTime? notifReviewTime,  bool notifEvent10min,  ThemeSetting theme,  bool seatDetectionEnabled,  int sensitivityLevel,  bool sensitivityAuto)?  $default,) {final _that = this;
switch (_that) {
case _AppSettings() when $default != null:
return $default(_that.dailyGoalMinutes,_that.weekStart,_that.notifReviewTime,_that.notifEvent10min,_that.theme,_that.seatDetectionEnabled,_that.sensitivityLevel,_that.sensitivityAuto);case _:
  return null;

}
}

}

/// @nodoc


class _AppSettings implements AppSettings {
  const _AppSettings({this.dailyGoalMinutes = 120, this.weekStart = 1, this.notifReviewTime, this.notifEvent10min = false, this.theme = ThemeSetting.system, this.seatDetectionEnabled = true, this.sensitivityLevel = 0, this.sensitivityAuto = true});
  

@override@JsonKey() final  int dailyGoalMinutes;
/// 1 = Monday … 7 = Sunday.
@override@JsonKey() final  int weekStart;
/// null = review reminder off.
@override final  LocalTime? notifReviewTime;
@override@JsonKey() final  bool notifEvent10min;
@override@JsonKey() final  ThemeSetting theme;
@override@JsonKey() final  bool seatDetectionEnabled;
@override@JsonKey() final  int sensitivityLevel;
@override@JsonKey() final  bool sensitivityAuto;

/// Create a copy of AppSettings
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AppSettingsCopyWith<_AppSettings> get copyWith => __$AppSettingsCopyWithImpl<_AppSettings>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _AppSettings&&(identical(other.dailyGoalMinutes, dailyGoalMinutes) || other.dailyGoalMinutes == dailyGoalMinutes)&&(identical(other.weekStart, weekStart) || other.weekStart == weekStart)&&(identical(other.notifReviewTime, notifReviewTime) || other.notifReviewTime == notifReviewTime)&&(identical(other.notifEvent10min, notifEvent10min) || other.notifEvent10min == notifEvent10min)&&(identical(other.theme, theme) || other.theme == theme)&&(identical(other.seatDetectionEnabled, seatDetectionEnabled) || other.seatDetectionEnabled == seatDetectionEnabled)&&(identical(other.sensitivityLevel, sensitivityLevel) || other.sensitivityLevel == sensitivityLevel)&&(identical(other.sensitivityAuto, sensitivityAuto) || other.sensitivityAuto == sensitivityAuto));
}


@override
int get hashCode {
    return Object.hash(runtimeType,dailyGoalMinutes,weekStart,notifReviewTime,notifEvent10min,theme,seatDetectionEnabled,sensitivityLevel,sensitivityAuto);
}

@override
String toString() {
    return 'AppSettings(dailyGoalMinutes: $dailyGoalMinutes, weekStart: $weekStart, notifReviewTime: $notifReviewTime, notifEvent10min: $notifEvent10min, theme: $theme, seatDetectionEnabled: $seatDetectionEnabled, sensitivityLevel: $sensitivityLevel, sensitivityAuto: $sensitivityAuto)';
}


}

/// @nodoc
abstract mixin class _$AppSettingsCopyWith<$Res> implements $AppSettingsCopyWith<$Res> {
  factory _$AppSettingsCopyWith(_AppSettings value, $Res Function(_AppSettings) _then) = __$AppSettingsCopyWithImpl;
@override @useResult
$Res call({
 int dailyGoalMinutes, int weekStart, LocalTime? notifReviewTime, bool notifEvent10min, ThemeSetting theme, bool seatDetectionEnabled, int sensitivityLevel, bool sensitivityAuto
});




}
/// @nodoc
class __$AppSettingsCopyWithImpl<$Res>
    implements _$AppSettingsCopyWith<$Res> {
  __$AppSettingsCopyWithImpl(this._self, this._then);

  final _AppSettings _self;
  final $Res Function(_AppSettings) _then;

/// Create a copy of AppSettings
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? dailyGoalMinutes = null,Object? weekStart = null,Object? notifReviewTime = freezed,Object? notifEvent10min = null,Object? theme = null,Object? seatDetectionEnabled = null,Object? sensitivityLevel = null,Object? sensitivityAuto = null,}) {
  return _then(_AppSettings(
dailyGoalMinutes: null == dailyGoalMinutes ? _self.dailyGoalMinutes : dailyGoalMinutes // ignore: cast_nullable_to_non_nullable
as int,weekStart: null == weekStart ? _self.weekStart : weekStart // ignore: cast_nullable_to_non_nullable
as int,notifReviewTime: freezed == notifReviewTime ? _self.notifReviewTime : notifReviewTime // ignore: cast_nullable_to_non_nullable
as LocalTime?,notifEvent10min: null == notifEvent10min ? _self.notifEvent10min : notifEvent10min // ignore: cast_nullable_to_non_nullable
as bool,theme: null == theme ? _self.theme : theme // ignore: cast_nullable_to_non_nullable
as ThemeSetting,seatDetectionEnabled: null == seatDetectionEnabled ? _self.seatDetectionEnabled : seatDetectionEnabled // ignore: cast_nullable_to_non_nullable
as bool,sensitivityLevel: null == sensitivityLevel ? _self.sensitivityLevel : sensitivityLevel // ignore: cast_nullable_to_non_nullable
as int,sensitivityAuto: null == sensitivityAuto ? _self.sensitivityAuto : sensitivityAuto // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
