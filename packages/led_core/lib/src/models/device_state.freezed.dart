// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'device_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$DeviceState {

 bool? get on; int? get bri; int? get tt; int? get cct; List<int>? get col; int? get fx; int? get sx; int? get ix; int? get pal; List<Segment>? get seg; String? get pattern; bool get live;
/// Create a copy of DeviceState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DeviceStateCopyWith<DeviceState> get copyWith => _$DeviceStateCopyWithImpl<DeviceState>(this as DeviceState, _$identity);

  /// Serializes this DeviceState to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DeviceState&&(identical(other.on, on) || other.on == on)&&(identical(other.bri, bri) || other.bri == bri)&&(identical(other.tt, tt) || other.tt == tt)&&(identical(other.cct, cct) || other.cct == cct)&&const DeepCollectionEquality().equals(other.col, col)&&(identical(other.fx, fx) || other.fx == fx)&&(identical(other.sx, sx) || other.sx == sx)&&(identical(other.ix, ix) || other.ix == ix)&&(identical(other.pal, pal) || other.pal == pal)&&const DeepCollectionEquality().equals(other.seg, seg)&&(identical(other.pattern, pattern) || other.pattern == pattern)&&(identical(other.live, live) || other.live == live));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,on,bri,tt,cct,const DeepCollectionEquality().hash(col),fx,sx,ix,pal,const DeepCollectionEquality().hash(seg),pattern,live);

@override
String toString() {
  return 'DeviceState(on: $on, bri: $bri, tt: $tt, cct: $cct, col: $col, fx: $fx, sx: $sx, ix: $ix, pal: $pal, seg: $seg, pattern: $pattern, live: $live)';
}


}

