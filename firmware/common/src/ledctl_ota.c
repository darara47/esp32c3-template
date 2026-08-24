#include "ledctl_ota.h"

#include "esp_log.h"
#include "esp_ota_ops.h"
#include "freertos/FreeRTOS.h"
#include "freertos/task.h"
#include "ledctl_auth.h"

static const char *TAG = "ledctl_ota";

// The httpd task's own stack is only 4096 bytes by default (bumped to
// LEDCTL_HTTPD_STACK_SIZE in ledctl_ws.c, but keep this modest anyway —
// httpd's own call frames already eat into that budget before this handler
// even starts).
#define OTA_RECV_BUF_SIZE 1024

static esp_err_t fail(httpd_req_t *req, httpd_err_code_t code, esp_ota_handle_t handle, const char *msg) {
    esp_ota_abort(handle);
    httpd_resp_send_err(req, code, msg);
    return ESP_FAIL;
}

static esp_err_t ota_post_handler(httpd_req_t *req) {
    if (!ledctl_auth_ok(req)) return ledctl_auth_reject(req);

    const esp_partition_t *update_partition = esp_ota_get_next_update_partition(NULL);
    if (update_partition == NULL) {
        ESP_LOGE(TAG, "no OTA partition available");
        httpd_resp_send_err(req, HTTPD_500_INTERNAL_SERVER_ERROR, "no OTA partition");
        return ESP_FAIL;
    }

    // A known size erases only the sectors the image needs; OTA_SIZE_UNKNOWN
    // erases the whole partition up front in one blocking call, which for a
    // 1.86MB slot can run well past the httpd's recv_wait_timeout and gets
    // the connection torn down before a single body byte is read.
    esp_ota_handle_t ota_handle;
    esp_err_t err = esp_ota_begin(update_partition, req->content_len, &ota_handle);
    if (err != ESP_OK) {
        ESP_LOGE(TAG, "esp_ota_begin failed: %s", esp_err_to_name(err));
        httpd_resp_send_err(req, HTTPD_500_INTERNAL_SERVER_ERROR, "ota begin failed");
        return ESP_FAIL;
    }

    char buf[OTA_RECV_BUF_SIZE];
    int remaining = req->content_len;
    while (remaining > 0) {
        int to_read = remaining < (int)sizeof(buf) ? remaining : (int)sizeof(buf);
        int received = httpd_req_recv(req, buf, to_read);
        if (received == HTTPD_SOCK_ERR_TIMEOUT) continue;
        if (received <= 0) {
            ESP_LOGE(TAG, "upload interrupted after %d/%d bytes", req->content_len - remaining, req->content_len);
            return fail(req, HTTPD_400_BAD_REQUEST, ota_handle, "upload interrupted");
        }

        err = esp_ota_write(ota_handle, buf, received);
        if (err != ESP_OK) {
            ESP_LOGE(TAG, "esp_ota_write failed: %s", esp_err_to_name(err));
            return fail(req, HTTPD_500_INTERNAL_SERVER_ERROR, ota_handle, "ota write failed");
        }
        remaining -= received;
    }

    err = esp_ota_end(ota_handle);
    if (err != ESP_OK) {
        ESP_LOGE(TAG, "esp_ota_end failed: %s", esp_err_to_name(err));
        const char *msg = (err == ESP_ERR_OTA_VALIDATE_FAILED) ? "image validation failed" : "ota end failed";
        httpd_resp_send_err(req, HTTPD_400_BAD_REQUEST, msg);
        return ESP_FAIL;
    }

    err = esp_ota_set_boot_partition(update_partition);
    if (err != ESP_OK) {
        ESP_LOGE(TAG, "esp_ota_set_boot_partition failed: %s", esp_err_to_name(err));
        httpd_resp_send_err(req, HTTPD_500_INTERNAL_SERVER_ERROR, "set boot partition failed");
        return ESP_FAIL;
    }

    httpd_resp_set_type(req, "application/json");
    httpd_resp_sendstr(req, "{\"ok\":true}");

    ESP_LOGI(TAG, "OTA update written to '%s', rebooting", update_partition->label);
    // Let the response above actually reach the client before the reset
    // tears down the connection out from under it.
    vTaskDelay(pdMS_TO_TICKS(500));
    esp_restart();
    return ESP_OK;  // unreachable
}

esp_err_t ledctl_ota_register(httpd_handle_t server) {
    httpd_uri_t ota_uri = {
        .uri = "/api/ota",
        .method = HTTP_POST,
        .handler = ota_post_handler,
    };
    return httpd_register_uri_handler(server, &ota_uri);
}
