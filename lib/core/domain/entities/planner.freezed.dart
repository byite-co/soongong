// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'planner.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$PlannerItem {

 String get id; SyncStamp get stamp; PlannerKind get kind; String get title; String? get subjectId; String? get rangeText; int? get targetMinutes; LocalDate get date; LocalTime? get startTime; LocalTime? get endTime; bool get isDone; DateTime? get doneAt; String? get recurrenceId; LocalDate? get bandStart; LocalDate? get bandEnd; int get sortOrder;
/// Create a copy of PlannerItem
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PlannerItemCopyWith<PlannerItem> get copyWith => _$PlannerItemCopyWithImpl<PlannerItem>(this as PlannerItem, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as PlannerItem;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PlannerItem&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.stamp, _this.stamp) || other.stamp == _this.stamp)&&(identical(other.kind, _this.kind) || other.kind == _this.kind)&&(identical(other.title, _this.title) || other.title == _this.title)&&(identical(other.subjectId, _this.subjectId) || other.subjectId == _this.subjectId)&&(identical(other.rangeText, _this.rangeText) || other.rangeText == _this.rangeText)&&(identical(other.targetMinutes, _this.targetMinutes) || other.targetMinutes == _this.targetMinutes)&&(identical(other.date, _this.date) || other.date == _this.date)&&(identical(other.startTime, _this.startTime) || other.startTime == _this.startTime)&&(identical(other.endTime, _this.endTime) || other.endTime == _this.endTime)&&(identical(other.isDone, _this.isDone) || other.isDone == _this.isDone)&&(identical(other.doneAt, _this.doneAt) || other.doneAt == _this.doneAt)&&(identical(other.recurrenceId, _this.recurrenceId) || other.recurrenceId == _this.recurrenceId)&&(identical(other.bandStart, _this.bandStart) || other.bandStart == _this.bandStart)&&(identical(other.bandEnd, _this.bandEnd) || other.bandEnd == _this.bandEnd)&&(identical(other.sortOrder, _this.sortOrder) || other.sortOrder == _this.sortOrder));
}


@override
int get hashCode {
  final _this = this as PlannerItem;
  return Object.hash(runtimeType,_this.id,_this.stamp,_this.kind,_this.title,_this.subjectId,_this.rangeText,_this.targetMinutes,_this.date,_this.startTime,_this.endTime,_this.isDone,_this.doneAt,_this.recurrenceId,_this.bandStart,_this.bandEnd,_this.sortOrder);
}

@override
String toString() {
  final _this = this as PlannerItem;
  return 'PlannerItem(id: ${_this.id}, stamp: ${_this.stamp}, kind: ${_this.kind}, title: ${_this.title}, subjectId: ${_this.subjectId}, rangeText: ${_this.rangeText}, targetMinutes: ${_this.targetMinutes}, date: ${_this.date}, startTime: ${_this.startTime}, endTime: ${_this.endTime}, isDone: ${_this.isDone}, doneAt: ${_this.doneAt}, recurrenceId: ${_this.recurrenceId}, bandStart: ${_this.bandStart}, bandEnd: ${_this.bandEnd}, sortOrder: ${_this.sortOrder})';
}


}