/// @nodoc
abstract mixin class $DeviceStateCopyWith<$Res>  {
  factory $DeviceStateCopyWith(DeviceState value, $Res Function(DeviceState) _then) = _$DeviceStateCopyWithImpl;
@useResult
$Res call({
 bool? on, int? bri, int? tt, int? cct, List<int>? col, int? fx, int? sx, int? ix, int? pal, List<Segment>? seg, String? pattern, bool live
});




}
/// @nodoc
class _$DeviceStateCopyWithImpl<$Res>
    implements $DeviceStateCopyWith<$Res> {
  _$DeviceStateCopyWithImpl(this._self, this._then);

  final DeviceState _self;
  final $Res Function(DeviceState) _then;

/// Create a copy of DeviceState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? on = freezed,Object? bri = freezed,Object? tt = freezed,Object? cct = freezed,Object? col = freezed,Object? fx = freezed,Object? sx = freezed,Object? ix = freezed,Object? pal = freezed,Object? seg = freezed,Object? pattern = freezed,Object? live = null,}) {
  return _then(DeviceState(
on: freezed == on ? _self.on : on // ignore: cast_nullable_to_non_nullable
as bool?,bri: freezed == bri ? _self.bri : bri // ignore: cast_nullable_to_non_nullable
as int?,tt: freezed == tt ? _self.tt : tt // ignore: cast_nullable_to_non_nullable
as int?,cct: freezed == cct ? _self.cct : cct // ignore: cast_nullable_to_non_nullable
as int?,col: freezed == col ? _self.col : col // ignore: cast_nullable_to_non_nullable
as List<int>?,fx: freezed == fx ? _self.fx : fx // ignore: cast_nullable_to_non_nullable
as int?,sx: freezed == sx ? _self.sx : sx // ignore: cast_nullable_to_non_nullable
as int?,ix: freezed == ix ? _self.ix : ix // ignore: cast_nullable_to_non_nullable
as int?,pal: freezed == pal ? _self.pal : pal // ignore: cast_nullable_to_non_nullable
as int?,seg: freezed == seg ? _self.seg : seg // ignore: cast_nullable_to_non_nullable
as List<Segment>?,pattern: freezed == pattern ? _self.pattern : pattern // ignore: cast_nullable_to_non_nullable
as String?,live: null == live ? _self.live : live // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [DeviceState].
extension DeviceStatePatterns on DeviceState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _DeviceState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _DeviceState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _DeviceState value)  $default,){
final _that = this;
switch (_that) {
case _DeviceState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _DeviceState value)?  $default,){
final _that = this;
switch (_that) {
case _DeviceState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( bool? on,  int? bri,  int? tt,  int? cct,  List<int>? col,  int? fx,  int? sx,  int? ix,  int? pal,  List<Segment>? seg,  String? pattern,  bool live)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _DeviceState() when $default != null:
return $default(_that.on,_that.bri,_that.tt,_that.cct,_that.col,_that.fx,_that.sx,_that.ix,_that.pal,_that.seg,_that.pattern,_that.live);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( bool? on,  int? bri,  int? tt,  int? cct,  List<int>? col,  int? fx,  int? sx,  int? ix,  int? pal,  List<Segment>? seg,  String? pattern,  bool live)  $default,) {final _that = this;
switch (_that) {
case _DeviceState():
return $default(_that.on,_that.bri,_that.tt,_that.cct,_that.col,_that.fx,_that.sx,_that.ix,_that.pal,_that.seg,_that.pattern,_that.live);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( bool? on,  int? bri,  int? tt,  int? cct,  List<int>? col,  int? fx,  int? sx,  int? ix,  int? pal,  List<Segment>? seg,  String? pattern,  bool live)?  $default,) {final _that = this;
switch (_that) {
case _DeviceState() when $default != null:
return $default(_that.on,_that.bri,_that.tt,_that.cct,_that.col,_that.fx,_that.sx,_that.ix,_that.pal,_that.seg,_that.pattern,_that.live);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _DeviceState implements DeviceState {
  const _DeviceState({this.on, this.bri, this.tt, this.cct,  List<int>? col, this.fx, this.sx, this.ix, this.pal,  List<Segment>? seg, this.pattern, this.live = false}): _col = col,_seg = seg;
  factory _DeviceState.fromJson(Map<String, dynamic> json) => _$DeviceStateFromJson(json);

@override final  bool? on;
@override final  int? bri;
@override final  int? tt;
@override final  int? cct;
 final  List<int>? _col;
@override List<int>? get col {
  final value = _col;
  if (value == null) return null;
  if (_col is EqualUnmodifiableListView) return _col;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(value);
}

@override final  int? fx;
@override final  int? sx;
@override final  int? ix;
@override final  int? pal;
 final  List<Segment>? _seg;
@override List<Segment>? get seg {
  final value = _seg;
  if (value == null) return null;
  if (_seg is EqualUnmodifiableListView) return _seg;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(value);
}

@override final  String? pattern;
@override@JsonKey() final  bool live;

/// Create a copy of DeviceState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DeviceStateCopyWith<_DeviceState> get copyWith => __$DeviceStateCopyWithImpl<_DeviceState>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$DeviceStateToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _DeviceState&&(identical(other.on, on) || other.on == on)&&(identical(other.bri, bri) || other.bri == bri)&&(identical(other.tt, tt) || other.tt == tt)&&(identical(other.cct, cct) || other.cct == cct)&&const DeepCollectionEquality().equals(other._col, _col)&&(identical(other.fx, fx) || other.fx == fx)&&(identical(other.sx, sx) || other.sx == sx)&&(identical(other.ix, ix) || other.ix == ix)&&(identical(other.pal, pal) || other.pal == pal)&&const DeepCollectionEquality().equals(other._seg, _seg)&&(identical(other.pattern, pattern) || other.pattern == pattern)&&(identical(other.live, live) || other.live == live));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,on,bri,tt,cct,const DeepCollectionEquality().hash(_col),fx,sx,ix,pal,const DeepCollectionEquality().hash(_seg),pattern,live);

@override
String toString() {
  return 'DeviceState(on: $on, bri: $bri, tt: $tt, cct: $cct, col: $col, fx: $fx, sx: $sx, ix: $ix, pal: $pal, seg: $seg, pattern: $pattern, live: $live)';
}


}

/// @nodoc
abstract mixin class _$DeviceStateCopyWith<$Res> implements $DeviceStateCopyWith<$Res> {
  factory _$DeviceStateCopyWith(_DeviceState value, $Res Function(_DeviceState) _then) = __$DeviceStateCopyWithImpl;
@override @useResult
$Res call({
 bool? on, int? bri, int? tt, int? cct, List<int>? col, int? fx, int? sx, int? ix, int? pal, List<Segment>? seg, String? pattern, bool live
});




}
/// @nodoc
class __$DeviceStateCopyWithImpl<$Res>
    implements _$DeviceStateCopyWith<$Res> {
  __$DeviceStateCopyWithImpl(this._self, this._then);

  final _DeviceState _self;
  final $Res Function(_DeviceState) _then;

/// Create a copy of DeviceState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? on = freezed,Object? bri = freezed,Object? tt = freezed,Object? cct = freezed,Object? col = freezed,Object? fx = freezed,Object? sx = freezed,Object? ix = freezed,Object? pal = freezed,Object? seg = freezed,Object? pattern = freezed,Object? live = null,}) {
  return _then(_DeviceState(
on: freezed == on ? _self.on : on // ignore: cast_nullable_to_non_nullable
as bool?,bri: freezed == bri ? _self.bri : bri // ignore: cast_nullable_to_non_nullable
as int?,tt: freezed == tt ? _self.tt : tt // ignore: cast_nullable_to_non_nullable
as int?,cct: freezed == cct ? _self.cct : cct // ignore: cast_nullable_to_non_nullable
as int?,col: freezed == col ? _self._col : col // ignore: cast_nullable_to_non_nullable
as List<int>?,fx: freezed == fx ? _self.fx : fx // ignore: cast_nullable_to_non_nullable
as int?,sx: freezed == sx ? _self.sx : sx // ignore: cast_nullable_to_non_nullable
as int?,ix: freezed == ix ? _self.ix : ix // ignore: cast_nullable_to_non_nullable
as int?,pal: freezed == pal ? _self.pal : pal // ignore: cast_nullable_to_non_nullable
as int?,seg: freezed == seg ? _self._seg : seg // ignore: cast_nullable_to_non_nullable
as List<Segment>?,pattern: freezed == pattern ? _self.pattern : pattern // ignore: cast_nullable_to_non_nullable
as String?,live: null == live ? _self.live : live // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
