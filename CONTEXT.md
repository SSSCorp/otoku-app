# OtoKu Vehicle Companion Context

This glossary defines the domain language for OtoKu, a vehicle companion that connects vehicle care with diagnostics, parts, and workshops.

## Vehicle care

**Vehicle**: A motorcycle or car registered to a person for tracking and maintenance.

**Active vehicle**: The vehicle currently selected as the subject of the app’s condition, maintenance, compatibility, and diagnostic information.

**Maintenance**: A planned or completed care activity for a vehicle, such as changing oil or checking brake pads.

**Service history**: The chronological record of a vehicle’s maintenance, fueling, mileage, and related care events.

**OBD**: An onboard diagnostic connection that provides vehicle data and diagnostic trouble codes when supported by the vehicle.

**Diagnostic trouble code (DTC)**: A vehicle-reported code indicating a condition that may require further inspection, not a definitive mechanical diagnosis.

## Marketplace

**Sparepart**: A replacement vehicle component or consumable offered for purchase and checked against the active vehicle’s compatibility.

**Bengkel**: A workshop that offers vehicle maintenance or repair services.

**Booking layanan**: A scheduled request for one or more services at a Bengkel.

**Pesanan**: A recorded purchase of a Sparepart or a confirmed Booking layanan.

## Relationships

- An **active vehicle** is one **Vehicle** selected at a time.
- A **Vehicle** has **Maintenance** items and a **Service history**.
- **OBD** may provide **Diagnostic trouble codes** for a **Vehicle**.
- A **Sparepart** is either compatible or incompatible with the **active vehicle**.
- A **Bengkel** offers services that can be combined into a **Booking layanan**.
- A **Pesanan** represents either a Sparepart purchase or a Booking layanan.

## Example dialogue

> **Dev:** “The OBD detected P0301. Should we tell the user the spark plug is broken?”
> **Domain expert:** “No. A **Diagnostic trouble code** is an indication requiring inspection; show possible checks and relevant **Sparepart** or **Bengkel** recommendations instead.”

## Flagged ambiguities

- “Account” is reserved for the user profile area; vehicle ownership information is represented by **Vehicle**, not Account.
- “Service” can mean either a maintenance activity or a workshop offering; use **Maintenance** for the activity and **Booking layanan** for the scheduled workshop request.
- “Order” is standardized as **Pesanan** in the Indonesian interface, covering both parts purchases and workshop bookings.
