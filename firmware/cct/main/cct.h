#pragma once

#include <stdbool.h>

/// Sets up the two LEDC PWM channels and starts the ~50 Hz fade task —
/// docs/04-firmware.md#cct-na-ledc.
void cct_init(int warm_gpio, int cold_gpio, int cct_min_k, int cct_max_k);

/// Sets a new fade target. Call this with the freshly-merged state after
/// every accepted patch (and once at boot with the restored/default state).
/// `tt_ms` is the transition duration — 0 means "jump immediately".
void cct_set_target(bool on, int bri, int cct, int tt_ms);
