# OtoKu Flutter App PRD

**Document type:** Flutter mobile application product requirements and
implementation plan\
**Version:** 1.2\
**Status:** Proposed baseline for MVP planning

## 1. Purpose

Build the OtoKu customer mobile app in Flutter for Android and iOS. The
app helps car and motorcycle owners manage their vehicles, track
maintenance, optionally connect OBD hardware, discover products, locate
automotive services, and manage bookings and orders.

This document defines client-side UX, app architecture, navigation,
state handling, API integration, and acceptance criteria. Backend
contracts are defined in `PRD_BACKEND.md`.

## 2. Product principles

1.  **Vehicle companion first:** Home prioritizes the selected vehicle,
    condition/known status, and next maintenance.
2.  **Useful without OBD:** manual mileage, service, fuel, and expense
    tracking remain first-class.
3.  **OBD is optional:** connected data is a capability enhancement, not
    a prerequisite.
4.  **Clear data confidence:** differentiate live, stale, unsupported,
    estimated, and unavailable data.
5.  **Shop is product-focused:** spareparts remain a category, not the
    entire shopping experience.
6.  **Peta is place-focused:** map partner/non-partner workshops,
    minimarkets, and SPBU.
7.  **Trust and compatibility:** clearly communicate fitment, partner
    verification, and transaction status.
8.  **Indonesian-first UX:** use concise Indonesian labels and
    explanations.

## 3. Target platforms and technical baseline

-   Flutter stable channel
-   Dart null safety
-   Android and iOS
-   Responsive layouts for common phone sizes (approximately 360--430
    logical px wide)
-   Material 3 foundations with a custom OtoKu theme
-   REST API over HTTPS
-   Secure token storage using a platform-backed secure-storage package
-   Use dependency versions pinned and reviewed by the implementation
    team

**Implementation defaults for MVP:** use `dio` for networking,
`go_router` for navigation, `flutter_riverpod` for state management,
`freezed`/`json_serializable` for typed models, `flutter_secure_storage`
for session credentials where applicable, `cached_network_image` for
remote imagery, `intl` for date/number formatting, and ARB-based
localization (`flutter_localizations` + `intl`). These are the baseline
choices, not permission to use unmaintained or incompatible package
versions; pin and review versions before implementation.

Use Google Maps for the current prototype with the available Google
Maps demo key. Treat this as prototype-only configuration: keep the key
outside source control, restrict it according to the provider's supported
key restrictions, and do not assume the demo key is suitable for a
production release. Keep a `MapProvider` abstraction so the UI is not
coupled to one map SDK. An OSM-based fallback is a future option only
after licensing, tile hosting, geocoding, caching, and attribution have
been reviewed. Do not assume provider data can be persisted or cached.
A production Google Maps project/key, billing configuration, quotas, and
data-use review are release blockers, not blockers for the local UI
prototype.

The minimum supported Android and iOS versions remain a Phase 0 release
blocker because BLE and active-trip background-location support depend
on them. Select and document them before choosing final platform package
versions. Do not add packages solely because they are listed here.

## 4. Navigation

Persistent bottom navigation:

1.  **Home**
2.  **Shop**
3.  **Peta**
4.  **Pesanan**
5.  **Akun**

Use nested routes for details. Keep navigation state predictable when
moving between tabs.

### Main routes

-   `/home`
-   `/vehicles`
-   `/vehicles/:id`
-   `/vehicles/:id/history`
-   `/vehicles/:id/maintenance`
-   `/vehicles/:id/obd`
-   `/shop`
-   `/shop/category/:categoryId`
-   `/shop/product/:productId`
-   `/cart`
-   `/map`
-   `/places/:placeId`
-   `/places/:placeId/booking`
-   `/orders`
-   `/orders/:orderId`
-   `/account`
-   `/account/addresses`
-   `/notifications`
-   `/auth/*` as required
-   `/trips/active`
-   `/trips/:tripId/review`

## 5. Visual design system

### Colors

  Token            Value       Use
  ---------------- ----------- -----------------------------
  Primary          `#E21B23`   Main CTA and selected state
  Primary dark     `#B81218`   Pressed state
  Background       `#F7F7F7`   Page background
  Surface          `#FFFFFF`   Cards
  Text primary     `#171717`   Headings/body
  Text secondary   `#6B6B6B`   Supporting copy
  Border           `#E8E8E8`   Separators
  Success          `#22A447`   Healthy/complete
  Warning          `#F59E0B`   Due soon
  Error            `#DC2626`   Critical/problem

