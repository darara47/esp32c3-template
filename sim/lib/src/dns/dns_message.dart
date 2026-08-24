import 'dart:convert';
import 'dart:typed_data';

/// Minimal DNS/mDNS wire-format codec — just enough to decode the question
/// section of an incoming query and encode a PTR/SRV/TXT/A response.
///
/// This exists because `package:multicast_dns` turned out not to help here:
/// its low-level `encodeResponseRecord()` methods skip proper DNS name
/// encoding (labels are written as flat UTF-8 strings, not length-prefixed),
/// and the package has no support at all for handling incoming queries
/// (`// TODO(dnfield): Support queries coming in for published entries.` in
/// its own source). See docs/05-symulator.md for why `sim` needs to
/// advertise itself in the first place.

const int dnsRecordTypeA = 1;
const int dnsRecordTypePtr = 12;
const int dnsRecordTypeTxt = 16;
const int dnsRecordTypeSrv = 33;

const int _classIn = 1;
const int _cacheFlushBit = 0x8000;

/// Encodes a dotted domain name as length-prefixed DNS labels terminated by
/// a zero-length label, per RFC 1035 §3.1. No compression on the way out —
/// packets this small don't need it, and skipping it keeps the encoder
/// trivially easy to get right.
Uint8List encodeName(String fqdn) {
  final bytes = BytesBuilder();
  for (final label in fqdn.split('.')) {
    if (label.isEmpty) continue;
    final labelBytes = utf8.encode(label);
    if (labelBytes.length > 63) {
      throw ArgumentError('DNS label too long (>63 bytes): $label');
    }
    bytes.addByte(labelBytes.length);
    bytes.add(labelBytes);
  }
  bytes.addByte(0);
  return bytes.toBytes();
}

/// Result of decoding a domain name out of a packet: the dotted name and the
/// offset of the first byte after it (before following any compression
/// pointer — that's what the caller needs to keep parsing the packet).
class DecodedName {
  DecodedName(this.name, this.nextOffset);

  final String name;
  final int nextOffset;
}

/// Decodes a domain name starting at [offset], following compression
/// pointers (RFC 1035 §4.1.4) so names that reference earlier parts of the
/// packet resolve correctly. Bounds a pointer chase to guard against
/// malformed or malicious packets looping forever.
DecodedName decodeName(Uint8List data, int offset) {
  final labels = <String>[];
  var pos = offset;
  var returnOffset = -1;
  var jumps = 0;

  while (true) {
    if (pos >= data.length) {
      throw const FormatException('DNS name runs past end of packet');
    }
    final lengthByte = data[pos];

    if (lengthByte == 0) {
      pos += 1;
      returnOffset = returnOffset == -1 ? pos : returnOffset;
      break;
    }

    if ((lengthByte & 0xc0) == 0xc0) {
      if (pos + 1 >= data.length) {
        throw const FormatException('Truncated compression pointer');
      }
      if (++jumps > 20) {
        throw const FormatException('Too many DNS compression pointer jumps');
      }
      final pointer = ((lengthByte & 0x3f) << 8) | data[pos + 1];
      returnOffset = returnOffset == -1 ? pos + 2 : returnOffset;
      pos = pointer;
      continue;
    }

    final start = pos + 1;
    final end = start + lengthByte;
    if (end > data.length) {
      throw const FormatException('DNS label runs past end of packet');
    }
    labels.add(utf8.decode(data.sublist(start, end)));
    pos = end;
  }

  return DecodedName(labels.join('.'), returnOffset);
}

/// The question section of a parsed query: just the names asked about.
/// `sim` answers the same four records (PTR/SRV/TXT/A) regardless of which
/// specific type was queried — simpler than replicating a real responder's
/// per-type filtering, and harmless for a dev tool talking to a handful of
/// clients on a LAN.
List<String> decodeQuestionNames(Uint8List packet) {
  if (packet.length < 12) return const [];
  final header = ByteData.sublistView(packet);
  final questionCount = header.getUint16(4);
  final names = <String>[];
  var offset = 12;

  try {
    for (var i = 0; i < questionCount; i++) {
      final decoded = decodeName(packet, offset);
      names.add(decoded.name);
      offset = decoded.nextOffset + 4; // skip QTYPE + QCLASS
    }
  } on FormatException {
    return names; // best-effort: return whatever we parsed before it broke
  }

  return names;
}

