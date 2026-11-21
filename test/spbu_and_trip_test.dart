import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:otoku/data/oto_ku_repository.dart';
import 'package:otoku/models/place.dart';
import 'package:otoku/services/location_service.dart';
import 'package:otoku/state/location_controller.dart';
import 'package:otoku/state/oto_ku_state.dart';
import 'package:otoku/state/spbu_visit_detector.dart';
import 'package:otoku/state/spbu_visit_monitor.dart';
import 'package:otoku/state/trip_tracker.dart';

import 'support/fakes.dart';

final spbu = Place.demoPlaces.firstWhere(
  (p) => p.category == PlaceCategory.spbu,
);
final t0 = DateTime(2026, 11, 19, 10);

void main() {
  group('SpbuVisitDetector', () {
    SpbuVisitDetector make() => SpbuVisitDetector(places: Place.demoPlaces);

    test('prompts after the user dwells at an SPBU', () {
      final d = make();
      expect(d.evaluate(spbu.position, t0), isNull);
      expect(
        d.evaluate(spbu.position, t0.add(const Duration(seconds: 20))),
        isNull,
      );
      expect(
        d.evaluate(spbu.position, t0.add(const Duration(seconds: 31)))?.id,
        spbu.id,
      );
    });

    test('does not prompt again within the cooldown, then does after it', () {
      final d = make();
      d.evaluate(spbu.position, t0);
      expect(
        d.evaluate(spbu.position, t0.add(const Duration(seconds: 40))),
        isNotNull,
      );
      expect(
        d.evaluate(spbu.position, t0.add(const Duration(minutes: 5))),
        isNull,
      );
      expect(
        d.evaluate(
          spbu.position,
          t0.add(const Duration(minutes: 5, seconds: 40)),
        ),
        isNull,
      );
      // Still parked there once the cooldown has passed: offered again.
      expect(
        d.evaluate(spbu.position, t0.add(const Duration(hours: 2))),
        isNotNull,
      );
    });

    test('ignores fast drive-bys, far positions and poor accuracy', () {
      final d = make();
      d.evaluate(spbu.position, t0, speed: 12);
      expect(
        d.evaluate(
          spbu.position,
          t0.add(const Duration(minutes: 2)),
          speed: 12,
        ),
        isNull,
      );
      expect(
        d.evaluate(bekasi, t0),
        isNull,
      ); // ~> 80 m away from every SPBU? bekasi is far enough
      d.evaluate(const LatLng(-6.0, 106.0), t0);
      expect(
        d.evaluate(
          const LatLng(-6.0, 106.0),
          t0.add(const Duration(minutes: 2)),
        ),
        isNull,
      );
      d.evaluate(spbu.position, t0, accuracy: 400);
      expect(
        d.evaluate(
          spbu.position,
          t0.add(const Duration(minutes: 2)),
          accuracy: 400,
        ),
        isNull,
      );
    });

    test('leaving resets the dwell timer', () {
      final d = make();
      d.evaluate(spbu.position, t0);
      d.evaluate(
        const LatLng(-6.0, 106.0),
        t0.add(const Duration(seconds: 20)),
      );
      expect(
        d.evaluate(spbu.position, t0.add(const Duration(seconds: 40))),
        isNull,
      );
      expect(
        d.evaluate(spbu.position, t0.add(const Duration(seconds: 75))),
        isNotNull,
      );
    });
  });

  test(
    'SpbuVisitMonitor raises a pending prompt from live fixes and clears it',
    () async {
      final service = FakeLocationService(fix: fixAt(spbu.position));
      final controller = LocationController(service);
      var now = t0;
      final monitor = SpbuVisitMonitor(
        controller,
        Place.demoPlaces,
        clock: () => now,
        tick: const Duration(milliseconds: 10),
      );
      await controller.refresh();
      monitor.start();
      service.emit(spbu.position, time: now);
      await Future<void>.delayed(Duration.zero);
      expect(monitor.pending, isNull);
      now = now.add(const Duration(seconds: 45));
      service.emit(spbu.position, time: now);
      await Future<void>.delayed(const Duration(milliseconds: 30));
      expect(monitor.pending?.id, spbu.id);
      monitor.dismiss();
      expect(monitor.pending, isNull);
      monitor.dispose();
      controller.dispose();
    },
  );

  group('TripTracker', () {
    late FakeLocationService service;
    late LocationController controller;
    late TripTracker tracker;
    var now = t0;

    setUp(() async {
      now = t0;
      service = FakeLocationService(fix: fixAt(bekasi, time: t0));
      controller = LocationController(service);
      await controller.refresh();
      tracker = TripTracker(controller, clock: () => now);
    });

    tearDown(() {
      tracker.dispose();
      controller.dispose();
    });

    test('accumulates distance and duration between accepted fixes', () async {
      expect(await tracker.start(), TripStart.started);
      // ~1.1 km due north in two steps.
      tracker.onFix(
        fixAt(
          LatLng(bekasi.latitude + .005, bekasi.longitude),
          time: t0.add(const Duration(minutes: 1)),
        ),
      );
      tracker.onFix(
        fixAt(
          LatLng(bekasi.latitude + .010, bekasi.longitude),
          time: t0.add(const Duration(minutes: 2)),
        ),
      );
      now = t0.add(const Duration(minutes: 2));
      expect(tracker.distanceMeters, closeTo(1112, 30));
      expect(tracker.elapsed, const Duration(minutes: 2));
      final summary = tracker.stop()!;
      expect(summary.distanceMeters, closeTo(1112, 30));
      expect(summary.duration, const Duration(minutes: 2));
      expect(tracker.recording, isFalse);
    });

    test('ignores jitter, inaccurate fixes and impossible jumps', () async {
      await tracker.start();
      tracker.onFix(
        fixAt(
          LatLng(bekasi.latitude + .00001, bekasi.longitude),
          time: t0.add(const Duration(seconds: 5)),
        ),
      ); // ~1 m
      tracker.onFix(
        fixAt(
          LatLng(bekasi.latitude + .01, bekasi.longitude),
          time: t0.add(const Duration(seconds: 6)),
          accuracy: 200,
        ),
      );
      tracker.onFix(
        fixAt(
          LatLng(bekasi.latitude + 1, bekasi.longitude),
          time: t0.add(const Duration(seconds: 7)),
        ),
      ); // 111 km in 7 s
      expect(tracker.distanceMeters, 0);
      expect(tracker.acceptedFixes, 0);
    });

    test('cannot start without location, and reports it', () async {
      final denied = FakeLocationService(access: LocationAccess.denied);
      final c = LocationController(denied);
      final t = TripTracker(c);
      expect(await t.start(), TripStart.noLocation);
      expect(denied.requests, 1);
      expect(t.recording, isFalse);
      t.dispose();
      c.dispose();
    });

    test('fixes before start are ignored; second start is a no-op', () async {
      tracker.onFix(fixAt(LatLng(bekasi.latitude + .01, bekasi.longitude)));
      expect(tracker.distanceMeters, 0);
      await tracker.start();
      expect(await tracker.start(), TripStart.alreadyRecording);
      expect(tracker.stop(), isNotNull);
      expect(tracker.stop(), isNull);
    });
  });

  group('Trip → mileage log', () {
    late OtoKuState state;
    setUp(() async {
      state = OtoKuState(repository: MemoryOtoKuRepository(), clock: () => t0);
      await state.restore();
    });

    test(
      'adds the rounded trip distance to the odometer and logs it once',
      () async {
        final trip = await state.saveTrip(
          startedAt: t0,
          endedAt: t0.add(const Duration(minutes: 20)),
          distanceMeters: 7400,
          durationSeconds: 1200,
        );
        expect(await state.addTripToMileage(trip.id), 12450 + 7);
        expect(state.vehicle.mileage, 12457);
        expect(state.logs.first['source'], 'trip');
        expect(state.activeTrips.single.addedToMileage, isTrue);
        expect(() => state.addTripToMileage(trip.id), throwsStateError);
      },
    );

    test('trips under 1 km are not added', () async {
      final trip = await state.saveTrip(
        startedAt: t0,
        endedAt: t0,
        distanceMeters: 300,
        durationSeconds: 60,
      );
      expect(() => state.addTripToMileage(trip.id), throwsArgumentError);
      expect(state.vehicle.mileage, 12450);
    });

    test('mileage decreases are rejected', () async {
      expect(() => state.updateMileage(12000), throwsArgumentError);
      expect(state.vehicle.mileage, 12450);
    });
  });
}
