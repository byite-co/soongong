// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'reading.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$ReadingRequest {

 String get id; SyncStamp get stamp; String get requestId; String get subjectId; String get rangeText; String? get sessionId; String? get plannerItemId; ReadingOrigin get origin; String? get payloadHash; ReadingRequestStatus get status; DateTime? get submittedAt; DateTime? get completedAt; String? get quotaMonth; bool get quotaCharged; String? get resultJson; String? get marksJson; String? get failReason; String? get confirmedMarksJson;
/// Create a copy of ReadingRequest
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ReadingRequestCopyWith<ReadingRequest> get copyWith => _$ReadingRequestCopyWithImpl<ReadingRequest>(this as ReadingRequest, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as ReadingRequest;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ReadingRequest&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.stamp, _this.stamp) || other.stamp == _this.stamp)&&(identical(other.requestId, _this.requestId) || other.requestId == _this.requestId)&&(identical(other.subjectId, _this.subjectId) || other.subjectId == _this.subjectId)&&(identical(other.rangeText, _this.rangeText) || other.rangeText == _this.rangeText)&&(identical(other.sessionId, _this.sessionId) || other.sessionId == _this.sessionId)&&(identical(other.plannerItemId, _this.plannerItemId) || other.plannerItemId == _this.plannerItemId)&&(identical(other.origin, _this.origin) || other.origin == _this.origin)&&(identical(other.payloadHash, _this.payloadHash) || other.payloadHash == _this.payloadHash)&&(identical(other.status, _this.status) || other.status == _this.status)&&(identical(other.submittedAt, _this.submittedAt) || other.submittedAt == _this.submittedAt)&&(identical(other.completedAt, _this.completedAt) || other.completedAt == _this.completedAt)&&(identical(other.quotaMonth, _this.quotaMonth) || other.quotaMonth == _this.quotaMonth)&&(identical(other.quotaCharged, _this.quotaCharged) || other.quotaCharged == _this.quotaCharged)&&(identical(other.resultJson, _this.resultJson) || other.resultJson == _this.resultJson)&&(identical(other.marksJson, _this.marksJson) || other.marksJson == _this.marksJson)&&(identical(other.failReason, _this.failReason) || other.failReason == _this.failReason)&&(identical(other.confirmedMarksJson, _this.confirmedMarksJson) || other.confirmedMarksJson == _this.confirmedMarksJson));
}


@override
int get hashCode {
  final _this = this as ReadingRequest;
  return Object.hash(runtimeType,_this.id,_this.stamp,_this.requestId,_this.subjectId,_this.rangeText,_this.sessionId,_this.plannerItemId,_this.origin,_this.payloadHash,_this.status,_this.submittedAt,_this.completedAt,_this.quotaMonth,_this.quotaCharged,_this.resultJson,_this.marksJson,_this.failReason,_this.confirmedMarksJson);
}

@override
String toString() {
  final _this = this as ReadingRequest;
  return 'ReadingRequest(id: ${_this.id}, stamp: ${_this.stamp}, requestId: ${_this.requestId}, subjectId: ${_this.subjectId}, rangeText: ${_this.rangeText}, sessionId: ${_this.sessionId}, plannerItemId: ${_this.plannerItemId}, origin: ${_this.origin}, payloadHash: ${_this.payloadHash}, status: ${_this.status}, submittedAt: ${_this.submittedAt}, completedAt: ${_this.completedAt}, quotaMonth: ${_this.quotaMonth}, quotaCharged: ${_this.quotaCharged}, resultJson: ${_this.resultJson}, marksJson: ${_this.marksJson}, failReason: ${_this.failReason}, confirmedMarksJson: ${_this.confirmedMarksJson})';
}


}