/// @nodoc
abstract mixin class $PlannerItemCopyWith<$Res>  {
  factory $PlannerItemCopyWith(PlannerItem value, $Res Function(PlannerItem) _then) = _$PlannerItemCopyWithImpl;
@useResult
$Res call({
 String id, SyncStamp stamp, PlannerKind kind, String title, String? subjectId, String? rangeText, int? targetMinutes, LocalDate date, LocalTime? startTime, LocalTime? endTime, bool isDone, DateTime? doneAt, String? recurrenceId, LocalDate? bandStart, LocalDate? bandEnd, int sortOrder
});


$SyncStampCopyWith<$Res> get stamp;

}
/// @nodoc
class _$PlannerItemCopyWithImpl<$Res>
    implements $PlannerItemCopyWith<$Res> {
  _$PlannerItemCopyWithImpl(this._self, this._then);

  final PlannerItem _self;
  final $Res Function(PlannerItem) _then;

/// Create a copy of PlannerItem
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? stamp = null,Object? kind = null,Object? title = null,Object? subjectId = freezed,Object? rangeText = freezed,Object? targetMinutes = freezed,Object? date = null,Object? startTime = freezed,Object? endTime = freezed,Object? isDone = null,Object? doneAt = freezed,Object? recurrenceId = freezed,Object? bandStart = freezed,Object? bandEnd = freezed,Object? sortOrder = null,}) {
  return _then(PlannerItem(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,stamp: null == stamp ? _self.stamp : stamp // ignore: cast_nullable_to_non_nullable
as SyncStamp,kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as PlannerKind,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,subjectId: freezed == subjectId ? _self.subjectId : subjectId // ignore: cast_nullable_to_non_nullable
as String?,rangeText: freezed == rangeText ? _self.rangeText : rangeText // ignore: cast_nullable_to_non_nullable
as String?,targetMinutes: freezed == targetMinutes ? _self.targetMinutes : targetMinutes // ignore: cast_nullable_to_non_nullable
as int?,date: null == date ? _self.date : date // ignore: cast_nullable_to_non_nullable
as LocalDate,startTime: freezed == startTime ? _self.startTime : startTime // ignore: cast_nullable_to_non_nullable
as LocalTime?,endTime: freezed == endTime ? _self.endTime : endTime // ignore: cast_nullable_to_non_nullable
as LocalTime?,isDone: null == isDone ? _self.isDone : isDone // ignore: cast_nullable_to_non_nullable
as bool,doneAt: freezed == doneAt ? _self.doneAt : doneAt // ignore: cast_nullable_to_non_nullable
as DateTime?,recurrenceId: freezed == recurrenceId ? _self.recurrenceId : recurrenceId // ignore: cast_nullable_to_non_nullable
as String?,bandStart: freezed == bandStart ? _self.bandStart : bandStart // ignore: cast_nullable_to_non_nullable
as LocalDate?,bandEnd: freezed == bandEnd ? _self.bandEnd : bandEnd // ignore: cast_nullable_to_non_nullable
as LocalDate?,sortOrder: null == sortOrder ? _self.sortOrder : sortOrder // ignore: cast_nullable_to_non_nullable
as int,
  ));
}
/// Create a copy of PlannerItem
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$SyncStampCopyWith<$Res> get stamp {
  
  return $SyncStampCopyWith<$Res>(_self.stamp, (value) {
    return _then(_self.copyWith(stamp: value));
  });
}
}


/// Adds pattern-matching-related methods to [PlannerItem].
extension PlannerItemPatterns on PlannerItem {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PlannerItem value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PlannerItem() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PlannerItem value)  $default,){
final _that = this;
switch (_that) {
case _PlannerItem():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PlannerItem value)?  $default,){
final _that = this;
switch (_that) {
case _PlannerItem() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  SyncStamp stamp,  PlannerKind kind,  String title,  String? subjectId,  String? rangeText,  int? targetMinutes,  LocalDate date,  LocalTime? startTime,  LocalTime? endTime,  bool isDone,  DateTime? doneAt,  String? recurrenceId,  LocalDate? bandStart,  LocalDate? bandEnd,  int sortOrder)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PlannerItem() when $default != null:
return $default(_that.id,_that.stamp,_that.kind,_that.title,_that.subjectId,_that.rangeText,_that.targetMinutes,_that.date,_that.startTime,_that.endTime,_that.isDone,_that.doneAt,_that.recurrenceId,_that.bandStart,_that.bandEnd,_that.sortOrder);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  SyncStamp stamp,  PlannerKind kind,  String title,  String? subjectId,  String? rangeText,  int? targetMinutes,  LocalDate date,  LocalTime? startTime,  LocalTime? endTime,  bool isDone,  DateTime? doneAt,  String? recurrenceId,  LocalDate? bandStart,  LocalDate? bandEnd,  int sortOrder)  $default,) {final _that = this;
switch (_that) {
case _PlannerItem():
return $default(_that.id,_that.stamp,_that.kind,_that.title,_that.subjectId,_that.rangeText,_that.targetMinutes,_that.date,_that.startTime,_that.endTime,_that.isDone,_that.doneAt,_that.recurrenceId,_that.bandStart,_that.bandEnd,_that.sortOrder);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  SyncStamp stamp,  PlannerKind kind,  String title,  String? subjectId,  String? rangeText,  int? targetMinutes,  LocalDate date,  LocalTime? startTime,  LocalTime? endTime,  bool isDone,  DateTime? doneAt,  String? recurrenceId,  LocalDate? bandStart,  LocalDate? bandEnd,  int sortOrder)?  $default,) {final _that = this;
switch (_that) {
case _PlannerItem() when $default != null:
return $default(_that.id,_that.stamp,_that.kind,_that.title,_that.subjectId,_that.rangeText,_that.targetMinutes,_that.date,_that.startTime,_that.endTime,_that.isDone,_that.doneAt,_that.recurrenceId,_that.bandStart,_that.bandEnd,_that.sortOrder);case _:
  return null;

}
}

}

