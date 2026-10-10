# OtoKu Flutter App PRD

**Document type:** Flutter mobile application product requirements and
implementation plan\
**Version:** 1.0\
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

Potential package choices (confirm versions before implementation): -
`dio` or `http` for networking - `go_router` for navigation -
`flutter_riverpod` for state management, or Bloc if the team already
uses it - `freezed`/`json_serializable` for immutable models and JSON
mapping - `flutter_secure_storage` for tokens - `cached_network_image`
for remote imagery - `geolocator` and a map SDK package selected with
the map provider - `image_picker` for vehicle photos - `intl` for
Indonesian number/date/currency formatting - Bluetooth package only
after the target OBD adapter and protocol are selected

Do not add packages solely because they are listed here. Confirm current
maintenance, platform support, licensing, and API compatibility before
choosing.

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
-   `/auth/*` as required

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

-   Sign in/create account using the selected auth method.
-   Explain why vehicle data is needed.
-   Let users register a vehicle or skip and explore where appropriate.
-   Handle loading, invalid input, expired session, and offline states.
-   Do not collect VIN/engine number unless needed.

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

3. **GPS-based distance estimation**
   - Estimate distance from location samples while a trip is active or an explicitly enabled tracking mode is running.
   - Treat GPS mileage as an estimate, not an authoritative odometer reading. GPS can drift, lose signal, or record movement when the user is not driving.
   - Display it separately as “Estimasi jarak GPS” and let users confirm, edit, or discard it before adding it to vehicle mileage.

**SPBU visit detection and fuel-refill confirmation**

OtoKu may detect that a vehicle appears to have stopped at an SPBU using GPS and place data. This is a candidate event, not proof that the user purchased fuel.

When the user next opens the app, show a non-blocking confirmation prompt if a credible, unconfirmed SPBU visit was detected. Example:

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
Error states for stock/price changes

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
-   Do not track user location continuously in the background.

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
-   Select service(s), date, and time where the workshop supports
    availability.
-   Add optional notes.
-   Show estimated price and booking policy.
-   Confirmation screen and booking status.
-   Prevent duplicate submission and handle slot conflicts.
-   Only show bookable slots returned by the backend.

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
-   Privacy and logout
-   Account deletion entry point if supported

## 7. State management and data flow

Use a consistent architecture. Recommended default: feature-first
folders with Riverpod providers, repositories, and typed API clients.
Bloc is acceptable if the team is already standardized on it.

Suggested layers: - **Presentation:** screens, widgets, form state -
**Application:** feature controllers/use cases - **Domain:** entities,
value objects, business rules where client-side logic is needed -
**Data:** API DTOs, repositories, cache, serialization

Backend remains the source of truth for: - Prices and totals -
Compatibility - Maintenance rules/status - Booking availability and
status - Order/payment status - OBD interpretation and freshness policy

Flutter may cache data for responsiveness but must not override server
authority.

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
- Show loading, empty, success, offline, and error states.
- Do not log tokens or private payloads.
- Handle pagination and image loading.
- Keep mock repositories available for UI development before backend endpoints are ready.

The Flutter app should use the backend contracts in `PRD_BACKEND.md`. Any API change must update API docs and client models together.

### Local-first development until the backend is ready

**For the current prototype phase, the app must work without a live backend.** Persist app data locally and simulate API behavior through repository interfaces and mock data. This is a temporary development strategy, not the final production architecture.

Requirements:
- Define repository interfaces for vehicles, vehicle events, maintenance, OBD, Shop, Map, bookings, and orders.
- Provide local/mock implementations first. Screens and state management must depend on repository interfaces, not directly on local storage or HTTP calls.
- Persist user-created prototype data locally so it survives app restarts: registered vehicles, selected vehicle, manual logs, maintenance changes, and mock cart/order/booking state where applicable.
- In local-first prototype mode, also persist the selected mileage source, GPS distance estimates awaiting confirmation, and pending/dismissed SPBU visit prompts. Use mock location/visit events for demos when real background tracking is not implemented.
- Use a local database for structured data (for example, SQLite through a maintained Flutter package such as Drift or sqflite). Use preferences only for small settings such as the selected vehicle ID or onboarding completion.
- Store mock catalog, workshop, SPBU, minimarket, OBD, booking, and order data in seed fixtures or local repositories. Treat sample records as demo data.
- Simulate loading, empty, success, and error states so the UI can be developed and tested before backend endpoints exist.
- Keep JSON models and repository method contracts aligned with `PRD_BACKEND.md` where practical, even while using local storage.
- Do not put database access directly inside widgets. Keep persistence in the data/repository layer so the storage implementation can be replaced without rewriting screens.
- Do not store real passwords, payment credentials, or sensitive authentication tokens in the local prototype database.
- Document which data is mock/seeded and which data was created by the user.

