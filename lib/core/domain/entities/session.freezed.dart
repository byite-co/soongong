// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'session.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$StudySession {

 String get id; SyncStamp get stamp; String? get subjectId; String? get plannerItemId; SessionKind get kind; SessionMode get mode; DateTime get startedAt; DateTime? get endedAt; SessionStatus get status; int get seatedSeconds; int get sensitivityLevel; String? get note;
/// Create a copy of StudySession
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$StudySessionCopyWith<StudySession> get copyWith => _$StudySessionCopyWithImpl<StudySession>(this as StudySession, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as StudySession;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is StudySession&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.stamp, _this.stamp) || other.stamp == _this.stamp)&&(identical(other.subjectId, _this.subjectId) || other.subjectId == _this.subjectId)&&(identical(other.plannerItemId, _this.plannerItemId) || other.plannerItemId == _this.plannerItemId)&&(identical(other.kind, _this.kind) || other.kind == _this.kind)&&(identical(other.mode, _this.mode) || other.mode == _this.mode)&&(identical(other.startedAt, _this.startedAt) || other.startedAt == _this.startedAt)&&(identical(other.endedAt, _this.endedAt) || other.endedAt == _this.endedAt)&&(identical(other.status, _this.status) || other.status == _this.status)&&(identical(other.seatedSeconds, _this.seatedSeconds) || other.seatedSeconds == _this.seatedSeconds)&&(identical(other.sensitivityLevel, _this.sensitivityLevel) || other.sensitivityLevel == _this.sensitivityLevel)&&(identical(other.note, _this.note) || other.note == _this.note));
}


@override
int get hashCode {
  final _this = this as StudySession;
  return Object.hash(runtimeType,_this.id,_this.stamp,_this.subjectId,_this.plannerItemId,_this.kind,_this.mode,_this.startedAt,_this.endedAt,_this.status,_this.seatedSeconds,_this.sensitivityLevel,_this.note);
}

@override
String toString() {
  final _this = this as StudySession;
  return 'StudySession(id: ${_this.id}, stamp: ${_this.stamp}, subjectId: ${_this.subjectId}, plannerItemId: ${_this.plannerItemId}, kind: ${_this.kind}, mode: ${_this.mode}, startedAt: ${_this.startedAt}, endedAt: ${_this.endedAt}, status: ${_this.status}, seatedSeconds: ${_this.seatedSeconds}, sensitivityLevel: ${_this.sensitivityLevel}, note: ${_this.note})';
}


}