/// @nodoc
abstract mixin class $ReadingRequestCopyWith<$Res>  {
  factory $ReadingRequestCopyWith(ReadingRequest value, $Res Function(ReadingRequest) _then) = _$ReadingRequestCopyWithImpl;
@useResult
$Res call({
 String id, SyncStamp stamp, String requestId, String subjectId, String rangeText, String? sessionId, String? plannerItemId, ReadingOrigin origin, String? payloadHash, ReadingRequestStatus status, DateTime? submittedAt, DateTime? completedAt, String? quotaMonth, bool quotaCharged, String? resultJson, String? marksJson, String? failReason, String? confirmedMarksJson
});


$SyncStampCopyWith<$Res> get stamp;

}
/// @nodoc
class _$ReadingRequestCopyWithImpl<$Res>
    implements $ReadingRequestCopyWith<$Res> {
  _$ReadingRequestCopyWithImpl(this._self, this._then);

  final ReadingRequest _self;
  final $Res Function(ReadingRequest) _then;

/// Create a copy of ReadingRequest
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? stamp = null,Object? requestId = null,Object? subjectId = null,Object? rangeText = null,Object? sessionId = freezed,Object? plannerItemId = freezed,Object? origin = null,Object? payloadHash = freezed,Object? status = null,Object? submittedAt = freezed,Object? completedAt = freezed,Object? quotaMonth = freezed,Object? quotaCharged = null,Object? resultJson = freezed,Object? marksJson = freezed,Object? failReason = freezed,Object? confirmedMarksJson = freezed,}) {
  return _then(ReadingRequest(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,stamp: null == stamp ? _self.stamp : stamp // ignore: cast_nullable_to_non_nullable
as SyncStamp,requestId: null == requestId ? _self.requestId : requestId // ignore: cast_nullable_to_non_nullable
as String,subjectId: null == subjectId ? _self.subjectId : subjectId // ignore: cast_nullable_to_non_nullable
as String,rangeText: null == rangeText ? _self.rangeText : rangeText // ignore: cast_nullable_to_non_nullable
as String,sessionId: freezed == sessionId ? _self.sessionId : sessionId // ignore: cast_nullable_to_non_nullable
as String?,plannerItemId: freezed == plannerItemId ? _self.plannerItemId : plannerItemId // ignore: cast_nullable_to_non_nullable
as String?,origin: null == origin ? _self.origin : origin // ignore: cast_nullable_to_non_nullable
as ReadingOrigin,payloadHash: freezed == payloadHash ? _self.payloadHash : payloadHash // ignore: cast_nullable_to_non_nullable
as String?,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as ReadingRequestStatus,submittedAt: freezed == submittedAt ? _self.submittedAt : submittedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,completedAt: freezed == completedAt ? _self.completedAt : completedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,quotaMonth: freezed == quotaMonth ? _self.quotaMonth : quotaMonth // ignore: cast_nullable_to_non_nullable
as String?,quotaCharged: null == quotaCharged ? _self.quotaCharged : quotaCharged // ignore: cast_nullable_to_non_nullable
as bool,resultJson: freezed == resultJson ? _self.resultJson : resultJson // ignore: cast_nullable_to_non_nullable
as String?,marksJson: freezed == marksJson ? _self.marksJson : marksJson // ignore: cast_nullable_to_non_nullable
as String?,failReason: freezed == failReason ? _self.failReason : failReason // ignore: cast_nullable_to_non_nullable
as String?,confirmedMarksJson: freezed == confirmedMarksJson ? _self.confirmedMarksJson : confirmedMarksJson // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}
/// Create a copy of ReadingRequest
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$SyncStampCopyWith<$Res> get stamp {
  
  return $SyncStampCopyWith<$Res>(_self.stamp, (value) {
    return _then(_self.copyWith(stamp: value));
  });
}
}


/// Adds pattern-matching-related methods to [ReadingRequest].
extension ReadingRequestPatterns on ReadingRequest {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ReadingRequest value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ReadingRequest() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ReadingRequest value)  $default,){
final _that = this;
switch (_that) {
case _ReadingRequest():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ReadingRequest value)?  $default,){
final _that = this;
switch (_that) {
case _ReadingRequest() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  SyncStamp stamp,  String requestId,  String subjectId,  String rangeText,  String? sessionId,  String? plannerItemId,  ReadingOrigin origin,  String? payloadHash,  ReadingRequestStatus status,  DateTime? submittedAt,  DateTime? completedAt,  String? quotaMonth,  bool quotaCharged,  String? resultJson,  String? marksJson,  String? failReason,  String? confirmedMarksJson)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ReadingRequest() when $default != null:
return $default(_that.id,_that.stamp,_that.requestId,_that.subjectId,_that.rangeText,_that.sessionId,_that.plannerItemId,_that.origin,_that.payloadHash,_that.status,_that.submittedAt,_that.completedAt,_that.quotaMonth,_that.quotaCharged,_that.resultJson,_that.marksJson,_that.failReason,_that.confirmedMarksJson);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  SyncStamp stamp,  String requestId,  String subjectId,  String rangeText,  String? sessionId,  String? plannerItemId,  ReadingOrigin origin,  String? payloadHash,  ReadingRequestStatus status,  DateTime? submittedAt,  DateTime? completedAt,  String? quotaMonth,  bool quotaCharged,  String? resultJson,  String? marksJson,  String? failReason,  String? confirmedMarksJson)  $default,) {final _that = this;
switch (_that) {
case _ReadingRequest():
return $default(_that.id,_that.stamp,_that.requestId,_that.subjectId,_that.rangeText,_that.sessionId,_that.plannerItemId,_that.origin,_that.payloadHash,_that.status,_that.submittedAt,_that.completedAt,_that.quotaMonth,_that.quotaCharged,_that.resultJson,_that.marksJson,_that.failReason,_that.confirmedMarksJson);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  SyncStamp stamp,  String requestId,  String subjectId,  String rangeText,  String? sessionId,  String? plannerItemId,  ReadingOrigin origin,  String? payloadHash,  ReadingRequestStatus status,  DateTime? submittedAt,  DateTime? completedAt,  String? quotaMonth,  bool quotaCharged,  String? resultJson,  String? marksJson,  String? failReason,  String? confirmedMarksJson)?  $default,) {final _that = this;
switch (_that) {
case _ReadingRequest() when $default != null:
return $default(_that.id,_that.stamp,_that.requestId,_that.subjectId,_that.rangeText,_that.sessionId,_that.plannerItemId,_that.origin,_that.payloadHash,_that.status,_that.submittedAt,_that.completedAt,_that.quotaMonth,_that.quotaCharged,_that.resultJson,_that.marksJson,_that.failReason,_that.confirmedMarksJson);case _:
  return null;

}
}

}

/// @nodoc


class _ReadingRequest extends ReadingRequest {
  const _ReadingRequest({required this.id, required this.stamp, required this.requestId, required this.subjectId, required this.rangeText, this.sessionId, this.plannerItemId, required this.origin, this.payloadHash, required this.status, this.submittedAt, this.completedAt, this.quotaMonth, this.quotaCharged = false, this.resultJson, this.marksJson, this.failReason, this.confirmedMarksJson}): super._();
  

@override final  String id;
@override final  SyncStamp stamp;
@override final  String requestId;
@override final  String subjectId;
@override final  String rangeText;
@override final  String? sessionId;
@override final  String? plannerItemId;
@override final  ReadingOrigin origin;
@override final  String? payloadHash;
@override final  ReadingRequestStatus status;
@override final  DateTime? submittedAt;
@override final  DateTime? completedAt;
@override final  String? quotaMonth;
@override@JsonKey() final  bool quotaCharged;
@override final  String? resultJson;
@override final  String? marksJson;
@override final  String? failReason;
@override final  String? confirmedMarksJson;

/// Create a copy of ReadingRequest
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ReadingRequestCopyWith<_ReadingRequest> get copyWith => __$ReadingRequestCopyWithImpl<_ReadingRequest>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _ReadingRequest&&(identical(other.id, id) || other.id == id)&&(identical(other.stamp, stamp) || other.stamp == stamp)&&(identical(other.requestId, requestId) || other.requestId == requestId)&&(identical(other.subjectId, subjectId) || other.subjectId == subjectId)&&(identical(other.rangeText, rangeText) || other.rangeText == rangeText)&&(identical(other.sessionId, sessionId) || other.sessionId == sessionId)&&(identical(other.plannerItemId, plannerItemId) || other.plannerItemId == plannerItemId)&&(identical(other.origin, origin) || other.origin == origin)&&(identical(other.payloadHash, payloadHash) || other.payloadHash == payloadHash)&&(identical(other.status, status) || other.status == status)&&(identical(other.submittedAt, submittedAt) || other.submittedAt == submittedAt)&&(identical(other.completedAt, completedAt) || other.completedAt == completedAt)&&(identical(other.quotaMonth, quotaMonth) || other.quotaMonth == quotaMonth)&&(identical(other.quotaCharged, quotaCharged) || other.quotaCharged == quotaCharged)&&(identical(other.resultJson, resultJson) || other.resultJson == resultJson)&&(identical(other.marksJson, marksJson) || other.marksJson == marksJson)&&(identical(other.failReason, failReason) || other.failReason == failReason)&&(identical(other.confirmedMarksJson, confirmedMarksJson) || other.confirmedMarksJson == confirmedMarksJson));
}


@override
int get hashCode {
    return Object.hash(runtimeType,id,stamp,requestId,subjectId,rangeText,sessionId,plannerItemId,origin,payloadHash,status,submittedAt,completedAt,quotaMonth,quotaCharged,resultJson,marksJson,failReason,confirmedMarksJson);
}

@override
String toString() {
    return 'ReadingRequest(id: $id, stamp: $stamp, requestId: $requestId, subjectId: $subjectId, rangeText: $rangeText, sessionId: $sessionId, plannerItemId: $plannerItemId, origin: $origin, payloadHash: $payloadHash, status: $status, submittedAt: $submittedAt, completedAt: $completedAt, quotaMonth: $quotaMonth, quotaCharged: $quotaCharged, resultJson: $resultJson, marksJson: $marksJson, failReason: $failReason, confirmedMarksJson: $confirmedMarksJson)';
}


}

