import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_esp_ble_prov/flutter_esp_ble_prov.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nsd/nsd.dart';
import 'package:permission_handler/permission_handler.dart' hide ServiceStatus;

import '../../providers/device_providers.dart';
import 'paired_tokens_provider.dart';

/// BLE service-name prefix ledctl firmware advertises while unprovisioned —
/// see ledctl_provisioning.c's service_name_from_mac().
const _servicePrefix = 'PROV_';

/// Matches Kconfig LEDCTL_PROV_POP's default — see
/// docs/04-firmware.md#provisioning-ble. Editable below for a device built
/// with a different value.
const _defaultPop = 'abcd1234';

const _mdnsServiceType = '_ledctl._tcp';
const _claimSearchTimeout = Duration(seconds: 30);

enum _Step { scanBle, pickWifi, done, error }

/// Walks the user through pairing a fresh (unprovisioned) device: BLE scan →
/// pick device → send WiFi credentials over the encrypted BLE channel
/// (handled by Espressif's own provisioning SDK, wrapped by
/// flutter_esp_ble_prov — not reimplemented here) → find the device on the
/// LAN via mDNS → claim its one-time API token over HTTP.
///
/// The token hand-off happens over LAN (`GET /api/claim`, disabled after
/// first use — see docs/02-protokol.md), not over the BLE channel itself:
/// no mature Flutter BLE-provisioning plugin exposes ESP-IDF's custom
/// protocomm endpoints, and reimplementing the X25519/AES-CTR handshake by
/// hand just to carry 32 bytes of token wasn't worth the risk. A device
/// still *can* hand its token out over BLE — see the "custom-data" endpoint
/// in ledctl_provisioning.c — for tools that do support it (e.g. IDF's
/// `esp_prov.py`).
class PairingScreen extends ConsumerStatefulWidget {
  const PairingScreen({super.key});

  @override
  ConsumerState<PairingScreen> createState() => _PairingScreenState();
}

class _PairingScreenState extends ConsumerState<PairingScreen> {
  final _prov = FlutterEspBleProv();
  final _popController = TextEditingController(text: _defaultPop);
  final _passwordController = TextEditingController();
  final _customSsidController = TextEditingController();

  _Step _step = _Step.scanBle;
  bool _busy = false;
  String _busyMessage = '';
  String? _error;

  List<String> _bleDevices = const [];
  String? _selectedDevice;
  List<String> _wifiNetworks = const [];
  bool _showOpenSettings = false;

  Uri? _claimedUri;

  @override
  void initState() {
    super.initState();
    _scanBle();
  }

  @override
  void dispose() {
    _popController.dispose();
    _passwordController.dispose();
    _customSsidController.dispose();
    super.dispose();
  }

  Future<bool> _ensurePermissions() async {
    if (!Platform.isAndroid && !Platform.isIOS) return true;

    // Android <12 needs location for a BLE scan to return anything; the
    // manifest caps ACCESS_FINE_LOCATION to maxSdkVersion 30, so on 12+
    // it isn't declared at all and requesting it here would just fail —
    // gating success on it would then block BLUETOOTH_SCAN's own
    // `neverForLocation` path for no reason. Best-effort only.
    await Permission.locationWhenInUse.request();

    final statuses = await [
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
    ].request();
    // A permanent denial means Android won't show the system dialog again
    // on a future request() — the only way back is the app's settings
    // page, so _buildError() offers a shortcut there instead of a retry
    // that would silently do nothing.
    _showOpenSettings = statuses.values.any((s) => s.isPermanentlyDenied);
    return statuses.values.every((s) => s.isGranted || s.isLimited);
  }

  Future<void> _scanBle() async {
    setState(() {
      _step = _Step.scanBle;
      _error = null;
      _showOpenSettings = false;
      _busy = true;
      _busyMessage = 'Szukam urządzeń…';
    });

    // flutter_esp_ble_prov only ships iOS/Android native implementations —
    // on any other platform its method channel has nothing on the other
    // end, and the call can simply hang forever rather than throwing.
    if (!Platform.isAndroid && !Platform.isIOS) {
      setState(() {
        _busy = false;
        _step = _Step.error;
        _error = 'Parowanie BLE działa tylko na telefonie (Android/iOS) — nie na tej platformie. '
            'Uruchom aplikację przez `flutter run -d <telefon>`, albo sparuj urządzenie ręcznie '
            'narzędziem esp_prov.py z ESP-IDF.';
      });
      return;
    }

    if (!await _ensurePermissions()) {
      setState(() {
        _busy = false;
        _step = _Step.error;
        _error = _showOpenSettings
            ? 'Uprawnienia Bluetooth zostały wcześniej odrzucone na stałe — Android nie pokaże '
                  'okna z prośbą ponownie. Włącz je ręcznie w ustawieniach aplikacji.'
            : 'Aplikacja potrzebuje uprawnień Bluetooth, żeby wyszukać urządzenie w trybie parowania.';
      });
      return;
    }

    try {
      final found = await _prov.scanBleDevices(_servicePrefix).timeout(const Duration(seconds: 20));
      setState(() {
        _bleDevices = found;
        _busy = false;
      });
    } catch (e) {
      setState(() {
        _busy = false;
        _step = _Step.error;
        _error = 'Skanowanie BLE nie powiodło się: $e';
      });
    }
  }

