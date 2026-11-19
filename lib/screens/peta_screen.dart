import 'package:flutter/material.dart';

import '../core/geo.dart';
import '../core/places_query.dart';
import '../map/places_map.dart';
import '../models/place.dart';
import '../services/app_services.dart';
import '../services/location_service.dart';
import '../state/oto_ku_state.dart';
import '../state/route_planner.dart';
import '../ui/common.dart';
import 'place_screens.dart';
import 'place_widgets.dart';
import 'trip_screen.dart';

/// Peta tab: a real map (OpenStreetMap by default) with the user's live
/// position, clustered markers, search, filters, distance sorting and routes.
class PetaScreen extends StatefulWidget {
  const PetaScreen({super.key, required this.state});
  final OtoKuState state;

  @override
  State<PetaScreen> createState() => _PetaScreenState();
}

class _PetaScreenState extends State<PetaScreen> {
  final _map = PlacesMapController();
  final _search = TextEditingController();
  RoutePlanner? _planner;
  AppServices? _services;
  PlaceFilter _filter = PlaceFilter.all;
  PlaceSort _sort = PlaceSort.distance;
  String _query = '';
  String? _selectedId;
  bool _online = true;
  bool _tilesFailed = false;
  bool _centered = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_services == null) {
      final services = _services = ServicesScope.of(context);
      _planner = RoutePlanner(services.routing)..addListener(_onRoute);
      services.location.addListener(_onLocation);
      _boot(services);
    }
  }

  Future<void> _boot(AppServices services) async {
    final location = services.location;
    if (location.access == LocationAccess.unknown) await location.refresh();
    if (location.access == LocationAccess.denied ||
        location.access == LocationAccess.unknown) {
      await location.request();
    }
    _checkNetwork();
  }

  Future<void> _checkNetwork() async {
    final online = await _services!.network.isOnline();
    if (!mounted) return;
    setState(() {
      _online = online;
      if (online) _tilesFailed = false;
    });
  }

  void _onLocation() {
    if (!mounted) return;
    final position = _services!.location.position;
    if (position != null && !_centered) {
      _centered = true;
      final near = distanceMeters(position, Place.demoCenter) < 60000;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        near
            ? _map.moveTo(position, zoom: 14.5)
            : _map.fitPoints([Place.demoCenter]);
      });
    }
    setState(() {});
  }

  void _onRoute() {
    if (!mounted) return;
    final route = _planner!.result;
    if (route != null && route.points.length > 1) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _map.fitPoints(route.points),
      );
    }
    setState(() {});
  }

  @override
  void dispose() {
    _services?.location.removeListener(_onLocation);
    _planner?.removeListener(_onRoute);
    _planner?.dispose();
    _search.dispose();
    super.dispose();
  }

  void _select(Place place) {
    if (_selectedId != place.id) _planner?.clear();
    setState(() => _selectedId = place.id);
  }

  Future<void> _recenter() async {
    final location = _services!.location;
    if (location.position == null) {
      await location.request();
    }
    final position = location.position;
    if (position == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            location.problemMessage ??
                'Posisimu belum tersedia. Coba lagi sebentar.',
          ),
        ),
      );
      return;
    }
    _map.moveTo(position, zoom: 16);
  }

  @override
  Widget build(BuildContext context) {
    final services = _services!;
    final location = services.location;
    final origin = location.position;
    final results = queryPlaces(
      widget.state.places,
      origin: origin,
      search: _query,
      filter: _filter,
      sort: _sort,
    );
    final selected = results
        .where((r) => r.place.id == _selectedId)
        .firstOrNull;
    final farFromDemo =
        origin != null && distanceMeters(origin, Place.demoCenter) > 60000;
    final height = MediaQuery.sizeOf(context).height;
    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 8, 0),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'Peta & Tempat',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
                  ),
                ),
                TextButton.icon(
                  key: const ValueKey('open-trip'),
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => TripScreen(state: widget.state),
                    ),
                  ),
                  icon: const Icon(Icons.route_outlined, size: 18),
                  label: const Text('Trip GPS'),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              children: [
                Text(
                  origin == null
                      ? 'Bekasi Utara · data tempat demo'
                      : 'Posisimu aktif · data tempat demo di Bekasi Utara',
                  style: const TextStyle(color: AppColors.muted, fontSize: 13),
                ),
                const SizedBox(height: 8),
                ..._banners(farFromDemo),
                TextField(
                  controller: _search,
                  onChanged: (value) => setState(() => _query = value),
                  decoration: InputDecoration(
                    hintText: 'Cari bengkel, SPBU, minimarket...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _query.isEmpty
                        ? null
                        : IconButton(
                            tooltip: 'Hapus pencarian',
                            icon: const Icon(Icons.close),
                            onPressed: () {
                              _search.clear();
                              setState(() => _query = '');
                            },
                          ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                ),
                const SizedBox(height: 10),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      for (final f in [
                        PlaceFilter.all,
                        PlaceFilter.bengkelPartner,
                        PlaceFilter.bengkelOther,
                        PlaceFilter.minimarket,
                        PlaceFilter.spbu,
                      ])
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text(f.label),
                            selected: _filter == f,
                            onSelected: (_) => setState(() => _filter = f),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: SizedBox(
                    key: const ValueKey('map-box'),
                    height: (height * .36).clamp(220, 340),
                    child: Stack(
                      children: [
                        PlacesMapView(
                          provider: services.config.effectiveProvider,
                          places: [for (final r in results) r.place],
                          controller: _map,
                          initialCenter: origin != null && !farFromDemo
                              ? origin
                              : Place.demoCenter,
                          onSelect: _select,
                          selectedId: _selectedId,
                          user: origin,
                          userAccuracy: location.fix?.accuracy,
                          route: _planner?.forPlaceId == _selectedId
                              ? _planner?.result?.points
                              : null,
                          tilesEnabled: services.tilesEnabled,
                          onTilesFailed: () {
                            if (!_tilesFailed && mounted) {
                              setState(() => _tilesFailed = true);
                              _checkNetwork();
                            }
                          },
                        ),
                        Positioned(
                          right: 10,
                          bottom: 28,
                          child: Column(
                            children: [
                              _MapButton(
                                key: const ValueKey('fit-places'),
                                tooltip: 'Lihat semua tempat',
                                icon: Icons.zoom_out_map,
                                onTap: () => _map.fitPoints([
                                  for (final r in results) r.place.position,
                                  ?origin,
                                ]),
                              ),
                              const SizedBox(height: 8),
                              _MapButton(
                                key: const ValueKey('recenter'),
                                tooltip: 'Posisi saya',
                                icon: origin == null
                                    ? Icons.location_searching
                                    : Icons.my_location,
                                onTap: _recenter,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (selected != null) ...[
                  const SizedBox(height: 10),
                  _SelectedCard(
                    key: const ValueKey('selected-place'),
                    result: selected,
                    planner: _planner!,
                    onDetail: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => PlaceDetailScreen(
                          state: widget.state,
                          place: selected.place,
                        ),
                      ),
                    ),
                    onClose: () {
                      _planner?.clear();
                      setState(() => _selectedId = null);
                    },
                  ),
                ],
                const SizedBox(height: 12),
                Row(
                  children: [
                    Text(
                      '${results.length} tempat',
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    const Spacer(),
                    for (final s in PlaceSort.values)
                      Padding(
                        padding: const EdgeInsets.only(left: 6),
                        child: ChoiceChip(
                          visualDensity: VisualDensity.compact,
                          label: Text(
                            s.label,
                            style: const TextStyle(fontSize: 12),
                          ),
                          selected: _sort == s,
                          onSelected: (_) => setState(() => _sort = s),
                        ),
                      ),
                  ],
                ),
                if (_sort == PlaceSort.distance && origin == null)
                  const Padding(
                    padding: EdgeInsets.only(top: 4),
                    child: Text(
                      'Urutan jarak aktif setelah lokasi tersedia.',
                      style: TextStyle(color: AppColors.muted, fontSize: 12),
                    ),
                  ),
                const SizedBox(height: 8),
                if (results.isEmpty)
                  CardBox(
                    child: Column(
                      children: [
                        const Icon(
                          Icons.search_off_outlined,
                          size: 34,
                          color: AppColors.muted,
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Tempat tidak ditemukan',
                          style: TextStyle(fontWeight: FontWeight.w800),
                        ),
                        const Text(
                          'Coba kata kunci atau filter lain.',
                          style: TextStyle(color: AppColors.muted),
                        ),
                        TextButton(
                          onPressed: () {
                            _search.clear();
                            setState(() {
                              _query = '';
                              _filter = PlaceFilter.all;
                            });
                          },
                          child: const Text('Reset pencarian'),
                        ),
                      ],
                    ),
                  ),
                for (final r in results)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: PlaceTile(
                      place: r.place,
                      distanceMeters: r.distanceMeters,
                      selected: r.place.id == _selectedId,
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => PlaceDetailScreen(
                            state: widget.state,
                            place: r.place,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _banners(bool farFromDemo) {
    final services = _services!;
    final problem = services.location.checking
        ? null
        : services.location.problemMessage;
    return [
      if (problem != null)
        _Notice(
          key: const ValueKey('location-problem'),
          icon: Icons.location_off_outlined,
          message: problem,
          actionLabel: switch (services.location.access) {
            LocationAccess.deniedForever => 'Buka Pengaturan',
            LocationAccess.serviceOff => 'Nyalakan GPS',
            _ => 'Izinkan lokasi',
          },
          onAction: () => switch (services.location.access) {
            LocationAccess.deniedForever => services.location.openAppSettings(),
            LocationAccess.serviceOff =>
              services.location.openLocationSettings().then(
                (_) => services.location.refresh(),
              ),
            _ => services.location.request(),
          },
        ),
      if (!_online || _tilesFailed)
        _Notice(
          key: const ValueKey('offline-notice'),
          icon: Icons.wifi_off,
          message: !_online
              ? 'Kamu sedang offline. Peta dasar tidak bisa dimuat, tetapi daftar tempat dan jarak tetap tersedia.'
              : 'Sebagian peta belum termuat. Periksa koneksi internet.',
          actionLabel: 'Coba lagi',
          onAction: _checkNetwork,
        ),
      if (services.config.googleFellBack)
        const _Notice(
          key: ValueKey('google-fallback'),
          icon: Icons.info_outline,
          message: 'MAP_PROVIDER=google tetapi GOOGLE_MAPS_API_KEY belum diisi, jadi peta OpenStreetMap dipakai.',
        ),
      if (farFromDemo)
        _Notice(
          key: const ValueKey('far-from-demo'),
          icon: Icons.explore_outlined,
          message: 'Tempat demo berada di Bekasi Utara, jauh dari posisimu. Jarak tetap dihitung dari posisimu saat ini.',
          actionLabel: 'Lihat area demo',
          onAction: () =>
              _map.fitPoints([for (final p in widget.state.places) p.position]),
        ),
    ];
  }
}

class _Notice extends StatelessWidget {
  const _Notice({
    super.key,
    required this.icon,
    required this.message,
    this.actionLabel,
    this.onAction,
  });
  final IconData icon;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 10),
    padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
    decoration: BoxDecoration(
      color: AppColors.amberTint,
      borderRadius: BorderRadius.circular(14),
    ),
    child: Row(
      children: [
        Icon(icon, color: AppColors.amber),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            message,
            style: const TextStyle(fontSize: 12.5, height: 1.35),
          ),
        ),
        if (actionLabel != null)
          TextButton(
            onPressed: onAction,
            child: Text(actionLabel!, textAlign: TextAlign.center),
          ),
      ],
    ),
  );
}

class _MapButton extends StatelessWidget {
  const _MapButton({
    super.key,
    required this.tooltip,
    required this.icon,
    required this.onTap,
  });
  final String tooltip;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.white,
    elevation: 3,
    shape: const CircleBorder(),
    child: IconButton(
      tooltip: tooltip,
      onPressed: onTap,
      icon: Icon(icon, color: AppColors.ink),
    ),
  );
}

class _SelectedCard extends StatelessWidget {
  const _SelectedCard({
    super.key,
    required this.result,
    required this.planner,
    required this.onDetail,
    required this.onClose,
  });
  final PlaceResult result;
  final RoutePlanner planner;
  final VoidCallback onDetail, onClose;

  @override
  Widget build(BuildContext context) {
    final place = result.place;
    return CardBox(
      onTap: onDetail,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                categoryIcon(place.category),
                color: categoryColor(place.category),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  place.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Tutup',
                visualDensity: VisualDensity.compact,
                onPressed: onClose,
                icon: const Icon(Icons.close, size: 20),
              ),
            ],
          ),
          Text(
            '${place.category.label} · ${describeDistance(result.distanceMeters)}',
            style: const TextStyle(
              color: AppColors.muted,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            place.hours.statusLabel(DateTime.now()),
            style: const TextStyle(fontSize: 12.5),
          ),
          Text(
            place.servicesLabel,
            style: const TextStyle(color: AppColors.muted, fontSize: 12),
          ),
          const SizedBox(height: 10),
          RouteActions(place: place, planner: planner, compact: true),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: onDetail,
              child: const Text('Detail tempat →'),
            ),
          ),
        ],
      ),
    );
  }
}
