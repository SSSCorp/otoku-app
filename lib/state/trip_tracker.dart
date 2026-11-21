import 'dart:async';

import 'package:flutter/foundation.dart';

import '../core/geo.dart' as geo;
import '../services/location_service.dart';
import 'location_controller.dart';

class TripSummary {
  const TripSummary({
    required this.startedAt,
    required this.endedAt,
    required this.distanceMeters,
    required this.duration,
  });
  final DateTime startedAt, endedAt;
  final double distanceMeters;
  final Duration duration;
}

enum TripStart { started, alreadyRecording, noLocation }

/// Records a GPS trip while the app is open: accumulates distance between
/// accepted fixes and measures elapsed time. Noisy fixes (poor accuracy,
/// sub-5 m jitter, impossible jumps) are ignored.
class TripTracker extends ChangeNotifier {
  TripTracker(this.location, {DateTime Function()? clock})
    : _clock = clock ?? DateTime.now;

  final LocationController location;
  final DateTime Function() _clock;

  static const minStepMeters = 5.0;
  static const maxAccuracyMeters = 50.0;
  static const maxSpeedMps = 70.0;

  bool recording = false;
  double distanceMeters = 0;
  DateTime? startedAt;
  int acceptedFixes = 0;
  UserFix? _last;
  StreamSubscription<UserFix>? _subscription;

  Duration get elapsed =>
      startedAt == null ? Duration.zero : _clock().difference(startedAt!);

  Future<TripStart> start() async {
    if (recording) return TripStart.alreadyRecording;
    if (!location.isReady) await location.request();
    if (!location.isReady) return TripStart.noLocation;
    recording = true;
    distanceMeters = 0;
    acceptedFixes = 0;
    startedAt = _clock();
    _last = location.fix;
    _subscription = location.fixes.listen(onFix);
    notifyListeners();
    return TripStart.started;
  }

  /// Visible for tests; normally driven by the location stream.
  void onFix(UserFix fix) {
    if (!recording) return;
    if (fix.accuracy > maxAccuracyMeters) return;
    final last = _last;
    if (last == null) {
      _last = fix;
      return;
    }
    final step = geo.distanceMeters(last.position, fix.position);
    if (step < minStepMeters) return;
    final seconds = fix.time.difference(last.time).inMilliseconds / 1000;
    if (seconds > 0 && step / seconds > maxSpeedMps) return;
    distanceMeters += step;
    acceptedFixes++;
    _last = fix;
    notifyListeners();
  }

  TripSummary? stop() {
    if (!recording) return null;
    final end = _clock();
    final summary = TripSummary(
      startedAt: startedAt!,
      endedAt: end,
      distanceMeters: distanceMeters,
      duration: end.difference(startedAt!),
    );
    _subscription?.cancel();
    _subscription = null;
    recording = false;
    startedAt = null;
    _last = null;
    notifyListeners();
    return summary;
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
