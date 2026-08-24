# 03 — Aplikacja (Flutter)

## Stos

| Warstwa | Pakiet | Uzasadnienie |
|---|---|---|
| Stan | `flutter_riverpod` | providery per-urządzenie tworzone dynamicznie (`family`) |
| Modele | `freezed`, `json_serializable` | sealed classes dla `Capability`, niezmienny stan, `copyWith` |
| WebSocket | `web_socket_channel` | standard; reconnect własny (~40 linii, lepsze niż pakiety) |
| HTTP | `dio` | interceptory na token, timeouty per-request, retry |
| UDP/DDP | `dart:io` `RawDatagramSocket` | bez zależności, pełna kontrola nad datagramem |
| mDNS | `nsd` | owija natywne NSD/Bonjour; czysty `multicast_dns` zawodzi na Androidzie |
| Baza | `drift` | typowany SQL, migracje, reaktywne query → UI |
| Sekrety | `flutter_secure_storage` | tokeny do Keychain/Keystore |
| Kolor | `material_color_utilities` | przestrzeń HCT; konwersje RGB↔HSV↔mired własne |
| Testy | `mocktail`, golden tests | golden łapie regresje renderingu wzorów |

Sprawdź aktualne wersje przy pierwszym `pub get` — zwłaszcza Riverpod, gdzie API
ewoluuje.

---

## Struktura katalogów

```
app/lib/
├── main.dart
├── app.dart                      MaterialApp, routing, theme
├── core/
│   ├── theme/                    kolory, typografia
│   └── router/                   go_router
├── features/
│   ├── discovery/                skanowanie, parowanie, lista urządzeń
│   ├── device/
│   │   ├── device_screen.dart    ekran urządzenia — składa widgety z caps
│   │   └── widgets/              CctSlider, ColorWheel, EffectList, SegmentEditor
│   ├── scenes/                   sceny wielourządzeniowe
│   ├── patterns/                 edytor wzorów
│   └── settings/
└── providers/                    Riverpod

packages/led_core/lib/
├── models/                       DeviceDescriptor, DeviceState, Capability, Pattern
├── drivers/                      DeviceDriver, NativeDriver, WledDriver, MockDriver
├── transport/                    ws_client.dart, ddp_sender.dart, discovery.dart
└── pattern/                      renderer.dart, generators.dart, modulators.dart
```

`led_core` nie ma zależności od Fluttera — dzięki temu symulator (Dart CLI) może
go używać.

---

## Abstrakcja urządzenia

```dart
abstract class DeviceDriver {
  DeviceDescriptor get descriptor;
  Stream<DeviceState> get state;
  Stream<ConnectionStatus> get status;

  Future<void> apply(StatePatch patch);
  Future<List<Preset>> presets();
  Future<void> savePreset(Preset p);

  /// null jeśli urządzenie nie zgłasza cap 'stream'
  StreamSink<Frame>? get frameSink;

  Future<void> connect();
  Future<void> dispose();
}
```

Implementacje:

| Klasa | Zastosowanie |
|---|---|
| `NativeDriver` | własny firmware, protokół z [02](02-protokol.md) |
| `WledDriver` | tłumaczy na WLED JSON API |
| `MockDriver` | testy jednostkowe, golden testy — bez sieci |

Reszta aplikacji zna **wyłącznie interfejs**. Przeniesienie paska z WLED na własny
firmware to podmiana jednej klasy w fabryce driverów.

```dart
DeviceDriver createDriver(DiscoveredDevice d) => switch (d.serviceType) {
  '_wled._tcp'   => WledDriver(d.host, d.port),
  '_ledctl._tcp' => NativeDriver(d.host, d.port, token: d.token),
  _              => throw UnsupportedError(d.serviceType),
};
```

---

## Rejestr widgetów

Serce dynamicznego UI. Mapa `cap → builder`:

```dart
final capabilityWidgets = <String, WidgetBuilder>{
  'power':      (_) => const PowerTile(),
  'brightness': (_) => const BrightnessSlider(),
  'cct':        (_) => const CctSlider(),
  'rgb':        (_) => const ColorWheel(),
  'effects':    (_) => const EffectList(),
  'segments':   (_) => const SegmentEditor(),
  'pattern':    (_) => const PatternPicker(),
};
```

```dart
Column(
  children: descriptor.caps
      .map((c) => capabilityWidgets[c])
      .whereType<WidgetBuilder>()   // nieznane cap = pominięte, bez błędu
      .map((b) => b(context))
      .toList(),
)
```

Kolejność widgetów: zdefiniuj jawną listę porządkującą, nie polegaj na kolejności
z deskryptora — firmware może ją zmienić między wersjami.

---

## Zarządzanie stanem

### Providery

```dart
final devicesProvider = StreamProvider<List<DiscoveredDevice>>(...);

final driverProvider = Provider.family<DeviceDriver, String>((ref, id) {
  final driver = createDriver(ref.watch(devicesProvider).byId(id));
  ref.onDispose(driver.dispose);
  return driver;
});

final deviceStateProvider = StreamProvider.family<DeviceState, String>(
  (ref, id) => ref.watch(driverProvider(id)).state,
);
```

### UI optymistyczny + reconciliation

Suwak musi reagować natychmiast, ale stan prawdy jest na urządzeniu.

1. Ruch suwaka → aktualizuj lokalny stan **od razu**, renderuj.
2. Wyślij patch (throttlowany).
3. Gdy przyjdzie `patch` z urządzenia — porównaj. Jeśli różni się od lokalnego
   i minęło >300 ms od ostatniej interakcji użytkownika, przyjmij wartość z urządzenia.

