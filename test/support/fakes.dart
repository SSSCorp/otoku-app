import 'dart:async';

import 'package:latlong2/latlong.dart';
import 'package:otoku/core/app_config.dart';
import 'package:otoku/services/app_services.dart';
import 'package:otoku/services/location_service.dart';
import 'package:otoku/services/network_and_launcher.dart';
import 'package:otoku/services/routing_service.dart';

/// Bekasi Utara, close to the demo places.
const bekasi = LatLng(-6.2060, 106.9950);

class FakeLocationService implements LocationService {
  FakeLocationService({
    this.access = LocationAccess.ready,
    LocationAccess? afterRequest,
    this.fix,
  }) : afterRequest = afterRequest ?? access;

  LocationAccess access;
  LocationAccess afterRequest;
  UserFix? fix;
  int requests = 0;
  int appSettingsOpened = 0;
  int locationSettingsOpened = 0;
  final controller = StreamController<UserFix>.broadcast();

  @override
  Future<LocationAccess> checkAccess() async => access;

  @override
  Future<LocationAccess> requestAccess() async {
    requests++;
    access = afterRequest;
    return access;
  }

  @override
  Future<UserFix?> currentFix() async => fix;

  @override
  Stream<UserFix> fixes({int distanceFilterMeters = 10}) => controller.stream;

  @override
  Future<void> openAppSettings() async => appSettingsOpened++;

  @override
  Future<void> openLocationSettings() async => locationSettingsOpened++;

  void emit(
    LatLng position, {
    double accuracy = 5,
    double speed = 0,
    DateTime? time,
  }) => controller.add(
    UserFix(
      position: position,
      accuracy: accuracy,
      speed: speed,
      time: time ?? DateTime.now(),
    ),
  );
}

UserFix fixAt(
  LatLng p, {
  DateTime? time,
  double accuracy = 5,
  double speed = 0,
}) => UserFix(
  position: p,
  time: time ?? DateTime.now(),
  accuracy: accuracy,
  speed: speed,
);

class FakeRoutingService implements RoutingService {
  FakeRoutingService({this.failure});
  RoutingFailure? failure;
  final calls = <(LatLng, LatLng)>[];

  @override
  Future<RouteResult> route(LatLng from, LatLng to) async {
    calls.add((from, to));
    if (failure != null) throw RoutingException(failure!);
    return RouteResult(
      distanceMeters: 3400,
      duration: const Duration(minutes: 9, seconds: 20),
      points: [
        from,
        LatLng((from.latitude + to.latitude) / 2, from.longitude),
        to,
      ],
    );
  }
}

class FakeNetwork implements NetworkChecker {
  FakeNetwork([this.online = true]);
  bool online;
  @override
  Future<bool> isOnline() async => online;
}

class FakeLauncher implements ExternalMapLauncher {
  final opened = <(LatLng, String)>[];
  bool result = true;
  @override
  Future<bool> openDirections(LatLng destination, String label) async {
    opened.add((destination, label));
    return result;
  }
}

AppServices testServices({
  FakeLocationService? location,
  FakeRoutingService? routing,
  FakeNetwork? network,
  FakeLauncher? launcher,
  AppConfig config = const AppConfig(),
  Duration spbuDwell = const Duration(seconds: 30),
}) => AppServices(
  config: config,
  locationService: location ?? FakeLocationService(fix: fixAt(bekasi)),
  routing: routing ?? FakeRoutingService(),
  network: network ?? FakeNetwork(),
  launcher: launcher ?? FakeLauncher(),
  tilesEnabled: false,
  spbuDwell: spbuDwell,
  visitTick: const Duration(milliseconds: 20),
);
