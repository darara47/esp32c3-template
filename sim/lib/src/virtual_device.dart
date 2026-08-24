import 'dart:convert';

import 'package:led_core/led_core.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

/// Which capability a state-patch field requires, per the catalog in
/// docs/01-architektura.md. Fields absent from this map (`on`) are always
/// allowed — every device has `power`.
const _fieldCapability = <String, Capability>{
  'bri': Capability.brightness,
  'tt': Capability.transition,
  'cct': Capability.cct,
  'col': Capability.rgb,
  'fx': Capability.effects,
  'sx': Capability.effects,
  'ix': Capability.effects,
  'pal': Capability.effects,
  'seg': Capability.segments,
  'pattern': Capability.pattern,
};

/// In-process model of one simulated device: the state and WebSocket
/// fan-out described in docs/02-protokol.md. Deliberately has no HTTP or
/// socket-server plumbing of its own — that lives in `device_server.dart` —
/// so this half is trivial to unit test.
///
/// Simplification: unlike real firmware, this accepts any client without
/// checking `Authorization: Bearer <token>`. There's no BLE provisioning
/// flow to hand out a token to in a simulator; revisit if/when `sim` needs
/// to exercise the app's auth handling specifically.
class VirtualDevice {
  VirtualDevice({required this.descriptor, DeviceState? initialState})
    : state = initialState ?? _defaultState(descriptor);

  final DeviceDescriptor descriptor;
  DeviceState state;

  final _sockets = <WebSocketChannel>{};

  static DeviceState _defaultState(DeviceDescriptor descriptor) {
    final cct = descriptor.cct;
    return DeviceState(
      on: true,
      bri: 128,
      cct: cct == null ? null : ((cct.min + cct.max) / 2).round(),
    );
  }

  /// Registers a freshly-connected WebSocket: sends the descriptor then the
  /// full state (the order docs/02-protokol.md specifies), and wires up
  /// frame handling for the connection's lifetime.
  void handleConnection(WebSocketChannel channel) {
    _sockets.add(channel);
    _send(channel, {'t': 'device', 'd': descriptor.toJson()});
    _send(channel, {'t': 'state', 'd': state.toJson()});

    channel.stream.listen(
      (message) => _handleFrame(channel, message),
      onDone: () => _sockets.remove(channel),
      onError: (_) => _sockets.remove(channel),
    );
  }

  void _handleFrame(WebSocketChannel channel, Object? message) {
    if (message is! String) return;
    final Map<String, dynamic> frame;
    try {
      frame = (jsonDecode(message) as Map).cast<String, dynamic>();
    } on FormatException {
      return;
    }

    switch (frame['t']) {
      case 'patch':
        applyPatch(_asStringKeyedMap(frame['d']), respondErrorsTo: channel);
        final id = frame['id'];
        if (id != null) {
          _send(channel, {'t': 'ack', 'id': id});
        }
      case 'get':
        _send(channel, {'t': 'state', 'd': state.toJson()});
      case 'ping':
        _send(channel, {'t': 'pong'});
    }
  }

  /// Applies an incoming merge patch — from a WS `patch` frame or
  /// `POST /api/state`. Fields that need a capability this device doesn't
  /// have are rejected (with an `error` frame if [respondErrorsTo] is
  /// given); `live` is always dropped since it's firmware-owned and never
  /// client-writable. Whatever's left is merged into [state] and broadcast
  /// to every connected client. Returns the fields actually applied.
  Map<String, dynamic> applyPatch(
    Map<String, dynamic> patch, {
    WebSocketChannel? respondErrorsTo,
  }) {
    final accepted = <String, dynamic>{};
    patch.forEach((field, value) {
      if (field == 'live') return;
      final requiredCap = _fieldCapability[field];
      if (requiredCap != null && !descriptor.hasCap(requiredCap)) {
        if (respondErrorsTo != null) {
          _send(respondErrorsTo, {
            't': 'error',
            'd': {'code': 'unsupported_cap', 'msg': field},
          });
        }
        return;
      }
      accepted[field] = value;
    });

    if (accepted.isEmpty) return accepted;

    state = DeviceState.fromJson({...state.toJson(), ...accepted});
    _broadcast({'t': 'patch', 'd': accepted});
    return accepted;
  }

  void _broadcast(Map<String, dynamic> frame) {
    final encoded = jsonEncode(frame);
    // `onDone` removes a closed socket from `_sockets` asynchronously, so a
    // client that just disconnected can still be in this set for one more
    // broadcast. Without the try/catch, its dead sink throwing on `add`
    // would abort the loop and silently skip every client after it.
    for (final channel in _sockets.toList()) {
      _trySend(channel, encoded);
    }
  }

  void _send(WebSocketChannel channel, Map<String, dynamic> frame) {
    _trySend(channel, jsonEncode(frame));
  }

  void _trySend(WebSocketChannel channel, String encoded) {
    try {
      channel.sink.add(encoded);
    } catch (_) {
      _sockets.remove(channel);
    }
  }
}

Map<String, dynamic> _asStringKeyedMap(Object? value) {
  if (value is Map) return value.cast<String, dynamic>();
  return const {};
}
