# OtoKu Backend PRD

**Document type:** Backend product requirements and implementation plan\
**Version:** 1.2\
**Status:** Proposed baseline for MVP planning

## 1. Purpose

Build the backend for OtoKu, a vehicle companion and automotive services
platform. The backend provides secure APIs and shared business logic for
vehicle profiles, maintenance logs, OBD data, product catalog and
compatibility, map locations, workshop bookings, orders, and
notifications.

The mobile client must not connect directly to the database. All
privileged operations must pass through the backend API.

## 2. Product goals

-   Support user accounts and multiple vehicles per user.
-   Support manual odometer, fuel, expense, and service logs.
-   Calculate maintenance status from approved rules and known
    mileage/date data.
-   Accept normalized OBD readings and diagnostic codes without assuming
    universal vehicle support.
-   Provide product catalog and explicit vehicle compatibility.
-   Support map search for partner workshops, non-partner workshops,
    minimarkets, and SPBU.
-   Distinguish verified OtoKu partners from third-party locations.
-   Support workshop booking and product order lifecycles.
-   Provide admin functions for catalog, partner verification,
    maintenance rules, and diagnostic guidance.

## 3. Non-goals for MVP

-   Universal OBD compatibility or development of OBD firmware.
-   Definitive mechanical diagnosis from DTC codes.
-   Real-time GPS vehicle/theft tracking.
-   Live inventory integration with every seller.
-   Payment settlement or delivery integrations before providers are
    selected.
-   Microservices unless scale or team ownership later requires them.

## 4. Recommended architecture

Start with a **modular monolith**.

Suggested stack: - TypeScript + NestJS (or Fastify) - PostgreSQL -
PostGIS for geospatial queries - Redis/queue only when needed for
scheduled work - S3-compatible object storage for images and receipts -
Managed identity provider or secure server-side auth - Licensed
map/place provider selected for Indonesian coverage - OpenAPI/Swagger -
Containerized deployment and managed database where practical

Modules: 1. Identity & Access 2. Vehicles 3. Vehicle Events &
Maintenance 4. OBD & Diagnostics 5. Catalog & Compatibility 6. Places &
Map 7. Workshops & Booking 8. Cart & Orders 9. Notifications 10. Admin &
Audit

``` text
Flutter App
    | HTTPS / JSON
    v
OtoKu API (modular monolith)
    +-- Identity
    +-- Vehicles
    +-- Maintenance
    +-- OBD / Diagnostics
    +-- Shop / Compatibility
    +-- Places / Map
    +-- Workshops / Bookings
    +-- Cart / Orders
    +-- Notifications / Admin
    |
    +--> PostgreSQL + PostGIS
    +--> Object storage
    +--> Maps / geocoding provider
    +--> Push provider
    +--> Payment provider (if selected)
```

## 5. Roles

-   **Customer:** manages vehicles, logs, products, bookings, and
    orders.
-   **Workshop partner:** manages profile, services, opening hours, and
    booking requests.
-   **Catalog operator/seller:** manages products, pricing, stock, and
    compatibility.
-   **OtoKu administrator:** verifies partners and manages catalog,
    maintenance rules, diagnostic guidance, and support.
-   **External place provider:** supplies licensed third-party place
    data.
-   **OBD/mobile integration:** reads supported adapter data client-side
    and submits normalized data.

## 6. Functional requirements

### 6.1 Identity and access

-   Sign in and manage user profile.
-   Support customer, partner, and admin roles.
-   Enforce authorization at the resource level on every private
    endpoint.
-   Avoid storing passwords when using a managed identity provider.

### 6.2 Vehicles

-   Create, read, update, and delete a vehicle.
-   Support multiple vehicles per account.
-   Store vehicle type, brand, model, year, variant, license plate,
    odometer, and optional photos.
-   VIN and engine number are optional, private fields.
-   Provide a curated vehicle catalog for guided vehicle registration,
    prioritizing common Indonesian car and motorcycle makes/models.
