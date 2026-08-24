#include "wifi_connect.h"

#include "cJSON.h"
#include "esp_event.h"
#include "esp_log.h"
#include "esp_netif.h"
#include "esp_timer.h"
#include "esp_wifi.h"
#include "freertos/FreeRTOS.h"
#include "freertos/event_groups.h"
#include "ledctl_auth.h"
#include "sdkconfig.h"

static const char *TAG = "wifi_connect";

#define WIFI_CONNECTED_BIT BIT0
#define WIFI_FAIL_BIT BIT1
#define MAX_RETRY 10

static EventGroupHandle_t s_wifi_event_group;
static int s_retry_count = 0;

// Small in-memory history so WiFi instability can be diagnosed over HTTP —
// see wifi_connect_debug_register() — when there's no spare USB cable for a
// serial monitor, e.g. while testing on external power.
#define WIFI_EVENT_LOG_CAP 20

typedef enum { WIFI_DBG_CONNECTED, WIFI_DBG_DISCONNECTED, WIFI_DBG_GOT_IP } wifi_dbg_event_type_t;

typedef struct {
    int64_t uptime_ms;
    wifi_dbg_event_type_t type;
    int reason;  // only meaningful for WIFI_DBG_DISCONNECTED
    int rssi;    // only meaningful for WIFI_DBG_DISCONNECTED
} wifi_dbg_event_t;

static wifi_dbg_event_t s_event_log[WIFI_EVENT_LOG_CAP];
static int s_event_count = 0;  // total ever logged; index wraps via modulo

static void log_event(wifi_dbg_event_type_t type, int reason, int rssi) {
    wifi_dbg_event_t *e = &s_event_log[s_event_count % WIFI_EVENT_LOG_CAP];
    e->uptime_ms = esp_timer_get_time() / 1000;
    e->type = type;
    e->reason = reason;
    e->rssi = rssi;
    s_event_count++;
}

static void event_handler(void *arg, esp_event_base_t event_base, int32_t event_id, void *event_data) {
    if (event_base == WIFI_EVENT && event_id == WIFI_EVENT_STA_START) {
        esp_wifi_connect();
    } else if (event_base == WIFI_EVENT && event_id == WIFI_EVENT_STA_CONNECTED) {
        log_event(WIFI_DBG_CONNECTED, 0, 0);
    } else if (event_base == WIFI_EVENT && event_id == WIFI_EVENT_STA_DISCONNECTED) {
        wifi_event_sta_disconnected_t *disconn = (wifi_event_sta_disconnected_t *)event_data;
        ESP_LOGW(TAG, "disconnected, reason=%d rssi=%d", disconn->reason, disconn->rssi);
        log_event(WIFI_DBG_DISCONNECTED, disconn->reason, disconn->rssi);
        // MAX_RETRY only bounds how long wifi_connect_wait() blocks the
        // caller before giving up and letting the rest of app_main proceed
        // (see main.c) — it must NOT mean "stop trying forever". A router
        // hiccup or a bad RF minute is common and often self-resolves; the
        // device should keep reconnecting in the background indefinitely
        // rather than needing a power cycle to recover.
        if (s_retry_count < MAX_RETRY) {
            s_retry_count++;
            ESP_LOGW(TAG, "retrying connection to the AP (%d/%d)", s_retry_count, MAX_RETRY);
        } else {
            xEventGroupSetBits(s_wifi_event_group, WIFI_FAIL_BIT);
        }
        esp_wifi_connect();
    } else if (event_base == IP_EVENT && event_id == IP_EVENT_STA_GOT_IP) {
        ip_event_got_ip_t *event = (ip_event_got_ip_t *)event_data;
        ESP_LOGI(TAG, "got ip:" IPSTR, IP2STR(&event->ip_info.ip));
        log_event(WIFI_DBG_GOT_IP, 0, 0);
        s_retry_count = 0;
        xEventGroupSetBits(s_wifi_event_group, WIFI_CONNECTED_BIT);
    }
}

static const char *event_type_str(wifi_dbg_event_type_t type) {
    switch (type) {
        case WIFI_DBG_CONNECTED: return "connected";
        case WIFI_DBG_DISCONNECTED: return "disconnected";
        case WIFI_DBG_GOT_IP: return "got_ip";
    }
    return "?";
}