### Typography

Use **Inter** as the primary typeface unless product design chooses
otherwise.

-   Screen title: 24 px, semibold/bold
-   Section title: 18 px, semibold
-   Card title: 16 px, semibold
-   Body: 14--16 px
-   Caption: 12--13 px
-   Metric: 20--24 px, bold
-   Use tabular numerals for changing metrics where supported.

### Layout

-   16 px horizontal page padding
-   12--16 px between cards
-   12--20 px card radius
-   Minimum 44 logical px interactive targets
-   Fixed bottom navigation
-   Scrollable content with keyboard-safe forms
-   Respect safe areas, text scaling, and system accessibility settings

## 6. Screen requirements

### 6.1 Authentication and onboarding

-   Prototype mode uses local/demo identity; no OAuth or live authentication is required during prototyping.
-   Explain why vehicle data is needed.
-   Let users register a vehicle or skip and explore where appropriate.
-   Handle loading, invalid input, expired session, and offline states.
-   Do not collect VIN/engine number unless needed.

### 6.1.1 Guided vehicle registration flow

Vehicle addition must be a guided, multi-step flow rather than a single long form. The primary path uses a preloaded vehicle catalog focused on cars and motorcycles commonly used in Indonesia, so users do not have to type make/model/year/variant manually.

Recommended steps:
1. **Vehicle type:** choose `Mobil` or `Motor`.
2. **Brand:** searchable list filtered by vehicle type.
3. **Model:** searchable list filtered by brand and vehicle type; show model image/illustration when available.
4. **Year/generation:** select from catalog-supported years/generations. Do not offer years or variants absent from the catalog.
5. **Variant:** choose a catalog variant when known. If variant identification is optional or the user is unsure, allow `Belum tahu` and preserve an unknown variant rather than guessing.
6. **Vehicle details:** nickname (optional), license plate (optional), and current odometer (optional, with unit appropriate to the vehicle).
7. **Vehicle image:** choose a catalog-provided image/illustration or add a custom image from camera/gallery; this step may be skipped.
8. **Review and save:** show a summary and allow the user to go back and edit previous steps.

Flow requirements:
- Show progress and preserve entered selections when navigating backward.
- Provide search, sensible popular/recent suggestions, and a clear empty state.
- If a make/model/year/variant is missing, offer `Kendaraan tidak ditemukan? Tambah manual`. Manual entry must still capture vehicle type, brand, model, year (if known), and variant (if known), and mark catalog-derived specifications as unknown.
- Do not block registration because a technical specification, variant, plate, odometer, or image is unknown.
- Validate catalog relationships server-side in connected mode. Local prototype mode uses the same catalog-shaped seed fixtures.
- Clearly distinguish a catalog match from verified OBD support, maintenance rules, or spare-part fitment. Selecting a vehicle identity must not automatically mark those capabilities as supported.
- The catalog must support aliases/common spellings used in Indonesia (for example, `Beat`/`BeAT`) for search, while displaying a canonical model name.
- If offline, allow the user to select from the locally seeded catalog and save locally; do not silently claim the catalog is current.

### 6.1.2 Custom vehicle image

Users can personalize each vehicle with either a built-in catalog image/illustration or their own photo.

- Image choices: `Pilih gambar kendaraan` (catalog image), `Ambil foto`, `Pilih dari galeri`, and `Gunakan gambar default`.
- Camera/gallery access is requested only after the user selects the corresponding action.
- Allow crop/preview, replace, and remove; preserve aspect ratio and use a consistent crop in vehicle cards and detail screens.
- If no custom image exists, show the catalog image; if that is unavailable, show a generic car/motor illustration based on vehicle type.
- The custom photo is a visual personalization only; it does not verify vehicle identity, condition, ownership, or compatibility.
- Handle permission denial, camera/gallery cancellation, unsupported format, upload failure, and image removal.
- In local-first mode, store the image locally and persist its reference. In backend-connected mode, upload through the authenticated upload flow and associate the returned asset with the vehicle.
- Provide a clear fallback when an image cannot be loaded. Do not require an image to complete vehicle registration.

### 6.2 Home --- OBD disconnected

Priority order: 1. Header with OtoKu, notifications, profile 2. Selected
vehicle card with image, name, plate, mileage, last service, and data
confidence 3. Next maintenance item(s) 4. Small, dismissible OBD
promotional banner 5. Locked OBD metric preview 6. Recent tracking/log
summary and manual "+ Catat" action

The OBD banner should be non-intrusive and must not dominate the first
viewport. Main product information and purchase CTA live in Shop.

