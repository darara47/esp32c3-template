// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'preset.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Preset _$PresetFromJson(Map<String, dynamic> json) => _Preset(
  id: json['id'] as String,
  name: json['name'] as String,
  state: StatePatch.fromJson(json['state'] as Map<String, dynamic>),
);

Map<String, dynamic> _$PresetToJson(_Preset instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'state': instance.state,
};
