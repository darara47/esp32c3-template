# 07 — Roadmapa

Kolejność jest dobrana tak, żeby **każdy etap kończył się czymś działającym**
i żeby ryzykowne decyzje odsunąć do momentu, w którym masz dane do ich podjęcia.

---

## M0 — Fundament (bez sprzętu)

**Cel:** monorepo, modele, symulator CCT, aplikacja pokazująca suwak.

- [ ] Monorepo + Melos, `flutter create app`, `dart create packages/led_core`
- [ ] `led_core`: `DeviceDescriptor`, `DeviceState`, `Capability`, `StatePatch` (freezed)
- [ ] `/schema`: JSON Schema deskryptora i stanu
- [ ] `MockDriver` + testy jednostkowe modeli
- [ ] `sim` — wirtualne urządzenie CCT (HTTP + WS + mDNS)
- [ ] Aplikacja: discovery, lista urządzeń, ekran z rejestrem widgetów
- [ ] `CctSlider` + `BrightnessSlider` + `PowerTile`

**Definition of done:** `dart run sim --type=cct` + `flutter run` → suwak
temperatury barwowej steruje symulatorem, zmiana widoczna w drugim kliencie.

**Dlaczego CCT pierwszy:** dwa suwaki i toggle. Cały szkielet — discovery,
driver, WebSocket, reconnect, optymistyczny UI — jest ten sam co dla pikseli,
ale bez rozpraszania się na kolory i efekty. Szybka wygrana, która weryfikuje
architekturę.

---

## M1 — Pierwszy sprzęt: CCT

**Cel:** fizyczna taśma CCT sterowana z telefonu.

- [x] `firmware/common`: NVS, serwer WS, broadcast, token
- [x] `firmware/cct`: LEDC, mapowanie mired, gamma, temporal dithering
- [x] Provisioning BLE + ekran parowania w aplikacji
- [x] Przywracanie stanu po restarcie
- [x] Partycje OTA + rollback

Zweryfikowane end-to-end na fizycznym ESP32-C3 + telefonie (2026-08-25):

- [x] Parowanie: świeże urządzenie → BLE → WiFi → `/api/claim` → sterowanie z apki.
- [x] Reset: przytrzymanie BOOT 5 s faktycznie wraca do trybu parowania.
- [ ] Zanik i powrót zasilania (odłączenie od prądu, nie restart przez USB) — jeszcze nie przetestowane wprost, choć restart przez `esp_restart()`/OTA już potwierdza odtwarzanie stanu z NVS.
- [ ] OTA: upload binarki przez `/api/ota` na żywym urządzeniu — kod przetestowany logicznie, brak jeszcze realnego przebiegu.

Po drodze znalezione i naprawione na sprzęcie (nie widoczne w samej kompilacji):
limit 8 zarejestrowanych endpointów `esp_http_server` (podbity do 16 po
dodaniu `/api/claim`), oraz niezgodność `flutter_esp_ble_prov` z nowszym AGP
(pakiet zvendorowany i załatany w `third_party/`, patrz jego `PATCHES.md`).

**Definition of done:** taśma reaguje na suwak z opóźnieniem <50 ms, ściemnianie
do 1% jest płynne, stan wraca po zaniku zasilania, OTA działa.

