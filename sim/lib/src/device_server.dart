import 'dart:convert';

import 'package:shelf/shelf.dart';
import 'package:shelf_web_socket/shelf_web_socket.dart';

import 'virtual_device.dart';

const _jsonHeaders = {'content-type': 'application/json'};

/// Wires [device] to the HTTP + WebSocket surface from
/// docs/02-protokol.md#http-api — the transport-facing half that
/// `virtual_device.dart` deliberately knows nothing about.
Handler buildDeviceHandler(VirtualDevice device) {
  final wsHandler = webSocketHandler(
    (channel, protocol) => device.handleConnection(channel),
  );

  return (Request request) async {
    if (request.url.path == 'ws') {
      return wsHandler(request);
    }

    switch ('${request.method} ${request.url.path}') {
      case 'GET api/device':
        return _json(device.descriptor.toJson());
      case 'GET api/state':
        return _json(device.state.toJson());
      case 'POST api/state':
        final body = await request.readAsString();
        final patch = body.isEmpty
            ? const <String, dynamic>{}
            : (jsonDecode(body) as Map).cast<String, dynamic>();
        device.applyPatch(patch);
        return _json(device.state.toJson());
      default:
        return Response.notFound(
          jsonEncode({'error': 'not_found'}),
          headers: _jsonHeaders,
        );
    }
  };
}

Response _json(Map<String, dynamic> body) =>
    Response.ok(jsonEncode(body), headers: _jsonHeaders);
