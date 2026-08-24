import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:led_core/led_core.dart';
import 'package:test/test.dart';

DeviceDescriptor _cctDescriptor() => const DeviceDescriptor(
  schema: 1,
  id: 'be:ef:00:00:00:03',
  name: 'Fake CCT',
  model: 'ledctl-cct',
  caps: ['power', 'brightness', 'cct', 'transition'],
  cct: CctRange(min: 2700, max: 6500),
);

/// A tiny stand-in for `sim` (or real firmware): speaks just enough of
/// docs/02-protokol.md's WebSocket protocol for NativeDriver's tests —
/// device+state on connect, patch merge + broadcast, get, ping/pong.
class FakeDeviceServer {
  FakeDeviceServer._(this._httpServer, this.descriptor);

  final HttpServer _httpServer;
  final DeviceDescriptor descriptor;
  final _sockets = <WebSocket>[];
  DeviceState state = const DeviceState(on: true, bri: 128, cct: 4600);
  Completer<void> _clientConnected = Completer<void>();

  int get port => _httpServer.port;

  /// Completes once a client has finished the WS handshake server-side.
  /// Needed because the client's `channel.ready` resolves on its own
  /// schedule — seeing "connected" client-side is not proof this server has
  /// gotten around to registering the socket in [_sockets] yet.
  Future<void> waitForConnection() => _clientConnected.future;

  static Future<FakeDeviceServer> start(DeviceDescriptor descriptor) async {
    final httpServer = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    final fake = FakeDeviceServer._(httpServer, descriptor);
    httpServer.listen((request) async {
      if (WebSocketTransformer.isUpgradeRequest(request)) {
        fake._handleSocket(await WebSocketTransformer.upgrade(request));
      } else {
        request.response.statusCode = 404;
        await request.response.close();
      }
    });
    return fake;
  }

  void _handleSocket(WebSocket ws) {
    _sockets.add(ws);
    if (!_clientConnected.isCompleted) _clientConnected.complete();
    ws
      ..add(jsonEncode({'t': 'device', 'd': descriptor.toJson()}))
      ..add(jsonEncode({'t': 'state', 'd': state.toJson()}));

    ws.listen(
      (raw) {
        final frame = (jsonDecode(raw as String) as Map).cast<String, dynamic>();
        switch (frame['t']) {
          case 'patch':
            final patch = (frame['d'] as Map).cast<String, dynamic>();
            state = DeviceState.fromJson({...state.toJson(), ...patch});
            for (final socket in _sockets.toList()) {
              _trySend(socket, jsonEncode({'t': 'patch', 'd': patch}));
            }
          case 'get':
            _trySend(ws, jsonEncode({'t': 'state', 'd': state.toJson()}));
          case 'ping':
            _trySend(ws, jsonEncode({'t': 'pong'}));
        }
      },
      onDone: () => _sockets.remove(ws),
    );
  }

  void _trySend(WebSocket socket, String encoded) {
    try {
      socket.add(encoded);
    } catch (_) {
      _sockets.remove(socket);
    }
  }

  /// Drops every connected client without closing the HTTP listener — lets
  /// tests exercise NativeDriver's reconnect path against the same port.
  Future<void> dropConnections() async {
    for (final socket in _sockets.toList()) {
      await socket.close();
    }
    _sockets.clear();
    _clientConnected = Completer<void>();
  }

  Future<void> close() async {
    await dropConnections();
    await _httpServer.close(force: true);
  }
}

