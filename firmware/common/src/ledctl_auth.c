#include "ledctl_auth.h"

#include <string.h>

#include "esp_log.h"
#include "ledctl_cfg.h"

static const char *TAG = "ledctl_auth";

static char s_token[LEDCTL_TOKEN_HEX_LEN + 1];
static bool s_have_token = false;

void ledctl_auth_init(const char *token_hex) {
    strncpy(s_token, token_hex, sizeof(s_token) - 1);
    s_token[sizeof(s_token) - 1] = '\0';
    s_have_token = true;
}

static bool token_matches(const char *presented) {
    return s_have_token && presented != NULL && strcmp(presented, s_token) == 0;
}

bool ledctl_auth_ok(httpd_req_t *req) {
    // "Bearer " (7 chars) + token + NUL.
    char hdr[7 + LEDCTL_TOKEN_HEX_LEN + 1];
    if (httpd_req_get_hdr_value_str(req, "Authorization", hdr, sizeof(hdr)) == ESP_OK &&
        strncmp(hdr, "Bearer ", 7) == 0 && token_matches(hdr + 7)) {
        return true;
    }

    // Fallback for clients that can't set a custom header on the WS
    // handshake request.
    char query[16 + LEDCTL_TOKEN_HEX_LEN];
    if (httpd_req_get_url_query_str(req, query, sizeof(query)) == ESP_OK) {
        char token_param[LEDCTL_TOKEN_HEX_LEN + 1];
        if (httpd_query_key_value(query, "token", token_param, sizeof(token_param)) == ESP_OK &&
            token_matches(token_param)) {
            return true;
        }
    }

    ESP_LOGW(TAG, "rejected unauthorized request to %s", req->uri);
    return false;
}

esp_err_t ledctl_auth_reject(httpd_req_t *req) {
    httpd_resp_set_status(req, "401 Unauthorized");
    return httpd_resp_send(req, NULL, 0);
}
