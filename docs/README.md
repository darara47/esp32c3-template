# ledctl

System sterowania oświetleniem LED oparty o ESP32-C3 i aplikację mobilną Flutter.

Obsługiwane urządzenia:

| Urządzenie | Sprzęt | Zdolności |
|---|---|---|
| `cct` | ESP32-C3 + 2× MOSFET | biel ciepła/zimna, ściemnianie |
| `pixels` | ESP32-C3 + WS2812B | RGB, segmenty, efekty, wzory, streaming |

Architektura jest zbudowana wokół **modelu zdolności (capabilities)** — urządzenie
opisuje siebie, aplikacja składa UI dynamicznie. Dodanie trzeciego typu urządzenia
nie wymaga zmian w warstwie widoków.

---

## Dokumentacja

| Dokument | Zawartość |
|---|---|
| [01 — Architektura](docs/01-architektura.md) | model zdolności, warstwy, decyzje projektowe |
| [02 — Protokół](docs/02-protokol.md) | WebSocket, DDP, discovery, auth, schematy |
| [03 — Aplikacja](docs/03-aplikacja.md) | struktura Flutter, stan, drivery, edytor wzorów |
| [04 — Firmware](docs/04-firmware.md) | ESP-IDF, taski, LEDC, RMT, NVS, OTA |
| [05 — Symulator](docs/05-symulator.md) | wirtualne urządzenia bez sprzętu |
| [06 — Hardware](docs/06-hardware.md) | schematy, zasilanie, level shifter, BOM |
| [07 — Roadmapa](docs/07-roadmapa.md) | kolejność prac, kamienie milowe, definition of done |

---

## Struktura repo

```
ledctl/
├── app/                    Flutter — aplikacja mobilna
├── packages/
│   └── led_core/           Dart — modele, drivery, protokoły, renderer wzorów
├── firmware/
│   ├── common/             komponenty współdzielone (ws_server, discovery, nvs_cfg)
│   ├── cct/                ESP-IDF — sterownik CCT
│   └── pixels/             ESP-IDF — sterownik WS2812B
├── schema/                 JSON Schema — źródło prawdy dla protokołu
├── sim/                    symulator urządzeń (Dart CLI)
└── tools/                  skrypty pomocnicze
```

`led_core` jest współdzielony przez aplikację i symulator. Dzięki temu niezgodność
protokołu wychodzi w testach jednostkowych, a nie na sprzęcie.

---

## Wymagania

| Narzędzie | Wersja | Uwagi |
|---|---|---|
| Flutter | 3.x stable | `flutter doctor` musi być czysty |
| Dart | dołączony do Fluttera | |
| Melos | `dart pub global activate melos` | zarządzanie monorepo |
| ESP-IDF | v5.x | instalacja przez VS Code extension lub `install.sh` |
| Python | 3.9+ | wymagany przez ESP-IDF |
| CMake, Ninja | | instalowane razem z IDF |

> Wersje pakietów Dart i komponentów IDF podane w dokumentach są punktem wyjścia —
> zweryfikuj aktualne przy pierwszym `pub get` / `idf.py reconfigure`.

---

## Quickstart — pierwsze 30 minut, bez sprzętu

```bash
# 1. Bootstrap monorepo
dart pub global activate melos
melos bootstrap

# 2. Odpal dwa wirtualne urządzenia (osobne terminale)
dart run sim --type=cct    --name="Salon – sufit" --port=8081
dart run sim --type=pixels --name="Biurko" --count=144 --port=8082

# 3. Odpal aplikację
cd app && flutter run
```

Aplikacja powinna wykryć oba urządzenia przez mDNS i wyrenderować dla nich
różne UI — suwak temperatury barwowej dla `cct`, color picker i listę efektów
dla `pixels`.

Jeśli discovery nie działa (typowe na emulatorze Androida), dodaj urządzenie
ręcznie: **Ustawienia → Dodaj urządzenie → `ws://<ip-hosta>:8081`**.

---

## Quickstart — firmware

```bash
. $HOME/esp/esp-idf/export.sh          # aktywacja środowiska IDF

cd firmware/cct
idf.py set-target esp32c3
idf.py build
idf.py -p /dev/ttyUSB0 flash monitor   # Ctrl+] aby wyjść
```

Pierwsze uruchomienie wchodzi w tryb provisioningu BLE — urządzenie ogłasza się
jako `PROV_xxxxxx`. Sparuj przez aplikację (**➕ → Paruj nowe urządzenie**) lub
przez referencyjne narzędzie `esp_prov.py` z ESP-IDF.

Reset konfiguracji: przytrzymaj przycisk BOOT (GPIO z `LEDCTL_PROV_RESET_GPIO`)
przez 5 s po starcie albo `idf.py erase-flash`.

---

## Konwencje

- **Język kodu i komentarzy:** angielski. Dokumentacja: polski.
- **Commity:** Conventional Commits (`feat(app):`, `fix(firmware/pixels):`).
- **Branche:** `main` zawsze buildowalny, praca na `feat/*`.
- **Wersjonowanie protokołu:** pole `schema` w deskryptorze urządzenia, patrz
  [02 — Protokół](docs/02-protokol.md#wersjonowanie).