  Future<void> _selectDevice(String deviceName) async {
    setState(() {
      _selectedDevice = deviceName;
      _busy = true;
      _busyMessage = 'Łączę się z urządzeniem…';
      _error = null;
    });
    try {
      final networks = await _prov.scanWifiNetworks(deviceName, _popController.text);
      setState(() {
        _wifiNetworks = networks;
        _busy = false;
        _step = _Step.pickWifi;
      });
    } catch (e) {
      setState(() {
        _busy = false;
        _step = _Step.error;
        _error = 'Nie udało się połączyć z urządzeniem — sprawdź proof-of-possession: $e';
      });
    }
  }

  Future<void> _provision(String ssid) async {
    final password = _passwordController.text;
    setState(() {
      _busy = true;
      _busyMessage = 'Wysyłam dane WiFi…';
      _error = null;
    });

    // ESP32-C3 shares one radio between WiFi and BLE — the *last* exchange
    // in this flow (polling for "config applied") sometimes drops right as
    // the device starts actually joining the network, throwing here even
    // though the credentials already landed. So: never treat a thrown/false
    // result here as final — always check the LAN afterward via
    // _claimToken(), and only report failure if that comes up empty too.
    try {
      await _prov.provisionWifi(_selectedDevice!, _popController.text, ssid, password);
    } catch (_) {
      // Swallowed deliberately — see comment above.
    }

    await _claimToken();
  }

  Future<void> _claimToken() async {
    setState(() => _busyMessage = 'Szukam urządzenia w sieci lokalnej…');

    // The BLE service name is "PROV_" + the last 3 MAC bytes (see
    // ledctl_provisioning.c) — the same bytes that end the mDNS `id` TXT
    // record (docs/02-protokol.md#mdns), so this is how the freshly
    // reappeared device is told apart from any others on the LAN.
    final macSuffix = _selectedDevice!.substring(_servicePrefix.length).toLowerCase();

    Discovery? discovery;
    try {
      discovery = await startDiscovery(_mdnsServiceType, ipLookupType: IpLookupType.v4);
      final uri = await _waitForMatch(discovery, macSuffix).timeout(_claimSearchTimeout, onTimeout: () => null);

      if (uri == null) {
        setState(() {
          _busy = false;
          _step = _Step.error;
          _error = 'Urządzenie nie pojawiło się w sieci lokalnej na czas — albo dane WiFi się nie '
              'przyjęły, albo telefon jest w innej sieci niż urządzenie. Sprawdź hasło i spróbuj '
              'ponownie, albo dodaj urządzenie ręcznie po adresie IP, jeśli już dołączyło do sieci.';
        });
        return;
      }

      setState(() => _busyMessage = 'Znaleziono — odbieram token…');
      final token = await _fetchClaim(uri);
      if (token == null) {
        setState(() {
          _busy = false;
          _step = _Step.error;
          _error = 'Urządzenie znalezione, ale token już odebrany wcześniej przez kogoś innego. '
              'Jeśli to nie Ty, zresetuj parowanie przyciskiem BOOT na urządzeniu (5 s) i spróbuj ponownie.';
        });
        return;
      }

      await ref.read(pairedTokensProvider.notifier).save(uri.host, token);
      ref.read(manualDevicesProvider.notifier).add(Uri(scheme: 'ws', host: uri.host, port: uri.port, path: '/ws'));

      setState(() {
        _busy = false;
        _claimedUri = uri;
        _step = _Step.done;
      });
    } finally {
      final d = discovery;
      if (d != null) unawaited(stopDiscovery(d));
    }
  }

