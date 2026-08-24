import 'package:freezed_annotation/freezed_annotation.dart';

import 'segment.dart';

part 'device_state.freezed.dart';
part 'device_state.g.dart';

/// Full state of a device, as received over the WebSocket `state`/`patch`
/// frames or `GET /api/state` — see docs/02-protokol.md. Every field besides
/// [live] is only meaningful when the corresponding capability is present in
/// the device's [Capability] list; a CCT device simply never sends `col`.
@freezed
abstract class DeviceState with _$DeviceState {
  const factory DeviceState({
    bool? on,
    int? bri,
    int? tt,
    int? cct,
    List<int>? col,
    int? fx,
    int? sx,
    int? ix,
    int? pal,
    List<Segment>? seg,
    String? pattern,
    @Default(false) bool live,
  }) = _DeviceState;

  factory DeviceState.fromJson(Map<String, dynamic> json) =>
      _$DeviceStateFromJson(json);
}