Locked metric examples: - RPM - Speed - Engine temperature -
Battery/control voltage - Fuel level when supported - Fuel consumption
when available

Show placeholders and lock state, never fabricated readings.

### 6.3 Home --- OBD connected

-   Show connection state and last update time.
-   Show only fresh, supported metrics.
-   Label units clearly.
-   Show diagnostic summary with severity and plain-language entry
    point.
-   Show maintenance progress only when odometer source/freshness is
    known.
-   Provide a way to open detailed OBD information.
-   If values become stale, visibly change their status rather than
    leaving them looking live.

### 6.4 Vehicle details

-   Vehicle image and core identity.
-   Change image using a catalog image, camera, gallery, or default illustration.
-   Edit profile and photos.
-   Show specifications only when provided.
-   Keep VIN and engine number private.
-   Links to history, maintenance, and OBD.
-   Confirm before deletion.

### 6.5 History and tracking

Tabs: - Timeline - Grafik - Biaya

Events include odometer, fuel, expense, service, part replacement, and
notes. Filter by event type/date. Add/edit/delete according to backend
permissions. Provide clear empty states.

**Mileage tracking sources**

OtoKu supports three ways to track vehicle mileage. Users should see which source is being used and be able to correct inaccurate values.

1. **Manual entry**
   - Users enter the current vehicle odometer reading themselves.
   - This is the baseline and must work without GPS or OBD.
   - Validate non-negative values and flag suspicious decreases rather than silently overwriting the previous reading.
   - Show the reading timestamp and source.

2. **OBD**
   - Read odometer data only when the connected vehicle/adapter exposes a reliable odometer value.
   - Many OBD setups do not provide a standard odometer PID, so never assume it is available.
   - OBD may still provide other supported readings when odometer data is unavailable.
   - Show connection status, last update time, and data source.

3. **GPS trip distance estimation**
   - GPS sampling runs only during a trip the user explicitly starts. Nothing samples location when there is no active trip.
   - Treat GPS mileage as an estimate, not an authoritative odometer reading. GPS can drift, lose signal, or record movement when the user is not driving.
   - Display it separately as “Estimasi jarak GPS” and let users review, edit, confirm, or discard it before it affects vehicle mileage.
   - A confirmed trip contributes a mileage event with source `gps_trip`. The trip record, detailed samples, and route polyline remain client-only in MVP; sync only the confirmed mileage event.
   - Filter low-accuracy samples and implausible GPS jumps, and handle tunnels/signal loss. Do not assume the device owner is the driver; review is required before confirmation.

**SPBU visit detection and fuel-refill confirmation**

OtoKu may detect that a vehicle appears to have stopped at an SPBU using GPS and place data only during an explicitly active trip. This is a client-only candidate event, not proof that the user purchased fuel. The candidate lifecycle is `pending_review → confirmed | dismissed`, with a `snoozed` presentation state that returns to pending review later. Candidates are persisted locally and are not synced to the backend.

At trip end, show a non-blocking confirmation prompt if a credible, unconfirmed SPBU visit was detected. Do not wait until the next app launch to imply that detection ran while the app was closed. Example:

> **Isi bensin di SPBU?**
>
> Kami mendeteksi kunjungan ke **SPBU XYZ** pada **{tanggal}**. Apakah Anda mengisi bensin?
>
> **[Ya, catat isi bensin]**  **[Tidak]**  **[Nanti]**

If the user selects “Ya, catat isi bensin”:
- Open a short fuel-log form.
- Pre-fill the SPBU name and visit date/time.
- Let the user enter fuel type, volume in liters (optional), total cost (optional), and odometer if known.
- Save only after the user confirms. Never infer fuel volume or cost from a location visit.
- Mark the candidate visit as resolved after saving so the prompt is not repeated.

If the user selects “Tidak”, mark the candidate visit as dismissed and do not prompt again for that event.

If the user selects “Nanti”, snooze the prompt and retain it in a pending activity area. Avoid showing it on every app launch.

Detection rules:
- Use confidence thresholds and configurable proximity/dwell-time rules to reduce false positives.
- Deduplicate repeated location samples and repeat visits.
- Do not run continuous background location outside an explicitly active trip. Active-trip tracking may require an Android foreground service with a persistent notification and iOS background-location capability; disclose this in context and request only the permissions required for the selected platform behavior.
- Add a visible active-trip indicator, start/stop controls, crash/app-kill recovery, and conservative auto-stop rules. Provide troubleshooting guidance for aggressive battery management on common Android OEMs, including Xiaomi, Oppo, and Vivo.
- Retain only trip distance/summary and local candidate metadata for MVP; do not retain or upload route polylines.
- Never create a fuel log automatically from GPS detection alone.
- If confidence is low, do not prompt; the user can still add fuel manually.

