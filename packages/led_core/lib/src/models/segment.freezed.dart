// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'segment.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Segment {

 int get id; int? get start; int? get stop; bool? get on; int? get bri; List<int>? get col; int? get fx;
/// Create a copy of Segment
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SegmentCopyWith<Segment> get copyWith => _$SegmentCopyWithImpl<Segment>(this as Segment, _$identity);

  /// Serializes this Segment to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Segment&&(identical(other.id, id) || other.id == id)&&(identical(other.start, start) || other.start == start)&&(identical(other.stop, stop) || other.stop == stop)&&(identical(other.on, on) || other.on == on)&&(identical(other.bri, bri) || other.bri == bri)&&const DeepCollectionEquality().equals(other.col, col)&&(identical(other.fx, fx) || other.fx == fx));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,start,stop,on,bri,const DeepCollectionEquality().hash(col),fx);

@override
String toString() {
  return 'Segment(id: $id, start: $start, stop: $stop, on: $on, bri: $bri, col: $col, fx: $fx)';
}


}

/// @nodoc
abstract mixin class $SegmentCopyWith<$Res>  {
  factory $SegmentCopyWith(Segment value, $Res Function(Segment) _then) = _$SegmentCopyWithImpl;
@useResult
$Res call({
 int id, int? start, int? stop, bool? on, int? bri, List<int>? col, int? fx
});




}
/// @nodoc
class _$SegmentCopyWithImpl<$Res>
    implements $SegmentCopyWith<$Res> {
  _$SegmentCopyWithImpl(this._self, this._then);

  final Segment _self;
  final $Res Function(Segment) _then;

/// Create a copy of Segment
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? start = freezed,Object? stop = freezed,Object? on = freezed,Object? bri = freezed,Object? col = freezed,Object? fx = freezed,}) {
  return _then(Segment(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,start: freezed == start ? _self.start : start // ignore: cast_nullable_to_non_nullable
as int?,stop: freezed == stop ? _self.stop : stop // ignore: cast_nullable_to_non_nullable
as int?,on: freezed == on ? _self.on : on // ignore: cast_nullable_to_non_nullable
as bool?,bri: freezed == bri ? _self.bri : bri // ignore: cast_nullable_to_non_nullable
as int?,col: freezed == col ? _self.col : col // ignore: cast_nullable_to_non_nullable
as List<int>?,fx: freezed == fx ? _self.fx : fx // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}

}


/// Adds pattern-matching-related methods to [Segment].
extension SegmentPatterns on Segment {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Segment value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Segment() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Segment value)  $default,){
final _that = this;
switch (_that) {
case _Segment():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Segment value)?  $default,){
final _that = this;
switch (_that) {
case _Segment() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id,  int? start,  int? stop,  bool? on,  int? bri,  List<int>? col,  int? fx)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Segment() when $default != null:
return $default(_that.id,_that.start,_that.stop,_that.on,_that.bri,_that.col,_that.fx);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id,  int? start,  int? stop,  bool? on,  int? bri,  List<int>? col,  int? fx)  $default,) {final _that = this;
switch (_that) {
case _Segment():
return $default(_that.id,_that.start,_that.stop,_that.on,_that.bri,_that.col,_that.fx);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id,  int? start,  int? stop,  bool? on,  int? bri,  List<int>? col,  int? fx)?  $default,) {final _that = this;
switch (_that) {
case _Segment() when $default != null:
return $default(_that.id,_that.start,_that.stop,_that.on,_that.bri,_that.col,_that.fx);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Segment implements Segment {
  const _Segment({required this.id, this.start, this.stop, this.on, this.bri,  List<int>? col, this.fx}): _col = col;
  factory _Segment.fromJson(Map<String, dynamic> json) => _$SegmentFromJson(json);

@override final  int id;
@override final  int? start;
@override final  int? stop;
@override final  bool? on;
@override final  int? bri;
 final  List<int>? _col;
@override List<int>? get col {
  final value = _col;
  if (value == null) return null;
  if (_col is EqualUnmodifiableListView) return _col;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(value);
}

@override final  int? fx;

/// Create a copy of Segment
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SegmentCopyWith<_Segment> get copyWith => __$SegmentCopyWithImpl<_Segment>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SegmentToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Segment&&(identical(other.id, id) || other.id == id)&&(identical(other.start, start) || other.start == start)&&(identical(other.stop, stop) || other.stop == stop)&&(identical(other.on, on) || other.on == on)&&(identical(other.bri, bri) || other.bri == bri)&&const DeepCollectionEquality().equals(other._col, _col)&&(identical(other.fx, fx) || other.fx == fx));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,start,stop,on,bri,const DeepCollectionEquality().hash(_col),fx);

@override
String toString() {
  return 'Segment(id: $id, start: $start, stop: $stop, on: $on, bri: $bri, col: $col, fx: $fx)';
}


}

/// @nodoc
abstract mixin class _$SegmentCopyWith<$Res> implements $SegmentCopyWith<$Res> {
  factory _$SegmentCopyWith(_Segment value, $Res Function(_Segment) _then) = __$SegmentCopyWithImpl;
@override @useResult
$Res call({
 int id, int? start, int? stop, bool? on, int? bri, List<int>? col, int? fx
});




}
/// @nodoc
class __$SegmentCopyWithImpl<$Res>
    implements _$SegmentCopyWith<$Res> {
  __$SegmentCopyWithImpl(this._self, this._then);

  final _Segment _self;
  final $Res Function(_Segment) _then;

/// Create a copy of Segment
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? start = freezed,Object? stop = freezed,Object? on = freezed,Object? bri = freezed,Object? col = freezed,Object? fx = freezed,}) {
  return _then(_Segment(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,start: freezed == start ? _self.start : start // ignore: cast_nullable_to_non_nullable
as int?,stop: freezed == stop ? _self.stop : stop // ignore: cast_nullable_to_non_nullable
as int?,on: freezed == on ? _self.on : on // ignore: cast_nullable_to_non_nullable
as bool?,bri: freezed == bri ? _self.bri : bri // ignore: cast_nullable_to_non_nullable
as int?,col: freezed == col ? _self._col : col // ignore: cast_nullable_to_non_nullable
as List<int>?,fx: freezed == fx ? _self.fx : fx // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}


}

// dart format on
