# 04 — Firmware (ESP-IDF)

Target: **ESP32-C3** (RISC-V, single core, 160 MHz)
Framework: **ESP-IDF v5.x**, czysty C

## Dlaczego ESP-IDF, nie Arduino

Arduino-ESP32 to i tak IDF pod spodem, tylko z warstwą abstrakcji, która ukrywa
dokładnie te rzeczy, które przy strumieniowaniu klatek mają znaczenie: przypinanie
tasków, priorytety FreeRTOS, `esp_timer` z rozdzielczością µs, konfiguracja RMT/DMA,
partycje OTA. Przy prostym projekcie Arduino wygrywa wygodą; tutaj przegrywa.

---

## Komponenty

| Funkcja | Komponent | Źródło |
|---|---|---|
| LED adresowalne | `espressif/led_strip` | component registry, backend RMT+DMA |
| PWM (CCT) | `driver/ledc` | wbudowany |
| HTTP + WebSocket | `esp_http_server` | wbudowany, `httpd_ws_*` |
| UDP | socket BSD / lwIP | wbudowany |
| mDNS | `espressif/mdns` | component registry |
| JSON | `cJSON` | wbudowany |
| Konfiguracja | `nvs_flash` | wbudowany |
| Wzory, presety | `joltwallet/littlefs` | SPIFFS jest deprecated |
| Provisioning | `wifi_provisioning` (BLE) | wbudowany |
| OTA | `esp_https_ota` | wbudowany |
| Czas | `esp_sntp` | wbudowany |

Instalacja komponentów z registry:

```bash
idf.py add-dependency "espressif/led_strip^3.0.0"
idf.py add-dependency "espressif/mdns^1.2.0"
idf.py add-dependency "joltwallet/littlefs^1.14.0"
```

---

## Struktura

```
firmware/
├── common/                    komponent współdzielony
│   ├── include/
│   │   ├── ledctl_state.h     model stanu, patch, serializacja
│   │   ├── ledctl_ws.h        serwer WS + broadcast
│   │   └── ledctl_cfg.h       NVS, token, provisioning
│   └── src/
├── cct/
│   ├── main/
│   │   ├── main.c
│   │   ├── cct.c              LEDC, mapowanie mired → 2 kanały, dithering
│   │   └── schedule.c         harmonogramy
│   └── sdkconfig.defaults
└── pixels/
    ├── main/
    │   ├── main.c
    │   ├── strip.c            led_strip, double buffer
    │   ├── pattern.c          interpreter wzorów
    │   ├── effects.c          efekty wbudowane
    │   └── ddp.c              odbiornik UDP
    └── sdkconfig.defaults
```

---

## Model tasków

### `pixels`

| Task | Priorytet | Opis |
|---|---|---|
| `net` | 5 | HTTP/WS, obsługa patchy |
| `ddp_rx` | 8 | odbiór UDP, zapis do bufora |
| `render` | 6 | interpreter wzorów / efekty → bufor |
| `output` | 10 | wypchnięcie bufora przez RMT, timing |

Bufory: **double buffering**. `render`/`ddp_rx` pisze do back buffera, `output`
zamienia wskaźniki pod mutexem i wypycha front. Bez tego zobaczysz tearing.

`output` odpalany z `esp_timer` co `1000/fps` ms. Nie z `vTaskDelay` — jitter
sterty milisekund jest widoczny jako nierówna animacja.

### `cct`

Prostszy: `net` + `fade` (interpolacja przejść, ~50 Hz) + `schedule`.

---

## WS2812B na C3

### Sterownik

**RMT z DMA** przez `espressif/led_strip`:

```c
led_strip_config_t strip_cfg = {
    .strip_gpio_num = CONFIG_LEDCTL_DATA_GPIO,
    .max_leds = CONFIG_LEDCTL_LED_COUNT,
    .led_model = LED_MODEL_WS2812,
    .color_component_format = LED_STRIP_COLOR_COMPONENT_FMT_GRB,
    .flags.invert_out = false,
};

led_strip_rmt_config_t rmt_cfg = {
    .clk_src = RMT_CLK_SRC_DEFAULT,
    .resolution_hz = 10 * 1000 * 1000,   // 10 MHz → 0.1 µs na tick
    .mem_block_symbols = 64,
    .flags.with_dma = true,
};

ESP_ERROR_CHECK(led_strip_new_rmt_device(&strip_cfg, &rmt_cfg, &strip));
```

