# 02 — Protokół

Wersja: `schema: 1`

---

## Podsumowanie portów

| Port | Protokół | Zastosowanie |
|---|---|---|
| 80 | HTTP + WebSocket | sterowanie, deskryptor, presety, OTA |
| 4048 | UDP (DDP) | streaming klatek pikseli |
| 5353 | mDNS | discovery |

---

## Discovery

### mDNS

Urządzenia ogłaszają usługę `_ledctl._tcp.local` z rekordami TXT:

```
_ledctl._tcp.local
  ├── port: 80
  └── TXT:
        id=a4:cf:12:00:11:22
        model=ledctl-pixels
        fw=0.1.0
        schema=1
```

Aplikacja nasłuchuje równolegle na `_wled._tcp.local`, żeby wykrywać urządzenia
z firmware'em WLED.

### Fallback — obowiązkowy

mDNS na Androidzie bywa niezawodny inaczej: potrafi milczeć przy oszczędzaniu
energii, na sieciach z izolacją klientów, na emulatorze. **Zawsze:**

1. Cache'uj ostatnie znane IP + MAC każdego sparowanego urządzenia (Drift).
2. Przy starcie próbuj bezpośrednio pod cache'owanym IP, równolegle z mDNS.
3. Udostępnij ręczne dodanie po IP/hostname.
4. Zarezerwuj IP w routerze po MAC — zalecane w dokumentacji użytkownika.

Bez punktu 2 aplikacja wygląda na zepsutą przy pierwszym uruchomieniu w nowej sieci.

### iOS — Info.plist

Bez tego skanowanie zwraca pustą listę **bez błędu**:

```xml
<key>NSLocalNetworkUsageDescription</key>
<string>Wyszukiwanie sterowników oświetlenia w sieci lokalnej.</string>
<key>NSBonjourServices</key>
<array>
  <string>_ledctl._tcp</string>
  <string>_wled._tcp</string>
</array>
```

---

## HTTP API

| Metoda | Ścieżka | Opis |
|---|---|---|
| `GET` | `/api/device` | deskryptor zdolności |
| `GET` | `/api/state` | pełny stan |
| `POST` | `/api/state` | patch stanu (JSON merge) |
| `GET` | `/api/presets` | lista presetów |
| `PUT` | `/api/presets/{id}` | zapis presetu |
| `DELETE` | `/api/presets/{id}` | usunięcie |
| `GET` | `/api/patterns` | lista wzorów |
| `PUT` | `/api/patterns/{id}` | zapis wzoru |
| `POST` | `/api/ota` | upload binarki |
| `GET` | `/api/claim` | jednorazowy odbiór tokenu po sparowaniu |
| `GET` | `/ws` | upgrade do WebSocket |

