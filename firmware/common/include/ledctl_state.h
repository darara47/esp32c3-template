#pragma once

#include <stdbool.h>
#include <stddef.h>

/// CCT device state — docs/02-protokol.md's state model, restricted to the
/// fields a `power/brightness/cct/transition` device actually has. No `col`,
/// `seg`, `fx`, `live` etc. — those belong to `rgb`/`segments`/`effects`/
/// `stream`, none of which this device reports.
typedef struct {
    bool on;
    int bri;  // 0-255, perceptual
    int tt;   // ms, transition time requested by the last patch
    int cct;  // Kelvin
} ledctl_state_t;

/// A JSON merge patch — same fields as ledctl_state_t, but each is optional,
/// so "was this field present in the patch" has to travel separately from
/// its value.
typedef struct {
    bool has_on;
    bool on;
    bool has_bri;
    int bri;
    bool has_tt;
    int tt;
    bool has_cct;
    int cct;
} ledctl_patch_t;

void ledctl_state_default(ledctl_state_t *state, int cct_min, int cct_max);

/// Parses a JSON merge patch. Unrecognised keys are ignored (matching the
/// protocol's "ignore what you don't understand" rule); returns false only
/// if `json` isn't valid JSON at all.
bool ledctl_patch_parse(const char *json, size_t len, ledctl_patch_t *out);

void ledctl_state_apply(ledctl_state_t *state, const ledctl_patch_t *patch);

/// Both return a heap buffer the caller must free().
char *ledctl_state_to_json(const ledctl_state_t *state);
char *ledctl_patch_to_json(const ledctl_patch_t *patch);

char *ledctl_device_descriptor_json(const char *id, const char *name, const char *fw, int cct_min, int cct_max);
