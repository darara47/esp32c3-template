// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'device_descriptor.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_CctRange _$CctRangeFromJson(Map<String, dynamic> json) => _CctRange(
  min: (json['min'] as num).toInt(),
  max: (json['max'] as num).toInt(),
);

Map<String, dynamic> _$CctRangeToJson(_CctRange instance) => <String, dynamic>{
  'min': instance.min,
  'max': instance.max,
};

_Geometry _$GeometryFromJson(Map<String, dynamic> json) => _Geometry(
  type: $enumDecode(_$GeometryTypeEnumMap, json['type']),
  count: (json['count'] as num).toInt(),
  width: (json['width'] as num?)?.toInt(),
  spacingMm: (json['spacing_mm'] as num?)?.toDouble(),
  map: (json['map'] as List<dynamic>?)
      ?.map(
        (e) => (e as List<dynamic>).map((e) => (e as num).toDouble()).toList(),
      )
      .toList(),
);

Map<String, dynamic> _$GeometryToJson(_Geometry instance) => <String, dynamic>{
  'type': _$GeometryTypeEnumMap[instance.type]!,
  'count': instance.count,
  'width': instance.width,
  'spacing_mm': instance.spacingMm,
  'map': instance.map,
};

const _$GeometryTypeEnumMap = {
  GeometryType.strip: 'strip',
  GeometryType.matrix: 'matrix',
  GeometryType.custom: 'custom',
};

_StreamConfig _$StreamConfigFromJson(Map<String, dynamic> json) =>
    _StreamConfig(
      proto: $enumDecode(_$StreamProtoEnumMap, json['proto']),
      port: (json['port'] as num?)?.toInt() ?? 4048,
      maxFps: (json['maxFps'] as num?)?.toInt() ?? 60,
    );

Map<String, dynamic> _$StreamConfigToJson(_StreamConfig instance) =>
    <String, dynamic>{
      'proto': _$StreamProtoEnumMap[instance.proto]!,
      'port': instance.port,
      'maxFps': instance.maxFps,
    };

const _$StreamProtoEnumMap = {StreamProto.ddp: 'ddp'};

_DeviceDescriptor _$DeviceDescriptorFromJson(Map<String, dynamic> json) =>
    _DeviceDescriptor(
      schema: (json['schema'] as num).toInt(),
      id: json['id'] as String,
      name: json['name'] as String,
      model: json['model'] as String,
      fw: json['fw'] as String?,
      caps: (json['caps'] as List<dynamic>).map((e) => e as String).toList(),
      cct: json['cct'] == null
          ? null
          : CctRange.fromJson(json['cct'] as Map<String, dynamic>),
      geometry: json['geometry'] == null
          ? null
          : Geometry.fromJson(json['geometry'] as Map<String, dynamic>),
      stream: json['stream'] == null
          ? null
          : StreamConfig.fromJson(json['stream'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$DeviceDescriptorToJson(_DeviceDescriptor instance) =>
    <String, dynamic>{
      'schema': instance.schema,
      'id': instance.id,
      'name': instance.name,
      'model': instance.model,
      'fw': instance.fw,
      'caps': instance.caps,
      'cct': instance.cct,
      'geometry': instance.geometry,
      'stream': instance.stream,
    };
