import 'dart:typed_data';

import 'package:sim/src/dns/dns_message.dart';
import 'package:test/test.dart';

/// Walks the answer records of a response packet built by
/// [buildAnnouncementPacket], re-using the module's own [decodeName] (it has
/// its own dedicated round-trip tests below) to check the parts an encoder
/// bug is most likely to get wrong: name framing, RDLENGTH, and per-type
/// RDATA layout.
List<Map<String, Object?>> _readAnswers(Uint8List packet) {
  final header = ByteData.sublistView(packet);
  final answerCount = header.getUint16(6);
  var offset = 12; // no questions in a response packet

  final answers = <Map<String, Object?>>[];
  for (var i = 0; i < answerCount; i++) {
    final name = decodeName(packet, offset);
    offset = name.nextOffset;
    final type = header.getUint16(offset);
    final rrClass = header.getUint16(offset + 2);
    final ttl = header.getUint32(offset + 4);
    final rdlength = header.getUint16(offset + 8);
    offset += 10;
    final rdata = packet.sublist(offset, offset + rdlength);
    offset += rdlength;
    answers.add({
      'name': name.name,
      'type': type,
      'class': rrClass,
      'ttl': ttl,
      'rdata': rdata,
    });
  }
  return answers;
}

void main() {
  group('encodeName / decodeName', () {
    test('round-trips a simple dotted name', () {
      final encoded = encodeName('Biurko._ledctl._tcp.local');
      final decoded = decodeName(encoded, 0);

      expect(decoded.name, 'Biurko._ledctl._tcp.local');
      expect(decoded.nextOffset, encoded.length);
    });

    test('follows a compression pointer', () {
      final target = encodeName('host.local');
      // Pointer bytes: top two bits set (0xC0) + 14-bit offset (0 here).
      final pointer = Uint8List.fromList([0xc0, 0x00]);
      final packet = Uint8List.fromList([...target, ...pointer]);

      final decoded = decodeName(packet, target.length);

      expect(decoded.name, 'host.local');
      expect(decoded.nextOffset, target.length + pointer.length);
    });

    test('rejects a pointer loop instead of hanging', () {
      // Byte 0 points at byte 0 — a direct self-loop.
      final packet = Uint8List.fromList([0xc0, 0x00]);

      expect(() => decodeName(packet, 0), throwsFormatException);
    });
  });

  group('decodeQuestionNames', () {
    test('parses the question section of a hand-built query packet', () {
      final name = encodeName('_ledctl._tcp.local');
      final header = ByteData(12);
      header.setUint16(4, 1); // QDCOUNT = 1
      final trailer = Uint8List(4); // QTYPE + QCLASS, values don't matter here
      final packet = Uint8List.fromList([
        ...header.buffer.asUint8List(),
        ...name,
        ...trailer,
      ]);

      expect(decodeQuestionNames(packet), ['_ledctl._tcp.local']);
    });

    test('returns an empty list for a too-short packet', () {
      expect(decodeQuestionNames(Uint8List(4)), isEmpty);
    });
  });

  group('buildAnnouncementPacket', () {
    test('encodes PTR, SRV, TXT and A answers for the service', () {
      final packet = buildAnnouncementPacket(
        serviceTypeFqdn: '_ledctl._tcp.local',
        instanceFqdn: 'Biurko._ledctl._tcp.local',
        hostFqdn: 'ledctl-abc123.local',
        ipv4Address: [192, 168, 1, 42],
        port: 8081,
        txt: {'id': 'be:ef:00:00:00:01', 'model': 'ledctl-cct'},
      );

      final header = ByteData.sublistView(packet);
      expect(header.getUint16(2), 0x8400); // QR + AA
      expect(header.getUint16(6), 4); // ANCOUNT

      final answers = _readAnswers(packet);
      final byType = {for (final a in answers) a['type']: a};

      final ptr = byType[dnsRecordTypePtr]!;
      expect(ptr['name'], '_ledctl._tcp.local');
      expect(ptr['class'], 1); // never cache-flushed
      expect(decodeName(ptr['rdata']! as Uint8List, 0).name, 'Biurko._ledctl._tcp.local');

      final srv = byType[dnsRecordTypeSrv]!;
      expect(srv['name'], 'Biurko._ledctl._tcp.local');
      expect(srv['class'], 0x8001); // cache-flush set
      final srvData = ByteData.sublistView(srv['rdata']! as Uint8List);
      expect(srvData.getUint16(4), 8081); // port
      expect(
        decodeName(srv['rdata']! as Uint8List, 6).name,
        'ledctl-abc123.local',
      );

      final txt = byType[dnsRecordTypeTxt]!;
      final txtBytes = txt['rdata']! as Uint8List;
      final firstLen = txtBytes[0];
      final firstEntry = String.fromCharCodes(txtBytes.sublist(1, 1 + firstLen));
      expect(firstEntry, 'id=be:ef:00:00:00:01');

      final a = byType[dnsRecordTypeA]!;
      expect(a['name'], 'ledctl-abc123.local');
      expect(a['rdata'], [192, 168, 1, 42]);
    });

    test('TXT record with no entries still encodes a single zero-length string', () {
      final packet = buildAnnouncementPacket(
        serviceTypeFqdn: '_ledctl._tcp.local',
        instanceFqdn: 'X._ledctl._tcp.local',
        hostFqdn: 'x.local',
        ipv4Address: [10, 0, 0, 1],
        port: 80,
        txt: const {},
      );

      final txt = _readAnswers(
        packet,
      ).firstWhere((a) => a['type'] == dnsRecordTypeTxt);
      expect(txt['rdata'], [0]);
    });
  });
}
