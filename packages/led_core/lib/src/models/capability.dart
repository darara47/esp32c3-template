/// Catalog of known device capabilities — see docs/01-architektura.md.
///
/// [DeviceDescriptor.caps] carries the raw wire strings, not this enum,
/// because the protocol requires unknown values to be ignored silently
/// (a device on newer firmware may report a `cap` this app has never heard
/// of). This enum exists only to give known capabilities a typed handle for
/// things like the widget registry and ordering.
enum Capability {
  power,
  brightness,
  cct,
  rgb,
  transition,
  segments,
  effects,
  stream,
  pattern;

  static Capability? tryParse(String wire) {
    for (final value in values) {
      if (value.name == wire) return value;
    }
    return null;
  }
}
