import 'package:led_core/led_core.dart';
import 'package:sim/src/virtual_device.dart';
import 'package:test/test.dart';

DeviceDescriptor _cctDescriptor() => const DeviceDescriptor(
  schema: 1,
  id: 'be:ef:00:00:00:01',
  name: 'Test CCT',
  model: 'ledctl-cct',
  caps: ['power', 'brightness', 'cct', 'transition'],
  cct: CctRange(min: 2700, max: 6500),
);

void main() {
  group('VirtualDevice.applyPatch', () {
    test('merges an allowed patch into state', () {
      final device = VirtualDevice(descriptor: _cctDescriptor());

      final accepted = device.applyPatch({'on': true, 'bri': 40, 'cct': 2700});

      expect(accepted, {'on': true, 'bri': 40, 'cct': 2700});
      expect(device.state.bri, 40);
      expect(device.state.cct, 2700);
    });

    test('rejects fields that need a capability this device lacks', () {
      final device = VirtualDevice(descriptor: _cctDescriptor());

      final accepted = device.applyPatch({'bri': 40, 'col': [255, 0, 0]});

      expect(accepted, {'bri': 40});
      expect(device.state.col, isNull);
    });

    test('always drops `live` — firmware-owned, never client-writable', () {
      final device = VirtualDevice(descriptor: _cctDescriptor());

      final accepted = device.applyPatch({'live': true, 'bri': 40});

      expect(accepted, {'bri': 40});
      expect(device.state.live, isFalse);
    });

    test('an empty patch leaves state untouched', () {
      final device = VirtualDevice(descriptor: _cctDescriptor());
      final before = device.state;

      final accepted = device.applyPatch(const {});

      expect(accepted, isEmpty);
      expect(device.state, before);
    });

    test('default state powers on at the midpoint of the cct range', () {
      final device = VirtualDevice(descriptor: _cctDescriptor());

      expect(device.state.on, isTrue);
      expect(device.state.cct, 4600); // (2700 + 6500) / 2
    });
  });
}