class _Record {
  _Record({
    required this.name,
    required this.type,
    required this.cacheFlush,
    required this.ttl,
    required this.rdata,
  });

  final String name;
  final int type;
  final bool cacheFlush;
  final int ttl;
  final Uint8List rdata;

  void writeTo(BytesBuilder out) {
    out.add(encodeName(name));
    final header = ByteData(10);
    header.setUint16(0, type);
    header.setUint16(2, _classIn | (cacheFlush ? _cacheFlushBit : 0));
    header.setUint32(4, ttl);
    header.setUint16(8, rdata.length);
    out.add(header.buffer.asUint8List());
    out.add(rdata);
  }
}

Uint8List _srvRdata({required String target, required int port}) {
  final out = BytesBuilder();
  final prio = ByteData(6)
    ..setUint16(0, 0) // priority
    ..setUint16(2, 0) // weight
    ..setUint16(4, port);
  out.add(prio.buffer.asUint8List());
  out.add(encodeName(target));
  return out.toBytes();
}

Uint8List _txtRdata(Map<String, String> entries) {
  if (entries.isEmpty) return Uint8List.fromList([0]);
  final out = BytesBuilder();
  entries.forEach((key, value) {
    final bytes = utf8.encode('$key=$value');
    if (bytes.length > 255) {
      throw ArgumentError('TXT entry too long: $key');
    }
    out.addByte(bytes.length);
    out.add(bytes);
  });
  return out.toBytes();
}

/// Builds a complete mDNS response packet announcing one service instance:
/// a PTR (service type → instance), SRV + TXT (instance → host/port/txt) and
/// an A record (host → address) — the same four records a real device would
/// answer with, per docs/02-protokol.md's discovery section.
Uint8List buildAnnouncementPacket({
  required String serviceTypeFqdn,
  required String instanceFqdn,
  required String hostFqdn,
  required List<int> ipv4Address,
  required int port,
  required Map<String, String> txt,
  int ttlSeconds = 120,
}) {
  assert(ipv4Address.length == 4);

  final records = [
    _Record(
      name: serviceTypeFqdn,
      type: dnsRecordTypePtr,
      // PTR is never cache-flushed: several instances share one service-type
      // name, and flushing would wipe out siblings this response knows
      // nothing about.
      cacheFlush: false,
      ttl: ttlSeconds,
      rdata: encodeName(instanceFqdn),
    ),
    _Record(
      name: instanceFqdn,
      type: dnsRecordTypeSrv,
      cacheFlush: true,
      ttl: ttlSeconds,
      rdata: _srvRdata(target: hostFqdn, port: port),
    ),
    _Record(
      name: instanceFqdn,
      type: dnsRecordTypeTxt,
      cacheFlush: true,
      ttl: ttlSeconds,
      rdata: _txtRdata(txt),
    ),
    _Record(
      name: hostFqdn,
      type: dnsRecordTypeA,
      cacheFlush: true,
      ttl: ttlSeconds,
      rdata: Uint8List.fromList(ipv4Address),
    ),
  ];

  final header = ByteData(12);
  header.setUint16(0, 0); // ID — unused for mDNS
  header.setUint16(2, 0x8400); // QR=1 (response), AA=1 (authoritative)
  header.setUint16(4, 0); // QDCOUNT
  header.setUint16(6, records.length); // ANCOUNT
  header.setUint16(8, 0); // NSCOUNT
  header.setUint16(10, 0); // ARCOUNT

  final out = BytesBuilder();
  out.add(header.buffer.asUint8List());
  for (final record in records) {
    record.writeTo(out);
  }
  return out.toBytes();
}