/// @nodoc
abstract mixin class $StudySessionCopyWith<$Res>  {
  factory $StudySessionCopyWith(StudySession value, $Res Function(StudySession) _then) = _$StudySessionCopyWithImpl;
@useResult
$Res call({
 String id, SyncStamp stamp, String? subjectId, String? plannerItemId, SessionKind kind, SessionMode mode, DateTime startedAt, DateTime? endedAt, SessionStatus status, int seatedSeconds, int sensitivityLevel, String? note
});


$SyncStampCopyWith<$Res> get stamp;

}
/// @nodoc
class _$StudySessionCopyWithImpl<$Res>
    implements $StudySessionCopyWith<$Res> {
  _$StudySessionCopyWithImpl(this._self, this._then);

  final StudySession _self;
  final $Res Function(StudySession) _then;

/// Create a copy of StudySession
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? stamp = null,Object? subjectId = freezed,Object? plannerItemId = freezed,Object? kind = null,Object? mode = null,Object? startedAt = null,Object? endedAt = freezed,Object? status = null,Object? seatedSeconds = null,Object? sensitivityLevel = null,Object? note = freezed,}) {
  return _then(StudySession(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,stamp: null == stamp ? _self.stamp : stamp // ignore: cast_nullable_to_non_nullable
as SyncStamp,subjectId: freezed == subjectId ? _self.subjectId : subjectId // ignore: cast_nullable_to_non_nullable
as String?,plannerItemId: freezed == plannerItemId ? _self.plannerItemId : plannerItemId // ignore: cast_nullable_to_non_nullable
as String?,kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as SessionKind,mode: null == mode ? _self.mode : mode // ignore: cast_nullable_to_non_nullable
as SessionMode,startedAt: null == startedAt ? _self.startedAt : startedAt // ignore: cast_nullable_to_non_nullable
as DateTime,endedAt: freezed == endedAt ? _self.endedAt : endedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as SessionStatus,seatedSeconds: null == seatedSeconds ? _self.seatedSeconds : seatedSeconds // ignore: cast_nullable_to_non_nullable
as int,sensitivityLevel: null == sensitivityLevel ? _self.sensitivityLevel : sensitivityLevel // ignore: cast_nullable_to_non_nullable
as int,note: freezed == note ? _self.note : note // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}
/// Create a copy of StudySession
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$SyncStampCopyWith<$Res> get stamp {
  
  return $SyncStampCopyWith<$Res>(_self.stamp, (value) {
    return _then(_self.copyWith(stamp: value));
  });
}
}


/// Adds pattern-matching-related methods to [StudySession].
extension StudySessionPatterns on StudySession {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _StudySession value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _StudySession() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _StudySession value)  $default,){
final _that = this;
switch (_that) {
case _StudySession():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _StudySession value)?  $default,){
final _that = this;
switch (_that) {
case _StudySession() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  SyncStamp stamp,  String? subjectId,  String? plannerItemId,  SessionKind kind,  SessionMode mode,  DateTime startedAt,  DateTime? endedAt,  SessionStatus status,  int seatedSeconds,  int sensitivityLevel,  String? note)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _StudySession() when $default != null:
return $default(_that.id,_that.stamp,_that.subjectId,_that.plannerItemId,_that.kind,_that.mode,_that.startedAt,_that.endedAt,_that.status,_that.seatedSeconds,_that.sensitivityLevel,_that.note);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  SyncStamp stamp,  String? subjectId,  String? plannerItemId,  SessionKind kind,  SessionMode mode,  DateTime startedAt,  DateTime? endedAt,  SessionStatus status,  int seatedSeconds,  int sensitivityLevel,  String? note)  $default,) {final _that = this;
switch (_that) {
case _StudySession():
return $default(_that.id,_that.stamp,_that.subjectId,_that.plannerItemId,_that.kind,_that.mode,_that.startedAt,_that.endedAt,_that.status,_that.seatedSeconds,_that.sensitivityLevel,_that.note);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  SyncStamp stamp,  String? subjectId,  String? plannerItemId,  SessionKind kind,  SessionMode mode,  DateTime startedAt,  DateTime? endedAt,  SessionStatus status,  int seatedSeconds,  int sensitivityLevel,  String? note)?  $default,) {final _that = this;
switch (_that) {
case _StudySession() when $default != null:
return $default(_that.id,_that.stamp,_that.subjectId,_that.plannerItemId,_that.kind,_that.mode,_that.startedAt,_that.endedAt,_that.status,_that.seatedSeconds,_that.sensitivityLevel,_that.note);case _:
  return null;

}
}

}

/// @nodoc


class _StudySession extends StudySession {
  const _StudySession({required this.id, required this.stamp, this.subjectId, this.plannerItemId, required this.kind, required this.mode, required this.startedAt, this.endedAt, required this.status, required this.seatedSeconds, required this.sensitivityLevel, this.note}): super._();
  

@override final  String id;
@override final  SyncStamp stamp;
@override final  String? subjectId;
@override final  String? plannerItemId;
@override final  SessionKind kind;
@override final  SessionMode mode;
@override final  DateTime startedAt;
@override final  DateTime? endedAt;
@override final  SessionStatus status;
@override final  int seatedSeconds;
@override final  int sensitivityLevel;
@override final  String? note;

/// Create a copy of StudySession
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$StudySessionCopyWith<_StudySession> get copyWith => __$StudySessionCopyWithImpl<_StudySession>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _StudySession&&(identical(other.id, id) || other.id == id)&&(identical(other.stamp, stamp) || other.stamp == stamp)&&(identical(other.subjectId, subjectId) || other.subjectId == subjectId)&&(identical(other.plannerItemId, plannerItemId) || other.plannerItemId == plannerItemId)&&(identical(other.kind, kind) || other.kind == kind)&&(identical(other.mode, mode) || other.mode == mode)&&(identical(other.startedAt, startedAt) || other.startedAt == startedAt)&&(identical(other.endedAt, endedAt) || other.endedAt == endedAt)&&(identical(other.status, status) || other.status == status)&&(identical(other.seatedSeconds, seatedSeconds) || other.seatedSeconds == seatedSeconds)&&(identical(other.sensitivityLevel, sensitivityLevel) || other.sensitivityLevel == sensitivityLevel)&&(identical(other.note, note) || other.note == note));
}


