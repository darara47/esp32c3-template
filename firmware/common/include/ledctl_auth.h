#pragma once

#include <stdbool.h>

#include "esp_err.h"
#include "esp_http_server.h"

/// Must be called once, with the device's token from ledctl_cfg_get_token(),
/// before any handler below calls ledctl_auth_ok().
void ledctl_auth_init(const char *token_hex);

/// True if `req` carries the correct token — either `Authorization: Bearer
/// <token>` (plain HTTP) or `?token=` in the query string (the WebSocket
/// handshake, where a client that can't set custom headers still needs a
/// way in) — see docs/02-protokol.md.
bool ledctl_auth_ok(httpd_req_t *req);

/// Sends a 401 response. Callers still need their own `return` right after —
/// this doesn't jump anywhere for you.
esp_err_t ledctl_auth_reject(httpd_req_t *req);
