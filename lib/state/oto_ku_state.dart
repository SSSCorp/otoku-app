import 'package:flutter/foundation.dart';

import '../core/geo.dart';
import '../data/oto_ku_repository.dart';
import '../models/commerce.dart';
import '../models/place.dart';
import '../models/trip.dart';
import '../models/vehicle.dart';
import '../ui/common.dart' show formatKilometers;

/// Local, offline app state. Every mutation is persisted through
/// [OtoKuRepository]; there is no backend, account or real payment.
class OtoKuState extends ChangeNotifier {
  OtoKuState({OtoKuRepository? repository, DateTime Function()? clock})
    : repository = repository ?? MemoryOtoKuRepository(),
      _clock = clock ?? DateTime.now;

  static const schemaVersion = 2;

  final OtoKuRepository repository;
  final DateTime Function() _clock;
  int _idCounter = 0;

  bool onboardingComplete = false;
  bool initialized = false;

  /// Set when stored data could not be read; the splash offers retry/reset.
  String? loadError;

  /// Set when the last write to SQLite failed.
  String? saveError;

  final List<Product> products = List.of(Product.catalog);
  final List<Place> places = Place.demoPlaces;

  List<Vehicle> vehicles = [Vehicle.demo];
  String activeVehicleId = Vehicle.demo.id;
  final _allLogs = <Map<String, dynamic>>[];
  final records = <MaintenanceRecord>[];
  final orders = <Pesanan>[];
  final trips = <Trip>[];
  final cart = <Product>[];

  /// Optional delivery address for the simulated checkout.
  String address = '';

  bool obdConnected = false;
  String? obdAdapter;
  List<String> obdCodes = [];

  DateTime get now => _clock();

  String newId(String prefix) =>
      '$prefix${_clock().microsecondsSinceEpoch}${_idCounter++}';

  // ---------------------------------------------------------------- vehicles

  Vehicle get vehicle => vehicles.firstWhere(
    (v) => v.id == activeVehicleId,
    orElse: () => vehicles.first,
  );

  /// Logs of the active vehicle, newest first.
  List<Map<String, dynamic>> get logs =>
      _allLogs.where((l) => l['vehicleId'] == vehicle.id).toList();

  List<Map<String, dynamic>> logsOf(String vehicleId) =>
      _allLogs.where((l) => l['vehicleId'] == vehicleId).toList();

  Future<Vehicle> addVehicle(Vehicle draft) async {
    final created = Vehicle(
      id: newId('veh-'),
      kind: draft.kind,
      brand: draft.brand,
      model: draft.model,
      plate: draft.plate,
      type: draft.type,
      year: draft.year,
      mileage: draft.mileage,
    );
    vehicles = [...vehicles, created];
    activeVehicleId = created.id;
    await _commit();
    return created;
  }

  Future<void> setActiveVehicle(String id) async {
    if (id == activeVehicleId || !vehicles.any((v) => v.id == id)) return;
    activeVehicleId = id;
    await _commit();
  }

  /// Replaces the stored vehicle with the same id. The odometer may not go
  /// down; a changed reading is written to the history as an odometer entry.
  Future<void> updateVehicle(Vehicle updated) async {
    final index = vehicles.indexWhere((v) => v.id == updated.id);
    if (index < 0) throw ArgumentError('Kendaraan tidak ditemukan.');
    final previous = vehicles[index];
    if (updated.mileage < previous.mileage) {
      throw ArgumentError('Odometer cannot decrease without correction.');
    }
    vehicles = [...vehicles]..[index] = updated;
    if (updated.mileage != previous.mileage) {
      _allLogs.insert(0, _odometerLog(updated.id, updated.mileage, 'manual'));
    }
    await _commit();
  }

