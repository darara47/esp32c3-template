import 'package:led_core/led_core.dart';
import 'package:test/test.dart';

void main() {
  group('DeviceDescriptor', () {
    test('parses the cct example from docs/01-architektura.md', () {
      final descriptor = DeviceDescriptor.fromJson({
        'schema': 1,
        'id': 'a4:cf:12:00:11:22',
        'name': 'Salon – sufit',
        'model': 'ledctl-cct',
        'fw': '0.1.0',
        'caps': ['power', 'brightness', 'cct', 'transition'],
        'cct': {'min': 2700, 'max': 6500},
      });

      expect(descriptor.id, 'a4:cf:12:00:11:22');
      expect(descriptor.cct, const CctRange(min: 2700, max: 6500));
      expect(descriptor.hasCap(Capability.cct), isTrue);
      expect(descriptor.hasCap(Capability.rgb), isFalse);
      expect(descriptor.geometry, isNull);
    });

    test('parses the pixels example from docs/01-architektura.md', () {
      final descriptor = DeviceDescriptor.fromJson({
        'schema': 1,
        'id': 'a4:cf:12:00:33:44',
        'name': 'Biurko',
        'model': 'ledctl-pixels',
        'fw': '0.1.0',
        'caps': [
          'power',
          'brightness',
          'rgb',
          'segments',
          'effects',
          'stream',
          'pattern',
        ],
        'geometry': {
          'type': 'strip',
          'count': 144,
          'spacing_mm': 6.94,
          'map': null,
        },
        'stream': {'proto': 'ddp', 'port': 4048, 'maxFps': 60},
      });

      expect(descriptor.geometry, isNotNull);
      expect(descriptor.geometry!.type, GeometryType.strip);
      expect(descriptor.geometry!.count, 144);
      expect(descriptor.geometry!.spacingMm, 6.94);
      expect(descriptor.stream, const StreamConfig(proto: StreamProto.ddp));
      expect(descriptor.capabilities.length, 7);
    });

    test('silently drops unrecognised caps from .capabilities', () {
      final descriptor = DeviceDescriptor.fromJson({
        'schema': 7,
        'id': 'future-device',
        'name': 'From the future',
        'model': 'ledctl-matrix',
        'caps': ['power', 'holographic-projection'],
      });

      // The raw wire list is preserved untouched...
      expect(descriptor.caps, ['power', 'holographic-projection']);
      // ...but the typed view only exposes what this app understands.
      expect(descriptor.capabilities, [Capability.power]);
    });
  });
}