/// @nodoc
abstract mixin class _$ReadingRequestCopyWith<$Res> implements $ReadingRequestCopyWith<$Res> {
  factory _$ReadingRequestCopyWith(_ReadingRequest value, $Res Function(_ReadingRequest) _then) = __$ReadingRequestCopyWithImpl;
@override @useResult
$Res call({
 String id, SyncStamp stamp, String requestId, String subjectId, String rangeText, String? sessionId, String? plannerItemId, ReadingOrigin origin, String? payloadHash, ReadingRequestStatus status, DateTime? submittedAt, DateTime? completedAt, String? quotaMonth, bool quotaCharged, String? resultJson, String? marksJson, String? failReason, String? confirmedMarksJson
});


@override $SyncStampCopyWith<$Res> get stamp;

}
/// @nodoc
class __$ReadingRequestCopyWithImpl<$Res>
    implements _$ReadingRequestCopyWith<$Res> {
  __$ReadingRequestCopyWithImpl(this._self, this._then);

  final _ReadingRequest _self;
  final $Res Function(_ReadingRequest) _then;

/// Create a copy of ReadingRequest
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? stamp = null,Object? requestId = null,Object? subjectId = null,Object? rangeText = null,Object? sessionId = freezed,Object? plannerItemId = freezed,Object? origin = null,Object? payloadHash = freezed,Object? status = null,Object? submittedAt = freezed,Object? completedAt = freezed,Object? quotaMonth = freezed,Object? quotaCharged = null,Object? resultJson = freezed,Object? marksJson = freezed,Object? failReason = freezed,Object? confirmedMarksJson = freezed,}) {
  return _then(_ReadingRequest(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,stamp: null == stamp ? _self.stamp : stamp // ignore: cast_nullable_to_non_nullable
as SyncStamp,requestId: null == requestId ? _self.requestId : requestId // ignore: cast_nullable_to_non_nullable
as String,subjectId: null == subjectId ? _self.subjectId : subjectId // ignore: cast_nullable_to_non_nullable
as String,rangeText: null == rangeText ? _self.rangeText : rangeText // ignore: cast_nullable_to_non_nullable
as String,sessionId: freezed == sessionId ? _self.sessionId : sessionId // ignore: cast_nullable_to_non_nullable
as String?,plannerItemId: freezed == plannerItemId ? _self.plannerItemId : plannerItemId // ignore: cast_nullable_to_non_nullable
as String?,origin: null == origin ? _self.origin : origin // ignore: cast_nullable_to_non_nullable
as ReadingOrigin,payloadHash: freezed == payloadHash ? _self.payloadHash : payloadHash // ignore: cast_nullable_to_non_nullable
as String?,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as ReadingRequestStatus,submittedAt: freezed == submittedAt ? _self.submittedAt : submittedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,completedAt: freezed == completedAt ? _self.completedAt : completedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,quotaMonth: freezed == quotaMonth ? _self.quotaMonth : quotaMonth // ignore: cast_nullable_to_non_nullable
as String?,quotaCharged: null == quotaCharged ? _self.quotaCharged : quotaCharged // ignore: cast_nullable_to_non_nullable
as bool,resultJson: freezed == resultJson ? _self.resultJson : resultJson // ignore: cast_nullable_to_non_nullable
as String?,marksJson: freezed == marksJson ? _self.marksJson : marksJson // ignore: cast_nullable_to_non_nullable
as String?,failReason: freezed == failReason ? _self.failReason : failReason // ignore: cast_nullable_to_non_nullable
as String?,confirmedMarksJson: freezed == confirmedMarksJson ? _self.confirmedMarksJson : confirmedMarksJson // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

/// Create a copy of ReadingRequest
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$SyncStampCopyWith<$Res> get stamp {
  
  return $SyncStampCopyWith<$Res>(_self.stamp, (value) {
    return _then(_self.copyWith(stamp: value));
  });
}
}

/// @nodoc
mixin _$Photo {

 String get id; String get userId; String? get requestId; String get localPath; DateTime get takenAt; DateTime get expiresAt; int get width; int get height; int get pageIndex; DateTime get createdAt; DateTime? get deletedAt;
/// Create a copy of Photo
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PhotoCopyWith<Photo> get copyWith => _$PhotoCopyWithImpl<Photo>(this as Photo, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as Photo;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Photo&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.userId, _this.userId) || other.userId == _this.userId)&&(identical(other.requestId, _this.requestId) || other.requestId == _this.requestId)&&(identical(other.localPath, _this.localPath) || other.localPath == _this.localPath)&&(identical(other.takenAt, _this.takenAt) || other.takenAt == _this.takenAt)&&(identical(other.expiresAt, _this.expiresAt) || other.expiresAt == _this.expiresAt)&&(identical(other.width, _this.width) || other.width == _this.width)&&(identical(other.height, _this.height) || other.height == _this.height)&&(identical(other.pageIndex, _this.pageIndex) || other.pageIndex == _this.pageIndex)&&(identical(other.createdAt, _this.createdAt) || other.createdAt == _this.createdAt)&&(identical(other.deletedAt, _this.deletedAt) || other.deletedAt == _this.deletedAt));
}


@override
int get hashCode {
  final _this = this as Photo;
  return Object.hash(runtimeType,_this.id,_this.userId,_this.requestId,_this.localPath,_this.takenAt,_this.expiresAt,_this.width,_this.height,_this.pageIndex,_this.createdAt,_this.deletedAt);
}

@override
String toString() {
  final _this = this as Photo;
  return 'Photo(id: ${_this.id}, userId: ${_this.userId}, requestId: ${_this.requestId}, localPath: ${_this.localPath}, takenAt: ${_this.takenAt}, expiresAt: ${_this.expiresAt}, width: ${_this.width}, height: ${_this.height}, pageIndex: ${_this.pageIndex}, createdAt: ${_this.createdAt}, deletedAt: ${_this.deletedAt})';
}


}

