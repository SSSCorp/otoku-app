# OtoKu Mobile App --- Prototype Design Specification

## 1. Product Overview

OtoKu is a mobile companion app for car and motorcycle owners. Its
primary purpose is to help users understand, track, and maintain their
vehicles.

The app should feel like a **vehicle companion first** and an automotive
marketplace second.

Core product loop:

**Register vehicle → monitor vehicle → track maintenance → detect
problems → get recommendations → buy compatible parts / find a
workshop**

The prototype should demonstrate this complete flow, including the OBD
feature as a premium/connected capability.

------------------------------------------------------------------------

## 2. Design Direction

### Visual language

-   Modern automotive utility app
-   Clean, practical, trustworthy
-   White/light-gray base
-   OtoKu red as the primary action color
-   Black/dark charcoal for headings
-   Green for healthy/success states
-   Amber/orange for warnings
-   Red for critical problems
-   Rounded cards with subtle shadows
-   Large touch targets
-   Minimal decorative elements
-   Product photography and vehicle imagery should be prominent

### Primary color tokens

  Token            Value       Usage
  ---------------- ----------- -------------------------------------------
  Primary          `#E21B23`   CTA, active navigation, important actions
  Primary Dark     `#B81218`   Pressed/hover states
  Background       `#F7F7F7`   Main app background
  Surface          `#FFFFFF`   Cards and content
  Text Primary     `#171717`   Main text
  Text Secondary   `#6B6B6B`   Supporting text
  Border           `#E8E8E8`   Dividers and card borders
  Success          `#22A447`   Healthy/complete states
  Warning          `#F59E0B`   Maintenance approaching
  Error            `#DC2626`   Diagnostic/error states

### Typography

Use a modern sans-serif such as Inter, SF Pro, or equivalent.

Recommended hierarchy:

-   Screen title: 24 px / Semibold
-   Section title: 18 px / Semibold
-   Card title: 16 px / Semibold
-   Body: 14--16 px / Regular
-   Caption: 12--13 px / Regular
-   Large metric: 20--24 px / Bold

------------------------------------------------------------------------

## 3. Navigation

Use a persistent bottom navigation bar:

1.  **Home**
2.  **Sparepart**
3.  **Bengkel**
4.  **Pesanan**
5.  **Akun**

The Home tab is the default entry point.

------------------------------------------------------------------------

# 4. Screen Inventory

The prototype should contain these screens:

1.  Splash Screen
2.  Home --- OBD Locked
3.  Home --- OBD Connected
4.  Detail Kendaraan
5.  Riwayat & Tracking
6.  Data OBD
7.  Jadwal Perawatan
8.  Sparepart Catalog
9.  Detail Sparepart
10. Bengkel List
11. Detail Bengkel
12. Booking Layanan
13. Pesanan
14. Akun

The prototype should provide clickable transitions between these
screens.

------------------------------------------------------------------------

# 5. Splash Screen

## Purpose

Introduce OtoKu and establish the brand.

## Layout

-   Full-screen dark background
-   OtoKu logo centered
-   Automotive silhouette/outline in the background
-   Tagline:

> Perawatan kendaraan lebih mudah, selalu terpantau.

## Behavior

After a short delay, navigate to Home.

------------------------------------------------------------------------

# 6. Home --- OBD Locked

This is the most important screen.

The Home screen should immediately communicate:

**"This is my vehicle, this is its current condition, and this is what I
need to do next."**

## Header

-   OtoKu logo
-   Notification icon
-   Account/avatar icon

## Vehicle Card

Large card near the top.

Example data:

``` text
Honda Beat 2021
B 1234 XYZ

12.450 km
Service terakhir: Mar 2026
Kondisi: Baik
```

Include:

-   Vehicle image
-   Edit icon
-   Vehicle name
-   License plate
-   Current mileage
-   Last service
-   Overall status

Clicking the vehicle card opens **Detail Kendaraan**.

------------------------------------------------------------------------

## OBD Soft-Selling Card

This should be visible on Home even when the user does not own/connect
an OBD device.

The card is intentionally promotional but should communicate value
rather than behave like an advertisement.

Title:

> Hubungkan OBD untuk Data Kendaraan Real-time

Description:

> Pantau kondisi mesin, konsumsi BBM, dan deteksi masalah lebih awal.

CTA:

> Lihat OBD OtoKu

Include a small OBD device illustration.

Feature hints:

-   Data real-time
-   Deteksi masalah
-   Rekomendasi servis
-   Integrasi sparepart & bengkel

Clicking the CTA opens the OBD information/connection flow.

------------------------------------------------------------------------

## Locked OBD Data Preview