/// @nodoc


class _PlannerItem extends PlannerItem {
  const _PlannerItem({required this.id, required this.stamp, required this.kind, required this.title, this.subjectId, this.rangeText, this.targetMinutes, required this.date, this.startTime, this.endTime, this.isDone = false, this.doneAt, this.recurrenceId, this.bandStart, this.bandEnd, required this.sortOrder}): super._();
  

@override final  String id;
@override final  SyncStamp stamp;
@override final  PlannerKind kind;
@override final  String title;
@override final  String? subjectId;
@override final  String? rangeText;
@override final  int? targetMinutes;
@override final  LocalDate date;
@override final  LocalTime? startTime;
@override final  LocalTime? endTime;
@override@JsonKey() final  bool isDone;
@override final  DateTime? doneAt;
@override final  String? recurrenceId;
@override final  LocalDate? bandStart;
@override final  LocalDate? bandEnd;
@override final  int sortOrder;

/// Create a copy of PlannerItem
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PlannerItemCopyWith<_PlannerItem> get copyWith => __$PlannerItemCopyWithImpl<_PlannerItem>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _PlannerItem&&(identical(other.id, id) || other.id == id)&&(identical(other.stamp, stamp) || other.stamp == stamp)&&(identical(other.kind, kind) || other.kind == kind)&&(identical(other.title, title) || other.title == title)&&(identical(other.subjectId, subjectId) || other.subjectId == subjectId)&&(identical(other.rangeText, rangeText) || other.rangeText == rangeText)&&(identical(other.targetMinutes, targetMinutes) || other.targetMinutes == targetMinutes)&&(identical(other.date, date) || other.date == date)&&(identical(other.startTime, startTime) || other.startTime == startTime)&&(identical(other.endTime, endTime) || other.endTime == endTime)&&(identical(other.isDone, isDone) || other.isDone == isDone)&&(identical(other.doneAt, doneAt) || other.doneAt == doneAt)&&(identical(other.recurrenceId, recurrenceId) || other.recurrenceId == recurrenceId)&&(identical(other.bandStart, bandStart) || other.bandStart == bandStart)&&(identical(other.bandEnd, bandEnd) || other.bandEnd == bandEnd)&&(identical(other.sortOrder, sortOrder) || other.sortOrder == sortOrder));
}


@override
int get hashCode {
    return Object.hash(runtimeType,id,stamp,kind,title,subjectId,rangeText,targetMinutes,date,startTime,endTime,isDone,doneAt,recurrenceId,bandStart,bandEnd,sortOrder);
}

@override
String toString() {
    return 'PlannerItem(id: $id, stamp: $stamp, kind: $kind, title: $title, subjectId: $subjectId, rangeText: $rangeText, targetMinutes: $targetMinutes, date: $date, startTime: $startTime, endTime: $endTime, isDone: $isDone, doneAt: $doneAt, recurrenceId: $recurrenceId, bandStart: $bandStart, bandEnd: $bandEnd, sortOrder: $sortOrder)';
}


}

