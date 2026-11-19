import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:otoku/core/app_config.dart';
import 'package:otoku/data/oto_ku_repository.dart';
import 'package:otoku/models/place.dart';
import 'package:otoku/services/location_service.dart';
import 'package:otoku/services/routing_service.dart';

import 'support/fakes.dart';
import 'support/harness.dart';

final jaya = Place.demoPlaces.firstWhere((p) => p.id == 'bengkel-jaya-motor');
final spbu = Place.demoPlaces.firstWhere((p) => p.id == 'spbu-pertamina-demo');

Future<void> openPeta(WidgetTester tester) => openTab(tester, 'Peta');

/// Filter chips sit in a horizontal scroller; bring one into view first.
Future<void> tapChip(WidgetTester tester, String label) async {
  final chip = find.widgetWithText(ChoiceChip, label);
  await tester.ensureVisible(chip);
  await tester.pumpAndSettle();
  await tester.tap(chip);
  await tester.pumpAndSettle();
}

void main() {
  group('Peta map', () {
    testWidgets(
      'shows a real map with attribution, markers and the user position',
      (tester) async {
        await launch(tester);
        await openPeta(tester);
        expect(find.byType(FlutterMap), findsOneWidget);
        expect(find.text(AppConfig.osmAttribution), findsOneWidget);
        expect(find.byKey(const ValueKey('user-position')), findsOneWidget);
        expect(find.textContaining('Posisimu aktif'), findsOneWidget);
        expect(find.byKey(const ValueKey('location-problem')), findsNothing);
      },
    );

    testWidgets('lists places with distance from the user, nearest first', (
      tester,
    ) async {
      await launch(tester);
      await openPeta(tester);
      expect(find.text('9 tempat'), findsOneWidget);
      final tiles = find
          .byType(Text)
          .evaluate()
          .map((e) => (e.widget as Text).data ?? '')
          .where(
            (t) =>
                t.contains(' · ') &&
                (t.startsWith('Bengkel ·') ||
                    t.startsWith('SPBU ·') ||
                    t.startsWith('Minimarket ·')),
          )
          .toList();
      expect(tiles, isNotEmpty);
      expect(
        tiles.first,
        matches(RegExp(r'· \d+ m$')),
        reason: 'nearest place is under 1 km: ${tiles.first}',
      );
      expect(tiles.any((t) => t.contains('Jarak belum tersedia')), isFalse);
    });

    testWidgets('filters by category and searches by name', (tester) async {
      await launch(tester);
      await openPeta(tester);
      await tapChip(tester, 'SPBU');
      await tester.pumpAndSettle();
      expect(find.text('3 tempat'), findsOneWidget);
      expect(find.text('SPBU Pertamina Demo'), findsOneWidget);
      expect(find.text('Bengkel Jaya Motor'), findsNothing);

      await tapChip(tester, 'Semua');
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'jaya');
      await tester.pumpAndSettle();
      expect(find.text('1 tempat'), findsOneWidget);
      expect(find.text('Bengkel Jaya Motor'), findsOneWidget);

      await tester.enterText(find.byType(TextField), 'zzz');
      await tester.pumpAndSettle();
      expect(find.text('Tempat tidak ditemukan'), findsOneWidget);
      await tester.tap(find.text('Reset pencarian'));
      await tester.pumpAndSettle();
      expect(find.text('9 tempat'), findsOneWidget);
    });

    testWidgets(
      'sorting by name works and the distance sort needs a location',
      (tester) async {
        final services = testServices(
          location: FakeLocationService(access: LocationAccess.denied),
        );
        await launch(tester, services: services);
        await openPeta(tester);
        expect(
          find.text('Urutan jarak aktif setelah lokasi tersedia.'),
          findsOneWidget,
        );
        await tester.tap(find.text('Nama A–Z'));
        await tester.pumpAndSettle();
        expect(
          find.text('Jarak belum tersedia'),
          findsNothing,
          reason: 'tiles show it inside a longer string',
        );
      },
    );

    testWidgets(
      'selecting a marker keeps selection through filter changes and map movement',
      (tester) async {
        await launch(tester);
        await openPeta(tester);
        await tapChip(tester, 'SPBU');
        await tester.pumpAndSettle();
        await tester.tap(
          find.bySemanticsLabel('Penanda ${spbu.name}'),
          warnIfMissed: false,
        );
        await tester.pumpAndSettle();
        expect(find.byKey(const ValueKey('selected-place')), findsOneWidget);
        expect(
          find.byKey(const ValueKey('selected-${'spbu-pertamina-demo'}')),
          findsOneWidget,
        );

        // Pan and zoom the map: the selection is kept.
        await tester.drag(find.byType(FlutterMap), const Offset(-80, 40));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const ValueKey('fit-places')));
        await tester.pumpAndSettle();
        expect(find.byKey(const ValueKey('selected-place')), findsOneWidget);

        // Switching to a filter that still contains it keeps it; one that hides it clears it.
        await tapChip(tester, 'Semua');
        await tester.pumpAndSettle();
        expect(find.byKey(const ValueKey('selected-place')), findsOneWidget);
        await tapChip(tester, 'Minimarket');
        await tester.pumpAndSettle();
        expect(find.byKey(const ValueKey('selected-place')), findsNothing);
      },
    );

    testWidgets(
      'Google provider without a key falls back to OSM with a notice',
      (tester) async {
        final services = testServices(
          config: const AppConfig(requestedProvider: MapProvider.google),
        );
        await launch(tester, services: services);
        await openPeta(tester);
        expect(find.byType(FlutterMap), findsOneWidget);
        expect(find.byKey(const ValueKey('google-fallback')), findsOneWidget);
      },
    );

    testWidgets(
      'a position far from the demo area is explained, distances stay real',
      (tester) async {
        final far = FakeLocationService(
          fix: fixAt(const LatLng(-7.25, 112.75)),
        ); // Surabaya
        await launch(tester, services: testServices(location: far));
        await openPeta(tester);
        expect(find.byKey(const ValueKey('far-from-demo')), findsOneWidget);
        expect(
          find.byWidgetPredicate(
            (w) => w is Text && RegExp(r'· 6\d\d km$').hasMatch(w.data ?? ''),
          ),
          findsWidgets,
        );
      },
    );
  });

  group('location states', () {
    testWidgets(
      'denied: clear message, Izinkan lokasi asks again and recovers',
      (tester) async {
        final service = FakeLocationService(
          access: LocationAccess.denied,
          afterRequest: LocationAccess.denied,
          fix: fixAt(bekasi),
        );
        await launch(tester, services: testServices(location: service));
        await openPeta(tester);
        expect(
          service.requests,
          greaterThanOrEqualTo(1),
          reason: 'the Peta tab requests permission',
        );
        expect(find.textContaining('Izin lokasi ditolak'), findsOneWidget);
        service
          ..afterRequest = LocationAccess.ready
          ..access = LocationAccess.denied;
        await tester.tap(find.text('Izinkan lokasi'));
        await tester.pumpAndSettle();
        expect(find.byKey(const ValueKey('location-problem')), findsNothing);
        expect(find.byKey(const ValueKey('user-position')), findsOneWidget);
      },
    );

    testWidgets('permanently denied: offers system settings', (tester) async {
      final service = FakeLocationService(access: LocationAccess.deniedForever);
      await launch(tester, services: testServices(location: service));
      await openPeta(tester);
      expect(find.textContaining('Izin lokasi diblokir'), findsOneWidget);
      await tester.tap(find.text('Buka Pengaturan'));
      await tester.pumpAndSettle();
      expect(service.appSettingsOpened, 1);
    });

    testWidgets('location services off: offers GPS settings', (tester) async {
      final service = FakeLocationService(access: LocationAccess.serviceOff);
      await launch(tester, services: testServices(location: service));
      await openPeta(tester);
      expect(find.textContaining('Layanan lokasi (GPS)'), findsOneWidget);
      await tester.tap(find.text('Nyalakan GPS'));
      await tester.pumpAndSettle();
      expect(service.locationSettingsOpened, 1);
    });

    testWidgets(
      'offline: notice appears, list and distances still work, retry rechecks',
      (tester) async {
        final network = FakeNetwork(false);
        await launch(tester, services: testServices(network: network));
        await openPeta(tester);
        expect(find.byKey(const ValueKey('offline-notice')), findsOneWidget);
        expect(find.text('9 tempat'), findsOneWidget);
        network.online = true;
        await tester.tap(find.text('Coba lagi'));
        await tester.pumpAndSettle();
        expect(find.byKey(const ValueKey('offline-notice')), findsNothing);
      },
    );

    testWidgets(
      'recenter without a position asks for permission and explains failure',
      (tester) async {
        final service = FakeLocationService(
          access: LocationAccess.denied,
          afterRequest: LocationAccess.deniedForever,
        );
        await launch(tester, services: testServices(location: service));
        await openPeta(tester);
        final before = service.requests;
        await tester.tap(find.byKey(const ValueKey('recenter')));
        await tester.pumpAndSettle();
        expect(service.requests, greaterThan(before));
        expect(find.textContaining('Izin lokasi diblokir'), findsWidgets);
      },
    );

    testWidgets('recenter with a position works without errors', (
      tester,
    ) async {
      await launch(tester);
      await openPeta(tester);
      await tester.tap(find.byKey(const ValueKey('recenter')));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  });

  group('place detail, route and booking', () {
    Future<void> openJayaDetail(WidgetTester tester) async {
      await openPeta(tester);
      await tapChip(tester, 'Bengkel partner');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Bengkel Jaya Motor'));
      await tester.pumpAndSettle();
    }

    testWidgets('detail shows distance, hours and services', (tester) async {
      await launch(tester);
      await openJayaDetail(tester);
      expect(find.text('Detail Tempat'), findsOneWidget);
      final distance = tester
          .widget<Text>(find.byKey(const ValueKey('place-distance')))
          .data!;
      expect(distance, matches(RegExp(r'^Bengkel · \d+ m$')));
      expect(find.text('Jam operasional'), findsOneWidget);
      expect(find.textContaining('08:00–17:00'), findsOneWidget);
      expect(find.text('Servis Rutin'), findsOneWidget);
      expect(find.text('Ganti Oli Mesin'), findsOneWidget);
    });

    testWidgets('Rute & ETA shows distance and duration from OSRM', (
      tester,
    ) async {
      final routing = FakeRoutingService();
      await launch(tester, services: testServices(routing: routing));
      await openJayaDetail(tester);
      await tester.tap(find.text('Rute & ETA'));
      await tester.pumpAndSettle();
      expect(find.textContaining('ETA 9 mnt · 3,4 km'), findsOneWidget);
      expect(routing.calls.single.$1, bekasi);
      expect(routing.calls.single.$2, jaya.position);
    });

    testWidgets(
      'route failures are explained and the maps hand-off still works',
      (tester) async {
        final launcher = FakeLauncher();
        final services = testServices(
          routing: FakeRoutingService(failure: RoutingFailure.offline),
          launcher: launcher,
        );
        await launch(tester, services: services);
        await openJayaDetail(tester);
        await tester.tap(find.text('Rute & ETA'));
        await tester.pumpAndSettle();
        expect(find.byKey(const ValueKey('route-error')), findsOneWidget);
        expect(find.textContaining('koneksi'), findsOneWidget);
        await tester.tap(find.text('Buka di Maps'));
        await tester.pumpAndSettle();
        expect(launcher.opened.single.$1, jaya.position);
      },
    );

    testWidgets('route from the map card draws on the selected place only', (
      tester,
    ) async {
      final routing = FakeRoutingService();
      await launch(tester, services: testServices(routing: routing));
      await openPeta(tester);
      await tapChip(tester, 'Bengkel partner');
      await tester.pumpAndSettle();
      await tester.tap(
        find.bySemanticsLabel('Penanda Bengkel Jaya Motor'),
        warnIfMissed: false,
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.descendant(
          of: find.byKey(const ValueKey('selected-place')),
          matching: find.text('Rute & ETA'),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('route-result')), findsOneWidget);
      expect(find.byType(PolylineLayer), findsOneWidget);
    });

    testWidgets(
      'Booking from place detail is pre-filled and saved as a Pesanan',
      (tester) async {
        final repo = MemoryOtoKuRepository(onboardingComplete: true);
        await launch(tester, repository: repo);
        await openJayaDetail(tester);
        await tester.tap(find.text('Booking Layanan'));
        await tester.pumpAndSettle();
        expect(find.text('Bengkel Jaya Motor'), findsWidgets);
        expect(
          find.textContaining('Honda Beat 2021 · B 1234 XYZ'),
          findsOneWidget,
        );
        await tester.tap(find.text('Lanjutkan'));
        await tester.pumpAndSettle();
        expect(find.text('Menunggu konfirmasi bengkel'), findsOneWidget);
        expect(find.text('Booking Bengkel Jaya Motor'), findsOneWidget);
        await tester.tap(find.text('Lihat Pesanan'));
        await tester.pumpAndSettle();
        expect(find.text('Pesanan Saya'), findsOneWidget);
        expect(find.text('Menunggu konfirmasi'), findsOneWidget);
        expect(find.text('Booking Bengkel Jaya Motor'), findsOneWidget);
        final saved = await repo.loadState();
        expect(
          (saved!['orders'] as List).single['placeId'],
          'bengkel-jaya-motor',
        );
      },
    );

    testWidgets('Booking requires at least one service', (tester) async {
      await launch(tester);
      await openJayaDetail(tester);
      await tester.tap(find.text('Booking Layanan'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('booking-oil')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Lanjutkan'));
      await tester.pumpAndSettle();
      expect(find.text('Pilih minimal satu layanan.'), findsOneWidget);
      expect(find.text('Menunggu konfirmasi bengkel'), findsNothing);
    });

    testWidgets(
      'non-partner bengkel can be booked too; SPBU and minimarket have no booking',
      (tester) async {
        await launch(tester);
        await openPeta(tester);
        await tester.tap(find.text('AutoCare Plus'));
        await tester.pumpAndSettle();
        expect(find.text('Booking Layanan'), findsOneWidget);
        await back(tester);
        await tapChip(tester, 'SPBU');
        await tester.pumpAndSettle();
        await tester.tap(find.text('SPBU Pertamina Demo'));
        await tester.pumpAndSettle();
        expect(find.text('Booking Layanan'), findsNothing);
        expect(find.text('Pertamax Turbo'), findsOneWidget);
      },
    );
  });

  group('map-linked suggestions', () {
    testWidgets(
      'an overdue maintenance item suggests the nearest bengkel with the service pre-selected',
      (tester) async {
        final repo = MemoryOtoKuRepository(onboardingComplete: true);
        await launch(tester, repository: repo);
        await reveal(tester, find.text('+ Catat'));
        await tester.tap(find.text('+ Catat'));
        await tester.pumpAndSettle();
        await tester.enterText(
          find.byKey(const ValueKey('log-value')),
          '14100',
        );
        await tester.tap(find.text('Simpan Catatan'));
        await tester.pumpAndSettle();
        await tester.drag(find.byType(Scrollable).first, const Offset(0, 1500));
        await tester.pumpAndSettle();
        expect(find.byKey(const ValueKey('nearest-bengkel')), findsOneWidget);

        await tester.ensureVisible(
          find.byKey(const ValueKey('nearest-bengkel')),
        );
        await tester.pumpAndSettle();
        final nearest = find
            .descendant(
              of: find.byKey(const ValueKey('nearest-bengkel')),
              matching: find.byType(InkWell),
            )
            .first;
        await tester.tap(nearest);
        await tester.pumpAndSettle();
        expect(find.text('Detail Tempat'), findsOneWidget);
        await tester.tap(find.text('Booking Layanan'));
        await tester.pumpAndSettle();
        expect(
          find.byIcon(Icons.check_circle),
          findsOneWidget,
          reason: 'only the oil service is pre-selected',
        );
      },
    );
  });

  group('GPS trip', () {
    final t0 = DateTime(2026, 11, 19, 10);

    Future<void> openTrip(WidgetTester tester) async {
      await openPeta(tester);
      await tester.tap(find.byKey(const ValueKey('open-trip')));
      await tester.pumpAndSettle();
    }

    testWidgets('start, drive, stop, then add the distance to the odometer', (
      tester,
    ) async {
      final service = FakeLocationService(fix: fixAt(bekasi, time: t0));
      final repo = MemoryOtoKuRepository(onboardingComplete: true);
      await launch(
        tester,
        repository: repo,
        services: testServices(location: service),
      );
      await openTrip(tester);
      expect(find.text('Belum ada trip'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('trip-start')));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('trip-stop')), findsOneWidget);

      service.emit(
        LatLng(bekasi.latitude + .01, bekasi.longitude),
        time: t0.add(const Duration(minutes: 3)),
      );
      service.emit(
        LatLng(bekasi.latitude + .02, bekasi.longitude),
        time: t0.add(const Duration(minutes: 6)),
      );
      await tester.pump(const Duration(milliseconds: 50));
      expect(find.text('2,22 km'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('trip-stop')));
      await tester.pumpAndSettle();
      expect(find.text('Trip selesai'), findsOneWidget);
      expect(find.textContaining('12.450 → 12.452 km'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('trip-add-mileage')));
      await tester.pumpAndSettle();
      expect(
        find.text('Kilometer kendaraan menjadi 12.452 km.'),
        findsOneWidget,
      );
      expect(find.text('Sudah ditambahkan ke kilometer'), findsOneWidget);
      final saved = await repo.loadState();
      expect(saved!['vehicles'][0]['mileage'], 12452);
      expect((saved['trips'] as List).single['addedToMileage'], true);
    });

    testWidgets(
      'a trip under 1 km is saved but not offered for the mileage log',
      (tester) async {
        final service = FakeLocationService(fix: fixAt(bekasi, time: t0));
        await launch(tester, services: testServices(location: service));
        await openTrip(tester);
        await tester.tap(find.byKey(const ValueKey('trip-start')));
        await tester.pumpAndSettle();
        service.emit(
          LatLng(bekasi.latitude + .002, bekasi.longitude),
          time: t0.add(const Duration(minutes: 1)),
        );
        await tester.pump();
        await tester.tap(find.byKey(const ValueKey('trip-stop')));
        await tester.pumpAndSettle();
        expect(find.textContaining('kurang dari 1 km'), findsOneWidget);
        expect(find.byKey(const ValueKey('trip-add-mileage')), findsNothing);
      },
    );

    testWidgets('cannot start without location permission', (tester) async {
      final service = FakeLocationService(access: LocationAccess.deniedForever);
      await launch(tester, services: testServices(location: service));
      await openTrip(tester);
      await tester.tap(find.byKey(const ValueKey('trip-start')));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('trip-stop')), findsNothing);
      expect(find.textContaining('Izin lokasi diblokir'), findsWidgets);
    });
  });

  group('SPBU visit → BBM prompt', () {
    testWidgets(
      'dwelling at an SPBU offers to log BBM, pre-filled, and saves it',
      (tester) async {
        final service = FakeLocationService(fix: fixAt(spbu.position));
        final repo = MemoryOtoKuRepository(onboardingComplete: true);
        await launch(
          tester,
          repository: repo,
          services: testServices(location: service, spbuDwell: Duration.zero),
        );
        await tester.pump(const Duration(milliseconds: 100));
        await tester.pumpAndSettle();
        expect(find.text('Kamu di SPBU?'), findsOneWidget);
        expect(find.textContaining('SPBU Pertamina Demo'), findsOneWidget);

        await tester.tap(find.text('Catat BBM'));
        await tester.pumpAndSettle();
        expect(find.text('Catat Aktivitas'), findsOneWidget);
        expect(
          find.widgetWithText(TextField, 'Isi BBM di SPBU Pertamina Demo'),
          findsOneWidget,
        );
        await tester.enterText(
          find.byKey(const ValueKey('log-value')),
          '30000',
        );
        await tester.tap(find.text('Simpan Catatan'));
        await tester.pumpAndSettle();
        final saved = await repo.loadState();
        final log = (saved!['logs'] as List).single;
        expect(log['type'], 'bbm');
        expect(log['title'], 'Isi BBM di SPBU Pertamina Demo');
        await tester.pump(const Duration(milliseconds: 200));
        expect(
          find.text('Kamu di SPBU?'),
          findsNothing,
          reason: 'cooldown prevents a repeat prompt',
        );
      },
    );

    testWidgets('Nanti dismisses the prompt without logging', (tester) async {
      final service = FakeLocationService(fix: fixAt(spbu.position));
      await launch(
        tester,
        services: testServices(location: service, spbuDwell: Duration.zero),
      );
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Nanti'));
      await tester.pumpAndSettle();
      expect(find.text('Kamu di SPBU?'), findsNothing);
      expect(find.text('Catat Aktivitas'), findsNothing);
    });

    testWidgets('no prompt away from SPBUs', (tester) async {
      await launch(tester, services: testServices(spbuDwell: Duration.zero));
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.text('Kamu di SPBU?'), findsNothing);
    });
  });
}
