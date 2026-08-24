// Diagnostic tool, not part of the app: sends a raw mDNS PTR query for
// `_ledctl._tcp.local` and prints whatever comes back for a few seconds.
// Isolates "does sim's responder actually answer on this network" from
// "does the nsd/Windows discovery client work at all" — run this while
// `sim` is running, independent of the Flutter app.
//
// Usage: dart run tool/mdns_probe.dart
import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:sim/src/dns/dns_message.dart';
import 'package:sim/src/dns/mdns_responder.dart';

Uint8List _buildQuery(String fqdn) {
  final header = ByteData(12);
  header.setUint16(4, 1); // QDCOUNT = 1
  final name = encodeName(fqdn);
  final trailer = ByteData(4);
  trailer.setUint16(0, dnsRecordTypePtr);
  trailer.setUint16(2, 1); // QCLASS IN
  return Uint8List.fromList([
    ...header.buffer.asUint8List(),
    ...name,
    ...trailer.buffer.asUint8List(),
  ]);
}

void _dumpResponse(Uint8List data, InternetAddress from) {
  print('--- response from ${from.address} (${data.length} bytes) ---');
  if (data.length < 12) {
    print('  too short to be a DNS packet');
    return;
  }
  final header = ByteData.sublistView(data);
  final ancount = header.getUint16(6);
  print('  ANCOUNT=$ancount flags=0x${header.getUint16(2).toRadixString(16)}');

  var offset = 12;
  // Skip any questions (shouldn't be any in a well-formed response, but
  // don't choke if there are).
  final qdcount = header.getUint16(4);
  for (var i = 0; i < qdcount; i++) {
    final name = decodeName(data, offset);
    offset = name.nextOffset + 4;
  }

  for (var i = 0; i < ancount; i++) {
    if (offset >= data.length) break;
    final name = decodeName(data, offset);
    offset = name.nextOffset;
    if (offset + 10 > data.length) break;
    final type = header.getUint16(offset);
    final ttl = header.getUint32(offset + 4);
    final rdlength = header.getUint16(offset + 8);
    offset += 10;
    final typeName = switch (type) {
      dnsRecordTypePtr => 'PTR',
      dnsRecordTypeSrv => 'SRV',
      dnsRecordTypeTxt => 'TXT',
      dnsRecordTypeA => 'A',
      _ => 'type $type',
    };
    print('  $typeName  name=${name.name}  ttl=$ttl  rdlength=$rdlength');
    offset += rdlength;
  }
}

Future<void> main() async {
  // mDNS replies go out multicast to port 5353, same as the query — a
  // client has to bind *that* port to receive them, same as the responder
  // does. (First version of this probe bound an ephemeral port instead and
  // never saw a reply — nothing to do with sim, just a bug in the probe.)
  final socket = await RawDatagramSocket.bind(
    InternetAddress.anyIPv4,
    mdnsPort,
    reuseAddress: true,
    reusePort: !Platform.isWindows,
  );
  socket.joinMulticast(mdnsGroup);

  socket.listen((event) {
    if (event != RawSocketEvent.read) return;
    final datagram = socket.receive();
    if (datagram == null) return;
    _dumpResponse(datagram.data, datagram.address);
  });

  final query = _buildQuery('_ledctl._tcp.local');
  print('Sending PTR query for _ledctl._tcp.local to $mdnsGroup:$mdnsPort ...');
  socket.send(query, mdnsGroup, mdnsPort);

  await Future<void>.delayed(const Duration(seconds: 5));
  print('Done waiting (5s). If nothing printed above, no responder answered.');
  socket.close();
  exit(0);
}
