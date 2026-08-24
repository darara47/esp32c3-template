import 'dart:async';
import 'dart:io';

import 'dns_message.dart';

final InternetAddress mdnsGroup = InternetAddress('224.0.0.251');
const int mdnsPort = 5353;

/// What to announce: one `_ledctl._tcp.local` service instance, per
/// docs/02-protokol.md#mdns.
class MdnsAnnouncement {
  MdnsAnnouncement({
    required this.instanceName,
    required this.hostName,
    required this.address,
    required this.port,
    required this.txt,
    this.serviceType = '_ledctl._tcp',
  });

  final String instanceName;
  final String hostName;
  final InternetAddress address;
  final int port;
  final Map<String, String> txt;
  final String serviceType;

  String get serviceTypeFqdn => '$serviceType.local';
  String get instanceFqdn => '$instanceName.$serviceTypeFqdn';
  String get hostFqdn => '$hostName.local';
}

/// A minimal mDNS responder: joins the multicast group, and answers any
/// query that names this service, its instance, or its host with the full
/// PTR/SRV/TXT/A set. No probing, no goodbye packet, no periodic
/// re-announcement — this is a dev tool started and stopped by hand for one
/// working session, not a long-lived production responder. See the mDNS
/// library research in the project history for why this is hand-rolled
/// instead of using a package.
class MdnsResponder {
  MdnsResponder(this.announcement);

  final MdnsAnnouncement announcement;
  RawDatagramSocket? _socket;

  Future<void> start() async {
    final socket = await RawDatagramSocket.bind(
      InternetAddress.anyIPv4,
      mdnsPort,
      reuseAddress: true,
      // SO_REUSEPORT isn't supported on Windows — dart:io logs a scary but
      // non-fatal "ERROR" to stderr and carries on if you pass true anyway.
      reusePort: !Platform.isWindows,
    );
    socket.joinMulticast(mdnsGroup);
    socket.listen(_handleEvent);
    _socket = socket;
  }

  void _handleEvent(RawSocketEvent event) {
    if (event != RawSocketEvent.read) return;
    final socket = _socket;
    if (socket == null) return;
    final datagram = socket.receive();
    if (datagram == null) return;

    List<String> questionNames;
    try {
      questionNames = decodeQuestionNames(datagram.data);
    } on FormatException {
      return; // not a packet we understand — ignore, don't crash the sim
    }
    if (questionNames.isEmpty) return;

    final ours = {
      announcement.serviceTypeFqdn,
      announcement.instanceFqdn,
      announcement.hostFqdn,
    };
    final isForUs = questionNames.any(
      (name) => ours.contains(_normalize(name)),
    );
    if (!isForUs) return;

    final packet = buildAnnouncementPacket(
      serviceTypeFqdn: announcement.serviceTypeFqdn,
      instanceFqdn: announcement.instanceFqdn,
      hostFqdn: announcement.hostFqdn,
      ipv4Address: announcement.address.rawAddress,
      port: announcement.port,
      txt: announcement.txt,
    );
    socket.send(packet, mdnsGroup, mdnsPort);
  }

  Future<void> stop() async {
    _socket?.close();
    _socket = null;
  }
}

String _normalize(String dnsName) =>
    dnsName.endsWith('.') ? dnsName.substring(0, dnsName.length - 1) : dnsName;
