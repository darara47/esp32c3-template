import 'package:flutter/widgets.dart';
import 'package:led_core/led_core.dart';

import 'widgets/brightness_slider.dart';
import 'widgets/cct_slider.dart';
import 'widgets/power_tile.dart';

/// Maps a capability to the widget that renders it — the mechanism behind
/// "the device describes itself, the app composes UI dynamically"
/// (docs/01-architektura.md). Adding a widget for a new capability never
/// touches [DeviceScreen]; a capability with no entry here is simply not
/// rendered, same as an unrecognised one — see [Capability.tryParse].
final capabilityWidgets = <Capability, Widget Function(Uri deviceUri)>{
  Capability.power: (uri) => PowerTile(deviceUri: uri),
  Capability.brightness: (uri) => BrightnessSlider(deviceUri: uri),
  Capability.cct: (uri) => CctSlider(deviceUri: uri),
};

/// Explicit render order — never the order capabilities happen to appear in
/// a device's descriptor, which firmware is free to change between versions
/// (docs/03-aplikacja.md#rejestr-widgetów).
const capabilityOrder = [Capability.power, Capability.brightness, Capability.cct];
