# OtoKu Mobile App — Prototype Design Specification

> Source of truth: `OtoKu_Automotive_App_UI_Showcase.png` (14 screens).
> All copy, sample data, labels, and layouts below mirror that image.
> Anything not visible in the image is marked **(derived)**.

## 1. Product Overview

OtoKu is a mobile companion app for car and motorcycle owners. It helps users understand, track, and maintain their vehicles.

The app is a **vehicle companion first** and an automotive marketplace second.

Core product loop:

**Register vehicle → monitor vehicle → track maintenance → detect problems → get recommendations → buy compatible parts / find a workshop**

The OBD feature is a premium/connected capability, soft-sold on Home.

---

## 2. Design Direction

### Visual language

- Modern automotive utility app; clean, practical, trustworthy
- White base, light-gray page background
- OtoKu red as the single primary/action color
- Black/dark charcoal for headings and the OBD promo card
- Soft red-tinted (pink) surfaces for vehicle card, next-maintenance alert, and "Hapus Kendaraan"
- Rounded cards, hairline borders, very subtle shadows
- Line icons (outlined, ~1.5 px stroke); active nav icon is filled red
- Real vehicle / product / workshop photography is prominent
- Pill-shaped chips, tabs, and status badges

### Color tokens

| Token | Value | Usage |
|---|---|---|
| Primary | `#E21B23` | CTAs, active nav/tab, "Lihat Semua" links, prices on product detail, progress bars, selected states |
| Primary Dark | `#B81218` | Pressed states |
| Primary Tint | `#FDECEC` | Vehicle card bg, next-maintenance card, selected chip/date/time fill, "Hapus Kendaraan" row |
| Background | `#F7F7F7` | App background |
| Surface | `#FFFFFF` | Cards, headers, nav bar |
| Dark Surface | `#1A1A1A` | Splash bg, OBD promo card |
| Text Primary | `#171717` | Titles, values |
| Text Secondary | `#6B6B6B` | Captions, units, sub-labels |
| Border | `#E8E8E8` | Dividers, card borders, inactive chips |
| Success | `#22A447` | "Baik", "Normal", "Terverifikasi", "Stok tersedia", "Buka", OBD connected |
| Success Tint | `#E6F6EA` | Success badge / OBD-connected card bg |
| Warning | `#F59E0B` | "Sedang" severity, "Diproses" status |
| Warning Tint | `#FEF3DC` | Warning badge bg |
| Error | `#DC2626` | "Ada 1 kode masalah", destructive actions |

### Typography

Modern sans-serif (Inter / SF Pro).

| Role | Spec |
|---|---|
| Screen title (app bar) | 16–18 px / Semibold, centered or left after back arrow |
| Section title | 14–16 px / Semibold (e.g. "Perawatan Berikutnya") |
| Card title | 14–15 px / Semibold |
| Body | 12–14 px / Regular |
| Caption | 10–12 px / Regular, Text Secondary |
| Large metric | 18–22 px / Bold (e.g. `1.250`) |
| Price | 13–14 px / Semibold; product detail price 20 px / Bold red |

### Common components

- **Status bar**: `9:41`, signal / wifi / battery
- **App bar**: back chevron (left), title, optional trailing icon (`⋯`, cart, gear, "Peta")
- **Section header row**: bold title left, red `Lihat Semua` / `Lihat Detail` link right
- **Chip / segmented tab**: pill; active = solid red fill + white text; inactive = light-gray fill + dark text
- **List row**: leading outlined icon, label, trailing chevron `›`
- **Status badge**: small pill, tinted bg + colored text
- **Primary button**: full-width, red, white semibold text, ~48 px tall, radius 10–12 px
- **Secondary button**: white bg, red 1 px border, red text
- **Progress bar**: 4–6 px, rounded; track light gray; fill red (due soon) or gray (not yet due)

---

## 3. Navigation

Persistent bottom navigation, five tabs, icon above label:

1. **Home**
2. **Sparepart**
3. **Bengkel**
4. **Pesanan**
5. **Akun**

Active tab: red icon (filled) + red label. Inactive: gray outline icon + gray label. Home is the default entry.

Screens without bottom nav: Splash, Detail Sparepart (sticky action bar instead), Detail Bengkel (sticky "Booking Sekarang" instead).

Active tab per screen in the image:

