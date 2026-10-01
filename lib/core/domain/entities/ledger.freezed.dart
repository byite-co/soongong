// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'ledger.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$SubscriptionState {

 String get userId; EntitlementStatus get status; bool get entitled; DateTime? get expiresAt; DateTime? get graceExpiresAt; String? get periodType; bool get willRenew; bool get trialUsed; SubscriptionSource get source; DateTime get lastCheckedAt;
/// Create a copy of SubscriptionState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SubscriptionStateCopyWith<SubscriptionState> get copyWith => _$SubscriptionStateCopyWithImpl<SubscriptionState>(this as SubscriptionState, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as SubscriptionState;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SubscriptionState&&(identical(other.userId, _this.userId) || other.userId == _this.userId)&&(identical(other.status, _this.status) || other.status == _this.status)&&(identical(other.entitled, _this.entitled) || other.entitled == _this.entitled)&&(identical(other.expiresAt, _this.expiresAt) || other.expiresAt == _this.expiresAt)&&(identical(other.graceExpiresAt, _this.graceExpiresAt) || other.graceExpiresAt == _this.graceExpiresAt)&&(identical(other.periodType, _this.periodType) || other.periodType == _this.periodType)&&(identical(other.willRenew, _this.willRenew) || other.willRenew == _this.willRenew)&&(identical(other.trialUsed, _this.trialUsed) || other.trialUsed == _this.trialUsed)&&(identical(other.source, _this.source) || other.source == _this.source)&&(identical(other.lastCheckedAt, _this.lastCheckedAt) || other.lastCheckedAt == _this.lastCheckedAt));
}


@override
int get hashCode {
  final _this = this as SubscriptionState;
  return Object.hash(runtimeType,_this.userId,_this.status,_this.entitled,_this.expiresAt,_this.graceExpiresAt,_this.periodType,_this.willRenew,_this.trialUsed,_this.source,_this.lastCheckedAt);
}

@override
String toString() {
  final _this = this as SubscriptionState;
  return 'SubscriptionState(userId: ${_this.userId}, status: ${_this.status}, entitled: ${_this.entitled}, expiresAt: ${_this.expiresAt}, graceExpiresAt: ${_this.graceExpiresAt}, periodType: ${_this.periodType}, willRenew: ${_this.willRenew}, trialUsed: ${_this.trialUsed}, source: ${_this.source}, lastCheckedAt: ${_this.lastCheckedAt})';
}


}