static esp_err_t wifi_debug_get_handler(httpd_req_t *req) {
    if (!ledctl_auth_ok(req)) return ledctl_auth_reject(req);

    cJSON *root = cJSON_CreateObject();
    cJSON_AddNumberToObject(root, "uptime_ms", esp_timer_get_time() / 1000);
    cJSON_AddNumberToObject(root, "total_events", s_event_count);

    cJSON *events = cJSON_CreateArray();
    int count = s_event_count < WIFI_EVENT_LOG_CAP ? s_event_count : WIFI_EVENT_LOG_CAP;
    int start = s_event_count < WIFI_EVENT_LOG_CAP ? 0 : s_event_count % WIFI_EVENT_LOG_CAP;
    for (int i = 0; i < count; i++) {
        wifi_dbg_event_t *e = &s_event_log[(start + i) % WIFI_EVENT_LOG_CAP];
        cJSON *item = cJSON_CreateObject();
        cJSON_AddNumberToObject(item, "uptime_ms", e->uptime_ms);
        cJSON_AddStringToObject(item, "type", event_type_str(e->type));
        if (e->type == WIFI_DBG_DISCONNECTED) {
            cJSON_AddNumberToObject(item, "reason", e->reason);
            cJSON_AddNumberToObject(item, "rssi", e->rssi);
        }
        cJSON_AddItemToArray(events, item);
    }
    cJSON_AddItemToObject(root, "events", events);

    char *json = cJSON_PrintUnformatted(root);
    cJSON_Delete(root);
    httpd_resp_set_type(req, "application/json");
    esp_err_t err = httpd_resp_sendstr(req, json);
    free(json);
    return err;
}

esp_err_t wifi_connect_debug_register(httpd_handle_t server) {
    httpd_uri_t uri = {
        .uri = "/api/debug/wifi",
        .method = HTTP_GET,
        .handler = wifi_debug_get_handler,
    };
    return httpd_register_uri_handler(server, &uri);
}

void wifi_connect_register_handlers(void) {
    s_wifi_event_group = xEventGroupCreate();

    esp_event_handler_instance_t instance_any_id;
    esp_event_handler_instance_t instance_got_ip;
    ESP_ERROR_CHECK(esp_event_handler_instance_register(
        WIFI_EVENT, ESP_EVENT_ANY_ID, &event_handler, NULL, &instance_any_id));
    ESP_ERROR_CHECK(esp_event_handler_instance_register(
        IP_EVENT, IP_EVENT_STA_GOT_IP, &event_handler, NULL, &instance_got_ip));
}

void wifi_connect_apply_pmf_workaround(wifi_config_t *cfg) {
    // Routers running WPA2/WPA3-transition mode advertise PMF as optional;
    // ESP-IDF's default of "capable" negotiates it opportunistically, and a
    // flaky PMF implementation on the AP side manifests as an otherwise-
    // healthy association (good RSSI, clean assoc) that stalls in the 4-way
    // handshake — reason 204 (WIFI_REASON_HANDSHAKE_TIMEOUT). This network
    // doesn't require PMF, so just don't offer it.
    cfg->sta.pmf_cfg.capable = false;
    cfg->sta.pmf_cfg.required = false;
}

esp_err_t wifi_connect_start_sta(void) {
    ESP_ERROR_CHECK(esp_wifi_set_mode(WIFI_MODE_STA));

    // Credentials already live in NVS from a previous BLE provisioning
    // session (esp_wifi's own flash-backed config storage) — just apply the
    // same PMF workaround wifi_prov_mgr's WIFI_PROV_SET_STA_CONFIG hook
    // applies during a fresh provisioning, in case this config predates it.
    wifi_config_t wifi_config;
    if (esp_wifi_get_config(WIFI_IF_STA, &wifi_config) == ESP_OK) {
        wifi_connect_apply_pmf_workaround(&wifi_config);
        esp_wifi_set_config(WIFI_IF_STA, &wifi_config);
    }

    ESP_ERROR_CHECK(esp_wifi_start());
    // Modem sleep (the default) drops beacons on some APs and adds latency
    // that fights the <50ms slider response this device is built for —
    // there's no battery to save power for anyway. See docs/07-roadmapa.md.
    ESP_ERROR_CHECK(esp_wifi_set_ps(WIFI_PS_NONE));
    return ESP_OK;
}

esp_err_t wifi_connect_wait(void) {
    EventBits_t bits = xEventGroupWaitBits(s_wifi_event_group, WIFI_CONNECTED_BIT | WIFI_FAIL_BIT, pdFALSE,
                                            pdFALSE, portMAX_DELAY);

    if (bits & WIFI_CONNECTED_BIT) {
        ESP_LOGI(TAG, "WiFi connected");
        return ESP_OK;
    }
    ESP_LOGE(TAG, "WiFi connection attempts exhausted");
    return ESP_FAIL;
}
