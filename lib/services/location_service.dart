import 'dart:async';

import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

/// What the app may currently do with the device location.
enum LocationAccess {
  /// Not checked yet.
  unknown,

  /// Permission granted and location services on.
  ready,

  /// Permission denied (can be asked again).
  denied,

  /// Permission permanently denied; only system settings can change it.
  deniedForever,

  /// Device location services (GPS) are switched off.
  serviceOff,

  /// Anything else that stopped us from getting a position.
  error,
}

class UserFix {
  const UserFix({
    required this.position,
    required this.time,
    this.accuracy = 0,
    this.speed = 0,
    this.heading,
  });

  final LatLng position;
  final DateTime time;

  /// Horizontal accuracy in metres.
  final double accuracy;

  /// Speed in metres per second (0 when unknown).
  final double speed;
  final double? heading;
}

abstract interface class LocationService {
  /// Reads the current access state without prompting.
  Future<LocationAccess> checkAccess();

  /// Asks for permission if needed, then reports the access state.
  Future<LocationAccess> requestAccess();

  Future<UserFix?> currentFix();
  Stream<UserFix> fixes({int distanceFilterMeters = 10});
  Future<void> openAppSettings();
  Future<void> openLocationSettings();
}

class GeolocatorLocationService implements LocationService {
  const GeolocatorLocationService();

  static UserFix _fix(Position p) => UserFix(
    position: LatLng(p.latitude, p.longitude),
    time: p.timestamp,
    accuracy: p.accuracy,
    speed: p.speed < 0 ? 0 : p.speed,
    heading: p.heading,
  );

  static LocationAccess _fromPermission(LocationPermission permission) =>
      switch (permission) {
        LocationPermission.denied => LocationAccess.denied,
        LocationPermission.deniedForever => LocationAccess.deniedForever,
        LocationPermission.unableToDetermine => LocationAccess.error,
        _ => LocationAccess.ready,
      };

  @override
  Future<LocationAccess> checkAccess() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        return LocationAccess.serviceOff;
      }
      return _fromPermission(await Geolocator.checkPermission());
    } catch (_) {
      return LocationAccess.error;
    }
  }

  @override
  Future<LocationAccess> requestAccess() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        return LocationAccess.serviceOff;
      }
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      return _fromPermission(permission);
    } catch (_) {
      return LocationAccess.error;
    }
  }

  @override
  Future<UserFix?> currentFix() async {
    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 15),
        ),
      );
      return _fix(position);
    } catch (_) {
      return null;
    }
  }

  @override
  Stream<UserFix> fixes({int distanceFilterMeters = 10}) =>
      Geolocator.getPositionStream(
        locationSettings: LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: distanceFilterMeters,
        ),
      ).map(_fix);

  @override
  Future<void> openAppSettings() => Geolocator.openAppSettings();

  @override
  Future<void> openLocationSettings() => Geolocator.openLocationSettings();
}