@override
int get hashCode {
    return Object.hash(runtimeType,id,stamp,subjectId,plannerItemId,kind,mode,startedAt,endedAt,status,seatedSeconds,sensitivityLevel,note);
}

@override
String toString() {
    return 'StudySession(id: $id, stamp: $stamp, subjectId: $subjectId, plannerItemId: $plannerItemId, kind: $kind, mode: $mode, startedAt: $startedAt, endedAt: $endedAt, status: $status, seatedSeconds: $seatedSeconds, sensitivityLevel: $sensitivityLevel, note: $note)';
}


}

/// @nodoc
abstract mixin class _$StudySessionCopyWith<$Res> implements $StudySessionCopyWith<$Res> {
  factory _$StudySessionCopyWith(_StudySession value, $Res Function(_StudySession) _then) = __$StudySessionCopyWithImpl;
@override @useResult
$Res call({
 String id, SyncStamp stamp, String? subjectId, String? plannerItemId, SessionKind kind, SessionMode mode, DateTime startedAt, DateTime? endedAt, SessionStatus status, int seatedSeconds, int sensitivityLevel, String? note
});


@override $SyncStampCopyWith<$Res> get stamp;

}
/// @nodoc
class __$StudySessionCopyWithImpl<$Res>
    implements _$StudySessionCopyWith<$Res> {
  __$StudySessionCopyWithImpl(this._self, this._then);

  final _StudySession _self;
  final $Res Function(_StudySession) _then;

/// Create a copy of StudySession
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? stamp = null,Object? subjectId = freezed,Object? plannerItemId = freezed,Object? kind = null,Object? mode = null,Object? startedAt = null,Object? endedAt = freezed,Object? status = null,Object? seatedSeconds = null,Object? sensitivityLevel = null,Object? note = freezed,}) {
  return _then(_StudySession(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,stamp: null == stamp ? _self.stamp : stamp // ignore: cast_nullable_to_non_nullable
as SyncStamp,subjectId: freezed == subjectId ? _self.subjectId : subjectId // ignore: cast_nullable_to_non_nullable
as String?,plannerItemId: freezed == plannerItemId ? _self.plannerItemId : plannerItemId // ignore: cast_nullable_to_non_nullable
as String?,kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as SessionKind,mode: null == mode ? _self.mode : mode // ignore: cast_nullable_to_non_nullable
as SessionMode,startedAt: null == startedAt ? _self.startedAt : startedAt // ignore: cast_nullable_to_non_nullable
as DateTime,endedAt: freezed == endedAt ? _self.endedAt : endedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as SessionStatus,seatedSeconds: null == seatedSeconds ? _self.seatedSeconds : seatedSeconds // ignore: cast_nullable_to_non_nullable
as int,sensitivityLevel: null == sensitivityLevel ? _self.sensitivityLevel : sensitivityLevel // ignore: cast_nullable_to_non_nullable
as int,note: freezed == note ? _self.note : note // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

/// Create a copy of StudySession
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
mixin _$SessionSegment {

 String get id; SyncStamp get stamp; String get sessionId; SegmentKind get kind; DateTime get startAt; DateTime get endAt; bool get corrected;
/// Create a copy of SessionSegment
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SessionSegmentCopyWith<SessionSegment> get copyWith => _$SessionSegmentCopyWithImpl<SessionSegment>(this as SessionSegment, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as SessionSegment;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SessionSegment&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.stamp, _this.stamp) || other.stamp == _this.stamp)&&(identical(other.sessionId, _this.sessionId) || other.sessionId == _this.sessionId)&&(identical(other.kind, _this.kind) || other.kind == _this.kind)&&(identical(other.startAt, _this.startAt) || other.startAt == _this.startAt)&&(identical(other.endAt, _this.endAt) || other.endAt == _this.endAt)&&(identical(other.corrected, _this.corrected) || other.corrected == _this.corrected));
}


@override
int get hashCode {
  final _this = this as SessionSegment;
  return Object.hash(runtimeType,_this.id,_this.stamp,_this.sessionId,_this.kind,_this.startAt,_this.endAt,_this.corrected);
}

@override
String toString() {
  final _this = this as SessionSegment;
  return 'SessionSegment(id: ${_this.id}, stamp: ${_this.stamp}, sessionId: ${_this.sessionId}, kind: ${_this.kind}, startAt: ${_this.startAt}, endAt: ${_this.endAt}, corrected: ${_this.corrected})';
}


}

