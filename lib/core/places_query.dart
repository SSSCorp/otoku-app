import 'package:latlong2/latlong.dart';

import '../models/place.dart';
import '../state/oto_ku_state.dart' show PlaceFilter, PlaceSort;
import 'geo.dart';

class PlaceResult {
  const PlaceResult(this.place, this.distanceMeters);
  final Place place;

  /// Metres from the user; null when the position is unknown.
  final double? distanceMeters;
}

/// Filters, searches and sorts places. Pure, so it is easy to unit test.
List<PlaceResult> queryPlaces(
  Iterable<Place> places, {
  LatLng? origin,
  String search = '',
  PlaceFilter filter = PlaceFilter.all,
  PlaceSort sort = PlaceSort.distance,
}) {
  final needle = search.toLowerCase().trim();
  final results = [
    for (final place in places)
      if (filter.matches(place) && _matches(place, needle))
        PlaceResult(
          place,
          origin == null ? null : distanceMeters(origin, place.position),
        ),
  ];
  results.sort((a, b) {
    if (sort == PlaceSort.distance &&
        a.distanceMeters != null &&
        b.distanceMeters != null) {
      return a.distanceMeters!.compareTo(b.distanceMeters!);
    }
    return a.place.name.toLowerCase().compareTo(b.place.name.toLowerCase());
  });
  return results;
}

bool _matches(Place p, String needle) =>
    needle.isEmpty ||
    '${p.name} ${p.category.label} ${p.address} ${p.services.join(' ')}'
        .toLowerCase()
        .contains(needle);

/// Nearest places of [category] to [origin], closest first.
List<PlaceResult> nearestPlaces(
  Iterable<Place> places,
  LatLng? origin, {
  PlaceCategory category = PlaceCategory.bengkel,
  int limit = 3,
}) {
  final results = queryPlaces(
    places.where((p) => p.category == category),
    origin: origin,
  );
  return results.take(limit).toList();
}