| Screen | Active tab |
|---|---|
| Home (both states) | Home |
| Sparepart Catalog | Sparepart |
| Bengkel List | Pesanan highlighted in the mockup **(mockup inconsistency — implement as Bengkel)** |
| Booking Layanan | Pesanan (booking leads into orders) |
| Pesanan | Pesanan |
| Akun | Akun |

---

# 4. Screen Inventory

Numbered exactly as in the reference image:

1. Splash Screen
2. Home (OBD Locked)
3. Home (OBD Connected)
4. Detail Kendaraan
5. Riwayat & Tracking
6. Data OBD (Connected)
7. Jadwal Perawatan
8. Sparepart (Catalog)
9. Detail Sparepart
10. Bengkel (List)
11. Detail Bengkel
12. Booking Layanan
13. Pesanan
14. Akun

Clickable transitions between all screens are required.

---

# 5. Splash Screen

## Layout

- Full-screen near-black background
- Dark-red outlined car silhouette (rear/taillight view) filling the lower half, faintly glowing
- Centered logo, upper-middle: red car-outline mark above wordmark **Oto**(white)**Ku**(red), large bold
- Tagline (white, centered, two lines):

> Perawatan kendaraan
> lebih mudah, selalu terpantau.

## Behavior

After a short delay, navigate to Home (OBD Locked).

---

# 6. Home — OBD Locked

## Header

- Wordmark **Oto**(black)**Ku**(red), left
- Right: bell icon with small red dot, circular avatar/person icon

## Vehicle Card

Full-width card with a pink (Primary Tint) background.

```text
Honda Beat 2021                      ✎
B 1234 XYZ ›
[scooter photo, right-aligned]
```

Stats row inside/under the card, three columns with small icons:

```text
🛵 12.450 km        🔧 Mar 2025        [ Baik ]
   Total Jarak         Servis Terakhir     Kondisi
```

- `Baik` is a green-tinted pill
- Tapping the card opens **Detail Kendaraan**
- Pencil icon edits the vehicle

## OBD Soft-Selling Card

Dark charcoal rounded card with a subtle red-glow background.

Title (white, bold):

> Hubungkan OBD
> untuk Data Kendaraan Real-time

Description (light gray, small):

> Pantau kondisi mesin, konsumsi BBM, dan deteksi masalah lebih awal.

Right side: small OBD dongle illustration with an "OtoKu" label.

CTA (full-width red button, trailing chevron):

> Lihat OBD OtoKu  ›

Feature strip below the CTA — four circular outlined icons with 2-line captions:

| Icon | Caption |
|---|---|
| Gauge | Data real-time |
| Magnifier/diagnostic | Deteksi masalah |
| Wrench | Rekomendasi servis |
| Linked nodes | Terintegrasi dengan sparepart & bengkel |

The card is a feature preview that communicates value, not a banner ad. **Locked metric cards are not shown on this screen** — the promo card replaces them.

## Maintenance Section

Header: **Perawatan Berikutnya** — `Lihat Semua` (red).

Pink alert card:

```text
[red oil-can icon]  Ganti Oli Mesin             ›
                    Dalam 1.550 km
                    Perkiraan: Okt 2025
```

Tapping opens **Jadwal Perawatan**.

---

# 7. Home — OBD Connected

Same header, vehicle card, stats row, and bottom nav as screen 6. The dark OBD promo card is replaced by live data.

## Connection Status

Green-tinted card with OBD device icon, trailing chevron:

```text
● OBD OtoKu Terhubung
  Terakhir update: 2 menit yang lalu
```

## Real-Time Data

Header: **Data Kendaraan (Real-time)** — `Lihat Semua` (red).

Six white metric cards in a 3 × 2 grid. Each has an icon, small label, large bold value, and small unit:

```text
RPM            Kecepatan       Suhu Mesin
1.250 rpm      0 km/h          87 °C

Tegangan Aki   Level BBM       Konsumsi BBM
13,8 V         64 %            42,5 km/L
```

## Vehicle Health

Header: **Kondisi Kendaraan** with trailing chevron. Card with a 2 × 2 grid of status items (circular icon + label + value):

```text
✓ Mesin          Normal        ✓ Sistem Pengisian   Normal
✓ Emisi          Normal        ⚠ Ada 1 kode masalah (P0301)   ← red text, red icon
```

