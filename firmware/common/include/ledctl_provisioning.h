#pragma once

#include "esp_err.h"

/// Brings up the TCP/IP + WiFi stack, then either runs BLE provisioning (if
/// the device has never been provisioned) or reconnects using the WiFi
/// config a previous provisioning session already persisted to flash.
///
/// `pop` is the proof-of-possession the app must present over BLE before
/// the (encrypted) WiFi credential exchange proceeds — see
/// docs/04-firmware.md#provisioning-ble. `token` is the device's API token
/// (ledctl_cfg_get_token()); once BLE provisioning succeeds, the app can
/// fetch `{"id","token"}` from the "custom-data" protocomm endpoint, which
/// is how it learns the token without it ever going out over WiFi/HTTP.
///
/// Blocks until WiFi connects or (mirroring the previous wifi_connect.c
/// behavior) connection attempts are exhausted — a lighting fixture has to
/// keep working locally either way, so this never blocks forever.
esp_err_t ledctl_prov_start(const char *device_id, const char *pop, const char *token);

/// Starts a background task watching `gpio_num` (expected: the BOOT
/// button, active-low). Held for ~5s, it wipes the stored WiFi
/// provisioning and reboots into BLE pairing mode — the escape hatch for a
/// device stuck on the wrong network with no serial cable handy. Call once
/// at boot, after ledctl_prov_start().
void ledctl_prov_watch_reset_button(int gpio_num);
