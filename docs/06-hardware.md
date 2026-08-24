# 06 — Hardware

> Praca z zasilaczami sieciowymi 230 V wymaga odpowiednich kwalifikacji. Jeśli nie
> masz doświadczenia z instalacjami elektrycznymi, użyj gotowego zasilacza
> zewnętrznego w obudowie (typu „zasilacz do taśm LED") zamiast modułu otwartego,
> i zleć podłączenie do sieci osobie z uprawnieniami.

---

## Moduł 1 — sterownik pikseli (WS2812B)

### Schemat blokowy

```
  5V PSU ──┬──────────────────────────┬──── WS2812B (+5V)
           │                          │
           ├── 1000 µF ── GND         │
           │                          │
           ├── ESP32-C3 (5V/VIN)      │
           │      │                   │
           │    GPIO ──► 74AHCT125 ──► 330 Ω ──► DIN
           │              │  (Vcc=5V)
  GND ─────┴──────────────┴───────────┴──── WS2812B (GND)
```

### Trzy rzeczy, które psują większość projektów

**1. Level shifter — obowiązkowy**

ESP32-C3 wystawia 3.3 V. WS2812B przy zasilaniu 5 V oczekuje na stanie wysokim
co najmniej `0.7 × Vcc = 3.5 V`. Sygnał 3.3 V jest **poniżej** specyfikacji.

Objaw jest podstępny: często *prawie* działa. Pierwsza dioda miga losowym kolorem,
reszta jest OK — bo pierwsza dioda regeneruje sygnał dla kolejnych. Ludzie tracą
na tym dni, szukając błędu w kodzie.

Rozwiązania:
- `74AHCT125` (bufor, 4 kanały) lub `SN74HCT245` — właściwe, kilka złotych.
- Zasilanie paska z 4.5 V zamiast 5 V (obniża próg). Działa, ale zmniejsza jasność.
- Poświęcenie pierwszej diody jako konwertera poziomu. Hack, ale skuteczny.

Uwaga: układy serii **HCT**, nie HC. HC ma progi względem Vcc i nie zadziała
z wejściem 3.3 V.

**2. Zasilanie**

WS2812B pobiera ~60 mA na diodę przy pełnej bieli (20 mA × 3 kanały).

| Diod | Prąd max | Zalecany zasilacz |
|---|---|---|
| 60 | 3.6 A | 5 V / 5 A |
| 144 | 8.6 A | 5 V / 10 A |
| 300 | 18 A | 5 V / 20 A + zasilanie z obu stron |

W praktyce rzadko świecisz pełną bielą, ale zasilacz dobieraj na maksimum —
inaczej przy pierwszym „white 100%" dostaniesz brownout i reset ESP.

**Wstrzykiwanie zasilania co 1–2 m.** Miedź w taśmie jest cienka; bez tego koniec
paska ma zauważalnie niższe napięcie i biel przechodzi w pomarańcz. Przewód
zasilający prowadź równolegle do taśmy (min. 1.5 mm² dla dłuższych odcinków).

**Wspólna masa ESP i paska jest obowiązkowa.** Bez tego sygnał danych nie ma
punktu odniesienia i pasek zachowuje się losowo.

**3. Elementy ochronne**

- **Kondensator 1000 µF / 6.3 V+** na wejściu zasilania paska, jak najbliżej
  pierwszej diody. Tłumi udar przy włączeniu.
- **Rezystor 330–470 Ω** szeregowo na linii danych, przy stronie ESP. Tłumi
  odbicia i chroni pierwszą diodę.
- Linia danych krótka — powyżej ~50 cm rozważ transmisję różnicową lub
  przeniesienie sterownika bliżej paska.

### Wybór diod

Rozważ **WS2812B-V5** lub **SK6812** zamiast klasycznego WS2812B:

| | WS2812B | WS2812B-V5 | SK6812 |
|---|---|---|---|
| Próg logiczny | 0.7 × Vcc | łagodniejszy | łagodniejszy |
| Ochrona odwrotnej polaryzacji | nie | tak | nie |
| Wariant RGBW | nie | nie | tak |

SK6812 RGBW ma dodatkową diodę białą — dużo lepsza biel niż mieszanie RGB,
kosztem 4 bajtów na piksel zamiast 3.

---

## Moduł 2 — sterownik CCT (2× MOSFET)

### Schemat blokowy

```
  12V/24V PSU ──┬────────────────── taśma CCT (+)
                │
                ├── DC-DC → 5V/3.3V ── ESP32-C3
                │
   GPIO_WARM ──►│ gate driver ──► MOSFET N ──► taśma (kanał ciepły −)
   GPIO_COLD ──►│ gate driver ──► MOSFET N ──► taśma (kanał zimny −)
                │
  GND ──────────┴────────────────────────────────────────
```

Taśma CCT ma wspólną anodę (+) i dwa katody. MOSFETy **N-kanałowe po stronie
niskiej** (low-side switching) — najprostszy i wystarczający układ.

### Dobór MOSFET-a

Kluczowe: MOSFET musi się w pełni otwierać przy napięciu bramki 3.3 V.
Szukaj **logic-level** z `V_GS(th)` poniżej 2 V i `R_DS(on)` podanym przy 4.5 V.

Kandydaci: `IRLZ44N` (klasyk, ale przy 3.3 V pracuje na granicy), `IRLB8721`,
`AO3400` (SMD, do małych mocy).

**Zalecane: gate driver** (`MCP1407`, `TC4427`) między GPIO a bramką. Przy PWM
19.5 kHz i pojemności bramki rzędu nF, GPIO nie wyrabia z przeładowaniem —
MOSFET spędza za dużo czasu w obszarze liniowym i grzeje się. Objaw: MOSFET
gorący mimo niewielkiego obciążenia.

Alternatywa bez drivera: rezystor 100–220 Ω szeregowo na bramce plus 10 kΩ
bramka→masa (pull-down, żeby MOSFET nie „pływał" przed inicjalizacją GPIO).

### Radiator

`P = I² × R_DS(on)`. Przy 3 A i `R_DS(on)` 20 mΩ to 0.18 W — radiator zbędny.
Przy 8 A i 50 mΩ to 3.2 W — radiator obowiązkowy.

---

## GPIO — ESP32-C3

Sugerowany przydział (dostosuj do konkretnej płytki):

| Funkcja | GPIO | Uwagi |
|---|---|---|
| Dane WS2812B | 3 | dowolny wolny, przez level shifter |
| PWM ciepły | 4 | LEDC kanał 0 |
| PWM zimny | 5 | LEDC kanał 1 |
| Przycisk reset konfiguracji | 9 | = BOOT, pull-up wewnętrzny |
| LED statusu | 8 | wbudowana na wielu płytkach |

**Unikaj:** GPIO 11–17 (SPI flash), GPIO 18/19 (USB-JTAG na wielu płytkach —
zajęcie ich odcina `idf.py monitor` przez USB).

GPIO 9 to strap pin — jeśli jest zwarty do masy przy starcie, płytka wchodzi
w tryb bootloadera. Do przycisku użytkownika nadaje się, ale czytaj go dopiero
po starcie systemu.

---

## BOM — punkt wyjścia

### Sterownik pikseli

| Element | Ilość | Uwagi |
|---|---|---|
| ESP32-C3 (np. Super Mini, DevKitM-1) | 1 | |
| 74AHCT125 | 1 | koniecznie HCT |
| Kondensator 1000 µF / 10 V | 1 | elektrolit, low-ESR |
| Kondensator 100 nF | 2 | odsprzęgające przy IC |
| Rezystor 330 Ω | 1 | linia danych |
| Zasilacz 5 V | 1 | patrz tabela prądów |
| Złącze śrubowe / JST | wg potrzeb | |
| Taśma WS2812B / SK6812 | wg potrzeb | |

### Sterownik CCT

| Element | Ilość | Uwagi |
|---|---|---|
| ESP32-C3 | 1 | |
| MOSFET logic-level N | 2 | + radiator wg mocy |
| Gate driver (MCP1407/TC4427) | 2 | zalecane |
| Rezystor 10 kΩ | 2 | pull-down bramki |
| Rezystor 100 Ω | 2 | szeregowy bramki (bez drivera) |
| Przetwornica DC-DC 12/24 V → 5 V | 1 | min. 1 A |
| Kondensator 470 µF | 1 | wejście zasilania |
| Zasilacz 12 V lub 24 V | 1 | wg taśmy |
| Taśma CCT | wg potrzeb | |

---

## Kolejność uruchamiania

Nie podłączaj wszystkiego naraz. Kolejność, która oszczędza spalone elementy:

1. Sam ESP32-C3 przez USB. Zweryfikuj `idf.py flash monitor`, WiFi, WebSocket.
2. Krótki pasek (8–16 diod) zasilany z USB, **z level shifterem**. Jedna dioda
   na biało, potem tęcza.
3. Docelowy zasilacz, docelowa długość paska. Zmierz napięcie na końcu taśmy
   przy pełnej bieli — spadek >0.5 V oznacza konieczność wstrzyknięcia zasilania.
4. Moduł CCT osobno, na małym odcinku taśmy, z amperomierzem.
5. Dopiero na końcu montaż docelowy.

Zawsze miej dostęp do USB po montażu — OTA jest wygodne, ale gdy firmware nie
wstaje, kabel jest jedynym wyjściem. Rollback A/B z [04](04-firmware.md#ota)
znacząco zmniejsza szansę, że będzie potrzebny.
