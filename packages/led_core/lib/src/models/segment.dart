import 'package:freezed_annotation/freezed_annotation.dart';

part 'segment.freezed.dart';
part 'segment.g.dart';

/// One entry of `DeviceState.seg` — an independently controlled slice of a
/// physical strip. `stop` is exclusive, matching schema/state.schema.json.
@freezed
abstract class Segment with _$Segment {
  const factory Segment({
    required int id,
    int? start,
    int? stop,
    bool? on,
    int? bri,
    List<int>? col,
    int? fx,
  }) = _Segment;

  factory Segment.fromJson(Map<String, dynamic> json) => _$SegmentFromJson(json);
}
