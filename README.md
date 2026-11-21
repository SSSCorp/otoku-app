# OtoKu Flutter prototype

An Indonesian-first vehicle-care prototype that runs **fully locally**: no backend, no accounts, no real payments. It includes a real map (OpenStreetMap by default) with live location, routes, GPS trips and SPBU visit detection.

## Run and test

```sh
flutter pub get
flutter run --print-dtd      # --print-dtd lets the Dart/Marionette agent tooling attach
flutter analyze
flutter test
```

No `.env` is needed. With no configuration the app uses OpenStreetMap and no API key, so `flutter analyze`, `flutter test` and `flutter run` work on a fresh clone.

### Map provider (optional Google Maps)

Configuration is read with `--dart-define` (see `lib/core/app_config.dart`):

| Define | Default | Meaning |
| --- | --- | --- |
| `MAP_PROVIDER` | `osm` | `osm` or `google` |
| `GOOGLE_MAPS_API_KEY` | empty | Maps SDK key, only used when `MAP_PROVIDER=google` |

```sh
flutter run --print-dtd --dart-define=MAP_PROVIDER=google --dart-define=GOOGLE_MAPS_API_KEY=<key>
```

The Android build also reads `GOOGLE_MAPS_API_KEY` (environment variable or a project-root `.env`, see `.env.example`) for the manifest. If Google is requested but no key is present, the app falls back to OpenStreetMap and says so on the Peta screen. Keep unrelated secrets (for example Stitch keys) out of any file you pass to `--dart-define-from-file`, because defines are compiled into the app.

Troubleshooting a blank Google map on Android (check `adb logcat | grep "Maps SDK"`):

- `Authorization failure` / `Error requesting API token`: the key is present but rejected. Enable **billing** on the Cloud project, enable **Maps SDK for Android**, and restrict the key to package `com.example.otoku` plus your signing SHA-1 (`keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android` for debug builds).
- Desktop and web use OpenStreetMap: `google_maps_flutter` has no Linux/macOS/Windows renderer.

## What works

All flows are reachable from the bottom navigation (Beranda, Toko, Peta, Pesanan, Akun):

- **Peta (real map)**: OpenStreetMap tiles (cached on disk, max 200 MB / 7 days, attribution shown), the user's live position with a recenter button, clustered category markers, search by name, filters (bengkel partner / non-partner, SPBU, minimarket), sorting by distance or name, and a selection that survives panning and zooming. Location permission is requested on the Peta tab; denied, permanently denied, GPS-off and offline states each have an Indonesian message with an action.
- **Place detail**: real distance from the user, opening hours (open/closed now), services, and a route action: driving distance and ETA from the public OSRM server drawn on the map, or hand-off to an external maps app.
- **Booking layanan**: from any bengkel, pre-filled with the vehicle and bengkel (and the service that triggered it), saved locally as a Pesanan and visible in order history.
- **Nearest bengkel suggestions** from due or overdue maintenance and from simulated OBD trouble codes.
- **GPS trips**: start/stop, distance and duration while the app is open, offer to add the distance to the odometer. Mileage decreases are rejected.
- **SPBU visit detection**: stopping near an SPBU for 30 s while the app is open prompts to log BBM.
- **Vehicles**: add, edit, delete (the last vehicle is kept), and switch the active vehicle. Maintenance, compatibility and logs follow the active vehicle.
- **Maintenance**: due soon / overdue from vehicle interval and odometer, mark done, service history.
- **Manual logs**: mileage, BBM, service, expense and sparepart, with edit and delete.
- **Toko**: compatibility against the active vehicle, cart, mock checkout and simulated order status.
- **OBD**: a simulated adapter flow (scan, pick adapter, connect) with explained DTCs; always labelled as simulation.
- **Pesanan**: sparepart purchases and bookings with simulated status steps, persisted across restarts.
- Onboarding, plus an empty or error state on each screen (including a recoverable error if stored data cannot be read).

## Local-first behavior

`OtoKuRepository` keeps persistence outside the widgets. SQLite stores the app state (vehicles, logs, maintenance records, orders, trips, cart, address, simulated OBD session); SharedPreferences stores the onboarding-complete flag. Tests inject `MemoryOtoKuRepository`. Older single-vehicle saves are migrated on load.

Seed/demo data: the product catalog, fourteen places around BINUS Bekasi (names and coordinates from OpenStreetMap; opening hours and services are illustrative and unverified, and only the OtoKu partner bengkel is bookable) and maintenance intervals. The UI labels hours and services as unverified. Distances are always computed from the user's real position; if you are far from Bekasi the map says so and offers to jump to the sample area.

What is simulated: payment, order and booking confirmation, delivery, OBD adapter data and trouble codes. What is real: map tiles, device location, OSRM routes.

Limits worth knowing: trips and SPBU detection only run while OtoKu is open (no background service); the public OSRM server has no uptime guarantee; deleting the last vehicle is blocked.

## Android emulator tips

The emulator's default location is in California. Set it near the sample places, and move it to drive a trip:

```sh
adb emu geo fix 107.0000 -6.2190     # longitude latitude (near BINUS Bekasi)
```

Product photos are illustrative Commons downloads, not exact SKU images. Creator and license credits are in [`assets/product_images/ATTRIBUTION.md`](assets/product_images/ATTRIBUTION.md). Map data © OpenStreetMap contributors.

`screenshots/` holds a walkthrough captured on an Android emulator with Marionette.
