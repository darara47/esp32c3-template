import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:led_core/led_core.dart';

import '../features/discovery/mdns_discovery.dart';
import '../features/pairing/paired_tokens_provider.dart';

/// URLs of manually-added devices — the mandatory IP fallback from
/// docs/02-protokol.md#fallback--obowiązkowy, kept around alongside mDNS
/// discovery (not instead of it) for networks where mDNS doesn't reach.
/// Held in memory only; Drift persistence
/// (docs/03-aplikacja.md#persystencja-drift) lands with scenes in M3.
class ManualDevicesNotifier extends Notifier<List<Uri>> {
  @override
  List<Uri> build() => const [];

  void add(Uri uri) {
    if (state.contains(uri)) return;
    state = [...state, uri];
  }

  void remove(Uri uri) {
    state = state.where((u) => u != uri).toList(growable: false);
  }
}

final manualDevicesProvider = NotifierProvider<ManualDevicesNotifier, List<Uri>>(
  ManualDevicesNotifier.new,
);

/// Manually-added and mDNS-discovered URLs, merged and de-duplicated. This
/// is what the device list actually shows — see [manualDevicesProvider] and
/// [discoveredDevicesProvider] for where each half comes from.
final allDevicesProvider = Provider<List<Uri>>((ref) {
  final manual = ref.watch(manualDevicesProvider);
  final discovered = ref.watch(discoveredDevicesProvider).value ?? const [];
  return {...manual, ...discovered}.toList(growable: false);
});

/// One [NativeDriver] per device URL, connected as soon as it's first
/// watched and disposed when nothing references it anymore.
final driverProvider = Provider.family<DeviceDriver, Uri>((ref, uri) {
  final token = ref.watch(pairedTokensProvider.select((tokens) => tokens[uri.host]));
  final driver = NativeDriver(uri, token: token);
  driver.connect();
  ref.onDispose(driver.dispose);
  return driver;
});

final deviceDescriptorProvider = StreamProvider.family<DeviceDescriptor, Uri>((
  ref,
  uri,
) {
  return ref.watch(driverProvider(uri)).descriptorUpdates;
});

final deviceStateProvider = StreamProvider.family<DeviceState, Uri>((
  ref,
  uri,
) {
  return ref.watch(driverProvider(uri)).state;
});

final connectionStatusProvider = StreamProvider.family<ConnectionStatus, Uri>((
  ref,
  uri,
) {
  return ref.watch(driverProvider(uri)).status;
});
