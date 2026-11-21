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

  /// Places around BINUS Bekasi. Positions and names come from OpenStreetMap;
  /// opening hours and services are illustrative and unverified. Only the
  /// OtoKu partner entry is bookable.
  static const demoPlaces = <Place>[
    Place(
      id: 'bengkel-jaya-motor',
      name: 'Bengkel Jaya Motor',
      category: PlaceCategory.bengkel,
      position: LatLng(-6.2178, 107.0008),
      address: 'Marga Mulya, Bekasi Utara',
      services: ['Servis rutin', 'Ganti oli', 'Rem', 'CVT'],
      hours: OpeningHours(8 * 60, 17 * 60, closedWeekdays: {7}),
      partner: true,
      offers: [_oil, _cvt, _brake, _tune, _diag],
    ),
    Place(
      id: 'karla-jaya-motor',
      name: 'Karla Jaya Motor',
      category: PlaceCategory.bengkel,
      position: LatLng(-6.27008, 107.00381),
      address: 'Bekasi Selatan',
      services: ['Bengkel umum', 'Servis mesin'],
      hours: OpeningHours(8 * 60, 17 * 60, closedWeekdays: {7}),
    ),
    Place(
      id: 'fahmi-jaya-motor',
      name: 'Fahmi Jaya Motor',
      category: PlaceCategory.bengkel,
      position: LatLng(-6.27011, 107.00391),
      address: 'Bekasi Selatan',
      services: ['Bengkel umum', 'Tune-up'],
      hours: OpeningHours(8 * 60 + 30, 16 * 60 + 30, closedWeekdays: {7}),
    ),
    Place(
      id: 'honda-service',
      name: 'Honda Service',
      category: PlaceCategory.bengkel,
      position: LatLng(-6.24477, 106.94271),
      address: 'Jatiasih, Bekasi',
      services: ['Servis resmi', 'Sparepart'],
      hours: OpeningHours(8 * 60, 16 * 60, closedWeekdays: {6, 7}),
    ),
    Place(
      id: 'duren-sawit-mobilindo',
      name: 'PT Duren Sawit Mobilindo',
      category: PlaceCategory.bengkel,
      position: LatLng(-6.23056, 106.92295),
      address: 'Duren Sawit, Jakarta Timur',
      services: ['Servis mobil', 'Body repair'],
      hours: OpeningHours(8 * 60, 17 * 60, closedWeekdays: {7}),
    ),
    Place(
      id: 'spbu-34-17542',
      name: 'Pertamina 34-17542',
      category: PlaceCategory.spbu,
      position: LatLng(-6.21339, 107.03379),
      address: 'Bekasi Utara',
      services: ['Pertalite', 'Pertamax', 'Solar'],
      hours: OpeningHours.allDay(),
    ),
    Place(
      id: 'spbu-34-13908',
      name: 'SPBU 34-13908',
      category: PlaceCategory.spbu,
      position: LatLng(-6.18954, 106.96733),
      address: 'Cakung, Jakarta Timur',
      services: ['Pertalite', 'Pertamax', 'Solar'],
      hours: OpeningHours(5 * 60, 22 * 60),
    ),
    Place(
      id: 'spbu-34-13907',
      name: 'SPBU 34-13907',
      category: PlaceCategory.spbu,
      position: LatLng(-6.20783, 106.95396),
      address: 'Bekasi Barat',
      services: ['Pertalite', 'Pertamax'],
      hours: OpeningHours.allDay(),
    ),
    Place(
      id: 'spbu-34-13905',
      name: 'SPBU 34-13905',
      category: PlaceCategory.spbu,
      position: LatLng(-6.19974, 106.95595),
      address: 'Bekasi Barat',
      services: ['Pertalite', 'Pertamax', 'Dexlite'],
      hours: OpeningHours.allDay(),
    ),
    Place(
      id: 'spbu-34-13421',
      name: 'SPBU 34-13421',
      category: PlaceCategory.spbu,
      position: LatLng(-6.21833, 106.94258),
      address: 'Jatiasih, Bekasi',
      services: ['Pertalite', 'Pertamax'],
      hours: OpeningHours(5 * 60, 22 * 60),
    ),
    Place(
      id: 'alfamart-kh-muchtar-tabrani',
      name: 'Alfamart KH Muchtar Tabrani',
      category: PlaceCategory.minimarket,
      position: LatLng(-6.22173, 107.00317),
      address: 'Jl. KH Muchtar Tabrani',
      services: ['Kebutuhan perjalanan', 'Minuman'],
      hours: OpeningHours(7 * 60, 22 * 60),
    ),
    Place(
      id: 'indomaret-kh-muchtar-tabrani',
      name: 'Indomaret KH Muchtar Tabrani',
      category: PlaceCategory.minimarket,
      position: LatLng(-6.22223, 107.00331),
      address: 'Jl. KH Muchtar Tabrani',
      services: ['Kebutuhan perjalanan', 'Minuman'],
      hours: OpeningHours.allDay(),
    ),
    Place(
      id: 'indomaret-marga-mulya',
      name: 'Indomaret Marga Mulya',
      category: PlaceCategory.minimarket,
      position: LatLng(-6.21487, 107.00322),
      address: 'Marga Mulya, Bekasi Utara',
      services: ['Kebutuhan harian', 'ATM'],
      hours: OpeningHours(7 * 60, 22 * 60),
    ),
    Place(
      id: 'indomaret-harapan-jaya',
      name: 'Indomaret Harapan Jaya',
      category: PlaceCategory.minimarket,
      position: LatLng(-6.21446, 107.00518),
      address: 'Harapan Jaya, Bekasi Utara',
      services: ['Kebutuhan harian'],
      hours: OpeningHours.allDay(),
    ),
  ];

  /// Reference point of the sample area (BINUS Bekasi), used when no user fix
  /// is available.
  static const demoCenter = LatLng(-6.2196, 106.9995);
}
