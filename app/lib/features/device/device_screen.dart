import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:led_core/led_core.dart';

import '../../providers/device_providers.dart';
import 'capability_registry.dart';

/// One class for every device type — the difference between a CCT strip and
/// a pixel strip is only which capabilities their descriptor lists, never a
/// branch in this widget. See docs/01-architektura.md's capability model and
/// mockups/index.html's implementation notes.
class DeviceScreen extends ConsumerWidget {
  const DeviceScreen({required this.deviceUri, super.key});

  final Uri deviceUri;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final descriptor = ref.watch(deviceDescriptorProvider(deviceUri)).value;
    final status = ref.watch(connectionStatusProvider(deviceUri)).value;

    return Scaffold(
      appBar: AppBar(title: Text(descriptor?.name ?? deviceUri.toString())),
      body: descriptor == null
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 12),
                  Text(_statusLabel(status)),
                ],
              ),
            )
          : ListView(
              padding: const EdgeInsets.symmetric(vertical: 16),
              children: [
                if (status != ConnectionStatus.connected)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: Text(
                      _statusLabel(status),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                for (final capability in capabilityOrder)
                  if (descriptor.hasCap(capability))
                    capabilityWidgets[capability]!(deviceUri),
              ],
            ),
    );
  }

  String _statusLabel(ConnectionStatus? status) => switch (status) {
    ConnectionStatus.connecting || null => 'Łączenie…',
    ConnectionStatus.connected => 'Połączono',
    ConnectionStatus.disconnected => 'Rozłączono — próbuję ponownie…',
  };
}
