import 'package:led_core/led_core.dart';
import 'package:test/test.dart';

void main() {
  group('DeviceState', () {
    test('parses the full state example from docs/02-protokol.md', () {
      final state = DeviceState.fromJson({
        'on': true,
        'bri': 128,
        'tt': 400,
        'cct': 3200,
        'col': [255, 120, 40],
        'fx': 12,
        'sx': 128,
        'ix': 200,
        'pal': 3,
        'seg': [
          {
            'id': 0,
            'start': 0,
            'stop': 72,
            'on': true,
            'bri': 255,
            'col': [255, 0, 0],
            'fx': 0,
          },
          {
            'id': 1,
            'start': 72,
            'stop': 144,
            'on': true,
            'bri': 180,
            'col': [0, 0, 255],
            'fx': 12,
          },
        ],
        'pattern': 'ember-slow',
        'live': false,
      });

      expect(state.on, isTrue);
      expect(state.col, [255, 120, 40]);
      expect(state.seg, hasLength(2));
      expect(state.seg![1].stop, 144);
      expect(state.pattern, 'ember-slow');
      expect(state.live, isFalse);
    });

    test('defaults live to false when the field is absent', () {
      final state = DeviceState.fromJson({'on': true, 'bri': 40, 'cct': 2700});
      expect(state.live, isFalse);
    });
  });
}