### 6.6 Manual logging

A clear "+ Catat" action opens a concise selector: - Kilometer - BBM -
Servis - Biaya - Penggantian sparepart

Use forms with validation, date/time, odometer when relevant, amount,
notes, and optional receipt/photo. Do not require OBD.

### 6.7 Maintenance schedule

Tabs: - Rekomendasi - Semua - Selesai

Each item displays component, due date/distance, progress, and
source/confidence if relevant. Allow marking completed and scheduling
manually. Do not invent a due interval when the backend returns unknown.

### 6.8 OBD details

States: - Not connected - Connecting - Connected - Stale/no recent
readings - Unsupported vehicle/parameter - Error

Show: - Device status and last update - Real-time metrics - Diagnostic
trouble codes - Plain-language meaning, possible causes, and next
steps - CTA to browse relevant products/workshops when useful

Do not claim a DTC identifies a failed part with certainty. Bluetooth
scanning/connection must only be implemented after the target adapter
and vehicle support matrix is selected. Provide a mock OBD mode for
prototype/demo.

### 6.9 Shop home

-   Search bar
-   Categories such as Sparepart, Oli & Cairan, Aksesori, and Perangkat
    OBD
-   Products recommended for the selected vehicle
-   OBD product promotion
-   Filters and sort options
-   Cart entry point

Product cards should show price, product image, stock/availability if
known, and compatibility state. The product should not be labeled
compatible unless fitment is confirmed.

### 6.10 Product details and cart

Product detail includes: - Image gallery - Name, brand, description -
Price and stock status - Compatibility with selected vehicle - Warranty
and seller information where available - Reviews only if backed by real
data - Add to cart / buy action

Cart: - Quantity changes - Price summary - Address selection - Clear
prototype/mock checkout state if real payments are not integrated -
Error states for stock/price changes. For MVP checkout, label the order
and all relevant screens `Simulasi`; show `payment_mode: mock` and use
an explicit demo action to advance simulated status rather than timers
that resemble a real payment. Generate an idempotency key for order
creation and reuse it for retries of the same logical submission.

### 6.11 Peta

-   Full-screen map as the main surface.
-   Search field at top.
-   Category filters for partner workshop, non-partner workshop,
    minimarket, and SPBU.
-   Distinct partner verification styling.
-   Recenter control and map zoom controls where supported.
-   Draggable bottom sheet for nearby places.
-   Tapping pin opens a compact preview; tapping preview opens place
    detail.
-   Offer manual location/area search when location permission is
    denied.
-   Request foreground location only when needed.
-   Do not track user location continuously in the background. Location sampling for mileage/SPBU detection is limited to an explicitly active trip; outside that lifecycle, no trip sampling runs.

The UI must distinguish: - OtoKu partner (verified/partner status) -
Non-partner workshop (not endorsed by OtoKu) - External place data with
unknown hours/details

### 6.12 Place and workshop detail

-   Name, category, address, hours when known, phone, distance if
    available, source/verification status.
-   Partner workshop: services, price estimates, duration, booking CTA
    if enabled.
-   Non-partner workshop: directions and contact options; no in-app
    booking unless a supported workflow exists.
-   SPBU/minimarket: directions, contact/opening info only when
    available.
-   Display unknown hours rather than implying a place is open.

### 6.13 Booking

-   Select vehicle.
-   Select service(s), a preferred date, and a preferred time window; this is a request, not a reserved slot.
-   Add optional notes.
-   Show estimated price and booking policy.
-   State clearly that the booking is not confirmed until the workshop accepts it.
-   Support `requested`, `confirmed`, `rejected`, `cancelled`, `expired`, `in_progress`, `completed`, and `no_show` states.
-   Show the response deadline and explain when an unanswered request expires.
-   For MVP, partner workshops accept/reject requests through a partner web portal or equivalent partner surface; customer booking is not end-to-end until that surface and partner notifications exist.
-   Counter-offers are out of scope for MVP; a partner can reject and ask the customer to submit a new request.
-   Protect submissions with idempotency keys. Do not show a slot picker or imply real-time availability.

### 6.14 Pesanan

