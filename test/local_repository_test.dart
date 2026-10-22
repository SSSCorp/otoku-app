import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:otoku/data/oto_ku_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory directory;
  late SqliteOtoKuRepository repository;

  setUp(() async {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    SharedPreferences.setMockInitialValues({});
    directory = await Directory.systemTemp.createTemp('otoku-repository-');
    repository = await SqliteOtoKuRepository.open(
      databasePath: '${directory.path}/otoku_test.db',
    );
  });

  tearDown(() async {
    await repository.close();
    await directory.delete(recursive: true);
  });

  test(
    'saved local app data can be restored after reopening storage',
    () async {
      await repository.saveState({
        'mileage': 12800,
        'logs': [
          {'type': 'fuel', 'amount': 50000},
        ],
        'cart': ['oil-spx2'],
      });
      await repository.close();

      repository = await SqliteOtoKuRepository.open(
        databasePath: '${directory.path}/otoku_test.db',
      );

      expect(await repository.loadState(), {
        'mileage': 12800,
        'logs': [
          {'type': 'fuel', 'amount': 50000},
        ],
        'cart': ['oil-spx2'],
      });
    },
  );

  test('onboarding completion is remembered as a small preference', () async {
    expect(await repository.hasCompletedOnboarding(), isFalse);
    await repository.completeOnboarding();
    expect(await repository.hasCompletedOnboarding(), isTrue);
  });
}
