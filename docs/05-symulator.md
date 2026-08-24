# 05 — Symulator

**To jest największy zysk na godzinę pracy w całym projekcie.** Zbuduj go zanim
zaczniesz UI.

## Po co

| Bez symulatora | Z symulatorem |
|---|---|
| cykl iteracji = 30 s flashowania | hot reload, <1 s |
| testujesz na sprzęcie, który masz | testujesz pasek 500 diod, którego nie masz |
| błędy sieci niepowtarzalne | wstrzykujesz utratę pakietów na żądanie |
| rozwój UI wymaga lutownicy | rozwój UI w pociągu |
| CI nie testuje integracji | CI odpala pełny flow |

Bez tego każda iteracja UI kosztuje wyjście do sprzętu, a to jest ten koszt,
który po dwóch tygodniach sprawia, że przestajesz iterować.

---

## Co robi

Dart CLI w `/sim`, importuje `led_core` — czyli **te same modele i ten sam kod
protokołu**, co aplikacja. Niezgodność wychodzi w testach, nie na sprzęcie.

Symulator:

1. ogłasza się przez mDNS jako `_ledctl._tcp`,
2. wystawia HTTP API i WebSocket,
3. nasłuchuje DDP na UDP,
4. renderuje wzory tym samym rendererem co aplikacja,
5. wyświetla stan paska w terminalu (ANSI truecolor).

---

## Uruchomienie

```bash
dart run sim --type=cct    --name="Salon – sufit" --port=8081
dart run sim --type=pixels --name="Biurko" --count=144 --port=8082 --ddp-port=4048
```

Parametry:

| Flaga | Domyślnie | Opis |
|---|---|---|
| `--type` | — | `cct` \| `pixels` |
| `--name` | auto | nazwa urządzenia |
| `--port` | 8080 | port HTTP/WS |
| `--ddp-port` | 4048 | port UDP |
| `--count` | 144 | liczba diod (pixels) |
| `--geometry` | `strip` | `strip` \| `matrix` |
| `--width` | — | szerokość dla `matrix` |
| `--schema` | 1 | udawana wersja schematu |
| `--latency` | 0 | sztuczne opóźnienie odpowiedzi (ms) |
| `--drop` | 0 | odsetek gubionych pakietów DDP (0–1) |
| `--flaky` | 0 | prawdopodobieństwo losowego rozłączenia WS |
| `--no-mdns` | false | wyłącz mDNS (test fallbacku po IP) |

Wyjście w terminalu:

```
Biurko  [pixels · 144 px · schema 1]  ws://192.168.1.42:8082/ws
live:false  on:true  bri:128  fx:12

████████████████████████████████████████████████████████████
                                        ^ 60 fps · 0 dropped
```

---

## Scenariusze testowe

Symulator istnieje głównie po to, żeby testować rzeczy trudne do wywołania
na sprzęcie:

```bash
# Słaba sieć — sprawdź, czy UI nie szarpie
dart run sim --type=pixels --latency=250 --drop=0.15

# Niestabilne połączenie — sprawdź reconnect z backoffem
dart run sim --type=pixels --flaky=0.05

# Discovery nie działa — sprawdź fallback po cache'owanym IP
dart run sim --type=pixels --no-mdns

# Przyszła wersja protokołu — sprawdź graceful degradation
dart run sim --type=pixels --schema=7

# Duży pasek — sprawdź fragmentację DDP i wydajność podglądu
dart run sim --type=pixels --count=600

# Matryca — sprawdź, czy wzory działają w 2D bez zmian
dart run sim --type=pixels --geometry=matrix --count=256 --width=16
```

Ostatni jest szczególnie wartościowy: jeśli wzór napisany na pasku działa na
matrycy bez zmian, przestrzeń znormalizowana z [01](01-architektura.md#geometria-i-przestrzeń-znormalizowana)
jest zaimplementowana poprawnie.

---

## Szkic implementacji

```dart
// sim/bin/sim.dart
import 'package:led_core/led_core.dart';

Future<void> main(List<String> args) async {
  final opts = parseArgs(args);

  final device = VirtualDevice(
    descriptor: buildDescriptor(opts),
    faults: FaultInjector(
      latencyMs: opts.latency,
      dropRate: opts.drop,
      flakyRate: opts.flaky,
    ),
  );

  await device.startHttpServer(opts.port);
  await device.startDdpListener(opts.ddpPort);
  if (!opts.noMdns) await device.announceMdns();

  device.frames.listen(TerminalRenderer(opts).paint);

  print('${opts.name} nasłuchuje na :${opts.port}');
}
```

`VirtualDevice` używa `PatternRenderer` z `led_core` — dokładnie tego samego,
którym aplikacja rysuje podgląd. Jedno źródło prawdy dla trzech konsumentów:
podgląd w edytorze, symulator, testy conformance.

---

## Rola w CI

```yaml
- name: Testy integracyjne
  run: |
    dart run sim --type=cct --port=8081 &
    dart run sim --type=pixels --port=8082 --count=144 &
    sleep 2
    cd app && flutter test integration_test/ --dart-define=SIM=1
```

Testy sprawdzają pełny flow: discovery → parowanie → patch stanu → broadcast
do drugiego klienta → streaming DDP → timeout `live`. Bez sprzętu, deterministycznie,
przy każdym pushu.

---

## Ograniczenia

Symulator **nie** zastąpi sprzętu w kilku miejscach — miej tego świadomość:

- rzeczywisty timing RMT i glitche przy aktywnym WiFi,
- spadki napięcia na długim pasku (kolory przechodzące w czerwień na końcu),
- realna wydajność interpretera wzorów na C3,
- zachowanie mDNS na konkretnym routerze,
- termika i pobór prądu.

Symulator służy do rozwoju **aplikacji**. Firmware i tak trzeba testować na płytce.