Tabs or filters for product orders and service bookings. - Status and
reference number - Item/service summary - Payment and shipping status
where applicable - Order detail timeline - Booking detail, cancellation
policy, and contact route - Do not display payment success unless
backend confirms it.

### 6.15 Akun

-   Profile
-   Registered vehicles
-   Addresses
-   Orders/bookings
-   Help and about
-   Privacy, notification preferences, and logout
-   Account deletion entry point with a clear confirmation and consequences
-   Upload/manage saved addresses through the account-address API

## 7. State management and data flow

Use a consistent architecture. Recommended default: feature-first
folders with Riverpod providers, repositories, and typed API clients.
Bloc is acceptable if the team is already standardized on it.

Suggested layers: - **Presentation:** screens, widgets, form state -
**Application:** feature controllers/use cases - **Domain:** entities,
value objects, business rules where client-side logic is needed -
**Data:** API DTOs, repositories, cache, serialization

Backend remains the source of truth for: - Prices and totals -
Compatibility - Maintenance rules/status in backend-connected mode -
Booking status - Order/payment status - OBD interpretation and freshness
policy. Booking uses request-and-confirm, not slot availability.

Flutter may cache data for responsiveness but must not override server
authority. Local-first prototype mode necessarily duplicates selected
maintenance presentation calculations and OBD freshness behavior because
the backend is absent. Treat this as temporary prototype logic, document
the duplicated rules, and use shared JSON test fixtures/expected outputs
to verify local and remote implementations agree. In production mode,
backend-calculated summary/status values take precedence; local
calculations must not silently override them.

## 8. Suggested folder structure

``` text
lib/
  main.dart
  app/
    app.dart
    router.dart
    theme/
      app_colors.dart
      app_theme.dart
      typography.dart
  core/
    api/
      api_client.dart
      api_error.dart
    auth/
    config/
    formatting/
    permissions/
    storage/
    widgets/
  features/
    auth/
      data/
      domain/
      presentation/
    home/
      data/
      domain/
      presentation/
    vehicles/
      data/
      domain/
      presentation/
    tracking/
      data/
      domain/
      presentation/
    maintenance/
      data/
      domain/
      presentation/
    obd/
      data/
      domain/
      presentation/
    shop/
      data/
      domain/
      presentation/
    cart/
      data/
      domain/
      presentation/
    map/
      data/
      domain/
      presentation/
    places/
      data/
      domain/
      presentation/
    bookings/
      data/
      domain/
      presentation/
    orders/
      data/
      domain/
      presentation/
    account/
      data/
      domain/
      presentation/
```

## 9. API integration

Use the backend's versioned `/api/v1` REST API. Keep base URLs configurable by environment.

Requirements:
- Typed request/response models.
- Centralized API client and error mapping.
- Attach auth credentials securely.
- Refresh/expire sessions according to the chosen auth provider.
- Support cancellation/timeouts and retry only safe/idempotent requests.
- Generate an `Idempotency-Key` for order creation, booking requests, and
  other non-idempotent writes where the API contract requires it. Reuse
  the same key only when retrying the same logical action; create a new
  key for a new user action. Never automatically retry writes whose
  idempotency contract is not documented.
- Show loading, empty, success, offline, and error states.
- Do not log tokens or private payloads.
- Handle pagination and image loading. Product lists use documented
  filters/sort fields and cursor pagination (or the exact scheme defined
  by OpenAPI); do not infer page shape in client code.
- Keep mock repositories available for UI development before backend endpoints are ready.

The Flutter app should use the backend contracts in `PRD_BACKEND.md`. Any API change must update API docs and client models together.

### Local-first development until the backend is ready

**For the current prototype phase, the app must work without a live backend.** Persist app data locally and simulate API behavior through repository interfaces and mock data. This is a temporary development strategy, not the final production architecture.

Requirements:
- Define repository interfaces for vehicles, vehicle events, maintenance, OBD, Shop, Map, bookings, and orders.
- Provide local/mock implementations first. Screens and state management must depend on repository interfaces, not directly on local storage or HTTP calls.
- Persist user-created prototype data locally so it survives app restarts: registered vehicles, selected vehicle, manual logs, maintenance changes, and mock cart/order/booking state where applicable.
- In local-first prototype mode, also persist the selected mileage source, GPS trip summaries/estimates awaiting confirmation, and pending/dismissed/snoozed SPBU visit candidates. Trip details and SPBU candidates are client-only in MVP; do not sync raw route/location history. Use mock location/visit events for demos when real active-trip tracking is not implemented.
- Use a local database for structured data (for example, SQLite through a maintained Flutter package such as Drift or sqflite). Use preferences only for small settings such as the selected vehicle ID or onboarding completion.
- Store mock catalog, workshop, SPBU, minimarket, OBD, booking, and order data in seed fixtures or local repositories. Treat sample records as demo data.
- Simulate loading, empty, success, and error states so the UI can be developed and tested before backend endpoints exist.
- Keep JSON models and repository method contracts aligned with `PRD_BACKEND.md` where practical, even while using local storage.
- Do not put database access directly inside widgets. Keep persistence in the data/repository layer so the storage implementation can be replaced without rewriting screens.
- Do not store real passwords, payment credentials, or sensitive authentication tokens in the local prototype database.
- Document which data is mock/seeded and which data was created by the user.

