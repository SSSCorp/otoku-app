import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_marker_cluster/flutter_map_marker_cluster.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/app_config.dart';
import '../models/place.dart';
import 'places_map.dart';

/// Real OpenStreetMap map: raster tiles with an on-disk cache, clustered
/// place markers that never lose the selected pin, the user's live position,
/// an optional route polyline and the required attribution.
class OsmPlacesMap extends StatefulWidget {
  const OsmPlacesMap({
    super.key,
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

  final List<Place> places;
  final PlacesMapController controller;
  final LatLng initialCenter;
  final ValueChanged<Place> onSelect;
  final String? selectedId;
  final LatLng? user;
  final double? userAccuracy;
  final List<LatLng>? route;
  final bool tilesEnabled;
  final VoidCallback? onTilesFailed, onTilesLoaded;

  @override
  State<OsmPlacesMap> createState() => _OsmPlacesMapState();
}

class _OsmPlacesMapState extends State<OsmPlacesMap> {
  final _map = MapController();
  TileProvider? _tiles;

  // Marker list is rebuilt only when the set of places changes, so selecting
  // a place or panning/zooming never re-clusters or resets the layer.
  List<Marker> _markers = const [];
  String _markerKey = '';

  @override
  void initState() {
    super.initState();
    if (widget.tilesEnabled) {
      _tiles = NetworkTileProvider(
        headers: {
          'User-Agent': 'OtoKu-prototype (${AppConfig.userAgentPackage})',
        },
        silenceExceptions: true,
        cachingProvider: BuiltInMapCachingProvider.getOrCreateInstance(
          maxCacheSize: 200 * 1024 * 1024,
          overrideFreshAge: const Duration(days: 7),
        ),
      );
    }
    widget.controller.attach(
      moveTo: (target, zoom) => _map.move(target, zoom ?? _map.camera.zoom),
      fit: _fit,
    );
  }

  void _fit(List<LatLng> points) {
    if (points.isEmpty) return;
    if (points.length == 1) {
      _map.move(points.first, 15);
      return;
    }
    _map.fitCamera(
      CameraFit.coordinates(
        coordinates: points,
        padding: const EdgeInsets.all(48),
        maxZoom: 16,
      ),
    );
  }

  @override
  void dispose() {
    widget.controller.detach();
    _tiles?.dispose();
    _map.dispose();
    super.dispose();
  }

  List<Marker> _buildMarkers() {
    final key = widget.places.map((p) => p.id).join('|');
    if (key == _markerKey) return _markers;
    _markerKey = key;
    return _markers = [
      for (final place in widget.places)
        Marker(
          key: ValueKey('marker-${place.id}'),
          point: place.position,
          width: 40,
          height: 46,
          alignment: Alignment.topCenter,
          child: GestureDetector(
            onTap: () => widget.onSelect(place),
            child: Semantics(
              label: 'Penanda ${place.name}',
              button: true,
              child: _Pin(place.category),
            ),
          ),
        ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final selected = widget.places
        .where((p) => p.id == widget.selectedId)
        .firstOrNull;
    return FlutterMap(
      mapController: _map,
      options: MapOptions(
        initialCenter: widget.initialCenter,
        initialZoom: 14,
        minZoom: 3,
        maxZoom: 19,
        interactionOptions: const InteractionOptions(
          flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
        ),
      ),
      children: [
        if (_tiles != null)
          TileLayer(
            urlTemplate: AppConfig.osmTileUrl,
            userAgentPackageName: AppConfig.userAgentPackage,
            tileProvider: _tiles,
            maxNativeZoom: 19,
            errorTileCallback: (tile, error, stackTrace) =>
                widget.onTilesFailed?.call(),
            tileDisplay: const TileDisplay.fadeIn(),
          ),
        if (widget.route != null && widget.route!.length > 1)
          PolylineLayer(
            polylines: [
              Polyline(
                points: widget.route!,
                strokeWidth: 5,
                color: const Color(0xFF1565C0),
                borderStrokeWidth: 1.5,
                borderColor: Colors.white,
              ),
            ],
          ),
        if (widget.user != null && (widget.userAccuracy ?? 0) > 0)
          CircleLayer(
            circles: [
              CircleMarker(
                point: widget.user!,
                radius: widget.userAccuracy!.clamp(5, 300),
                useRadiusInMeter: true,
                color: const Color(0x221565C0),
                borderColor: const Color(0x661565C0),
                borderStrokeWidth: 1,
              ),
            ],
          ),
        MarkerClusterLayerWidget(
          options: MarkerClusterLayerOptions(
            maxClusterRadius: 52,
            size: const Size(42, 42),
            alignment: Alignment.center,
            padding: const EdgeInsets.all(48),
            maxZoom: 19,
            markers: _buildMarkers(),
            builder: (context, markers) => DecoratedBox(
              decoration: BoxDecoration(
                color: const Color(0xFF151C27),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: Center(
                child: Text(
                  '${markers.length}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ),
        ),
        if (selected != null)
          MarkerLayer(
            markers: [
              Marker(
                key: ValueKey('selected-${selected.id}'),
                point: selected.position,
                width: 52,
                height: 60,
                alignment: Alignment.topCenter,
                child: _Pin(selected.category, selected: true),
              ),
            ],
          ),
        if (widget.user != null)
          MarkerLayer(
            markers: [
              Marker(
                key: const ValueKey('user-position'),
                point: widget.user!,
                width: 26,
                height: 26,
                child: Semantics(label: 'Posisimu', child: const _UserDot()),
              ),
            ],
          ),
        Align(
          alignment: Alignment.bottomLeft,
          child: GestureDetector(
            onTap: () => launchUrl(
              Uri.parse(AppConfig.osmCopyrightUrl),
              mode: LaunchMode.externalApplication,
            ),
            child: Container(
              margin: const EdgeInsets.all(4),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xCCFFFFFF),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                AppConfig.osmAttribution,
                style: TextStyle(fontSize: 11, color: Color(0xFF0078A8)),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _Pin extends StatelessWidget {
  const _Pin(this.category, {this.selected = false});
  final PlaceCategory category;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final color = categoryColor(category);
    final size = selected ? 38.0 : 30.0;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: selected ? color : Colors.white,
            shape: BoxShape.circle,
            border: Border.all(color: color, width: selected ? 3 : 2.5),
            boxShadow: const [
              BoxShadow(
                color: Color(0x44000000),
                blurRadius: 4,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Icon(
            categoryIcon(category),
            size: size * .55,
            color: selected ? Colors.white : color,
          ),
        ),
        CustomPaint(size: const Size(10, 8), painter: _PinTip(color)),
      ],
    );
  }
}

class _PinTip extends CustomPainter {
  const _PinTip(this.color);
  final Color color;
  @override
  void paint(Canvas canvas, Size size) => canvas.drawPath(
    ui.Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width / 2, size.height)
      ..close(),
    Paint()..color = color,
  );
  @override
  bool shouldRepaint(_PinTip old) => old.color != color;
}

class _UserDot extends StatelessWidget {
  const _UserDot();
  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: const Color(0xFF1976D2),
      shape: BoxShape.circle,
      border: Border.all(color: Colors.white, width: 3),
      boxShadow: const [BoxShadow(color: Color(0x55000000), blurRadius: 5)],
    ),
  );
}
