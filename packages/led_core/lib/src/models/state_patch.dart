import 'package:freezed_annotation/freezed_annotation.dart';

import 'segment.dart';

part 'state_patch.freezed.dart';
part 'state_patch.g.dart';

/// A JSON merge patch sent to a device — same shape as [DeviceState] minus
/// [DeviceState.live], which is firmware-owned and never client-writable.
/// `toJson` drops unset fields (`includeIfNull: false`) so only the fields a
/// caller actually touched are sent, per docs/02-protokol.md.
///
/// Known gap: the wire protocol lets `pattern: null` mean "clear the running
/// pattern", but `includeIfNull: false` can't distinguish that from "field
/// left unset". Not an issue while nothing constructs a pattern-clearing
/// patch; revisit when the pattern editor (M5) needs it.
@freezed
abstract class StatePatch with _$StatePatch {
  const factory StatePatch({
    @JsonKey(includeIfNull: false) bool? on,
    @JsonKey(includeIfNull: false) int? bri,
    @JsonKey(includeIfNull: false) int? tt,
    @JsonKey(includeIfNull: false) int? cct,
    @JsonKey(includeIfNull: false) List<int>? col,
    @JsonKey(includeIfNull: false) int? fx,
    @JsonKey(includeIfNull: false) int? sx,
    @JsonKey(includeIfNull: false) int? ix,
    @JsonKey(includeIfNull: false) int? pal,
    @JsonKey(includeIfNull: false) List<Segment>? seg,
    @JsonKey(includeIfNull: false) String? pattern,
  }) = _StatePatch;

  factory StatePatch.fromJson(Map<String, dynamic> json) =>
      _$StatePatchFromJson(json);
}
