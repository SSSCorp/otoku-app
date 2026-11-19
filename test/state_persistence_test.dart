import 'package:flutter_test/flutter_test.dart';
import 'package:otoku/data/oto_ku_repository.dart';
import 'package:otoku/models/commerce.dart';
import 'package:otoku/models/place.dart';
import 'package:otoku/models/vehicle.dart';
import 'package:otoku/state/oto_ku_state.dart';

final t0 = DateTime(2026, 11, 19, 10);

Future<OtoKuState> open(MemoryOtoKuRepository repo) async {
  final state = OtoKuState(repository: repo, clock: () => t0);
  await state.restore();
  return state;
}

void main() {
  late MemoryOtoKuRepository repo;
  late OtoKuState state;
  setUp(() async {
    repo = MemoryOtoKuRepository(onboardingComplete: true);
    state = await open(repo);
  });

  group('vehicles', () {
    test(
      'add, switch, edit and delete; the last vehicle is protected',
      () async {
        final car = await state.addVehicle(
          const Vehicle(
            kind: VehicleKind.mobil,
            brand: 'Toyota',
            model: 'Avanza',
            plate: 'B 9 CAR',
            type: '1.3 G',
            year: 2019,
            mileage: 54000,
          ),
        );
        expect(state.vehicles, hasLength(2));
        expect(
          state.vehicle.id,
          car.id,
          reason: 'a new vehicle becomes active',
        );

        await state.updateVehicle(
          car.copyWith(plate: 'B 77 CAR', mileage: 54100),
        );
        expect(state.vehicle.plate, 'B 77 CAR');
        expect(state.logs.first['type'], 'odometer');

        await state.setActiveVehicle('veh-1');
        expect(state.vehicle.brand, 'Honda');
        expect(state.logs, isEmpty, reason: 'logs are per vehicle');

        await state.deleteVehicle(car.id);
        expect(state.vehicles.single.id, 'veh-1');
        expect(() => state.deleteVehicle('veh-1'), throwsStateError);
      },
    );

    test(
      'deleting the active vehicle activates another and drops its data',
      () async {
        final car = await state.addVehicle(
          const Vehicle(
            brand: 'Toyota',
            model: 'Avanza',
            plate: 'B 9',
            type: '',
            year: 2019,
            mileage: 1000,
          ),
        );
        await state.addLog({'type': 'bbm', 'title': 'Pertalite'});
        await state.deleteVehicle(car.id);
        expect(state.vehicle.id, 'veh-1');
        expect(state.logsOf(car.id), isEmpty);
      },
    );

    test('odometer cannot decrease through updateVehicle', () async {
      expect(
        () => state.updateVehicle(state.vehicle.copyWith(mileage: 100)),
        throwsArgumentError,
      );
      expect(state.vehicle.mileage, 12450);
    });

    test('product compatibility follows the active vehicle', () async {
      final oil = state.products.firstWhere(
        (p) => p.name.contains('Oli Mesin'),
      );
      final avanzaPads = state.products.firstWhere(
        (p) => p.name.contains('Avanza'),
      );
      expect(oil.fitmentFor(state.vehicle), ProductFitment.possibleUnverified);
      expect(avanzaPads.fitmentFor(state.vehicle), ProductFitment.incompatible);
      await state.addVehicle(
        const Vehicle(
          kind: VehicleKind.mobil,
          brand: 'Toyota',
          model: 'Avanza',
          plate: 'B 9',
          type: '',
          year: 2019,
          mileage: 1000,
        ),
      );
      expect(
        avanzaPads.fitmentFor(state.vehicle),
        ProductFitment.possibleUnverified,
      );
      expect(oil.fitmentFor(state.vehicle), ProductFitment.incompatible);
    });
  });

  group('maintenance', () {
    test('due soon, overdue, then reset when marked done', () async {
      var oil = state.maintenanceStatuses().firstWhere(
        (s) => s.task.title == 'Ganti Oli Mesin',
      );
      expect(oil.dueAt, 14000);
      expect(oil.remaining, 1550);
      expect(oil.level, DueLevel.ok);

      await state.updateMileage(13200);
      oil = state.maintenanceStatuses().firstWhere(
        (s) => s.task.title == 'Ganti Oli Mesin',
      );
      expect(oil.level, DueLevel.soon);
      expect(
        state.maintenanceNeedingAttention.map((s) => s.task.title),
        contains('Ganti Oli Mesin'),
      );

      await state.updateMileage(14100);
      oil = state.maintenanceStatuses().firstWhere(
        (s) => s.task.title == 'Ganti Oli Mesin',
      );
      expect(oil.level, DueLevel.overdue);
      expect(oil.remaining, -100);
      expect(state.nextMaintenance.task.title, 'Ganti Oli Mesin');

      await state.completeMaintenance('Ganti Oli Mesin');
      oil = state.maintenanceStatuses().firstWhere(
        (s) => s.task.title == 'Ganti Oli Mesin',
      );
      expect(oil.dueAt, 16100);
      expect(oil.level, DueLevel.ok);
      expect(state.activeRecords.single.mileage, 14100);
      expect(
        state.logs.first['type'],
        'servis',
        reason: 'completion lands in service history',
      );
    });

    test('cars use their own task intervals', () async {
      await state.addVehicle(
        const Vehicle(
          kind: VehicleKind.mobil,
          brand: 'Toyota',
          model: 'Avanza',
          plate: 'B 9',
          type: '',
          year: 2019,
          mileage: 54000,
        ),
      );
      final oil = state.maintenanceStatuses().firstWhere(
        (s) => s.task.title == 'Ganti Oli Mesin',
      );
      expect(oil.dueAt, 55000);
      expect(
        state.maintenanceStatuses().any((s) => s.task.title.contains('CVT')),
        isFalse,
      );
    });
  });

  group('manual logs', () {
    test('add, edit and delete every log type', () async {
      for (final type in ['bbm', 'servis', 'biaya', 'sparepart']) {
        await state.addLog({
          'type': type,
          'title': 'Catatan $type',
          'amount': 1000,
        });
      }
      expect(state.logs, hasLength(4));
      final id = state.logs.last['id'] as String;
      await state.updateLog(id, {'title': 'Diubah', 'amount': 2500});
      expect(state.logs.firstWhere((l) => l['id'] == id)['title'], 'Diubah');
      expect(
        state.logs.firstWhere((l) => l['id'] == id)['type'],
        'bbm',
        reason: 'type is preserved',
      );
      await state.deleteLog(id);
      expect(state.logs, hasLength(3));
    });

    test('an activity reading above the odometer raises it; below is never applied', () async {
      await state.addLog({
        'type': 'servis',
        'title': 'Servis',
        'mileage': 12800,
      });
      expect(state.vehicle.mileage, 12800);
      await state.addLog({'type': 'servis', 'title': 'Lama', 'mileage': 12000});
      expect(state.vehicle.mileage, 12800);
    });
  });

  group('pesanan', () {
    test('checkout turns the cart into a pending sparepart order', () async {
      final oil = state.products.first;
      await state.add(oil);
      await state.add(oil);
      final order = await state.checkout();
      expect(order.kind, PesananKind.sparepart);
      expect(order.status, Pesanan.waitingPayment);
      expect(order.total, 130000);
      expect(order.title, '2x Oli Mesin Honda AHM SPX2');
      expect(state.cart, isEmpty);
      expect(() => state.checkout(), throwsStateError);
    });

    test(
      'status flow: pay → ship → deliver; cancel only before shipping',
      () async {
        await state.add(state.products.first);
        final order = await state.checkout();
        await state.advancePesanan(order.id);
        expect(state.orderById(order.id)!.status, Pesanan.processing);
        await state.advancePesanan(order.id);
        expect(state.orderById(order.id)!.status, Pesanan.shipped);
        expect(state.orderById(order.id)!.canCancel, isFalse);
        await state.cancelPesanan(order.id);
        expect(state.orderById(order.id)!.status, Pesanan.shipped);
        await state.advancePesanan(order.id);
        expect(state.orderById(order.id)!.status, Pesanan.done);
        expect(state.orderById(order.id)!.nextStep, isNull);
      },
    );

    test('booking is stored for the bengkel and vehicle, and finishing it logs a service', () async {
      final jaya = Place.demoPlaces.firstWhere(
        (p) => p.id == 'bengkel-jaya-motor',
      );
      final order = await state.addBooking(
        jaya,
        services: ['Ganti Oli Mesin'],
        date: t0.add(const Duration(days: 1)),
        time: '10:00',
        notes: 'Cek rem',
      );
      expect(order.kind, PesananKind.layanan);
      expect(order.status, Pesanan.waitingConfirmation);
      expect(order.placeName, 'Bengkel Jaya Motor');
      expect(order.vehicleId, state.vehicle.id);
      expect(order.title, 'Booking Bengkel Jaya Motor');
      await state.advancePesanan(order.id);
      expect(state.orderById(order.id)!.status, Pesanan.confirmed);
      await state.advancePesanan(order.id);
      expect(state.logs.first['title'], 'Servis di Bengkel Jaya Motor');
      await state.cancelPesanan(order.id);
      expect(
        state.orderById(order.id)!.status,
        Pesanan.done,
        reason: 'finished orders cannot be cancelled',
      );
    });
  });

  group('obd simulation', () {
    test('connect shows demo codes tied to a simulated adapter; clear and disconnect', () async {
      await state.connectObd(adapter: 'ELM327 Mini (simulasi)');
      expect(state.obdConnected, isTrue);
      expect(state.obdAdapter, contains('simulasi'));
      expect(state.obdCodes, ['P0301', 'P0562']);
      await state.clearObdCodes();
      expect(state.obdCodes, isEmpty);
      await state.disconnectObd();
      expect(state.obdConnected, isFalse);
    });
  });

  group('persistence across restart', () {
    test('everything survives restoring from the repository', () async {
      await state.updateMileage(13000);
      final car = await state.addVehicle(
        const Vehicle(
          kind: VehicleKind.mobil,
          brand: 'Toyota',
          model: 'Avanza',
          plate: 'B 9',
          type: '',
          year: 2019,
          mileage: 54000,
        ),
      );
      await state.addLog({
        'type': 'bbm',
        'title': 'Pertalite',
        'amount': 50000,
        'volume': 5.5,
      });
      await state.completeMaintenance('Cek Busi');
      await state.add(state.products.first);
      await state.checkout();
      await state.add(state.products[1]);
      final jaya = Place.demoPlaces.first;
      await state.addBooking(
        jaya,
        services: ['Ganti Oli Mesin'],
        date: t0,
        time: '09:00',
      );
      await state.saveTrip(
        startedAt: t0,
        endedAt: t0,
        distanceMeters: 5000,
        durationSeconds: 600,
      );
      await state.connectObd();
      await state.setAddress('Jl. Mawar 1');
      await state.setActiveVehicle(car.id);

      final restored = await open(repo);
      expect(restored.vehicles.map((v) => v.plate), ['B 1234 XYZ', 'B 9']);
      expect(restored.vehicle.id, car.id);
      expect(restored.vehicles.first.mileage, 13000);
      expect(
        restored.logs.map((l) => l['title']),
        containsAll(['Pertalite', 'Cek Busi']),
      );
      expect(restored.records.single.task, 'Cek Busi');
      expect(restored.orders, hasLength(2));
      expect(
        restored.orders.map((o) => o.kind),
        containsAll([PesananKind.sparepart, PesananKind.layanan]),
      );
      expect(restored.cart, hasLength(1));
      expect(restored.trips.single.distanceMeters, 5000);
      expect(restored.obdConnected, isTrue);
      expect(restored.address, 'Jl. Mawar 1');
    });

    test('a pre-v2 saved blob is migrated', () async {
      await repo.saveState({
        'mileage': 13000,
        'vehicle': {
          'brand': 'Honda',
          'model': 'Beat Deluxe',
          'plate': 'B 5678 XYZ',
          'type': 'CBS',
          'year': 2021,
          'mileage': 13000,
        },
        'obdConnected': true,
        'cart': ['oli-mesin-honda-ahm-spx2'],
        'orders': [
          '#SP12345 • 2x Oli Mesin Honda AHM SPX2 • Menunggu pembayaran • Rp 130.000 • 1/1/2026',
          '#SV999 • Booking X • Menunggu konfirmasi • 1/1/2026',
        ],
        'logs': [
          {'type': 'bbm', 'title': 'Lama', 'amount': 1},
        ],
        'completedMaintenance': ['Ganti Oli Mesin'],
      });
      final restored = await open(repo);
      expect(restored.vehicle.model, 'Beat Deluxe');
      expect(restored.vehicle.mileage, 13000);
      expect(restored.logs.single['vehicleId'], restored.vehicle.id);
      expect(restored.logs.single['id'], isNotNull);
      expect(restored.orders.map((o) => o.kind), [
        PesananKind.sparepart,
        PesananKind.layanan,
      ]);
      expect(restored.orders.first.status, Pesanan.waitingPayment);
      expect(restored.records.single.task, 'Ganti Oli Mesin');
      expect(restored.obdConnected, isTrue);
      expect(restored.cart, hasLength(1));
    });

    test('unreadable storage reports a load error instead of crashing; reset recovers', () async {
      final broken = _BrokenRepository();
      final s = OtoKuState(repository: broken);
      await s.restore();
      expect(s.initialized, isTrue);
      expect(s.loadError, isNotNull);
      broken.broken = false;
      await s.resetLocalData();
      expect(s.loadError, isNull);
      expect(s.vehicle.brand, 'Honda');
    });

    test(
      'a failing write is surfaced as saveError and clears on success',
      () async {
        final flaky = _BrokenRepository()
          ..broken = false
          ..failSave = true;
        final s = OtoKuState(repository: flaky);
        await s.restore();
        await s.updateMileage(13000);
        expect(s.saveError, isNotNull);
        flaky.failSave = false;
        await s.updateMileage(13100);
        expect(s.saveError, isNull);
      },
    );
  });
}

class _BrokenRepository extends MemoryOtoKuRepository {
  bool broken = true, failSave = false;
  @override
  Future<Map<String, dynamic>?> loadState() async =>
      broken ? throw const FormatException('bad data') : super.loadState();
  @override
  Future<void> saveState(Map<String, dynamic> state) async =>
      failSave ? throw StateError('disk full') : super.saveState(state);
}
