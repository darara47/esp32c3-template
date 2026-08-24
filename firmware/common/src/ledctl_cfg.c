#include "ledctl_cfg.h"

#include "esp_log.h"
#include "esp_random.h"
#include "esp_timer.h"
#include "nvs.h"

static const char *TAG = "ledctl_cfg";

#define NVS_NAMESPACE "ledctl"
#define NVS_KEY_STATE "state"
#define NVS_KEY_TOKEN "token"
#define NVS_KEY_CLAIMED "claimed"
#define SAVE_DEBOUNCE_US (5 * 1000 * 1000)
#define TOKEN_RAW_LEN (LEDCTL_TOKEN_HEX_LEN / 2)

static esp_timer_handle_t s_save_timer;
static ledctl_state_t s_pending_state;

static void save_timer_cb(void *arg) {
    (void)arg;
    nvs_handle_t handle;
    esp_err_t err = nvs_open(NVS_NAMESPACE, NVS_READWRITE, &handle);
    if (err != ESP_OK) {
        ESP_LOGW(TAG, "nvs_open failed: %s", esp_err_to_name(err));
        return;
    }
    err = nvs_set_blob(handle, NVS_KEY_STATE, &s_pending_state, sizeof(s_pending_state));
    if (err == ESP_OK) err = nvs_commit(handle);
    if (err != ESP_OK) {
        ESP_LOGW(TAG, "failed to persist state: %s", esp_err_to_name(err));
    }
    nvs_close(handle);
}

void ledctl_cfg_init(void) {
    const esp_timer_create_args_t args = {
        .callback = &save_timer_cb,
        .name = "ledctl_save",
    };
    ESP_ERROR_CHECK(esp_timer_create(&args, &s_save_timer));
}

bool ledctl_cfg_load_state(ledctl_state_t *out) {
    nvs_handle_t handle;
    if (nvs_open(NVS_NAMESPACE, NVS_READONLY, &handle) != ESP_OK) return false;

    size_t len = sizeof(*out);
    esp_err_t err = nvs_get_blob(handle, NVS_KEY_STATE, out, &len);
    nvs_close(handle);
    return err == ESP_OK && len == sizeof(*out);
}

void ledctl_cfg_save_state_debounced(const ledctl_state_t *state) {
    s_pending_state = *state;
    esp_timer_stop(s_save_timer);  // ESP_ERR_INVALID_STATE if idle — fine
    esp_timer_start_once(s_save_timer, SAVE_DEBOUNCE_US);
}

static void bytes_to_hex(const uint8_t *bytes, size_t len, char *out) {
    static const char digits[] = "0123456789abcdef";
    for (size_t i = 0; i < len; i++) {
        out[i * 2] = digits[bytes[i] >> 4];
        out[i * 2 + 1] = digits[bytes[i] & 0x0f];
    }
    out[len * 2] = '\0';
}

void ledctl_cfg_get_token(char *out) {
    uint8_t raw[TOKEN_RAW_LEN];
    size_t len = sizeof(raw);
    bool have_token = false;

    nvs_handle_t handle;
    if (nvs_open(NVS_NAMESPACE, NVS_READONLY, &handle) == ESP_OK) {
        have_token = nvs_get_blob(handle, NVS_KEY_TOKEN, raw, &len) == ESP_OK && len == sizeof(raw);
        nvs_close(handle);
    }

    if (!have_token) {
        esp_fill_random(raw, sizeof(raw));
        if (nvs_open(NVS_NAMESPACE, NVS_READWRITE, &handle) == ESP_OK) {
            esp_err_t err = nvs_set_blob(handle, NVS_KEY_TOKEN, raw, sizeof(raw));
            if (err == ESP_OK) err = nvs_commit(handle);
            if (err != ESP_OK) ESP_LOGW(TAG, "failed to persist new token: %s", esp_err_to_name(err));
            nvs_close(handle);
        }
        ESP_LOGI(TAG, "generated new API token");
    }

    bytes_to_hex(raw, sizeof(raw), out);
}

static void set_claimed(uint8_t claimed) {
    nvs_handle_t handle;
    if (nvs_open(NVS_NAMESPACE, NVS_READWRITE, &handle) != ESP_OK) return;
    esp_err_t err = nvs_set_u8(handle, NVS_KEY_CLAIMED, claimed);
    if (err == ESP_OK) err = nvs_commit(handle);
    if (err != ESP_OK) ESP_LOGW(TAG, "failed to persist claim state: %s", esp_err_to_name(err));
    nvs_close(handle);
}

bool ledctl_cfg_token_claimed(void) {
    nvs_handle_t handle;
    uint8_t claimed = 0;
    if (nvs_open(NVS_NAMESPACE, NVS_READONLY, &handle) == ESP_OK) {
        nvs_get_u8(handle, NVS_KEY_CLAIMED, &claimed);
        nvs_close(handle);
    }
    return claimed != 0;
}

void ledctl_cfg_mark_token_claimed(void) { set_claimed(1); }

void ledctl_cfg_reset_token_claim(void) { set_claimed(0); }
