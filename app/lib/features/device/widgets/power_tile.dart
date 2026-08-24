import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:led_core/led_core.dart';

import '../../../providers/device_providers.dart';

/// The `power` capability — see docs/01-architektura.md's capability catalog.
class PowerTile extends ConsumerWidget {
  const PowerTile({required this.deviceUri, super.key});

  final Uri deviceUri;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final on = ref.watch(deviceStateProvider(deviceUri)).value?.on ?? false;
    final driver = ref.watch(driverProvider(deviceUri));

    return SwitchListTile(
      title: const Text('Zasilanie'),
      value: on,
      // A toggle is a discrete action, not a drag — always send it in full,
      // immediately. See docs/03-aplikacja.md#throttling-suwaków for why
      // sliders behave differently.
      onChanged: (value) => driver.apply(StatePatch(on: value), force: true),
    );
  }
}
