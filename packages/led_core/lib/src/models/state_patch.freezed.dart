// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'state_patch.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$StatePatch {

@JsonKey(includeIfNull: false) bool? get on;@JsonKey(includeIfNull: false) int? get bri;@JsonKey(includeIfNull: false) int? get tt;@JsonKey(includeIfNull: false) int? get cct;@JsonKey(includeIfNull: false) List<int>? get col;@JsonKey(includeIfNull: false) int? get fx;@JsonKey(includeIfNull: false) int? get sx;@JsonKey(includeIfNull: false) int? get ix;@JsonKey(includeIfNull: false) int? get pal;@JsonKey(includeIfNull: false) List<Segment>? get seg;@JsonKey(includeIfNull: false) String? get pattern;
/// Create a copy of StatePatch
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$StatePatchCopyWith<StatePatch> get copyWith => _$StatePatchCopyWithImpl<StatePatch>(this as StatePatch, _$identity);

  /// Serializes this StatePatch to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is StatePatch&&(identical(other.on, on) || other.on == on)&&(identical(other.bri, bri) || other.bri == bri)&&(identical(other.tt, tt) || other.tt == tt)&&(identical(other.cct, cct) || other.cct == cct)&&const DeepCollectionEquality().equals(other.col, col)&&(identical(other.fx, fx) || other.fx == fx)&&(identical(other.sx, sx) || other.sx == sx)&&(identical(other.ix, ix) || other.ix == ix)&&(identical(other.pal, pal) || other.pal == pal)&&const DeepCollectionEquality().equals(other.seg, seg)&&(identical(other.pattern, pattern) || other.pattern == pattern));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,on,bri,tt,cct,const DeepCollectionEquality().hash(col),fx,sx,ix,pal,const DeepCollectionEquality().hash(seg),pattern);

@override
String toString() {
  return 'StatePatch(on: $on, bri: $bri, tt: $tt, cct: $cct, col: $col, fx: $fx, sx: $sx, ix: $ix, pal: $pal, seg: $seg, pattern: $pattern)';
}


}

