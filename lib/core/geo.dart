import 'dart:math' as math;

import 'package:latlong2/latlong.dart';

const _earthRadiusMeters = 6371008.8;

/// Great-circle (haversine) distance in metres.
double distanceMeters(LatLng a, LatLng b) {
  double rad(double d) => d * math.pi / 180;
  final dLat = rad(b.latitude - a.latitude);
  final dLng = rad(b.longitude - a.longitude);
  final h =
      math.pow(math.sin(dLat / 2), 2) +
      math.cos(rad(a.latitude)) *
          math.cos(rad(b.latitude)) *
          math.pow(math.sin(dLng / 2), 2);
  return 2 * _earthRadiusMeters * math.asin(math.min(1, math.sqrt(h)));
}

/// "850 m" below 1 km, otherwise "2,1 km" (Indonesian decimal comma);
/// distances of 100 km or more drop the decimal.
String formatDistance(double meters) {
  if (meters < 1000) return '${(meters / 10).round() * 10} m';
  final km = meters / 1000;
  if (km >= 100) return '${km.round()} km';
  return '${km.toStringAsFixed(1).replaceAll('.', ',')} km';
}

String formatDuration(Duration d) {
  final seconds = d.inSeconds;
  if (seconds < 60) return '$seconds dtk';
  final minutes = (seconds / 60).round();
  if (minutes < 60) return '$minutes mnt';
  final h = minutes ~/ 60, m = minutes % 60;
  return m == 0 ? '$h jam' : '$h jam $m mnt';
}

String formatClockDuration(Duration d) {
  String two(int n) => n.toString().padLeft(2, '0');
  return '${two(d.inHours)}:${two(d.inMinutes % 60)}:${two(d.inSeconds % 60)}';
}
