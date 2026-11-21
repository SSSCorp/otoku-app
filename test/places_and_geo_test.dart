import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:otoku/core/geo.dart';
import 'package:otoku/core/places_query.dart';
import 'package:otoku/models/place.dart';
import 'package:otoku/state/oto_ku_state.dart';

import 'support/fakes.dart';

void main() {
  group('distance', () {
    test('haversine matches a known distance (Jakarta - Bandung ≈ 116 km)', () {
      final d = distanceMeters(
        const LatLng(-6.2088, 106.8456),
        const LatLng(-6.9175, 107.6191),
      );
      expect(d / 1000, closeTo(116, 3));
    });

    test('zero distance for the same point', () {
      expect(distanceMeters(bekasi, bekasi), 0);
    });

    test('formats metres, kilometres and durations in Indonesian style', () {
      expect(formatDistance(850), '850 m');
      expect(formatDistance(2140), '2,1 km');
      expect(formatDistance(150000), '150 km');
      expect(formatDuration(const Duration(minutes: 9, seconds: 20)), '9 mnt');
      expect(formatDuration(const Duration(minutes: 75)), '1 jam 15 mnt');
      expect(
        formatClockDuration(const Duration(minutes: 3, seconds: 7)),
        '00:03:07',
      );
    });
  });

  group('queryPlaces', () {
    const places = Place.demoPlaces;

    test('sorts by distance from the user, nearest first', () {
      final results = queryPlaces(places, origin: bekasi);
      final distances = results.map((r) => r.distanceMeters!).toList();
      expect(distances, [...distances]..sort());
      expect(
        results.first.distanceMeters,
        lessThan(results.last.distanceMeters!),
      );
    });

    test('without a position distances are null and names sort A-Z', () {
      final results = queryPlaces(places);
      expect(results.every((r) => r.distanceMeters == null), isTrue);
      final names = results.map((r) => r.place.name.toLowerCase()).toList();
      expect(names, [...names]..sort());
    });

    test('filters by category', () {
      expect(
        queryPlaces(
          places,
          filter: PlaceFilter.spbu,
        ).every((r) => r.place.category == PlaceCategory.spbu),
        isTrue,
      );
      expect(queryPlaces(places, filter: PlaceFilter.minimarket), hasLength(4));
      expect(
        queryPlaces(
          places,
          filter: PlaceFilter.bengkel,
        ).every((r) => r.place.isBengkel),
        isTrue,
      );
      final partner = queryPlaces(places, filter: PlaceFilter.bengkelPartner);
      expect(partner.map((r) => r.place.name), ['Bengkel Jaya Motor']);
      expect(
        queryPlaces(
          places,
          filter: PlaceFilter.bengkelOther,
        ).every((r) => !r.place.partner),
        isTrue,
      );
    });

    test('searches by name, case-insensitively', () {
      expect(
        queryPlaces(places, search: 'bengkel JAYA').single.place.id,
        'bengkel-jaya-motor',
      );
      expect(
        queryPlaces(
          places,
          search: '  SPBU ',
        ).every((r) => r.place.category == PlaceCategory.spbu),
        isTrue,
      );
      expect(queryPlaces(places, search: 'tidak-ada-tempat'), isEmpty);
    });

    test('search and filter combine; name sort ignores distance', () {
      final r = queryPlaces(
        places,
        origin: bekasi,
        search: 'spbu',
        filter: PlaceFilter.spbu,
        sort: PlaceSort.name,
      );
      expect(
        r.map((x) => x.place.name),
        [...r.map((x) => x.place.name)]..sort(),
      );
    });

    test('nearestPlaces returns the closest bengkel first', () {
      final near = nearestPlaces(places, bekasi, limit: 2);
      expect(near, hasLength(2));
      expect(near.every((r) => r.place.isBengkel), isTrue);
      expect(
        near.first.distanceMeters,
        lessThanOrEqualTo(near.last.distanceMeters!),
      );
    });
  });

  group('opening hours', () {
    const hours = OpeningHours(8 * 60, 17 * 60, closedWeekdays: {7});
    test('open during the day, closed at night and on Sunday', () {
      expect(hours.isOpenAt(DateTime(2026, 11, 18, 10)), isTrue); // Wednesday
      expect(hours.isOpenAt(DateTime(2026, 11, 18, 18)), isFalse);
      expect(hours.isOpenAt(DateTime(2026, 11, 22, 10)), isFalse); // Sunday
      expect(
        hours.statusLabel(DateTime(2026, 11, 18, 10)),
        'Buka sekarang · tutup 17:00',
      );
      expect(
        hours.statusLabel(DateTime(2026, 11, 18, 6)),
        'Tutup · buka 08:00',
      );
    });
    test('24-hour places are always open', () {
      const all = OpeningHours.allDay();
      expect(all.is24h, isTrue);
      expect(all.isOpenAt(DateTime(2026, 11, 22, 3)), isTrue);
      expect(all.statusLabel(DateTime(2026, 11, 22, 3)), 'Buka 24 jam');
    });
  });

  test('bengkel offers match maintenance tasks and OBD checks', () {
    final jaya = Place.demoPlaces.firstWhere(
      (p) => p.id == 'bengkel-jaya-motor',
    );
    expect(jaya.offerForTask('Ganti Oli Mesin')?.name, 'Ganti Oli Mesin');
    expect(jaya.offerForTask('Cek Kampas Rem')?.name, contains('Rem'));
    expect(jaya.offerForTask('Pemeriksaan Kode OBD')?.id, 'diag');
    expect(jaya.offerForTask('Cek Busi')?.id, 'tune');
  });
}