/// @nodoc
abstract mixin class $StatePatchCopyWith<$Res>  {
  factory $StatePatchCopyWith(StatePatch value, $Res Function(StatePatch) _then) = _$StatePatchCopyWithImpl;
@useResult
$Res call({
@JsonKey(includeIfNull: false) bool? on,@JsonKey(includeIfNull: false) int? bri,@JsonKey(includeIfNull: false) int? tt,@JsonKey(includeIfNull: false) int? cct,@JsonKey(includeIfNull: false) List<int>? col,@JsonKey(includeIfNull: false) int? fx,@JsonKey(includeIfNull: false) int? sx,@JsonKey(includeIfNull: false) int? ix,@JsonKey(includeIfNull: false) int? pal,@JsonKey(includeIfNull: false) List<Segment>? seg,@JsonKey(includeIfNull: false) String? pattern
});




}
/// @nodoc
class _$StatePatchCopyWithImpl<$Res>
    implements $StatePatchCopyWith<$Res> {
  _$StatePatchCopyWithImpl(this._self, this._then);

  final StatePatch _self;
  final $Res Function(StatePatch) _then;

/// Create a copy of StatePatch
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? on = freezed,Object? bri = freezed,Object? tt = freezed,Object? cct = freezed,Object? col = freezed,Object? fx = freezed,Object? sx = freezed,Object? ix = freezed,Object? pal = freezed,Object? seg = freezed,Object? pattern = freezed,}) {
  return _then(StatePatch(
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
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [StatePatch].
extension StatePatchPatterns on StatePatch {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _StatePatch value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _StatePatch() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _StatePatch value)  $default,){
final _that = this;
switch (_that) {
case _StatePatch():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _StatePatch value)?  $default,){
final _that = this;
switch (_that) {
case _StatePatch() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(includeIfNull: false)  bool? on, @JsonKey(includeIfNull: false)  int? bri, @JsonKey(includeIfNull: false)  int? tt, @JsonKey(includeIfNull: false)  int? cct, @JsonKey(includeIfNull: false)  List<int>? col, @JsonKey(includeIfNull: false)  int? fx, @JsonKey(includeIfNull: false)  int? sx, @JsonKey(includeIfNull: false)  int? ix, @JsonKey(includeIfNull: false)  int? pal, @JsonKey(includeIfNull: false)  List<Segment>? seg, @JsonKey(includeIfNull: false)  String? pattern)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _StatePatch() when $default != null:
return $default(_that.on,_that.bri,_that.tt,_that.cct,_that.col,_that.fx,_that.sx,_that.ix,_that.pal,_that.seg,_that.pattern);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(includeIfNull: false)  bool? on, @JsonKey(includeIfNull: false)  int? bri, @JsonKey(includeIfNull: false)  int? tt, @JsonKey(includeIfNull: false)  int? cct, @JsonKey(includeIfNull: false)  List<int>? col, @JsonKey(includeIfNull: false)  int? fx, @JsonKey(includeIfNull: false)  int? sx, @JsonKey(includeIfNull: false)  int? ix, @JsonKey(includeIfNull: false)  int? pal, @JsonKey(includeIfNull: false)  List<Segment>? seg, @JsonKey(includeIfNull: false)  String? pattern)  $default,) {final _that = this;
switch (_that) {
case _StatePatch():
return $default(_that.on,_that.bri,_that.tt,_that.cct,_that.col,_that.fx,_that.sx,_that.ix,_that.pal,_that.seg,_that.pattern);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(includeIfNull: false)  bool? on, @JsonKey(includeIfNull: false)  int? bri, @JsonKey(includeIfNull: false)  int? tt, @JsonKey(includeIfNull: false)  int? cct, @JsonKey(includeIfNull: false)  List<int>? col, @JsonKey(includeIfNull: false)  int? fx, @JsonKey(includeIfNull: false)  int? sx, @JsonKey(includeIfNull: false)  int? ix, @JsonKey(includeIfNull: false)  int? pal, @JsonKey(includeIfNull: false)  List<Segment>? seg, @JsonKey(includeIfNull: false)  String? pattern)?  $default,) {final _that = this;
switch (_that) {
case _StatePatch() when $default != null:
return $default(_that.on,_that.bri,_that.tt,_that.cct,_that.col,_that.fx,_that.sx,_that.ix,_that.pal,_that.seg,_that.pattern);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _StatePatch implements StatePatch {
  const _StatePatch({@JsonKey(includeIfNull: false) this.on, @JsonKey(includeIfNull: false) this.bri, @JsonKey(includeIfNull: false) this.tt, @JsonKey(includeIfNull: false) this.cct, @JsonKey(includeIfNull: false)  List<int>? col, @JsonKey(includeIfNull: false) this.fx, @JsonKey(includeIfNull: false) this.sx, @JsonKey(includeIfNull: false) this.ix, @JsonKey(includeIfNull: false) this.pal, @JsonKey(includeIfNull: false)  List<Segment>? seg, @JsonKey(includeIfNull: false) this.pattern}): _col = col,_seg = seg;
  factory _StatePatch.fromJson(Map<String, dynamic> json) => _$StatePatchFromJson(json);

@override@JsonKey(includeIfNull: false) final  bool? on;
@override@JsonKey(includeIfNull: false) final  int? bri;
@override@JsonKey(includeIfNull: false) final  int? tt;
@override@JsonKey(includeIfNull: false) final  int? cct;
 final  List<int>? _col;
@override@JsonKey(includeIfNull: false) List<int>? get col {
  final value = _col;
  if (value == null) return null;
  if (_col is EqualUnmodifiableListView) return _col;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(value);
}

@override@JsonKey(includeIfNull: false) final  int? fx;
@override@JsonKey(includeIfNull: false) final  int? sx;
@override@JsonKey(includeIfNull: false) final  int? ix;
@override@JsonKey(includeIfNull: false) final  int? pal;
 final  List<Segment>? _seg;
@override@JsonKey(includeIfNull: false) List<Segment>? get seg {
  final value = _seg;
  if (value == null) return null;
  if (_seg is EqualUnmodifiableListView) return _seg;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(value);
}

@override@JsonKey(includeIfNull: false) final  String? pattern;

/// Create a copy of StatePatch
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$StatePatchCopyWith<_StatePatch> get copyWith => __$StatePatchCopyWithImpl<_StatePatch>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$StatePatchToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _StatePatch&&(identical(other.on, on) || other.on == on)&&(identical(other.bri, bri) || other.bri == bri)&&(identical(other.tt, tt) || other.tt == tt)&&(identical(other.cct, cct) || other.cct == cct)&&const DeepCollectionEquality().equals(other._col, _col)&&(identical(other.fx, fx) || other.fx == fx)&&(identical(other.sx, sx) || other.sx == sx)&&(identical(other.ix, ix) || other.ix == ix)&&(identical(other.pal, pal) || other.pal == pal)&&const DeepCollectionEquality().equals(other._seg, _seg)&&(identical(other.pattern, pattern) || other.pattern == pattern));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,on,bri,tt,cct,const DeepCollectionEquality().hash(_col),fx,sx,ix,pal,const DeepCollectionEquality().hash(_seg),pattern);

@override
String toString() {
  return 'StatePatch(on: $on, bri: $bri, tt: $tt, cct: $cct, col: $col, fx: $fx, sx: $sx, ix: $ix, pal: $pal, seg: $seg, pattern: $pattern)';
}


}

/// @nodoc
abstract mixin class _$StatePatchCopyWith<$Res> implements $StatePatchCopyWith<$Res> {
  factory _$StatePatchCopyWith(_StatePatch value, $Res Function(_StatePatch) _then) = __$StatePatchCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(includeIfNull: false) bool? on,@JsonKey(includeIfNull: false) int? bri,@JsonKey(includeIfNull: false) int? tt,@JsonKey(includeIfNull: false) int? cct,@JsonKey(includeIfNull: false) List<int>? col,@JsonKey(includeIfNull: false) int? fx,@JsonKey(includeIfNull: false) int? sx,@JsonKey(includeIfNull: false) int? ix,@JsonKey(includeIfNull: false) int? pal,@JsonKey(includeIfNull: false) List<Segment>? seg,@JsonKey(includeIfNull: false) String? pattern
});




}
/// @nodoc
class __$StatePatchCopyWithImpl<$Res>
    implements _$StatePatchCopyWith<$Res> {
  __$StatePatchCopyWithImpl(this._self, this._then);

  final _StatePatch _self;
  final $Res Function(_StatePatch) _then;

/// Create a copy of StatePatch
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? on = freezed,Object? bri = freezed,Object? tt = freezed,Object? cct = freezed,Object? col = freezed,Object? fx = freezed,Object? sx = freezed,Object? ix = freezed,Object? pal = freezed,Object? seg = freezed,Object? pattern = freezed,}) {
  return _then(_StatePatch(
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
as String?,
  ));
}


}

// dart format on
