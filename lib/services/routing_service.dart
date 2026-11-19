import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

class RouteResult {
  const RouteResult({
    required this.distanceMeters,
    required this.duration,
    required this.points,
  });
  final double distanceMeters;
  final Duration duration;
  final List<LatLng> points;
}

enum RoutingFailure { offline, noRoute, server }

class RoutingException implements Exception {
  const RoutingException(this.failure);
  final RoutingFailure failure;

  String get message => switch (failure) {
    RoutingFailure.offline => 'Tidak ada koneksi internet. Rute tidak dapat dihitung; coba buka di aplikasi peta.',
    RoutingFailure.noRoute => 'Rute tidak ditemukan untuk lokasi ini.',
    RoutingFailure.server => 'Layanan rute sedang tidak tersedia. Coba lagi atau buka di aplikasi peta.',
  };

  @override
  String toString() => message;
}

abstract interface class RoutingService {
  Future<RouteResult> route(LatLng from, LatLng to);
}

/// Free routing through the public OSRM demo server (driving profile).
/// Suitable for a prototype; it has no SLA or usage guarantees.
class OsrmRoutingService implements RoutingService {
  OsrmRoutingService({
    http.Client? client,
    this.baseUrl = 'https://router.project-osrm.org',
  }) : _client = client ?? http.Client();

  final http.Client _client;
  final String baseUrl;

  @override
  Future<RouteResult> route(LatLng from, LatLng to) async {
    final uri = Uri.parse(
      '$baseUrl/route/v1/driving/'
      '${from.longitude},${from.latitude};${to.longitude},${to.latitude}'
      '?overview=full&geometries=geojson',
    );
    final http.Response response;
    try {
      response = await _client
          .get(uri, headers: {'User-Agent': 'OtoKu-prototype'})
          .timeout(const Duration(seconds: 12));
    } on SocketException {
      throw const RoutingException(RoutingFailure.offline);
    } on http.ClientException {
      throw const RoutingException(RoutingFailure.offline);
    } on TimeoutException {
      throw const RoutingException(RoutingFailure.offline);
    }
    if (response.statusCode != 200) {
      throw const RoutingException(RoutingFailure.server);
    }
    return parse(response.body);
  }

  /// Parses an OSRM `route` response body.
  static RouteResult parse(String body) {
    final Map<String, dynamic> json;
    try {
      json = jsonDecode(body) as Map<String, dynamic>;
    } catch (_) {
      throw const RoutingException(RoutingFailure.server);
    }
    final routes = json['routes'];
    if (json['code'] != 'Ok' || routes is! List || routes.isEmpty) {
      throw const RoutingException(RoutingFailure.noRoute);
    }
    final route = routes.first as Map<String, dynamic>;
    final coordinates =
        ((route['geometry'] as Map?)?['coordinates'] as List? ?? [])
            .map(
              (c) => LatLng((c[1] as num).toDouble(), (c[0] as num).toDouble()),
            )
            .toList();
    return RouteResult(
      distanceMeters: (route['distance'] as num).toDouble(),
      duration: Duration(seconds: (route['duration'] as num).round()),
      points: coordinates,
    );
  }
}
