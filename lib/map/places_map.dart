import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

import '../core/app_config.dart';
import '../models/place.dart';
import 'google_places_map.dart';
import 'osm_places_map.dart';

/// Imperative handle for the map widget (works for both providers).
class PlacesMapController {
  void Function(LatLng target, double? zoom)? _moveTo;
  void Function(List<LatLng> points)? _fit;

  void attach({
    required void Function(LatLng, double?) moveTo,
    required void Function(List<LatLng>) fit,
  }) {
    _moveTo = moveTo;
    _fit = fit;
  }

  void detach() {
    _moveTo = null;
    _fit = null;
  }

  void moveTo(LatLng target, {double? zoom}) => _moveTo?.call(target, zoom);
  void fitPoints(List<LatLng> points) => _fit?.call(points);
}

/// Inputs shared by the OSM and Google map implementations.
class PlacesMapView extends StatelessWidget {
  const PlacesMapView({
    super.key,
    required this.provider,
    required this.places,
    required this.controller,
    required this.initialCenter,
    required this.onSelect,
    this.selectedId,
    this.user,
    this.userAccuracy,
    this.route,
    this.tilesEnabled = true,
    this.onTilesFailed,
    this.onTilesLoaded,
  });

  final MapProvider provider;
  final List<Place> places;
  final PlacesMapController controller;
  final LatLng initialCenter;
  final ValueChanged<Place> onSelect;
  final String? selectedId;
  final LatLng? user;
  final double? userAccuracy;
  final List<LatLng>? route;
  final bool tilesEnabled;
  final VoidCallback? onTilesFailed;
  final VoidCallback? onTilesLoaded;

  @override
  Widget build(BuildContext context) => provider == MapProvider.google
      ? GooglePlacesMap(
          places: places,
          controller: controller,
          initialCenter: initialCenter,
          onSelect: onSelect,
          selectedId: selectedId,
          user: user,
          route: route,
        )
      : OsmPlacesMap(
          places: places,
          controller: controller,
          initialCenter: initialCenter,
          onSelect: onSelect,
          selectedId: selectedId,
          user: user,
          userAccuracy: userAccuracy,
          route: route,
          tilesEnabled: tilesEnabled,
          onTilesFailed: onTilesFailed,
          onTilesLoaded: onTilesLoaded,
        );
}

IconData categoryIcon(PlaceCategory c) => switch (c) {
  PlaceCategory.bengkel => Icons.build,
  PlaceCategory.spbu => Icons.local_gas_station,
  PlaceCategory.minimarket => Icons.storefront,
};

Color categoryColor(PlaceCategory c) => switch (c) {
  PlaceCategory.bengkel => const Color(0xFFE21B23),
  PlaceCategory.spbu => const Color(0xFF1565C0),
  PlaceCategory.minimarket => const Color(0xFF2E7D32),
};
