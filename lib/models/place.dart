import 'package:latlong2/latlong.dart';

enum PlaceCategory {
  bengkel('Bengkel'),
  spbu('SPBU'),
  minimarket('Minimarket');

  const PlaceCategory(this.label);
  final String label;
}

/// Daily opening hours. Times are minutes after midnight.
class OpeningHours {
  const OpeningHours(this.open, this.close, {this.closedWeekdays = const {}});
  const OpeningHours.allDay()
    : open = 0,
      close = 24 * 60,
      closedWeekdays = const {};

  final int open, close;

  /// `DateTime.weekday` values (1 = Monday ... 7 = Sunday) the place is closed.
  final Set<int> closedWeekdays;

  bool get is24h => open == 0 && close >= 24 * 60 && closedWeekdays.isEmpty;

  bool isOpenAt(DateTime time) {
    if (closedWeekdays.contains(time.weekday)) return false;
    final minute = time.hour * 60 + time.minute;
    return minute >= open && minute < close;
  }

  static String _clock(int minutes) =>
      '${(minutes ~/ 60 % 24).toString().padLeft(2, '0')}:${(minutes % 60).toString().padLeft(2, '0')}';

  String get rangeLabel =>
      is24h ? 'Buka 24 jam' : '${_clock(open)}–${_clock(close)}';

  /// e.g. "Buka sekarang · tutup 17:00" or "Tutup · buka 08:00".
  String statusLabel(DateTime now) {
    if (is24h) return 'Buka 24 jam';
    return isOpenAt(now)
        ? 'Buka sekarang · tutup ${_clock(close)}'
        : 'Tutup · buka ${_clock(open)}';
  }
}

class ServiceOffer {
  const ServiceOffer(this.id, this.name, this.estimate, this.minutes);
  final String id, name;
  final int estimate, minutes;
}

class Place {
  const Place({
    required this.id,
    required this.name,
    required this.category,
    required this.position,
    required this.address,
    required this.services,
    required this.hours,
    this.partner = false,
    this.offers = const [],
  });

  final String id, name, address;
  final PlaceCategory category;
  final LatLng position;
  final List<String> services;
  final OpeningHours hours;
  final bool partner;

  /// Bookable services (bengkel only).
  final List<ServiceOffer> offers;

  /// The bookable service that best matches a maintenance task or OBD check.
  ServiceOffer? offerForTask(String task) {
    final t = task.toLowerCase();
    final wanted = t.contains('oli mesin')
        ? 'oil'
        : t.contains('cvt') || t.contains('transmisi') || t.contains('oli gear')
        ? 'cvt'
        : t.contains('rem')
        ? 'brake'
        : t.contains('obd') || t.contains('kode')
        ? 'diag'
        : 'tune';
    return offers.where((o) => o.id == wanted).firstOrNull ??
        offers.where((o) => o.id == 'tune').firstOrNull;
  }

  bool get isBengkel => category == PlaceCategory.bengkel;
  bool get bookingEnabled => isBengkel && offers.isNotEmpty;
  String get servicesLabel => services.join(' · ');

  static const _oil = ServiceOffer('oil', 'Ganti Oli Mesin', 50000, 30);
  static const _cvt = ServiceOffer('cvt', 'Servis CVT', 80000, 45);
  static const _brake = ServiceOffer(
    'brake',
    'Cek & Ganti Kampas Rem',
    60000,
    40,
  );
  static const _tune = ServiceOffer(
    'tune',
    'Servis Ringan / Tune-up',
    90000,
    60,
  );
  static const _diag = ServiceOffer('diag', 'Pemeriksaan Kode OBD', 40000, 30);