void main() {
  group('NativeDriver', () {
    late FakeDeviceServer server;

    setUp(() async {
      server = await FakeDeviceServer.start(_cctDescriptor());
    });

    tearDown(() async {
      await server.close();
    });

    test('connect() receives the descriptor and initial state', () async {
      final driver = NativeDriver(Uri.parse('ws://127.0.0.1:${server.port}/ws'));
      addTearDown(driver.dispose);

      final descriptor = driver.descriptorUpdates.first;
      final state = driver.state.first;
      await driver.connect();

      expect((await descriptor).id, 'be:ef:00:00:00:03');
      expect((await state).bri, 128);
      expect(driver.descriptor?.id, 'be:ef:00:00:00:03');
    });

    test(
      'a late subscriber to state/status/descriptor sees the current '
      'value immediately, not just future changes',
      () async {
        // This is the exact bug a live end-to-end run caught: a device
        // screen that starts watching only after its list tile already
        // connected the driver saw nothing, because the one-time `device`
        // and `state` frames had already come and gone into a broadcast
        // stream with no listener.
        final driver = NativeDriver(Uri.parse('ws://127.0.0.1:${server.port}/ws'));
        addTearDown(driver.dispose);

        await driver.connect();
        await driver.status.firstWhere((s) => s == ConnectionStatus.connected);
        // Give the initial `device`/`state` frames time to be processed —
        // nothing subscribed to descriptorUpdates/state up to this point.
        await Future<void>.delayed(const Duration(milliseconds: 100));

        expect((await driver.descriptorUpdates.first).id, 'be:ef:00:00:00:03');
        expect((await driver.state.first).bri, 128);
        expect(await driver.status.first, ConnectionStatus.connected);
      },
    );

    test('status goes connecting → connected', () async {
      final driver = NativeDriver(Uri.parse('ws://127.0.0.1:${server.port}/ws'));
      addTearDown(driver.dispose);

      final statuses = <ConnectionStatus>[];
      final sub = driver.status.listen(statuses.add);

      await driver.connect();
      await Future<void>.delayed(const Duration(milliseconds: 200));

      expect(statuses, [ConnectionStatus.connecting, ConnectionStatus.connected]);
      await sub.cancel();
    });

    test('apply() sends a patch that round-trips back through state', () async {
      final driver = NativeDriver(Uri.parse('ws://127.0.0.1:${server.port}/ws'));
      addTearDown(driver.dispose);
      await driver.connect();
      await driver.status.firstWhere((s) => s == ConnectionStatus.connected);

      final updated = driver.state.firstWhere((s) => s.bri == 77);
      await driver.apply(const StatePatch(bri: 77));

      expect((await updated).bri, 77);
      expect(server.state.bri, 77);
    });

    test('reconnects with backoff after the server drops the connection', () async {
      final driver = NativeDriver(Uri.parse('ws://127.0.0.1:${server.port}/ws'));
      addTearDown(driver.dispose);

      final statuses = <ConnectionStatus>[];
      final sub = driver.status.listen(statuses.add);

      await driver.connect();
      await driver.status.firstWhere((s) => s == ConnectionStatus.connected);
      await server.waitForConnection();

      await server.dropConnections();

      // First backoff step is ~0.5s ± 20% jitter; give it real headroom.
      await Future<void>.delayed(const Duration(seconds: 2));

      expect(statuses, containsAllInOrder([
        ConnectionStatus.connecting,
        ConnectionStatus.connected,
        ConnectionStatus.disconnected,
        ConnectionStatus.connecting,
      ]));
      await sub.cancel();
    });

    test('dispose() stops reconnect attempts and closes streams', () async {
      final driver = NativeDriver(Uri.parse('ws://127.0.0.1:${server.port}/ws'));
      await driver.connect();
      await driver.status.firstWhere((s) => s == ConnectionStatus.connected);
      // Let the initial state frame actually get processed before checking
      // what gets replayed post-dispose — connecting and receiving the
      // first message are two independent async chains with no ordering
      // guarantee between them.
      await Future<void>.delayed(const Duration(milliseconds: 100));

      await driver.dispose();

      // Replay-latest means a post-dispose listener still sees the last
      // known value before the stream reports done — see the "late
      // subscriber" test above for why that replay exists at all.
      expect(driver.state, emitsInOrder([anything, emitsDone]));
      expect(
        driver.status,
        emitsInOrder([ConnectionStatus.disconnected, emitsDone]),
      );
    });
  });
}
