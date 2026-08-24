# 01 — Architektura

## Zasada naczelna

**Urządzenie opisuje siebie, aplikacja renderuje UI dynamicznie.**

Aplikacja nigdy nie zawiera kodu w rodzaju `if (device.type == 'cct') showCctSlider()`.
Zamiast tego urządzenie wystawia listę zdolności, a aplikacja ma rejestr widgetów
mapowanych na te zdolności.

Konsekwencja: dodanie ściemniacza 0–10 V, matrycy 16×16 czy sterownika RGBW oznacza
napisanie firmware'u i **jednego widgetu**. Reszta aplikacji nie wie o zmianie.

```
caps: ["power","brightness","cct"]      →  [PowerTile] [BrightnessSlider] [CctSlider]
caps: ["power","brightness","rgb",
       "segments","effects","stream"]   →  [PowerTile] [BrightnessSlider] [ColorWheel]
                                           [SegmentEditor] [EffectList] [PatternEditor]
```

---

## Warstwy

```
┌─────────────────────────────────────────────────┐
│  UI (Flutter)                                   │
│  Widgety składane z rejestru wg caps            │
├─────────────────────────────────────────────────┤
│  Stan (Riverpod)                                │
│  deviceProvider.family — jeden per urządzenie   │
├─────────────────────────────────────────────────┤
│  DeviceDriver (abstrakcja)                      │
│  WledDriver │ NativeDriver │ MockDriver         │
├─────────────────────────────────────────────────┤
│  Transport                                      │
│  WebSocket (control) │ UDP/DDP (stream) │ mDNS  │
├─────────────────────────────────────────────────┤
│  Firmware (ESP-IDF)                             │
│  Interpreter wzorów │ Renderer │ RMT/LEDC       │
└─────────────────────────────────────────────────┘
```

---

## Control plane vs data plane

Najważniejsza decyzja architektoniczna w projekcie. Dwie ścieżki, dwa protokoły:

| | Control plane | Data plane |
|---|---|---|
| **Co** | kolor, efekt, jasność, presety | klatki pikseli 30–60 fps |
| **Wymagania** | musi dojść, potwierdzenie | niska latencja, zgubione klatki OK |
| **Protokół** | WebSocket / JSON | UDP / DDP |
| **Częstotliwość** | zdarzeniowa, ≤25 Hz | stała, 30–60 Hz |

**Dlaczego nie WebSocket do wszystkiego:** TCP przy zgubionym pakiecie wstrzymuje
kolejne (head-of-line blocking) i retransmituje klatkę, która jest już nieaktualna.
Efekt to widoczne zacinanie zamiast płynnego pominięcia jednej klatki.

---

## Model zdolności

### Deskryptor urządzenia

Zwracany przez `GET /api/device` oraz wysyłany jako pierwsza ramka po handshake WS.

```json
{
  "schema": 1,
  "id": "a4:cf:12:00:11:22",
  "name": "Salon – sufit",
  "model": "ledctl-cct",
  "fw": "0.1.0",
  "caps": ["power", "brightness", "cct", "transition"],
  "cct": { "min": 2700, "max": 6500 }
}
```

```json
{
  "schema": 1,
  "id": "a4:cf:12:00:33:44",
  "name": "Biurko",
  "model": "ledctl-pixels",
  "fw": "0.1.0",
  "caps": ["power", "brightness", "rgb", "segments", "effects", "stream", "pattern"],
  "geometry": {
    "type": "strip",
    "count": 144,
    "spacing_mm": 6.94,
    "map": null
  },
  "stream": { "proto": "ddp", "port": 4048, "maxFps": 60 }
}
```

### Katalog zdolności

| `cap` | Znaczenie | Pola stanu |
|---|---|---|
| `power` | włącz/wyłącz | `on: bool` |
| `brightness` | jasność globalna | `bri: 0–255` |
| `cct` | temperatura barwowa | `cct: kelwiny` |
| `rgb` | kolor | `col: [r,g,b]` |
| `transition` | płynne przejścia | `tt: ms` |
| `segments` | podział paska | `seg: [...]` |
| `effects` | wbudowane efekty | `fx: id`, `sx`, `ix` |
| `stream` | odbiór klatek UDP | — (osobny kanał) |
| `pattern` | interpreter wzorów | `pattern: {...}` |

Nieznane `caps` aplikacja **ignoruje po cichu** — nie wywala się, nie pokazuje błędu.
To pozwala trzymać w sieci urządzenia na różnych wersjach firmware'u.

