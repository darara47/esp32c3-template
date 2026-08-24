import 'package:led_core/led_core.dart';
import 'package:test/test.dart';

void main() {
  group('Capability.tryParse', () {
    test('parses known wire values', () {
      expect(Capability.tryParse('power'), Capability.power);
      expect(Capability.tryParse('pattern'), Capability.pattern);
    });

    test('returns null for unknown wire values instead of throwing', () {
      expect(Capability.tryParse('teleport'), isNull);
    });
  });
}