/// @nodoc
abstract mixin class _$PlannerItemCopyWith<$Res> implements $PlannerItemCopyWith<$Res> {
  factory _$PlannerItemCopyWith(_PlannerItem value, $Res Function(_PlannerItem) _then) = __$PlannerItemCopyWithImpl;
@override @useResult
$Res call({
 String id, SyncStamp stamp, PlannerKind kind, String title, String? subjectId, String? rangeText, int? targetMinutes, LocalDate date, LocalTime? startTime, LocalTime? endTime, bool isDone, DateTime? doneAt, String? recurrenceId, LocalDate? bandStart, LocalDate? bandEnd, int sortOrder
});


@override $SyncStampCopyWith<$Res> get stamp;

}
/// @nodoc
class __$PlannerItemCopyWithImpl<$Res>
    implements _$PlannerItemCopyWith<$Res> {
  __$PlannerItemCopyWithImpl(this._self, this._then);

  final _PlannerItem _self;
  final $Res Function(_PlannerItem) _then;

/// Create a copy of PlannerItem
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? stamp = null,Object? kind = null,Object? title = null,Object? subjectId = freezed,Object? rangeText = freezed,Object? targetMinutes = freezed,Object? date = null,Object? startTime = freezed,Object? endTime = freezed,Object? isDone = null,Object? doneAt = freezed,Object? recurrenceId = freezed,Object? bandStart = freezed,Object? bandEnd = freezed,Object? sortOrder = null,}) {
  return _then(_PlannerItem(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,stamp: null == stamp ? _self.stamp : stamp // ignore: cast_nullable_to_non_nullable
as SyncStamp,kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as PlannerKind,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,subjectId: freezed == subjectId ? _self.subjectId : subjectId // ignore: cast_nullable_to_non_nullable
as String?,rangeText: freezed == rangeText ? _self.rangeText : rangeText // ignore: cast_nullable_to_non_nullable
as String?,targetMinutes: freezed == targetMinutes ? _self.targetMinutes : targetMinutes // ignore: cast_nullable_to_non_nullable
as int?,date: null == date ? _self.date : date // ignore: cast_nullable_to_non_nullable
as LocalDate,startTime: freezed == startTime ? _self.startTime : startTime // ignore: cast_nullable_to_non_nullable
as LocalTime?,endTime: freezed == endTime ? _self.endTime : endTime // ignore: cast_nullable_to_non_nullable
as LocalTime?,isDone: null == isDone ? _self.isDone : isDone // ignore: cast_nullable_to_non_nullable
as bool,doneAt: freezed == doneAt ? _self.doneAt : doneAt // ignore: cast_nullable_to_non_nullable
as DateTime?,recurrenceId: freezed == recurrenceId ? _self.recurrenceId : recurrenceId // ignore: cast_nullable_to_non_nullable
as String?,bandStart: freezed == bandStart ? _self.bandStart : bandStart // ignore: cast_nullable_to_non_nullable
as LocalDate?,bandEnd: freezed == bandEnd ? _self.bandEnd : bandEnd // ignore: cast_nullable_to_non_nullable
as LocalDate?,sortOrder: null == sortOrder ? _self.sortOrder : sortOrder // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

/// Create a copy of PlannerItem
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
mixin _$Recurrence {

 String get id; SyncStamp get stamp; String get title; String? get subjectId; int get weekdayMask; LocalTime get startTime; LocalTime get endTime; LocalDate? get endsOn; bool get active;
/// Create a copy of Recurrence
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RecurrenceCopyWith<Recurrence> get copyWith => _$RecurrenceCopyWithImpl<Recurrence>(this as Recurrence, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as Recurrence;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Recurrence&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.stamp, _this.stamp) || other.stamp == _this.stamp)&&(identical(other.title, _this.title) || other.title == _this.title)&&(identical(other.subjectId, _this.subjectId) || other.subjectId == _this.subjectId)&&(identical(other.weekdayMask, _this.weekdayMask) || other.weekdayMask == _this.weekdayMask)&&(identical(other.startTime, _this.startTime) || other.startTime == _this.startTime)&&(identical(other.endTime, _this.endTime) || other.endTime == _this.endTime)&&(identical(other.endsOn, _this.endsOn) || other.endsOn == _this.endsOn)&&(identical(other.active, _this.active) || other.active == _this.active));
}


@override
int get hashCode {
  final _this = this as Recurrence;
  return Object.hash(runtimeType,_this.id,_this.stamp,_this.title,_this.subjectId,_this.weekdayMask,_this.startTime,_this.endTime,_this.endsOn,_this.active);
}

@override
String toString() {
  final _this = this as Recurrence;
  return 'Recurrence(id: ${_this.id}, stamp: ${_this.stamp}, title: ${_this.title}, subjectId: ${_this.subjectId}, weekdayMask: ${_this.weekdayMask}, startTime: ${_this.startTime}, endTime: ${_this.endTime}, endsOn: ${_this.endsOn}, active: ${_this.active})';
}


}

