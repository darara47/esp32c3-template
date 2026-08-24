import 'dart:io';

import 'package:args/args.dart';
import 'package:led_core/led_core.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:sim/src/device_server.dart';
import 'package:sim/src/dns/mdns_responder.dart';
import 'package:sim/src/ids.dart';
import 'package:sim/src/network.dart';
import 'package:sim/src/virtual_device.dart';

ArgParser _buildParser() => ArgParser()
  ..addOption(
    'type',
    allowed: ['cct'],
    allowedHelp: {'cct': 'ESP32-C3 + 2× MOSFET — biel ciepła/zimna'},
    help:
        'Typ urządzenia. `pixels` dochodzi w M2 (docs/07-roadmapa.md), na '
        'razie zaimplementowany jest tylko cct.',
  )
  ..addOption('name', defaultsTo: 'Symulator CCT', help: 'Nazwa urządzenia.')
  ..addOption('port', defaultsTo: '8080', help: 'Port HTTP/WS.')
  ..addOption('schema', defaultsTo: '1', help: 'Udawana wersja schematu.')
  ..addFlag(
    'no-mdns',
    negatable: false,
    help: 'Wyłącz ogłaszanie mDNS — test fallbacku po ręcznie podanym IP.',
  )
  ..addFlag('help', abbr: 'h', negatable: false);

Future<void> main(List<String> arguments) async {
  final parser = _buildParser();

  final ArgResults args;
  try {
    args = parser.parse(arguments);
  } on FormatException catch (e) {
    stderr.writeln(e.message);
    stderr.writeln(parser.usage);
    exitCode = 64;
    return;
  }

  final wantsHelp = args['help'] as bool;
  if (wantsHelp || args['type'] == null) {
    stdout
      ..writeln('Użycie: dart run sim --type=cct [opcje]')
      ..writeln()
      ..writeln(parser.usage);
    exitCode = wantsHelp ? 0 : 64;
    return;
  }

  final name = args['name'] as String;
  final port = int.parse(args['port'] as String);
  final schema = int.parse(args['schema'] as String);
  final id = syntheticMac('$name:$port');

  final descriptor = DeviceDescriptor(
    schema: schema,
    id: id,
    name: name,
    model: 'ledctl-cct',
    fw: '0.1.0-sim',
    caps: const ['power', 'brightness', 'cct', 'transition'],
    cct: const CctRange(min: 2700, max: 6500),
  );

  final device = VirtualDevice(descriptor: descriptor);
  await shelf_io.serve(
    buildDeviceHandler(device),
    InternetAddress.anyIPv4,
    port,
  );

  final address = await primaryLocalAddress();
  stdout.writeln(
    '$name  [cct · schema $schema]  ws://${address.address}:$port/ws',
  );

  MdnsResponder? responder;
  if (args['no-mdns'] as bool) {
    stdout.writeln(
      'mDNS: wyłączone (--no-mdns) — dodaj urządzenie ręcznie po adresie wyżej.',
    );
  } else {
    final announcement = MdnsAnnouncement(
      instanceName: name,
      hostName: 'ledctl-${id.replaceAll(':', '')}',
      address: address,
      port: port,
      txt: {
        'id': id,
        'model': descriptor.model,
        'fw': descriptor.fw ?? '',
        'schema': '$schema',
      },
    );
    responder = MdnsResponder(announcement);
    await responder.start();
    stdout.writeln('mDNS: ogłaszanie ${announcement.instanceFqdn}');
  }

  stdout.writeln('Ctrl+C aby zakończyć.');
  await ProcessSignal.sigint.watch().first;
  stdout.writeln('\nZamykanie...');
  await responder?.stop();
  exit(0);
}
