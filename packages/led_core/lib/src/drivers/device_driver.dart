import 'dart:async';

import '../models/device_descriptor.dart';
import '../models/device_state.dart';
import '../models/preset.dart';
import '../models/state_patch.dart';

enum ConnectionStatus { connecting, connected, disconnected }

/// One flat RGB byte buffer — `[R,G,B, R,G,B, ...]`, matching the DDP payload
/// layout in docs/02-protokol.md. Provisional: nothing sends real streams
/// yet, this just gives [DeviceDriver.frameSink] a concrete type until the
/// DDP sender and pattern renderer land (M4–M6).
typedef Frame = List<int>;

/// Uniform control surface for a device, independent of what protocol it
/// actually speaks underneath (`NativeDriver`, `WledDriver`, `MockDriver`).
/// See docs/03-aplikacja.md#abstrakcja-urządzenia.
///
/// Deviation from that doc's sketch: [descriptor] is nullable and there's a
/// [descriptorUpdates] stream, neither of which the sketch has. Reason: a
/// manually-added device (the mandatory IP fallback in
/// docs/02-protokol.md#fallback--obowiązkowy) starts out as nothing but a
/// URL — its capabilities aren't known until the `device` WebSocket frame
/// arrives after connecting. A non-nullable synchronous getter can't
/// represent "not known yet" for that case.
abstract class DeviceDriver {
  DeviceDescriptor? get descriptor;
  Stream<DeviceDescriptor> get descriptorUpdates;

  Stream<DeviceState> get state;
  Stream<ConnectionStatus> get status;

  /// Send a merge patch. UI sliders throttle calls during a drag and pass
  /// `force: true` on release so the final value is never dropped — see
  /// docs/03-aplikacja.md#throttling-suwaków.
  Future<void> apply(StatePatch patch, {bool force = false});

  Future<List<Preset>> presets();
  Future<void> savePreset(Preset preset);

  /// Null when the device does not report the `stream` capability.
  StreamSink<Frame>? get frameSink;

  Future<void> connect();
  Future<void> dispose();
}