/// @nodoc
abstract mixin class $SessionSegmentCopyWith<$Res>  {
  factory $SessionSegmentCopyWith(SessionSegment value, $Res Function(SessionSegment) _then) = _$SessionSegmentCopyWithImpl;
@useResult
$Res call({
 String id, SyncStamp stamp, String sessionId, SegmentKind kind, DateTime startAt, DateTime endAt, bool corrected
});


$SyncStampCopyWith<$Res> get stamp;

}
/// @nodoc
class _$SessionSegmentCopyWithImpl<$Res>
    implements $SessionSegmentCopyWith<$Res> {
  _$SessionSegmentCopyWithImpl(this._self, this._then);

  final SessionSegment _self;
  final $Res Function(SessionSegment) _then;

/// Create a copy of SessionSegment
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? stamp = null,Object? sessionId = null,Object? kind = null,Object? startAt = null,Object? endAt = null,Object? corrected = null,}) {
  return _then(SessionSegment(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,stamp: null == stamp ? _self.stamp : stamp // ignore: cast_nullable_to_non_nullable
as SyncStamp,sessionId: null == sessionId ? _self.sessionId : sessionId // ignore: cast_nullable_to_non_nullable
as String,kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as SegmentKind,startAt: null == startAt ? _self.startAt : startAt // ignore: cast_nullable_to_non_nullable
as DateTime,endAt: null == endAt ? _self.endAt : endAt // ignore: cast_nullable_to_non_nullable
as DateTime,corrected: null == corrected ? _self.corrected : corrected // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}
/// Create a copy of SessionSegment
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$SyncStampCopyWith<$Res> get stamp {
  
  return $SyncStampCopyWith<$Res>(_self.stamp, (value) {
    return _then(_self.copyWith(stamp: value));
  });
}
}


/// Adds pattern-matching-related methods to [SessionSegment].
extension SessionSegmentPatterns on SessionSegment {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SessionSegment value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SessionSegment() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SessionSegment value)  $default,){
final _that = this;
switch (_that) {
case _SessionSegment():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SessionSegment value)?  $default,){
final _that = this;
switch (_that) {
case _SessionSegment() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  SyncStamp stamp,  String sessionId,  SegmentKind kind,  DateTime startAt,  DateTime endAt,  bool corrected)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SessionSegment() when $default != null:
return $default(_that.id,_that.stamp,_that.sessionId,_that.kind,_that.startAt,_that.endAt,_that.corrected);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  SyncStamp stamp,  String sessionId,  SegmentKind kind,  DateTime startAt,  DateTime endAt,  bool corrected)  $default,) {final _that = this;
switch (_that) {
case _SessionSegment():
return $default(_that.id,_that.stamp,_that.sessionId,_that.kind,_that.startAt,_that.endAt,_that.corrected);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  SyncStamp stamp,  String sessionId,  SegmentKind kind,  DateTime startAt,  DateTime endAt,  bool corrected)?  $default,) {final _that = this;
switch (_that) {
case _SessionSegment() when $default != null:
return $default(_that.id,_that.stamp,_that.sessionId,_that.kind,_that.startAt,_that.endAt,_that.corrected);case _:
  return null;

}
}

}

/// @nodoc


