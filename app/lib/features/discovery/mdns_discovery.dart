import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nsd/nsd.dart';

/// `_ledctl._tcp` — the service type native ledctl firmware and `sim`
/// announce, per docs/02-protokol.md#mdns. `_wled._tcp` isn't scanned for
/// yet — there's no `WledDriver` to hand a match to until M2.
const _serviceType = '_ledctl._tcp';

/// Live set of `ws://` URLs discovered via mDNS. Starts a discovery on first
/// watch and stops it when nothing's watching any more — mirrors
/// docs/03-aplikacja.md#discovery--przepływ, minus the IP-cache half (no
/// Drift yet; that's M3, and manual add already covers the fallback).
final discoveredDevicesProvider = StreamProvider<List<Uri>>((ref) {
  final controller = StreamController<List<Uri>>();
  // Keyed by service name (the mDNS instance name), not by URI: a device
  // can flap its IP without changing its name, and re-resolving the same
  // name should replace the old entry rather than duplicate it.
  final devicesByName = <String, Uri>{};
  Discovery? discovery;

  void publish() => controller.add(devicesByName.values.toList(growable: false));

  void handle(Service service, ServiceStatus status) {
    final name = service.name;
    if (name == null) return;

    if (status == ServiceStatus.lost) {
      devicesByName.remove(name);
      publish();
      return;
    }

    final uri = _toWsUri(service);
    if (uri == null) return; // not resolved enough to connect to yet
    devicesByName[name] = uri;
    publish();
  }

  () async {
    try {
      discovery = await startDiscovery(_serviceType, ipLookupType: IpLookupType.v4);
    } catch (_) {
      // No mDNS on this platform, no permission granted, plugin not
      // registered (e.g. a widget test with no platform channel handler) —
      // whatever the cause, manual add is still there as a fallback, so
      // this degrades to "found nothing" rather than crashing the screen.
      return;
    }
    discovery!.addServiceListener(handle);
    for (final service in discovery!.services) {
      handle(service, ServiceStatus.found);
    }
  }();

  ref.onDispose(() {
    controller.close();
    final current = discovery;
    if (current != null) {
      discovery = null;
      stopDiscovery(current);
    }
  });

  return controller.stream;
});

Uri? _toWsUri(Service service) {
  final port = service.port;
  if (port == null) return null;

  final addresses = service.addresses;
  final host = (addresses != null && addresses.isNotEmpty)
      ? addresses.first.address
      : service.host;
  if (host == null) return null;

  return Uri(scheme: 'ws', host: host, port: port, path: '/ws');
}