Autoryzacja: `Authorization: Bearer <token>` na każdym żądaniu — **poza**
`/api/claim`, które celowo nie wymaga tokenu (skąd by go klient wziął przed
pierwszym razem?) i zamiast tego jest jednorazowe: pierwsze wywołanie zwraca
`{"id","token"}` i trwale zamyka się na kolejne (`403 already_claimed`), aż do
ponownego provisioningu. Patrz [04 — Firmware](04-firmware.md#provisioning-ble).

HTTP służy głównie do operacji jednorazowych i kompatybilności z WLED.
**Sterowanie w czasie rzeczywistym idzie przez WebSocket.**

---

## WebSocket

Endpoint: `ws://<host>/ws`
Token przekazywany w nagłówku handshake (lub jako `?token=` gdy klient nie może
ustawić nagłówka).

### Ramka: serwer → klient

Po połączeniu urządzenie wysyła deskryptor, potem pełny stan, potem już tylko
zmiany. Każda zmiana jest broadcastowana do **wszystkich** podłączonych klientów —
stąd darmowa synchronizacja między dwoma telefonami i fizycznym przyciskiem.

```json
{ "t": "device", "d": { "schema": 1, "id": "...", "caps": [...] } }
{ "t": "state",  "d": { "on": true, "bri": 128, "cct": 3200 } }
{ "t": "patch",  "d": { "bri": 200 } }
{ "t": "error",  "d": { "code": "unsupported_cap", "msg": "cct" } }
```

### Ramka: klient → serwer

```json
{ "t": "patch", "id": 42, "d": { "bri": 200, "tt": 400 } }
{ "t": "get" }
{ "t": "ping" }
```

`id` jest opcjonalny; jeśli obecny, serwer odpowie `{"t":"ack","id":42}`.
Używaj go przy operacjach, które muszą dojść (zapis presetu), pomijaj przy
suwakach.

### Stan — pełny model

```json
{
  "on": true,
  "bri": 128,
  "tt": 400,

  "cct": 3200,

  "col": [255, 120, 40],
  "fx": 12,
  "sx": 128,
  "ix": 200,
  "pal": 3,

  "seg": [
    { "id": 0, "start": 0, "stop": 72, "on": true, "bri": 255, "col": [255,0,0], "fx": 0 },
    { "id": 1, "start": 72, "stop": 144, "on": true, "bri": 180, "col": [0,0,255], "fx": 12 }
  ],

  "pattern": "ember-slow",

  "live": false
}
```

`live: true` oznacza, że urządzenie odbiera strumień DDP i ignoruje `fx`/`pattern`.
Ustawiane automatycznie przez firmware, wraca na `false` po timeoucie (patrz niżej).

### Reconnect

Klient odpowiada za ponowne łączenie z **exponential backoff**: 0.5 s, 1 s, 2 s,
4 s, 8 s, max 30 s, z jitterem ±20%. Po udanym reconnect klient wysyła `{"t":"get"}`
żeby zresynchronizować stan — nie zakłada, że lokalny stan jest aktualny.

Heartbeat: klient wysyła `ping` co 15 s, serwer odpowiada `pong`. Brak `pong`
przez 45 s → zamknij socket i zacznij reconnect.

---

## DDP — streaming klatek

**Distributed Display Protocol**, UDP port 4048. Standard używany m.in. przez WLED
i xLights, więc Twoje urządzenie od razu współpracuje z istniejącymi narzędziami.

### Nagłówek (10 bajtów)

```
 offset  rozmiar  pole
   0       1      flags     0x41 = ver1 | PUSH  (0x40 bez PUSH)
   1       1      sequence  0–15, cyklicznie; 0 = brak numeracji
   2       1      type      0x0B = RGB 8-bit per kanał
   3       1      dest id   1 = domyślne wyjście
   4       4      offset    offset w bajtach (big-endian)
   8       2      length    długość danych w bajtach (big-endian)
```

Dane: `[R,G,B, R,G,B, ...]`, po 3 bajty na piksel.

### Fragmentacja

Utrzymuj datagram **poniżej 1400 bajtów** (bezpiecznie pod typowym MTU 1500 minus
nagłówki). To daje ~460 pikseli na pakiet. Przy dłuższych paskach dziel na pakiety
z rosnącym `offset`, flagę PUSH ustaw **tylko na ostatnim**.

### Zachowanie firmware'u

- Pierwszy pakiet DDP → `live = true`, broadcast patcha po WS.
- Brak pakietów przez **2500 ms** → `live = false`, powrót do `fx`/`pattern`.
- Jasność globalna (`bri`) **jest** stosowana do strumienia. Kolor `col` nie.
- Pakiety poza zakresem geometrii są odrzucane po cichu, nie logowane
  (przy 60 fps zalałyby log).

### Rate limiting po stronie aplikacji

Nadawaj max `stream.maxFps` z deskryptora. Nie kompensuj zgubionych klatek
retransmisją — to mija się z celem UDP.

---

## Wzory

### Struktura

```json
{
  "schema": 1,
  "id": "ember-slow",
  "name": "Żar",
  "layers": [ /* od dołu do góry */ ]
}
```

### Warstwa

```json
{
  "src":     { "type": "...", /* parametry generatora */ },
  "mod":     [ { "type": "...", /* parametry */ } ],
  "blend":   "normal | add | screen | multiply",
  "opacity": 0.0–1.0
}
```

### Generatory (`src`)

| `type` | Parametry | Opis |
|---|---|---|
| `solid` | `color` | jednolity kolor |
| `gradient` | `stops: [[pos, hex], ...]` | interpolacja w OkLab |
| `palette` | `id`, `spread` | paleta cykliczna |
| `noise` | `scale`, `octaves` | szum Perlina 1D/2D |
| `sparkle` | `color`, `density`, `decay` | losowe błyski |
| `comet` | `color`, `len`, `pos` | kometa z ogonem |
| `plasma` | `scale`, `hueShift` | klasyczna plazma |

### Modulatory (`mod`)

| `type` | Parametry | Opis |
|---|---|---|
| `scroll` | `speed` | przesuwanie w przestrzeni (obr./s) |
| `time` | `speed` | animowanie osi czasu generatora |
| `pulse` | `freq`, `depth`, `shape` | oddech jasności |
| `mirror` | `axis` | odbicie |
| `wave` | `freq`, `amp` | falowanie współrzędnych |
| `clamp` | `min`, `max` | ograniczenie zakresu |
| `hue` | `shift` | przesunięcie barwy |
| `audio` | `band`, `gain` | reakcja na dźwięk (wymaga strumienia FFT) |

### Kontrakt renderera

Funkcja generatora ma sygnaturę konceptualną:

```
color sample(float x, float y, float t)
```

gdzie `x, y ∈ [0,1]` (przestrzeń znormalizowana), `t` w sekundach od startu wzoru.

**Obie implementacje (Dart i C) muszą dawać identyczny wynik** dla tych samych
argumentów. Zabezpieczenie: zestaw testów porównawczych w `tools/pattern_conformance/`
generujący złote wartości z Dart i weryfikujący je testem jednostkowym w C.

Interpolacja kolorów w gradientach: **OkLab**, nie sRGB. Interpolacja liniowa w RGB
daje szarawe przejścia w połowie (klasyczny problem czerwony→niebieski).

---

## Konwersje i krzywe

### Temperatura barwowa — interpoluj w miredach

```
mired = 1_000_000 / kelwin
```

Przejście 2700 K → 6500 K liniowo w kelwinach wygląda nierówno, bo percepcja
odpowiada odwrotności temperatury. Interpolacja w miredach jest równomierna.

Mapowanie na dwa kanały MOSFET (ciepły `w`, zimny `c`):

```
ratio = (mired - mired_max_temp) / (mired_min_temp - mired_max_temp)   // 0..1
w = brightness * ratio
c = brightness * (1 - ratio)
```

> Uwaga: to mapowanie utrzymuje **stałą sumę mocy**. Alternatywa („constant
> brightness" vs „constant power") — patrz komentarz w `firmware/cct/cct.c`,
> decyzja zależy od tego, czy chcesz żeby środek zakresu był jaśniejszy.

### Gamma

Wszystkie wartości jasności przekazywane w protokole są **percepcyjne** (liniowe
dla oka). Firmware stosuje gammę ~2.2 przed wypełnieniem PWM/bufora LED.

Aplikacja **nie** stosuje gammy — inaczej zostanie zaaplikowana dwukrotnie.

---

## Kompatybilność z WLED

`WledDriver` mapuje protokół WLED na wewnętrzny model:

| ledctl | WLED |
|---|---|
| `GET /api/device` | `GET /json/info` → syntetyzowany deskryptor |
| `GET /api/state` | `GET /json/state` |
| `POST /api/state` | `POST /json/state` |
| WebSocket `/ws` | `ws://<host>/ws` (kompatybilny format) |
| DDP 4048 | DDP 4048 (natywnie wspierany) |

Deskryptor dla WLED jest syntetyzowany po stronie aplikacji na podstawie `/json/info`:
`caps` ustawiane na `["power","brightness","rgb","segments","effects","stream"]`,
`geometry.count` z `info.leds.count`. Zdolność `pattern` **nie** jest zgłaszana —
WLED nie ma interpretera wzorów.

---

## Wersjonowanie

Pole `schema` w deskryptorze urządzenia i w definicji wzoru.

**Reguły zgodności:**

- Dodanie nowego `cap` — **nie** podbija `schema`. Klient ignoruje nieznane.
- Dodanie opcjonalnego pola stanu — **nie** podbija `schema`.
- Zmiana znaczenia lub typu istniejącego pola — **podbija** `schema`.
- Usunięcie pola — **podbija** `schema`.

Aplikacja obsługuje `schema` od 1 do aktualnego. Przy wyższym niż znany —
pokazuje urządzenie z komunikatem „wymaga aktualizacji aplikacji" zamiast
próbować parsować.

W praktyce będziesz miał w sieci urządzenia na trzech różnych wersjach firmware'u
jednocześnie. Ta sekcja jest po to, żeby to nie bolało.
