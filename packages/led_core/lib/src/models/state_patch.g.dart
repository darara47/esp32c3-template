// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'state_patch.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_StatePatch _$StatePatchFromJson(Map<String, dynamic> json) => _StatePatch(
  on: json['on'] as bool?,
  bri: (json['bri'] as num?)?.toInt(),
  tt: (json['tt'] as num?)?.toInt(),
  cct: (json['cct'] as num?)?.toInt(),
  col: (json['col'] as List<dynamic>?)?.map((e) => (e as num).toInt()).toList(),
  fx: (json['fx'] as num?)?.toInt(),
  sx: (json['sx'] as num?)?.toInt(),
  ix: (json['ix'] as num?)?.toInt(),
  pal: (json['pal'] as num?)?.toInt(),
  seg: (json['seg'] as List<dynamic>?)
      ?.map((e) => Segment.fromJson(e as Map<String, dynamic>))
      .toList(),
  pattern: json['pattern'] as String?,
);

Map<String, dynamic> _$StatePatchToJson(_StatePatch instance) =>
    <String, dynamic>{
      'on': ?instance.on,
      'bri': ?instance.bri,
      'tt': ?instance.tt,
      'cct': ?instance.cct,
      'col': ?instance.col,
      'fx': ?instance.fx,
      'sx': ?instance.sx,
      'ix': ?instance.ix,
      'pal': ?instance.pal,
      'seg': ?instance.seg,
      'pattern': ?instance.pattern,
    };
