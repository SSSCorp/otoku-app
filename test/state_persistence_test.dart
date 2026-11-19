import 'package:flutter_test/flutter_test.dart';
import 'package:otoku/main.dart';
import 'package:otoku/data/oto_ku_repository.dart';

void main() {
  test(
    'manual mileage and cart survive restoring the local app state',
    () async {
      final repository = MemoryOtoKuRepository(onboardingComplete: true);
      final state = OtoKuState(repository: repository);
      await state.restore();

      await state.updateMileage(13000);
      await state.updateVehicle(
        Vehicle(
          brand: 'Honda',
          model: 'Beat Deluxe',
          plate: 'B 5678 XYZ',
          type: 'CBS',
          year: 2021,
          mileage: 13000,
        ),
      );
      await state.add(state.products.first);
      await state.add(state.products.first);
      await state.completeMaintenance('Ganti Oli Mesin');

      final restored = OtoKuState(repository: repository);
      await restored.restore();

      expect(restored.vehicle.mileage, 13000);
      expect(restored.vehicle.model, 'Beat Deluxe');
      expect(restored.cart, hasLength(2));
      expect(restored.quantityOf(restored.products.first), 2);
      expect(restored.completedMaintenance, contains('Ganti Oli Mesin'));
    },
  );

  test('care goals roll over to the next interval once passed', () {
    final oil = careTasks.firstWhere((task) => task.title == 'Ganti Oli Mesin');

    expect(nextCareDueKm(task: oil, currentKm: 13000), 14000);
    expect(nextCareDueKm(task: oil, currentKm: 14000), 18000);
    expect(nextCareDueKm(task: oil, currentKm: 15999), 18000);
    expect(nextCareDueKm(task: oil, currentKm: 18000), 22000);
    expect(nextCareDueKm(task: oil, currentKm: 15000, doneAtKm: 15500), 19500);
  });

  test(
    'completing a care goal records the odometer for the next interval',
    () async {
      final repository = MemoryOtoKuRepository(onboardingComplete: true);
      final state = OtoKuState(repository: repository);
      await state.restore();

      await state.updateMileage(14200);
      await state.completeMaintenance('Ganti Oli Mesin');

      expect(state.maintenanceDoneAt['Ganti Oli Mesin'], 14200);

      final oil = careTasks.firstWhere(
        (task) => task.title == 'Ganti Oli Mesin',
      );
      expect(
        nextCareDueKm(
          task: oil,
          currentKm: state.vehicle.mileage,
          doneAtKm: state.maintenanceDoneAt[oil.title],
        ),
        18200,
      );
    },
  );
}
