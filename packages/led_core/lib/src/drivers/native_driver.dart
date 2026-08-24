import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:web_socket_channel/web_socket_channel.dart';

import '../models/device_descriptor.dart';
import '../models/device_state.dart';
import '../models/preset.dart';
import '../models/state_patch.dart';
import 'device_driver.dart';
import 'replay_latest.dart';

const _heartbeatInterval = Duration(seconds: 15);
const _heartbeatTimeout = Duration(seconds: 45);
const _maxBackoff = Duration(seconds: 30);

/// Talks the native ledctl protocol (docs/02-protokol.md) to a real device —
/// physical firmware or `sim`. Handles reconnect with the documented
/// exponential backoff (0.5s doubling to a 30s ceiling, ±20% jitter) and the
/// ping/pong heartbeat (15s interval, 45s timeout) itself; callers just see
/// [status] flip and [state]/[descriptorUpdates] pick back up once a
/// reconnect succeeds.
class NativeDriver implements DeviceDriver {
  NativeDriver(this.uri, {this.token, Random? random})
    : _random = random ?? Random();

  final Uri uri;

  /// Bearer token from BLE provisioning, if this device requires one.
  final String? token;
  final Random _random;

  WebSocketChannel? _channel;
  StreamSubscription<Object?>? _subscription;
  Timer? _reconnectTimer;
  Timer? _heartbeatTimer;
  DateTime? _lastPong;
  int _reconnectAttempt = 0;
  bool _disposed = true;

  DeviceDescriptor? _descriptor;
  DeviceState? _state;
  ConnectionStatus? _status;

  final _descriptorController = StreamController<DeviceDescriptor>.broadcast();
  final _stateController = StreamController<DeviceState>.broadcast();
  final _statusController = StreamController<ConnectionStatus>.broadcast();

  @override
  DeviceDescriptor? get descriptor => _descriptor;

  // A late subscriber — e.g. a device screen opened after its list tile
  // already connected — must see the current value immediately, not wait
  // for the next change. See replay_latest.dart.
  @override
  Stream<DeviceDescriptor> get descriptorUpdates =>
      replayLatest(() => _descriptor, _descriptorController.stream);

  @override
  Stream<DeviceState> get state =>
      replayLatest(() => _state, _stateController.stream);

  @override
  Stream<ConnectionStatus> get status =>
      replayLatest(() => _status, _statusController.stream);

  // DDP streaming lands with the pattern renderer (M4–M6); nothing sends
  // frames yet.
  @override
  StreamSink<Frame>? get frameSink => null;

  @override
  Future<void> connect() async {
    if (!_disposed) return; // already connecting/connected
    _disposed = false;
    _reconnectAttempt = 0;
    _openSocket();
  }

  void _setStatus(ConnectionStatus status) {
    _status = status;
    _statusController.add(status);
  }

  void _openSocket() {
    if (_disposed) return;
    _setStatus(ConnectionStatus.connecting);

    // Browsers can't set custom headers on a WebSocket handshake, so the
    // token travels as a query param instead — the fallback docs/02-protokol.md
    // explicitly allows for clients that can't set the Authorization header.
    final connectUri = token == null
        ? uri
        : uri.replace(
            queryParameters: {...uri.queryParameters, 'token': token},
          );

    final WebSocketChannel channel;
    try {
      channel = WebSocketChannel.connect(connectUri);
    } catch (_) {
      _scheduleReconnect();
      return;
    }
    _channel = channel;
    _subscription = channel.stream.listen(
      _handleFrame,
      onDone: _handleDisconnect,
      onError: (Object _) => _handleDisconnect(),
      cancelOnError: true,
    );

    channel.ready
        .then((_) {
          if (_disposed || _channel != channel) return;
          _reconnectAttempt = 0;
          _setStatus(ConnectionStatus.connected);
          _startHeartbeat();
          // Resync explicitly rather than trusting local state is current —
          // docs/02-protokol.md#reconnect calls this out even for the first
          // connect, since the server already pushes state unprompted but a
          // resync request is idempotent and cheap.
          _sendFrame({'t': 'get'});
        })
        .catchError((Object _) => _handleDisconnect());
  }