class _SessionSegment extends SessionSegment {
  const _SessionSegment({required this.id, required this.stamp, required this.sessionId, required this.kind, required this.startAt, required this.endAt, this.corrected = false}): super._();
  

@override final  String id;
@override final  SyncStamp stamp;
@override final  String sessionId;
@override final  SegmentKind kind;
@override final  DateTime startAt;
@override final  DateTime endAt;
@override@JsonKey() final  bool corrected;

/// Create a copy of SessionSegment
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SessionSegmentCopyWith<_SessionSegment> get copyWith => __$SessionSegmentCopyWithImpl<_SessionSegment>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _SessionSegment&&(identical(other.id, id) || other.id == id)&&(identical(other.stamp, stamp) || other.stamp == stamp)&&(identical(other.sessionId, sessionId) || other.sessionId == sessionId)&&(identical(other.kind, kind) || other.kind == kind)&&(identical(other.startAt, startAt) || other.startAt == startAt)&&(identical(other.endAt, endAt) || other.endAt == endAt)&&(identical(other.corrected, corrected) || other.corrected == corrected));
}


@override
int get hashCode {
    return Object.hash(runtimeType,id,stamp,sessionId,kind,startAt,endAt,corrected);
}

@override
String toString() {
    return 'SessionSegment(id: $id, stamp: $stamp, sessionId: $sessionId, kind: $kind, startAt: $startAt, endAt: $endAt, corrected: $corrected)';
}


}

/// @nodoc
abstract mixin class _$SessionSegmentCopyWith<$Res> implements $SessionSegmentCopyWith<$Res> {
  factory _$SessionSegmentCopyWith(_SessionSegment value, $Res Function(_SessionSegment) _then) = __$SessionSegmentCopyWithImpl;
@override @useResult
$Res call({
 String id, SyncStamp stamp, String sessionId, SegmentKind kind, DateTime startAt, DateTime endAt, bool corrected
});


@override $SyncStampCopyWith<$Res> get stamp;

}
/// @nodoc
class __$SessionSegmentCopyWithImpl<$Res>
    implements _$SessionSegmentCopyWith<$Res> {
  __$SessionSegmentCopyWithImpl(this._self, this._then);

  final _SessionSegment _self;
  final $Res Function(_SessionSegment) _then;

/// Create a copy of SessionSegment
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? stamp = null,Object? sessionId = null,Object? kind = null,Object? startAt = null,Object? endAt = null,Object? corrected = null,}) {
  return _then(_SessionSegment(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,stamp: null == stamp ? _self.stamp : stamp // ignore: cast_nullable_to_non_nullable
as SyncStamp,sessionId: null == sessionId ? _self.sessionId : sessionId // ignore: cast_nullable_to_non_nullable
as String,kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as SegmentKind,startAt: null == startAt ? _self.startAt : startAt // ignore: cast_nullable_to_non_nullable
as DateTime,endAt: null == endAt ? _self.endAt : endAt // ignore: cast_nullable_to_non_nullable
as DateTime,corrected: null == corrected ? _self.corrected : corrected // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

/// Create a copy of SessionSegment
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
mixin _$Correction {

 String get id; SyncStamp get stamp; String get sessionId; String get segmentId; SegmentKind get fromKind; SegmentKind get toKind; DateTime get at; int get sensitivityBefore; int get sensitivityAfter;
/// Create a copy of Correction
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CorrectionCopyWith<Correction> get copyWith => _$CorrectionCopyWithImpl<Correction>(this as Correction, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as Correction;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Correction&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.stamp, _this.stamp) || other.stamp == _this.stamp)&&(identical(other.sessionId, _this.sessionId) || other.sessionId == _this.sessionId)&&(identical(other.segmentId, _this.segmentId) || other.segmentId == _this.segmentId)&&(identical(other.fromKind, _this.fromKind) || other.fromKind == _this.fromKind)&&(identical(other.toKind, _this.toKind) || other.toKind == _this.toKind)&&(identical(other.at, _this.at) || other.at == _this.at)&&(identical(other.sensitivityBefore, _this.sensitivityBefore) || other.sensitivityBefore == _this.sensitivityBefore)&&(identical(other.sensitivityAfter, _this.sensitivityAfter) || other.sensitivityAfter == _this.sensitivityAfter));
}


@override
int get hashCode {
  final _this = this as Correction;
  return Object.hash(runtimeType,_this.id,_this.stamp,_this.sessionId,_this.segmentId,_this.fromKind,_this.toKind,_this.at,_this.sensitivityBefore,_this.sensitivityAfter);
}

@override
String toString() {
  final _this = this as Correction;
  return 'Correction(id: ${_this.id}, stamp: ${_this.stamp}, sessionId: ${_this.sessionId}, segmentId: ${_this.segmentId}, fromKind: ${_this.fromKind}, toKind: ${_this.toKind}, at: ${_this.at}, sensitivityBefore: ${_this.sensitivityBefore}, sensitivityAfter: ${_this.sensitivityAfter})';
}


}

