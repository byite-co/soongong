// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'sync_stamp.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$SyncStamp {

 String get userId; DateTime get createdAt; DateTime get clientUpdatedAt; String get deviceId; int get clientRev; int? get baseServerVersion; int? get serverVersion; int? get serverSeq; int get purgeEpoch; DateTime? get pendingDeleteUntil;
/// Create a copy of SyncStamp
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SyncStampCopyWith<SyncStamp> get copyWith => _$SyncStampCopyWithImpl<SyncStamp>(this as SyncStamp, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as SyncStamp;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SyncStamp&&(identical(other.userId, _this.userId) || other.userId == _this.userId)&&(identical(other.createdAt, _this.createdAt) || other.createdAt == _this.createdAt)&&(identical(other.clientUpdatedAt, _this.clientUpdatedAt) || other.clientUpdatedAt == _this.clientUpdatedAt)&&(identical(other.deviceId, _this.deviceId) || other.deviceId == _this.deviceId)&&(identical(other.clientRev, _this.clientRev) || other.clientRev == _this.clientRev)&&(identical(other.baseServerVersion, _this.baseServerVersion) || other.baseServerVersion == _this.baseServerVersion)&&(identical(other.serverVersion, _this.serverVersion) || other.serverVersion == _this.serverVersion)&&(identical(other.serverSeq, _this.serverSeq) || other.serverSeq == _this.serverSeq)&&(identical(other.purgeEpoch, _this.purgeEpoch) || other.purgeEpoch == _this.purgeEpoch)&&(identical(other.pendingDeleteUntil, _this.pendingDeleteUntil) || other.pendingDeleteUntil == _this.pendingDeleteUntil));
}


@override
int get hashCode {
  final _this = this as SyncStamp;
  return Object.hash(runtimeType,_this.userId,_this.createdAt,_this.clientUpdatedAt,_this.deviceId,_this.clientRev,_this.baseServerVersion,_this.serverVersion,_this.serverSeq,_this.purgeEpoch,_this.pendingDeleteUntil);
}

@override
String toString() {
  final _this = this as SyncStamp;
  return 'SyncStamp(userId: ${_this.userId}, createdAt: ${_this.createdAt}, clientUpdatedAt: ${_this.clientUpdatedAt}, deviceId: ${_this.deviceId}, clientRev: ${_this.clientRev}, baseServerVersion: ${_this.baseServerVersion}, serverVersion: ${_this.serverVersion}, serverSeq: ${_this.serverSeq}, purgeEpoch: ${_this.purgeEpoch}, pendingDeleteUntil: ${_this.pendingDeleteUntil})';
}


}