/// @nodoc
abstract mixin class $PhotoCopyWith<$Res>  {
  factory $PhotoCopyWith(Photo value, $Res Function(Photo) _then) = _$PhotoCopyWithImpl;
@useResult
$Res call({
 String id, String userId, String? requestId, String localPath, DateTime takenAt, DateTime expiresAt, int width, int height, int pageIndex, DateTime createdAt, DateTime? deletedAt
});




}
/// @nodoc
class _$PhotoCopyWithImpl<$Res>
    implements $PhotoCopyWith<$Res> {
  _$PhotoCopyWithImpl(this._self, this._then);

  final Photo _self;
  final $Res Function(Photo) _then;

/// Create a copy of Photo
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? userId = null,Object? requestId = freezed,Object? localPath = null,Object? takenAt = null,Object? expiresAt = null,Object? width = null,Object? height = null,Object? pageIndex = null,Object? createdAt = null,Object? deletedAt = freezed,}) {
  return _then(Photo(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,requestId: freezed == requestId ? _self.requestId : requestId // ignore: cast_nullable_to_non_nullable
as String?,localPath: null == localPath ? _self.localPath : localPath // ignore: cast_nullable_to_non_nullable
as String,takenAt: null == takenAt ? _self.takenAt : takenAt // ignore: cast_nullable_to_non_nullable
as DateTime,expiresAt: null == expiresAt ? _self.expiresAt : expiresAt // ignore: cast_nullable_to_non_nullable
as DateTime,width: null == width ? _self.width : width // ignore: cast_nullable_to_non_nullable
as int,height: null == height ? _self.height : height // ignore: cast_nullable_to_non_nullable
as int,pageIndex: null == pageIndex ? _self.pageIndex : pageIndex // ignore: cast_nullable_to_non_nullable
as int,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,deletedAt: freezed == deletedAt ? _self.deletedAt : deletedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [Photo].
extension PhotoPatterns on Photo {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Photo value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Photo() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Photo value)  $default,){
final _that = this;
switch (_that) {
case _Photo():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Photo value)?  $default,){
final _that = this;
switch (_that) {
case _Photo() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String userId,  String? requestId,  String localPath,  DateTime takenAt,  DateTime expiresAt,  int width,  int height,  int pageIndex,  DateTime createdAt,  DateTime? deletedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Photo() when $default != null:
return $default(_that.id,_that.userId,_that.requestId,_that.localPath,_that.takenAt,_that.expiresAt,_that.width,_that.height,_that.pageIndex,_that.createdAt,_that.deletedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String userId,  String? requestId,  String localPath,  DateTime takenAt,  DateTime expiresAt,  int width,  int height,  int pageIndex,  DateTime createdAt,  DateTime? deletedAt)  $default,) {final _that = this;
switch (_that) {
case _Photo():
return $default(_that.id,_that.userId,_that.requestId,_that.localPath,_that.takenAt,_that.expiresAt,_that.width,_that.height,_that.pageIndex,_that.createdAt,_that.deletedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String userId,  String? requestId,  String localPath,  DateTime takenAt,  DateTime expiresAt,  int width,  int height,  int pageIndex,  DateTime createdAt,  DateTime? deletedAt)?  $default,) {final _that = this;
switch (_that) {
case _Photo() when $default != null:
return $default(_that.id,_that.userId,_that.requestId,_that.localPath,_that.takenAt,_that.expiresAt,_that.width,_that.height,_that.pageIndex,_that.createdAt,_that.deletedAt);case _:
  return null;

}
}

}

/// @nodoc


class _Photo extends Photo {
  const _Photo({required this.id, required this.userId, this.requestId, required this.localPath, required this.takenAt, required this.expiresAt, required this.width, required this.height, required this.pageIndex, required this.createdAt, this.deletedAt}): super._();
  

@override final  String id;
@override final  String userId;
@override final  String? requestId;
@override final  String localPath;
@override final  DateTime takenAt;
@override final  DateTime expiresAt;
@override final  int width;
@override final  int height;
@override final  int pageIndex;
@override final  DateTime createdAt;
@override final  DateTime? deletedAt;

/// Create a copy of Photo
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PhotoCopyWith<_Photo> get copyWith => __$PhotoCopyWithImpl<_Photo>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _Photo&&(identical(other.id, id) || other.id == id)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.requestId, requestId) || other.requestId == requestId)&&(identical(other.localPath, localPath) || other.localPath == localPath)&&(identical(other.takenAt, takenAt) || other.takenAt == takenAt)&&(identical(other.expiresAt, expiresAt) || other.expiresAt == expiresAt)&&(identical(other.width, width) || other.width == width)&&(identical(other.height, height) || other.height == height)&&(identical(other.pageIndex, pageIndex) || other.pageIndex == pageIndex)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.deletedAt, deletedAt) || other.deletedAt == deletedAt));
}


@override
int get hashCode {
    return Object.hash(runtimeType,id,userId,requestId,localPath,takenAt,expiresAt,width,height,pageIndex,createdAt,deletedAt);
}

@override
String toString() {
    return 'Photo(id: $id, userId: $userId, requestId: $requestId, localPath: $localPath, takenAt: $takenAt, expiresAt: $expiresAt, width: $width, height: $height, pageIndex: $pageIndex, createdAt: $createdAt, deletedAt: $deletedAt)';
}


}

/// @nodoc
abstract mixin class _$PhotoCopyWith<$Res> implements $PhotoCopyWith<$Res> {
  factory _$PhotoCopyWith(_Photo value, $Res Function(_Photo) _then) = __$PhotoCopyWithImpl;
@override @useResult
$Res call({
 String id, String userId, String? requestId, String localPath, DateTime takenAt, DateTime expiresAt, int width, int height, int pageIndex, DateTime createdAt, DateTime? deletedAt
});




}
/// @nodoc
class __$PhotoCopyWithImpl<$Res>
    implements _$PhotoCopyWith<$Res> {
  __$PhotoCopyWithImpl(this._self, this._then);

  final _Photo _self;
  final $Res Function(_Photo) _then;

/// Create a copy of Photo
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? userId = null,Object? requestId = freezed,Object? localPath = null,Object? takenAt = null,Object? expiresAt = null,Object? width = null,Object? height = null,Object? pageIndex = null,Object? createdAt = null,Object? deletedAt = freezed,}) {
  return _then(_Photo(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,requestId: freezed == requestId ? _self.requestId : requestId // ignore: cast_nullable_to_non_nullable
as String?,localPath: null == localPath ? _self.localPath : localPath // ignore: cast_nullable_to_non_nullable
as String,takenAt: null == takenAt ? _self.takenAt : takenAt // ignore: cast_nullable_to_non_nullable
as DateTime,expiresAt: null == expiresAt ? _self.expiresAt : expiresAt // ignore: cast_nullable_to_non_nullable
as DateTime,width: null == width ? _self.width : width // ignore: cast_nullable_to_non_nullable
as int,height: null == height ? _self.height : height // ignore: cast_nullable_to_non_nullable
as int,pageIndex: null == pageIndex ? _self.pageIndex : pageIndex // ignore: cast_nullable_to_non_nullable
as int,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,deletedAt: freezed == deletedAt ? _self.deletedAt : deletedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

/// @nodoc
mixin _$WrongItem {

 String get id; SyncStamp get stamp; String get requestId; String get subjectId; String get rangeText; int get pageIndex; int get number; WrongMark get mark; double get confidence; bool get userConfirmed; WrongItemStatus get status; DateTime? get resolvedAt;
/// Create a copy of WrongItem
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$WrongItemCopyWith<WrongItem> get copyWith => _$WrongItemCopyWithImpl<WrongItem>(this as WrongItem, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as WrongItem;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is WrongItem&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.stamp, _this.stamp) || other.stamp == _this.stamp)&&(identical(other.requestId, _this.requestId) || other.requestId == _this.requestId)&&(identical(other.subjectId, _this.subjectId) || other.subjectId == _this.subjectId)&&(identical(other.rangeText, _this.rangeText) || other.rangeText == _this.rangeText)&&(identical(other.pageIndex, _this.pageIndex) || other.pageIndex == _this.pageIndex)&&(identical(other.number, _this.number) || other.number == _this.number)&&(identical(other.mark, _this.mark) || other.mark == _this.mark)&&(identical(other.confidence, _this.confidence) || other.confidence == _this.confidence)&&(identical(other.userConfirmed, _this.userConfirmed) || other.userConfirmed == _this.userConfirmed)&&(identical(other.status, _this.status) || other.status == _this.status)&&(identical(other.resolvedAt, _this.resolvedAt) || other.resolvedAt == _this.resolvedAt));
}


@override
int get hashCode {
  final _this = this as WrongItem;
  return Object.hash(runtimeType,_this.id,_this.stamp,_this.requestId,_this.subjectId,_this.rangeText,_this.pageIndex,_this.number,_this.mark,_this.confidence,_this.userConfirmed,_this.status,_this.resolvedAt);
}

@override
String toString() {
  final _this = this as WrongItem;
  return 'WrongItem(id: ${_this.id}, stamp: ${_this.stamp}, requestId: ${_this.requestId}, subjectId: ${_this.subjectId}, rangeText: ${_this.rangeText}, pageIndex: ${_this.pageIndex}, number: ${_this.number}, mark: ${_this.mark}, confidence: ${_this.confidence}, userConfirmed: ${_this.userConfirmed}, status: ${_this.status}, resolvedAt: ${_this.resolvedAt})';
}


}

