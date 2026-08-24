#include "cct.h"

#include <math.h>

#include "driver/ledc.h"
#include "esp_log.h"
#include "esp_timer.h"
#include "freertos/FreeRTOS.h"
#include "freertos/task.h"

static const char *TAG = "cct";

#define LEDC_FREQ_HZ 19531  // 80 MHz / 2^12 — see docs/04-firmware.md#cct-na-ledc
#define LEDC_DUTY_RES LEDC_TIMER_12_BIT
#define LEDC_MAX_DUTY 4095.0f
#define FADE_INTERVAL_MS 20  // ~50 Hz, matches the "fade" task in the doc's task model

static int s_cct_min_k;
static int s_cct_max_k;

// Guards every field below: written by whichever task calls cct_set_target
// (the HTTP server's task, via main.c's patch callback), read every tick by
// fade_task. Both are short, non-blocking accesses, so a critical section
// (not a full mutex) is the right tool.
static portMUX_TYPE s_mux = portMUX_INITIALIZER_UNLOCKED;
static float s_warm_from, s_cold_from;
static float s_warm_to, s_cold_to;
static int64_t s_fade_start_us;
static int64_t s_fade_duration_us;

static float s_dither_error[2];  // [0]=warm, [1]=cold

static float gamma_correct(float linear_0_1) {
    if (linear_0_1 <= 0.0f) return 0.0f;
    if (linear_0_1 >= 1.0f) return 1.0f;
    return powf(linear_0_1, 2.2f);
}

// docs/04-firmware.md#temporal-dithering--konieczny — spreads the
// quantization error from float duty -> 12-bit duty across frames instead
// of dropping it, so dimming to 1-3% doesn't visibly step.
static int apply_dither(float duty_f, int channel) {
    float v = duty_f + s_dither_error[channel];
    int d = (int)(v + 0.5f);
    if (d < 0) d = 0;
    if (d > (int)LEDC_MAX_DUTY) d = (int)LEDC_MAX_DUTY;
    s_dither_error[channel] = v - d;
    return d;
}

// docs/04-firmware.md#mapowanie-mired — interpolating in mireds (not
// Kelvin) keeps the warm<->cold sweep perceptually even.
static float warm_ratio_for(int kelvin) {
    float mired = 1e6f / (float)kelvin;
    float mired_warm = 1e6f / (float)s_cct_min_k;
    float mired_cold = 1e6f / (float)s_cct_max_k;
    float ratio = (mired - mired_cold) / (mired_warm - mired_cold);
    if (ratio < 0.0f) ratio = 0.0f;
    if (ratio > 1.0f) ratio = 1.0f;
    return ratio;
}

static float lerp(float a, float b, float t) { return a + (b - a) * t; }

static void fade_task(void *arg) {
    (void)arg;
    while (1) {
        float warm, cold;
        portENTER_CRITICAL(&s_mux);
        float t = 1.0f;
        if (s_fade_duration_us > 0) {
            t = (float)(esp_timer_get_time() - s_fade_start_us) / (float)s_fade_duration_us;
            if (t > 1.0f) t = 1.0f;
            if (t < 0.0f) t = 0.0f;
        }
        warm = lerp(s_warm_from, s_warm_to, t);
        cold = lerp(s_cold_from, s_cold_to, t);
        portEXIT_CRITICAL(&s_mux);

        int warm_duty = apply_dither(gamma_correct(warm) * LEDC_MAX_DUTY, 0);
        int cold_duty = apply_dither(gamma_correct(cold) * LEDC_MAX_DUTY, 1);

        ledc_set_duty(LEDC_LOW_SPEED_MODE, LEDC_CHANNEL_0, warm_duty);
        ledc_update_duty(LEDC_LOW_SPEED_MODE, LEDC_CHANNEL_0);
        ledc_set_duty(LEDC_LOW_SPEED_MODE, LEDC_CHANNEL_1, cold_duty);
        ledc_update_duty(LEDC_LOW_SPEED_MODE, LEDC_CHANNEL_1);

        vTaskDelay(pdMS_TO_TICKS(FADE_INTERVAL_MS));
    }
}

void cct_init(int warm_gpio, int cold_gpio, int cct_min_k, int cct_max_k) {
    s_cct_min_k = cct_min_k;
    s_cct_max_k = cct_max_k;

    ledc_timer_config_t timer_cfg = {
        .speed_mode = LEDC_LOW_SPEED_MODE,
        .duty_resolution = LEDC_DUTY_RES,
        .timer_num = LEDC_TIMER_0,
        .freq_hz = LEDC_FREQ_HZ,
        .clk_cfg = LEDC_AUTO_CLK,
    };
    ESP_ERROR_CHECK(ledc_timer_config(&timer_cfg));

    ledc_channel_config_t warm_channel = {
        .gpio_num = warm_gpio,
        .speed_mode = LEDC_LOW_SPEED_MODE,
        .channel = LEDC_CHANNEL_0,
        .timer_sel = LEDC_TIMER_0,
        .duty = 0,
        .hpoint = 0,
    };
    ESP_ERROR_CHECK(ledc_channel_config(&warm_channel));

    ledc_channel_config_t cold_channel = {
        .gpio_num = cold_gpio,
        .speed_mode = LEDC_LOW_SPEED_MODE,
        .channel = LEDC_CHANNEL_1,
        .timer_sel = LEDC_TIMER_0,
        .duty = 0,
        .hpoint = 0,
    };
    ESP_ERROR_CHECK(ledc_channel_config(&cold_channel));

    xTaskCreate(fade_task, "cct_fade", 3072, NULL, 5, NULL);
    ESP_LOGI(TAG, "LEDC ready: warm=GPIO%d cold=GPIO%d", warm_gpio, cold_gpio);
}

void cct_set_target(bool on, int bri, int cct, int tt_ms) {
    float ratio = warm_ratio_for(cct);
    float brightness = on ? (bri / 255.0f) : 0.0f;
    float warm = brightness * ratio;
    float cold = brightness * (1.0f - ratio);

    portENTER_CRITICAL(&s_mux);
    // Start the new fade from wherever the current one has actually
    // reached, not its old target — otherwise a patch arriving mid-fade
    // makes the output jump before continuing.
    float t = 1.0f;
    if (s_fade_duration_us > 0) {
        t = (float)(esp_timer_get_time() - s_fade_start_us) / (float)s_fade_duration_us;
        if (t > 1.0f) t = 1.0f;
        if (t < 0.0f) t = 0.0f;
    }
    s_warm_from = lerp(s_warm_from, s_warm_to, t);
    s_cold_from = lerp(s_cold_from, s_cold_to, t);
    s_warm_to = warm;
    s_cold_to = cold;
    s_fade_start_us = esp_timer_get_time();
    s_fade_duration_us = (int64_t)tt_ms * 1000;
    portEXIT_CRITICAL(&s_mux);
}
