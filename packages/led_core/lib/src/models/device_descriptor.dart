import 'package:freezed_annotation/freezed_annotation.dart';

import 'capability.dart';

part 'device_descriptor.freezed.dart';
part 'device_descriptor.g.dart';

/// Warmest/coldest color temperature in Kelvin, present when `caps` contains
/// `cct`.
@freezed
abstract class CctRange with _$CctRange {
  const factory CctRange({required int min, required int max}) = _CctRange;

  factory CctRange.fromJson(Map<String, dynamic> json) =>
      _$CctRangeFromJson(json);
}

enum GeometryType { strip, matrix, custom }

/// Physical layout of an addressable strip — the basis of the normalized
/// coordinate space that pattern generators sample. Present when `caps`
/// contains `rgb`. See docs/01-architektura.md#geometria-i-przestrzeń-znormalizowana.
@freezed
abstract class Geometry with _$Geometry {
  const factory Geometry({
    required GeometryType type,
    required int count,
    int? width,
    @JsonKey(name: 'spacing_mm') double? spacingMm,
    List<List<double>>? map,
  }) = _Geometry;

  factory Geometry.fromJson(Map<String, dynamic> json) =>
      _$GeometryFromJson(json);
}

enum StreamProto { ddp }

/// UDP/DDP streaming endpoint, present when `caps` contains `stream`.
@freezed
abstract class StreamConfig with _$StreamConfig {
  const factory StreamConfig({
    required StreamProto proto,
    @Default(4048) int port,
    @Default(60) int maxFps,
  }) = _StreamConfig;

  factory StreamConfig.fromJson(Map<String, dynamic> json) =>
      _$StreamConfigFromJson(json);
}

/// Describes what a device is and what it can do. Returned by
/// `GET /api/device` and as the first WebSocket frame after handshake — see
/// docs/02-protokol.md.
@freezed
abstract class DeviceDescriptor with _$DeviceDescriptor {
  const DeviceDescriptor._();

  const factory DeviceDescriptor({
    required int schema,
    required String id,
    required String name,
    required String model,
    String? fw,
    required List<String> caps,
    CctRange? cct,
    Geometry? geometry,
    StreamConfig? stream,
  }) = _DeviceDescriptor;

  factory DeviceDescriptor.fromJson(Map<String, dynamic> json) =>
      _$DeviceDescriptorFromJson(json);

  /// [caps] filtered to entries this app recognises, in enum declaration
  /// order. Unknown wire values are dropped here — once, in one place —
  /// so nothing downstream (widget registry included) has to special-case
  /// a capability it has never heard of.
  List<Capability> get capabilities => caps
      .map(Capability.tryParse)
      .whereType<Capability>()
      .toList(growable: false);

  bool hasCap(Capability capability) => capabilities.contains(capability);
}