/// @nodoc
abstract mixin class $SubscriptionStateCopyWith<$Res>  {
  factory $SubscriptionStateCopyWith(SubscriptionState value, $Res Function(SubscriptionState) _then) = _$SubscriptionStateCopyWithImpl;
@useResult
$Res call({
 String userId, EntitlementStatus status, bool entitled, DateTime? expiresAt, DateTime? graceExpiresAt, String? periodType, bool willRenew, bool trialUsed, SubscriptionSource source, DateTime lastCheckedAt
});




}
/// @nodoc
class _$SubscriptionStateCopyWithImpl<$Res>
    implements $SubscriptionStateCopyWith<$Res> {
  _$SubscriptionStateCopyWithImpl(this._self, this._then);

  final SubscriptionState _self;
  final $Res Function(SubscriptionState) _then;

/// Create a copy of SubscriptionState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? userId = null,Object? status = null,Object? entitled = null,Object? expiresAt = freezed,Object? graceExpiresAt = freezed,Object? periodType = freezed,Object? willRenew = null,Object? trialUsed = null,Object? source = null,Object? lastCheckedAt = null,}) {
  return _then(SubscriptionState(
userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as EntitlementStatus,entitled: null == entitled ? _self.entitled : entitled // ignore: cast_nullable_to_non_nullable
as bool,expiresAt: freezed == expiresAt ? _self.expiresAt : expiresAt // ignore: cast_nullable_to_non_nullable
as DateTime?,graceExpiresAt: freezed == graceExpiresAt ? _self.graceExpiresAt : graceExpiresAt // ignore: cast_nullable_to_non_nullable
as DateTime?,periodType: freezed == periodType ? _self.periodType : periodType // ignore: cast_nullable_to_non_nullable
as String?,willRenew: null == willRenew ? _self.willRenew : willRenew // ignore: cast_nullable_to_non_nullable
as bool,trialUsed: null == trialUsed ? _self.trialUsed : trialUsed // ignore: cast_nullable_to_non_nullable
as bool,source: null == source ? _self.source : source // ignore: cast_nullable_to_non_nullable
as SubscriptionSource,lastCheckedAt: null == lastCheckedAt ? _self.lastCheckedAt : lastCheckedAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// Adds pattern-matching-related methods to [SubscriptionState].
extension SubscriptionStatePatterns on SubscriptionState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SubscriptionState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SubscriptionState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SubscriptionState value)  $default,){
final _that = this;
switch (_that) {
case _SubscriptionState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SubscriptionState value)?  $default,){
final _that = this;
switch (_that) {
case _SubscriptionState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String userId,  EntitlementStatus status,  bool entitled,  DateTime? expiresAt,  DateTime? graceExpiresAt,  String? periodType,  bool willRenew,  bool trialUsed,  SubscriptionSource source,  DateTime lastCheckedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SubscriptionState() when $default != null:
return $default(_that.userId,_that.status,_that.entitled,_that.expiresAt,_that.graceExpiresAt,_that.periodType,_that.willRenew,_that.trialUsed,_that.source,_that.lastCheckedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String userId,  EntitlementStatus status,  bool entitled,  DateTime? expiresAt,  DateTime? graceExpiresAt,  String? periodType,  bool willRenew,  bool trialUsed,  SubscriptionSource source,  DateTime lastCheckedAt)  $default,) {final _that = this;
switch (_that) {
case _SubscriptionState():
return $default(_that.userId,_that.status,_that.entitled,_that.expiresAt,_that.graceExpiresAt,_that.periodType,_that.willRenew,_that.trialUsed,_that.source,_that.lastCheckedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String userId,  EntitlementStatus status,  bool entitled,  DateTime? expiresAt,  DateTime? graceExpiresAt,  String? periodType,  bool willRenew,  bool trialUsed,  SubscriptionSource source,  DateTime lastCheckedAt)?  $default,) {final _that = this;
switch (_that) {
case _SubscriptionState() when $default != null:
return $default(_that.userId,_that.status,_that.entitled,_that.expiresAt,_that.graceExpiresAt,_that.periodType,_that.willRenew,_that.trialUsed,_that.source,_that.lastCheckedAt);case _:
  return null;

}
}

}

/// @nodoc


class _SubscriptionState extends SubscriptionState {
  const _SubscriptionState({required this.userId, required this.status, required this.entitled, this.expiresAt, this.graceExpiresAt, this.periodType, this.willRenew = false, this.trialUsed = false, required this.source, required this.lastCheckedAt}): super._();
  

@override final  String userId;
@override final  EntitlementStatus status;
@override final  bool entitled;
@override final  DateTime? expiresAt;
@override final  DateTime? graceExpiresAt;
@override final  String? periodType;
@override@JsonKey() final  bool willRenew;
@override@JsonKey() final  bool trialUsed;
@override final  SubscriptionSource source;
@override final  DateTime lastCheckedAt;

/// Create a copy of SubscriptionState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SubscriptionStateCopyWith<_SubscriptionState> get copyWith => __$SubscriptionStateCopyWithImpl<_SubscriptionState>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _SubscriptionState&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.status, status) || other.status == status)&&(identical(other.entitled, entitled) || other.entitled == entitled)&&(identical(other.expiresAt, expiresAt) || other.expiresAt == expiresAt)&&(identical(other.graceExpiresAt, graceExpiresAt) || other.graceExpiresAt == graceExpiresAt)&&(identical(other.periodType, periodType) || other.periodType == periodType)&&(identical(other.willRenew, willRenew) || other.willRenew == willRenew)&&(identical(other.trialUsed, trialUsed) || other.trialUsed == trialUsed)&&(identical(other.source, source) || other.source == source)&&(identical(other.lastCheckedAt, lastCheckedAt) || other.lastCheckedAt == lastCheckedAt));
}


@override
int get hashCode {
    return Object.hash(runtimeType,userId,status,entitled,expiresAt,graceExpiresAt,periodType,willRenew,trialUsed,source,lastCheckedAt);
}

@override
String toString() {
    return 'SubscriptionState(userId: $userId, status: $status, entitled: $entitled, expiresAt: $expiresAt, graceExpiresAt: $graceExpiresAt, periodType: $periodType, willRenew: $willRenew, trialUsed: $trialUsed, source: $source, lastCheckedAt: $lastCheckedAt)';
}


}

/// @nodoc
abstract mixin class _$SubscriptionStateCopyWith<$Res> implements $SubscriptionStateCopyWith<$Res> {
  factory _$SubscriptionStateCopyWith(_SubscriptionState value, $Res Function(_SubscriptionState) _then) = __$SubscriptionStateCopyWithImpl;
@override @useResult
$Res call({
 String userId, EntitlementStatus status, bool entitled, DateTime? expiresAt, DateTime? graceExpiresAt, String? periodType, bool willRenew, bool trialUsed, SubscriptionSource source, DateTime lastCheckedAt
});




}
/// @nodoc
class __$SubscriptionStateCopyWithImpl<$Res>
    implements _$SubscriptionStateCopyWith<$Res> {
  __$SubscriptionStateCopyWithImpl(this._self, this._then);

  final _SubscriptionState _self;
  final $Res Function(_SubscriptionState) _then;

/// Create a copy of SubscriptionState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? userId = null,Object? status = null,Object? entitled = null,Object? expiresAt = freezed,Object? graceExpiresAt = freezed,Object? periodType = freezed,Object? willRenew = null,Object? trialUsed = null,Object? source = null,Object? lastCheckedAt = null,}) {
  return _then(_SubscriptionState(
userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as EntitlementStatus,entitled: null == entitled ? _self.entitled : entitled // ignore: cast_nullable_to_non_nullable
as bool,expiresAt: freezed == expiresAt ? _self.expiresAt : expiresAt // ignore: cast_nullable_to_non_nullable
as DateTime?,graceExpiresAt: freezed == graceExpiresAt ? _self.graceExpiresAt : graceExpiresAt // ignore: cast_nullable_to_non_nullable
as DateTime?,periodType: freezed == periodType ? _self.periodType : periodType // ignore: cast_nullable_to_non_nullable
as String?,willRenew: null == willRenew ? _self.willRenew : willRenew // ignore: cast_nullable_to_non_nullable
as bool,trialUsed: null == trialUsed ? _self.trialUsed : trialUsed // ignore: cast_nullable_to_non_nullable
as bool,source: null == source ? _self.source : source // ignore: cast_nullable_to_non_nullable
as SubscriptionSource,lastCheckedAt: null == lastCheckedAt ? _self.lastCheckedAt : lastCheckedAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}

/// @nodoc
mixin _$ReadingQuota {

 String get userId; String get month; int get used; int get reserved; int get limit;
/// Create a copy of ReadingQuota
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ReadingQuotaCopyWith<ReadingQuota> get copyWith => _$ReadingQuotaCopyWithImpl<ReadingQuota>(this as ReadingQuota, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as ReadingQuota;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ReadingQuota&&(identical(other.userId, _this.userId) || other.userId == _this.userId)&&(identical(other.month, _this.month) || other.month == _this.month)&&(identical(other.used, _this.used) || other.used == _this.used)&&(identical(other.reserved, _this.reserved) || other.reserved == _this.reserved)&&(identical(other.limit, _this.limit) || other.limit == _this.limit));
}


@override
int get hashCode {
  final _this = this as ReadingQuota;
  return Object.hash(runtimeType,_this.userId,_this.month,_this.used,_this.reserved,_this.limit);
}

@override
String toString() {
  final _this = this as ReadingQuota;
  return 'ReadingQuota(userId: ${_this.userId}, month: ${_this.month}, used: ${_this.used}, reserved: ${_this.reserved}, limit: ${_this.limit})';
}


}

/// @nodoc
abstract mixin class $ReadingQuotaCopyWith<$Res>  {
  factory $ReadingQuotaCopyWith(ReadingQuota value, $Res Function(ReadingQuota) _then) = _$ReadingQuotaCopyWithImpl;
@useResult
$Res call({
 String userId, String month, int used, int reserved, int limit
});




}
/// @nodoc
class _$ReadingQuotaCopyWithImpl<$Res>
    implements $ReadingQuotaCopyWith<$Res> {
  _$ReadingQuotaCopyWithImpl(this._self, this._then);

  final ReadingQuota _self;
  final $Res Function(ReadingQuota) _then;

/// Create a copy of ReadingQuota
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? userId = null,Object? month = null,Object? used = null,Object? reserved = null,Object? limit = null,}) {
  return _then(ReadingQuota(
userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,month: null == month ? _self.month : month // ignore: cast_nullable_to_non_nullable
as String,used: null == used ? _self.used : used // ignore: cast_nullable_to_non_nullable
as int,reserved: null == reserved ? _self.reserved : reserved // ignore: cast_nullable_to_non_nullable
as int,limit: null == limit ? _self.limit : limit // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [ReadingQuota].
extension ReadingQuotaPatterns on ReadingQuota {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ReadingQuota value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ReadingQuota() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ReadingQuota value)  $default,){
final _that = this;
switch (_that) {
case _ReadingQuota():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ReadingQuota value)?  $default,){
final _that = this;
switch (_that) {
case _ReadingQuota() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String userId,  String month,  int used,  int reserved,  int limit)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ReadingQuota() when $default != null:
return $default(_that.userId,_that.month,_that.used,_that.reserved,_that.limit);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String userId,  String month,  int used,  int reserved,  int limit)  $default,) {final _that = this;
switch (_that) {
case _ReadingQuota():
return $default(_that.userId,_that.month,_that.used,_that.reserved,_that.limit);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String userId,  String month,  int used,  int reserved,  int limit)?  $default,) {final _that = this;
switch (_that) {
case _ReadingQuota() when $default != null:
return $default(_that.userId,_that.month,_that.used,_that.reserved,_that.limit);case _:
  return null;

}
}

}

/// @nodoc


class _ReadingQuota extends ReadingQuota {
  const _ReadingQuota({required this.userId, required this.month, required this.used, required this.reserved, required this.limit}): super._();
  

@override final  String userId;
@override final  String month;
@override final  int used;
@override final  int reserved;
@override final  int limit;

/// Create a copy of ReadingQuota
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ReadingQuotaCopyWith<_ReadingQuota> get copyWith => __$ReadingQuotaCopyWithImpl<_ReadingQuota>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _ReadingQuota&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.month, month) || other.month == month)&&(identical(other.used, used) || other.used == used)&&(identical(other.reserved, reserved) || other.reserved == reserved)&&(identical(other.limit, limit) || other.limit == limit));
}


