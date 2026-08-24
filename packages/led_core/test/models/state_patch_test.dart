import 'package:led_core/led_core.dart';
import 'package:test/test.dart';

void main() {
  group('StatePatch', () {
    test('toJson only includes fields that were actually set', () {
      const patch = StatePatch(bri: 200, tt: 400);

      expect(patch.toJson(), {'bri': 200, 'tt': 400});
    });

    test('an empty patch serializes to an empty object', () {
      expect(const StatePatch().toJson(), <String, dynamic>{});
    });

    test('round-trips through JSON', () {
      const patch = StatePatch(cct: 2700, on: true);

      expect(StatePatch.fromJson(patch.toJson()), patch);
    });
  });
}
