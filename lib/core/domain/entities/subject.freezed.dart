// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'subject.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$Subject {

 String get id; SyncStamp get stamp; String get name; int get colorIndex; int get sortOrder; bool get isDefault;
/// Create a copy of Subject
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SubjectCopyWith<Subject> get copyWith => _$SubjectCopyWithImpl<Subject>(this as Subject, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as Subject;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Subject&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.stamp, _this.stamp) || other.stamp == _this.stamp)&&(identical(other.name, _this.name) || other.name == _this.name)&&(identical(other.colorIndex, _this.colorIndex) || other.colorIndex == _this.colorIndex)&&(identical(other.sortOrder, _this.sortOrder) || other.sortOrder == _this.sortOrder)&&(identical(other.isDefault, _this.isDefault) || other.isDefault == _this.isDefault));
}


@override
int get hashCode {
  final _this = this as Subject;
  return Object.hash(runtimeType,_this.id,_this.stamp,_this.name,_this.colorIndex,_this.sortOrder,_this.isDefault);
}

@override
String toString() {
  final _this = this as Subject;
  return 'Subject(id: ${_this.id}, stamp: ${_this.stamp}, name: ${_this.name}, colorIndex: ${_this.colorIndex}, sortOrder: ${_this.sortOrder}, isDefault: ${_this.isDefault})';
}


}

/// @nodoc
abstract mixin class $SubjectCopyWith<$Res>  {
  factory $SubjectCopyWith(Subject value, $Res Function(Subject) _then) = _$SubjectCopyWithImpl;
@useResult
$Res call({
 String id, SyncStamp stamp, String name, int colorIndex, int sortOrder, bool isDefault
});


$SyncStampCopyWith<$Res> get stamp;

}
/// @nodoc
class _$SubjectCopyWithImpl<$Res>
    implements $SubjectCopyWith<$Res> {
  _$SubjectCopyWithImpl(this._self, this._then);

  final Subject _self;
  final $Res Function(Subject) _then;

/// Create a copy of Subject
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? stamp = null,Object? name = null,Object? colorIndex = null,Object? sortOrder = null,Object? isDefault = null,}) {
  return _then(Subject(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,stamp: null == stamp ? _self.stamp : stamp // ignore: cast_nullable_to_non_nullable
as SyncStamp,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,colorIndex: null == colorIndex ? _self.colorIndex : colorIndex // ignore: cast_nullable_to_non_nullable
as int,sortOrder: null == sortOrder ? _self.sortOrder : sortOrder // ignore: cast_nullable_to_non_nullable
as int,isDefault: null == isDefault ? _self.isDefault : isDefault // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}
/// Create a copy of Subject
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$SyncStampCopyWith<$Res> get stamp {
  
  return $SyncStampCopyWith<$Res>(_self.stamp, (value) {
    return _then(_self.copyWith(stamp: value));
  });
}
}


/// Adds pattern-matching-related methods to [Subject].
extension SubjectPatterns on Subject {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Subject value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Subject() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Subject value)  $default,){
final _that = this;
switch (_that) {
case _Subject():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Subject value)?  $default,){
final _that = this;
switch (_that) {
case _Subject() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  SyncStamp stamp,  String name,  int colorIndex,  int sortOrder,  bool isDefault)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Subject() when $default != null:
return $default(_that.id,_that.stamp,_that.name,_that.colorIndex,_that.sortOrder,_that.isDefault);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  SyncStamp stamp,  String name,  int colorIndex,  int sortOrder,  bool isDefault)  $default,) {final _that = this;
switch (_that) {
case _Subject():
return $default(_that.id,_that.stamp,_that.name,_that.colorIndex,_that.sortOrder,_that.isDefault);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  SyncStamp stamp,  String name,  int colorIndex,  int sortOrder,  bool isDefault)?  $default,) {final _that = this;
switch (_that) {
case _Subject() when $default != null:
return $default(_that.id,_that.stamp,_that.name,_that.colorIndex,_that.sortOrder,_that.isDefault);case _:
  return null;

}
}

}

/// @nodoc


class _Subject implements Subject {
  const _Subject({required this.id, required this.stamp, required this.name, required this.colorIndex, required this.sortOrder, this.isDefault = false});
  

@override final  String id;
@override final  SyncStamp stamp;
@override final  String name;
@override final  int colorIndex;
@override final  int sortOrder;
@override@JsonKey() final  bool isDefault;

/// Create a copy of Subject
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SubjectCopyWith<_Subject> get copyWith => __$SubjectCopyWithImpl<_Subject>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _Subject&&(identical(other.id, id) || other.id == id)&&(identical(other.stamp, stamp) || other.stamp == stamp)&&(identical(other.name, name) || other.name == name)&&(identical(other.colorIndex, colorIndex) || other.colorIndex == colorIndex)&&(identical(other.sortOrder, sortOrder) || other.sortOrder == sortOrder)&&(identical(other.isDefault, isDefault) || other.isDefault == isDefault));
}


@override
int get hashCode {
    return Object.hash(runtimeType,id,stamp,name,colorIndex,sortOrder,isDefault);
}

@override
String toString() {
    return 'Subject(id: $id, stamp: $stamp, name: $name, colorIndex: $colorIndex, sortOrder: $sortOrder, isDefault: $isDefault)';
}


}

/// @nodoc
abstract mixin class _$SubjectCopyWith<$Res> implements $SubjectCopyWith<$Res> {
  factory _$SubjectCopyWith(_Subject value, $Res Function(_Subject) _then) = __$SubjectCopyWithImpl;
@override @useResult
$Res call({
 String id, SyncStamp stamp, String name, int colorIndex, int sortOrder, bool isDefault
});


@override $SyncStampCopyWith<$Res> get stamp;

}
/// @nodoc
class __$SubjectCopyWithImpl<$Res>
    implements _$SubjectCopyWith<$Res> {
  __$SubjectCopyWithImpl(this._self, this._then);

  final _Subject _self;
  final $Res Function(_Subject) _then;

/// Create a copy of Subject
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? stamp = null,Object? name = null,Object? colorIndex = null,Object? sortOrder = null,Object? isDefault = null,}) {
  return _then(_Subject(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,stamp: null == stamp ? _self.stamp : stamp // ignore: cast_nullable_to_non_nullable
as SyncStamp,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,colorIndex: null == colorIndex ? _self.colorIndex : colorIndex // ignore: cast_nullable_to_non_nullable
as int,sortOrder: null == sortOrder ? _self.sortOrder : sortOrder // ignore: cast_nullable_to_non_nullable
as int,isDefault: null == isDefault ? _self.isDefault : isDefault // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

/// Create a copy of Subject
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