/// @nodoc
abstract mixin class $CorrectionCopyWith<$Res>  {
  factory $CorrectionCopyWith(Correction value, $Res Function(Correction) _then) = _$CorrectionCopyWithImpl;
@useResult
$Res call({
 String id, SyncStamp stamp, String sessionId, String segmentId, SegmentKind fromKind, SegmentKind toKind, DateTime at, int sensitivityBefore, int sensitivityAfter
});


$SyncStampCopyWith<$Res> get stamp;

}
/// @nodoc
class _$CorrectionCopyWithImpl<$Res>
    implements $CorrectionCopyWith<$Res> {
  _$CorrectionCopyWithImpl(this._self, this._then);

  final Correction _self;
  final $Res Function(Correction) _then;

/// Create a copy of Correction
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? stamp = null,Object? sessionId = null,Object? segmentId = null,Object? fromKind = null,Object? toKind = null,Object? at = null,Object? sensitivityBefore = null,Object? sensitivityAfter = null,}) {
  return _then(Correction(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,stamp: null == stamp ? _self.stamp : stamp // ignore: cast_nullable_to_non_nullable
as SyncStamp,sessionId: null == sessionId ? _self.sessionId : sessionId // ignore: cast_nullable_to_non_nullable
as String,segmentId: null == segmentId ? _self.segmentId : segmentId // ignore: cast_nullable_to_non_nullable
as String,fromKind: null == fromKind ? _self.fromKind : fromKind // ignore: cast_nullable_to_non_nullable
as SegmentKind,toKind: null == toKind ? _self.toKind : toKind // ignore: cast_nullable_to_non_nullable
as SegmentKind,at: null == at ? _self.at : at // ignore: cast_nullable_to_non_nullable
as DateTime,sensitivityBefore: null == sensitivityBefore ? _self.sensitivityBefore : sensitivityBefore // ignore: cast_nullable_to_non_nullable
as int,sensitivityAfter: null == sensitivityAfter ? _self.sensitivityAfter : sensitivityAfter // ignore: cast_nullable_to_non_nullable
as int,
  ));
}
/// Create a copy of Correction
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$SyncStampCopyWith<$Res> get stamp {
  
  return $SyncStampCopyWith<$Res>(_self.stamp, (value) {
    return _then(_self.copyWith(stamp: value));
  });
}
}


/// Adds pattern-matching-related methods to [Correction].
extension CorrectionPatterns on Correction {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Correction value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Correction() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Correction value)  $default,){
final _that = this;
switch (_that) {
case _Correction():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Correction value)?  $default,){
final _that = this;
switch (_that) {
case _Correction() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  SyncStamp stamp,  String sessionId,  String segmentId,  SegmentKind fromKind,  SegmentKind toKind,  DateTime at,  int sensitivityBefore,  int sensitivityAfter)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Correction() when $default != null:
return $default(_that.id,_that.stamp,_that.sessionId,_that.segmentId,_that.fromKind,_that.toKind,_that.at,_that.sensitivityBefore,_that.sensitivityAfter);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  SyncStamp stamp,  String sessionId,  String segmentId,  SegmentKind fromKind,  SegmentKind toKind,  DateTime at,  int sensitivityBefore,  int sensitivityAfter)  $default,) {final _that = this;
switch (_that) {
case _Correction():
return $default(_that.id,_that.stamp,_that.sessionId,_that.segmentId,_that.fromKind,_that.toKind,_that.at,_that.sensitivityBefore,_that.sensitivityAfter);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  SyncStamp stamp,  String sessionId,  String segmentId,  SegmentKind fromKind,  SegmentKind toKind,  DateTime at,  int sensitivityBefore,  int sensitivityAfter)?  $default,) {final _that = this;
switch (_that) {
case _Correction() when $default != null:
return $default(_that.id,_that.stamp,_that.sessionId,_that.segmentId,_that.fromKind,_that.toKind,_that.at,_that.sensitivityBefore,_that.sensitivityAfter);case _:
  return null;

}
}

}

