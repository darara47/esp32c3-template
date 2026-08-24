import 'dart:io';

/// Best-effort LAN IPv4 address to advertise — the one other devices on the
/// network can actually dial, as opposed to the `0.0.0.0` the HTTP server
/// itself binds to. Falls back to loopback if nothing else turns up (e.g. no
/// network connection at all), which at least keeps `sim` usable locally.
Future<InternetAddress> primaryLocalAddress() async {
  final interfaces = await NetworkInterface.list(
    type: InternetAddressType.IPv4,
    includeLoopback: false,
    includeLinkLocal: false,
  );
  for (final interface in interfaces) {
    for (final address in interface.addresses) {
      if (!address.isLoopback) return address;
    }
  }
  return InternetAddress.loopbackIPv4;
}
