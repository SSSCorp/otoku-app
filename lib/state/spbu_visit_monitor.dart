import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/place.dart';
import '../services/location_service.dart';
import 'location_controller.dart';
import 'spbu_visit_detector.dart';

/// Watches the live position for SPBU visits and exposes a pending prompt
/// the UI turns into a "Catat BBM?" offer. Runs only while the app is open.
class SpbuVisitMonitor extends ChangeNotifier {
  SpbuVisitMonitor(
    this.location,
    Iterable<Place> places, {
    DateTime Function()? clock,
    this._tick = const Duration(seconds: 5),
    SpbuVisitDetector? detector,
  }) : _clock = clock ?? DateTime.now,
       _detector = detector ?? SpbuVisitDetector(places: places);

  final LocationController location;
  final DateTime Function() _clock;
  final Duration _tick;
  final SpbuVisitDetector _detector;
  StreamSubscription<UserFix>? _subscription;
  Timer? _timer;

  /// SPBU the user appears to be at; cleared by [dismiss].
  Place? pending;

  void start() {
    _subscription ??= location.fixes.listen(_evaluate);
    _timer ??= Timer.periodic(_tick, (_) => _evaluate(location.fix));
  }

  void stop() {
    _subscription?.cancel();
    _subscription = null;
    _timer?.cancel();
    _timer = null;
  }

  void _evaluate(UserFix? fix) {
    if (fix == null || pending != null) return;
    final visit = _detector.evaluate(
      fix.position,
      _clock(),
      accuracy: fix.accuracy,
      speed: fix.speed,
    );
    if (visit != null) {
      pending = visit;
      notifyListeners();
    }
  }

  void dismiss() {
    pending = null;
    notifyListeners();
  }

  @override
  void dispose() {
    stop();
    super.dispose();
  }
}
