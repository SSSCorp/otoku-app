import 'vehicle.dart';

enum ProductFitment { confirmed, possibleUnverified, incompatible, unknown }

class Product {
  const Product(
    this.name,
    this.category,
    this.price,
    this.icon, {
    this.kind,
    this.brands = const [],
    this.models = const [],
  });

  final String name, category, price, icon;

  /// Which kind of vehicle the part is made for; null means universal.
  final VehicleKind? kind;

  /// Lower-case brands/models the part is listed for. Empty means any.
  final List<String> brands, models;

  String get id => name.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '-');
  int get priceValue => int.parse(price.replaceAll(RegExp(r'[^0-9]'), ''));

  String get imageAsset => switch (icon) {
    'oil' => 'assets/product_images/engine_oil.jpg',
    'brake' =>
      name.contains('Mobil')
          ? 'assets/product_images/car_brake_pads.jpg'
          : 'assets/product_images/motorcycle_brake_pads.jpg',
    'filter' => 'assets/product_images/air_filter.jpg',
    'battery' => 'assets/product_images/motorcycle_battery.jpg',
    'lamp' => 'assets/product_images/led_bulb.jpg',
    _ => '',
  };

  /// Compatibility of this part with [vehicle]. The demo catalog carries no
  /// verified fitment data, so a match is only ever "possible, unverified".
  ProductFitment fitmentFor(Vehicle vehicle) {
    if (kind != null && kind != vehicle.kind) {
      return ProductFitment.incompatible;
    }
    final brand = vehicle.brand.toLowerCase();
    final model = vehicle.model.toLowerCase();
    if (brands.isNotEmpty && !brands.any(brand.contains)) {
      return ProductFitment.incompatible;
    }
    if (models.isNotEmpty) {
      return models.any(model.contains)
          ? ProductFitment.possibleUnverified
          : ProductFitment.incompatible;
    }
    if (brands.isNotEmpty) return ProductFitment.possibleUnverified;
    return ProductFitment.unknown;
  }

  static const catalog = [
    Product(
      'Oli Mesin Honda AHM SPX2',
      'Oli & Cairan',
      'Rp 65.000',
      'oil',
      kind: VehicleKind.motor,
      brands: ['honda'],
    ),
    Product(
      'Kampas Rem Depan Beat',
      'Rem',
      'Rp 85.000',
      'brake',
      kind: VehicleKind.motor,
      brands: ['honda'],
      models: ['beat'],
    ),
    Product(
      'Filter Udara Honda Beat',
      'Filter',
      'Rp 42.000',
      'filter',
      kind: VehicleKind.motor,
      brands: ['honda'],
      models: ['beat'],
    ),
    Product(
      'Aki Motor YTZ5S',
      'Aki',
      'Rp 185.000',
      'battery',
      kind: VehicleKind.motor,
    ),
    Product('Lampu LED Universal', 'Aksesori', 'Rp 75.000', 'lamp'),
    Product(
      'Kampas Rem Mobil Avanza',
      'Rem',
      'Rp 210.000',
      'brake',
      kind: VehicleKind.mobil,
      brands: ['toyota'],
      models: ['avanza'],
    ),
  ];
}

enum PesananKind { sparepart, layanan }

class PesananLine {
  const PesananLine(this.name, this.quantity, this.unitPrice);
  final String name;
  final int quantity, unitPrice;
  int get subtotal => quantity * unitPrice;

  Map<String, dynamic> toJson() => {
    'name': name,
    'quantity': quantity,
    'unitPrice': unitPrice,
  };
  factory PesananLine.fromJson(Map<String, dynamic> json) => PesananLine(
    json['name'] as String? ?? '',
    (json['quantity'] as num?)?.toInt() ?? 1,
    (json['unitPrice'] as num?)?.toInt() ?? 0,
  );
}

/// A recorded purchase of a sparepart or a Booking layanan at a bengkel.
class Pesanan {
  const Pesanan({
    required this.id,
    required this.kind,
    required this.status,
    required this.createdAt,
    this.lines = const [],
    this.vehicleId,
    this.placeId,
    this.placeName,
    this.services = const [],
    this.scheduledDate,
    this.timeSlot,
    this.notes = '',
    this.legacyText,
  });

  static const waitingPayment = 'Menunggu pembayaran';
  static const processing = 'Diproses';
  static const shipped = 'Dikirim';
  static const waitingConfirmation = 'Menunggu konfirmasi';
  static const confirmed = 'Dikonfirmasi';
  static const done = 'Selesai';
  static const cancelled = 'Dibatalkan';