/// @nodoc
abstract mixin class $RecurrenceCopyWith<$Res>  {
  factory $RecurrenceCopyWith(Recurrence value, $Res Function(Recurrence) _then) = _$RecurrenceCopyWithImpl;
@useResult
$Res call({
 String id, SyncStamp stamp, String title, String? subjectId, int weekdayMask, LocalTime startTime, LocalTime endTime, LocalDate? endsOn, bool active
});


$SyncStampCopyWith<$Res> get stamp;

}
/// @nodoc
class _$RecurrenceCopyWithImpl<$Res>
    implements $RecurrenceCopyWith<$Res> {
  _$RecurrenceCopyWithImpl(this._self, this._then);

  final Recurrence _self;
  final $Res Function(Recurrence) _then;

/// Create a copy of Recurrence
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? stamp = null,Object? title = null,Object? subjectId = freezed,Object? weekdayMask = null,Object? startTime = null,Object? endTime = null,Object? endsOn = freezed,Object? active = null,}) {
  return _then(Recurrence(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,stamp: null == stamp ? _self.stamp : stamp // ignore: cast_nullable_to_non_nullable
as SyncStamp,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,subjectId: freezed == subjectId ? _self.subjectId : subjectId // ignore: cast_nullable_to_non_nullable
as String?,weekdayMask: null == weekdayMask ? _self.weekdayMask : weekdayMask // ignore: cast_nullable_to_non_nullable
as int,startTime: null == startTime ? _self.startTime : startTime // ignore: cast_nullable_to_non_nullable
as LocalTime,endTime: null == endTime ? _self.endTime : endTime // ignore: cast_nullable_to_non_nullable
as LocalTime,endsOn: freezed == endsOn ? _self.endsOn : endsOn // ignore: cast_nullable_to_non_nullable
as LocalDate?,active: null == active ? _self.active : active // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}
/// Create a copy of Recurrence
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$SyncStampCopyWith<$Res> get stamp {
  
  return $SyncStampCopyWith<$Res>(_self.stamp, (value) {
    return _then(_self.copyWith(stamp: value));
  });
}
}


/// Adds pattern-matching-related methods to [Recurrence].
extension RecurrencePatterns on Recurrence {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Recurrence value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Recurrence() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Recurrence value)  $default,){
final _that = this;
switch (_that) {
case _Recurrence():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Recurrence value)?  $default,){
final _that = this;
switch (_that) {
case _Recurrence() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  SyncStamp stamp,  String title,  String? subjectId,  int weekdayMask,  LocalTime startTime,  LocalTime endTime,  LocalDate? endsOn,  bool active)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Recurrence() when $default != null:
return $default(_that.id,_that.stamp,_that.title,_that.subjectId,_that.weekdayMask,_that.startTime,_that.endTime,_that.endsOn,_that.active);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  SyncStamp stamp,  String title,  String? subjectId,  int weekdayMask,  LocalTime startTime,  LocalTime endTime,  LocalDate? endsOn,  bool active)  $default,) {final _that = this;
switch (_that) {
case _Recurrence():
return $default(_that.id,_that.stamp,_that.title,_that.subjectId,_that.weekdayMask,_that.startTime,_that.endTime,_that.endsOn,_that.active);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  SyncStamp stamp,  String title,  String? subjectId,  int weekdayMask,  LocalTime startTime,  LocalTime endTime,  LocalDate? endsOn,  bool active)?  $default,) {final _that = this;
switch (_that) {
case _Recurrence() when $default != null:
return $default(_that.id,_that.stamp,_that.title,_that.subjectId,_that.weekdayMask,_that.startTime,_that.endTime,_that.endsOn,_that.active);case _:
  return null;

}
}

}