-   Support canonical names, search aliases, catalog-supported years or
    generations, and variants when data is available. Unknown variants
    must be representable without inventing a match.
-   A catalog identity match does not imply OBD support, a verified
    maintenance schedule, or confirmed product fitment.
-   Track odometer source (`manual`, `obd`, `gps_trip`, `imported`) and timestamp.
-   Detect suspicious odometer regression and require an audited
    correction path with a mandatory `correction_reason`.
-   Treat source as provenance, not an unconditional precedence rule.
    Compare source, timestamp, current accepted value, plausible distance
    change, and regression flags. Conflicting readings must not silently
    overwrite the accepted odometer; return an explicit review-required
    result where appropriate.

### 6.3 Logs and maintenance

-   Record odometer, fuel, expenses, service, part replacement, and
    notes.
-   Store amount in integer IDR, not floating-point currency.
-   Calculate maintenance due/overdue state using configurable rules.
-   Support time-based and distance-based intervals, including due when
    either threshold is reached first.
-   Show unknown when no reliable maintenance rule exists.
-   Distinguish manufacturer guidance, workshop advice, and OtoKu
    estimates.
-   Support event history and spending summaries.

### 6.4 OBD and diagnostics

-   Store device metadata, vehicle-device links, connection status, and
    last-seen timestamp.
-   Ingest normalized readings with parameter key, value, unit,
    observation time, and quality.
-   Support `valid`, `stale`, `estimated`, and `invalid` reading
    quality.
-   Store diagnostic trouble codes (DTCs), status, severity, and
    reviewed plain-language guidance.
-   Handle unsupported parameters and missing data explicitly.
-   Validate device ownership, vehicle link, payload size, timestamps,
    units, and parameter keys.
-   Avoid persisting every second of every metric unless product
    requirements justify it.
-   Publish a supported-parameter registry as backend-owned configuration
    or API data; the client must not infer support from a PID alone.
-   Define client batch cadence/throttling and server retention before
    pilot. Persist normalized snapshots rather than every-second streams;
    apply configurable retention/aggregation to `obd_readings`.
-   Treat DTCs as indicators, not definitive component diagnoses.
-   The Flutter app handles Bluetooth/USB adapter communication; the
    backend is not a Bluetooth scanner.

### 6.5 Shop and compatibility

-   Manage product categories, product descriptions, price, images,
    seller, stock, and status.
-   Search/filter/sort products with documented query, category,
    fitment, price, stock, and sort parameters plus a consistent
    pagination envelope.
-   Match products against vehicle type, brand, model, year, and
    variant.
-   Reviews are out of MVP unless a real review data model, moderation
    policy, and API are approved.
-   Return explicit fitment state: `confirmed`, `possible_unverified`,
    `incompatible`, or `unknown`.
-   Only `confirmed` fitment may be displayed as "Cocok dengan kendaraan
    Anda."
-   Recalculate all prices and totals server-side.

### 6.6 Map and places

-   Support place types: `partner_workshop`, `non_partner_workshop`,
    `minimarket`, `spbu`, and `other`.
-   Store coordinates, address, source, partner/verification status,
    hours, and freshness metadata.
-   Support nearby/radius and bounding-box queries with category
    filters.
-   Support `GET /places/search` by name and area for users who deny
    location permission. Define whether geocoding is performed by the
    selected licensed provider or by an OSM-compatible service.
-   Keep OtoKu-owned/partner places in the first-party database. Treat
    third-party provider places as a separate provider-sourced layer
    with source, attribution, and freshness metadata; do not persist or
    cache provider data unless its license permits it.
-   Return minimal pin data and separate place-detail data.
-   Distinguish partner and non-partner locations clearly.
-   Do not imply that OtoKu has verified non-partner places.
-   Respect the selected place provider's data licensing and attribution
    rules.

### 6.7 Workshop bookings

-   Allow in-app booking only for partner workshops that have booking
    enabled.
-   Allow non-partner locations to expose directions/contact only,
    unless a later integration is agreed.