When the backend becomes available, add remote repository implementations using the same interfaces, then switch through dependency injection or environment configuration. Migrate local user-created data only if migration is explicitly required; do not silently overwrite server data. Keep a development/demo mode available for UI testing.

Local-first mode is a development/prototype mode, not a claim that production maintenance calculations are server-authoritative while offline. Any locally calculated maintenance summary or OBD freshness state must be marked as demo/local behavior and tested against shared fixtures. In production-connected mode, use backend summary and maintenance responses as authoritative.

## 10. Offline and caching behavior

For the backend-connected MVP (after local-first prototype development): - Cache read-only data where useful: vehicle summary,
maintenance list, recent events, product/category metadata. - Make cache
age visible for data that may change. - Queueing writes offline is
optional and should not be added without conflict handling. - If
offline, allow drafting a manual log only if it can be safely reconciled
later; otherwise explain that saving requires connectivity. - Never show
cached OBD values as live. - Do not cache sensitive information longer
than needed.

## 11. Permissions and hardware

### Location

OtoKu uses location for these user-facing functions:
- **Map and nearby places:** show the user's position and help find nearby workshops, SPBU, and other map categories. If permission is denied, allow searching by area or place name.
- **GPS mileage estimation:** collect location samples only during an active trip or explicitly enabled tracking mode; present the result as an estimate that users can review before it affects their vehicle mileage.
- **SPBU visit suggestions:** identify a possible SPBU stop so the app can ask whether the user refueled. A detected visit is only a suggestion and must never create a fuel log without user confirmation.

Permission and privacy requirements:
- Ask for foreground location permission when the user invokes a location-dependent feature, and explain the benefit in context.
- Request platform permissions needed for an explicitly active trip only after in-context disclosure. Active-trip background behavior may require an Android foreground service and iOS background-location capability; no always-on tracking is permitted in MVP.
- Map location permission and active-trip tracking permission are separate concerns. The app must remain usable when either is denied.
- Do not track continuously in the background by default. Respect OS permission state, provide a clear way to disable tracking, and minimize retained location data. Prefer storing a candidate SPBU, approximate visit time, confidence, and resolution status rather than a full route history.
- Use confidence thresholds, proximity/dwell-time rules, and deduplication to reduce false SPBU detections. Do not show low-confidence prompts.

### Photos

-   Request access only when the user chooses camera/gallery for a vehicle image or receipt.
-   Handle permission denial and camera/gallery cancellation.
-   Compress/resize custom images before upload within documented size limits; keep the original local image only if needed for the prototype. Show upload progress and retryable failure states.

### Bluetooth/OBD

-   Select the exact supported adapter and protocols first.
-   Implement platform-specific permissions and lifecycle handling.
-   Handle adapter absent, pairing failure, disconnect, unsupported PID,
    and stale values.
-   Keep OBD connection logic behind an interface so UI and API
    integration can be tested with a simulator.
-   Do not infer support from connector shape alone.

## 12. Error and empty states

Every data-driven screen must define: - Initial loading -
Pull-to-refresh or explicit refresh where appropriate - Empty state -
Recoverable error - Offline state - Permission denied state where
applicable - Partial data/unsupported fields

Use concise Indonesian messages. Example: - "Data belum tersedia untuk
kendaraan ini." - "Koneksi OBD terputus. Coba hubungkan kembali." -
"Lokasi tidak diizinkan. Cari area secara manual." - "Kompatibilitas
produk belum terverifikasi."

## 13. Accessibility and usability

-   Support text scaling and screen readers.
-   Do not rely on color alone to communicate status.
-   Use readable contrast and touch targets.
-   Provide labels for icon-only controls.
-   Respect safe areas and keyboard insets.
-   Keep diagnostic explanations short by default with expandable
    detail.