Warunek czasowy jest kluczowy: bez niego echo własnego patcha będzie „szarpać"
suwakiem w trakcie przeciągania.

### Throttling suwaków

```dart
// wysyłaj max 25 Hz w trakcie przeciągania
onChanged: (v) => _throttle(() => driver.apply(StatePatch(bri: v)));

// ZAWSZE wyślij pełną wartość po puszczeniu palca
onChangeEnd: (v) => driver.apply(StatePatch(bri: v), force: true);
```

Bez `onChangeEnd` ostatnia wartość czasem ginie w throttlu i kolor zostaje
o krok obok tego, co pokazuje UI. To jeden z tych bugów, które trudno powtórzyć
i łatwo zignorować.

---

## Color picker i edytor wzorów — pisz sam

`CustomPainter`, nie gotowe pakiety. Powody:

- Gotowe color pickery wyglądają generycznie i to jest **dokładnie ta część**,
  w której aplikacja ma bić webowy UI WLED-a.
- Podgląd 144 pikseli w `CustomPainter` to zero problemu wydajnościowego.
- Pełna kontrola nad gestami (dwa palce = jasność + saturacja jednocześnie).

Przy podglądzie matrycy 16×16 przy 60 fps — `FragmentProgram` (shadery GLSL).
Ale dopiero gdy `CustomPainter` przestanie wyrabiać, nie zapobiegawczo.

### Podgląd wzoru

Edytor renderuje ten sam JSON co firmware, przez `led_core/pattern/renderer.dart`:

```dart
final frame = PatternRenderer(pattern, geometry).sample(t);
// frame: List<Color> — rysowane przez CustomPainter jako pasek/matryca
```

Podgląd napędzany `Ticker` (60 fps). Przy edycji parametru — rerender natychmiast,
zapis na urządzenie throttlowany do ~5 Hz.

---

## Discovery — przepływ

```
start aplikacji
   ├── załaduj sparowane urządzenia z Drift (IP + MAC + token)
   ├── równolegle:
   │     ├── próba połączenia po cache'owanym IP     ← daje wynik w <200 ms
   │     └── skan mDNS (_ledctl._tcp, _wled._tcp)    ← może trwać 2–5 s
   └── merge wyników po `id` (MAC), aktualizuj cache IP
```

Nigdy nie blokuj UI na mDNS. Pokaż listę z cache natychmiast, oznacz stan
połączenia per-urządzenie.

---

## Persystencja (Drift)

Tabele:

| Tabela | Zawartość |
|---|---|
| `devices` | id (MAC), nazwa, ostatnie IP, model, schema, `token_ref` |
| `scenes` | nazwa, JSON targets, transition_ms |
| `patterns` | id, nazwa, JSON, thumbnail |
| `favorites` | kolory, palety |

Tokeny **nie** w Drift — tylko referencja. Sama wartość w `flutter_secure_storage`
pod kluczem `token_<device_id>`.

**Stan na M1 (przed Drift):** `PairedTokensNotifier` (`features/pairing/`) już
używa `flutter_secure_storage`, ale kluczem jest **host**, nie `device_id` —
nie ma jeszcze tabeli `devices`, więc nie ma gdzie trzymać mapowania
id → ostatnie IP. Konsekwencja: zmiana IP przez DHCP wymaga ponownego
sparowania, tak samo jak dziś działa `manualDevicesProvider`. Naprawia się to
przy okazji Drift, nie osobno.

---

## Uprawnienia platformowe

### Android — `AndroidManifest.xml`

```xml
<uses-permission android:name="android.permission.INTERNET"/>
<uses-permission android:name="android.permission.ACCESS_NETWORK_STATE"/>
<uses-permission android:name="android.permission.CHANGE_WIFI_MULTICAST_STATE"/>

<!-- BLE provisioning. Pre-API31 scanning also needs location; capped with
     maxSdkVersion since API31+ covers it via BLUETOOTH_SCAN instead. -->
<uses-permission android:name="android.permission.BLUETOOTH" android:maxSdkVersion="30"/>
<uses-permission android:name="android.permission.BLUETOOTH_ADMIN" android:maxSdkVersion="30"/>
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" android:maxSdkVersion="30"/>
<uses-permission android:name="android.permission.BLUETOOTH_SCAN"
                 android:usesPermissionFlags="neverForLocation"/>
<uses-permission android:name="android.permission.BLUETOOTH_CONNECT"/>
```

`CHANGE_WIFI_MULTICAST_STATE` jest wymagane do mDNS i łatwo je przeoczyć —
objaw to działające discovery na iOS i cisza na Androidzie.

### iOS — `Info.plist`

Patrz [02 — Protokół](02-protokol.md#ios--infoplist) plus:

```xml
<key>NSBluetoothAlwaysUsageDescription</key>
<string>Konfiguracja WiFi nowego sterownika.</string>
```

---

## Testy

| Rodzaj | Zakres |
|---|---|
| Unit | konwersje kolorów, mired, enkoder DDP, parser stanu |
| Conformance | renderer wzorów Dart vs złote wartości (patrz [02](02-protokol.md#kontrakt-renderera)) |
| Widget | rejestr caps → poprawny zestaw widgetów |
| Golden | podgląd wzoru, color wheel |
| Integracyjne | pełny flow przeciwko symulatorowi |

Testy integracyjne odpalane przeciwko `sim` w CI — bez sprzętu, deterministycznie.