Tapping opens **Data OBD**.

## Maintenance

Header: **Perawatan Berikutnya** — `Lihat Semua`.

```text
[oil icon] Ganti Oli Mesin                1.550 km lagi
           ███████████████░░ (red fill)
           12.450 / 14.000 km
```

---

# 8. Detail Kendaraan

App bar: back, **Detail Kendaraan**, `⋯` menu.

- Large vehicle photo (light-gray rounded backdrop) with a pencil edit button at top-right
- Name: **Honda Beat 2021** with a pencil icon
- License plate in a gray pill: `B 1234 XYZ`

Spec table (label gray, value dark, two columns):

| Label | Value |
|---|---|
| Merek | Honda |
| Model | Beat |
| Tahun | 2021 |
| Tipe | CBS |
| No. Rangka | MH1JM3110MK123456 |
| No. Mesin | JM31E1123456 |

Action rows (white cards, leading icon, trailing chevron):

1. Riwayat & Tracking
2. Jadwal Perawatan
3. Data OBD
4. Ubah Data Kendaraan
5. **Hapus Kendaraan** — red text and icon on a pink (Primary Tint) row

---

# 9. Riwayat & Tracking

App bar: back, **Riwayat & Tracking**.

Segmented pills: `Timeline` (active, red) | `Grafik` | `Biaya`.

## Timeline

Vertical line with dots on the left. Date headers: the current day is **red bold** ("Hari ini") with a red dot; older dates are dark with a gray dot. Under each date is its odometer reading in gray.

Each entry: gray rounded icon tile (fuel pump / wrench / brake-disc), title, gray sub-lines, odometer, and right-aligned price.

```text
● Hari ini
  12.450 km

  [⛽] Isi Pertalite                              Rp 50.000
       8,2 L (Rp 6.100/L)
       12.450 km

  [🔧] Servis Rutin                               Rp 80.000
       • Ganti oli mesin
       • Cek filter udara
       • Cek CVT
       12.100 km

● 10 Jul 2025
  11.800 km
  [⛽] Isi Pertalite  8,1 L (Rp 6.150/L)  11.800 km     Rp 50.000

● 15 Jun 2025
  11.200 km
  [⚙] Ganti Kampas Rem  11.200 km                      Rp 120.000

● 20 Apr 2025
  10.500 km
  [⛽] Isi Pertalite  8,3 L (Rp 6.000/L)  10.500 km     Rp 50.000

● 12 Mar 2025
  9.800 km
  [🔧] Servis Rutin  • Ganti oli mesin  • Cek filter udara …   Rp 80.000
```

## Grafik

Charts for mileage, fuel consumption, and maintenance spending **(derived)**.

## Biaya

Monthly/yearly maintenance expenditure **(derived)**.

---

# 10. Data OBD (Connected)

App bar: back, **Data OBD**.

Green-tinted status card with OBD device icon:

```text
OBD Terhubung
Terakhir update: 2 menit yang lalu
```

Segmented control (full-width, two halves): `Real-time` (active, red) | `Diagnostik` (gray).

## Real-time

One white card containing a 3 × 2 grid separated by hairlines; each cell has a small gray label, a large bold value, and a unit:

```text
RPM           Kecepatan     Suhu Mesin
1.250 rpm     0 km/h        87 °C

Tegangan Aki  Level BBM     Konsumsi BBM
13,8 V        64 %          42,5 km/L
```

Additional PIDs (engine load, throttle position, intake temperature) appear only when supported **(derived)**. Unsupported PIDs show:

> Tidak tersedia pada kendaraan ini

## Kondisi Kendaraan

Header with `Lihat Detail` (red). 2 × 2 grid:

```text
✓ Mesin  Normal            ✓ Sistem Pengisian  Normal
✓ Emisi  Normal            ⚠ 1 Kode Masalah  (P0301)  ← red
```

## Kode Masalah (DTC)

Row card:

```text
[⚠]  P0301                          [ Sedang ]  ›
     Cylinder 1 Misfire Detected
```

`Sedang` = amber pill.

Sticky/full-width red CTA:

> Lihat Solusi & Rekomendasi

---

# 11. Jadwal Perawatan

App bar: back, **Jadwal Perawatan**.

Chips: `Rekomendasi` (active, red) | `Semua` | `Selesai`.

