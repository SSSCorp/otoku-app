import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:latlong2/latlong.dart';
import 'package:otoku/core/app_config.dart';
import 'package:otoku/services/location_service.dart';
import 'package:otoku/services/routing_service.dart';
import 'package:otoku/state/location_controller.dart';

import 'support/fakes.dart';

void main() {
  group('AppConfig', () {
    test('defaults to OSM with no key', () {
      const config = AppConfig();
      expect(config.effectiveProvider, MapProvider.osm);
      expect(config.googleFellBack, isFalse);
    });
    test('Google needs a key; without it falls back to OSM', () {
      const noKey = AppConfig(requestedProvider: MapProvider.google);
      expect(noKey.effectiveProvider, MapProvider.osm);
      expect(noKey.googleFellBack, isTrue);
      const blank = AppConfig(
        requestedProvider: MapProvider.google,
        googleMapsApiKey: '  ',
      );
      expect(blank.effectiveProvider, MapProvider.osm);
      const withKey = AppConfig(
        requestedProvider: MapProvider.google,
        googleMapsApiKey: 'abc',
      );
      expect(withKey.effectiveProvider, MapProvider.google);
      expect(withKey.googleFellBack, isFalse);
    });
    test('provider parsing is forgiving', () {
      expect(AppConfig.parseProvider('Google'), MapProvider.google);
      expect(AppConfig.parseProvider('osm'), MapProvider.osm);
      expect(AppConfig.parseProvider(''), MapProvider.osm);
      expect(AppConfig.parseProvider('mapbox'), MapProvider.osm);
    });
    test('fromEnvironment works with no dart-defines (fresh clone)', () {
      final config = AppConfig.fromEnvironment();
      expect(config.effectiveProvider, MapProvider.osm);
      expect(config.googleMapsApiKey, isEmpty);
    });
  });

  group('OSRM routing', () {
    final body = jsonEncode({
      'code': 'Ok',
      'routes': [
        {
          'distance': 3412.6,
          'duration': 560.4,
          'geometry': {
            'coordinates': [
              [106.995, -6.206],
              [106.99, -6.2051],
              [106.991, -6.2051],
            ],
          },
        },
      ],
    });

    test('parses distance, ETA and polyline (lng/lat order)', () {
      final route = OsrmRoutingService.parse(body);
      expect(route.distanceMeters, closeTo(3412.6, .01));
      expect(route.duration, const Duration(seconds: 560));
      expect(route.points.first, const LatLng(-6.206, 106.995));
      expect(route.points, hasLength(3));
    });

    test('requests lon,lat pairs from the OSRM endpoint', () async {
      Uri? requested;
      final service = OsrmRoutingService(
        client: MockClient((request) async {
          requested = request.url;
          return http.Response(body, 200);
        }),
      );
      final route = await service.route(bekasi, const LatLng(-6.2051, 106.991));
      expect(
        requested!.path,
        contains('/route/v1/driving/106.995,-6.206;106.991,-6.2051'),
      );
      expect(requested!.queryParameters['overview'], 'full');
      expect(route.points, isNotEmpty);
    });

    test('maps failures to Indonesian messages', () async {
      Future<RoutingException> failWith(http.Client client) async {
        try {
          await OsrmRoutingService(client: client).route(bekasi, bekasi);
        } on RoutingException catch (e) {
          return e;
        }
        throw StateError('expected failure');
      }

      final offline = await failWith(
        MockClient((_) async => throw http.ClientException('no network')),
      );
      expect(offline.failure, RoutingFailure.offline);
      expect(offline.message, contains('koneksi'));
      expect(
        (await failWith(MockClient((_) async => http.Response('', 503))))
            .failure,
        RoutingFailure.server,
      );
      expect(
        (await failWith(
          MockClient(
            (_) async => http.Response('{"code":"NoRoute","routes":[]}', 200),
          ),
        )).failure,
        RoutingFailure.noRoute,
      );
      expect(
        (await failWith(
          MockClient((_) async => http.Response('not json', 200)),
        )).failure,
        RoutingFailure.server,
      );
    });
  });

  group('LocationController', () {
    test('ready: publishes the first fix and live updates', () async {
      final service = FakeLocationService(fix: fixAt(bekasi));
      final c = LocationController(service);
      await c.refresh();
      expect(c.isReady, isTrue);
      expect(c.position, bekasi);
      expect(c.problemMessage, isNull);
      service.emit(const LatLng(-6.21, 106.99));
      await Future<void>.delayed(Duration.zero);
      expect(c.position, const LatLng(-6.21, 106.99));
      c.dispose();
    });

    test(
      'each problem state has a clear Indonesian message and no stream',
      () async {
        final expectations = {
          LocationAccess.denied: 'Izin lokasi ditolak',
          LocationAccess.deniedForever: 'diblokir',
          LocationAccess.serviceOff: 'GPS',
          LocationAccess.error: 'belum bisa ditentukan',
        };
        for (final entry in expectations.entries) {
          final c = LocationController(FakeLocationService(access: entry.key));
          await c.refresh();
          expect(c.isReady, isFalse, reason: '${entry.key}');
          expect(c.isStreaming, isFalse);
          expect(c.problemMessage, contains(entry.value));
          c.dispose();
        }
      },
    );

    test('request upgrades denied to ready when the user allows', () async {
      final service = FakeLocationService(
        access: LocationAccess.denied,
        afterRequest: LocationAccess.ready,
        fix: fixAt(bekasi),
      );
      final c = LocationController(service);
      await c.refresh();
      expect(c.access, LocationAccess.denied);
      await c.request();
      expect(c.isReady, isTrue);
      expect(c.position, bekasi);
      expect(service.requests, 1);
      c.dispose();
    });
  });
}
