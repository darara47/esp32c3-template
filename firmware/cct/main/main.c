#include <stdbool.h>
#include <stdio.h>

#include "esp_log.h"
#include "esp_mac.h"
#include "esp_ota_ops.h"
#include "esp_system.h"
#include "mdns.h"
#include "nvs_flash.h"
#include "sdkconfig.h"

#include "cct.h"
#include "ledctl_cfg.h"
#include "ledctl_debug_log.h"
#include "ledctl_provisioning.h"
#include "ledctl_state.h"
#include "ledctl_ws.h"

static const char *TAG = "main";

#define FW_VERSION "0.1.0"

static void on_patch(const ledctl_patch_t *patch) {
    (void)patch;  // the merged state already reflects it — read that instead
    ledctl_state_t *state = ledctl_ws_state();
    cct_set_target(state->on, state->bri, state->cct, state->tt);
    ledctl_cfg_save_state_debounced(state);
    ESP_LOGI(TAG, "state now: on=%d bri=%d cct=%d tt=%d", state->on, state->bri, state->cct, state->tt);
}

static void device_id_from_mac(char *out, size_t out_len) {
    uint8_t mac[6];
    esp_read_mac(mac, ESP_MAC_WIFI_STA);
    snprintf(out, out_len, "%02x:%02x:%02x:%02x:%02x:%02x", mac[0], mac[1], mac[2], mac[3], mac[4], mac[5]);
}

static void start_mdns(const char *device_id, const char *device_name) {
    ESP_ERROR_CHECK(mdns_init());
    ESP_ERROR_CHECK(mdns_hostname_set(CONFIG_LEDCTL_DEVICE_NAME));
    ESP_ERROR_CHECK(mdns_instance_name_set(device_name));

    mdns_txt_item_t txt[] = {
        {"id", device_id},
        {"model", "ledctl-cct"},
        {"fw", FW_VERSION},
        {"schema", "1"},
    };
    ESP_ERROR_CHECK(mdns_service_add(NULL, "_ledctl", "_tcp", 80, txt, sizeof(txt) / sizeof(txt[0])));
}

void app_main(void) {
    // First, before anything else has a chance to log — see
    // ledctl_debug_log.h.
    ledctl_debug_log_install();
    ESP_LOGI(TAG, "reset reason: %d", esp_reset_reason());

    ESP_ERROR_CHECK(nvs_flash_init());
    ledctl_cfg_init();

    // Bring the physical light up from its last known state before touching
    // the network at all. This used to happen after the blocking WiFi
    // connect call, which meant a bad WiFi day (or a first boot sitting in
    // BLE provisioning) left the light dark, and (worse) that call failing
    // was ESP_ERROR_CHECK'd, so exhausting the retry budget aborted the
    // whole device before it ever reached this code. A lighting fixture has
    // to keep working locally regardless of what the network is doing.
    ledctl_state_t restored;
    bool have_restored_state = ledctl_cfg_load_state(&restored);
    cct_init(CONFIG_LEDCTL_WARM_GPIO, CONFIG_LEDCTL_COLD_GPIO, CONFIG_LEDCTL_CCT_MIN_K, CONFIG_LEDCTL_CCT_MAX_K);
    if (have_restored_state) {
        ESP_LOGI(TAG, "restored state from NVS: on=%d bri=%d cct=%d", restored.on, restored.bri, restored.cct);
        cct_set_target(restored.on, restored.bri, restored.cct, 0);
    }

    char device_id[18];
    device_id_from_mac(device_id, sizeof(device_id));
    ESP_LOGI(TAG, "device id: %s", device_id);

    char token[LEDCTL_TOKEN_HEX_LEN + 1];
    ledctl_cfg_get_token(token);

    // Brings up BLE provisioning on first boot, or just reconnects using
    // credentials a previous provisioning already persisted. Either way,
    // `token` ends up guarding ledctl_ws_start()'s API below — the app
    // fetches it via the one-time GET /api/claim once this device shows up
    // on the LAN. See docs/04-firmware.md#provisioning-ble.
    if (ledctl_prov_start(device_id, CONFIG_LEDCTL_PROV_POP, token) != ESP_OK) {
        ESP_LOGW(TAG, "WiFi still not up — light is running locally; network features will catch up once "
                      "wifi_connect.c's background retry succeeds");
    }
    // A freshly OTA-flashed image boots into the "pending verify" state; if
    // nothing ever calls this, the bootloader assumes it's bad and rolls
    // back to the previous slot on the next reset. Reaching this point
    // (whether or not WiFi is up yet) is our bar for "this image is good"
    // — see docs/04-firmware.md#ota.
    esp_ota_mark_app_valid_cancel_rollback();

    ledctl_prov_watch_reset_button(CONFIG_LEDCTL_PROV_RESET_GPIO);

    start_mdns(device_id, CONFIG_LEDCTL_DEVICE_NAME);

    ESP_ERROR_CHECK(ledctl_ws_start(device_id, CONFIG_LEDCTL_DEVICE_NAME, FW_VERSION, CONFIG_LEDCTL_CCT_MIN_K,
                                     CONFIG_LEDCTL_CCT_MAX_K, token, on_patch));
    if (have_restored_state) {
        ledctl_ws_set_state(&restored);
    }

    ESP_LOGI(TAG, "ledctl-cct ready");
}