---

## Geometria i przestrzeń znormalizowana

`geometry` to nie metadana kosmetyczna — to fundament systemu wzorów.

Każdy piksel ma współrzędną znormalizowaną `x ∈ [0,1]` (dla `strip`) lub
`(x, y) ∈ [0,1]²` (dla `matrix`). Generatory wzorów operują **wyłącznie** na tej
przestrzeni, nigdy na indeksach.

Konsekwencja: ten sam wzór działa identycznie na pasku 60 diod, pasku 300 diod
i matrycy 16×16. Bez tego każdy wzór trzeba by pisać per-urządzenie.

Dla nietypowych układów (pasek zawinięty w spiralę, litery) pole `map` zawiera
jawną tablicę współrzędnych.

---

## System wzorów — model warstw

Trzy możliwe podejścia zostały rozważone:

| Model | Zalety | Wady | Decyzja |
|---|---|---|---|
| Telefon renderuje, streamuje DDP | pełna dowolność, prosty | gaśnie po odłożeniu telefonu | tryb pomocniczy |
| Bajtkod + VM na ESP | maksymalna ekspresja, autonomia | duża złożoność, trudny debug | odrzucone |
| **Deklaratywny JSON + interpreter** | autonomia, WYSIWYG, prosty | ograniczony zestaw prymitywów | **wybrane** |

Wzór to stos warstw. Każda warstwa ma generator (`src`), listę modulatorów (`mod`),
tryb mieszania i krycie:

```json
{
  "schema": 1,
  "name": "ember-slow",
  "layers": [
    {
      "src": { "type": "gradient", "stops": [[0.0, "#ff2200"], [1.0, "#ffaa00"]] },
      "mod": [{ "type": "scroll", "speed": 0.15 }]
    },
    {
      "src": { "type": "noise", "scale": 3.0 },
      "mod": [{ "type": "time", "speed": 0.4 }],
      "blend": "screen",
      "opacity": 0.35
    }
  ]
}
```

**Ten sam JSON renderuje się dwukrotnie:**
- w Dart (`led_core/pattern/renderer.dart`) → podgląd na żywo w edytorze,
- w C (`firmware/pixels/pattern.c`) → wykonanie na urządzeniu.

Utrzymanie zgodności obu implementacji to koszt. W zamian dostajesz prawdziwy
WYSIWYG i wzór, który działa po odłożeniu telefonu.

Zestaw prymitywów — patrz [02 — Protokół](02-protokol.md#wzory).

---

## Autonomia urządzenia

**Twarda zasada: stan i harmonogramy mieszkają na ESP, telefon jest tylko pilotem.**

W NVS/LittleFS trzymane są:
- ostatni stan (przywracany po zaniku prądu),
- presety i wzory,
- harmonogramy (budzik, zachód słońca),
- konfiguracja sieci i token.

Aplikacja, która musi być otwarta, żeby światło działało, jest gorsza od zwykłego
włącznika. To kryterium odrzuca kilka pozornie kuszących uproszczeń.

---

## Sceny wielourządzeniowe

Główna wartość „ogólnej" aplikacji: jedna scena dotyka obu urządzeń naraz.

```json
{
  "name": "Wieczór",
  "targets": {
    "a4:cf:12:00:11:22": { "on": true, "bri": 40, "cct": 2700 },
    "a4:cf:12:00:33:44": { "on": true, "bri": 60, "pattern": "ember-slow" }
  },
  "transition_ms": 3000
}
```

Sceny są przechowywane **w aplikacji** (Drift), nie na urządzeniach — urządzenie
nie wie o istnieniu innych urządzeń. Wyzwolenie sceny to N równoległych patchy.

> Rozszerzenie na później: scena wyzwalana harmonogramem musi działać bez telefonu.
> Rozwiązanie — jedno urządzenie jako „koordynator" albo Home Assistant / Matter.

---

## Bezpieczeństwo

- Token bearer w nagłówku `Authorization`, sprawdzany również przy handshake WS.
- Weryfikacja `Origin` na WebSockecie.
- **Zakaz przekierowania portu z routera na ESP32.** Zdalny dostęp wyłącznie
  przez WireGuard/Tailscale na telefonie.
- Token generowany na urządzeniu przy provisioningu, przekazywany szyfrowanym
  kanałem BLE, przechowywany w Keychain/Keystore po stronie telefonu.

Otwarte API w sieci domowej to zaproszenie dla każdego skompromitowanego IoT-a,
który do niej trafi.