  /// Demo places at real Bekasi Utara coordinates. Names, hours and services
  /// are illustrative and unverified.
  static const demoPlaces = <Place>[
    Place(
      id: 'bengkel-jaya-motor',
      name: 'Bengkel Jaya Motor',
      category: PlaceCategory.bengkel,
      position: LatLng(-6.2051, 106.9910),
      address: 'Jl. Kali Abang Tengah, Bekasi Utara · lokasi demo',
      services: ['Servis Rutin', 'Ganti Oli', 'Rem', 'CVT'],
      hours: OpeningHours(8 * 60, 17 * 60, closedWeekdays: {7}),
      partner: true,
      offers: [_oil, _cvt, _brake, _tune, _diag],
    ),
    Place(
      id: 'autocare-plus',
      name: 'AutoCare Plus',
      category: PlaceCategory.bengkel,
      position: LatLng(-6.2108, 107.0034),
      address: 'Jl. Boulevard Ujung Harapan, Bekasi Utara · lokasi demo',
      services: ['Spesialis CVT', 'Rem', 'Oli'],
      hours: OpeningHours(9 * 60, 18 * 60),
      offers: [_oil, _cvt, _brake],
    ),
    Place(
      id: 'speed-motor',
      name: 'Speed Motor',
      category: PlaceCategory.bengkel,
      position: LatLng(-6.1962, 106.9835),
      address: 'Jl. Perjuangan, Bekasi Utara · lokasi demo',
      services: ['Servis Lengkap', 'Body Part', 'Tune-up'],
      hours: OpeningHours(8 * 60 + 30, 16 * 60 + 30, closedWeekdays: {7}),
      offers: [_oil, _tune, _diag],
    ),
    Place(
      id: 'bengkel-mitra-roda',
      name: 'Bengkel Mitra Roda',
      category: PlaceCategory.bengkel,
      position: LatLng(-6.2175, 106.9970),
      address: 'Jl. Teluk Pucung, Bekasi Utara · lokasi demo',
      services: ['Motor & Mobil', 'Rem', 'Tune-up'],
      hours: OpeningHours(8 * 60, 20 * 60),
      offers: [_oil, _brake, _tune, _diag],
    ),
    Place(
      id: 'spbu-pertamina-demo',
      name: 'SPBU Pertamina Demo',
      category: PlaceCategory.spbu,
      position: LatLng(-6.2078, 106.9962),
      address: 'Jl. Sultan Agung, Bekasi Utara · lokasi demo',
      services: ['Pertalite', 'Pertamax', 'Pertamax Turbo'],
      hours: OpeningHours.allDay(),
    ),
    Place(
      id: 'spbu-harapan-indah-demo',
      name: 'SPBU Harapan Indah Demo',
      category: PlaceCategory.spbu,
      position: LatLng(-6.1900, 106.9920),
      address: 'Jl. Harapan Indah, Bekasi Utara · lokasi demo',
      services: ['Pertalite', 'Pertamax', 'Solar'],
      hours: OpeningHours(5 * 60, 22 * 60),
    ),
    Place(
      id: 'spbu-summarecon-demo',
      name: 'SPBU Boulevard Demo',
      category: PlaceCategory.spbu,
      position: LatLng(-6.2210, 107.0075),
      address: 'Jl. Boulevard Summarecon, Bekasi Utara · lokasi demo',
      services: ['Pertalite', 'Pertamax', 'Dexlite'],
      hours: OpeningHours.allDay(),
    ),
    Place(
      id: 'minimarket-demo',
      name: 'Minimarket Demo',
      category: PlaceCategory.minimarket,
      position: LatLng(-6.2035, 106.9940),
      address: 'Jl. Kali Abang, Bekasi Utara · lokasi demo',
      services: ['Kebutuhan perjalanan', 'Minuman', 'ATM'],
      hours: OpeningHours(7 * 60, 22 * 60),
    ),
    Place(
      id: 'minimarket-24-demo',
      name: 'Minimarket 24 Jam Demo',
      category: PlaceCategory.minimarket,
      position: LatLng(-6.2150, 106.9895),
      address: 'Jl. Bintara, Bekasi Utara · lokasi demo',
      services: ['Kebutuhan perjalanan', 'Oli & aksesori dasar'],
      hours: OpeningHours.allDay(),
    ),
  ];

  /// Rough centre of the demo area, used when no user fix is available.
  static const demoCenter = LatLng(-6.2065, 106.9970);
}
