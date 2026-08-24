import 'package:led_core/led_core.dart';

void main() {
  final descriptor = DeviceDescriptor.fromJson({
    'schema': 1,
    'id': 'a4:cf:12:00:11:22',
    'name': 'Salon – sufit',
    'model': 'ledctl-cct',
    'fw': '0.1.0',
    'caps': ['power', 'brightness', 'cct', 'transition'],
    'cct': {'min': 2700, 'max': 6500},
  });

  print('${descriptor.name}: ${descriptor.capabilities}');

  final patch = StatePatch(bri: 200, tt: 400);
  print(patch.toJson());
}
