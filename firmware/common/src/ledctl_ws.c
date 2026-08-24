#include "ledctl_ws.h"

#include <string.h>
#include <unistd.h>

#include "cJSON.h"
#include "esp_http_server.h"
#include "esp_log.h"
#include "ledctl_auth.h"
#include "ledctl_cfg.h"
#include "ledctl_debug_log.h"
#include "ledctl_ota.h"
#include "wifi_connect.h"

static const char *TAG = "ledctl_ws";

#define MAX_WS_CLIENTS 4

static httpd_handle_t s_server = NULL;
static int s_ws_fds[MAX_WS_CLIENTS];
static ledctl_state_t s_state;
static char s_device_json[512];
static char s_device_id[18];
static char s_token[LEDCTL_TOKEN_HEX_LEN + 1];
static ledctl_patch_cb_t s_on_patch = NULL;

ledctl_state_t *ledctl_ws_state(void) { return &s_state; }

void ledctl_ws_set_state(const ledctl_state_t *state) { s_state = *state; }

static void register_client(int fd) {
    for (int i = 0; i < MAX_WS_CLIENTS; i++) {
        if (s_ws_fds[i] == fd) return;
    }
    for (int i = 0; i < MAX_WS_CLIENTS; i++) {
        if (s_ws_fds[i] == 0) {
            s_ws_fds[i] = fd;
            return;
        }
    }
    ESP_LOGW(TAG, "no room for another WS client (fd=%d)", fd);
}

static void unregister_client(int fd) {
    for (int i = 0; i < MAX_WS_CLIENTS; i++) {
        if (s_ws_fds[i] == fd) {
            s_ws_fds[i] = 0;
            return;
        }
    }
}

static void send_text(int fd, const char *text) {
    httpd_ws_frame_t frame = {
        .type = HTTPD_WS_TYPE_TEXT,
        .payload = (uint8_t *)text,
        .len = strlen(text),
    };
    esp_err_t err = httpd_ws_send_frame_async(s_server, fd, &frame);
    if (err != ESP_OK) {
        // The client is almost certainly gone; stop tracking it rather than
        // retry a dead socket on every future broadcast.
        unregister_client(fd);
    }
}

static void broadcast_text(const char *text) {
    for (int i = 0; i < MAX_WS_CLIENTS; i++) {
        if (s_ws_fds[i] != 0) send_text(s_ws_fds[i], text);
    }
}

void ledctl_ws_broadcast_patch(const ledctl_patch_t *patch) {
    char *patch_json = ledctl_patch_to_json(patch);
    char frame[256];
    snprintf(frame, sizeof(frame), "{\"t\":\"patch\",\"d\":%s}", patch_json);
    free(patch_json);
    broadcast_text(frame);
}

static void handle_apply(int fd, cJSON *d_item, cJSON *id_item) {
    char *d_json = d_item ? cJSON_PrintUnformatted(d_item) : NULL;
    if (d_json != NULL) {
        ledctl_patch_t patch;
        if (ledctl_patch_parse(d_json, strlen(d_json), &patch)) {
            ledctl_state_apply(&s_state, &patch);
            if (s_on_patch) s_on_patch(&patch);
            ledctl_ws_broadcast_patch(&patch);
        }
        free(d_json);
    }

    if (id_item != NULL) {
        char *id_json = cJSON_PrintUnformatted(id_item);
        char ack[64];
        snprintf(ack, sizeof(ack), "{\"t\":\"ack\",\"id\":%s}", id_json);
        free(id_json);
        send_text(fd, ack);
    }
}

static void handle_frame(int fd, const char *raw, size_t len) {
    cJSON *root = cJSON_ParseWithLength(raw, len);
    if (root == NULL) return;

    cJSON *t = cJSON_GetObjectItemCaseSensitive(root, "t");
    if (!cJSON_IsString(t)) {
        cJSON_Delete(root);
        return;
    }

    if (strcmp(t->valuestring, "patch") == 0) {
        handle_apply(fd, cJSON_GetObjectItemCaseSensitive(root, "d"), cJSON_GetObjectItemCaseSensitive(root, "id"));
    } else if (strcmp(t->valuestring, "get") == 0) {
        char *state_json = ledctl_state_to_json(&s_state);
        char frame[256];
        snprintf(frame, sizeof(frame), "{\"t\":\"state\",\"d\":%s}", state_json);
        free(state_json);
        send_text(fd, frame);
    } else if (strcmp(t->valuestring, "ping") == 0) {
        send_text(fd, "{\"t\":\"pong\"}");
    }

    cJSON_Delete(root);
}

static void send_initial_frames(int fd) {
    char device_frame[560];
    snprintf(device_frame, sizeof(device_frame), "{\"t\":\"device\",\"d\":%s}", s_device_json);
    send_text(fd, device_frame);

    char *state_json = ledctl_state_to_json(&s_state);
    char state_frame[256];
    snprintf(state_frame, sizeof(state_frame), "{\"t\":\"state\",\"d\":%s}", state_json);
    free(state_json);
    send_text(fd, state_frame);
}