/// @nodoc


class _Recurrence extends Recurrence {
  const _Recurrence({required this.id, required this.stamp, required this.title, this.subjectId, required this.weekdayMask, required this.startTime, required this.endTime, this.endsOn, this.active = true}): super._();
  

@override final  String id;
@override final  SyncStamp stamp;
@override final  String title;
@override final  String? subjectId;
@override final  int weekdayMask;
@override final  LocalTime startTime;
@override final  LocalTime endTime;
@override final  LocalDate? endsOn;
@override@JsonKey() final  bool active;

/// Create a copy of Recurrence
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$RecurrenceCopyWith<_Recurrence> get copyWith => __$RecurrenceCopyWithImpl<_Recurrence>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _Recurrence&&(identical(other.id, id) || other.id == id)&&(identical(other.stamp, stamp) || other.stamp == stamp)&&(identical(other.title, title) || other.title == title)&&(identical(other.subjectId, subjectId) || other.subjectId == subjectId)&&(identical(other.weekdayMask, weekdayMask) || other.weekdayMask == weekdayMask)&&(identical(other.startTime, startTime) || other.startTime == startTime)&&(identical(other.endTime, endTime) || other.endTime == endTime)&&(identical(other.endsOn, endsOn) || other.endsOn == endsOn)&&(identical(other.active, active) || other.active == active));
}


@override
int get hashCode {
    return Object.hash(runtimeType,id,stamp,title,subjectId,weekdayMask,startTime,endTime,endsOn,active);
}

@override
String toString() {
    return 'Recurrence(id: $id, stamp: $stamp, title: $title, subjectId: $subjectId, weekdayMask: $weekdayMask, startTime: $startTime, endTime: $endTime, endsOn: $endsOn, active: $active)';
}


}

/// @nodoc
abstract mixin class _$RecurrenceCopyWith<$Res> implements $RecurrenceCopyWith<$Res> {
  factory _$RecurrenceCopyWith(_Recurrence value, $Res Function(_Recurrence) _then) = __$RecurrenceCopyWithImpl;
@override @useResult
$Res call({
 String id, SyncStamp stamp, String title, String? subjectId, int weekdayMask, LocalTime startTime, LocalTime endTime, LocalDate? endsOn, bool active
});


@override $SyncStampCopyWith<$Res> get stamp;

}
/// @nodoc
class __$RecurrenceCopyWithImpl<$Res>
    implements _$RecurrenceCopyWith<$Res> {
  __$RecurrenceCopyWithImpl(this._self, this._then);

  final _Recurrence _self;
  final $Res Function(_Recurrence) _then;

/// Create a copy of Recurrence
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? stamp = null,Object? title = null,Object? subjectId = freezed,Object? weekdayMask = null,Object? startTime = null,Object? endTime = null,Object? endsOn = freezed,Object? active = null,}) {
  return _then(_Recurrence(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,stamp: null == stamp ? _self.stamp : stamp // ignore: cast_nullable_to_non_nullable
as SyncStamp,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,subjectId: freezed == subjectId ? _self.subjectId : subjectId // ignore: cast_nullable_to_non_nullable
as String?,weekdayMask: null == weekdayMask ? _self.weekdayMask : weekdayMask // ignore: cast_nullable_to_non_nullable
as int,startTime: null == startTime ? _self.startTime : startTime // ignore: cast_nullable_to_non_nullable
as LocalTime,endTime: null == endTime ? _self.endTime : endTime // ignore: cast_nullable_to_non_nullable
as LocalTime,endsOn: freezed == endsOn ? _self.endsOn : endsOn // ignore: cast_nullable_to_non_nullable
as LocalDate?,active: null == active ? _self.active : active // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

/// Create a copy of Recurrence
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