/// @nodoc
abstract mixin class $WrongItemCopyWith<$Res>  {
  factory $WrongItemCopyWith(WrongItem value, $Res Function(WrongItem) _then) = _$WrongItemCopyWithImpl;
@useResult
$Res call({
 String id, SyncStamp stamp, String requestId, String subjectId, String rangeText, int pageIndex, int number, WrongMark mark, double confidence, bool userConfirmed, WrongItemStatus status, DateTime? resolvedAt
});


$SyncStampCopyWith<$Res> get stamp;

}
/// @nodoc
class _$WrongItemCopyWithImpl<$Res>
    implements $WrongItemCopyWith<$Res> {
  _$WrongItemCopyWithImpl(this._self, this._then);

  final WrongItem _self;
  final $Res Function(WrongItem) _then;

/// Create a copy of WrongItem
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? stamp = null,Object? requestId = null,Object? subjectId = null,Object? rangeText = null,Object? pageIndex = null,Object? number = null,Object? mark = null,Object? confidence = null,Object? userConfirmed = null,Object? status = null,Object? resolvedAt = freezed,}) {
  return _then(WrongItem(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,stamp: null == stamp ? _self.stamp : stamp // ignore: cast_nullable_to_non_nullable
as SyncStamp,requestId: null == requestId ? _self.requestId : requestId // ignore: cast_nullable_to_non_nullable
as String,subjectId: null == subjectId ? _self.subjectId : subjectId // ignore: cast_nullable_to_non_nullable
as String,rangeText: null == rangeText ? _self.rangeText : rangeText // ignore: cast_nullable_to_non_nullable
as String,pageIndex: null == pageIndex ? _self.pageIndex : pageIndex // ignore: cast_nullable_to_non_nullable
as int,number: null == number ? _self.number : number // ignore: cast_nullable_to_non_nullable
as int,mark: null == mark ? _self.mark : mark // ignore: cast_nullable_to_non_nullable
as WrongMark,confidence: null == confidence ? _self.confidence : confidence // ignore: cast_nullable_to_non_nullable
as double,userConfirmed: null == userConfirmed ? _self.userConfirmed : userConfirmed // ignore: cast_nullable_to_non_nullable
as bool,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as WrongItemStatus,resolvedAt: freezed == resolvedAt ? _self.resolvedAt : resolvedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}
/// Create a copy of WrongItem
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$SyncStampCopyWith<$Res> get stamp {
  
  return $SyncStampCopyWith<$Res>(_self.stamp, (value) {
    return _then(_self.copyWith(stamp: value));
  });
}
}


/// Adds pattern-matching-related methods to [WrongItem].
extension WrongItemPatterns on WrongItem {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _WrongItem value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _WrongItem() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _WrongItem value)  $default,){
final _that = this;
switch (_that) {
case _WrongItem():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _WrongItem value)?  $default,){
final _that = this;
switch (_that) {
case _WrongItem() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  SyncStamp stamp,  String requestId,  String subjectId,  String rangeText,  int pageIndex,  int number,  WrongMark mark,  double confidence,  bool userConfirmed,  WrongItemStatus status,  DateTime? resolvedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _WrongItem() when $default != null:
return $default(_that.id,_that.stamp,_that.requestId,_that.subjectId,_that.rangeText,_that.pageIndex,_that.number,_that.mark,_that.confidence,_that.userConfirmed,_that.status,_that.resolvedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  SyncStamp stamp,  String requestId,  String subjectId,  String rangeText,  int pageIndex,  int number,  WrongMark mark,  double confidence,  bool userConfirmed,  WrongItemStatus status,  DateTime? resolvedAt)  $default,) {final _that = this;
switch (_that) {
case _WrongItem():
return $default(_that.id,_that.stamp,_that.requestId,_that.subjectId,_that.rangeText,_that.pageIndex,_that.number,_that.mark,_that.confidence,_that.userConfirmed,_that.status,_that.resolvedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  SyncStamp stamp,  String requestId,  String subjectId,  String rangeText,  int pageIndex,  int number,  WrongMark mark,  double confidence,  bool userConfirmed,  WrongItemStatus status,  DateTime? resolvedAt)?  $default,) {final _that = this;
switch (_that) {
case _WrongItem() when $default != null:
return $default(_that.id,_that.stamp,_that.requestId,_that.subjectId,_that.rangeText,_that.pageIndex,_that.number,_that.mark,_that.confidence,_that.userConfirmed,_that.status,_that.resolvedAt);case _:
  return null;

}
}

}

/// @nodoc


class _WrongItem implements WrongItem {
  const _WrongItem({required this.id, required this.stamp, required this.requestId, required this.subjectId, required this.rangeText, required this.pageIndex, required this.number, required this.mark, required this.confidence, required this.userConfirmed, this.status = WrongItemStatus.open, this.resolvedAt});
  

@override final  String id;
@override final  SyncStamp stamp;
@override final  String requestId;
@override final  String subjectId;
@override final  String rangeText;
@override final  int pageIndex;
@override final  int number;
@override final  WrongMark mark;
@override final  double confidence;
@override final  bool userConfirmed;
@override@JsonKey() final  WrongItemStatus status;
@override final  DateTime? resolvedAt;

/// Create a copy of WrongItem
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$WrongItemCopyWith<_WrongItem> get copyWith => __$WrongItemCopyWithImpl<_WrongItem>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _WrongItem&&(identical(other.id, id) || other.id == id)&&(identical(other.stamp, stamp) || other.stamp == stamp)&&(identical(other.requestId, requestId) || other.requestId == requestId)&&(identical(other.subjectId, subjectId) || other.subjectId == subjectId)&&(identical(other.rangeText, rangeText) || other.rangeText == rangeText)&&(identical(other.pageIndex, pageIndex) || other.pageIndex == pageIndex)&&(identical(other.number, number) || other.number == number)&&(identical(other.mark, mark) || other.mark == mark)&&(identical(other.confidence, confidence) || other.confidence == confidence)&&(identical(other.userConfirmed, userConfirmed) || other.userConfirmed == userConfirmed)&&(identical(other.status, status) || other.status == status)&&(identical(other.resolvedAt, resolvedAt) || other.resolvedAt == resolvedAt));
}