// ESP-IDF's httpd core completes the WS handshake internally and never calls
// uri->handler() for that request (see httpd_uri.c: it returns ESP_OK right
// after httpd_ws_respond_server_handshake() without dispatching to us) — so
// registering the client and sending the hello frames has to happen here,
// via the post-handshake hook, not by branching on req->method inside
// ws_handler() below.
static esp_err_t ws_post_handshake_cb(httpd_req_t *req) {
    int fd = httpd_req_to_sockfd(req);
    register_client(fd);
    send_initial_frames(fd);
    return ESP_OK;
}

// Runs before the 101 Switching Protocols response goes out, so an
// unauthorized client never completes the handshake — returning anything
// other than ESP_OK here aborts it (see httpd_uri.c). WS clients generally
// can't set custom headers on the handshake request, hence the ?token=
// fallback in ledctl_auth_ok().
static esp_err_t ws_pre_handshake_cb(httpd_req_t *req) { return ledctl_auth_ok(req) ? ESP_OK : ESP_FAIL; }

static esp_err_t ws_handler(httpd_req_t *req) {
    int fd = httpd_req_to_sockfd(req);

    httpd_ws_frame_t ws_pkt;
    memset(&ws_pkt, 0, sizeof(ws_pkt));
    ws_pkt.type = HTTPD_WS_TYPE_TEXT;

    esp_err_t ret = httpd_ws_recv_frame(req, &ws_pkt, 0);
    if (ret != ESP_OK) {
        ESP_LOGE(TAG, "httpd_ws_recv_frame (length probe) failed: %d", ret);
        return ret;
    }
    if (ws_pkt.len == 0) return ESP_OK;

    uint8_t *buf = calloc(1, ws_pkt.len + 1);
    if (buf == NULL) return ESP_ERR_NO_MEM;
    ws_pkt.payload = buf;

    ret = httpd_ws_recv_frame(req, &ws_pkt, ws_pkt.len);
    if (ret != ESP_OK) {
        ESP_LOGE(TAG, "httpd_ws_recv_frame failed: %d", ret);
        free(buf);
        return ret;
    }

    if (ws_pkt.type == HTTPD_WS_TYPE_TEXT) {
        handle_frame(fd, (char *)buf, ws_pkt.len);
    } else if (ws_pkt.type == HTTPD_WS_TYPE_CLOSE) {
        unregister_client(fd);
    }

    free(buf);
    return ESP_OK;
}

static esp_err_t api_device_get_handler(httpd_req_t *req) {
    if (!ledctl_auth_ok(req)) return ledctl_auth_reject(req);
    httpd_resp_set_type(req, "application/json");
    return httpd_resp_send(req, s_device_json, HTTPD_RESP_USE_STRLEN);
}

// Deliberately unauthenticated (there's no token to present yet) but
// self-limiting: the first caller gets the token, every caller after that
// gets 403 — see ledctl_cfg_token_claimed(). Reopens only when BLE
// provisioning (re)starts (ledctl_provisioning.c), which needs physical
// access to the device (BOOT-button reset) or is the device's very first
// boot. This is how pairing_screen.dart in the app learns a device's
// token without the BLE plugin it uses supporting ESP-IDF's custom
// protocomm endpoints — see docs/04-firmware.md#provisioning-ble.
static esp_err_t api_claim_get_handler(httpd_req_t *req) {
    httpd_resp_set_type(req, "application/json");

    if (ledctl_cfg_token_claimed()) {
        httpd_resp_set_status(req, "403 Forbidden");
        return httpd_resp_sendstr(req, "{\"error\":\"already_claimed\"}");
    }
    ledctl_cfg_mark_token_claimed();

    cJSON *root = cJSON_CreateObject();
    cJSON_AddStringToObject(root, "id", s_device_id);
    cJSON_AddStringToObject(root, "token", s_token);
    char *json = cJSON_PrintUnformatted(root);
    cJSON_Delete(root);
    if (json == NULL) return ESP_ERR_NO_MEM;

    esp_err_t ret = httpd_resp_sendstr(req, json);
    free(json);
    return ret;
}

static esp_err_t api_state_get_handler(httpd_req_t *req) {
    if (!ledctl_auth_ok(req)) return ledctl_auth_reject(req);
    char *json = ledctl_state_to_json(&s_state);
    httpd_resp_set_type(req, "application/json");
    esp_err_t ret = httpd_resp_send(req, json, HTTPD_RESP_USE_STRLEN);
    free(json);
    return ret;
}