/// @nodoc
abstract mixin class $SyncStampCopyWith<$Res>  {
  factory $SyncStampCopyWith(SyncStamp value, $Res Function(SyncStamp) _then) = _$SyncStampCopyWithImpl;
@useResult
$Res call({
 String userId, DateTime createdAt, DateTime clientUpdatedAt, String deviceId, int clientRev, int? baseServerVersion, int? serverVersion, int? serverSeq, int purgeEpoch, DateTime? pendingDeleteUntil
});




}
/// @nodoc
class _$SyncStampCopyWithImpl<$Res>
    implements $SyncStampCopyWith<$Res> {
  _$SyncStampCopyWithImpl(this._self, this._then);

  final SyncStamp _self;
  final $Res Function(SyncStamp) _then;

/// Create a copy of SyncStamp
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? userId = null,Object? createdAt = null,Object? clientUpdatedAt = null,Object? deviceId = null,Object? clientRev = null,Object? baseServerVersion = freezed,Object? serverVersion = freezed,Object? serverSeq = freezed,Object? purgeEpoch = null,Object? pendingDeleteUntil = freezed,}) {
  return _then(SyncStamp(
userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,clientUpdatedAt: null == clientUpdatedAt ? _self.clientUpdatedAt : clientUpdatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,deviceId: null == deviceId ? _self.deviceId : deviceId // ignore: cast_nullable_to_non_nullable
as String,clientRev: null == clientRev ? _self.clientRev : clientRev // ignore: cast_nullable_to_non_nullable
as int,baseServerVersion: freezed == baseServerVersion ? _self.baseServerVersion : baseServerVersion // ignore: cast_nullable_to_non_nullable
as int?,serverVersion: freezed == serverVersion ? _self.serverVersion : serverVersion // ignore: cast_nullable_to_non_nullable
as int?,serverSeq: freezed == serverSeq ? _self.serverSeq : serverSeq // ignore: cast_nullable_to_non_nullable
as int?,purgeEpoch: null == purgeEpoch ? _self.purgeEpoch : purgeEpoch // ignore: cast_nullable_to_non_nullable
as int,pendingDeleteUntil: freezed == pendingDeleteUntil ? _self.pendingDeleteUntil : pendingDeleteUntil // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [SyncStamp].
extension SyncStampPatterns on SyncStamp {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SyncStamp value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SyncStamp() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SyncStamp value)  $default,){
final _that = this;
switch (_that) {
case _SyncStamp():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SyncStamp value)?  $default,){
final _that = this;
switch (_that) {
case _SyncStamp() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String userId,  DateTime createdAt,  DateTime clientUpdatedAt,  String deviceId,  int clientRev,  int? baseServerVersion,  int? serverVersion,  int? serverSeq,  int purgeEpoch,  DateTime? pendingDeleteUntil)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SyncStamp() when $default != null:
return $default(_that.userId,_that.createdAt,_that.clientUpdatedAt,_that.deviceId,_that.clientRev,_that.baseServerVersion,_that.serverVersion,_that.serverSeq,_that.purgeEpoch,_that.pendingDeleteUntil);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String userId,  DateTime createdAt,  DateTime clientUpdatedAt,  String deviceId,  int clientRev,  int? baseServerVersion,  int? serverVersion,  int? serverSeq,  int purgeEpoch,  DateTime? pendingDeleteUntil)  $default,) {final _that = this;
switch (_that) {
case _SyncStamp():
return $default(_that.userId,_that.createdAt,_that.clientUpdatedAt,_that.deviceId,_that.clientRev,_that.baseServerVersion,_that.serverVersion,_that.serverSeq,_that.purgeEpoch,_that.pendingDeleteUntil);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String userId,  DateTime createdAt,  DateTime clientUpdatedAt,  String deviceId,  int clientRev,  int? baseServerVersion,  int? serverVersion,  int? serverSeq,  int purgeEpoch,  DateTime? pendingDeleteUntil)?  $default,) {final _that = this;
switch (_that) {
case _SyncStamp() when $default != null:
return $default(_that.userId,_that.createdAt,_that.clientUpdatedAt,_that.deviceId,_that.clientRev,_that.baseServerVersion,_that.serverVersion,_that.serverSeq,_that.purgeEpoch,_that.pendingDeleteUntil);case _:
  return null;

}
}

}

/// @nodoc


