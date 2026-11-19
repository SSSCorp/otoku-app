import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

import '../core/geo.dart';
import '../core/places_query.dart';
import '../map/places_map.dart';
import '../models/place.dart';
import '../services/app_services.dart';
import '../state/oto_ku_state.dart';
import '../state/route_planner.dart';
import '../ui/common.dart';
import 'place_screens.dart';

/// "Rute & ETA" + "Buka di aplikasi peta" actions for one place. Shows the
/// OSRM distance and ETA, or an Indonesian explanation when it fails.
class RouteActions extends StatelessWidget {
  const RouteActions({
    super.key,
    required this.place,
    required this.planner,
    this.compact = false,
  });
  final Place place;
  final RoutePlanner planner;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final services = ServicesScope.of(context);
    return ListenableBuilder(
      listenable: Listenable.merge([planner, services.location]),
      builder: (context, _) {
        final origin = services.location.position;
        final route = planner.forPlaceId == place.id ? planner.result : null;
        final error = planner.forPlaceId == place.id ? planner.error : null;
        final loading = planner.loading && planner.forPlaceId == place.id;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (route != null)
              Container(
                key: const ValueKey('route-result'),
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFE3F0FF),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.directions_car_outlined,
                      color: Color(0xFF1565C0),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'ETA ${formatDuration(route.duration)} · ${formatDistance(route.distanceMeters)} lewat jalan',
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ),
                  ],
                ),
              ),
            if (error != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  error,
                  key: const ValueKey('route-error'),
                  style: const TextStyle(color: AppColors.red, fontSize: 12),
                ),
              ),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton.icon(
                  onPressed: loading
                      ? null
                      : () async {
                          if (origin == null) {
                            await services.location.request();
                            if (services.location.position == null &&
                                context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    services.location.problemMessage ?? 'Posisimu belum tersedia. Coba lagi sebentar.',
                                  ),
                                ),
                              );
                              return;
                            }
                          }
                          final from = services.location.position;
                          if (from != null) {
                            await planner.plan(from, place.position, place.id);
                          }
                        },
                  icon: loading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.alt_route, size: 18),
                  label: Text(loading ? 'Menghitung…' : 'Rute & ETA'),
                  style: FilledButton.styleFrom(
                    minimumSize: Size(0, compact ? 40 : 46),
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: () async {
                    final ok = await services.launcher.openDirections(
                      place.position,
                      place.name,
                    );
                    if (!ok && context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Tidak ada aplikasi peta yang bisa dibuka di perangkat ini.',
                          ),
                        ),
                      );
                    }
                  },
                  icon: const Icon(Icons.open_in_new, size: 18),
                  label: const Text('Buka di Maps'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: Size(0, compact ? 40 : 46),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}

/// A place row used in the map list and in suggestion sections.
class PlaceTile extends StatelessWidget {
  const PlaceTile({
    super.key,
    required this.place,
    required this.distanceMeters,
    required this.onTap,
    this.selected = false,
    this.note,
  });
  final Place place;
  final double? distanceMeters;
  final VoidCallback onTap;
  final bool selected;
  final String? note;

  @override
  Widget build(BuildContext context) {
    final color = categoryColor(place.category);
    final open = place.hours.isOpenAt(DateTime.now());
    return CardBox(
      onTap: onTap,
      color: selected ? AppColors.redTint : Colors.white,
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: color.withValues(alpha: .12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(categoryIcon(place.category), color: color, size: 28),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  place.name,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                Text(
                  '${place.category.label} · ${describeDistance(distanceMeters)}',
                  style: const TextStyle(
                    color: AppColors.muted,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  place.hours.is24h
                      ? 'Buka 24 jam'
                      : (open
                            ? 'Buka · ${place.hours.rangeLabel}'
                            : 'Tutup · ${place.hours.rangeLabel}'),
                  style: TextStyle(
                    color: open ? AppColors.green : AppColors.muted,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  note ??
                      (place.partner
                          ? 'Partner OtoKu · demo'
                          : 'Lokasi demo · belum diverifikasi'),
                  style: TextStyle(
                    color: place.partner && note == null
                        ? AppColors.green
                        : AppColors.muted,
                    fontSize: 11,
                  ),
                ),
                Text(
                  place.servicesLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: AppColors.muted, fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// "Bengkel terdekat" suggestions, shown from maintenance due items and OBD
/// trouble codes. [task] pre-selects the matching service in Booking layanan.
class NearestBengkelSection extends StatelessWidget {
  const NearestBengkelSection({
    super.key,
    required this.state,
    required this.reason,
    this.task,
    this.limit = 2,
  });
  final OtoKuState state;
  final String reason;
  final String? task;
  final int limit;

  @override
  Widget build(BuildContext context) {
    final services = ServicesScope.of(context);
    final location = services.location;
    return ListenableBuilder(
      listenable: location,
      builder: (context, _) {
        final origin = location.position;
        final results = queryBengkel(state.places, origin).take(limit).toList();
        return Column(
          key: const ValueKey('nearest-bengkel'),
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              reason,
              style: const TextStyle(color: AppColors.muted, fontSize: 13),
            ),
            const SizedBox(height: 8),
            if (origin == null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Aktifkan lokasi untuk mengurutkan bengkel dari yang terdekat.',
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                    TextButton(
                      onPressed: location.request,
                      child: const Text('Aktifkan'),
                    ),
                  ],
                ),
              ),
            for (final r in results)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: PlaceTile(
                  place: r.place,
                  distanceMeters: r.distanceMeters,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => PlaceDetailScreen(
                        state: state,
                        place: r.place,
                        suggestedTask: task,
                      ),
                    ),
                  ),
                ),
              ),
            TextButton.icon(
              onPressed: () => services.goToTab(context, AppServices.tabPeta),
              icon: const Icon(Icons.map_outlined, size: 18),
              label: const Text('Lihat semua di Peta'),
            ),
          ],
        );
      },
    );
  }
}

List<PlaceResult> queryBengkel(List<Place> places, LatLng? origin) =>
    nearestPlaces(places, origin, limit: places.length);
