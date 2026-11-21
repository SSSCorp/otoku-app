import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';

import '../services/location_service.dart';

/// Owns device-location permission state and the live position stream shared
/// by the map, GPS trips and SPBU visit detection.
class LocationController extends ChangeNotifier {
  LocationController(this.service);

  final LocationService service;

  LocationAccess access = LocationAccess.unknown;
  UserFix? fix;
  bool checking = false;
  final _fixes = StreamController<UserFix>.broadcast();
  StreamSubscription<UserFix>? _subscription;
  bool _disposed = false;

  Stream<UserFix> get fixes => _fixes.stream;
  LatLng? get position => fix?.position;
  bool get isReady => access == LocationAccess.ready;
  bool get isStreaming => _subscription != null;

  /// Indonesian explanation of why location is unavailable; null when ready.
  String? get problemMessage => switch (access) {
    LocationAccess.denied => 'Izin lokasi ditolak. Izinkan lokasi agar OtoKu bisa menampilkan posisimu dan jarak ke tempat terdekat.',
    LocationAccess.deniedForever => 'Izin lokasi diblokir. Buka Pengaturan aplikasi lalu izinkan lokasi untuk OtoKu.',
    LocationAccess.serviceOff => 'Layanan lokasi (GPS) di perangkat mati. Nyalakan GPS untuk melihat posisimu.',
    LocationAccess.error =>
      'Posisimu belum bisa ditentukan. Coba lagi di tempat terbuka.',
    _ => null,
  };

  /// Checks permission without prompting (safe at app start). Starts the
  /// position stream when location is already allowed.
  Future<void> refresh() async => _apply(await service.checkAccess());

  /// Prompts for permission if needed and starts updates when granted.
  Future<void> request() async {
    checking = true;
    notifyListeners();
    try {
      await _apply(await service.requestAccess());
    } finally {
      checking = false;
      if (!_disposed) notifyListeners();
    }
  }

  Future<void> _apply(LocationAccess result) async {
    access = result;
    if (result == LocationAccess.ready) {
      start();
      if (fix == null) {
        final first = await service.currentFix();
        if (first != null) _publish(first);
      }
    } else {
      stop();
    }
    if (!_disposed) notifyListeners();
  }

  void _publish(UserFix next) {
    fix = next;
    if (!_fixes.isClosed) _fixes.add(next);
    if (!_disposed) notifyListeners();
  }

  void start() {
    if (_subscription != null) return;
    _subscription = service.fixes().listen(
      _publish,
      onError: (Object _) {
        access = LocationAccess.error;
        stop();
        if (!_disposed) notifyListeners();
      },
    );
  }

  void stop() {
    _subscription?.cancel();
    _subscription = null;
  }

  Future<void> openAppSettings() => service.openAppSettings();
  Future<void> openLocationSettings() => service.openLocationSettings();

  @override
  void dispose() {
    _disposed = true;
    stop();
    _fixes.close();
    super.dispose();
  }
}
