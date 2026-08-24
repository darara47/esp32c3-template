#pragma once

#include "esp_err.h"
#include "esp_http_server.h"

/// Installs a log sink that mirrors every ESP_LOG line into an in-RAM ring
/// buffer (still prints to UART as normal), so recent activity can be
/// pulled back over HTTP later — call once, first thing in app_main(),
/// before anything else has a chance to log. Not persisted across a reboot
/// (that's what ledctl_debug_log_reset_reason() is for); this is for
/// diagnosing a device that's still alive but has nobody watching a serial
/// monitor (e.g. running on external power, USB unplugged).
void ledctl_debug_log_install(void);

/// Registers `GET /api/debug/log` (plain text dump of the ring buffer) and
/// `GET /api/debug/reset` (why the CURRENT boot happened — panic, task
/// watchdog, brownout, power-on, ... — read from esp_reset_reason(), which
/// survives a crash even though the ring buffer above doesn't). Neither is
/// part of docs/02-protokol.md; both are debug-only escape hatches.
esp_err_t ledctl_debug_log_register(httpd_handle_t server);