**Ryzyko:** dithering. Jeśli w dolnym zakresie widać skoki — patrz
[04](04-firmware.md#temporal-dithering--konieczny). Zweryfikuj zanim zamontujesz
taśmę na stałe.

---

## M2 — Piksele przez WLED

**Cel:** drugi typ urządzenia w aplikacji, bez pisania firmware'u.

- [ ] `WledDriver` — mapowanie `/json/info` → deskryptor, `/json/state` → stan
- [ ] `ColorWheel` (własny `CustomPainter`)
- [ ] `EffectList`, `SegmentEditor`
- [ ] `sim --type=pixels`
- [ ] Nasłuch `_wled._tcp` w discovery

**Definition of done:** WLED na fizycznym pasku sterowany z tej samej aplikacji
co CCT, oba urządzenia widoczne na jednej liście z różnym UI.

**To jest moment weryfikacji architektury.** Jeśli dodanie drugiego typu urządzenia
wymagało zmian w `device_screen.dart` — model zdolności jest źle zaimplementowany
i lepiej to naprawić teraz niż przy trzecim urządzeniu.

---

## M3 — Sceny

**Cel:** jedno dotknięcie zmienia oba urządzenia naraz.

- [ ] Drift: tabele `devices`, `scenes`
- [ ] Edytor sceny — zapisz aktualny stan wszystkich urządzeń
- [ ] Wyzwalanie sceny (N równoległych patchy)
- [ ] Przejścia (`transition_ms`)

**Definition of done:** scena „Wieczór" ustawia CCT na 2700 K / 40% i pasek na
ciepły efekt, płynnie, w 3 sekundy.

To jest pierwszy moment, w którym aplikacja robi coś, czego nie robi WLED.
Warto tu być wcześnie — daje motywację na dalsze etapy.

---

## M4 — Własny firmware pikseli

**Cel:** zastąpienie WLED, przygotowanie pod wzory.

- [ ] `firmware/pixels`: `led_strip` RMT+DMA, double buffering
- [ ] Model tasków (`net`, `render`, `output`)
- [ ] Kilka efektów wbudowanych (solid, rainbow, comet, sparkle)
- [ ] Segmenty
- [ ] `NativeDriver` w aplikacji
- [ ] Odbiornik DDP + timeout `live`

**Definition of done:** pasek działa na własnym firmware, `WledDriver` nadal
działa dla starszych urządzeń, aplikacja nie zauważa różnicy poza dostępnymi `caps`.

**Podejmij decyzję świadomie:** jeśli po M2 okaże się, że WLED robi wszystko,
czego potrzebujesz poza wzorami — rozważ pozostanie przy WLED i dodanie wzorów
jako strumień DDP z telefonu (M5, wariant A). Własny firmware to kilka tygodni.

---

## M5 — Edytor wzorów

**Cel:** to, czego nie ma żaden gotowy system.

- [ ] `led_core/pattern`: generatory + modulatory + blending (Dart)
- [ ] `PatternRenderer` — podgląd na `CustomPainter`, 60 fps
- [ ] Edytor warstw: dodaj/usuń/przestaw, parametry, tryby mieszania
- [ ] Interpreter w C (`firmware/pixels/pattern.c`)
- [ ] Testy conformance Dart ↔ C
- [ ] LittleFS: zapis wzorów na urządzeniu
- [ ] Biblioteka wzorów w aplikacji (Drift + miniatury)

**Definition of done:** wzór zbudowany w aplikacji wygląda identycznie w podglądzie
i na pasku, działa po zamknięciu aplikacji, przeżywa restart urządzenia.

**Największe ryzyko projektu.** Rozbij na dwa kroki:
1. Renderer w Dart + streaming DDP → działa od razu, gaśnie po odłożeniu telefonu.
2. Interpreter w C → autonomia.

Krok 1 daje wartość natychmiast i pozwala zweryfikować, czy zestaw prymitywów
jest wystarczająco ekspresyjny, **zanim** zainwestujesz w implementację w C.

---

## M6 — Tryby czasu rzeczywistego

- [ ] Music reactive — FFT na telefonie, DDP do paska
- [ ] Ambilight — capture ekranu, uśrednianie stref
- [ ] Modulator `audio` we wzorach

FFT liczysz na telefonie, nie na C3 — masz tam dwa rzędy wielkości więcej mocy.
Na urządzenie idą gotowe klatki albo współczynniki pasm.

---

## M7 — Autonomia i integracje

- [ ] Harmonogramy na urządzeniu (SNTP + budzik + symulacja wschodu)
- [ ] Geofencing w aplikacji
- [ ] Synchronizacja wielu pasków (NTP + timestamp w nagłówku klatki)
- [ ] Matter (`esp-matter`) — Apple Home / Google / Alexa

**Matter jest wart rozważenia wcześniej.** Wystawiasz urządzenie jako standardową
żarówkę: dostajesz zdalny dostęp przez cudzy hub, integrację z asystentami
i sterowanie głosem — bez budowania backendu. Twoja aplikacja robi wtedy tylko to,
czego standard nie obejmuje (wzory, segmenty, edytor).

Koszt: `esp-matter` to spory komponent, wymaga miejsca we flashu i osobnej ścieżki
provisioningu.

---

## Zdalny dostęp

Nie ma osobnego kamienia milowego, bo **nie wymaga kodu**.

- **Projekt prywatny:** Tailscale albo WireGuard na telefonie. Ta sama aplikacja
  LAN-owa działa spoza domu. Zero backendu, zero kont, pełne szyfrowanie.
- **Produkt dla innych:** MQTT over TLS (EMQX/HiveMQ), urządzenie wychodzi na
  zewnątrz, NAT nie przeszkadza. To wtedy jest osobny projekt — auth, konta,
  provisioning tożsamości.

**Nigdy** przekierowanie portu z routera na ESP32.

---

## Czego nie robić

| Pokusa | Dlaczego nie |
|---|---|
| Zacząć od edytora wzorów | Nie wiesz jeszcze, czego potrzebuje. Najpierw używaj systemu. |
| Pominąć symulator | Każda iteracja UI kosztuje 30 s flashowania. Po dwóch tygodniach przestajesz iterować. |
| Pisać własny firmware od razu | WLED w M2 pokaże Ci, co naprawdę jest potrzebne. |
| WebSocket do streamingu klatek | Head-of-line blocking → widoczne zacinanie. |
| Trzymać stan w aplikacji | Światło musi działać bez telefonu. |
| BLE jako główny kanał | Jeden klient, brak automatyzacji, słaby zasięg. |
| Zoptymalizować interpreter przed pomiarem | C3 policzy 144 px × 3 warstwy × 60 fps bez wysiłku. Zmierz, potem optymalizuj. |

---

## Pierwszy krok, konkretnie

```bash
mkdir ledctl && cd ledctl
git init
dart pub global activate melos
```

Potem `packages/led_core` z modelem `Capability` i `DeviceState`. Do pierwszego
działającego ekranu w aplikacji nie potrzebujesz w ogóle sprzętu — a gdy już
podłączysz ESP, będziesz debugować jedną warstwę zamiast trzech naraz.
