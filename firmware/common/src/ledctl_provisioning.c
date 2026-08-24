#include "ledctl_provisioning.h"

#include <stdint.h>
#include <string.h>

#include "cJSON.h"
#include "driver/gpio.h"
#include "esp_event.h"
#include "esp_log.h"
#include "esp_netif.h"
#include "esp_timer.h"
#include "esp_wifi.h"
#include "freertos/FreeRTOS.h"
#include "freertos/task.h"
#include "ledctl_cfg.h"
#include "wifi_connect.h"
#include "wifi_provisioning/manager.h"
#include "wifi_provisioning/scheme_ble.h"

static const char *TAG = "ledctl_prov";

#define RESET_HOLD_MS 5000
#define RESET_POLL_MS 50

// Stashed for custom_data_handler(), which runs on protocomm's own task
// during the (short, one-shot) provisioning session — see
// ledctl_prov_start(). Read-only after being set, so no locking.
static const char *s_device_id;
static const char *s_token;

// The only hook into the credentials wifi_prov_mgr receives over BLE and
// applies itself — see wifi_connect_apply_pmf_workaround()'s doc comment.
static void prov_app_event_cb(void *user_data, wifi_prov_cb_event_t event, void *event_data) {
    (void)user_data;
    if (event == WIFI_PROV_SET_STA_CONFIG) {
        wifi_connect_apply_pmf_workaround((wifi_config_t *)event_data);
    }
}

static wifi_prov_mgr_config_t prov_mgr_config(void) {
    return (wifi_prov_mgr_config_t){
        .scheme = wifi_prov_scheme_ble,
        // Releases the ~30kB the BT stack holds once provisioning is done
        // (or skipped, for an already-provisioned device) — see
        // docs/04-firmware.md#provisioning-ble.
        .scheme_event_handler = WIFI_PROV_SCHEME_BLE_EVENT_HANDLER_FREE_BTDM,
        .app_event_handler = {.event_cb = prov_app_event_cb, .user_data = NULL},
    };
}

// Secondary path for fetching the token over the BLE session itself
// (X25519 + proof-of-possession), for tools whose provisioning stack
// exposes custom protocomm endpoints — e.g. IDF's `esp_prov.py`. The
// app doesn't use this: no mature Flutter BLE-provisioning plugin exposes
// custom endpoints, so pairing_screen.dart fetches the token over the LAN
// instead, via ledctl_ws.c's one-time GET /api/claim. See
// docs/04-firmware.md#provisioning-ble.
static esp_err_t custom_data_handler(uint32_t session_id, const uint8_t *inbuf, ssize_t inlen, uint8_t **outbuf,
                                      ssize_t *outlen, void *priv_data) {
    (void)session_id;
    (void)inbuf;
    (void)inlen;
    (void)priv_data;

    cJSON *root = cJSON_CreateObject();
    cJSON_AddStringToObject(root, "id", s_device_id);
    cJSON_AddStringToObject(root, "token", s_token);
    char *json = cJSON_PrintUnformatted(root);
    cJSON_Delete(root);
    if (json == NULL) return ESP_ERR_NO_MEM;

    // protocomm frees this buffer itself once the transport has sent it.
    *outbuf = (uint8_t *)json;
    *outlen = (ssize_t)strlen(json) + 1;
    return ESP_OK;
}

static void service_name_from_mac(char *out, size_t out_len) {
    uint8_t mac[6];
    esp_wifi_get_mac(WIFI_IF_STA, mac);
    snprintf(out, out_len, "PROV_%02X%02X%02X", mac[3], mac[4], mac[5]);
}

esp_err_t ledctl_prov_start(const char *device_id, const char *pop, const char *token) {
    s_device_id = device_id;
    s_token = token;

    ESP_ERROR_CHECK(esp_netif_init());
    ESP_ERROR_CHECK(esp_event_loop_create_default());
    esp_netif_create_default_wifi_sta();

    wifi_init_config_t wifi_cfg = WIFI_INIT_CONFIG_DEFAULT();
    ESP_ERROR_CHECK(esp_wifi_init(&wifi_cfg));

    // Registered before wifi_prov_mgr ever touches the WiFi driver: when
    // credentials arrive over BLE, the manager connects internally and this
    // is the only way to observe that. FreeRTOS event bits latch, so it's
    // fine that wifi_connect_wait() below is called well after the fact in
    // that case — it'll see the bit already set instead of blocking.
    wifi_connect_register_handlers();

    ESP_ERROR_CHECK(wifi_prov_mgr_init(prov_mgr_config()));

    bool provisioned = false;
    ESP_ERROR_CHECK(wifi_prov_mgr_is_provisioned(&provisioned));

    if (!provisioned) {
        // Reopens the GET /api/claim window (see ledctl_ws.c) so the app
        // pairing this device can fetch its token — including on a
        // re-pair after a factory reset, when the token itself doesn't
        // change but a prior claim shouldn't block the new owner.
        ledctl_cfg_reset_token_claim();

        char service_name[13];
        service_name_from_mac(service_name, sizeof(service_name));

        ESP_ERROR_CHECK(wifi_prov_mgr_endpoint_create("custom-data"));
        ESP_ERROR_CHECK(
            wifi_prov_mgr_start_provisioning(WIFI_PROV_SECURITY_1, (wifi_prov_security1_params_t *)pop,
                                              service_name, NULL));
        ESP_ERROR_CHECK(wifi_prov_mgr_endpoint_register("custom-data", custom_data_handler, NULL));

        ESP_LOGI(TAG, "BLE provisioning started as \"%s\" — pair from the app's \"Add device\" screen",
                 service_name);

        wifi_prov_mgr_wait();  // blocks until WIFI_PROV_END (after a successful connect)
        wifi_prov_mgr_deinit();
    } else {
        ESP_LOGI(TAG, "already provisioned, connecting directly");
        wifi_prov_mgr_deinit();
        ESP_ERROR_CHECK(wifi_connect_start_sta());
    }

    return wifi_connect_wait();
}

static void factory_reset_and_reboot(void) {
    ESP_LOGW(TAG, "BOOT held %dms — resetting WiFi provisioning and rebooting", RESET_HOLD_MS);
    if (wifi_prov_mgr_init(prov_mgr_config()) == ESP_OK) {
        wifi_prov_mgr_reset_provisioning();
        wifi_prov_mgr_deinit();
    }
    esp_restart();
}

static void reset_button_task(void *arg) {
    int gpio_num = (int)(intptr_t)arg;
    int64_t held_since_us = -1;

    while (1) {
        if (gpio_get_level(gpio_num) == 0) {  // BOOT button pulls the pin low while held
            if (held_since_us < 0) held_since_us = esp_timer_get_time();
            if (esp_timer_get_time() - held_since_us >= (int64_t)RESET_HOLD_MS * 1000) {
                factory_reset_and_reboot();  // does not return
            }
        } else {
            held_since_us = -1;
        }
        vTaskDelay(pdMS_TO_TICKS(RESET_POLL_MS));
    }
}

void ledctl_prov_watch_reset_button(int gpio_num) {
    gpio_config_t cfg = {
        .pin_bit_mask = 1ULL << gpio_num,
        .mode = GPIO_MODE_INPUT,
        .pull_up_en = GPIO_PULLUP_ENABLE,
    };
    gpio_config(&cfg);
    xTaskCreate(reset_button_task, "prov_reset_btn", 3072, (void *)(intptr_t)gpio_num, 3, NULL);
}
