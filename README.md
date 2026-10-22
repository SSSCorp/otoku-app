# OtoKu Flutter prototype

An Indonesian-first vehicle-care prototype. App data is local while backend, payment, location, and map-provider decisions are pending.

## Run and test

```sh
flutter pub get
flutter run
flutter analyze
flutter test
```

## Local-first behavior

`OtoKuRepository` keeps persistence outside the widgets. SQLite stores vehicle details, mileage, manual activity, maintenance completion, cart quantities, bookings, and orders. SharedPreferences stores the small onboarding-complete setting. Tests can inject `MemoryOtoKuRepository`.

Seed/demo data: the product catalog, workshop/SPBU/minimarket listings, and maintenance intervals. Their UI marks compatibility, location, prices, schedules, and booking slots as demo or unverified. User-created data is stored locally on the device; there is no account, backend sync, real payment, or confirmed booking yet.

Manual mileage, BBM, service, expense, and sparepart logs work without OBD. Mileage decreases are rejected rather than silently overwriting the previous reading. Shop cart quantities, mock checkout, booking requests, and pending order states are local. OBD values are simulated and never presented as live adapter readings.

The Peta screen currently shows a local illustrative preview and filters seeded places. It does not request location or use a map API key. OpenStreetMap integration can be added when the provider/key and attribution approach are supplied. GPS trip estimates and SPBU visit detection are not implemented.

Product photos are illustrative Commons downloads, not exact SKU images. Creator and license credits are in [`assets/product_images/ATTRIBUTION.md`](assets/product_images/ATTRIBUTION.md).
