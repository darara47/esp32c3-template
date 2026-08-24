import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:led_core/led_core.dart';

import '../../providers/device_providers.dart';
import '../device/device_screen.dart';
import '../pairing/pairing_screen.dart';

enum _AddChoice { pairBle, manualIp }

/// Discovery is mDNS plus the mandatory IP fallback
/// (docs/03-aplikacja.md#discovery--przepływ, docs/02-protokol.md#fallback--obowiązkowy).
/// The IP-cache half of that design is still missing (no Drift yet — M3),
/// so a device found only by mDNS forgets it the moment the app restarts;
/// a manually-added one doesn't, since [manualDevicesProvider] holds it
/// directly.
class DeviceListScreen extends ConsumerWidget {
  const DeviceListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final devices = ref.watch(allDevicesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Światło')),
      body: devices.isEmpty
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Brak urządzeń. Powinny pojawić się same (mDNS) — jeśli sieć '
                  'tego nie lubi, dodaj ręcznie przez ➕, np. ws://192.168.1.42:8080/ws\n'
                  '(dart run sim --type=cct wypisuje gotowy adres po starcie)',
                  textAlign: TextAlign.center,
                ),
              ),
            )
          : ListView(
              children: [
                for (final uri in devices) _DeviceTile(deviceUri: uri),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddOptions(context, ref),
        tooltip: 'Dodaj urządzenie',
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<void> _showAddOptions(BuildContext context, WidgetRef ref) async {
    // The sheet returns a choice instead of acting directly from its own
    // `onTap` — that context is mid-pop by the time a follow-up
    // showDialog/push would run on it, which left the sheet's own content
    // (and the dialog it tried to open) stuck on screen. Acting afterward,
    // on the caller's still-mounted context, avoids that.
    final choice = await showModalBottomSheet<_AddChoice>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.bluetooth),
              title: const Text('Paruj nowe urządzenie'),
              subtitle: const Text('Pierwsze uruchomienie, przez Bluetooth'),
              onTap: () => Navigator.pop(context, _AddChoice.pairBle),
            ),
            ListTile(
              leading: const Icon(Icons.language),
              title: const Text('Dodaj po adresie IP'),
              subtitle: const Text('Urządzenie już w sieci (np. sim)'),
              onTap: () => Navigator.pop(context, _AddChoice.manualIp),
            ),
          ],
        ),
      ),
    );

    if (!context.mounted || choice == null) return;
    switch (choice) {
      case _AddChoice.pairBle:
        Navigator.of(context).push(MaterialPageRoute(builder: (_) => const PairingScreen()));
      case _AddChoice.manualIp:
        _addDevice(context, ref);
    }
  }

  Future<void> _addDevice(BuildContext context, WidgetRef ref) async {
    final controller = TextEditingController(text: 'ws://');
    final uri = await showDialog<Uri>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Dodaj urządzenie'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'ws://192.168.1.42:8080/ws'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Anuluj'),
          ),
          FilledButton(
            onPressed: () {
              final parsed = Uri.tryParse(controller.text.trim());
              Navigator.pop(context, parsed);
            },
            child: const Text('Dodaj'),
          ),
        ],
      ),
    );

    if (uri == null || uri.host.isEmpty) return;
    ref.read(manualDevicesProvider.notifier).add(uri);
  }
}

class _DeviceTile extends ConsumerWidget {
  const _DeviceTile({required this.deviceUri});

  final Uri deviceUri;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final descriptor = ref.watch(deviceDescriptorProvider(deviceUri)).value;
    final status = ref.watch(connectionStatusProvider(deviceUri)).value;
    final isManual = ref.watch(manualDevicesProvider).contains(deviceUri);

    return ListTile(
      leading: Icon(
        status == ConnectionStatus.connected ? Icons.lightbulb : Icons.lightbulb_outline,
      ),
      title: Text(descriptor?.name ?? deviceUri.toString()),
      subtitle: Text(descriptor == null ? 'Łączenie…' : descriptor.model),
      trailing: isManual
          ? IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: 'Usuń urządzenie',
              onPressed: () => _confirmRemove(context, ref),
            )
          : null,
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => DeviceScreen(deviceUri: deviceUri)),
      ),
    );
  }

  Future<void> _confirmRemove(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Usunąć urządzenie?'),
        content: Text(deviceUri.toString()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Anuluj'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Usuń'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      ref.read(manualDevicesProvider.notifier).remove(deviceUri);
    }
  }
}