-   Store service and price snapshots at booking time.
-   Validate availability transactionally to prevent double-booking.
-   State whether prices are estimates until confirmed by the workshop.

Booking uses **request-and-confirm**, not slot-based availability.
Customers submit a preferred date and time window; the request is not a
reservation until the partner accepts it. No slot-availability endpoint
is required for MVP.

Booking statuses: `requested`, `confirmed`, `rejected`, `cancelled`,
`expired`, `in_progress`, `completed`, `no_show`. Every request has a
response deadline and expires automatically if unanswered. Counter-offers
are out of scope for MVP; a partner may reject and ask the customer to
submit a new request. Capacity limits may be configured per workshop,
but transactional slot reservation/double-booking prevention is not an
MVP requirement for request-and-confirm.

### 6.8 Cart and orders

-   Support cart items, order creation, order history, and status
    timeline.
-   Snapshot product names, SKUs, and prices in each order.
-   Validate stock and reserve/update it transactionally.
-   Use idempotency keys for order creation and payment events.
-   Do not show a successful payment until a verified payment-provider
    event confirms it.
-   If payments are out of scope, label checkout as mock/prototype.
-   MVP uses `payment_mode: mock`; responses and order records must
    explicitly identify simulated checkout. Do not create real payment
    intents or imply provider-verified payment. A deterministic demo
    action may advance mock status; do not rely on timers that resemble
    real payment processing.
-   Require idempotency keys for order creation and other write
    operations where duplicate submissions would create duplicate
    business records.

Suggested order statuses: `pending_payment`, `paid`, `processing`,
`shipped`, `delivered`, `completed`, `cancelled`, `refunded`.

### 6.9 Notifications and admin

-   Provide in-app notifications for maintenance, bookings, and orders.
-   Add push notifications when a provider and permissions are selected.
-   Expose APIs for notification listing/read state/preferences and
    push-token registration/removal. Notifications for booking requests
    must reach customers and partners through the configured channels.
-   Admin CRUD for catalog, compatibility, maintenance rules, diagnostic
    guidance, and place/partner verification.
-   Audit material admin actions and booking/order state changes.

## 7. Data model

Use UUID primary keys, UTC timestamps, database constraints, and
migrations. Core tables:

-   `users`
-   `user_addresses`
-   `push_tokens`
-   `notification_preferences`
-   `vehicles`
-   `vehicle_catalog_brands`
-   `vehicle_catalog_models`
-   `vehicle_catalog_generations` (or equivalent year-range mapping)
-   `vehicle_catalog_variants` (optional where trustworthy data exists)
-   `vehicle_catalog_aliases`
-   `vehicle_photos`
-   `upload_objects` or an equivalent upload-intent metadata model
-   `vehicle_events`
-   `fuel_logs`
-   `service_records`
-   `expenses`
-   `maintenance_rules`
-   `vehicle_maintenance_items`
-   `obd_devices`
-   `vehicle_obd_links`
-   `obd_readings`
-   `diagnostic_events`
-   `diagnostic_guidance`
-   `products`
-   `product_assets`
-   `product_categories`
-   `vehicle_product_compatibility`
-   `places`
-   `workshops`
-   `workshop_services`
-   `bookings`
-   `booking_items`
-   `carts`
-   `cart_items`
-   `orders`
-   `order_items`
-   `payments` (only if a provider is selected)
-   `notifications`
-   `audit_logs`

Client-only MVP data: active-trip samples/route polylines and unconfirmed
GPS distance estimates are stored locally on the device, not in backend
tables. SPBU visit candidates (`pending_review`, `dismissed`, `snoozed`,
`resolved`) are also client-only and are not synced. The backend receives
only a user-confirmed fuel or mileage event through the normal vehicle
event API. This minimizes location data and is consistent with no
continuous background tracking outside an explicitly active trip.

