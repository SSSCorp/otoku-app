import 'package:latlong2/latlong.dart';

import '../core/geo.dart';
import '../models/place.dart';

/// Detects that the user has stopped at an SPBU so the app can offer to log
/// BBM. Needs the user inside [radiusMeters] of an SPBU, moving slower than
/// [maxSpeed] and staying for [dwell]. A place is not offered again within
/// [cooldown].
class SpbuVisitDetector {
  SpbuVisitDetector({
    required Iterable<Place> places,
    this.radiusMeters = 80,
    this.dwell = const Duration(seconds: 30),
    this.cooldown = const Duration(hours: 1),
    this.maxSpeed = 3.0,
    this.maxAccuracy = 100,
  }) : _spbu = places.where((p) => p.category == PlaceCategory.spbu).toList();

  final List<Place> _spbu;
  final double radiusMeters, maxSpeed, maxAccuracy;
  final Duration dwell, cooldown;

  Place? _candidate;
  DateTime? _since;
  final _lastPrompt = <String, DateTime>{};

  /// Feeds the latest known position. Returns the SPBU once per visit.
  Place? evaluate(
    LatLng position,
    DateTime now, {
    double accuracy = 0,
    double speed = 0,
  }) {
    if (accuracy > maxAccuracy || speed > maxSpeed) {
      _reset();
      return null;
    }
    Place? nearest;
    var best = double.infinity;
    for (final place in _spbu) {
      final d = distanceMeters(position, place.position);
      if (d <= radiusMeters && d < best) {
        nearest = place;
        best = d;
      }
    }
    if (nearest == null) {
      _reset();
      return null;
    }
    if (_candidate?.id != nearest.id) {
      _candidate = nearest;
      _since = now;
    }
    final last = _lastPrompt[nearest.id];
    if (last != null && now.difference(last) < cooldown) return null;
    if (now.difference(_since!) >= dwell) {
      _lastPrompt[nearest.id] = now;
      _reset();
      return nearest;
    }
    return null;
  }

  void _reset() {
    _candidate = null;
    _since = null;
  }
}