  Future<Uri?> _waitForMatch(Discovery discovery, String macSuffix) {
    final completer = Completer<Uri?>();

    bool matchesSuffix(Service service) {
      final idBytes = service.txt?['id'];
      if (idBytes == null) return false;
      final id = utf8.decode(idBytes).replaceAll(':', '').toLowerCase();
      return id.endsWith(macSuffix);
    }

    Uri? toHttpUri(Service service) {
      final port = service.port;
      if (port == null) return null;
      final addresses = service.addresses;
      final host = (addresses != null && addresses.isNotEmpty) ? addresses.first.address : service.host;
      if (host == null) return null;
      return Uri(scheme: 'http', host: host, port: port);
    }

    void check(Service service) {
      if (completer.isCompleted || !matchesSuffix(service)) return;
      final uri = toHttpUri(service);
      if (uri != null) completer.complete(uri);
    }

    discovery.addServiceListener((service, status) {
      if (status != ServiceStatus.lost) check(service);
    });
    for (final service in discovery.services) {
      check(service);
    }

    return completer.future;
  }

  Future<String?> _fetchClaim(Uri deviceHttpUri) async {
    final client = HttpClient();
    try {
      final request = await client.getUrl(deviceHttpUri.replace(path: '/api/claim'));
      final response = await request.close();
      if (response.statusCode != 200) return null;
      final body = await response.transform(utf8.decoder).join();
      final json = jsonDecode(body) as Map<String, dynamic>;
      return json['token'] as String?;
    } finally {
      client.close();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Paruj urządzenie')),
      body: _busy
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(),
                    const SizedBox(height: 16),
                    Text(_busyMessage, textAlign: TextAlign.center),
                  ],
                ),
              ),
            )
          : switch (_step) {
              _Step.scanBle => _buildScanBle(),
              _Step.pickWifi => _buildPickWifi(),
              _Step.done => _buildDone(),
              _Step.error => _buildError(),
            },
    );
  }

  Widget _buildScanBle() {
    return Column(
      children: [
        Expanded(
          child: _bleDevices.isEmpty
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Text(
                      'Brak urządzeń w trybie parowania w zasięgu. Nowe urządzenie '
                      'wchodzi w ten tryb automatycznie przy pierwszym uruchomieniu.',
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              : ListView(
                  children: [
                    for (final name in _bleDevices)
                      ListTile(
                        leading: const Icon(Icons.bluetooth),
                        title: Text(name),
                        onTap: () => _selectDevice(name),
                      ),
                  ],
                ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              ExpansionTile(
                title: const Text('Zaawansowane'),
                tilePadding: EdgeInsets.zero,
                children: [
                  TextField(
                    controller: _popController,
                    decoration: const InputDecoration(
                      labelText: 'Proof-of-possession',
                      helperText: 'Musi zgadzać się z LEDCTL_PROV_POP firmware\'u urządzenia.',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              FilledButton.icon(
                onPressed: _scanBle,
                icon: const Icon(Icons.refresh),
                label: const Text('Skanuj ponownie'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPickWifi() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Sieć WiFi widziana przez ${_selectedDevice ?? "urządzenie"}:', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        for (final ssid in _wifiNetworks)
          ListTile(
            leading: const Icon(Icons.wifi),
            title: Text(ssid),
            onTap: () => _showPasswordDialog(ssid),
          ),
        const Divider(),
        TextField(
          controller: _customSsidController,
          decoration: const InputDecoration(labelText: 'Inna sieć (SSID ukryte)'),
          onSubmitted: (ssid) {
            if (ssid.trim().isNotEmpty) _showPasswordDialog(ssid.trim());
          },
        ),
      ],
    );
  }

  Future<void> _showPasswordDialog(String ssid) async {
    _passwordController.clear();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(ssid),
        content: TextField(
          controller: _passwordController,
          obscureText: true,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Hasło WiFi'),
          onSubmitted: (_) => Navigator.pop(context, true),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Anuluj')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Połącz')),
        ],
      ),
    );
    if (confirmed == true) await _provision(ssid);
  }

  Widget _buildDone() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle, color: Colors.green, size: 64),
            const SizedBox(height: 16),
            Text('Sparowano ${_claimedUri?.host ?? ""}', textAlign: TextAlign.center),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Gotowe'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 64),
            const SizedBox(height: 16),
            Text(_error ?? 'Coś poszło nie tak.', textAlign: TextAlign.center),
            const SizedBox(height: 24),
            if (_showOpenSettings) ...[
              FilledButton(
                onPressed: () => openAppSettings(),
                child: const Text('Otwórz ustawienia aplikacji'),
              ),
              const SizedBox(height: 8),
              TextButton(onPressed: _scanBle, child: const Text('Spróbuj ponownie')),
            ] else
              FilledButton(onPressed: _scanBle, child: const Text('Zacznij od nowa')),
          ],
        ),
      ),
    );
  }
}
