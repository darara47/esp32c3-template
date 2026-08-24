// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'device_descriptor.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$CctRange {

 int get min; int get max;
/// Create a copy of CctRange
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CctRangeCopyWith<CctRange> get copyWith => _$CctRangeCopyWithImpl<CctRange>(this as CctRange, _$identity);

  /// Serializes this CctRange to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CctRange&&(identical(other.min, min) || other.min == min)&&(identical(other.max, max) || other.max == max));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,min,max);

@override
String toString() {
  return 'CctRange(min: $min, max: $max)';
}


}

/// @nodoc
abstract mixin class $CctRangeCopyWith<$Res>  {
  factory $CctRangeCopyWith(CctRange value, $Res Function(CctRange) _then) = _$CctRangeCopyWithImpl;
@useResult
$Res call({
 int min, int max
});




}
/// @nodoc
class _$CctRangeCopyWithImpl<$Res>
    implements $CctRangeCopyWith<$Res> {
  _$CctRangeCopyWithImpl(this._self, this._then);

  final CctRange _self;
  final $Res Function(CctRange) _then;

/// Create a copy of CctRange
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? min = null,Object? max = null,}) {
  return _then(CctRange(
min: null == min ? _self.min : min // ignore: cast_nullable_to_non_nullable
as int,max: null == max ? _self.max : max // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [CctRange].
extension CctRangePatterns on CctRange {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CctRange value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CctRange() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CctRange value)  $default,){
final _that = this;
switch (_that) {
case _CctRange():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CctRange value)?  $default,){
final _that = this;
switch (_that) {
case _CctRange() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int min,  int max)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CctRange() when $default != null:
return $default(_that.min,_that.max);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int min,  int max)  $default,) {final _that = this;
switch (_that) {
case _CctRange():
return $default(_that.min,_that.max);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int min,  int max)?  $default,) {final _that = this;
switch (_that) {
case _CctRange() when $default != null:
return $default(_that.min,_that.max);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _CctRange implements CctRange {
  const _CctRange({required this.min, required this.max});
  factory _CctRange.fromJson(Map<String, dynamic> json) => _$CctRangeFromJson(json);

@override final  int min;
@override final  int max;

/// Create a copy of CctRange
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CctRangeCopyWith<_CctRange> get copyWith => __$CctRangeCopyWithImpl<_CctRange>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CctRangeToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CctRange&&(identical(other.min, min) || other.min == min)&&(identical(other.max, max) || other.max == max));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,min,max);

@override
String toString() {
  return 'CctRange(min: $min, max: $max)';
}


}

/// @nodoc
abstract mixin class _$CctRangeCopyWith<$Res> implements $CctRangeCopyWith<$Res> {
  factory _$CctRangeCopyWith(_CctRange value, $Res Function(_CctRange) _then) = __$CctRangeCopyWithImpl;
@override @useResult
$Res call({
 int min, int max
});




}
/// @nodoc
class __$CctRangeCopyWithImpl<$Res>
    implements _$CctRangeCopyWith<$Res> {
  __$CctRangeCopyWithImpl(this._self, this._then);

  final _CctRange _self;
  final $Res Function(_CctRange) _then;

/// Create a copy of CctRange
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? min = null,Object? max = null,}) {
  return _then(_CctRange(
min: null == min ? _self.min : min // ignore: cast_nullable_to_non_nullable
as int,max: null == max ? _self.max : max // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}


/// @nodoc
mixin _$Geometry {

 GeometryType get type; int get count; int? get width;@JsonKey(name: 'spacing_mm') double? get spacingMm; List<List<double>>? get map;
/// Create a copy of Geometry
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$GeometryCopyWith<Geometry> get copyWith => _$GeometryCopyWithImpl<Geometry>(this as Geometry, _$identity);

  /// Serializes this Geometry to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Geometry&&(identical(other.type, type) || other.type == type)&&(identical(other.count, count) || other.count == count)&&(identical(other.width, width) || other.width == width)&&(identical(other.spacingMm, spacingMm) || other.spacingMm == spacingMm)&&const DeepCollectionEquality().equals(other.map, map));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,type,count,width,spacingMm,const DeepCollectionEquality().hash(map));

@override
String toString() {
  return 'Geometry(type: $type, count: $count, width: $width, spacingMm: $spacingMm, map: $map)';
}


}

/// @nodoc
abstract mixin class $GeometryCopyWith<$Res>  {
  factory $GeometryCopyWith(Geometry value, $Res Function(Geometry) _then) = _$GeometryCopyWithImpl;
@useResult
$Res call({
 GeometryType type, int count, int? width,@JsonKey(name: 'spacing_mm') double? spacingMm, List<List<double>>? map
});




}
/// @nodoc
class _$GeometryCopyWithImpl<$Res>
    implements $GeometryCopyWith<$Res> {
  _$GeometryCopyWithImpl(this._self, this._then);

  final Geometry _self;
  final $Res Function(Geometry) _then;

/// Create a copy of Geometry
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? type = null,Object? count = null,Object? width = freezed,Object? spacingMm = freezed,Object? map = freezed,}) {
  return _then(Geometry(
type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as GeometryType,count: null == count ? _self.count : count // ignore: cast_nullable_to_non_nullable
as int,width: freezed == width ? _self.width : width // ignore: cast_nullable_to_non_nullable
as int?,spacingMm: freezed == spacingMm ? _self.spacingMm : spacingMm // ignore: cast_nullable_to_non_nullable
as double?,map: freezed == map ? _self.map : map // ignore: cast_nullable_to_non_nullable
as List<List<double>>?,
  ));
}

}


/// Adds pattern-matching-related methods to [Geometry].
extension GeometryPatterns on Geometry {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Geometry value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Geometry() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Geometry value)  $default,){
final _that = this;
switch (_that) {
case _Geometry():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Geometry value)?  $default,){
final _that = this;
switch (_that) {
case _Geometry() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( GeometryType type,  int count,  int? width, @JsonKey(name: 'spacing_mm')  double? spacingMm,  List<List<double>>? map)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Geometry() when $default != null:
return $default(_that.type,_that.count,_that.width,_that.spacingMm,_that.map);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( GeometryType type,  int count,  int? width, @JsonKey(name: 'spacing_mm')  double? spacingMm,  List<List<double>>? map)  $default,) {final _that = this;
switch (_that) {
case _Geometry():
return $default(_that.type,_that.count,_that.width,_that.spacingMm,_that.map);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( GeometryType type,  int count,  int? width, @JsonKey(name: 'spacing_mm')  double? spacingMm,  List<List<double>>? map)?  $default,) {final _that = this;
switch (_that) {
case _Geometry() when $default != null:
return $default(_that.type,_that.count,_that.width,_that.spacingMm,_that.map);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Geometry implements Geometry {
  const _Geometry({required this.type, required this.count, this.width, @JsonKey(name: 'spacing_mm') this.spacingMm,  List<List<double>>? map}): _map = map;
  factory _Geometry.fromJson(Map<String, dynamic> json) => _$GeometryFromJson(json);

@override final  GeometryType type;
@override final  int count;
@override final  int? width;
@override@JsonKey(name: 'spacing_mm') final  double? spacingMm;
 final  List<List<double>>? _map;
@override List<List<double>>? get map {
  final value = _map;
  if (value == null) return null;
  if (_map is EqualUnmodifiableListView) return _map;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(value);
}


/// Create a copy of Geometry
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$GeometryCopyWith<_Geometry> get copyWith => __$GeometryCopyWithImpl<_Geometry>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$GeometryToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Geometry&&(identical(other.type, type) || other.type == type)&&(identical(other.count, count) || other.count == count)&&(identical(other.width, width) || other.width == width)&&(identical(other.spacingMm, spacingMm) || other.spacingMm == spacingMm)&&const DeepCollectionEquality().equals(other._map, _map));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,type,count,width,spacingMm,const DeepCollectionEquality().hash(_map));

@override
String toString() {
  return 'Geometry(type: $type, count: $count, width: $width, spacingMm: $spacingMm, map: $map)';
}


}

/// @nodoc
abstract mixin class _$GeometryCopyWith<$Res> implements $GeometryCopyWith<$Res> {
  factory _$GeometryCopyWith(_Geometry value, $Res Function(_Geometry) _then) = __$GeometryCopyWithImpl;
@override @useResult
$Res call({
 GeometryType type, int count, int? width,@JsonKey(name: 'spacing_mm') double? spacingMm, List<List<double>>? map
});




}
/// @nodoc
class __$GeometryCopyWithImpl<$Res>
    implements _$GeometryCopyWith<$Res> {
  __$GeometryCopyWithImpl(this._self, this._then);

  final _Geometry _self;
  final $Res Function(_Geometry) _then;

/// Create a copy of Geometry
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? type = null,Object? count = null,Object? width = freezed,Object? spacingMm = freezed,Object? map = freezed,}) {
  return _then(_Geometry(
type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as GeometryType,count: null == count ? _self.count : count // ignore: cast_nullable_to_non_nullable
as int,width: freezed == width ? _self.width : width // ignore: cast_nullable_to_non_nullable
as int?,spacingMm: freezed == spacingMm ? _self.spacingMm : spacingMm // ignore: cast_nullable_to_non_nullable
as double?,map: freezed == map ? _self._map : map // ignore: cast_nullable_to_non_nullable
as List<List<double>>?,
  ));
}


}