@override
int get hashCode {
    return Object.hash(runtimeType,userId,month,used,reserved,limit);
}

@override
String toString() {
    return 'ReadingQuota(userId: $userId, month: $month, used: $used, reserved: $reserved, limit: $limit)';
}


}

/// @nodoc
abstract mixin class _$ReadingQuotaCopyWith<$Res> implements $ReadingQuotaCopyWith<$Res> {
  factory _$ReadingQuotaCopyWith(_ReadingQuota value, $Res Function(_ReadingQuota) _then) = __$ReadingQuotaCopyWithImpl;
@override @useResult
$Res call({
 String userId, String month, int used, int reserved, int limit
});




}
/// @nodoc
class __$ReadingQuotaCopyWithImpl<$Res>
    implements _$ReadingQuotaCopyWith<$Res> {
  __$ReadingQuotaCopyWithImpl(this._self, this._then);

  final _ReadingQuota _self;
  final $Res Function(_ReadingQuota) _then;

/// Create a copy of ReadingQuota
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? userId = null,Object? month = null,Object? used = null,Object? reserved = null,Object? limit = null,}) {
  return _then(_ReadingQuota(
userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,month: null == month ? _self.month : month // ignore: cast_nullable_to_non_nullable
as String,used: null == used ? _self.used : used // ignore: cast_nullable_to_non_nullable
as int,reserved: null == reserved ? _self.reserved : reserved // ignore: cast_nullable_to_non_nullable
as int,limit: null == limit ? _self.limit : limit // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on