When the backend becomes available, add remote repository implementations using the same interfaces, then switch through dependency injection or environment configuration. Migrate local user-created data only if migration is explicitly required; do not silently overwrite server data. Keep a development/demo mode available for UI testing.

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
- Request background location only if background mileage tracking is explicitly enabled and the feature genuinely requires it; explain why before opening the platform permission flow.
- Map location permission and mileage-tracking permission are separate concerns. The app must remain usable when either is denied.
- Do not track continuously in the background by default. Respect OS permission state, provide a clear way to disable tracking, and minimize retained location data. Prefer storing a candidate SPBU, approximate visit time, confidence, and resolution status rather than a full route history.
- Use confidence thresholds, proximity/dwell-time rules, and deduplication to reduce false SPBU detections. Do not show low-confidence prompts.

### Photos

-   Request access only when adding/changing vehicle images or receipts.
-   Handle permission denial and camera/gallery cancellation.

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

### Phase 0 --- UX and API contract

-   Confirm screen flows and navigation.
-   Agree API schemas with backend.
-   Select map SDK, auth provider, and initial OBD target.
-   Create theme, routing, API client, and mock repositories.

### Phase 1 --- App foundation

-   Theme and reusable components
-   Auth/session handling
-   Bottom navigation
-   Error/loading/empty state system
-   CI, linting, formatting, and widget test setup

### Phase 2 --- Vehicle companion

-   Vehicle selection and profile
-   Home disconnected state
-   Manual logging
-   History and maintenance schedule
-   Home summary API integration

### Phase 3 --- OBD

-   Locked teaser and Shop promotion
-   OBD details states
-   Mock OBD simulator
-   Real adapter integration only for validated hardware/vehicles
-   Diagnostic code explanation

### Phase 4 --- Shop

-   Category/search/product list
-   Vehicle compatibility display
-   Product detail and cart
-   Checkout UI aligned to actual backend/payment scope

### Phase 5 --- Map and bookings

-   Map and category filters
-   Bottom sheet and place detail
-   Partner vs non-partner states
-   Booking flow for eligible workshops

### Phase 6 --- Orders and account

-   Order/booking history
-   Status detail and timeline
-   Account and addresses
-   Notification screens/preferences as required

### Phase 7 --- QA and pilot

-   Android/iOS device testing
-   Accessibility checks
-   Network and permission testing
-   Usability test tasks
-   Crash/error monitoring and release checklist

## 16. Testing plan

### Unit tests

-   Formatting and validation
-   Maintenance display calculations where duplicated client-side
-   State transitions in UI
-   Compatibility label rendering
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

1.  Register a vehicle and identify its next maintenance task.
2.  Add a fuel or service log without OBD.
3.  Understand what OBD unlocks and find it in Shop.
4.  View connected, stale, disconnected, and unsupported OBD states.
5.  Find a product and determine whether it is confirmed compatible.
6.  Filter the map to SPBU and partner workshops.
7.  Open a partner workshop and request a booking.
8.  Check order/booking status.
9.  Deny location permission and still search by area.
10. Confirm or dismiss a detected SPBU visit; verify that no fuel log is created until the user confirms.

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

-   Which auth method and provider?
-   Which map SDK/provider and attribution requirements?
-   Which state management approach will the team standardize on?
-   Which OBD adapter and exact vehicle matrix are in scope?
-   Will prototype mode use seeded/mock data?
-   Is checkout mock or connected to a payment provider?
-   Are non-partner workshop bookings excluded from MVP?
-   What offline write behavior is required?
-   What minimum Android/iOS versions will be supported?

## 19. Core principle

The Flutter app should make vehicle care simple and trustworthy. It must
remain useful without OBD, clearly represent data uncertainty, and keep
Home, Shop, and Peta focused on distinct user goals.
