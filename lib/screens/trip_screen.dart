import 'dart:async';

import 'package:flutter/material.dart';

import '../core/geo.dart';
import '../models/trip.dart';
import '../services/app_services.dart';
import '../state/oto_ku_state.dart';
import '../state/trip_tracker.dart';
import '../ui/common.dart';

/// Start/stop a GPS trip, then optionally add the distance to the odometer.
class TripScreen extends StatefulWidget {
  const TripScreen({super.key, required this.state});
  final OtoKuState state;

  @override
  State<TripScreen> createState() => _TripScreenState();
}

class _TripScreenState extends State<TripScreen> {
  Timer? _ticker;
  TripSummary? _justFinished;
  Trip? _justSaved;
  String? _message;

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted && ServicesScope.of(context).trip.recording) setState(() {});
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  Future<void> _start(AppServices services) async {
    setState(() {
      _justFinished = null;
      _justSaved = null;
      _message = null;
    });
    final result = await services.trip.start();
    if (!mounted) return;
    if (result == TripStart.noLocation) {
      setState(
        () => _message =
            services.location.problemMessage ?? 'Lokasi belum tersedia.',
      );
    }
  }

  Future<void> _stop(AppServices services) async {
    final summary = services.trip.stop();
    if (summary == null) return;
    final saved = await widget.state.saveTrip(
      startedAt: summary.startedAt,
      endedAt: summary.endedAt,
      distanceMeters: summary.distanceMeters,
      durationSeconds: summary.duration.inSeconds,
    );
    if (!mounted) return;
    setState(() {
      _justFinished = summary;
      _justSaved = saved;
    });
  }

  Future<void> _addToMileage(Trip trip) async {
    try {
      final reading = await widget.state.addTripToMileage(trip.id);
      if (!mounted) return;
      setState(() {
        _message =
            'Kilometer kendaraan menjadi ${formatKilometers(reading)} km.';
        if (_justSaved?.id == trip.id) {
          _justSaved = _justSaved!.copyWith(addedToMileage: true);
        }
      });
    } on ArgumentError catch (e) {
      if (mounted) {
        setState(
          () => _message = e.message.toString().contains('decrease')
              ? 'Kilometer tidak boleh turun.'
              : '${e.message}',
        );
      }
    } on StateError catch (e) {
      if (mounted) setState(() => _message = e.message);
    }
  }

  double _km(TripTracker tracker) =>
      (tracker.recording
          ? tracker.distanceMeters
          : (_justFinished?.distanceMeters ?? 0)) /
      1000;

  @override
  Widget build(BuildContext context) {
    final services = ServicesScope.of(context);
    final tracker = services.trip;
    return AppPage(
      title: 'Trip GPS',
      child: ListenableBuilder(
        listenable: Listenable.merge([
          tracker,
          widget.state,
          services.location,
        ]),
        builder: (context, _) {
          final trips = widget.state.activeTrips;
          return ScrollPage(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CardBox(
                  color: AppColors.surfaceLow,
                  child: Text(
                    'Trip direkam dari GPS hanya saat OtoKu terbuka. Jarak adalah estimasi dan tidak menggantikan odometer kendaraan. Kendaraan: ${widget.state.vehicle.name}.',
                    style: const TextStyle(fontSize: 12.5, height: 1.4),
                  ),
                ),
                const SizedBox(height: 12),
                if (services.location.problemMessage != null &&
                    !tracker.recording)
                  CardBox(
                    color: AppColors.amberTint,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          services.location.problemMessage!,
                          style: const TextStyle(fontSize: 13),
                        ),
                        TextButton(
                          onPressed: services.location.request,
                          child: const Text('Izinkan lokasi'),
                        ),
                      ],
                    ),
                  ),
                if (services.location.problemMessage != null &&
                    !tracker.recording)
                  const SizedBox(height: 12),
                CardBox(
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _Stat(
                              'Jarak',
                              '${_km(tracker).toStringAsFixed(2).replaceAll('.', ',')} km',
                              const ValueKey('trip-distance'),
                            ),
                          ),
                          Expanded(
                            child: _Stat(
                              'Durasi',
                              formatClockDuration(
                                tracker.recording
                                    ? tracker.elapsed
                                    : (_justFinished?.duration ??
                                          Duration.zero),
                              ),
                              const ValueKey('trip-duration'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      SizedBox(
                        width: double.infinity,
                        child: tracker.recording
                            ? FilledButton.icon(
                                key: const ValueKey('trip-stop'),
                                onPressed: () => _stop(services),
                                style: FilledButton.styleFrom(
                                  backgroundColor: AppColors.ink,
                                  minimumSize: const Size.fromHeight(50),
                                ),
                                icon: const Icon(Icons.stop_circle_outlined),
                                label: const Text('Hentikan Trip'),
                              )
                            : FilledButton.icon(
                                key: const ValueKey('trip-start'),
                                onPressed: () => _start(services),
                                style: FilledButton.styleFrom(
                                  minimumSize: const Size.fromHeight(50),
                                ),
                                icon: const Icon(Icons.play_circle_outline),
                                label: const Text('Mulai Trip'),
                              ),
                      ),
                      if (tracker.recording)
                        const Padding(
                          padding: EdgeInsets.only(top: 8),
                          child: Text(
                            'Merekam… biarkan OtoKu tetap terbuka.',
                            style: TextStyle(
                              color: AppColors.muted,
                              fontSize: 12,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                if (_message != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Text(
                      _message!,
                      key: const ValueKey('trip-message'),
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                if (_justSaved != null && !tracker.recording) ...[
                  const SectionTitle('Trip selesai'),
                  _TripActions(
                    trip: _justSaved!,
                    onAdd: () => _addToMileage(_justSaved!),
                    vehicleMileage: widget.state.vehicle.mileage,
                  ),
                ],
                const SectionTitle('Riwayat trip'),
                if (trips.isEmpty)
                  const CardBox(
                    child: Column(
                      children: [
                        Icon(
                          Icons.route_outlined,
                          size: 34,
                          color: AppColors.muted,
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Belum ada trip',
                          style: TextStyle(fontWeight: FontWeight.w800),
                        ),
                        Text(
                          'Mulai trip untuk mencatat jarak dan durasi perjalananmu.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: AppColors.muted),
                        ),
                      ],
                    ),
                  ),
                for (final trip in trips)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: CardBox(
                      child: Row(
                        children: [
                          const Icon(Icons.route, color: AppColors.red),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${trip.km.toStringAsFixed(2).replaceAll('.', ',')} km · ${formatDuration(Duration(seconds: trip.durationSeconds))}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                Text(
                                  formatDateId(trip.startedAt),
                                  style: const TextStyle(
                                    color: AppColors.muted,
                                    fontSize: 12,
                                  ),
                                ),
                                Text(
                                  trip.addedToMileage
                                      ? 'Sudah ditambahkan ke kilometer'
                                      : 'Belum ditambahkan ke kilometer',
                                  style: TextStyle(
                                    color: trip.addedToMileage
                                        ? AppColors.green
                                        : AppColors.muted,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (!trip.addedToMileage && trip.roundedKm >= 1)
                            TextButton(
                              onPressed: () => _addToMileage(trip),
                              child: const Text('Tambah km'),
                            ),
                          IconButton(
                            tooltip: 'Hapus trip',
                            onPressed: () => widget.state.deleteTrip(trip.id),
                            icon: const Icon(
                              Icons.delete_outline,
                              color: AppColors.muted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat(this.label, this.value, this.valueKey);
  final String label, value;
  final Key valueKey;
  @override
  Widget build(BuildContext context) => Column(
    children: [
      Text(
        value,
        key: valueKey,
        style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900),
      ),
      Text(label, style: const TextStyle(color: AppColors.muted, fontSize: 12)),
    ],
  );
}

class _TripActions extends StatelessWidget {
  const _TripActions({
    required this.trip,
    required this.onAdd,
    required this.vehicleMileage,
  });
  final Trip trip;
  final VoidCallback onAdd;
  final int vehicleMileage;

  @override
  Widget build(BuildContext context) {
    final km = trip.roundedKm;
    return CardBox(
      color: AppColors.greenTint,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tersimpan: ${trip.km.toStringAsFixed(2).replaceAll('.', ',')} km dalam ${formatDuration(Duration(seconds: trip.durationSeconds))}',
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          if (trip.addedToMileage)
            const Text('Jarak sudah ditambahkan ke catatan kilometer.')
          else if (km < 1)
            const Text(
              'Jarak kurang dari 1 km, jadi tidak ditawarkan untuk catatan kilometer.',
            )
          else ...[
            Text(
              'Tambahkan $km km ke catatan kilometer? (${formatKilometers(vehicleMileage)} → ${formatKilometers(vehicleMileage + km)} km)',
            ),
            const SizedBox(height: 8),
            FilledButton(
              key: const ValueKey('trip-add-mileage'),
              onPressed: onAdd,
              child: const Text('Tambahkan ke catatan kilometer'),
            ),
          ],
        ],
      ),
    );
  }
}
