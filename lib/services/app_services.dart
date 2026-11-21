import 'package:flutter/widgets.dart';

import '../core/app_config.dart';
import '../models/place.dart';
import '../state/location_controller.dart';
import '../state/spbu_visit_detector.dart';
import '../state/spbu_visit_monitor.dart';
import '../state/trip_tracker.dart';
import 'location_service.dart';
import 'network_and_launcher.dart';
import 'routing_service.dart';

/// Runtime dependencies of the map features, injectable for tests.
class AppServices {
  AppServices({
    AppConfig? config,
    LocationService? locationService,
    RoutingService? routing,
    NetworkChecker? network,
    ExternalMapLauncher? launcher,
    this.tilesEnabled = true,
    Duration spbuDwell = const Duration(seconds: 30),
    Duration visitTick = const Duration(seconds: 5),
  }) : config = config ?? AppConfig.fromEnvironment(),
       location = LocationController(
         locationService ?? const GeolocatorLocationService(),
       ),
       routing = routing ?? OsrmRoutingService(),
       network = network ?? const DnsNetworkChecker(),
       launcher = launcher ?? const UrlExternalMapLauncher() {
    trip = TripTracker(location);
    visits = SpbuVisitMonitor(
      location,
      Place.demoPlaces,
      tick: visitTick,
      detector: SpbuVisitDetector(places: Place.demoPlaces, dwell: spbuDwell),
    );
  }

  final AppConfig config;
  final LocationController location;
  final RoutingService routing;
  final NetworkChecker network;
  final ExternalMapLauncher launcher;

  /// False in widget tests so no tile requests are made.
  final bool tilesEnabled;
  late final TripTracker trip;
  late final SpbuVisitMonitor visits;

  /// Selected bottom-navigation tab; lets any screen jump to Pesanan / Peta.
  final tab = ValueNotifier<int>(0);

  static const tabHome = 0,
      tabShop = 1,
      tabPeta = 2,
      tabPesanan = 3,
      tabAkun = 4;

  void dispose() {
    visits.dispose();
    trip.dispose();
    location.dispose();
    tab.dispose();
  }

  /// Pops back to the shell and selects [index].
  void goToTab(BuildContext context, int index) {
    Navigator.of(context).popUntil((route) => route.isFirst);
    tab.value = index;
  }
}

class ServicesScope extends InheritedWidget {
  const ServicesScope({
    super.key,
    required this.services,
    required super.child,
  });
  final AppServices services;

  static AppServices of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<ServicesScope>();
    assert(scope != null, 'ServicesScope missing above this widget');
    return scope!.services;
  }

  @override
  bool updateShouldNotify(ServicesScope oldWidget) =>
      services != oldWidget.services;
}