class _SyncStamp extends SyncStamp {
  const _SyncStamp({required this.userId, required this.createdAt, required this.clientUpdatedAt, required this.deviceId, this.clientRev = 1, this.baseServerVersion, this.serverVersion, this.serverSeq, this.purgeEpoch = 0, this.pendingDeleteUntil}): super._();
  

@override final  String userId;
@override final  DateTime createdAt;
@override final  DateTime clientUpdatedAt;
@override final  String deviceId;
@override@JsonKey() final  int clientRev;
@override final  int? baseServerVersion;
@override final  int? serverVersion;
@override final  int? serverSeq;
@override@JsonKey() final  int purgeEpoch;
@override final  DateTime? pendingDeleteUntil;

/// Create a copy of SyncStamp
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SyncStampCopyWith<_SyncStamp> get copyWith => __$SyncStampCopyWithImpl<_SyncStamp>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _SyncStamp&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.clientUpdatedAt, clientUpdatedAt) || other.clientUpdatedAt == clientUpdatedAt)&&(identical(other.deviceId, deviceId) || other.deviceId == deviceId)&&(identical(other.clientRev, clientRev) || other.clientRev == clientRev)&&(identical(other.baseServerVersion, baseServerVersion) || other.baseServerVersion == baseServerVersion)&&(identical(other.serverVersion, serverVersion) || other.serverVersion == serverVersion)&&(identical(other.serverSeq, serverSeq) || other.serverSeq == serverSeq)&&(identical(other.purgeEpoch, purgeEpoch) || other.purgeEpoch == purgeEpoch)&&(identical(other.pendingDeleteUntil, pendingDeleteUntil) || other.pendingDeleteUntil == pendingDeleteUntil));
}


@override
int get hashCode {
    return Object.hash(runtimeType,userId,createdAt,clientUpdatedAt,deviceId,clientRev,baseServerVersion,serverVersion,serverSeq,purgeEpoch,pendingDeleteUntil);
}

@override
String toString() {
    return 'SyncStamp(userId: $userId, createdAt: $createdAt, clientUpdatedAt: $clientUpdatedAt, deviceId: $deviceId, clientRev: $clientRev, baseServerVersion: $baseServerVersion, serverVersion: $serverVersion, serverSeq: $serverSeq, purgeEpoch: $purgeEpoch, pendingDeleteUntil: $pendingDeleteUntil)';
}


}

/// @nodoc
abstract mixin class _$SyncStampCopyWith<$Res> implements $SyncStampCopyWith<$Res> {
  factory _$SyncStampCopyWith(_SyncStamp value, $Res Function(_SyncStamp) _then) = __$SyncStampCopyWithImpl;
@override @useResult
$Res call({
 String userId, DateTime createdAt, DateTime clientUpdatedAt, String deviceId, int clientRev, int? baseServerVersion, int? serverVersion, int? serverSeq, int purgeEpoch, DateTime? pendingDeleteUntil
});




}
/// @nodoc
class __$SyncStampCopyWithImpl<$Res>
    implements _$SyncStampCopyWith<$Res> {
  __$SyncStampCopyWithImpl(this._self, this._then);

  final _SyncStamp _self;
  final $Res Function(_SyncStamp) _then;

/// Create a copy of SyncStamp
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? userId = null,Object? createdAt = null,Object? clientUpdatedAt = null,Object? deviceId = null,Object? clientRev = null,Object? baseServerVersion = freezed,Object? serverVersion = freezed,Object? serverSeq = freezed,Object? purgeEpoch = null,Object? pendingDeleteUntil = freezed,}) {
  return _then(_SyncStamp(
userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,clientUpdatedAt: null == clientUpdatedAt ? _self.clientUpdatedAt : clientUpdatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,deviceId: null == deviceId ? _self.deviceId : deviceId // ignore: cast_nullable_to_non_nullable
as String,clientRev: null == clientRev ? _self.clientRev : clientRev // ignore: cast_nullable_to_non_nullable
as int,baseServerVersion: freezed == baseServerVersion ? _self.baseServerVersion : baseServerVersion // ignore: cast_nullable_to_non_nullable
as int?,serverVersion: freezed == serverVersion ? _self.serverVersion : serverVersion // ignore: cast_nullable_to_non_nullable
as int?,serverSeq: freezed == serverSeq ? _self.serverSeq : serverSeq // ignore: cast_nullable_to_non_nullable
as int?,purgeEpoch: null == purgeEpoch ? _self.purgeEpoch : purgeEpoch // ignore: cast_nullable_to_non_nullable
as int,pendingDeleteUntil: freezed == pendingDeleteUntil ? _self.pendingDeleteUntil : pendingDeleteUntil // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

// dart format on
