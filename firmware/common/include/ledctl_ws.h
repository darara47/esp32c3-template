#pragma once

#include "esp_err.h"
#include "ledctl_state.h"

/// Called whenever a client's patch is accepted (WS `patch` frame or
/// `POST /api/state`) — main.c uses this to drive LEDC once that exists;
/// for now it's just where a log line would go.
typedef void (*ledctl_patch_cb_t)(const ledctl_patch_t *patch);

/// Starts the HTTP + WebSocket server on port 80: `/ws`, `GET/POST
/// /api/state`, `GET /api/device` — see docs/02-protokol.md. Every request
/// must carry `token` (the device's API token, from ledctl_cfg_get_token())
/// via `Authorization: Bearer` or, for the WS handshake, `?token=`.
esp_err_t ledctl_ws_start(const char *device_id, const char *device_name, const char *fw_version, int cct_min,
                           int cct_max, const char *token, ledctl_patch_cb_t on_patch);

/// The canonical state. Only ever written from the HTTP server task (patch
/// handling) — no locking, because there's exactly one writer.
ledctl_state_t *ledctl_ws_state(void);

/// Overwrites the canonical state — for seeding it from NVS right after
/// ledctl_ws_start(), before any client has connected. Not a general-purpose
/// setter: nothing broadcasts this change, since there's nobody to tell yet.
void ledctl_ws_set_state(const ledctl_state_t *state);

/// Broadcasts a patch frame to every connected WebSocket client.
void ledctl_ws_broadcast_patch(const ledctl_patch_t *patch);
