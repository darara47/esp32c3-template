#include "ledctl_state.h"

#include <stdlib.h>

#include "cJSON.h"

void ledctl_state_default(ledctl_state_t *state, int cct_min, int cct_max) {
    state->on = true;
    state->bri = 128;
    state->tt = 0;
    state->cct = (cct_min + cct_max) / 2;
}

bool ledctl_patch_parse(const char *json, size_t len, ledctl_patch_t *out) {
    *out = (ledctl_patch_t){0};
    cJSON *root = cJSON_ParseWithLength(json, len);
    if (root == NULL || !cJSON_IsObject(root)) {
        cJSON_Delete(root);
        return false;
    }

    cJSON *item;
    if ((item = cJSON_GetObjectItemCaseSensitive(root, "on")) && cJSON_IsBool(item)) {
        out->has_on = true;
        out->on = cJSON_IsTrue(item);
    }
    if ((item = cJSON_GetObjectItemCaseSensitive(root, "bri")) && cJSON_IsNumber(item)) {
        out->has_bri = true;
        out->bri = item->valueint;
    }
    if ((item = cJSON_GetObjectItemCaseSensitive(root, "tt")) && cJSON_IsNumber(item)) {
        out->has_tt = true;
        out->tt = item->valueint;
    }
    if ((item = cJSON_GetObjectItemCaseSensitive(root, "cct")) && cJSON_IsNumber(item)) {
        out->has_cct = true;
        out->cct = item->valueint;
    }

    cJSON_Delete(root);
    return true;
}

void ledctl_state_apply(ledctl_state_t *state, const ledctl_patch_t *patch) {
    if (patch->has_on) state->on = patch->on;
    if (patch->has_bri) state->bri = patch->bri;
    if (patch->has_tt) state->tt = patch->tt;
    if (patch->has_cct) state->cct = patch->cct;
}

char *ledctl_state_to_json(const ledctl_state_t *state) {
    cJSON *root = cJSON_CreateObject();
    cJSON_AddBoolToObject(root, "on", state->on);
    cJSON_AddNumberToObject(root, "bri", state->bri);
    cJSON_AddNumberToObject(root, "tt", state->tt);
    cJSON_AddNumberToObject(root, "cct", state->cct);
    char *out = cJSON_PrintUnformatted(root);
    cJSON_Delete(root);
    return out;
}

char *ledctl_patch_to_json(const ledctl_patch_t *patch) {
    cJSON *root = cJSON_CreateObject();
    if (patch->has_on) cJSON_AddBoolToObject(root, "on", patch->on);
    if (patch->has_bri) cJSON_AddNumberToObject(root, "bri", patch->bri);
    if (patch->has_tt) cJSON_AddNumberToObject(root, "tt", patch->tt);
    if (patch->has_cct) cJSON_AddNumberToObject(root, "cct", patch->cct);
    char *out = cJSON_PrintUnformatted(root);
    cJSON_Delete(root);
    return out;
}

char *ledctl_device_descriptor_json(const char *id, const char *name, const char *fw, int cct_min, int cct_max) {
    cJSON *root = cJSON_CreateObject();
    cJSON_AddNumberToObject(root, "schema", 1);
    cJSON_AddStringToObject(root, "id", id);
    cJSON_AddStringToObject(root, "name", name);
    cJSON_AddStringToObject(root, "model", "ledctl-cct");
    cJSON_AddStringToObject(root, "fw", fw);

    cJSON *caps = cJSON_CreateArray();
    cJSON_AddItemToArray(caps, cJSON_CreateString("power"));
    cJSON_AddItemToArray(caps, cJSON_CreateString("brightness"));
    cJSON_AddItemToArray(caps, cJSON_CreateString("cct"));
    cJSON_AddItemToArray(caps, cJSON_CreateString("transition"));
    cJSON_AddItemToObject(root, "caps", caps);

    cJSON *cct = cJSON_CreateObject();
    cJSON_AddNumberToObject(cct, "min", cct_min);
    cJSON_AddNumberToObject(cct, "max", cct_max);
    cJSON_AddItemToObject(root, "cct", cct);

    char *out = cJSON_PrintUnformatted(root);
    cJSON_Delete(root);
    return out;
}
