#pragma once

#include <stdbool.h>

#include "ledctl_state.h"

/// Length of the API token as returned by ledctl_cfg_get_token(), in hex
/// characters (not counting the NUL terminator) — see docs/02-protokol.md's
/// `Authorization: Bearer <token>`.
#define LEDCTL_TOKEN_HEX_LEN 64

/// Must be called once at boot, after nvs_flash_init().
void ledctl_cfg_init(void);

/// Fills `out` from NVS and returns true if a previously-saved state exists.
bool ledctl_cfg_load_state(ledctl_state_t *out);

/// Schedules a write 5s after the *last* call — docs/04-firmware.md's NVS
/// table calls this out explicitly: writing on every slider tick would burn
/// through flash's ~100k erase-cycle budget.
void ledctl_cfg_save_state_debounced(const ledctl_state_t *state);

/// Returns the device's persistent API token as a lowercase hex string
/// (`out` must hold LEDCTL_TOKEN_HEX_LEN+1 bytes). Generated once from the
/// hardware RNG on first call — whether that's this boot or a previous one —
/// and persisted to NVS, so it survives reboots and OTA updates but is fresh
/// per-device. Handed to the app once, during BLE provisioning.
void ledctl_cfg_get_token(char *out);

/// True once `GET /api/claim` has handed the token to an app — see
/// ledctl_ws.c's claim handler. Persisted, so a stray reboot doesn't reopen
/// the unauthenticated claim window.
bool ledctl_cfg_token_claimed(void);

/// Marks the token as claimed. Idempotent.
void ledctl_cfg_mark_token_claimed(void);

/// Reopens the claim window — call when BLE provisioning (re-)starts, so a
/// freshly (re-)paired app can claim the token again.
void ledctl_cfg_reset_token_claim(void);