Important data rules: - Keep VIN, engine number, address, and contact
data private. - Currency is integer IDR. - Store timestamps in UTC and
render locally in Flutter. - Support null/unsupported OBD values. -
Track source and freshness for external places and OBD readings. - Use
soft deletion only where recovery or audit needs justify it.

## 8. API conventions and endpoints

Use versioned REST under `/api/v1`, JSON, ISO 8601 UTC timestamps,
consistent error responses, pagination, validation, and OpenAPI
documentation.

### Identity

-   `POST /auth/session` — exchange/validate an identity-provider token
    and issue the OtoKu API session, if the selected managed auth
    architecture requires an exchange endpoint.
-   `POST /auth/refresh` — refresh an API session where applicable.
-   `POST /auth/sign-out` — revoke the current OtoKu session and/or
    provider session as supported by the selected identity architecture.
-   `DELETE /me` — request account deletion, revoke sessions, and apply
    the documented deletion/retention policy.
-   `GET /me`
-   `PATCH /me`

These identity endpoints describe the backend-connected/production
contract and are not required for the local prototype. During prototyping,
the Flutter app uses local/demo identity state and does not call `/auth/*`.

The exact token flow depends on the selected identity provider. “OAuth”
is a protocol rather than a provider. Document which layer validates
provider ID tokens and owns refresh/revocation; do not implement duplicate
auth semantics in both a managed provider and the API without a clear
contract.

### Addresses and uploads

-   `GET /account/addresses`
-   `POST /account/addresses`
-   `GET /account/addresses/:id`
-   `PATCH /account/addresses/:id`
-   `DELETE /account/addresses/:id`
-   `POST /uploads/presign` — return a short-lived upload URL and object
    metadata for an authorized upload purpose (vehicle photo or receipt).
-   `POST /uploads/:id/complete` — validate/confirm the uploaded object
    and return the asset reference; resource attachment is a separate
    authorized operation such as `PUT /vehicles/:id/photo`.

Do not expose object-storage credentials. Enforce ownership, MIME type,
size, and purpose constraints; use short-lived URLs and lifecycle cleanup
for abandoned uploads.

### Vehicles and logs

-   `GET /vehicles`
-   `POST /vehicles`
-   `GET /vehicle-catalog/types`
-   `GET /vehicle-catalog/brands?vehicleType=`
-   `GET /vehicle-catalog/models?vehicleType=&brandId=&q=&cursor=&limit=`
-   `GET /vehicle-catalog/models/:id/years`
-   `GET /vehicle-catalog/models/:id/variants?year=`
-   `GET /vehicle-catalog/search?q=&vehicleType=&cursor=&limit=`
-   `GET /vehicles/:id`
-   `PATCH /vehicles/:id`
-   `DELETE /vehicles/:id`
-   `PUT /vehicles/:id/photo` — attach a completed uploaded asset or
    catalog image reference as the vehicle's selected image.
-   `DELETE /vehicles/:id/photo` — remove the custom photo and revert
    to catalog/default imagery.
-   `GET /vehicles/:id/events`
-   `POST /vehicles/:id/events`
-   `PATCH /vehicles/:id/events/:eventId`
-   `DELETE /vehicles/:id/events/:eventId`
-   `GET /vehicles/:id/summary`
-   `GET /vehicles/:id/maintenance`
-   `POST /vehicles/:id/maintenance/:itemId/complete`
-   `POST /vehicles/:id/maintenance/:itemId/schedule`

### OBD and diagnostics

-   `GET /vehicles/:id/obd/status`
-   `POST /vehicles/:id/obd/link`
-   `DELETE /vehicles/:id/obd/link`
-   `POST /vehicles/:id/obd/readings:batch`
-   `GET /vehicles/:id/obd/readings`
-   `GET /vehicles/:id/diagnostics`
-   `GET /diagnostics/codes/:code/guidance`

### Shop

