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
}