static esp_err_t api_state_post_handler(httpd_req_t *req) {
    if (!ledctl_auth_ok(req)) return ledctl_auth_reject(req);
    char buf[512];
    int total = 0;
    int remaining = req->content_len;
    if (remaining >= (int)sizeof(buf)) remaining = sizeof(buf) - 1;

    while (total < remaining) {
        int r = httpd_req_recv(req, buf + total, remaining - total);
        if (r == HTTPD_SOCK_ERR_TIMEOUT) continue;
        if (r <= 0) return ESP_FAIL;
        total += r;
    }
    buf[total] = '\0';

    ledctl_patch_t patch;
    if (total > 0 && ledctl_patch_parse(buf, total, &patch)) {
        ledctl_state_apply(&s_state, &patch);
        if (s_on_patch) s_on_patch(&patch);
        ledctl_ws_broadcast_patch(&patch);
    }

    char *json = ledctl_state_to_json(&s_state);
    httpd_resp_set_type(req, "application/json");
    esp_err_t ret = httpd_resp_send(req, json, HTTPD_RESP_USE_STRLEN);
    free(json);
    return ret;
}

static void ws_close_handler(httpd_handle_t hd, int sockfd) {
    (void)hd;
    unregister_client(sockfd);
    close(sockfd);
}

esp_err_t ledctl_ws_start(const char *device_id, const char *device_name, const char *fw_version, int cct_min,
                           int cct_max, const char *token, ledctl_patch_cb_t on_patch) {
    s_on_patch = on_patch;
    ledctl_auth_init(token);
    ledctl_state_default(&s_state, cct_min, cct_max);

    char *device_json = ledctl_device_descriptor_json(device_id, device_name, fw_version, cct_min, cct_max);
    strncpy(s_device_json, device_json, sizeof(s_device_json) - 1);
    free(device_json);

    strncpy(s_device_id, device_id, sizeof(s_device_id) - 1);
    strncpy(s_token, token, sizeof(s_token) - 1);

    httpd_config_t config = HTTPD_DEFAULT_CONFIG();
    config.close_fn = ws_close_handler;
    // The default 5s is fine for state/WS traffic but too tight for an OTA
    // upload — sector erase inside esp_ota_begin() plus transferring an
    // ~1MB image over WiFi can each individually take longer than that.
    config.recv_wait_timeout = 60;
    config.send_wait_timeout = 60;
    // Default is 4096 bytes for the whole httpd task — not enough headroom
    // for httpd's own call frames plus ledctl_ota.c's receive buffer and
    // esp_ota_write()'s internal flash-write buffering. Undersizing this
    // is a silent stack overflow (reset reason "panic"), not a clean error.
    config.stack_size = 8192;
    config.max_open_sockets = MAX_WS_CLIENTS + 2;
    // Default is 8. This module alone registers 5 (/ws, /api/device,
    // /api/claim, /api/state GET+POST) and the three register_*() calls
    // below add 4 more (ota, wifi debug, debug log ×2) — 9 total, one over
    // the default. httpd_register_uri_handler() returning
    // ESP_ERR_HTTPD_HANDLERS_FULL for the 9th, unchecked here but wrapped
    // in an ESP_ERROR_CHECK at the ledctl_ws_start() call site in main.c,
    // turned into an infinite boot -> register -> abort -> reboot loop.
    // Generous headroom so the next added endpoint doesn't repeat this.
    config.max_uri_handlers = 16;

    esp_err_t err = httpd_start(&s_server, &config);
    if (err != ESP_OK) return err;

    httpd_uri_t ws_uri = {
        .uri = "/ws",
        .method = HTTP_GET,
        .handler = ws_handler,
        .is_websocket = true,
        .ws_pre_handshake_cb = ws_pre_handshake_cb,
        .ws_post_handshake_cb = ws_post_handshake_cb,
    };
    httpd_register_uri_handler(s_server, &ws_uri);

    httpd_uri_t device_uri = {
        .uri = "/api/device",
        .method = HTTP_GET,
        .handler = api_device_get_handler,
    };
    httpd_register_uri_handler(s_server, &device_uri);

    httpd_uri_t claim_uri = {
        .uri = "/api/claim",
        .method = HTTP_GET,
        .handler = api_claim_get_handler,
    };
    httpd_register_uri_handler(s_server, &claim_uri);

    httpd_uri_t state_get_uri = {
        .uri = "/api/state",
        .method = HTTP_GET,
        .handler = api_state_get_handler,
    };
    httpd_register_uri_handler(s_server, &state_get_uri);

    httpd_uri_t state_post_uri = {
        .uri = "/api/state",
        .method = HTTP_POST,
        .handler = api_state_post_handler,
    };
    httpd_register_uri_handler(s_server, &state_post_uri);

    err = ledctl_ota_register(s_server);
    if (err != ESP_OK) return err;

    err = wifi_connect_debug_register(s_server);
    if (err != ESP_OK) return err;

    err = ledctl_debug_log_register(s_server);
    if (err != ESP_OK) return err;

    return ESP_OK;
}