@override
int get hashCode {
    return Object.hash(runtimeType,id,stamp,requestId,subjectId,rangeText,pageIndex,number,mark,confidence,userConfirmed,status,resolvedAt);
}

@override
String toString() {
    return 'WrongItem(id: $id, stamp: $stamp, requestId: $requestId, subjectId: $subjectId, rangeText: $rangeText, pageIndex: $pageIndex, number: $number, mark: $mark, confidence: $confidence, userConfirmed: $userConfirmed, status: $status, resolvedAt: $resolvedAt)';
}


}

/// @nodoc
abstract mixin class _$WrongItemCopyWith<$Res> implements $WrongItemCopyWith<$Res> {
  factory _$WrongItemCopyWith(_WrongItem value, $Res Function(_WrongItem) _then) = __$WrongItemCopyWithImpl;
@override @useResult
$Res call({
 String id, SyncStamp stamp, String requestId, String subjectId, String rangeText, int pageIndex, int number, WrongMark mark, double confidence, bool userConfirmed, WrongItemStatus status, DateTime? resolvedAt
});


@override $SyncStampCopyWith<$Res> get stamp;

}
/// @nodoc
class __$WrongItemCopyWithImpl<$Res>
    implements _$WrongItemCopyWith<$Res> {
  __$WrongItemCopyWithImpl(this._self, this._then);

  final _WrongItem _self;
  final $Res Function(_WrongItem) _then;

/// Create a copy of WrongItem
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? stamp = null,Object? requestId = null,Object? subjectId = null,Object? rangeText = null,Object? pageIndex = null,Object? number = null,Object? mark = null,Object? confidence = null,Object? userConfirmed = null,Object? status = null,Object? resolvedAt = freezed,}) {
  return _then(_WrongItem(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,stamp: null == stamp ? _self.stamp : stamp // ignore: cast_nullable_to_non_nullable
as SyncStamp,requestId: null == requestId ? _self.requestId : requestId // ignore: cast_nullable_to_non_nullable
as String,subjectId: null == subjectId ? _self.subjectId : subjectId // ignore: cast_nullable_to_non_nullable
as String,rangeText: null == rangeText ? _self.rangeText : rangeText // ignore: cast_nullable_to_non_nullable
as String,pageIndex: null == pageIndex ? _self.pageIndex : pageIndex // ignore: cast_nullable_to_non_nullable
as int,number: null == number ? _self.number : number // ignore: cast_nullable_to_non_nullable
as int,mark: null == mark ? _self.mark : mark // ignore: cast_nullable_to_non_nullable
as WrongMark,confidence: null == confidence ? _self.confidence : confidence // ignore: cast_nullable_to_non_nullable
as double,userConfirmed: null == userConfirmed ? _self.userConfirmed : userConfirmed // ignore: cast_nullable_to_non_nullable
as bool,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as WrongItemStatus,resolvedAt: freezed == resolvedAt ? _self.resolvedAt : resolvedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

/// Create a copy of WrongItem
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$SyncStampCopyWith<$Res> get stamp {
  
  return $SyncStampCopyWith<$Res>(_self.stamp, (value) {
    return _then(_self.copyWith(stamp: value));
  });
}
}

/// @nodoc
mixin _$ReviewEntry {

 String get id; SyncStamp get stamp; String get wrongItemId; DateTime get dueAt; int get intervalDays; int get consecutiveCorrect; RetryResult? get lastResult;
/// Create a copy of ReviewEntry
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ReviewEntryCopyWith<ReviewEntry> get copyWith => _$ReviewEntryCopyWithImpl<ReviewEntry>(this as ReviewEntry, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as ReviewEntry;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ReviewEntry&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.stamp, _this.stamp) || other.stamp == _this.stamp)&&(identical(other.wrongItemId, _this.wrongItemId) || other.wrongItemId == _this.wrongItemId)&&(identical(other.dueAt, _this.dueAt) || other.dueAt == _this.dueAt)&&(identical(other.intervalDays, _this.intervalDays) || other.intervalDays == _this.intervalDays)&&(identical(other.consecutiveCorrect, _this.consecutiveCorrect) || other.consecutiveCorrect == _this.consecutiveCorrect)&&(identical(other.lastResult, _this.lastResult) || other.lastResult == _this.lastResult));
}


@override
int get hashCode {
  final _this = this as ReviewEntry;
  return Object.hash(runtimeType,_this.id,_this.stamp,_this.wrongItemId,_this.dueAt,_this.intervalDays,_this.consecutiveCorrect,_this.lastResult);
}

@override
String toString() {
  final _this = this as ReviewEntry;
  return 'ReviewEntry(id: ${_this.id}, stamp: ${_this.stamp}, wrongItemId: ${_this.wrongItemId}, dueAt: ${_this.dueAt}, intervalDays: ${_this.intervalDays}, consecutiveCorrect: ${_this.consecutiveCorrect}, lastResult: ${_this.lastResult})';
}


}

/// @nodoc
abstract mixin class $ReviewEntryCopyWith<$Res>  {
  factory $ReviewEntryCopyWith(ReviewEntry value, $Res Function(ReviewEntry) _then) = _$ReviewEntryCopyWithImpl;
@useResult
$Res call({
 String id, SyncStamp stamp, String wrongItemId, DateTime dueAt, int intervalDays, int consecutiveCorrect, RetryResult? lastResult
});


$SyncStampCopyWith<$Res> get stamp;

}
/// @nodoc
class _$ReviewEntryCopyWithImpl<$Res>
    implements $ReviewEntryCopyWith<$Res> {
  _$ReviewEntryCopyWithImpl(this._self, this._then);

  final ReviewEntry _self;
  final $Res Function(ReviewEntry) _then;

/// Create a copy of ReviewEntry
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? stamp = null,Object? wrongItemId = null,Object? dueAt = null,Object? intervalDays = null,Object? consecutiveCorrect = null,Object? lastResult = freezed,}) {
  return _then(ReviewEntry(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,stamp: null == stamp ? _self.stamp : stamp // ignore: cast_nullable_to_non_nullable
as SyncStamp,wrongItemId: null == wrongItemId ? _self.wrongItemId : wrongItemId // ignore: cast_nullable_to_non_nullable
as String,dueAt: null == dueAt ? _self.dueAt : dueAt // ignore: cast_nullable_to_non_nullable
as DateTime,intervalDays: null == intervalDays ? _self.intervalDays : intervalDays // ignore: cast_nullable_to_non_nullable
as int,consecutiveCorrect: null == consecutiveCorrect ? _self.consecutiveCorrect : consecutiveCorrect // ignore: cast_nullable_to_non_nullable
as int,lastResult: freezed == lastResult ? _self.lastResult : lastResult // ignore: cast_nullable_to_non_nullable
as RetryResult?,
  ));
}
/// Create a copy of ReviewEntry
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$SyncStampCopyWith<$Res> get stamp {
  
  return $SyncStampCopyWith<$Res>(_self.stamp, (value) {
    return _then(_self.copyWith(stamp: value));
  });
}
}


