// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'segment.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Segment _$SegmentFromJson(Map<String, dynamic> json) => _Segment(
  id: (json['id'] as num).toInt(),
  start: (json['start'] as num?)?.toInt(),
  stop: (json['stop'] as num?)?.toInt(),
  on: json['on'] as bool?,
  bri: (json['bri'] as num?)?.toInt(),
  col: (json['col'] as List<dynamic>?)?.map((e) => (e as num).toInt()).toList(),
  fx: (json['fx'] as num?)?.toInt(),
);

Map<String, dynamic> _$SegmentToJson(_Segment instance) => <String, dynamic>{
  'id': instance.id,
  'start': instance.start,
  'stop': instance.stop,
  'on': instance.on,
  'bri': instance.bri,
  'col': instance.col,
  'fx': instance.fx,
};