  /// Deletes a vehicle and its logs, maintenance records and trips.
  /// The last remaining vehicle cannot be deleted.
  Future<void> deleteVehicle(String id) async {
    if (vehicles.length <= 1) {
      throw StateError('Minimal satu kendaraan diperlukan.');
    }
    vehicles = vehicles.where((v) => v.id != id).toList();
    _allLogs.removeWhere((l) => l['vehicleId'] == id);
    records.removeWhere((r) => r.vehicleId == id);
    trips.removeWhere((t) => t.vehicleId == id);
    if (activeVehicleId == id) activeVehicleId = vehicles.first.id;
    await _commit();
  }

  /// Sets the odometer of the active vehicle. Decreases are rejected.
  Future<void> updateMileage(int mileage, {String source = 'manual'}) async {
    final current = vehicle;
    if (mileage < current.mileage) {
      throw ArgumentError('Odometer cannot decrease without correction.');
    }
    if (mileage == current.mileage) return;
    _replaceVehicle(current.copyWith(mileage: mileage));
    _allLogs.insert(0, _odometerLog(current.id, mileage, source));
    await _commit();
  }

  Map<String, dynamic> _odometerLog(String vehicleId, int km, String source) =>
      {
        'id': newId('log-'),
        'vehicleId': vehicleId,
        'type': 'odometer',
        'title': source == 'trip'
            ? 'Kilometer dari trip GPS'
            : 'Kilometer diperbarui',
        'value': km,
        'date': now.toIso8601String(),
        'source': source,
      };

  void _replaceVehicle(Vehicle updated) {
    vehicles = [for (final v in vehicles) v.id == updated.id ? updated : v];
  }

  // -------------------------------------------------------------------- logs

  /// Adds an activity log (BBM, servis, biaya, sparepart) to the active
  /// vehicle. An activity odometer reading above the vehicle's raises it.
  Future<Map<String, dynamic>> addLog(Map<String, dynamic> log) async {
    final entry = {
      ...log,
      'id': newId('log-'),
      'vehicleId': vehicle.id,
      'date': log['date'] ?? now.toIso8601String(),
    };
    _allLogs.insert(0, entry);
    final mileage = entry['mileage'];
    if (mileage is int && mileage > vehicle.mileage) {
      _replaceVehicle(vehicle.copyWith(mileage: mileage));
    }
    await _commit();
    return entry;
  }

  Future<void> updateLog(String id, Map<String, dynamic> changes) async {
    final index = _allLogs.indexWhere((l) => l['id'] == id);
    if (index < 0) return;
    _allLogs[index] = {
      ..._allLogs[index],
      ...changes,
      'id': id,
      'vehicleId': _allLogs[index]['vehicleId'],
    };
    await _commit();
  }

  Future<void> deleteLog(String id) async {
    _allLogs.removeWhere((l) => l['id'] == id);
    await _commit();
  }

  // ------------------------------------------------------------- maintenance

  List<MaintenanceStatus> maintenanceStatuses([Vehicle? forVehicle]) {
    final v = forVehicle ?? vehicle;
    return [
      for (final task in MaintenanceTask.forKind(v.kind))
        MaintenanceStatus.compute(v, task, records),
    ];
  }

  /// The task that is due first (most overdue, otherwise closest).
  MaintenanceStatus get nextMaintenance =>
      (maintenanceStatuses()
            ..sort((a, b) => a.remaining.compareTo(b.remaining)))
          .first;

  List<MaintenanceStatus> get maintenanceNeedingAttention =>
      maintenanceStatuses().where((s) => s.needsAttention).toList()
        ..sort((a, b) => a.remaining.compareTo(b.remaining));

  List<MaintenanceRecord> get activeRecords =>
      records.where((r) => r.vehicleId == vehicle.id).toList()
        ..sort((a, b) => b.date.compareTo(a.date));

  /// Marks [taskTitle] as done at the current odometer. The next due point is
  /// recomputed from this reading, and a service entry is added to the history.
  Future<void> completeMaintenance(String taskTitle) async {
    final v = vehicle;
    records.add(
      MaintenanceRecord(
        id: newId('mnt-'),
        vehicleId: v.id,
        task: taskTitle,
        mileage: v.mileage,
        date: now,
      ),
    );
    _allLogs.insert(0, {
      'id': newId('log-'),
      'vehicleId': v.id,
      'type': 'servis',
      'title': taskTitle,
      'mileage': v.mileage,
      'date': now.toIso8601String(),
      'source': 'maintenance',
    });
    await _commit();
  }

