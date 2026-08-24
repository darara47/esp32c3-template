import 'package:led_core/led_core.dart';
import 'package:test/test.dart';

DeviceDescriptor _cctDescriptor() => DeviceDescriptor.fromJson({
  'schema': 1,
  'id': 'a4:cf:12:00:11:22',
  'name': 'Salon – sufit',
  'model': 'ledctl-cct',
  'caps': ['power', 'brightness', 'cct', 'transition'],
  'cct': {'min': 2700, 'max': 6500},
});

void main() {
  group('MockDriver', () {
    test('exposes the descriptor it was built with', () {
      final driver = MockDriver(descriptor: _cctDescriptor());
      expect(driver.descriptor.id, 'a4:cf:12:00:11:22');
    });

    test('connect() reports connecting then connected', () async {
      final driver = MockDriver(descriptor: _cctDescriptor());
      final statuses = <ConnectionStatus>[];
      // Subscribing replays the current status first — `disconnected`,
      // since connect() hasn't run yet — before any future change.
      final sub = driver.status.listen(statuses.add);

      await driver.connect();
      await Future<void>.delayed(Duration.zero);

      expect(statuses, [
        ConnectionStatus.disconnected,
        ConnectionStatus.connecting,
        ConnectionStatus.connected,
      ]);
      await sub.cancel();
      await driver.dispose();
    });

    test('apply() merges the patch into state and emits it', () async {
      final driver = MockDriver(descriptor: _cctDescriptor());
      final states = <DeviceState>[];
      // Subscribing replays the current (default) state first, then each
      // apply()'s result.
      final sub = driver.state.listen(states.add);

      await driver.apply(const StatePatch(on: true, bri: 40, cct: 2700));
      await driver.apply(const StatePatch(bri: 80));
      await Future<void>.delayed(Duration.zero);

      expect(driver.currentState.on, isTrue);
      expect(driver.currentState.cct, 2700);
      expect(driver.currentState.bri, 80);
      expect(states, hasLength(3));
      expect(states.last.bri, 80);
      await sub.cancel();
      await driver.dispose();
    });

    test('apply(force: true) is accepted and still merges', () async {
      final driver = MockDriver(descriptor: _cctDescriptor());

      await driver.apply(const StatePatch(bri: 200), force: true);

      expect(driver.currentState.bri, 200);
      await driver.dispose();
    });

    test('savePreset() then presets() round-trips', () async {
      final driver = MockDriver(descriptor: _cctDescriptor());
      const preset = Preset(
        id: 'evening',
        name: 'Wieczór',
        state: StatePatch(cct: 2700, bri: 40),
      );

      await driver.savePreset(preset);

      expect(await driver.presets(), [preset]);
      await driver.dispose();
    });

    test('frameSink is null — this device does not report `stream`', () {
      final driver = MockDriver(descriptor: _cctDescriptor());
      expect(driver.frameSink, isNull);
    });

    test('dispose() closes the state and status streams', () async {
      final driver = MockDriver(descriptor: _cctDescriptor());

      await driver.dispose();

      // Replay-latest means a post-dispose listener still sees the last
      // known value before the stream reports done — see the "late
      // subscriber" tests below for why that replay exists at all.
      expect(driver.state, emitsInOrder([const DeviceState(), emitsDone]));
      expect(
        driver.status,
        emitsInOrder([ConnectionStatus.disconnected, emitsDone]),
      );
    });

    test('a late subscriber to state sees the current value immediately', () async {
      final driver = MockDriver(descriptor: _cctDescriptor());
      await driver.apply(const StatePatch(bri: 99));

      // No listener existed before this apply() — this is exactly the
      // "opened the device screen after the list tile already connected"
      // scenario that motivated replayLatest.
      final first = await driver.state.first;

      expect(first.bri, 99);
      await driver.dispose();
    });

    test('a late subscriber to status sees "connected" immediately', () async {
      final driver = MockDriver(descriptor: _cctDescriptor());
      await driver.connect();

      final first = await driver.status.first;

      expect(first, ConnectionStatus.connected);
      await driver.dispose();
    });
  });
}