**Nie bit-banguj.** WS2812B wymaga timingu 800 kHz z tolerancją ~±150 ns.
Aktywne radio WiFi przerywa CPU i przy bit-bangingu daje losowe glitche —
diody zapalające się na przypadkowy kolor. RMT ma własny sprzętowy generator,
odporny na przerwania.

Alternatywa: SPI z kodowaniem bitów (3 bity SPI na 1 bit danych). Przydatne
gdy RMT jest zajęty czymś innym.

### Gamma

Tablica 256-elementowa w flashu, gamma 2.2:

```c
static const uint8_t GAMMA8[256] = { /* wygenerowana przez tools/gen_gamma.py */ };
```

Stosowana **na końcu**, tuż przed zapisem do bufora RMT. Wartości w protokole
i w rendererze są percepcyjne (liniowe dla oka).

---

## CCT na LEDC

### Konfiguracja

```c
ledc_timer_config_t timer = {
    .speed_mode      = LEDC_LOW_SPEED_MODE,
    .duty_resolution = LEDC_TIMER_12_BIT,
    .timer_num       = LEDC_TIMER_0,
    .freq_hz         = 19531,              // 80 MHz / 2^12
    .clk_cfg         = LEDC_AUTO_CLK,
};
```

**Częstotliwość ≥ 20 kHz** — poniżej tego pasek migocze w kamerze telefonu
(rolling shutter) i bywa słyszalny jako pisk z cewek zasilacza.

Zależność rozdzielczości od częstotliwości na C3:

```
bits = log2(80_000_000 / freq_hz)
```

Przy 19.5 kHz → 12 bitów. Przy 40 kHz → 11 bitów. Nie da się mieć obu naraz.

### Temporal dithering — konieczny

12 bitów po nałożeniu gammy 2.2 daje w dolnym zakresie skoki widoczne gołym okiem.
Zakres 1–3% to dokładnie ten, którego używasz wieczorem, więc problem jest realny.

Rozwiązanie: rozrzucaj błąd kwantyzacji między kolejnymi klatkami.

```c
// duty_f: żądana wartość float w [0, 4095]
static float err_accum[2];

int apply_dither(float duty_f, int ch) {
    float v = duty_f + err_accum[ch];
    int   d = (int)(v + 0.5f);
    if (d < 0) d = 0;
    if (d > 4095) d = 4095;
    err_accum[ch] = v - d;
    return d;
}
```

Wywoływane co klatkę fade'u (~50 Hz). Efektywna rozdzielczość rośnie do ~14 bitów.
Bez tego ściemnianie do 1% wygląda źle.

### Mapowanie mired

```c
// mired = 1e6 / kelvin;  interpolacja liniowa w miredach, nie w kelwinach
float mired      = 1e6f / kelvin;
float mired_warm = 1e6f / CCT_MIN_K;   // 2700 K → 370
float mired_cold = 1e6f / CCT_MAX_K;   // 6500 K → 154

float ratio = (mired - mired_cold) / (mired_warm - mired_cold);  // 0=zimno, 1=ciepło
float warm  = brightness * ratio;
float cold  = brightness * (1.0f - ratio);
```

---

## Odbiornik DDP

```c
void ddp_task(void *arg) {
    int sock = socket(AF_INET, SOCK_DGRAM, IPPROTO_IP);
    struct sockaddr_in addr = {
        .sin_family = AF_INET,
        .sin_addr.s_addr = htonl(INADDR_ANY),
        .sin_port = htons(4048),
    };
    bind(sock, (struct sockaddr *)&addr, sizeof(addr));

    uint8_t buf[1500];
    while (1) {
        int len = recv(sock, buf, sizeof(buf), 0);
        if (len < 10) continue;

        uint32_t offset = (buf[4]<<24)|(buf[5]<<16)|(buf[6]<<8)|buf[7];
        uint16_t dlen   = (buf[8]<<8)|buf[9];
        if (10 + dlen > len) continue;

        write_pixels(offset, buf + 10, dlen);

        if (buf[0] & 0x01) {          // flaga PUSH
            swap_buffers();
        }
        live_watchdog_feed();
    }
}
```

**Timeout `live`:** osobny `esp_timer` na 2500 ms, resetowany przy każdym pakiecie.
Po wygaśnięciu — `live = false`, powrót do wzoru/efektu, broadcast patcha po WS.