  // -------------------------------------------------------------------- cart

  int quantityOf(Product product) =>
      cart.where((item) => item.id == product.id).length;

  int get cartSubtotal => cart.fold(0, (sum, p) => sum + p.priceValue);

  Future<void> add(Product p) async {
    cart.add(p);
    await _commit();
  }

  Future<void> removeOne(Product product) async {
    final index = cart.lastIndexWhere((item) => item.id == product.id);
    if (index >= 0) cart.removeAt(index);
    await _commit();
  }

  // ----------------------------------------------------------------- pesanan

  Future<Pesanan> checkout() async {
    if (cart.isEmpty) throw StateError('Cart is empty.');
    final lines = <PesananLine>[];
    for (final product in cart.toSet()) {
      lines.add(
        PesananLine(product.name, quantityOf(product), product.priceValue),
      );
    }
    final order = Pesanan(
      id: '#SP${_clock().millisecondsSinceEpoch.toString().substring(5)}',
      kind: PesananKind.sparepart,
      status: Pesanan.waitingPayment,
      createdAt: now,
      lines: lines,
      vehicleId: vehicle.id,
    );
    orders.insert(0, order);
    cart.clear();
    await _commit();
    return order;
  }

  /// Saves a Booking layanan at [place] as a local Pesanan.
  Future<Pesanan> addBooking(
    Place place, {
    required List<String> services,
    required DateTime date,
    required String time,
    String notes = '',
  }) async {
    final order = Pesanan(
      id: '#SV${_clock().millisecondsSinceEpoch.toString().substring(5)}',
      kind: PesananKind.layanan,
      status: Pesanan.waitingConfirmation,
      createdAt: now,
      vehicleId: vehicle.id,
      placeId: place.id,
      placeName: place.name,
      services: services,
      scheduledDate: date,
      timeSlot: time,
      notes: notes,
      lines: [
        for (final name in services)
          PesananLine(
            name,
            1,
            place.offers.where((o) => o.name == name).firstOrNull?.estimate ??
                0,
          ),
      ],
    );
    orders.insert(0, order);
    await _commit();
    return order;
  }

  Pesanan? orderById(String id) => orders.where((o) => o.id == id).firstOrNull;

  /// Moves a Pesanan to its next simulated status. Finishing a booking adds
  /// a service entry to the vehicle history.
  Future<void> advancePesanan(String id) async {
    final index = orders.indexWhere((o) => o.id == id);
    if (index < 0) return;
    final next = orders[index].nextStep;
    if (next == null) return;
    final updated = orders[index].copyWith(status: next.$1);
    orders[index] = updated;
    if (updated.isBooking &&
        updated.status == Pesanan.done &&
        updated.vehicleId != null) {
      _allLogs.insert(0, {
        'id': newId('log-'),
        'vehicleId': updated.vehicleId,
        'type': 'servis',
        'title': 'Servis di ${updated.placeName ?? 'bengkel'}',
        'notes': updated.services.join(', '),
        'date': now.toIso8601String(),
        'source': 'booking',
      });
    }
    await _commit();
  }

  Future<void> cancelPesanan(String id) async {
    final index = orders.indexWhere((o) => o.id == id);
    if (index < 0 || !orders[index].canCancel) return;
    orders[index] = orders[index].copyWith(status: Pesanan.cancelled);
    await _commit();
  }

  Future<void> setAddress(String value) async {
    address = value.trim();
    await _commit();
  }

  // --------------------------------------------------------------------- obd

  /// Connects the *simulated* adapter and produces demo trouble codes.
  Future<void> connectObd({String adapter = 'ELM327 Mini (simulasi)'}) async {
    obdConnected = true;
    obdAdapter = adapter;
    obdCodes = ['P0301', 'P0562'];
    await _commit();
  }