-   `GET /shop/categories`
-   `GET /shop/products?q=&categoryId=&fitment=&minPrice=&maxPrice=&inStock=&sort=&cursor=&limit=`
-   `GET /shop/products/:id`
-   `GET /vehicles/:id/compatible-products`
-   `GET /shop/products/:id/compatibility`
-   `GET /cart`
-   `POST /cart/items`
-   `PATCH /cart/items/:id`
-   `DELETE /cart/items/:id`

### Map and workshops

-   `GET /places?bbox=...`
-   `GET /places/nearby?lat=...&lng=...&radiusM=...`
-   `GET /places/search?q=...&area=...&category=...&cursor=...&limit=...`
    — name/area search must work without location permission; geocoding
    provider and query semantics must be documented.
-   `GET /places/:id`
-   `GET /places/:id/services`
-   `POST /bookings` — accepts service IDs, vehicle ID, preferred date,
    preferred time window, notes, and an `Idempotency-Key`; it does not
    reserve a time slot.
-   `POST /partner/bookings/:id/confirm`
-   `POST /partner/bookings/:id/reject`
-   `POST /partner/bookings/:id/start`
-   `POST /partner/bookings/:id/complete`
-   `GET /bookings`
-   `GET /bookings/:id`
-   `POST /bookings/:id/cancel`

### Notifications

-   `GET /notifications?cursor=&limit=`
-   `PATCH /notifications/:id` — mark read/unread as supported.
-   `GET /notification-preferences`
-   `PATCH /notification-preferences`
-   `POST /push-tokens`
-   `DELETE /push-tokens/:id`

### Orders

-   `POST /orders` — requires `Idempotency-Key`; response includes
    `payment_mode: mock` for MVP.
-   `GET /orders`
-   `GET /orders/:id`
-   `POST /orders/:id/cancel`
-   `POST /orders/:id/confirm-delivery`
-   `POST /orders/:id/mock-checkout/advance` — development/demo-only
    action, disabled in production unless explicitly configured.

### Admin/partner

-   Admin endpoints for products, categories, fitment, maintenance
    rules, DTC guidance, partner verification, and audit records.
-   Partner endpoints for booking confirmation, rejection, and
    completion.

## 9. Business logic

### Home summary

Provide a purpose-built summary containing: - Selected vehicle summary
and odometer source - Last completed service - Next maintenance items
and due status - OBD state and last update - Only fresh, supported live
metrics - Active diagnostic count/severity - Recent vehicle events

Do not send full OBD history to render Home.

### Maintenance

For due odometer `D` and current odometer `C`, remaining distance is
`D - C`. A distance-based item is **overdue when `C >= D`**, including
the exact boundary. A time-based item is overdue when the current date
is on or after its due date. For rules with both time and distance
intervals, the item is due when either threshold is reached first.
Due-soon thresholds are configurable per maintenance rule (distance and/or
days); the API returns the effective threshold and computed status.
Do not calculate exact remaining distance from stale/unknown mileage.
Cover exact-boundary and combined interval behavior in shared test
fixtures.

### OBD freshness

Represent `connected`, `disconnected`, `stale`, `unsupported`, and
`error` distinctly. A connected adapter does not mean every parameter is
available. The backend-owned supported-parameter registry is the source
of truth for normalized parameter keys, units, supported vehicle/adapter
scope, and interpretation. The Flutter client samples locally and sends
throttled batches rather than every-second raw streams. Set a documented
initial batch cadence (default target: up to one batch every 10 seconds
while a relevant OBD screen/session is active, configurable by parameter
and device) and cap payload size/rate server-side. Define retention and
aggregation before pilot; raw normalized readings must have a configurable
retention window and may be summarized for longer-term history.

### Compatibility

Never collapse `unknown` or `possible_unverified` into `confirmed`.

### Map

Cap radius and result count; use PostGIS indexes, bounding-box queries,
and clustering/aggregation at low zoom levels.

### State transitions

Enforce booking/order state transitions on the server, record
actor/time, and reject invalid transitions. Booking requests expire at
their configured response deadline if still `requested`; the expiry job
must be idempotent. All create/write endpoints that can duplicate
business actions must document idempotency behavior and key retention.