/// @nodoc


class _Correction implements Correction {
  const _Correction({required this.id, required this.stamp, required this.sessionId, required this.segmentId, required this.fromKind, required this.toKind, required this.at, required this.sensitivityBefore, required this.sensitivityAfter});
  

@override final  String id;
@override final  SyncStamp stamp;
@override final  String sessionId;
@override final  String segmentId;
@override final  SegmentKind fromKind;
@override final  SegmentKind toKind;
@override final  DateTime at;
@override final  int sensitivityBefore;
@override final  int sensitivityAfter;

/// Create a copy of Correction
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CorrectionCopyWith<_Correction> get copyWith => __$CorrectionCopyWithImpl<_Correction>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _Correction&&(identical(other.id, id) || other.id == id)&&(identical(other.stamp, stamp) || other.stamp == stamp)&&(identical(other.sessionId, sessionId) || other.sessionId == sessionId)&&(identical(other.segmentId, segmentId) || other.segmentId == segmentId)&&(identical(other.fromKind, fromKind) || other.fromKind == fromKind)&&(identical(other.toKind, toKind) || other.toKind == toKind)&&(identical(other.at, at) || other.at == at)&&(identical(other.sensitivityBefore, sensitivityBefore) || other.sensitivityBefore == sensitivityBefore)&&(identical(other.sensitivityAfter, sensitivityAfter) || other.sensitivityAfter == sensitivityAfter));
}


@override
int get hashCode {
    return Object.hash(runtimeType,id,stamp,sessionId,segmentId,fromKind,toKind,at,sensitivityBefore,sensitivityAfter);
}

@override
String toString() {
    return 'Correction(id: $id, stamp: $stamp, sessionId: $sessionId, segmentId: $segmentId, fromKind: $fromKind, toKind: $toKind, at: $at, sensitivityBefore: $sensitivityBefore, sensitivityAfter: $sensitivityAfter)';
}


}

/// @nodoc
abstract mixin class _$CorrectionCopyWith<$Res> implements $CorrectionCopyWith<$Res> {
  factory _$CorrectionCopyWith(_Correction value, $Res Function(_Correction) _then) = __$CorrectionCopyWithImpl;
@override @useResult
$Res call({
 String id, SyncStamp stamp, String sessionId, String segmentId, SegmentKind fromKind, SegmentKind toKind, DateTime at, int sensitivityBefore, int sensitivityAfter
});


@override $SyncStampCopyWith<$Res> get stamp;

}
/// @nodoc
class __$CorrectionCopyWithImpl<$Res>
    implements _$CorrectionCopyWith<$Res> {
  __$CorrectionCopyWithImpl(this._self, this._then);

  final _Correction _self;
  final $Res Function(_Correction) _then;

/// Create a copy of Correction
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? stamp = null,Object? sessionId = null,Object? segmentId = null,Object? fromKind = null,Object? toKind = null,Object? at = null,Object? sensitivityBefore = null,Object? sensitivityAfter = null,}) {
  return _then(_Correction(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,stamp: null == stamp ? _self.stamp : stamp // ignore: cast_nullable_to_non_nullable
as SyncStamp,sessionId: null == sessionId ? _self.sessionId : sessionId // ignore: cast_nullable_to_non_nullable
as String,segmentId: null == segmentId ? _self.segmentId : segmentId // ignore: cast_nullable_to_non_nullable
as String,fromKind: null == fromKind ? _self.fromKind : fromKind // ignore: cast_nullable_to_non_nullable
as SegmentKind,toKind: null == toKind ? _self.toKind : toKind // ignore: cast_nullable_to_non_nullable
as SegmentKind,at: null == at ? _self.at : at // ignore: cast_nullable_to_non_nullable
as DateTime,sensitivityBefore: null == sensitivityBefore ? _self.sensitivityBefore : sensitivityBefore // ignore: cast_nullable_to_non_nullable
as int,sensitivityAfter: null == sensitivityAfter ? _self.sensitivityAfter : sensitivityAfter // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

/// Create a copy of Correction
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
