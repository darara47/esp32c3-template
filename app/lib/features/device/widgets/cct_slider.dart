import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:led_core/led_core.dart';

import '../../../providers/device_providers.dart';
import 'throttled_slider.dart';

/// The `cct` capability (color temperature, Kelvin) — docs/01-architektura.md.
/// Range comes from the device's own descriptor (`cct.min`/`cct.max`), not a
/// hardcoded constant — different CCT hardware can have different ranges.
class CctSlider extends ConsumerWidget {
  const CctSlider({required this.deviceUri, super.key});

  final Uri deviceUri;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final range = ref.watch(deviceDescriptorProvider(deviceUri)).value?.cct;
    final cct = ref.watch(deviceStateProvider(deviceUri)).value?.cct;
    final driver = ref.watch(driverProvider(deviceUri));

    final min = (range?.min ?? 2700).toDouble();
    final max = (range?.max ?? 6500).toDouble();

    return ThrottledSlider(
      label: 'Temperatura barwowa',
      value: (cct ?? (min + max) / 2).toDouble(),
      min: min,
      max: max,
      valueLabel: (v) => '${v.round()} K',
      onChanged: (v) => driver.apply(StatePatch(cct: v.round())),
      onChangeEnd: (v) => driver.apply(StatePatch(cct: v.round()), force: true),
    );
  }
}
