import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:led_core/led_core.dart';

import '../../../providers/device_providers.dart';
import 'throttled_slider.dart';

/// The `brightness` capability (`bri`, 0–255) — docs/01-architektura.md.
class BrightnessSlider extends ConsumerWidget {
  const BrightnessSlider({required this.deviceUri, super.key});

  final Uri deviceUri;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bri = ref.watch(deviceStateProvider(deviceUri)).value?.bri ?? 0;
    final driver = ref.watch(driverProvider(deviceUri));

    return ThrottledSlider(
      label: 'Jasność',
      value: bri.toDouble(),
      min: 0,
      max: 255,
      valueLabel: (v) => '${(v / 255 * 100).round()}%',
      onChanged: (v) => driver.apply(StatePatch(bri: v.round())),
      onChangeEnd: (v) => driver.apply(StatePatch(bri: v.round()), force: true),
    );
  }
}
