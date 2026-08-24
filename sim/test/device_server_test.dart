import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:led_core/led_core.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:sim/src/device_server.dart';
import 'package:sim/src/virtual_device.dart';
import 'package:test/test.dart';

DeviceDescriptor _cctDescriptor() => const DeviceDescriptor(
  schema: 1,
  id: 'be:ef:00:00:00:02',
  name: 'Test CCT',
  model: 'ledctl-cct',
  caps: ['power', 'brightness', 'cct', 'transition'],
  cct: CctRange(min: 2700, max: 6500),
);

void main() {
  group('device_server (HTTP + WebSocket, real sockets)', () {
    late VirtualDevice device;
    late HttpServer server;
    late String baseUrl;
    late String wsUrl;

    setUp(() async {
      device = VirtualDevice(descriptor: _cctDescriptor());
      server = await shelf_io.serve(
        buildDeviceHandler(device),
        InternetAddress.loopbackIPv4,
        0,
      );
      baseUrl = 'http://${server.address.address}:${server.port}';
      wsUrl = 'ws://${server.address.address}:${server.port}/ws';
    });

    tearDown(() async {
      await server.close(force: true);
    });

    test('GET /api/device returns the descriptor', () async {
      final response = await HttpClient()
          .getUrl(Uri.parse('$baseUrl/api/device'))
          .then((r) => r.close());
      final body = jsonDecode(await response.transform(utf8.decoder).join());

      expect(body['id'], 'be:ef:00:00:00:02');
      expect(body['caps'], contains('cct'));
    });

    test('POST /api/state merges a patch and returns the new state', () async {
      final request = await HttpClient().postUrl(Uri.parse('$baseUrl/api/state'));
      request.headers.contentType = ContentType.json;
      request.write(jsonEncode({'bri': 77}));
      final response = await request.close();
      final body = jsonDecode(await response.transform(utf8.decoder).join());

      expect(body['bri'], 77);
      expect(device.state.bri, 77);
    });

    test(
      'WebSocket: connect sends device then state; patch broadcasts and acks',
      () async {
        final socket = await WebSocket.connect(wsUrl);
        final frames = socket.map((raw) => jsonDecode(raw as String) as Map);
        final it = StreamIterator(frames);

        await it.moveNext();
        expect(it.current['t'], 'device');

        await it.moveNext();
        expect(it.current['t'], 'state');

        socket.add(
          jsonEncode({'t': 'patch', 'id': 1, 'd': {'bri': 55}}),
        );

        // Order isn't guaranteed between the ack and the broadcast, so
        // collect both frames before asserting on them.
        await it.moveNext();
        final first = it.current;
        await it.moveNext();
        final second = it.current;
        final byType = {first['t']: first, second['t']: second};

        expect(byType['ack']!['id'], 1);
        expect(byType['patch']!['d'], {'bri': 55});

        await socket.close();
      },
    );

    test('WebSocket: patching an unsupported field returns an error frame', () async {
      final socket = await WebSocket.connect(wsUrl);
      final frames = socket.map((raw) => jsonDecode(raw as String) as Map);
      final it = StreamIterator(frames);

      await it.moveNext(); // device
      await it.moveNext(); // state

      socket.add(
        jsonEncode({
          't': 'patch',
          'd': {
            'col': [255, 0, 0],
          },
        }),
      );

      await it.moveNext();
      expect(it.current['t'], 'error');
      expect(it.current['d']['code'], 'unsupported_cap');
      expect(it.current['d']['msg'], 'col');

      await socket.close();
    });

    test('WebSocket: get and ping', () async {
      final socket = await WebSocket.connect(wsUrl);
      final frames = socket.map((raw) => jsonDecode(raw as String) as Map);
      final it = StreamIterator(frames);

      await it.moveNext(); // device
      await it.moveNext(); // state

      socket.add(jsonEncode({'t': 'ping'}));
      await it.moveNext();
      expect(it.current['t'], 'pong');

      socket.add(jsonEncode({'t': 'get'}));
      await it.moveNext();
      expect(it.current['t'], 'state');

      await socket.close();
    });
  });
}
