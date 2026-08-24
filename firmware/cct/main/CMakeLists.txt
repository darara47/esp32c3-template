idf_component_register(
    SRCS "main.c" "cct.c"
    INCLUDE_DIRS "."
    REQUIRES common mdns driver esp_timer app_update nvs_flash esp_wifi
)