-   Avoid auto-rotating banners that move too quickly or distract users.

## 14. Analytics and product validation

Track only necessary, privacy-reviewed product events, such as: -
Vehicle created - Manual log created - Maintenance item
opened/completed - OBD promotion opened - OBD connection
attempt/result - Product search and compatibility view - Map filter
selected/place detail opened - Booking started/completed - Checkout
started/order created

Do not log VIN, engine number, precise location history, diagnostic
payloads, or sensitive personal data in analytics.

Measure: - Task completion rate - Time to find next maintenance - OBD
feature discovery without banner interruption - Product compatibility
comprehension - Time to locate an SPBU/partner workshop - Manual log
completion rate - Booking/order flow error rate

## 15. Implementation plan

### Phase 0 --- Decisions and API contract

- Confirm screen flows and navigation.
- Select identity provider/auth architecture, map provider and licensing model, minimum Android/iOS versions, and initial OBD target/vehicle matrix.
- Confirm OpenAPI contracts, request idempotency rules, account deletion/retention behavior, and the client-only trip/SPBU data policy.
- Confirm partner booking portal ownership and mock-checkout behavior.
- Create theme, routing, API client, repository interfaces, local database, seeded fixtures, and shared business-rule test fixtures.

### Phase 1 --- Local-first prototype foundation

- Theme and reusable components
- Local profile/vehicle setup and demo-mode session state; live authentication is not required to explore the prototype
- Bottom navigation
- Error/loading/empty/offline state system
- Local repositories and persistence
- CI, linting, formatting, and widget/unit test setup

### Phase 2 --- Backend connection and identity

- Integrate the selected identity provider and session lifecycle
- Implement remote repositories against the published OpenAPI contract
- Add safe local-to-remote transition behavior without silently overwriting server data
- Validate parity against shared fixtures

### Phase 3 --- Vehicle companion

- Guided vehicle registration flow with Indonesian catalog seed data
- Vehicle profile and custom image selection/upload
- Home disconnected state
- Manual logging
- History and maintenance schedule
- Home summary API integration; backend values are authoritative in connected mode

### Phase 4 --- OBD

- Locked teaser and Shop promotion
- OBD details states
- Mock OBD simulator
- Real adapter integration only for validated hardware/vehicles
- Supported-parameter registry, sampling/batching, diagnostic code explanation

### Phase 5 --- Shop

- Category/search/product list with documented filters and pagination
- Vehicle compatibility display and unknown-fitment empty state
- Product detail and cart
- Mock checkout labeled `Simulasi`

### Phase 6 --- Map and bookings

- Map provider abstraction and category filters
- Bottom sheet, place detail, and search by name/area without location permission
- Partner vs non-partner states
- Request-and-confirm booking flow with preferred date/time window and response deadline
- Partner booking surface and customer/partner notifications must exist for end-to-end booking

### Phase 7 --- Orders and account

- Order/booking history and status detail/timeline
- Order cancellation and confirm-delivery where eligible
- Account, addresses, account deletion, notification screens/preferences
- Upload flow for vehicle photos and receipts

### Phase 8 --- QA and pilot

- Android/iOS device testing on the declared minimum OS versions
- Active-trip location and BLE lifecycle testing, including OEM battery restrictions
- Accessibility checks
- Network and permission testing
- Usability test tasks
- Crash/error monitoring and release checklist

## 16. Testing plan

### Unit tests

-   Formatting and validation
-   Maintenance display calculations where duplicated client-side
-   State transitions in UI
-   Compatibility label rendering
-   Vehicle catalog search, alias matching, and type/brand/model/year/variant filtering
-   Vehicle registration flow state preservation and manual fallback
-   Custom image selection, fallback, and upload state
-   OBD state mapping
-   Error mapping

### Widget tests

-   Home disconnected/connected states
-   Locked metric preview
-   Manual log forms
-   Product compatibility states
-   Map filter chips and place preview
-   Booking validation
-   Order status rendering

### Integration tests

-   Authentication and API session
-   Vehicle CRUD
-   Logs and maintenance
-   OBD mock/real state
-   Shop/cart
-   Map/places
-   Booking/order flows

### Acceptance tasks

1. Register a vehicle using the guided catalog flow without manually typing make/model/year when the vehicle is present.
2. Add a vehicle image from the catalog or a custom photo; verify default/fallback behavior.
3. Identify the vehicle's next maintenance task.
4. Add a fuel or service log without OBD.
5. Understand what OBD unlocks and find it in Shop.
6. View connected, stale, disconnected, and unsupported OBD states.
7. Find a product and determine whether it is confirmed compatible.
8. Filter the map to SPBU and partner workshops.
9. Open a partner workshop and request a booking.
10. Check order/booking status.
11. Deny location permission and still search by area.
12. Confirm or dismiss a detected SPBU visit; verify that no fuel log is created until the user confirms.

