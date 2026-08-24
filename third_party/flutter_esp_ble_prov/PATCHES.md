# Patches applied to flutter_esp_ble_prov 0.1.7

Vendored from pub.dev because the published package doesn't build against
the AGP version this repo's `app/android` uses — the incompatibility isn't a
config issue on our side, the plugin's Android module predates AGP's
`namespace` requirement and there's no newer release fixing it (last publish:
2023, hosted on GitLab, no visible activity since).

Changes from the upstream 0.1.7 sources (`android/` only — `lib/` and `ios/`
are untouched):

- `android/build.gradle`: added `namespace 'how.virc.flutter_esp_ble_prov'`
  inside the `android {}` block.
- `android/src/main/AndroidManifest.xml`: removed the `package="..."`
  attribute. Current AGP treats declaring the namespace *both* ways (manifest
  `package` and `build.gradle` `namespace`) as a hard error, not a warning.

If a fixed upstream release ever appears, prefer switching back to the
pub.dev dependency over maintaining this fork.
