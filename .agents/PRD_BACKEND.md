# OtoKu Backend PRD

**Document type:** Backend product requirements and implementation plan\
**Version:** 1.0\
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
-   Track odometer source (`manual`, `obd`, `imported`) and timestamp.
-   Detect suspicious odometer regression and require an audited
    correction path.

### 6.3 Logs and maintenance

-   Record odometer, fuel, expenses, service, part replacement, and
    notes.
-   Store amount in integer IDR, not floating-point currency.
-   Calculate maintenance due/overdue state using configurable rules.
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
-   Treat DTCs as indicators, not definitive component diagnoses.
-   The Flutter app handles Bluetooth/USB adapter communication; the
    backend is not a Bluetooth scanner.

### 6.5 Shop and compatibility

-   Manage product categories, product descriptions, price, images,
    seller, stock, and status.
-   Search/filter products.
-   Match products against vehicle type, brand, model, year, and
    variant.
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

Booking statuses: `requested`, `confirmed`, `rejected`, `cancelled`,
`in_progress`, `completed`, `no_show`.

### 6.8 Cart and orders

-   Support cart items, order creation, order history, and status
    timeline.
-   Snapshot product names, SKUs, and prices in each order.
-   Validate stock and reserve/update it transactionally.
-   Use idempotency keys for order creation and payment events.
-   Do not show a successful payment until a verified payment-provider
    event confirms it.
-   If payments are out of scope, label checkout as mock/prototype.

Suggested order statuses: `pending_payment`, `paid`, `processing`,
`shipped`, `delivered`, `completed`, `cancelled`, `refunded`.

### 6.9 Notifications and admin

-   Provide in-app notifications for maintenance, bookings, and orders.
-   Add push notifications when a provider and permissions are selected.
-   Admin CRUD for catalog, compatibility, maintenance rules, diagnostic
    guidance, and place/partner verification.
-   Audit material admin actions and booking/order state changes.

## 7. Data model

Use UUID primary keys, UTC timestamps, database constraints, and
migrations. Core tables:

-   `users`
-   `user_addresses`
-   `vehicles`
-   `vehicle_photos`
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

-   `GET /me`
-   `PATCH /me`

### Vehicles and logs

-   `GET /vehicles`
-   `POST /vehicles`
-   `GET /vehicles/:id`
-   `PATCH /vehicles/:id`
-   `DELETE /vehicles/:id`
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
-   `GET /shop/products`
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
-   `GET /places/:id`
-   `GET /places/:id/services`
-   `POST /bookings`
-   `GET /bookings`
-   `GET /bookings/:id`
-   `POST /bookings/:id/cancel`

### Orders

-   `POST /orders`
-   `GET /orders`
-   `GET /orders/:id`
-   `POST /orders/:id/cancel`
-   `POST /orders/:id/confirm-delivery`

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
`D - C`. Mark overdue when current mileage exceeds due mileage; use a
configurable threshold for due-soon. Define boundary behavior in tests.
Do not calculate exact remaining distance from stale/unknown mileage.

### OBD freshness

Represent `connected`, `disconnected`, `stale`, `unsupported`, and
`error` distinctly. A connected adapter does not mean every parameter is
available.

### Compatibility

Never collapse `unknown` or `possible_unverified` into `confirmed`.

### Map

Cap radius and result count; use PostGIS indexes, bounding-box queries,
and clustering/aggregation at low zoom levels.

### State transitions

Enforce booking/order state transitions on the server, record
actor/time, and reject invalid transitions.

## 10. Security, privacy, and reliability

-   TLS for all traffic.
-   Ownership checks on every private resource.
-   Role-based partner/admin access.
-   Input validation, parameterized queries, request-size limits, and
    rate limiting.
-   Keep secrets outside source control.
-   Do not log credentials, tokens, or unnecessary raw diagnostic
    payloads.
-   Minimize location collection; no continuous background tracking in
    MVP.
-   Provide account deletion and retention rules.
-   Backups, migrations, health checks, structured logs, error
    monitoring, timeouts, and graceful external-provider failure.
-   Verify payment webhooks and make them idempotent if payment is
    integrated.

## 11. Implementation phases

### Phase 0 --- Decisions

Select authentication, hosting, maps/place provider, OBD adapter/vehicle
matrix, payment approach, booking availability model, catalog ownership,
maintenance-rule sources, and data-retention rules.

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
verification, services, booking lifecycle.

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
-   Which layer reads Bluetooth data and uploads normalized values?
-   Which sellers/products populate Shop?
-   Real payment or mock checkout?
-   Are bookings request-and-confirm or slot-based?
-   Who approves maintenance intervals, fitment, and diagnostic
    guidance?
-   What data-retention and account-deletion rules apply?

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

## 15. Core principle

OtoKu must remain useful without an OBD device. The backend should
distinguish **known, estimated, unavailable, stale, and unverified
information**, instead of implying certainty where data is missing.
