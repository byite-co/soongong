// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'dev_fake_settings.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$DevFakeSettings {

 FakeSeatScenario get seat; int get seatAfterSeconds; FakeReadingScenario get reading; int get delayMs; EntitlementStatus get billing; bool get syncOffline;
/// Create a copy of DevFakeSettings
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DevFakeSettingsCopyWith<DevFakeSettings> get copyWith => _$DevFakeSettingsCopyWithImpl<DevFakeSettings>(this as DevFakeSettings, _$identity);

  /// Serializes this DevFakeSettings to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as DevFakeSettings;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DevFakeSettings&&(identical(other.seat, _this.seat) || other.seat == _this.seat)&&(identical(other.seatAfterSeconds, _this.seatAfterSeconds) || other.seatAfterSeconds == _this.seatAfterSeconds)&&(identical(other.reading, _this.reading) || other.reading == _this.reading)&&(identical(other.delayMs, _this.delayMs) || other.delayMs == _this.delayMs)&&(identical(other.billing, _this.billing) || other.billing == _this.billing)&&(identical(other.syncOffline, _this.syncOffline) || other.syncOffline == _this.syncOffline));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as DevFakeSettings;
  return Object.hash(runtimeType,_this.seat,_this.seatAfterSeconds,_this.reading,_this.delayMs,_this.billing,_this.syncOffline);
}

@override
String toString() {
  final _this = this as DevFakeSettings;
  return 'DevFakeSettings(seat: ${_this.seat}, seatAfterSeconds: ${_this.seatAfterSeconds}, reading: ${_this.reading}, delayMs: ${_this.delayMs}, billing: ${_this.billing}, syncOffline: ${_this.syncOffline})';
}


}