  final String id, status;
  final PesananKind kind;
  final DateTime createdAt;
  final List<PesananLine> lines;
  final String? vehicleId, placeId, placeName, timeSlot, legacyText;
  final List<String> services;
  final DateTime? scheduledDate;
  final String notes;

  bool get isBooking => kind == PesananKind.layanan;
  int get total => lines.fold(0, (sum, line) => sum + line.subtotal);
  bool get isFinal => status == done || status == cancelled;
  bool get canCancel => !isFinal && status != shipped;

  static String dateLabel(DateTime d) => '${d.day}/${d.month}/${d.year}';

  String get title => isBooking
      ? 'Booking ${placeName ?? 'bengkel'}'
      : (lines.isEmpty
            ? (legacyText ?? 'Pesanan')
            : lines.map((l) => '${l.quantity}x ${l.name}').join(', '));

  String get detail => isBooking
      ? [
          services.join(', '),
          if (scheduledDate != null)
            '${dateLabel(scheduledDate!)} ${timeSlot ?? ''}'.trim(),
          if (notes.trim().isNotEmpty) 'Catatan: ${notes.trim()}',
        ].where((s) => s.isNotEmpty).join(' · ')
      : (total > 0 ? 'Rp ${_rupiah(total)}' : '');

  /// Next simulated step, as (new status, button label); null when final.
  (String, String)? get nextStep => switch (status) {
    waitingPayment => (processing, 'Simulasikan pembayaran'),
    processing => (shipped, 'Simulasikan pengiriman'),
    shipped => (done, 'Tandai pesanan diterima'),
    waitingConfirmation => (confirmed, 'Simulasikan konfirmasi bengkel'),
    confirmed => (done, 'Tandai layanan selesai'),
    _ => null,
  };

  Pesanan copyWith({String? status}) => Pesanan(
    id: id,
    kind: kind,
    status: status ?? this.status,
    createdAt: createdAt,
    lines: lines,
    vehicleId: vehicleId,
    placeId: placeId,
    placeName: placeName,
    services: services,
    scheduledDate: scheduledDate,
    timeSlot: timeSlot,
    notes: notes,
    legacyText: legacyText,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'kind': kind.name,
    'status': status,
    'createdAt': createdAt.toIso8601String(),
    'lines': lines.map((l) => l.toJson()).toList(),
    'vehicleId': vehicleId,
    'placeId': placeId,
    'placeName': placeName,
    'services': services,
    'scheduledDate': scheduledDate?.toIso8601String(),
    'timeSlot': timeSlot,
    'notes': notes,
    'legacyText': legacyText,
  };

  factory Pesanan.fromJson(Map<String, dynamic> json) => Pesanan(
    id: json['id'] as String,
    kind: json['kind'] == 'layanan'
        ? PesananKind.layanan
        : PesananKind.sparepart,
    status: json['status'] as String? ?? waitingPayment,
    createdAt: DateTime.tryParse('${json['createdAt']}') ?? DateTime.now(),
    lines: (json['lines'] as List? ?? [])
        .whereType<Map>()
        .map((l) => PesananLine.fromJson(Map<String, dynamic>.from(l)))
        .toList(),
    vehicleId: json['vehicleId'] as String?,
    placeId: json['placeId'] as String?,
    placeName: json['placeName'] as String?,
    services: (json['services'] as List? ?? []).cast<String>(),
    scheduledDate: DateTime.tryParse('${json['scheduledDate']}'),
    timeSlot: json['timeSlot'] as String?,
    notes: json['notes'] as String? ?? '',
    legacyText: json['legacyText'] as String?,
  );

  /// Converts a pre-v2 order string such as
  /// `#SP123 • 2x Oli • Menunggu pembayaran • Rp 130.000 • 1/1/2026`.
  factory Pesanan.fromLegacy(String text) {
    final fields = text.split(' • ');
    const statuses = [
      waitingPayment,
      waitingConfirmation,
      processing,
      shipped,
      done,
      cancelled,
      'Pesanan Selesai',
    ];
    final status = fields.firstWhere(
      statuses.contains,
      orElse: () => waitingPayment,
    );
    final id = fields.first;
    return Pesanan(
      id: id,
      kind: id.startsWith('#SV') ? PesananKind.layanan : PesananKind.sparepart,
      status: status == 'Pesanan Selesai' ? done : status,
      createdAt: DateTime.now(),
      legacyText: fields.length > 1 ? fields[1] : text,
    );
  }
}

String _rupiah(int value) => value.toString().replaceAllMapped(
  RegExp(r'\B(?=(\d{3})+(?!\d))'),
  (_) => '.',
);