## 10. Security, privacy, and reliability

-   TLS for all traffic.
-   Ownership checks on every private resource.
-   Role-based partner/admin access.
-   Input validation, parameterized queries, request-size limits, and
    rate limiting.
-   Keep secrets outside source control.
-   Do not log credentials, tokens, or unnecessary raw diagnostic
    payloads.
-   Minimize location collection; no continuous background tracking
    outside an explicitly active user-started trip in MVP. Trip samples,
    route polylines, GPS estimates awaiting confirmation, and SPBU
    candidates remain client-only. Sync only confirmed mileage/fuel
    events. The app must disclose active-trip location behavior and
    platform-specific requirements before enabling it.
-   Provide account deletion and retention rules.
-   Backups, migrations, health checks, structured logs, error
    monitoring, timeouts, and graceful external-provider failure.
-   Verify payment webhooks and make them idempotent if payment is
    integrated.

## 11. Implementation phases

### Phase 0 --- Decisions

For prototype integration, use the Google Maps demo key and do not
require live identity/authentication; OAuth is deferred. Select the
production identity provider/auth architecture, production map project
and licensing/caching policy, minimum mobile OS versions, OBD
adapter/vehicle matrix, mock-checkout behavior, partner portal owner,
catalog/fitment seed source, maintenance-rule sources, API idempotency
policy, and data-retention rules before the production-connected MVP.
Booking model is decided for MVP: request-and-confirm with preferred
date/time window, no slot reservation.

### Phase 1 --- Foundation

Repository, environments, schema/migrations, authentication, roles,
validation, OpenAPI, logging, CI, seed data.

### Phase 2 --- Vehicle companion

Vehicle CRUD, manual logs, maintenance rules, history, cost aggregation,
Home summary.

### Phase 3 --- OBD foundation

Device links, reading ingestion, supported parameter registry, DTC
guidance, freshness states, mock OBD simulator.

### Phase 4 --- Shop

Catalog, categories, search, compatibility, cart, admin catalog tools.

### Phase 5 --- Map and booking

Place ingestion/curation, PostGIS queries, filters, partner
verification, licensed provider/geocoding integration, services,
request-and-confirm booking lifecycle, partner web portal or equivalent
partner surface, response deadlines, and customer/partner notifications.

### Phase 6 --- Orders and notifications

Orders, stock validation, mock or real checkout, order states, reminders
and updates.

### Phase 7 --- Hardening/pilot

Security review, backup/restore test, performance, network failure
handling, compatibility pilot, monitoring and incident notes.

## 12. Testing and acceptance criteria

Unit tests: - Maintenance calculations - Compatibility matching - OBD
freshness and unsupported states - Booking/order transitions - Pricing
and stock - Access policies

Integration tests: - Ownership checks - Event-to-summary updates - OBD
batch ingestion - Geospatial filters - Booking conflicts - Transactional
order creation - Admin verification and audit logs

End-to-end tests: 1. Register vehicle, add odometer, see maintenance
summary. 2. Add fuel/service log and see history. 3. Disconnect OBD and
verify no fake live values. 4. Submit mock OBD readings and verify
fresh/stale states. 5. Find a compatible product and add it to cart. 6.
Filter map by SPBU and partner workshops. 7. Book a partner workshop
service. 8. Create an order and progress through configured checkout. 9.
Attempt cross-user access and verify rejection.

MVP acceptance: - No known cross-user data access defects. - Private
resources have tested authorization. - Manual tracking works without
OBD. - Unsupported/stale OBD states are correct. - Fitment is explicit
and auditable. - Map categories and partner status are correct. -
Booking/order transitions are enforced server-side. - No payment is
shown as successful without verification. - API docs, migrations,
backups, and deployment instructions exist.

## 13. Key unresolved decisions

