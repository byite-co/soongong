// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'activity_day.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$ActivityDay {

 String get id; SyncStamp get stamp; LocalDate get date;
/// Create a copy of ActivityDay
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ActivityDayCopyWith<ActivityDay> get copyWith => _$ActivityDayCopyWithImpl<ActivityDay>(this as ActivityDay, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as ActivityDay;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ActivityDay&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.stamp, _this.stamp) || other.stamp == _this.stamp)&&(identical(other.date, _this.date) || other.date == _this.date));
}


@override
int get hashCode {
  final _this = this as ActivityDay;
  return Object.hash(runtimeType,_this.id,_this.stamp,_this.date);
}

@override
String toString() {
  final _this = this as ActivityDay;
  return 'ActivityDay(id: ${_this.id}, stamp: ${_this.stamp}, date: ${_this.date})';
}


}

/// @nodoc
abstract mixin class $ActivityDayCopyWith<$Res>  {
  factory $ActivityDayCopyWith(ActivityDay value, $Res Function(ActivityDay) _then) = _$ActivityDayCopyWithImpl;
@useResult
$Res call({
 String id, SyncStamp stamp, LocalDate date
});


$SyncStampCopyWith<$Res> get stamp;

}
/// @nodoc
class _$ActivityDayCopyWithImpl<$Res>
    implements $ActivityDayCopyWith<$Res> {
  _$ActivityDayCopyWithImpl(this._self, this._then);

  final ActivityDay _self;
  final $Res Function(ActivityDay) _then;

/// Create a copy of ActivityDay
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? stamp = null,Object? date = null,}) {
  return _then(ActivityDay(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,stamp: null == stamp ? _self.stamp : stamp // ignore: cast_nullable_to_non_nullable
as SyncStamp,date: null == date ? _self.date : date // ignore: cast_nullable_to_non_nullable
as LocalDate,
  ));
}
/// Create a copy of ActivityDay
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$SyncStampCopyWith<$Res> get stamp {
  
  return $SyncStampCopyWith<$Res>(_self.stamp, (value) {
    return _then(_self.copyWith(stamp: value));
  });
}
}


/// Adds pattern-matching-related methods to [ActivityDay].
extension ActivityDayPatterns on ActivityDay {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ActivityDay value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ActivityDay() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ActivityDay value)  $default,){
final _that = this;
switch (_that) {
case _ActivityDay():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ActivityDay value)?  $default,){
final _that = this;
switch (_that) {
case _ActivityDay() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  SyncStamp stamp,  LocalDate date)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ActivityDay() when $default != null:
return $default(_that.id,_that.stamp,_that.date);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  SyncStamp stamp,  LocalDate date)  $default,) {final _that = this;
switch (_that) {
case _ActivityDay():
return $default(_that.id,_that.stamp,_that.date);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  SyncStamp stamp,  LocalDate date)?  $default,) {final _that = this;
switch (_that) {
case _ActivityDay() when $default != null:
return $default(_that.id,_that.stamp,_that.date);case _:
  return null;

}
}

}

/// @nodoc


class _ActivityDay implements ActivityDay {
  const _ActivityDay({required this.id, required this.stamp, required this.date});
  

@override final  String id;
@override final  SyncStamp stamp;
@override final  LocalDate date;

/// Create a copy of ActivityDay
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ActivityDayCopyWith<_ActivityDay> get copyWith => __$ActivityDayCopyWithImpl<_ActivityDay>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _ActivityDay&&(identical(other.id, id) || other.id == id)&&(identical(other.stamp, stamp) || other.stamp == stamp)&&(identical(other.date, date) || other.date == date));
}


@override
int get hashCode {
    return Object.hash(runtimeType,id,stamp,date);
}

@override
String toString() {
    return 'ActivityDay(id: $id, stamp: $stamp, date: $date)';
}


}

/// @nodoc
abstract mixin class _$ActivityDayCopyWith<$Res> implements $ActivityDayCopyWith<$Res> {
  factory _$ActivityDayCopyWith(_ActivityDay value, $Res Function(_ActivityDay) _then) = __$ActivityDayCopyWithImpl;
@override @useResult
$Res call({
 String id, SyncStamp stamp, LocalDate date
});


@override $SyncStampCopyWith<$Res> get stamp;

}
/// @nodoc
class __$ActivityDayCopyWithImpl<$Res>
    implements _$ActivityDayCopyWith<$Res> {
  __$ActivityDayCopyWithImpl(this._self, this._then);

  final _ActivityDay _self;
  final $Res Function(_ActivityDay) _then;

/// Create a copy of ActivityDay
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? stamp = null,Object? date = null,}) {
  return _then(_ActivityDay(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,stamp: null == stamp ? _self.stamp : stamp // ignore: cast_nullable_to_non_nullable
as SyncStamp,date: null == date ? _self.date : date // ignore: cast_nullable_to_non_nullable
as LocalDate,
  ));
}

/// Create a copy of ActivityDay
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$SyncStampCopyWith<$Res> get stamp {
  
  return $SyncStampCopyWith<$Res>(_self.stamp, (value) {
    return _then(_self.copyWith(stamp: value));
  });
}
}

// dart format on