## 17. Definition of done

A feature is complete when: - UI matches the agreed design system and
responsive behavior. - Loading, empty, error, offline, and permission
states are handled. - API models and error states match backend
contracts. - Sensitive data is not logged or exposed. - Unit/widget
tests cover critical behavior. - Accessibility labels and touch targets
are in place. - The feature works on supported Android and iOS
versions. - No UI claims unsupported OBD capability or unverified
product fitment. - Product and booking/payment states reflect backend
truth.

## 18. Key decisions still required

- Production identity provider and token/session architecture (deferred; local/demo identity is used in prototyping).
- Production Google Maps project/key, billing, quotas, restrictions, and place-data licensing review (demo key is for prototyping only).
- Which state management approach will the team standardize on? Default is Riverpod.
- Which OBD adapter and exact vehicle/parameter matrix are in scope?
- Vehicle catalog source, data owner, update cadence, and licensed catalog image/illustration source.
- Fitment seed source and approval ownership.
- Partner portal implementation/owner and partner notification delivery.
- Minimum Android/iOS versions.
- Whether any local prototype data must be migrated after sign-in.
- Whether non-partner workshop booking remains excluded from MVP (default: excluded).
- Whether any offline writes are required beyond local drafts and client-only trip/candidate data (default: no queued remote writes).

## 19. Cross-cutting implementation contracts

### Identity and session lifecycle

**Prototype:** use local/demo identity state only. OAuth and live authentication are out of scope for the prototyping phase; do not build sign-in provider integration or require a backend session to explore the app.

**Backend-connected/production phase:** choose a specific identity provider and document sign-in/token exchange, refresh/expiry, sign-out/revocation, and account deletion. “OAuth” alone is not a provider decision. If Google sign-in is offered on iOS, verify current App Store requirements for an equivalent sign-in option such as Sign in with Apple before release. Never treat local demo-mode identity as a production session.

### Uploads, addresses, and notifications

Vehicle photos and receipts use an authenticated backend upload-intent/presigned-URL flow; the client must not embed object-storage credentials. Account addresses use explicit list/create/update/delete APIs. Notification screens and preferences require APIs for listing, read state, preferences, and push-token registration/removal. Do not ship inert screens that imply server-side notification support before those contracts exist.

### Money, search, and pagination

IDR values are integers in API models and application logic; never represent currency amounts as `double`. Format IDR only at the presentation layer. Product search must support documented query, category, fitment, price/stock filters, sort options, and a documented pagination envelope. Reviews are out of MVP unless a real review model and API are approved.

### Odometer source precedence and correction UX

The app must show the current odometer source and timestamp. A new reading is not accepted solely because its source is usually more trusted: source precedence is `manual-confirmed / gps_trip-confirmed / obd-validated / imported` only as an input-quality guide, while the backend's accepted current value is authoritative. The backend must compare timestamp, source, magnitude, and regression rules; conflicting readings must be surfaced for review rather than silently overwriting one another. A suspicious decrease opens a correction flow that requires the user to enter a reason; submit `correction_reason` with the proposed reading. Show the previous value, proposed value, source/time, and reason before confirmation. The server returns accepted, rejected, or review-required status, and the client reflects that response.

### Active-trip lifecycle and data retention

Trip state is `active → pending_review → confirmed | discarded`. Provide a visible active-trip indicator, explicit start/stop, conservative auto-stop, and recovery after app kill/crash. Apply accuracy and jump filters; allow users to correct the estimated distance before confirmation. Keep detailed location samples and route polylines on-device only in MVP, and delete raw samples after the trip summary has been finalized according to a documented local retention policy. Only a confirmed `gps_trip` mileage event is synced.

### Shared calculation fixtures

Create versioned JSON fixtures for maintenance boundary cases, due-soon thresholds, OBD freshness transitions, odometer conflicts/regressions, and trip-distance filtering. Run the same expected-result fixtures against local prototype logic and backend behavior wherever rules overlap. Backend responses remain authoritative in connected production mode.

## 20. Core principle

The Flutter app should make vehicle care simple and trustworthy. It must
remain useful without OBD, clearly represent data uncertainty, and keep
Home, Shop, and Peta focused on distinct user goals.