-   Prototype backend or production MVP?
-   NestJS or another framework?
-   Authentication method?
-   Map/place provider and license?
-   Initial supported OBD adapter and vehicle matrix?
-   Which layer validates identity-provider tokens and owns refresh/revocation? Default direction: managed identity provider; Google sign-in, with Sign in with Apple on iOS if current store rules require it.
-   Which minimum Android/iOS versions are supported?
-   Which concrete map/place provider, geocoder, tile host, and licensing/caching policy are approved? Google Maps is the initial preference; OSM is a possible fallback only with compliant hosting and attribution.
-   Which OBD adapter/vehicle/parameter matrix and sampling cadence are supported?
-   Which sellers/products populate Shop, and what is the initial fitment seeding/approval workflow?
-   What is the authoritative source, owner, license, and refresh cadence for Indonesian vehicle make/model/year/variant catalog data?
-   Which catalog vehicle images are licensed for use, and what default illustrations will be supplied?
-   Who owns and operates the partner booking portal and notification delivery?
-   Who approves maintenance intervals and diagnostic guidance?
-   What data-retention and account-deletion rules apply?
-   What exact source/precedence and plausibility thresholds apply to odometer conflict detection? The API must support `correction_reason` and audited outcomes.
-   Reviews are excluded from MVP unless a real review model/API is approved.
-   Non-partner workshop booking is excluded from MVP; only directions/contact are shown.
-   Mock checkout is the MVP default; real payments and payment webhooks are deferred.

## 14. Repository suggestion

``` text
otoku-backend/
  src/
    common/
    modules/
      users/
      vehicles/
      vehicle-events/
      maintenance/
      obd/
      diagnostics/
      catalog/
      compatibility/
      places/
      workshops/
      bookings/
      cart/
      orders/
      notifications/
      admin/
    database/
      migrations/
      seeds/
  test/
    unit/
    integration/
    e2e/
  docs/
  .env.example
  Dockerfile
  docker-compose.yml
  README.md
```

## 15. Vehicle catalog and image requirements

### Curated vehicle catalog

Vehicle registration should use a searchable, preloaded catalog rather
than requiring customers to type make/model/year/variant. The initial
catalog is Indonesia-focused and must cover both motorcycles and cars.
The catalog schema should support vehicle type, canonical brand/model
names, aliases/common spellings, model generation or supported year
ranges, and variants only when the source data is reliable. A user may
select `variant unknown` or use manual entry if their vehicle is missing.

Initial seed candidates for validation include:

- **Motorcycles:** Honda BeAT, Vario 125/160, Scoopy, PCX 160, ADV 160,
  Supra X 125; Yamaha NMAX, Aerox, Fazzio, Gear, Mio, Jupiter; Suzuki
  Nex II, Address, Satria F150.
- **Cars:** Toyota Avanza, Kijang Innova (Reborn/Zenix), Calya, Agya,
  Rush, Fortuner, Hilux; Daihatsu Xenia, Sigra, Ayla, Terios, Gran Max;
  Honda Brio, HR-V, CR-V; Mitsubishi Xpander, Pajero Sport, L300;
  Suzuki Carry, Ertiga, XL7, Fronx; and selected popular EV models such
  as BYD Atto 1 and M6.

This list is a seed scope, not a claim that every year/variant is already
verified. Model/year/variant records must be curated from a maintained
source before being marked available. For cars, GAIKINDO's 2025 sales
data supports prioritizing models such as Kijang Innova, Gran Max,
Avanza, Sigra, Brio, Calya, Rush, Carry, and Xpander; update the seed
priority periodically rather than hard-coding rankings into the API.
Catalog data source, licensing, ownership, and refresh cadence remain
explicit operational decisions.

The catalog API must support search, type/brand/model/year filtering,
pagination, aliases, and a response that distinguishes a known catalog
entry from unknown/missing year or variant data. Catalog selection must
not implicitly certify OBD support, maintenance rules, or product
fitment. Keep these datasets independently governed.

### Custom vehicle images

Each vehicle may reference a catalog image/illustration or a user-uploaded
custom photo. User photos are optional and do not prove vehicle identity
or ownership.