Powiększ bufory lwIP w `sdkconfig.defaults`, inaczej przy 60 fps zaczniesz gubić
pakiety pod obciążeniem:

```
CONFIG_LWIP_UDP_RECVMBOX_SIZE=16
CONFIG_LWIP_TCPIP_RECVMBOX_SIZE=64
```

---

## Interpreter wzorów

Wzór ładowany z LittleFS jako JSON, parsowany **raz** przy aktywacji do struktury
w RAM. Nie parsuj JSON-a per klatkę.

```c
typedef struct {
    gen_type_t type;
    union { gradient_t grad; noise_t noise; /* ... */ } p;
} generator_t;

typedef struct {
    generator_t  src;
    modulator_t  mods[MAX_MODS];
    uint8_t      mod_count;
    blend_mode_t blend;
    float        opacity;
} layer_t;
```

Pętla renderowania:

```c
for (int i = 0; i < led_count; i++) {
    float x = (float)i / (led_count - 1);   // przestrzeń znormalizowana
    rgb_t acc = {0, 0, 0};
    for (int l = 0; l < pattern.layer_count; l++) {
        float xm = x, tm = t;
        apply_modulators(&pattern.layers[l], &xm, &tm);
        rgb_t c = sample_generator(&pattern.layers[l].src, xm, tm);
        acc = blend(acc, c, pattern.layers[l].blend, pattern.layers[l].opacity);
    }
    back_buffer[i] = acc;
}
```

**Wydajność:** 144 diody × 3 warstwy × 60 fps na C3 @ 160 MHz to bez problemu.
Przy 300+ diodach i szumie Perlina zmierz `esp_timer_get_time()` wokół pętli.
Optymalizacje w kolejności: LUT dla `sin`, arytmetyka stałoprzecinkowa Q16.16,
`-O2` w `sdkconfig`.

**Zgodność z Dart:** ten sam wzór musi dać identyczny wynik. Test conformance
w `tools/pattern_conformance/` — złote wartości z Dart, weryfikacja w teście
jednostkowym C (Unity, `idf.py build` w `test/`).

---

## Konfiguracja i provisioning

### NVS — namespace `ledctl`

| Klucz | Typ | Zawartość |
|---|---|---|
| `token` | blob | token API (32 B, losowy), patrz `ledctl_cfg_get_token()` |
| `claimed` | u8 | czy `/api/claim` już oddał token (patrz niżej) |
| `state` | blob | ostatni stan (przywracany po restarcie) |
| `led_count` | u16 | liczba diod (pixels) |
| `cct_min/max` | u16 | zakres K (cct) |

WiFi SSID/hasło **nie** są tu wymienione — `wifi_prov_mgr` trzyma je we własnym
namespace przez `esp_wifi`'s NVS storage, nie przez `ledctl_cfg.c`.

Zapis stanu do NVS: **debounce 5 s** po ostatniej zmianie. Zapis przy każdym ruchu
suwaka zajedzie flash (~100k cykli kasowania).

### Provisioning BLE

Zaimplementowane w `firmware/common/src/ledctl_provisioning.c`:

```c
wifi_prov_mgr_config_t cfg = {
    .scheme = wifi_prov_scheme_ble,
    .scheme_event_handler = WIFI_PROV_SCHEME_BLE_EVENT_HANDLER_FREE_BTDM,
    .app_event_handler = {.event_cb = prov_app_event_cb, .user_data = NULL},
};
wifi_prov_mgr_init(cfg);
wifi_prov_mgr_start_provisioning(WIFI_PROV_SECURITY_1, pop, service_name, NULL);
```

`WIFI_PROV_SECURITY_1` = wymiana kluczy X25519 + AES-CTR, z proof-of-possession
(`LEDCTL_PROV_POP` w Kconfig, domyślnie `abcd1234`). ESP32-C3 nie ma radia BT
classic, więc stosem jest NimBLE (`CONFIG_BT_NIMBLE_ENABLED=y`), nie Bluedroid.

