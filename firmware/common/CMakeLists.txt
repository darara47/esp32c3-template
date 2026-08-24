idf_component_register(
    SRCS "src/ledctl_state.c" "src/ledctl_ws.c" "src/ledctl_cfg.c" "src/ledctl_ota.c" "src/ledctl_debug_log.c"
         "src/wifi_connect.c" "src/ledctl_auth.c" "src/ledctl_provisioning.c"
    INCLUDE_DIRS "include"
    REQUIRES esp_wifi esp_netif esp_event nvs_flash esp_http_server json esp_timer app_update esp_system
             wifi_provisioning driver
)