- Store the asset reference and metadata, not binary image content in
  PostgreSQL.
- Use the existing presigned upload flow with authorized image purpose,
  size/MIME validation, and a separate vehicle-photo attachment endpoint.
- Enforce vehicle ownership for upload attachment, replacement, and
  removal. Delete or lifecycle-expire orphaned uploads.
- Return image source/type and a stable asset URL or authorized retrieval
  mechanism. The client falls back to catalog imagery, then a generic
  vehicle-type illustration.
- Catalog images must have an approved source/license. Do not assume
  images from manufacturer sites or search results may be copied into
  the catalog.

## 16. Client-only location data and confirmed event contract

The following are client-only in MVP and must not be represented as
backend resources: active-trip GPS samples, route polylines, unconfirmed
GPS distance estimates, and SPBU visit candidates with pending,
dismissed, snoozed, or resolved presentation state. This is a deliberate
data-minimization choice. No server-side continuous location tracking or
SPBU candidate detection is in MVP.

After the user confirms a GPS trip estimate, the Flutter client submits
the resulting mileage event through `POST /vehicles/:id/events`, with
`type: odometer`, `source: gps_trip`, the confirmed odometer/distance
fields defined by the event schema, observation time, and any required
`correction_reason`. The backend validates the event and decides whether
it updates the accepted odometer.

After the user confirms an SPBU fuel suggestion, the client submits a
normal fuel event through the same endpoint, with `type: fuel`,
`source: spbu_suggestion`, an optional `place_id` referencing a known
SPBU, visit/event time, and only user-entered fuel quantity/cost values.
No fuel log is created from a candidate alone. If the place cannot be
resolved to a backend place record, the event may carry a user-entered
place label but must not invent a place ID.

## 17. Odometer acceptance and correction contract

Odometer source is provenance, not a simple winner-takes-all ranking.
The server compares the proposed value with the last accepted value,
source, observation timestamp, plausibility thresholds, and any existing
regression flags. A later manual entry does not automatically lose to an
older OBD reading, and a source does not automatically override a newer
accepted reading solely because of its nominal rank.

If a value is a suspicious decrease or otherwise conflicts with the
accepted reading, return a typed response such as `review_required` with
the prior value, proposed value, source/time, and reason code. The client
must ask the user to confirm a correction and provide `correction_reason`.
The server stores the proposed/previous values, actor, timestamps, source,
reason, and decision in an audit record. The precise plausibility
thresholds are a Phase 0 decision and must be configuration-backed and
covered by shared fixtures.

## 18. Fitment data readiness

Fitment is a trust-critical dataset. Before launch, seed an explicitly
bounded set of products and vehicle variants with reviewed fitment data,
and record who/what source approved each fitment decision and when.
Unknown fitment remains `unknown`; do not backfill `confirmed` from
category-level assumptions. If no reviewed fitment exists for the
selected vehicle, the Shop must show a useful empty/unknown state and
allow general browsing without claiming compatibility.

## 19. Shared API contract and release gates

OpenAPI is the contract source of truth and must be drafted before
Flutter API models are generated. Every endpoint must document
authentication, authorization, request/response schemas, pagination,
error codes, idempotency, and rate/size limits as applicable. API changes
must update OpenAPI and client models together.

Release gates before the relevant implementation phase:
- Before Phase 1: decide auth architecture, minimum OS versions, map
  provider/licensing direction, and data-retention policy.
- Before OBD pilot: publish parameter registry, sampling/batching limits,
  and `obd_readings` retention.
- Before Map/booking pilot: approve place/geocoding data source and
  licensing; deliver partner booking surface and notifications.
- Before Shop launch: seed reviewed fitment data and define approval
  ownership.
- Before account creation launch: implement account deletion and session
  revocation behavior.

## 20. Core principle

OtoKu must remain useful without an OBD device. The backend should
distinguish **known, estimated, unavailable, stale, and unverified
information**, instead of implying certainty where data is missing.
