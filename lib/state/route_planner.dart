import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';

import '../services/routing_service.dart';

/// Requests a driving route (distance + ETA) from OSRM for one destination.
class RoutePlanner extends ChangeNotifier {
  RoutePlanner(this._routing);
  final RoutingService _routing;

  RouteResult? result;
  String? forPlaceId;
  String? error;
  bool loading = false;
  int _ticket = 0;

  Future<void> plan(LatLng from, LatLng to, String placeId) async {
    final ticket = ++_ticket;
    loading = true;
    error = null;
    result = null;
    forPlaceId = placeId;
    notifyListeners();
    try {
      final route = await _routing.route(from, to);
      if (ticket != _ticket) return;
      result = route;
    } on RoutingException catch (e) {
      if (ticket != _ticket) return;
      error = e.message;
    } catch (_) {
      if (ticket != _ticket) return;
      error = const RoutingException(RoutingFailure.server).message;
    }
    loading = false;
    notifyListeners();
  }

  void clear() {
    _ticket++;
    result = null;
    error = null;
    loading = false;
    forPlaceId = null;
    notifyListeners();
  }
}
