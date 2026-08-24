import 'package:freezed_annotation/freezed_annotation.dart';

import 'state_patch.dart';

part 'preset.freezed.dart';
part 'preset.g.dart';

/// A named, saved [StatePatch] a user can re-apply in one tap — backed by
/// `GET/PUT/DELETE /api/presets/{id}` (docs/02-protokol.md). Distinct from a
/// scene: a preset lives on one device, a scene spans several.
@freezed
abstract class Preset with _$Preset {
  const factory Preset({
    required String id,
    required String name,
    required StatePatch state,
  }) = _Preset;

  factory Preset.fromJson(Map<String, dynamic> json) =>
      _$PresetFromJson(json);
}