/// Adds pattern-matching-related methods to [ReviewEntry].
extension ReviewEntryPatterns on ReviewEntry {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ReviewEntry value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ReviewEntry() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ReviewEntry value)  $default,){
final _that = this;
switch (_that) {
case _ReviewEntry():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ReviewEntry value)?  $default,){
final _that = this;
switch (_that) {
case _ReviewEntry() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  SyncStamp stamp,  String wrongItemId,  DateTime dueAt,  int intervalDays,  int consecutiveCorrect,  RetryResult? lastResult)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ReviewEntry() when $default != null:
return $default(_that.id,_that.stamp,_that.wrongItemId,_that.dueAt,_that.intervalDays,_that.consecutiveCorrect,_that.lastResult);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  SyncStamp stamp,  String wrongItemId,  DateTime dueAt,  int intervalDays,  int consecutiveCorrect,  RetryResult? lastResult)  $default,) {final _that = this;
switch (_that) {
case _ReviewEntry():
return $default(_that.id,_that.stamp,_that.wrongItemId,_that.dueAt,_that.intervalDays,_that.consecutiveCorrect,_that.lastResult);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  SyncStamp stamp,  String wrongItemId,  DateTime dueAt,  int intervalDays,  int consecutiveCorrect,  RetryResult? lastResult)?  $default,) {final _that = this;
switch (_that) {
case _ReviewEntry() when $default != null:
return $default(_that.id,_that.stamp,_that.wrongItemId,_that.dueAt,_that.intervalDays,_that.consecutiveCorrect,_that.lastResult);case _:
  return null;

}
}

}

/// @nodoc


class _ReviewEntry implements ReviewEntry {
  const _ReviewEntry({required this.id, required this.stamp, required this.wrongItemId, required this.dueAt, required this.intervalDays, required this.consecutiveCorrect, this.lastResult});
  

@override final  String id;
@override final  SyncStamp stamp;
@override final  String wrongItemId;
@override final  DateTime dueAt;
@override final  int intervalDays;
@override final  int consecutiveCorrect;
@override final  RetryResult? lastResult;

/// Create a copy of ReviewEntry
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ReviewEntryCopyWith<_ReviewEntry> get copyWith => __$ReviewEntryCopyWithImpl<_ReviewEntry>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _ReviewEntry&&(identical(other.id, id) || other.id == id)&&(identical(other.stamp, stamp) || other.stamp == stamp)&&(identical(other.wrongItemId, wrongItemId) || other.wrongItemId == wrongItemId)&&(identical(other.dueAt, dueAt) || other.dueAt == dueAt)&&(identical(other.intervalDays, intervalDays) || other.intervalDays == intervalDays)&&(identical(other.consecutiveCorrect, consecutiveCorrect) || other.consecutiveCorrect == consecutiveCorrect)&&(identical(other.lastResult, lastResult) || other.lastResult == lastResult));
}


@override
int get hashCode {
    return Object.hash(runtimeType,id,stamp,wrongItemId,dueAt,intervalDays,consecutiveCorrect,lastResult);
}

@override
String toString() {
    return 'ReviewEntry(id: $id, stamp: $stamp, wrongItemId: $wrongItemId, dueAt: $dueAt, intervalDays: $intervalDays, consecutiveCorrect: $consecutiveCorrect, lastResult: $lastResult)';
}


}

/// @nodoc
abstract mixin class _$ReviewEntryCopyWith<$Res> implements $ReviewEntryCopyWith<$Res> {
  factory _$ReviewEntryCopyWith(_ReviewEntry value, $Res Function(_ReviewEntry) _then) = __$ReviewEntryCopyWithImpl;
@override @useResult
$Res call({
 String id, SyncStamp stamp, String wrongItemId, DateTime dueAt, int intervalDays, int consecutiveCorrect, RetryResult? lastResult
});


@override $SyncStampCopyWith<$Res> get stamp;

}
/// @nodoc
class __$ReviewEntryCopyWithImpl<$Res>
    implements _$ReviewEntryCopyWith<$Res> {
  __$ReviewEntryCopyWithImpl(this._self, this._then);

  final _ReviewEntry _self;
  final $Res Function(_ReviewEntry) _then;

/// Create a copy of ReviewEntry
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? stamp = null,Object? wrongItemId = null,Object? dueAt = null,Object? intervalDays = null,Object? consecutiveCorrect = null,Object? lastResult = freezed,}) {
  return _then(_ReviewEntry(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,stamp: null == stamp ? _self.stamp : stamp // ignore: cast_nullable_to_non_nullable
as SyncStamp,wrongItemId: null == wrongItemId ? _self.wrongItemId : wrongItemId // ignore: cast_nullable_to_non_nullable
as String,dueAt: null == dueAt ? _self.dueAt : dueAt // ignore: cast_nullable_to_non_nullable
as DateTime,intervalDays: null == intervalDays ? _self.intervalDays : intervalDays // ignore: cast_nullable_to_non_nullable
as int,consecutiveCorrect: null == consecutiveCorrect ? _self.consecutiveCorrect : consecutiveCorrect // ignore: cast_nullable_to_non_nullable
as int,lastResult: freezed == lastResult ? _self.lastResult : lastResult // ignore: cast_nullable_to_non_nullable
as RetryResult?,
  ));
}

/// Create a copy of ReviewEntry
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$SyncStampCopyWith<$Res> get stamp {
  
  return $SyncStampCopyWith<$Res>(_self.stamp, (value) {
    return _then(_self.copyWith(stamp: value));
  });
}
}

/// @nodoc
mixin _$RetryRecord {

 String get id; SyncStamp get stamp; String get wrongItemId; RetryResult get result; DateTime get at; bool get voided; DateTime? get voidedAt;
/// Create a copy of RetryRecord
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RetryRecordCopyWith<RetryRecord> get copyWith => _$RetryRecordCopyWithImpl<RetryRecord>(this as RetryRecord, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as RetryRecord;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RetryRecord&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.stamp, _this.stamp) || other.stamp == _this.stamp)&&(identical(other.wrongItemId, _this.wrongItemId) || other.wrongItemId == _this.wrongItemId)&&(identical(other.result, _this.result) || other.result == _this.result)&&(identical(other.at, _this.at) || other.at == _this.at)&&(identical(other.voided, _this.voided) || other.voided == _this.voided)&&(identical(other.voidedAt, _this.voidedAt) || other.voidedAt == _this.voidedAt));
}