/// @nodoc
mixin _$StreamConfig {

 StreamProto get proto; int get port; int get maxFps;
/// Create a copy of StreamConfig
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$StreamConfigCopyWith<StreamConfig> get copyWith => _$StreamConfigCopyWithImpl<StreamConfig>(this as StreamConfig, _$identity);

  /// Serializes this StreamConfig to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is StreamConfig&&(identical(other.proto, proto) || other.proto == proto)&&(identical(other.port, port) || other.port == port)&&(identical(other.maxFps, maxFps) || other.maxFps == maxFps));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,proto,port,maxFps);

@override
String toString() {
  return 'StreamConfig(proto: $proto, port: $port, maxFps: $maxFps)';
}


}

/// @nodoc
abstract mixin class $StreamConfigCopyWith<$Res>  {
  factory $StreamConfigCopyWith(StreamConfig value, $Res Function(StreamConfig) _then) = _$StreamConfigCopyWithImpl;
@useResult
$Res call({
 StreamProto proto, int port, int maxFps
});




}
/// @nodoc
class _$StreamConfigCopyWithImpl<$Res>
    implements $StreamConfigCopyWith<$Res> {
  _$StreamConfigCopyWithImpl(this._self, this._then);

  final StreamConfig _self;
  final $Res Function(StreamConfig) _then;

/// Create a copy of StreamConfig
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? proto = null,Object? port = null,Object? maxFps = null,}) {
  return _then(StreamConfig(
proto: null == proto ? _self.proto : proto // ignore: cast_nullable_to_non_nullable
as StreamProto,port: null == port ? _self.port : port // ignore: cast_nullable_to_non_nullable
as int,maxFps: null == maxFps ? _self.maxFps : maxFps // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [StreamConfig].
extension StreamConfigPatterns on StreamConfig {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _StreamConfig value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _StreamConfig() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _StreamConfig value)  $default,){
final _that = this;
switch (_that) {
case _StreamConfig():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _StreamConfig value)?  $default,){
final _that = this;
switch (_that) {
case _StreamConfig() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( StreamProto proto,  int port,  int maxFps)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _StreamConfig() when $default != null:
return $default(_that.proto,_that.port,_that.maxFps);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( StreamProto proto,  int port,  int maxFps)  $default,) {final _that = this;
switch (_that) {
case _StreamConfig():
return $default(_that.proto,_that.port,_that.maxFps);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( StreamProto proto,  int port,  int maxFps)?  $default,) {final _that = this;
switch (_that) {
case _StreamConfig() when $default != null:
return $default(_that.proto,_that.port,_that.maxFps);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _StreamConfig implements StreamConfig {
  const _StreamConfig({required this.proto, this.port = 4048, this.maxFps = 60});
  factory _StreamConfig.fromJson(Map<String, dynamic> json) => _$StreamConfigFromJson(json);

@override final  StreamProto proto;
@override@JsonKey() final  int port;
@override@JsonKey() final  int maxFps;

/// Create a copy of StreamConfig
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$StreamConfigCopyWith<_StreamConfig> get copyWith => __$StreamConfigCopyWithImpl<_StreamConfig>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$StreamConfigToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _StreamConfig&&(identical(other.proto, proto) || other.proto == proto)&&(identical(other.port, port) || other.port == port)&&(identical(other.maxFps, maxFps) || other.maxFps == maxFps));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,proto,port,maxFps);

@override
String toString() {
  return 'StreamConfig(proto: $proto, port: $port, maxFps: $maxFps)';
}


}

/// @nodoc
abstract mixin class _$StreamConfigCopyWith<$Res> implements $StreamConfigCopyWith<$Res> {
  factory _$StreamConfigCopyWith(_StreamConfig value, $Res Function(_StreamConfig) _then) = __$StreamConfigCopyWithImpl;
@override @useResult
$Res call({
 StreamProto proto, int port, int maxFps
});




}
/// @nodoc
class __$StreamConfigCopyWithImpl<$Res>
    implements _$StreamConfigCopyWith<$Res> {
  __$StreamConfigCopyWithImpl(this._self, this._then);

  final _StreamConfig _self;
  final $Res Function(_StreamConfig) _then;

/// Create a copy of StreamConfig
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? proto = null,Object? port = null,Object? maxFps = null,}) {
  return _then(_StreamConfig(
proto: null == proto ? _self.proto : proto // ignore: cast_nullable_to_non_nullable
as StreamProto,port: null == port ? _self.port : port // ignore: cast_nullable_to_non_nullable
as int,maxFps: null == maxFps ? _self.maxFps : maxFps // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}


/// @nodoc
mixin _$DeviceDescriptor {

 int get schema; String get id; String get name; String get model; String? get fw; List<String> get caps; CctRange? get cct; Geometry? get geometry; StreamConfig? get stream;
/// Create a copy of DeviceDescriptor
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DeviceDescriptorCopyWith<DeviceDescriptor> get copyWith => _$DeviceDescriptorCopyWithImpl<DeviceDescriptor>(this as DeviceDescriptor, _$identity);

  /// Serializes this DeviceDescriptor to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DeviceDescriptor&&(identical(other.schema, schema) || other.schema == schema)&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.model, model) || other.model == model)&&(identical(other.fw, fw) || other.fw == fw)&&const DeepCollectionEquality().equals(other.caps, caps)&&(identical(other.cct, cct) || other.cct == cct)&&(identical(other.geometry, geometry) || other.geometry == geometry)&&(identical(other.stream, stream) || other.stream == stream));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,schema,id,name,model,fw,const DeepCollectionEquality().hash(caps),cct,geometry,stream);

@override
String toString() {
  return 'DeviceDescriptor(schema: $schema, id: $id, name: $name, model: $model, fw: $fw, caps: $caps, cct: $cct, geometry: $geometry, stream: $stream)';
}


}

/// @nodoc
abstract mixin class $DeviceDescriptorCopyWith<$Res>  {
  factory $DeviceDescriptorCopyWith(DeviceDescriptor value, $Res Function(DeviceDescriptor) _then) = _$DeviceDescriptorCopyWithImpl;
@useResult
$Res call({
 int schema, String id, String name, String model, String? fw, List<String> caps, CctRange? cct, Geometry? geometry, StreamConfig? stream
});


$CctRangeCopyWith<$Res>? get cct;$GeometryCopyWith<$Res>? get geometry;$StreamConfigCopyWith<$Res>? get stream;

}
/// @nodoc
class _$DeviceDescriptorCopyWithImpl<$Res>
    implements $DeviceDescriptorCopyWith<$Res> {
  _$DeviceDescriptorCopyWithImpl(this._self, this._then);

  final DeviceDescriptor _self;
  final $Res Function(DeviceDescriptor) _then;

/// Create a copy of DeviceDescriptor
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? schema = null,Object? id = null,Object? name = null,Object? model = null,Object? fw = freezed,Object? caps = null,Object? cct = freezed,Object? geometry = freezed,Object? stream = freezed,}) {
  return _then(DeviceDescriptor(
schema: null == schema ? _self.schema : schema // ignore: cast_nullable_to_non_nullable
as int,id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,model: null == model ? _self.model : model // ignore: cast_nullable_to_non_nullable
as String,fw: freezed == fw ? _self.fw : fw // ignore: cast_nullable_to_non_nullable
as String?,caps: null == caps ? _self.caps : caps // ignore: cast_nullable_to_non_nullable
as List<String>,cct: freezed == cct ? _self.cct : cct // ignore: cast_nullable_to_non_nullable
as CctRange?,geometry: freezed == geometry ? _self.geometry : geometry // ignore: cast_nullable_to_non_nullable
as Geometry?,stream: freezed == stream ? _self.stream : stream // ignore: cast_nullable_to_non_nullable
as StreamConfig?,
  ));
}
/// Create a copy of DeviceDescriptor
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CctRangeCopyWith<$Res>? get cct {
    if (_self.cct == null) {
    return null;
  }

  return $CctRangeCopyWith<$Res>(_self.cct!, (value) {
    return _then(_self.copyWith(cct: value));
  });
}/// Create a copy of DeviceDescriptor
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$GeometryCopyWith<$Res>? get geometry {
    if (_self.geometry == null) {
    return null;
  }

  return $GeometryCopyWith<$Res>(_self.geometry!, (value) {
    return _then(_self.copyWith(geometry: value));
  });
}/// Create a copy of DeviceDescriptor
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$StreamConfigCopyWith<$Res>? get stream {
    if (_self.stream == null) {
    return null;
  }

  return $StreamConfigCopyWith<$Res>(_self.stream!, (value) {
    return _then(_self.copyWith(stream: value));
  });
}
}


/// Adds pattern-matching-related methods to [DeviceDescriptor].
extension DeviceDescriptorPatterns on DeviceDescriptor {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _DeviceDescriptor value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _DeviceDescriptor() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _DeviceDescriptor value)  $default,){
final _that = this;
switch (_that) {
case _DeviceDescriptor():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _DeviceDescriptor value)?  $default,){
final _that = this;
switch (_that) {
case _DeviceDescriptor() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int schema,  String id,  String name,  String model,  String? fw,  List<String> caps,  CctRange? cct,  Geometry? geometry,  StreamConfig? stream)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _DeviceDescriptor() when $default != null:
return $default(_that.schema,_that.id,_that.name,_that.model,_that.fw,_that.caps,_that.cct,_that.geometry,_that.stream);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int schema,  String id,  String name,  String model,  String? fw,  List<String> caps,  CctRange? cct,  Geometry? geometry,  StreamConfig? stream)  $default,) {final _that = this;
switch (_that) {
case _DeviceDescriptor():
return $default(_that.schema,_that.id,_that.name,_that.model,_that.fw,_that.caps,_that.cct,_that.geometry,_that.stream);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int schema,  String id,  String name,  String model,  String? fw,  List<String> caps,  CctRange? cct,  Geometry? geometry,  StreamConfig? stream)?  $default,) {final _that = this;
switch (_that) {
case _DeviceDescriptor() when $default != null:
return $default(_that.schema,_that.id,_that.name,_that.model,_that.fw,_that.caps,_that.cct,_that.geometry,_that.stream);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _DeviceDescriptor extends DeviceDescriptor {
  const _DeviceDescriptor({required this.schema, required this.id, required this.name, required this.model, this.fw, required  List<String> caps, this.cct, this.geometry, this.stream}): _caps = caps,super._();
  factory _DeviceDescriptor.fromJson(Map<String, dynamic> json) => _$DeviceDescriptorFromJson(json);

@override final  int schema;
@override final  String id;
@override final  String name;
@override final  String model;
@override final  String? fw;
 final  List<String> _caps;
@override List<String> get caps {
  if (_caps is EqualUnmodifiableListView) return _caps;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_caps);
}

@override final  CctRange? cct;
@override final  Geometry? geometry;
@override final  StreamConfig? stream;

/// Create a copy of DeviceDescriptor
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DeviceDescriptorCopyWith<_DeviceDescriptor> get copyWith => __$DeviceDescriptorCopyWithImpl<_DeviceDescriptor>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$DeviceDescriptorToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _DeviceDescriptor&&(identical(other.schema, schema) || other.schema == schema)&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.model, model) || other.model == model)&&(identical(other.fw, fw) || other.fw == fw)&&const DeepCollectionEquality().equals(other._caps, _caps)&&(identical(other.cct, cct) || other.cct == cct)&&(identical(other.geometry, geometry) || other.geometry == geometry)&&(identical(other.stream, stream) || other.stream == stream));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,schema,id,name,model,fw,const DeepCollectionEquality().hash(_caps),cct,geometry,stream);