Below the promotional card, show a section:

> Data Kendaraan

Badge:

> 🔒 Terhubung OBD

Show locked metric cards:

``` text
RPM             —
Kecepatan       —
Suhu Mesin      —

Tegangan Aki    —
Level BBM       —
Konsumsi BBM    —
```

Each metric should show a lock icon.

The purpose is to let the user understand what additional information
OtoKu can provide without an OBD connection.

Do not fabricate live values when disconnected.

------------------------------------------------------------------------

## Maintenance Section

Title:

> Perawatan Berikutnya

CTA:

> Lihat Semua

Example:

``` text
Ganti Oli Mesin
Dalam 1.550 km
Perkiraan: Oktober 2026
```

Use a red-tinted alert card for the next important maintenance item.

Other examples:

-   Cek kampas rem
-   Cek filter udara
-   Cek busi

Clicking the section opens **Jadwal Perawatan**.

------------------------------------------------------------------------

# 7. Home --- OBD Connected

This screen uses the same structure as Home but unlocks OBD information.

## Connection Status

Show a green connection card:

``` text
● OBD OtoKu Terhubung
Terakhir diperbarui: 2 menit yang lalu
```

## Real-Time Data

Title:

> Data Kendaraan (Real-time)

Example values:

``` text
RPM             1.250 rpm
Kecepatan       0 km/h
Suhu Mesin      87 °C

Tegangan Aki    13,8 V
Level BBM       64 %
Konsumsi BBM    42,5 km/L
```

Values should be displayed as large numbers with small labels.

## Vehicle Health

Card:

``` text
Kondisi Kendaraan

✓ Mesin
  Normal

✓ Sistem Pengisian
  Normal

✓ Emisi
  Normal

⚠ 1 Kode Masalah
  P0301
```

The diagnostic warning should be visually prominent.

Clicking it opens **Data OBD**.

## Maintenance

Maintenance progress can now be tied to automatically collected mileage.

Example:

``` text
Ganti Oli Mesin
12.450 / 14.000 km

██████████████░░

1.550 km lagi
```

------------------------------------------------------------------------

# 8. Detail Kendaraan

## Purpose

Show all registered vehicle information.

## Content

Vehicle image at the top.

``` text
Honda Beat 2021
B 1234 XYZ
```

Vehicle specifications:

-   Brand
-   Model
-   Year
-   Type
-   VIN / nomor rangka
-   Engine number
-   Transmission/type where applicable

## Navigation Cards

-   Riwayat & Tracking
-   Jadwal Perawatan
-   Data OBD

## Actions

-   Ubah Data Kendaraan
-   Hapus Kendaraan

------------------------------------------------------------------------

# 9. Riwayat & Tracking

Use segmented controls:

``` text
Timeline | Grafik | Biaya
```

## Timeline

Show chronological events.

Example:

``` text
Hari ini
12.450 km

Isi Pertalite
8,2 L
Rp 50.000

Servis Rutin
Ganti oli
Cek filter udara
Cek CVT
Rp 80.000

10 Jul 2026
11.800 km

Isi Pertalite
8,1 L
Rp 50.000

15 Jun 2026
11.200 km

Ganti Kampas Rem
Rp 120.000
```

## Grafik

Allow users to visualize:

-   Mileage
-   Fuel consumption
-   Maintenance spending

## Biaya

Show monthly/yearly maintenance expenditure.

------------------------------------------------------------------------

# 10. Data OBD

This screen is available when an OBD device is connected.

Header:

``` text
Data OBD
● OBD Terhubung
```

Tabs:

``` text
Real-time | Diagnostik
```

## Real-Time Metrics

Show:

-   RPM
-   Vehicle speed
-   Engine temperature
-   Battery/control voltage
-   Fuel level when supported
-   Fuel consumption when available
-   Engine load
-   Throttle position
-   Intake temperature when supported

Not every vehicle supports every PID.

If unavailable, show:

> Tidak tersedia pada kendaraan ini

instead of fake data.

## Diagnostic Section

Show detected diagnostic trouble codes.

Example:

``` text
P0301
Cylinder 1 Misfire Detected

Status:
Sedang

[ Lihat Solusi & Rekomendasi ]
```

The prototype can use static sample data.

------------------------------------------------------------------------

# 11. Jadwal Perawatan

Tabs:

``` text
Rekomendasi | Semua | Selesai
```

Maintenance cards should show:

-   Component
-   Current mileage
-   Recommended interval
-   Progress
-   Estimated remaining distance

Example:

``` text
Ganti Oli Mesin

Dalam 1.550 km

12.450 / 14.000 km
██████████████░░
```

