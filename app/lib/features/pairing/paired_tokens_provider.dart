import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

const _prefsPrefix = 'ledctl.token.';
const _storage = FlutterSecureStorage();

/// {host: token} learned from BLE provisioning (pairing_screen.dart) and
/// persisted across restarts — otherwise a paired device would become
/// unreachable the moment the app closes, since every request now needs the
/// token (docs/02-protokol.md's `Authorization: Bearer`). Backed by
/// Keychain/Keystore (docs/03-aplikacja.md#persystencja-drift calls this out
/// explicitly: tokens are secrets, not plain prefs).
///
/// Keyed by host, not the stable device id: like [manualDevicesProvider],
/// this app doesn't yet cache "last known IP per device id" (that's the
/// still-missing half of docs/02-protokol.md#fallback--obowiązkowy, M3), so
/// a device that gets a new DHCP lease needs re-pairing either way.
class PairedTokensNotifier extends Notifier<Map<String, String>> {
  @override
  Map<String, String> build() {
    _hydrate();
    return const {};
  }

  Future<void> _hydrate() async {
    final Map<String, String> all;
    try {
      all = await _storage.readAll();
    } catch (_) {
      // No secure-storage backend on this platform (e.g. a widget test with
      // no platform channel handler) — degrade to "no paired tokens yet"
      // rather than crashing every provider that reads this one.
      return;
    }
    if (!ref.mounted) return;

    state = {
      for (final entry in all.entries)
        if (entry.key.startsWith(_prefsPrefix)) entry.key.substring(_prefsPrefix.length): entry.value,
    };
  }

  Future<void> save(String host, String token) async {
    state = {...state, host: token};
    await _storage.write(key: '$_prefsPrefix$host', value: token);
  }

  Future<void> remove(String host) async {
    state = {...state}..remove(host);
    await _storage.delete(key: '$_prefsPrefix$host');
  }
}

final pairedTokensProvider = NotifierProvider<PairedTokensNotifier, Map<String, String>>(
  PairedTokensNotifier.new,
);