Each card: leading component illustration, title, "Dalam X km" (gray), progress bar, `current / target km` caption, trailing chevron.

| Title | Remaining | Progress | Bar color |
|---|---|---|---|
| Ganti Oli Mesin | Dalam 1.550 km | 12.450 / 14.000 km | Red (nearly full) |
| Cek Kampas Rem | Dalam 3.000 km | 12.450 / 15.000 km | Gray |
| Cek Filter Udara | Dalam 3.000 km | 12.450 / 15.000 km | Gray |
| Cek Busi | Dalam 5.000 km | 12.450 / 17.500 km | Gray |
| Ganti Oli Gear (CVT) | Dalam 5.000 km | 12.450 / 17.500 km | Gray |

Recommendations depend on the registered vehicle. Additional items (battery, coolant) may appear under `Semua` where applicable **(derived)**.

---

# 12. Sparepart (Catalog)

App bar: back, **Sparepart**, cart icon with red badge dot.

- Search field: `Cari sparepart...` (leading magnifier)
- Chips: `Semua` (active, red) | `Oli & Cairan` | `Rem` | `Filter`

**Kategori** — 4 × 2 icon grid (square light tile + label):

```text
Oli & Cairan   Rem     Filter   Aki
Lampu          Body Part   CVT   Lainnya
```

**Rekomendasi untuk Honda Beat** — `Lihat Semua` (red). Horizontal product cards (photo, name, price):

| Product | Price |
|---|---|
| Oli Mesin Honda AHM SPX2 | Rp 65.000 |
| Kampas Rem Depan Beat | Rp 85.000 |
| (third card partially visible, horizontally scrollable) | |

Vehicle compatibility is the key differentiator: recommendations are always filtered to the selected vehicle.

---

# 13. Detail Sparepart

No app bar. Hero image with circular back button (top-left) and heart/wishlist button (top-right).

Thumbnail strip below the hero (5 thumbs, first selected with a dark border).

```text
Kampas Rem Depan
Honda Beat
Honda Genuine Parts
★ 4.8 (120 ulasan)

Rp 85.000  (red, bold)                 [ Stok tersedia ] (green pill)
```

Feature rows (outlined icon + bold title + gray subtitle):

| Title | Subtitle |
|---|---|
| 100% Original | Garansi resmi |
| Bisa pasang di bengkel | Rekomendasi OtoKu |
| Pengiriman cepat | 1-2 hari |

Sticky bottom bar:

- `Tambah ke Keranjang` — secondary (red outline)
- `Beli Sekarang` — primary (red fill)

If the product is not compatible with the selected vehicle, show **Tidak kompatibel dengan kendaraan Anda** and never imply a match **(derived)**.

---

# 14. Bengkel (List)

App bar: back, **Bengkel**, trailing `Peta` (red text with map icon).

- Location row: pin icon + `Jakarta Selatan`
- Search: `Cari bengkel...`
- Chips: `Semua` (active, red) | `Terdekat` | `Terbaik`

Workshop cards: left photo thumbnail, name, rating, distance, tags.

```text
Bengkel Jaya Motor
★ 4.7 (238)
2.1 km • Jakarta Selatan
[✓ Terverifikasi]  Servis Rutin • Ganti Oli

AutoCare Plus
★ 4.6 (120)
3.4 km • Jakarta Selatan
Spesialis CVT • Rem • Oli

Speed Motor
★ 4.5 (98)
4.2 km • Jakarta Selatan
Servis Lengkap • Body Part
```

`Terverifikasi` = green pill with check icon. Service tags are small gray pills.

---

# 15. Detail Bengkel

Full-bleed workshop photo header with a circular back button.

```text
Bengkel Jaya Motor
★ 4.7 (238 ulasan)    [✓ Terverifikasi]
📍 2.1 km • Jakarta Selatan
🕒 Buka • 08:00 - 21:00      ("Buka" in green)
```

Action row — 4 outlined circular icons with labels:

`Rute` · `Hubungi` · `Simpan` · `Bagikan`

Underlined tabs: `Layanan` (active, red underline) | `Ulasan` | `Galeri` | `Tentang`

**Layanan Populer**

```text
[img] Ganti Oli Mesin        [ Pilih ]
      Rp 50.000
      ⏱ 30 menit

[img] Servis CVT             [ Pilih ]
      Rp 80.000
      ⏱ 45 menit
```