  void _handleFrame(Object? message) {
    if (message is! String) return;
    final Map<String, dynamic> frame;
    try {
      frame = (jsonDecode(message) as Map).cast<String, dynamic>();
    } on FormatException {
      return;
    }

    switch (frame['t']) {
      case 'device':
        _descriptor = DeviceDescriptor.fromJson(_asMap(frame['d']));
        _descriptorController.add(_descriptor!);
      case 'state':
        _state = DeviceState.fromJson(_asMap(frame['d']));
        _stateController.add(_state!);
      case 'patch':
        final base = _state ?? const DeviceState();
        _state = DeviceState.fromJson({...base.toJson(), ..._asMap(frame['d'])});
        _stateController.add(_state!);
      case 'pong':
        _lastPong = DateTime.now();
      // 'error' and 'ack' frames have no listener yet — nothing in M0 saves
      // presets or sends capability-gated patches that would trigger one.
    }
  }

  void _handleDisconnect() {
    if (_disposed || _channel == null) return;
    _subscription?.cancel();
    _subscription = null;
    _channel = null;
    _stopHeartbeat();
    _setStatus(ConnectionStatus.disconnected);
    _scheduleReconnect();
  }

  void _scheduleReconnect() {
    if (_disposed) return;
    final base = Duration(
      milliseconds: (500 * pow(2, _reconnectAttempt)).clamp(0, _maxBackoff.inMilliseconds).toInt(),
    );
    _reconnectAttempt++;
    final jitterFactor = 1 + (_random.nextDouble() * 0.4 - 0.2); // ±20%
    final delay = Duration(
      milliseconds: (base.inMilliseconds * jitterFactor).round(),
    );
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(delay, _openSocket);
  }

  void _startHeartbeat() {
    _lastPong = DateTime.now();
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(_heartbeatInterval, (_) {
      final lastPong = _lastPong;
      if (lastPong != null &&
          DateTime.now().difference(lastPong) > _heartbeatTimeout) {
        _handleDisconnect();
        return;
      }
      _sendFrame({'t': 'ping'});
    });
  }

  void _stopHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
  }

  void _sendFrame(Map<String, dynamic> frame) {
    _channel?.sink.add(jsonEncode(frame));
  }

  @override
  Future<void> apply(StatePatch patch, {bool force = false}) async {
    // No `id` — per docs/02-protokol.md, that's reserved for operations that
    // must land (like a preset save); sliders skip it deliberately.
    _sendFrame({'t': 'patch', 'd': patch.toJson()});
  }

  @override
  Future<List<Preset>> presets() async {
    final client = HttpClient();
    try {
      final request = await client.getUrl(_httpUri('/api/presets'));
      _applyAuth(request);
      final response = await request.close();
      if (response.statusCode != 200) return const [];
      final body = await response.transform(utf8.decoder).join();
      return (jsonDecode(body) as List)
          .map((entry) => Preset.fromJson(_asMap(entry)))
          .toList();
    } finally {
      client.close();
    }
  }

  @override
  Future<void> savePreset(Preset preset) async {
    final client = HttpClient();
    try {
      final request = await client.putUrl(_httpUri('/api/presets/${preset.id}'));
      _applyAuth(request);
      request.headers.contentType = ContentType.json;
      request.write(jsonEncode(preset.toJson()));
      await request.close();
    } finally {
      client.close();
    }
  }

  Uri _httpUri(String path) =>
      Uri(scheme: 'http', host: uri.host, port: uri.port, path: path);

  void _applyAuth(HttpClientRequest request) {
    if (token != null) {
      request.headers.set(HttpHeaders.authorizationHeader, 'Bearer $token');
    }
  }

  @override
  Future<void> dispose() async {
    _disposed = true;
    _reconnectTimer?.cancel();
    _stopHeartbeat();
    await _subscription?.cancel();
    await _channel?.sink.close();
    _status = ConnectionStatus.disconnected;
    await _descriptorController.close();
    await _stateController.close();
    await _statusController.close();
  }
}

Map<String, dynamic> _asMap(Object? value) {
  if (value is Map) return value.cast<String, dynamic>();
  return const {};
}
