#pragma once

#include "esp_err.h"
#include "esp_http_server.h"

/// Registers `POST /api/ota` on the given server — see
/// docs/02-protokol.md#http-api. The request body is the raw firmware image;
/// it's streamed straight into the inactive OTA slot (never buffered whole),
/// and a successful upload reboots into it immediately. Pairs with
/// esp_ota_mark_app_valid_cancel_rollback() in main.c: if the new image
/// can't reach that call (crash loop, bad WiFi creds baked in by mistake),
/// the bootloader rolls back on its own — see docs/04-firmware.md#ota.
esp_err_t ledctl_ota_register(httpd_handle_t server);