/// @nodoc
abstract mixin class $DevFakeSettingsCopyWith<$Res>  {
  factory $DevFakeSettingsCopyWith(DevFakeSettings value, $Res Function(DevFakeSettings) _then) = _$DevFakeSettingsCopyWithImpl;
@useResult
$Res call({
 FakeSeatScenario seat, int seatAfterSeconds, FakeReadingScenario reading, int delayMs, EntitlementStatus billing, bool syncOffline
});




}
/// @nodoc
class _$DevFakeSettingsCopyWithImpl<$Res>
    implements $DevFakeSettingsCopyWith<$Res> {
  _$DevFakeSettingsCopyWithImpl(this._self, this._then);

  final DevFakeSettings _self;
  final $Res Function(DevFakeSettings) _then;

/// Create a copy of DevFakeSettings
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? seat = null,Object? seatAfterSeconds = null,Object? reading = null,Object? delayMs = null,Object? billing = null,Object? syncOffline = null,}) {
  return _then(DevFakeSettings(
seat: null == seat ? _self.seat : seat // ignore: cast_nullable_to_non_nullable
as FakeSeatScenario,seatAfterSeconds: null == seatAfterSeconds ? _self.seatAfterSeconds : seatAfterSeconds // ignore: cast_nullable_to_non_nullable
as int,reading: null == reading ? _self.reading : reading // ignore: cast_nullable_to_non_nullable
as FakeReadingScenario,delayMs: null == delayMs ? _self.delayMs : delayMs // ignore: cast_nullable_to_non_nullable
as int,billing: null == billing ? _self.billing : billing // ignore: cast_nullable_to_non_nullable
as EntitlementStatus,syncOffline: null == syncOffline ? _self.syncOffline : syncOffline // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [DevFakeSettings].
extension DevFakeSettingsPatterns on DevFakeSettings {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _DevFakeSettings value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _DevFakeSettings() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _DevFakeSettings value)  $default,){
final _that = this;
switch (_that) {
case _DevFakeSettings():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _DevFakeSettings value)?  $default,){
final _that = this;
switch (_that) {
case _DevFakeSettings() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( FakeSeatScenario seat,  int seatAfterSeconds,  FakeReadingScenario reading,  int delayMs,  EntitlementStatus billing,  bool syncOffline)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _DevFakeSettings() when $default != null:
return $default(_that.seat,_that.seatAfterSeconds,_that.reading,_that.delayMs,_that.billing,_that.syncOffline);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( FakeSeatScenario seat,  int seatAfterSeconds,  FakeReadingScenario reading,  int delayMs,  EntitlementStatus billing,  bool syncOffline)  $default,) {final _that = this;
switch (_that) {
case _DevFakeSettings():
return $default(_that.seat,_that.seatAfterSeconds,_that.reading,_that.delayMs,_that.billing,_that.syncOffline);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( FakeSeatScenario seat,  int seatAfterSeconds,  FakeReadingScenario reading,  int delayMs,  EntitlementStatus billing,  bool syncOffline)?  $default,) {final _that = this;
switch (_that) {
case _DevFakeSettings() when $default != null:
return $default(_that.seat,_that.seatAfterSeconds,_that.reading,_that.delayMs,_that.billing,_that.syncOffline);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _DevFakeSettings implements DevFakeSettings {
  const _DevFakeSettings({this.seat = FakeSeatScenario.alwaysSeated, this.seatAfterSeconds = 10, this.reading = FakeReadingScenario.success, this.delayMs = 600, this.billing = EntitlementStatus.free, this.syncOffline = false});
  factory _DevFakeSettings.fromJson(Map<String, dynamic> json) => _$DevFakeSettingsFromJson(json);

@override@JsonKey() final  FakeSeatScenario seat;
@override@JsonKey() final  int seatAfterSeconds;
@override@JsonKey() final  FakeReadingScenario reading;
@override@JsonKey() final  int delayMs;
@override@JsonKey() final  EntitlementStatus billing;
@override@JsonKey() final  bool syncOffline;

/// Create a copy of DevFakeSettings
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DevFakeSettingsCopyWith<_DevFakeSettings> get copyWith => __$DevFakeSettingsCopyWithImpl<_DevFakeSettings>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$DevFakeSettingsToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _DevFakeSettings&&(identical(other.seat, seat) || other.seat == seat)&&(identical(other.seatAfterSeconds, seatAfterSeconds) || other.seatAfterSeconds == seatAfterSeconds)&&(identical(other.reading, reading) || other.reading == reading)&&(identical(other.delayMs, delayMs) || other.delayMs == delayMs)&&(identical(other.billing, billing) || other.billing == billing)&&(identical(other.syncOffline, syncOffline) || other.syncOffline == syncOffline));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,seat,seatAfterSeconds,reading,delayMs,billing,syncOffline);
}

@override
String toString() {
    return 'DevFakeSettings(seat: $seat, seatAfterSeconds: $seatAfterSeconds, reading: $reading, delayMs: $delayMs, billing: $billing, syncOffline: $syncOffline)';
}


}

/// @nodoc
abstract mixin class _$DevFakeSettingsCopyWith<$Res> implements $DevFakeSettingsCopyWith<$Res> {
  factory _$DevFakeSettingsCopyWith(_DevFakeSettings value, $Res Function(_DevFakeSettings) _then) = __$DevFakeSettingsCopyWithImpl;
@override @useResult
$Res call({
 FakeSeatScenario seat, int seatAfterSeconds, FakeReadingScenario reading, int delayMs, EntitlementStatus billing, bool syncOffline
});




}
/// @nodoc
class __$DevFakeSettingsCopyWithImpl<$Res>
    implements _$DevFakeSettingsCopyWith<$Res> {
  __$DevFakeSettingsCopyWithImpl(this._self, this._then);

  final _DevFakeSettings _self;
  final $Res Function(_DevFakeSettings) _then;

/// Create a copy of DevFakeSettings
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? seat = null,Object? seatAfterSeconds = null,Object? reading = null,Object? delayMs = null,Object? billing = null,Object? syncOffline = null,}) {
  return _then(_DevFakeSettings(
seat: null == seat ? _self.seat : seat // ignore: cast_nullable_to_non_nullable
as FakeSeatScenario,seatAfterSeconds: null == seatAfterSeconds ? _self.seatAfterSeconds : seatAfterSeconds // ignore: cast_nullable_to_non_nullable
as int,reading: null == reading ? _self.reading : reading // ignore: cast_nullable_to_non_nullable
as FakeReadingScenario,delayMs: null == delayMs ? _self.delayMs : delayMs // ignore: cast_nullable_to_non_nullable
as int,billing: null == billing ? _self.billing : billing // ignore: cast_nullable_to_non_nullable
as EntitlementStatus,syncOffline: null == syncOffline ? _self.syncOffline : syncOffline // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
