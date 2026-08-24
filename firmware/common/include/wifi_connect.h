#pragma once

#include "esp_err.h"
#include "esp_http_server.h"
#include "esp_wifi.h"

/// Registers the WIFI_EVENT/IP_EVENT handlers that retry indefinitely on
/// disconnect and feed wifi_connect_debug_register()'s ring buffer. Must be
/// called once, before WiFi connects for the first time this boot —
/// *including* a connection kicked off internally by wifi_prov_mgr during
/// BLE provisioning — so the event group wifi_connect_wait() blocks on is
/// guaranteed to observe it (FreeRTOS event bits latch, so it's fine if the
/// connect finishes before wifi_connect_wait() is even called).
void wifi_connect_register_handlers(void);

/// Applies the PMF workaround below to `cfg` in place. Exposed so
/// ledctl_provisioning.c can call it from wifi_prov_mgr's
/// WIFI_PROV_SET_STA_CONFIG hook — that's the only chance to touch the
/// config when credentials arrive via BLE provisioning, since the manager
/// applies them and connects internally.
void wifi_connect_apply_pmf_workaround(wifi_config_t *cfg);

/// Starts the WiFi driver in station mode, assuming credentials are already
/// in NVS (from a previous provisioning session — see
/// docs/04-firmware.md#provisioning-ble). Does not block; call
/// wifi_connect_wait() afterward. Skip this entirely if wifi_prov_mgr just
/// connected during this boot (BLE provisioning does so itself).
esp_err_t wifi_connect_start_sta(void);

/// Blocks until wifi_connect_register_handlers() has observed either a
/// successful connection or MAX_RETRY consecutive failures.
esp_err_t wifi_connect_wait(void);

/// Registers `GET /api/debug/wifi` — a ring buffer of the last connect /
/// disconnect / got-ip events (uptime, reason, rssi). Not part of
/// docs/02-protokol.md; a debug-only escape hatch for diagnosing WiFi
/// instability over the network when there's no USB cable free for a
/// serial monitor (e.g. testing on external power).
esp_err_t wifi_connect_debug_register(httpd_handle_t server);
