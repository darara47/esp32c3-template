#include "ledctl_debug_log.h"

#include <stdarg.h>
#include <stdbool.h>
#include <stdio.h>
#include <string.h>

#include "esp_log.h"
#include "esp_system.h"
#include "freertos/FreeRTOS.h"
#include "ledctl_auth.h"

#define LOG_BUF_SIZE 8192

static char s_log_buf[LOG_BUF_SIZE];
static size_t s_write_pos = 0;
static bool s_wrapped = false;
static portMUX_TYPE s_log_mux = portMUX_INITIALIZER_UNLOCKED;
static vprintf_like_t s_orig_vprintf = NULL;

static int debug_log_vprintf(const char *fmt, va_list args) {
    char line[256];
    va_list args_copy;
    va_copy(args_copy, args);
    int len = vsnprintf(line, sizeof(line), fmt, args_copy);
    va_end(args_copy);

    if (len > 0) {
        size_t n = (size_t)len < sizeof(line) ? (size_t)len : sizeof(line) - 1;
        portENTER_CRITICAL(&s_log_mux);
        for (size_t i = 0; i < n; i++) {
            s_log_buf[s_write_pos] = line[i];
            s_write_pos = (s_write_pos + 1) % LOG_BUF_SIZE;
            if (s_write_pos == 0) s_wrapped = true;
        }
        portEXIT_CRITICAL(&s_log_mux);
    }

    return s_orig_vprintf ? s_orig_vprintf(fmt, args) : len;
}

void ledctl_debug_log_install(void) { s_orig_vprintf = esp_log_set_vprintf(debug_log_vprintf); }

static esp_err_t debug_log_get_handler(httpd_req_t *req) {
    if (!ledctl_auth_ok(req)) return ledctl_auth_reject(req);

    static char snapshot[LOG_BUF_SIZE + 1];
    size_t len;

    portENTER_CRITICAL(&s_log_mux);
    if (s_wrapped) {
        memcpy(snapshot, s_log_buf + s_write_pos, LOG_BUF_SIZE - s_write_pos);
        memcpy(snapshot + (LOG_BUF_SIZE - s_write_pos), s_log_buf, s_write_pos);
        len = LOG_BUF_SIZE;
    } else {
        memcpy(snapshot, s_log_buf, s_write_pos);
        len = s_write_pos;
    }
    portEXIT_CRITICAL(&s_log_mux);

    snapshot[len] = '\0';
    httpd_resp_set_type(req, "text/plain");
    return httpd_resp_send(req, snapshot, len);
}

static const char *reset_reason_str(esp_reset_reason_t reason) {
    switch (reason) {
        case ESP_RST_POWERON: return "poweron";
        case ESP_RST_EXT: return "ext_pin";
        case ESP_RST_SW: return "sw (esp_restart)";
        case ESP_RST_PANIC: return "panic";
        case ESP_RST_INT_WDT: return "interrupt_watchdog";
        case ESP_RST_TASK_WDT: return "task_watchdog";
        case ESP_RST_WDT: return "other_watchdog";
        case ESP_RST_BROWNOUT: return "brownout";
        case ESP_RST_SDIO: return "sdio";
        default: return "other";
    }
}

static esp_err_t debug_reset_get_handler(httpd_req_t *req) {
    if (!ledctl_auth_ok(req)) return ledctl_auth_reject(req);

    char body[96];
    esp_reset_reason_t reason = esp_reset_reason();
    snprintf(body, sizeof(body), "{\"reason_code\":%d,\"reason\":\"%s\"}", (int)reason, reset_reason_str(reason));
    httpd_resp_set_type(req, "application/json");
    return httpd_resp_sendstr(req, body);
}

esp_err_t ledctl_debug_log_register(httpd_handle_t server) {
    httpd_uri_t log_uri = {
        .uri = "/api/debug/log",
        .method = HTTP_GET,
        .handler = debug_log_get_handler,
    };
    esp_err_t err = httpd_register_uri_handler(server, &log_uri);
    if (err != ESP_OK) return err;

    httpd_uri_t reset_uri = {
        .uri = "/api/debug/reset",
        .method = HTTP_GET,
        .handler = debug_reset_get_handler,
    };
    return httpd_register_uri_handler(server, &reset_uri);
}