  Future<void> disconnectObd() async {
    obdConnected = false;
    obdAdapter = null;
    await _commit();
  }

  Future<void> clearObdCodes() async {
    obdCodes = [];
    await _commit();
  }

  // ------------------------------------------------------------------- trips

  List<Trip> get activeTrips =>
      trips.where((t) => t.vehicleId == vehicle.id).toList();

  Future<Trip> saveTrip({
    required DateTime startedAt,
    required DateTime endedAt,
    required double distanceMeters,
    required int durationSeconds,
  }) async {
    final trip = Trip(
      id: newId('trip-'),
      vehicleId: vehicle.id,
      startedAt: startedAt,
      endedAt: endedAt,
      distanceMeters: distanceMeters,
      durationSeconds: durationSeconds,
    );
    trips.insert(0, trip);
    await _commit();
    return trip;
  }

  /// Adds the trip distance to the odometer. Returns the new reading.
  /// Throws [ArgumentError] when the result would lower the odometer or the
  /// trip is shorter than 1 km.
  Future<int> addTripToMileage(String tripId) async {
    final index = trips.indexWhere((t) => t.id == tripId);
    if (index < 0) throw ArgumentError('Trip tidak ditemukan.');
    final trip = trips[index];
    if (trip.addedToMileage) throw StateError('Trip sudah ditambahkan.');
    if (trip.roundedKm < 1) {
      throw ArgumentError('Jarak trip kurang dari 1 km.');
    }
    final target = vehicle.mileage + trip.roundedKm;
    await updateMileage(target, source: 'trip');
    trips[index] = trip.copyWith(addedToMileage: true);
    await _commit();
    return target;
  }

  Future<void> deleteTrip(String id) async {
    trips.removeWhere((t) => t.id == id);
    await _commit();
  }

  // ------------------------------------------------------------- persistence

  Future<void> restore() async {
    loadError = null;
    try {
      onboardingComplete = await repository.hasCompletedOnboarding();
      final saved = await repository.loadState();
      if (saved != null) _apply(saved);
    } catch (error) {
      loadError = '$error';
    }
    initialized = true;
    notifyListeners();
  }

  /// Wipes stored app data (used by the splash error state).
  Future<void> resetLocalData() async {
    await repository.saveState({'schema': schemaVersion});
    vehicles = [Vehicle.demo];
    activeVehicleId = Vehicle.demo.id;
    _allLogs.clear();
    records.clear();
    orders.clear();
    trips.clear();
    cart.clear();
    address = '';
    obdConnected = false;
    obdAdapter = null;
    obdCodes = [];
    loadError = null;
    notifyListeners();
  }

  Future<void> finishOnboarding() async {
    onboardingComplete = true;
    await repository.completeOnboarding();
    notifyListeners();
  }