`Pilih` = small solid-red pill button.

Sticky primary CTA:

> Booking Sekarang

---

# 16. Booking Layanan

App bar: back, **Booking Layanan**.

Selected workshop card (thumbnail, name, location):

```text
Bengkel Jaya Motor
Jakarta Selatan
```

**Pilih Layanan** — service card with image, name, price, duration, and a red check circle when selected (multiple allowed):

```text
Ganti Oli Mesin
Rp 50.000
⏱ 30 menit                                  ✓
```

**Pilih Tanggal** — 4 date chips (weekday over day + month). Selected chip: pink fill + red border + red text.

```text
Sen 22 Sep | Sel 23 Sep (selected) | Rab 24 Sep | Kam 25 Sep
```

**Pilih Waktu** — 4-column grid of slots. Selected: pink fill + red border + red text.

```text
08:00  09:00  10:00 (selected)  11:00
13:00  14:00  15:00             16:00
```

**Catatan (opsional)** — multiline field, placeholder:

> Contoh: minta dicek bagian lain juga

Sticky CTA: **Lanjutkan**

---

# 17. Pesanan

Top title **Pesanan Saya** (left-aligned, no back arrow).

Chips: `Sparepart` (active: pink fill, red border, red text) | `Layanan` | `Semua`

Order cards: thumbnail, order ID (gray), item title, subtitle, price, date (bottom-right), status badge (top-right).

| Order ID | Item | Detail | Price | Status | Date |
|---|---|---|---|---|---|
| #SP250922001 | Kampas Rem Depan | Honda Beat | Rp 85.000 | Diproses (amber) | 22 Sep 2025 |
| #SP250918003 | Oli Shell Advance | — | Rp 79.000 | Pesanan Selesai (green) | 18 Sep 2025 |
| #SV250915002 | Ganti Oli | Bengkel Jaya Motor | Rp 60.000 | Selesai (green) | 15 Sep 2025 |
| #SV250901004 | Servis Rutin | Bengkel AutoCare | Rp 80.000 | Selesai (green) | 01 Sep 2025 |

ID prefix: `SP` = sparepart, `SV` = service/booking. Other statuses: Dikirim, Dibatalkan **(derived)**.

Tapping a card opens order detail **(derived — not in image)**: status timeline (Pesanan dibuat → Sedang dikemas → Dikirim → Sampai tujuan → Pesanan selesai), product, quantity, price, address, payment.

---

# 18. Akun

Top title **Akun Saya** with a gear icon at right.

Profile row: circular gray avatar with initials **IF**, then:

```text
Ifan Prasetyo
ifan@email.com
Lihat Profil ›
```

Menu list (leading outlined icon, label, trailing chevron):

1. Kendaraan Saya
2. Pesanan Saya
3. Booking Layanan
4. Alamat Saya
5. Metode Pembayaran
6. Voucher & Promo
7. Pusat Bantuan
8. Tentang OtoKu
9. **Logout** — red text and red icon, no chevron

---

# 19. Vehicle Data Model

```json
{
  "id": "vehicle_001",
  "brand": "Honda",
  "model": "Beat",
  "year": 2021,
  "type": "CBS",
  "licensePlate": "B 1234 XYZ",
  "vin": "MH1JM3110MK123456",
  "engineNumber": "JM31E1123456",
  "mileage": 12450,
  "lastServiceDate": "2025-03-12",
  "condition": "good",
  "obdConnected": false
}
```

Display mapping: `condition: "good"` → badge `Baik`; `lastServiceDate` → `Mar 2025`; `mileage` → `12.450 km` (Indonesian thousands separator `.`, decimal comma).

---

# 20. OBD Data Model

```json
{
  "connected": true,
  "lastUpdated": "2025-09-22T14:20:00",
  "rpm": 1250,
  "speed": 0,
  "engineTemperature": 87,
  "batteryVoltage": 13.8,
  "fuelLevel": 64,
  "fuelConsumption": 42.5,
  "engineLoad": null,
  "throttlePosition": null,
  "diagnosticCodes": [
    {
      "code": "P0301",
      "description": "Cylinder 1 Misfire Detected",
      "severity": "medium"
    }
  ]
}
```

Severity `medium` renders as the `Sedang` badge. `null` values are supported because PID availability varies by vehicle. `lastUpdated` renders as relative text ("2 menit yang lalu").