@override
String toString() {
  return 'DeviceDescriptor(schema: $schema, id: $id, name: $name, model: $model, fw: $fw, caps: $caps, cct: $cct, geometry: $geometry, stream: $stream)';
}


}

/// @nodoc
abstract mixin class _$DeviceDescriptorCopyWith<$Res> implements $DeviceDescriptorCopyWith<$Res> {
  factory _$DeviceDescriptorCopyWith(_DeviceDescriptor value, $Res Function(_DeviceDescriptor) _then) = __$DeviceDescriptorCopyWithImpl;
@override @useResult
$Res call({
 int schema, String id, String name, String model, String? fw, List<String> caps, CctRange? cct, Geometry? geometry, StreamConfig? stream
});


@override $CctRangeCopyWith<$Res>? get cct;@override $GeometryCopyWith<$Res>? get geometry;@override $StreamConfigCopyWith<$Res>? get stream;

}
/// @nodoc
class __$DeviceDescriptorCopyWithImpl<$Res>
    implements _$DeviceDescriptorCopyWith<$Res> {
  __$DeviceDescriptorCopyWithImpl(this._self, this._then);

  final _DeviceDescriptor _self;
  final $Res Function(_DeviceDescriptor) _then;

/// Create a copy of DeviceDescriptor
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? schema = null,Object? id = null,Object? name = null,Object? model = null,Object? fw = freezed,Object? caps = null,Object? cct = freezed,Object? geometry = freezed,Object? stream = freezed,}) {
  return _then(_DeviceDescriptor(
schema: null == schema ? _self.schema : schema // ignore: cast_nullable_to_non_nullable
as int,id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,model: null == model ? _self.model : model // ignore: cast_nullable_to_non_nullable
as String,fw: freezed == fw ? _self.fw : fw // ignore: cast_nullable_to_non_nullable
as String?,caps: null == caps ? _self._caps : caps // ignore: cast_nullable_to_non_nullable
as List<String>,cct: freezed == cct ? _self.cct : cct // ignore: cast_nullable_to_non_nullable
as CctRange?,geometry: freezed == geometry ? _self.geometry : geometry // ignore: cast_nullable_to_non_nullable
as Geometry?,stream: freezed == stream ? _self.stream : stream // ignore: cast_nullable_to_non_nullable
as StreamConfig?,
  ));
}

/// Create a copy of DeviceDescriptor
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CctRangeCopyWith<$Res>? get cct {
    if (_self.cct == null) {
    return null;
  }

  return $CctRangeCopyWith<$Res>(_self.cct!, (value) {
    return _then(_self.copyWith(cct: value));
  });
}/// Create a copy of DeviceDescriptor
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$GeometryCopyWith<$Res>? get geometry {
    if (_self.geometry == null) {
    return null;
  }

  return $GeometryCopyWith<$Res>(_self.geometry!, (value) {
    return _then(_self.copyWith(geometry: value));
  });
}/// Create a copy of DeviceDescriptor
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$StreamConfigCopyWith<$Res>? get stream {
    if (_self.stream == null) {
    return null;
  }

  return $StreamConfigCopyWith<$Res>(_self.stream!, (value) {
    return _then(_self.copyWith(stream: value));
  });
}
}

// dart format on