Other items:

-   Kampas rem
-   Filter udara
-   Busi
-   Oli gear/CVT
-   Battery
-   Coolant where applicable

Recommendations should depend on the registered vehicle.

------------------------------------------------------------------------

# 12. Sparepart Catalog

Bottom navigation: Sparepart active.

## Header

Search:

> Cari sparepart...

Categories:

-   Oli & Cairan
-   Rem
-   Filter
-   Aki
-   Lampu
-   Body Part
-   CVT
-   Lainnya

## Vehicle Compatibility

Prioritize compatible parts for the user's currently selected vehicle.

Show:

> Cocok untuk Honda Beat 2021

This is a key OtoKu differentiator.

------------------------------------------------------------------------

# 13. Detail Sparepart

Show:

-   Product image
-   Product name
-   Brand
-   Compatibility
-   Rating
-   Price
-   Stock
-   Warranty/authenticity information

Example:

``` text
Kampas Rem Depan
Honda Beat

Rp 85.000

★ 4.8 (120 ulasan)

✓ Cocok dengan kendaraan Anda
✓ 100% Original
✓ Stok tersedia
```

Actions:

-   Tambah ke Keranjang
-   Beli Sekarang

If the product is incompatible, explicitly show:

> Tidak kompatibel dengan kendaraan Anda

Do not let the prototype imply compatibility without a vehicle match.

------------------------------------------------------------------------

# 14. Bengkel List

Show nearby/recommended workshops.

Filters:

``` text
Semua | Terdekat | Terbaik
```

Each workshop card:

-   Workshop image
-   Name
-   Rating
-   Distance
-   Verification badge
-   Main services

Example:

``` text
Bengkel Jaya Motor
★ 4.7
2.1 km
✓ Terverifikasi

Servis Rutin · Ganti Oli
```

------------------------------------------------------------------------

# 15. Detail Bengkel

Header image.

Information:

-   Name
-   Rating
-   Distance
-   Opening hours
-   Verification status

Actions:

-   Rute
-   Hubungi
-   Simpan
-   Bagikan

Tabs:

``` text
Layanan | Ulasan | Galeri | Tentang
```

Services:

``` text
Ganti Oli Mesin
Rp 50.000
30 menit

Servis CVT
Rp 80.000
45 menit
```

Primary CTA:

> Booking Sekarang

------------------------------------------------------------------------

# 16. Booking Layanan

Show selected workshop at the top.

## Service Selection

Allow multiple services.

Example:

``` text
Ganti Oli Mesin
Rp 50.000
✓
```

## Date

Horizontal date selector.

## Time

Grid of available slots:

``` text
08:00  09:00  10:00
11:00  13:00  14:00
15:00  16:00
```

## Notes

Optional text field.

CTA:

> Lanjutkan

------------------------------------------------------------------------

# 17. Pesanan

Tabs:

``` text
Sparepart | Layanan | Semua
```

Show order cards.

Statuses:

-   Diproses
-   Dikirim
-   Selesai
-   Dibatalkan

Example:

``` text
#SP250922001

Kampas Rem Depan
Honda Beat

Rp 85.000

Diproses
```

Click opens order detail.

------------------------------------------------------------------------

# 18. Order Detail

Show:

``` text
#SP250922001
Diproses
```

Timeline:

``` text
● Pesanan dibuat
│
● Sedang dikemas
│
○ Dikirim
│
○ Sampai tujuan
│
○ Pesanan selesai
```

Show:

-   Product
-   Quantity
-   Price
-   Delivery address
-   Payment information

------------------------------------------------------------------------

# 19. Akun

Header:

``` text
Ifan Prasetyo
ifan@email.com
```

Menu:

-   Kendaraan Saya
-   Pesanan Saya
-   Booking Layanan
-   Alamat Saya
-   Metode Pembayaran
-   Voucher & Promo
-   Pusat Bantuan
-   Tentang OtoKu
-   Logout

------------------------------------------------------------------------

# 20. Vehicle Data Model

The prototype should use a centralized vehicle object.

Example:

``` json
{
  "id": "vehicle_001",
  "brand": "Honda",
  "model": "Beat",
  "year": 2021,
  "type": "CBS",
  "licensePlate": "B 1234 XYZ",
  "vin": "MH1JM3110MK123456",
  "engineNumber": "JM3E1123456",
  "mileage": 12450,
  "lastServiceDate": "2026-03-15",
  "condition": "good",
  "obdConnected": false
}
```

The prototype can initially use mock/local data.

------------------------------------------------------------------------

# 21. OBD Data Model

Use a separate OBD object.