**Token API — odbiór przez aplikację, nie przez BLE.** Pierwotny plan (token
przekazywany tym samym kanałem BLE, przez własny endpoint protocomm
`custom-data`) okazał się niepraktyczny: żaden dojrzały pakiet Flutter do BLE
provisioningu (patrz [03 — Aplikacja](03-aplikacja.md)) nie wystawia
niestandardowych endpointów protocomm — tylko `scanBleDevices` /
`scanWifiNetworks` / `provisionWifi`. Ręczna implementacja handshake'u
X25519/AES-CTR w Dart tylko po to, żeby przenieść 32 bajty tokenu, byłaby
ryzykowna bez sprzętu do testów. Zamiast tego: `GET /api/claim` (patrz
[02 — Protokół](02-protokol.md#http-api)) — bez autoryzacji, ale jednorazowe —
oddaje `{"id","token"}` zaraz po tym, jak urządzenie pojawi się w sieci przez
mDNS. `custom-data` **nadal istnieje** w firmware jako dodatkowa ścieżka dla
narzędzi, które faktycznie wspierają protocomm (np. referencyjny `esp_prov.py`
z ESP-IDF) — patrz `custom_data_handler()`.

Po zakończeniu — `WIFI_PROV_SCHEME_BLE_EVENT_HANDLER_FREE_BTDM` zwalnia ~30 kB RAM
zajmowane przez stos BT. Na C3 z 400 kB to zauważalne.

**Reset:** przycisk BOOT (GPIO z `LEDCTL_PROV_RESET_GPIO`, domyślnie 9)
przytrzymany 5 s → `wifi_prov_mgr_reset_provisioning()` + restart w tryb
parowania. Token API **nie** jest generowany na nowo (to ten sam token co
przed resetem) — tylko okno `/api/claim` otwiera się ponownie.

---

## OTA

Partycje A/B z rollbackiem — `partitions.csv`:

```
# Name,   Type, SubType,  Offset,   Size
nvs,      data, nvs,      0x9000,   0x6000
otadata,  data, ota,      0xf000,   0x2000
phy_init, data, phy,      0x11000,  0x1000
ota_0,    app,  ota_0,    0x20000,  0x180000
ota_1,    app,  ota_1,    0x1A0000, 0x180000
storage,  data, littlefs, 0x320000, 0xC0000
```

Włącz `CONFIG_BOOTLOADER_APP_ROLLBACK_ENABLE`. Nowy firmware musi zawołać
`esp_ota_mark_app_valid_cancel_rollback()` po udanym połączeniu z WiFi — jeśli
tego nie zrobi, bootloader wróci do poprzedniej wersji.

Bez tego jeden zły build oznacza wyjęcie paska z sufitu i podpięcie kabla.

---

## sdkconfig.defaults

```
CONFIG_IDF_TARGET="esp32c3"
CONFIG_COMPILER_OPTIMIZATION_PERF=y

CONFIG_ESP_MAIN_TASK_STACK_SIZE=6144
CONFIG_FREERTOS_HZ=1000

CONFIG_LWIP_UDP_RECVMBOX_SIZE=16
CONFIG_LWIP_TCPIP_RECVMBOX_SIZE=64
CONFIG_LWIP_MAX_SOCKETS=10

CONFIG_HTTPD_WS_SUPPORT=y
CONFIG_HTTPD_MAX_REQ_HDR_LEN=1024

CONFIG_BOOTLOADER_APP_ROLLBACK_ENABLE=y
CONFIG_ESP_TASK_WDT_TIMEOUT_S=10

CONFIG_PM_ENABLE=n
```

`CONFIG_PM_ENABLE=n` — power management skaluje częstotliwość CPU i psuje timing
animacji. Przy zasilaniu sieciowym nie ma powodu go włączać.

`CONFIG_FREERTOS_HZ=1000` daje tick 1 ms zamiast 10 ms — potrzebne do sensownego
schedulingu przy 60 fps.

---

## Debug

```bash
idf.py monitor                    # dekoduje backtrace automatycznie
idf.py monitor --print-filter="pattern:D *:I"
```

Logowanie: `ESP_LOGD` w ścieżce renderowania **wyłącz w release**. `ESP_LOGI`
przy 60 fps zapcha UART i sam stanie się przyczyną gubienia klatek.

Pomiar czasu renderowania:

```c
int64_t t0 = esp_timer_get_time();
render_frame();
ESP_LOGD(TAG, "render %lld us", esp_timer_get_time() - t0);
```

Task watchdog jest włączony — długa pętla renderująca bez `vTaskDelay` wywoła reset.
Przy ciężkich wzorach dodaj `vTaskDelay(1)` co N pikseli albo wydłuż timeout.
