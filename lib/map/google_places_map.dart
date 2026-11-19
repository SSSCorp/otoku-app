import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as g;
import 'package:latlong2/latlong.dart';

import '../models/place.dart';
import 'places_map.dart';

g.LatLng _g(LatLng p) => g.LatLng(p.latitude, p.longitude);

/// Google Maps implementation, used only when MAP_PROVIDER=google and an API
/// key is present. Markers are clustered by the Maps SDK's cluster manager.
class GooglePlacesMap extends StatefulWidget {
  const GooglePlacesMap({
    super.key,
    required this.places,
    required this.controller,
    required this.initialCenter,
    required this.onSelect,
    this.selectedId,
    this.user,
    this.route,
  });

  final List<Place> places;
  final PlacesMapController controller;
  final LatLng initialCenter;
  final ValueChanged<Place> onSelect;
  final String? selectedId;
  final LatLng? user;
  final List<LatLng>? route;

  @override
  State<GooglePlacesMap> createState() => _GooglePlacesMapState();
}

class _GooglePlacesMapState extends State<GooglePlacesMap> {
  static const _clusterId = g.ClusterManagerId('places');

  @override
  void dispose() {
    widget.controller.detach();
    super.dispose();
  }

  void _onCreated(g.GoogleMapController map) {
    widget.controller.attach(
      moveTo: (target, zoom) => map.animateCamera(
        zoom == null
            ? g.CameraUpdate.newLatLng(_g(target))
            : g.CameraUpdate.newLatLngZoom(_g(target), zoom),
      ),
      fit: (points) {
        if (points.isEmpty) return;
        if (points.length == 1) {
          map.animateCamera(g.CameraUpdate.newLatLngZoom(_g(points.first), 15));
          return;
        }
        final lats = points.map((p) => p.latitude),
            lngs = points.map((p) => p.longitude);
        map.animateCamera(
          g.CameraUpdate.newLatLngBounds(
            g.LatLngBounds(
              southwest: g.LatLng(
                lats.reduce((a, b) => a < b ? a : b),
                lngs.reduce((a, b) => a < b ? a : b),
              ),
              northeast: g.LatLng(
                lats.reduce((a, b) => a > b ? a : b),
                lngs.reduce((a, b) => a > b ? a : b),
              ),
            ),
            56,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) => g.GoogleMap(
    initialCameraPosition: g.CameraPosition(
      target: _g(widget.initialCenter),
      zoom: 14,
    ),
    onMapCreated: _onCreated,
    myLocationEnabled: widget.user != null,
    myLocationButtonEnabled: false,
    zoomControlsEnabled: false,
    mapToolbarEnabled: false,
    clusterManagers: {const g.ClusterManager(clusterManagerId: _clusterId)},
    markers: {
      for (final place in widget.places)
        g.Marker(
          markerId: g.MarkerId(place.id),
          position: _g(place.position),
          clusterManagerId: _clusterId,
          infoWindow: g.InfoWindow(title: place.name),
          icon: g.BitmapDescriptor.defaultMarkerWithHue(
            place.id == widget.selectedId
                ? g.BitmapDescriptor.hueAzure
                : switch (place.category) {
                    PlaceCategory.bengkel => g.BitmapDescriptor.hueRed,
                    PlaceCategory.spbu => g.BitmapDescriptor.hueBlue,
                    PlaceCategory.minimarket => g.BitmapDescriptor.hueGreen,
                  },
          ),
          onTap: () => widget.onSelect(place),
        ),
    },
    polylines: {
      if (widget.route != null && widget.route!.length > 1)
        g.Polyline(
          polylineId: const g.PolylineId('route'),
          points: widget.route!.map(_g).toList(),
          width: 5,
          color: const Color(0xFF1565C0),
        ),
    },
  );
}