Sample maintenance data:

```json
[
  { "name": "Ganti Oli Mesin",      "current": 12450, "target": 14000, "remaining": 1550 },
  { "name": "Cek Kampas Rem",       "current": 12450, "target": 15000, "remaining": 3000 },
  { "name": "Cek Filter Udara",     "current": 12450, "target": 15000, "remaining": 3000 },
  { "name": "Cek Busi",             "current": 12450, "target": 17500, "remaining": 5000 },
  { "name": "Ganti Oli Gear (CVT)", "current": 12450, "target": 17500, "remaining": 5000 }
]
```

---

# 21. Prototype Interaction Flow

Main flow:

```text
Splash → Home (OBD Locked)
  └─ Vehicle Card → Detail Kendaraan
       ├─ Riwayat & Tracking
       ├─ Jadwal Perawatan
       └─ Data OBD
```

OBD flow:

```text
Home (OBD Locked) → "Lihat OBD OtoKu" → OBD information / connection
  → Home (OBD Connected) → Kondisi Kendaraan → Data OBD
  → Kode Masalah P0301 → "Lihat Solusi & Rekomendasi"
       ├─ Sparepart
       └─ Bengkel
```

Sparepart flow:

```text
Sparepart → Category / Rekomendasi → Detail Sparepart
  → Tambah ke Keranjang / Beli Sekarang → Pesanan
```

Workshop flow:

```text
Bengkel → Detail Bengkel → Pilih (service) → Booking Layanan
  → Pilih Tanggal → Pilih Waktu → Lanjutkan → Pesanan
```

---

# 22. OBD Soft-Selling Strategy

OBD is presented as a capability, not an ad.

**Without OBD** the user gets: registered vehicle, manual mileage, maintenance schedule, service history, sparepart marketplace, workshop marketplace.

**With OBD** the user unlocks: real-time vehicle data, automatic data collection, more accurate mileage, vehicle health, diagnostic trouble codes, better maintenance recommendations.

The CTA reads **Lihat OBD OtoKu** (benefit/discovery framing), never "Beli OBD sekarang". The promo card sits on Home between the vehicle card and "Perawatan Berikutnya", styled as a dark premium feature panel with a four-icon benefit strip.

---

# 23. Compatibility and Safety Rules

Three data states:

**Available**

```text
RPM
1.250 rpm
```

**Unsupported**

```text
Fuel Level
Tidak tersedia pada kendaraan ini
```

**Disconnected** **(derived — used on any screen needing live data when no device is paired)**

```text
RPM
—
🔒 Hubungkan OBD
```

Never fabricate live values when disconnected.

Diagnostics are indications, not definitive diagnoses:

> Kode P0301 terdeteksi. Kemungkinan terdapat masalah pada sistem pembakaran. Periksa kendaraan lebih lanjut.

Avoid claims like "Busi Anda rusak."

---

# 24. Responsive Mobile Layout

Targets: 390 × 844, 393 × 852, 360 × 800.

- 16 px horizontal page padding
- 12 px gaps between cards
- 12–16 px card radius (pills fully rounded)
- 44 px minimum touch target
- Fixed bottom navigation (~64 px incl. safe area)
- Sticky primary CTA on Detail Sparepart, Detail Bengkel, Data OBD, Booking Layanan
- Horizontal scroll for product rails; vertical scroll for all screens
- Works for both motorcycle and car profiles

---

# 25. Prototype Priority

**P0 — Essential**: Home (Locked), Home (Connected), Detail Kendaraan, Riwayat & Tracking, Jadwal Perawatan, Data OBD, Detail Sparepart, Detail Bengkel

**P1 — Supporting**: Sparepart Catalog, Bengkel List, Booking Layanan, Pesanan

**P2 — Secondary**: Akun, Splash

---

# 26. Prototype Success Criteria

Within seconds a user should understand:

1. Which vehicle is selected (Honda Beat 2021, B 1234 XYZ)
2. Its condition (Baik)
3. What maintenance is due next (Ganti Oli Mesin, 1.550 km lagi)
4. What OBD adds
5. Why connecting OBD is useful
6. How OtoKu links diagnostics to maintenance, spareparts, and workshops

> **A digital companion for your vehicle, not merely an automotive marketplace.**