@override
int get hashCode {
  final _this = this as RetryRecord;
  return Object.hash(runtimeType,_this.id,_this.stamp,_this.wrongItemId,_this.result,_this.at,_this.voided,_this.voidedAt);
}

@override
String toString() {
  final _this = this as RetryRecord;
  return 'RetryRecord(id: ${_this.id}, stamp: ${_this.stamp}, wrongItemId: ${_this.wrongItemId}, result: ${_this.result}, at: ${_this.at}, voided: ${_this.voided}, voidedAt: ${_this.voidedAt})';
}


}

/// @nodoc
abstract mixin class $RetryRecordCopyWith<$Res>  {
  factory $RetryRecordCopyWith(RetryRecord value, $Res Function(RetryRecord) _then) = _$RetryRecordCopyWithImpl;
@useResult
$Res call({
 String id, SyncStamp stamp, String wrongItemId, RetryResult result, DateTime at, bool voided, DateTime? voidedAt
});


$SyncStampCopyWith<$Res> get stamp;

}
/// @nodoc
class _$RetryRecordCopyWithImpl<$Res>
    implements $RetryRecordCopyWith<$Res> {
  _$RetryRecordCopyWithImpl(this._self, this._then);

  final RetryRecord _self;
  final $Res Function(RetryRecord) _then;

/// Create a copy of RetryRecord
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? stamp = null,Object? wrongItemId = null,Object? result = null,Object? at = null,Object? voided = null,Object? voidedAt = freezed,}) {
  return _then(RetryRecord(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,stamp: null == stamp ? _self.stamp : stamp // ignore: cast_nullable_to_non_nullable
as SyncStamp,wrongItemId: null == wrongItemId ? _self.wrongItemId : wrongItemId // ignore: cast_nullable_to_non_nullable
as String,result: null == result ? _self.result : result // ignore: cast_nullable_to_non_nullable
as RetryResult,at: null == at ? _self.at : at // ignore: cast_nullable_to_non_nullable
as DateTime,voided: null == voided ? _self.voided : voided // ignore: cast_nullable_to_non_nullable
as bool,voidedAt: freezed == voidedAt ? _self.voidedAt : voidedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}
/// Create a copy of RetryRecord
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$SyncStampCopyWith<$Res> get stamp {
  
  return $SyncStampCopyWith<$Res>(_self.stamp, (value) {
    return _then(_self.copyWith(stamp: value));
  });
}
}


/// Adds pattern-matching-related methods to [RetryRecord].
extension RetryRecordPatterns on RetryRecord {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _RetryRecord value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _RetryRecord() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _RetryRecord value)  $default,){
final _that = this;
switch (_that) {
case _RetryRecord():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _RetryRecord value)?  $default,){
final _that = this;
switch (_that) {
case _RetryRecord() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  SyncStamp stamp,  String wrongItemId,  RetryResult result,  DateTime at,  bool voided,  DateTime? voidedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _RetryRecord() when $default != null:
return $default(_that.id,_that.stamp,_that.wrongItemId,_that.result,_that.at,_that.voided,_that.voidedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  SyncStamp stamp,  String wrongItemId,  RetryResult result,  DateTime at,  bool voided,  DateTime? voidedAt)  $default,) {final _that = this;
switch (_that) {
case _RetryRecord():
return $default(_that.id,_that.stamp,_that.wrongItemId,_that.result,_that.at,_that.voided,_that.voidedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  SyncStamp stamp,  String wrongItemId,  RetryResult result,  DateTime at,  bool voided,  DateTime? voidedAt)?  $default,) {final _that = this;
switch (_that) {
case _RetryRecord() when $default != null:
return $default(_that.id,_that.stamp,_that.wrongItemId,_that.result,_that.at,_that.voided,_that.voidedAt);case _:
  return null;

}
}

}

/// @nodoc


class _RetryRecord implements RetryRecord {
  const _RetryRecord({required this.id, required this.stamp, required this.wrongItemId, required this.result, required this.at, this.voided = false, this.voidedAt});
  

@override final  String id;
@override final  SyncStamp stamp;
@override final  String wrongItemId;
@override final  RetryResult result;
@override final  DateTime at;
@override@JsonKey() final  bool voided;
@override final  DateTime? voidedAt;

/// Create a copy of RetryRecord
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$RetryRecordCopyWith<_RetryRecord> get copyWith => __$RetryRecordCopyWithImpl<_RetryRecord>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _RetryRecord&&(identical(other.id, id) || other.id == id)&&(identical(other.stamp, stamp) || other.stamp == stamp)&&(identical(other.wrongItemId, wrongItemId) || other.wrongItemId == wrongItemId)&&(identical(other.result, result) || other.result == result)&&(identical(other.at, at) || other.at == at)&&(identical(other.voided, voided) || other.voided == voided)&&(identical(other.voidedAt, voidedAt) || other.voidedAt == voidedAt));
}


@override
int get hashCode {
    return Object.hash(runtimeType,id,stamp,wrongItemId,result,at,voided,voidedAt);
}

@override
String toString() {
    return 'RetryRecord(id: $id, stamp: $stamp, wrongItemId: $wrongItemId, result: $result, at: $at, voided: $voided, voidedAt: $voidedAt)';
}


}

/// @nodoc
abstract mixin class _$RetryRecordCopyWith<$Res> implements $RetryRecordCopyWith<$Res> {
  factory _$RetryRecordCopyWith(_RetryRecord value, $Res Function(_RetryRecord) _then) = __$RetryRecordCopyWithImpl;
@override @useResult
$Res call({
 String id, SyncStamp stamp, String wrongItemId, RetryResult result, DateTime at, bool voided, DateTime? voidedAt
});


@override $SyncStampCopyWith<$Res> get stamp;

}
/// @nodoc
class __$RetryRecordCopyWithImpl<$Res>
    implements _$RetryRecordCopyWith<$Res> {
  __$RetryRecordCopyWithImpl(this._self, this._then);

  final _RetryRecord _self;
  final $Res Function(_RetryRecord) _then;

/// Create a copy of RetryRecord
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? stamp = null,Object? wrongItemId = null,Object? result = null,Object? at = null,Object? voided = null,Object? voidedAt = freezed,}) {
  return _then(_RetryRecord(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,stamp: null == stamp ? _self.stamp : stamp // ignore: cast_nullable_to_non_nullable
as SyncStamp,wrongItemId: null == wrongItemId ? _self.wrongItemId : wrongItemId // ignore: cast_nullable_to_non_nullable
as String,result: null == result ? _self.result : result // ignore: cast_nullable_to_non_nullable
as RetryResult,at: null == at ? _self.at : at // ignore: cast_nullable_to_non_nullable
as DateTime,voided: null == voided ? _self.voided : voided // ignore: cast_nullable_to_non_nullable
as bool,voidedAt: freezed == voidedAt ? _self.voidedAt : voidedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

/// Create a copy of RetryRecord
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