  void _apply(Map<String, dynamic> saved) {
    final isLegacy = saved['schema'] == null;
    if (isLegacy) {
      final raw = saved['vehicle'];
      final details = raw is Map
          ? Map<String, dynamic>.from(raw)
          : <String, dynamic>{};
      if (saved['mileage'] is int) details['mileage'] ??= saved['mileage'];
      vehicles = [
        Vehicle.fromJson({...details, 'id': 'veh-1'}, fallback: Vehicle.demo),
      ];
      activeVehicleId = 'veh-1';
    } else {
      final list = (saved['vehicles'] as List? ?? [])
          .whereType<Map>()
          .map((v) => Vehicle.fromJson(Map<String, dynamic>.from(v)))
          .toList();
      vehicles = list.isEmpty ? [Vehicle.demo] : list;
      activeVehicleId =
          saved['activeVehicleId'] as String? ?? vehicles.first.id;
    }
    final firstId = vehicles.first.id;

    _allLogs
      ..clear()
      ..addAll(
        (saved['logs'] as List? ?? []).whereType<Map>().map((raw) {
          final log = Map<String, dynamic>.from(raw);
          log['id'] ??= newId('log-');
          log['vehicleId'] ??= firstId;
          return log;
        }),
      );

    records.clear();
    if (isLegacy) {
      for (final title
          in (saved['completedMaintenance'] as List? ?? []).cast<String>()) {
        records.add(
          MaintenanceRecord(
            id: newId('mnt-'),
            vehicleId: firstId,
            task: title,
            mileage: vehicles.first.mileage,
            date: now,
          ),
        );
      }
    } else {
      records.addAll(
        (saved['maintenanceRecords'] as List? ?? []).whereType<Map>().map(
          (r) => MaintenanceRecord.fromJson(Map<String, dynamic>.from(r)),
        ),
      );
    }

    orders.clear();
    for (final raw in saved['orders'] as List? ?? []) {
      if (raw is String) {
        orders.add(Pesanan.fromLegacy(raw));
      } else if (raw is Map) {
        orders.add(Pesanan.fromJson(Map<String, dynamic>.from(raw)));
      }
    }

    trips
      ..clear()
      ..addAll(
        (saved['trips'] as List? ?? []).whereType<Map>().map(
          (t) => Trip.fromJson(Map<String, dynamic>.from(t)),
        ),
      );

    cart
      ..clear()
      ..addAll(
        (saved['cart'] as List? ?? []).cast<String>().expand(
          (id) => products.where((p) => p.id == id),
        ),
      );

    address = saved['address'] as String? ?? '';

    final obd = saved['obd'];
    if (obd is Map) {
      obdConnected = obd['connected'] == true;
      obdAdapter = obd['adapter'] as String?;
      obdCodes = (obd['codes'] as List? ?? []).cast<String>();
    } else {
      obdConnected = saved['obdConnected'] == true;
      obdAdapter = obdConnected ? 'ELM327 Mini (simulasi)' : null;
      obdCodes = obdConnected ? ['P0301', 'P0562'] : [];
    }
  }

  Future<void> _commit() async {
    notifyListeners();
    try {
      await repository.saveState({
        'schema': schemaVersion,
        'activeVehicleId': activeVehicleId,
        'vehicles': vehicles.map((v) => v.toJson()).toList(),
        'logs': _allLogs,
        'maintenanceRecords': records.map((r) => r.toJson()).toList(),
        'orders': orders.map((o) => o.toJson()).toList(),
        'trips': trips.map((t) => t.toJson()).toList(),
        'cart': cart.map((p) => p.id).toList(),
        'address': address,
        'obd': {
          'connected': obdConnected,
          'adapter': obdAdapter,
          'codes': obdCodes,
        },
      });
      if (saveError != null) {
        saveError = null;
        notifyListeners();
      }
    } catch (error) {
      saveError = '$error';
      notifyListeners();
    }
  }
}

/// Sort/filter model for the map screen's place list.
enum PlaceFilter {
  all('Semua'),
  bengkelPartner('Bengkel partner'),
  bengkelOther('Bengkel non-partner'),
  bengkel('Bengkel'),
  spbu('SPBU'),
  minimarket('Minimarket');

  const PlaceFilter(this.label);
  final String label;

  bool matches(Place p) => switch (this) {
    PlaceFilter.all => true,
    PlaceFilter.bengkelPartner => p.isBengkel && p.partner,
    PlaceFilter.bengkelOther => p.isBengkel && !p.partner,
    PlaceFilter.bengkel => p.isBengkel,
    PlaceFilter.spbu => p.category == PlaceCategory.spbu,
    PlaceFilter.minimarket => p.category == PlaceCategory.minimarket,
  };
}

enum PlaceSort {
  distance('Terdekat'),
  name('Nama A–Z');

  const PlaceSort(this.label);
  final String label;
}

String formatRupiah(int value) => 'Rp ${formatKilometers(value)}';

String formatDateId(DateTime d) =>
    '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

String describeDistance(double? meters) =>
    meters == null ? 'Jarak belum tersedia' : formatDistance(meters);
