import 'dart:async';

import '../models/device_descriptor.dart';
import '../models/device_state.dart';
import '../models/preset.dart';
import '../models/state_patch.dart';
import 'device_driver.dart';
import 'replay_latest.dart';

/// In-memory [DeviceDriver] with no network I/O — for unit tests and golden
/// tests (docs/07-roadmapa.md, M0). A patch is merged into the current state
/// and re-emitted synchronously; there is nothing resembling a round trip to
/// simulate, so `force` is accepted for interface compliance but has no
/// observable effect here.
class MockDriver implements DeviceDriver {
  MockDriver({required this.descriptor, DeviceState? initialState})
    : _state = initialState ?? const DeviceState();

  @override
  final DeviceDescriptor descriptor;

  DeviceState _state;
  ConnectionStatus _status = ConnectionStatus.disconnected;
  final _stateController = StreamController<DeviceState>.broadcast();
  final _statusController = StreamController<ConnectionStatus>.broadcast();
  final _presets = <String, Preset>{};

  /// The current merged state, for assertions that don't want to await a
  /// stream event.
  DeviceState get currentState => _state;

  // MockDriver is always constructed with a full descriptor and it never
  // changes, so unlike NativeDriver there's no "not known yet" period to
  // model — just replay the one value new listeners would otherwise miss.
  @override
  Stream<DeviceDescriptor> get descriptorUpdates => Stream.value(descriptor);

  // A late subscriber (e.g. a device screen opened after its list tile
  // already called connect()) must see the current value immediately —
  // see replay_latest.dart.
  @override
  Stream<DeviceState> get state =>
      replayLatest(() => _state, _stateController.stream);

  @override
  Stream<ConnectionStatus> get status =>
      replayLatest(() => _status, _statusController.stream);

  void _setStatus(ConnectionStatus status) {
    _status = status;
    _statusController.add(status);
  }

  @override
  Future<void> apply(StatePatch patch, {bool force = false}) async {
    final merged = {..._state.toJson(), ...patch.toJson()};
    _state = DeviceState.fromJson(merged);
    _stateController.add(_state);
  }

  @override
  Future<List<Preset>> presets() async =>
      _presets.values.toList(growable: false);

  @override
  Future<void> savePreset(Preset preset) async {
    _presets[preset.id] = preset;
  }

  @override
  StreamSink<Frame>? get frameSink => null;

  @override
  Future<void> connect() async {
    _setStatus(ConnectionStatus.connecting);
    _setStatus(ConnectionStatus.connected);
    _stateController.add(_state);
  }

  @override
  Future<void> dispose() async {
    _setStatus(ConnectionStatus.disconnected);
    await _stateController.close();
    await _statusController.close();
  }
}
