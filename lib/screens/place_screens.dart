import 'package:flutter/material.dart';

import '../core/geo.dart';
import '../map/places_map.dart';
import '../models/commerce.dart';
import '../models/place.dart';
import '../services/app_services.dart';
import '../state/oto_ku_state.dart';
import '../state/route_planner.dart';
import '../ui/common.dart';
import 'place_widgets.dart';

class PlaceDetailScreen extends StatefulWidget {
  const PlaceDetailScreen({
    super.key,
    required this.state,
    required this.place,
    this.suggestedTask,
  });
  final OtoKuState state;
  final Place place;

  /// Maintenance task or OBD check that led here; pre-selects the service.
  final String? suggestedTask;

  @override
  State<PlaceDetailScreen> createState() => _PlaceDetailScreenState();
}

class _PlaceDetailScreenState extends State<PlaceDetailScreen> {
  RoutePlanner? _planner;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _planner ??= RoutePlanner(ServicesScope.of(context).routing);
  }

  @override
  void dispose() {
    _planner?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final place = widget.place;
    final location = ServicesScope.of(context).location;
    final color = categoryColor(place.category);
    return AppPage(
      title: 'Detail Tempat',
      bottomBar: place.bookingEnabled
          ? SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: FilledButton(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => BookingScreen(
                        state: widget.state,
                        place: place,
                        suggestedTask: widget.suggestedTask,
                      ),
                    ),
                  ),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                  ),
                  child: const Text('Booking Layanan'),
                ),
              ),
            )
          : null,
      child: ScrollPage(
        child: ListenableBuilder(
          listenable: location,
          builder: (context, _) {
            final origin = location.position;
            final distance = origin == null
                ? null
                : distanceMeters(origin, place.position);
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CardBox(
                  color: AppColors.ink,
                  child: SizedBox(
                    height: 120,
                    child: Center(
                      child: Icon(
                        categoryIcon(place.category),
                        color: color == AppColors.red
                            ? AppColors.red
                            : Colors.white,
                        size: 64,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  place.name,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  '${place.category.label} · ${describeDistance(distance)}',
                  key: const ValueKey('place-distance'),
                  style: const TextStyle(color: AppColors.muted),
                ),
                const SizedBox(height: 10),
                Text(
                  place.partner
                      ? 'Partner OtoKu · jam dan layanan belum diverifikasi'
                      : 'Non-partner · jam operasional belum diverifikasi, booking tidak tersedia',
                  style: const TextStyle(color: AppColors.muted),
                ),
                const SectionTitle('Jam operasional'),
                CardBox(
                  child: Row(
                    children: [
                      const Icon(Icons.schedule, color: AppColors.muted),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              place.hours.statusLabel(DateTime.now()),
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            Text(
                              '${place.hours.rangeLabel}${place.hours.closedWeekdays.contains(7) ? ' · Minggu tutup' : ''} (demo)',
                              style: const TextStyle(
                                color: AppColors.muted,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SectionTitle('Alamat'),
                CardBox(child: Text(place.address)),
                SectionTitle(place.isBengkel ? 'Layanan' : 'Tersedia'),
                CardBox(
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final s in place.services)
                        Pill(s, selectedTint: true),
                    ],
                  ),
                ),
                if (place.isBengkel) ...[
                  const SectionTitle('Estimasi layanan (demo)'),
                  for (final offer in place.offers)
                    CardBox(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.build_circle_outlined,
                            color: AppColors.red,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              offer.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          Text(
                            '${formatRupiah(offer.estimate)} · ${offer.minutes} mnt',
                            style: const TextStyle(
                              color: AppColors.muted,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
                const SectionTitle('Rute'),
                RouteActions(place: place, planner: _planner!),
              ],
            );
          },
        ),
      ),
    );
  }
}

class BookingScreen extends StatefulWidget {
  const BookingScreen({
    super.key,
    required this.state,
    required this.place,
    this.suggestedTask,
  });
  final OtoKuState state;
  final Place place;
  final String? suggestedTask;

  @override
  State<BookingScreen> createState() => _BookingState();
}

class _BookingState extends State<BookingScreen> {
  static const times = [
    '08:00',
    '09:00',
    '10:00',
    '11:00',
    '13:00',
    '14:00',
    '15:00',
    '16:00',
  ];
  static const weekdays = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];
  static const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'Mei',
    'Jun',
    'Jul',
    'Agu',
    'Sep',
    'Okt',
    'Nov',
    'Des',
  ];
  final _notes = TextEditingController();
  int day = 0, time = 2;
  late final Set<String> selected;
  bool submitting = false;

  @override
  void initState() {
    super.initState();
    final offers = widget.place.offers;
    final suggested = widget.suggestedTask == null
        ? null
        : widget.place.offerForTask(widget.suggestedTask!);
    selected = {(suggested ?? offers.firstOrNull)?.name ?? ''}..remove('');
  }

  DateTime get selectedDate => widget.state.now.add(Duration(days: day + 1));
  String _dateLabel(DateTime date) =>
      '${weekdays[date.weekday - 1]} ${date.day} ${months[date.month - 1]}';

  @override
  void dispose() {
    _notes.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (submitting) return;
    if (selected.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih minimal satu layanan.')),
      );
      return;
    }
    setState(() => submitting = true);
    try {
      final order = await widget.state.addBooking(
        widget.place,
        services: [
          for (final o in widget.place.offers)
            if (selected.contains(o.name)) o.name,
        ],
        date: selectedDate,
        time: times[time],
        notes: _notes.text,
      );
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute<void>(
          builder: (_) =>
              BookingConfirmationScreen(state: widget.state, order: order),
        ),
      );
    } finally {
      if (mounted) setState(() => submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final vehicle = widget.state.vehicle;
    return AppPage(
      title: 'Booking Layanan',
      bottomBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: FilledButton(
            onPressed: submitting ? null : _submit,
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
            ),
            child: Text(submitting ? 'Menyimpan...' : 'Lanjutkan'),
          ),
        ),
      ),
      child: ScrollPage(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CardBox(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.place.name,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  Text(
                    widget.place.address,
                    style: const TextStyle(color: AppColors.muted),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Kendaraan: ${vehicle.name} · ${vehicle.plate}',
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),
            const SectionTitle('Pilih Layanan'),
            for (final offer in widget.place.offers)
              CardBox(
                key: ValueKey('booking-${offer.id}'),
                onTap: () => setState(
                  () => selected.contains(offer.name)
                      ? selected.remove(offer.name)
                      : selected.add(offer.name),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.build_circle_outlined,
                      color: AppColors.red,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            offer.name,
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          Text(
                            'Estimasi demo ${formatRupiah(offer.estimate)} · ${offer.minutes} menit (demo)',
                            style: const TextStyle(
                              color: AppColors.muted,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      selected.contains(offer.name)
                          ? Icons.check_circle
                          : Icons.radio_button_unchecked,
                      color: selected.contains(offer.name)
                          ? AppColors.red
                          : AppColors.muted,
                    ),
                  ],
                ),
              ),
            const SectionTitle('Pilih Tanggal · jadwal demo'),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: List.generate(5, (i) {
                final date = widget.state.now.add(Duration(days: i + 1));
                return GestureDetector(
                  onTap: () => setState(() => day = i),
                  child: Pill(_dateLabel(date), active: day == i),
                );
              }),
            ),
            const SectionTitle('Pilih Waktu · slot belum dikonfirmasi bengkel'),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final (i, t) in times.indexed)
                  GestureDetector(
                    onTap: () => setState(() => time = i),
                    child: Pill(t, active: time == i),
                  ),
              ],
            ),
            const SectionTitle('Catatan (opsional)'),
            TextField(
              controller: _notes,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'Contoh: minta dicek bagian lain juga',
                filled: true,
                fillColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class BookingConfirmationScreen extends StatelessWidget {
  const BookingConfirmationScreen({
    super.key,
    required this.state,
    required this.order,
  });
  final OtoKuState state;
  final Pesanan order;

  @override
  Widget build(BuildContext context) {
    final services = ServicesScope.of(context);
    return AppPage(
      title: 'Permintaan Booking',
      child: ScrollPage(
        child: Column(
          children: [
            const CardBox(
              color: AppColors.amberTint,
              child: Column(
                children: [
                  Icon(Icons.schedule, color: AppColors.amber, size: 44),
                  SizedBox(height: 10),
                  Text(
                    'Menunggu konfirmasi bengkel',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'Permintaan tersimpan lokal sebagai Pesanan. Jadwal belum dikonfirmasi dan pembayaran belum dilakukan.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.muted),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            CardBox(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    order.id,
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 12,
                    ),
                  ),
                  Text(
                    order.title,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  Text(order.detail),
                ],
              ),
            ),
            const SizedBox(height: 18),
            FilledButton(
              onPressed: () =>
                  services.goToTab(context, AppServices.tabPesanan),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
              ),
              child: const Text('Lihat Pesanan'),
            ),
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: () => services.goToTab(context, AppServices.tabHome),
              child: const Text('Kembali ke Home'),
            ),
          ],
        ),
      ),
    );
  }
}