``` json
{
  "connected": true,
  "lastUpdated": "2026-10-04T14:20:00",
  "rpm": 1250,
  "speed": 0,
  "engineTemperature": 87,
  "batteryVoltage": 13.8,
  "fuelLevel": 64,
  "fuelConsumption": 42.5,
  "engineLoad": 18,
  "throttlePosition": 12,
  "diagnosticCodes": [
    {
      "code": "P0301",
      "description": "Cylinder 1 Misfire Detected",
      "severity": "warning"
    }
  ]
}
```

The implementation must support `null` values because OBD PID
availability varies by vehicle.

------------------------------------------------------------------------

# 22. Prototype Interaction Flow

The main demonstration flow should be:

``` text
Splash
  ↓
Home
  ↓
Vehicle Card
  ↓
Detail Kendaraan
  ├── Riwayat & Tracking
  ├── Jadwal Perawatan
  └── Data OBD
```

Secondary flow:

``` text
Home
  ↓
Locked OBD Card
  ↓
OBD Information / Connection
  ↓
Home — OBD Connected
  ↓
Data OBD
  ↓
Diagnostic Code
  ↓
Recommendation
  ├── Sparepart
  └── Bengkel
```

Sparepart flow:

``` text
Sparepart
  ↓
Catalog
  ↓
Product Detail
  ↓
Compatibility Check
  ↓
Add to Cart / Buy
  ↓
Order
```

Workshop flow:

``` text
Bengkel
  ↓
Workshop Detail
  ↓
Select Service
  ↓
Select Date
  ↓
Select Time
  ↓
Booking
  ↓
Pesanan
```

------------------------------------------------------------------------

# 23. OBD Soft-Selling Strategy

OBD should not be presented as an aggressive advertisement.

The product strategy is:

**Without OBD:**

The user gets:

-   Registered vehicle
-   Manual mileage
-   Maintenance schedule
-   Service history
-   Sparepart marketplace
-   Workshop marketplace

**With OBD:**

The user unlocks:

-   Real-time vehicle data
-   Automatic vehicle data collection
-   More accurate mileage tracking
-   Vehicle health information
-   Diagnostic trouble codes
-   More informed maintenance recommendations

The key CTA should communicate the benefit:

> Hubungkan OBD

rather than:

> Beli OBD sekarang

The OBD card should visually resemble a locked feature preview, not a
banner advertisement.

------------------------------------------------------------------------

# 24. Compatibility and Safety Rules

The prototype must not imply that every OBD device or vehicle supports
every metric.

Use three states:

### Available

``` text
RPM
1.250 rpm
```

### Unsupported

``` text
Fuel Level
Tidak tersedia
```

### Disconnected

``` text
RPM
—
🔒 Hubungkan OBD
```

Diagnostic information should be described as an indication, not a
definitive mechanical diagnosis.

For example:

> Kode P0301 terdeteksi. Kemungkinan terdapat masalah pada sistem
> pembakaran. Periksa kendaraan lebih lanjut.

Avoid claiming:

> Busi Anda rusak.

------------------------------------------------------------------------

# 25. Responsive Mobile Layout

Primary target:

-   390 × 844 px
-   393 × 852 px
-   360 × 800 px

Use:

-   16 px horizontal page padding
-   12--16 px card gaps
-   12--20 px card radius
-   44 px minimum interactive target
-   Fixed bottom navigation
-   Scrollable content areas
-   Sticky primary CTA where appropriate

The design must work for both motorcycle and car profiles.

------------------------------------------------------------------------

# 26. Prototype Priority

If implementation time is limited, prioritize these screens:

### P0 --- Essential

1.  Home --- OBD Locked
2.  Home --- OBD Connected
3.  Detail Kendaraan
4.  Riwayat & Tracking
5.  Jadwal Perawatan
6.  Data OBD
7.  Sparepart Detail
8.  Bengkel Detail

### P1 --- Supporting

9.  Sparepart Catalog
10. Bengkel List
11. Booking
12. Pesanan

### P2 --- Secondary

13. Account
14. Splash

The Home → OBD → maintenance → sparepart/bengkel flow is the core
prototype narrative.

------------------------------------------------------------------------

# 27. Prototype Success Criteria

A user should be able to understand within a few seconds:

1.  Which vehicle is currently selected.
2.  What condition the vehicle is in.
3.  What maintenance is due next.
4.  What additional information OBD provides.
5.  Why connecting an OBD device is useful.
6.  How OtoKu can connect vehicle diagnostics to maintenance,
    spareparts, and workshops.

The prototype should therefore position OtoKu as:

> **A digital companion for your vehicle, not merely an automotive
> marketplace.**
