import 'package:flutter/material.dart';

import '../core/geo.dart';
import '../models/trip.dart';
import '../services/app_services.dart';
import '../state/oto_ku_state.dart';
import '../ui/common.dart';
import 'maintenance_screens.dart';
import 'obd_screens.dart';
import 'trip_screen.dart';

const _weekdays = [
  'Senin',
  'Selasa',
  'Rabu',
  'Kamis',
  'Jumat',
  'Sabtu',
  'Minggu',
];
const _months = [
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

String _two(int n) => n.toString().padLeft(2, '0');
String _clock(DateTime d) => '${_two(d.hour)}:${_two(d.minute)}';
String _km1(double km) => km.toStringAsFixed(1).replaceAll('.', ',');
bool _sameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

String _dayLabel(DateTime d, DateTime now) {
  final base = '${_weekdays[d.weekday - 1]}, ${d.day} ${_months[d.month - 1]}'
      .toUpperCase();
  if (_sameDay(d, now)) return 'HARI INI · $base';
  if (_sameDay(d, now.subtract(const Duration(days: 1)))) {
    return 'KEMARIN · $base';
  }
  return base;
}

String _longDuration(int seconds) {
  final minutes = (seconds / 60).round();
  if (minutes < 60) return '$minutes m';
  return '${minutes ~/ 60} j ${minutes % 60} m';
}

/// Trip summary for the last seven days, with the main "start trip" action.
class HomeTripCard extends StatelessWidget {
  const HomeTripCard({super.key, required this.state});
  final OtoKuState state;

  Future<void> _addToMileage(BuildContext context, Trip trip) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final reading = await state.addTripToMileage(trip.id);
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              'Jarak tempuh menjadi ${formatKilometers(reading)} km.',
            ),
          ),
        );
    } catch (_) {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(content: Text('Trip belum bisa ditambahkan.')),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final now = state.now;
    final today = DateTime(now.year, now.month, now.day);
    final days = [
      for (var i = 6; i >= 0; i--) today.subtract(Duration(days: i)),
    ];
    final trips = state.activeTrips;
    final perDay = [
      for (final day in days)
        trips
            .where((t) => _sameDay(t.startedAt, day))
            .fold<double>(0, (sum, t) => sum + t.km),
    ];
    final week = trips.where(
      (t) => !t.startedAt.isBefore(days.first) && !t.startedAt.isAfter(now),
    );
    final totalKm = week.fold<double>(0, (sum, t) => sum + t.km);
    final totalSeconds = week.fold<int>(0, (sum, t) => sum + t.durationSeconds);
    final maxKm = perDay.fold<double>(0, (m, v) => v > m ? v : m);
    Trip? pending;
    for (final t in trips) {
      if (!t.addedToMileage && t.roundedKm >= 1) {
        pending = t;
        break;
      }
    }

    return CardBox(
      key: const ValueKey('home-trip-card'),
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '7 HARI TERAKHIR',
                        style: TextStyle(
                          fontSize: 10,
                          letterSpacing: .8,
                          fontWeight: FontWeight.w800,
                          color: AppColors.muted,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(
                              text: _km1(totalKm),
                              style: const TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -1,
                                height: 1,
                              ),
                            ),
                            const TextSpan(
                              text: ' km',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: AppColors.muted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        week.isEmpty
                            ? 'Belum ada trip minggu ini'
                            : '${week.length} trip · ${_longDuration(totalSeconds)} di jalan',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.muted,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Semantics(
                  label: 'Grafik jarak 7 hari terakhir',
                  child: SizedBox(
                    height: 76,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        for (var i = 0; i < 7; i++) ...[
                          if (i > 0) const SizedBox(width: 7),
                          _Bar(
                            km: perDay[i],
                            maxKm: maxKm,
                            label: _weekdays[days[i].weekday - 1].substring(
                              0,
                              3,
                            ),
                            today: i == 6,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, indent: 16, endIndent: 16),
          if (pending != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 12, 10),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppColors.redTint,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.route_outlined,
                      size: 18,
                      color: AppColors.red,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Trip ${_sameDay(pending.startedAt, now) ? 'hari ini' : '${pending.startedAt.day} ${_months[pending.startedAt.month - 1]}'} · ${_km1(pending.km)} km',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const Text(
                          'Belum ditambahkan ke jarak tempuh',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.muted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  OutlinedButton(
                    key: const ValueKey('home-trip-add'),
                    onPressed: () => _addToMileage(context, pending!),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(0, 44),
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      foregroundColor: AppColors.red,
                      side: const BorderSide(color: AppColors.red, width: 1.5),
                    ),
                    child: const Text(
                      'Tambah',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            )
          else if (trips.isEmpty)
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Text(
                'Belum ada trip. Rekam perjalananmu untuk mencatat jarak dan durasi.',
                style: TextStyle(fontSize: 12, color: AppColors.muted),
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: FilledButton.icon(
              key: const ValueKey('home-trip-start'),
              onPressed: () => push(context, TripScreen(state: state)),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
              ),
              icon: const Icon(Icons.play_arrow_rounded, size: 22),
              label: const Text('Mulai Trip GPS'),
            ),
          ),
        ],
      ),
    );
  }
}

class _Bar extends StatelessWidget {
  const _Bar({
    required this.km,
    required this.maxKm,
    required this.label,
    required this.today,
  });
  final double km, maxKm;
  final String label;
  final bool today;

  @override
  Widget build(BuildContext context) {
    final height = km <= 0 || maxKm <= 0
        ? 4.0
        : (km / maxKm * 52).clamp(8.0, 52.0);
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Container(
          width: 16,
          height: height,
          decoration: BoxDecoration(
            color: today
                ? AppColors.red
                : (km <= 0 ? AppColors.surfaceHigh : const Color(0xFFC5CDE4)),
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(5),
              bottom: Radius.circular(3),
            ),
          ),
        ),
        const SizedBox(height: 5),
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: AppColors.muted,
          ),
        ),
      ],
    );
  }
}

class _Entry {
  const _Entry({
    required this.kind,
    required this.title,
    required this.meta,
    required this.date,
    required this.onTap,
    this.value,
  });
  final String kind, title, meta;
  final String? value;
  final DateTime date;
  final void Function(BuildContext) onTap;
}

/// Quick-add tiles plus one timeline mixing logs and trips.
class HomeActivitySection extends StatefulWidget {
  const HomeActivitySection({super.key, required this.state});
  final OtoKuState state;

  @override
  State<HomeActivitySection> createState() => _HomeActivitySectionState();
}

class _HomeActivitySectionState extends State<HomeActivitySection> {
  static const _filters = [
    ('semua', 'Semua'),
    ('trip', 'Trip'),
    ('bbm', 'BBM'),
    ('servis', 'Servis'),
    ('biaya', 'Biaya'),
  ];
  String _filter = 'semua';

  OtoKuState get state => widget.state;

  List<_Entry> _entries() {
    final entries = <_Entry>[];
    for (final log in state.logs) {
      final type = (log['type'] ?? '').toString();
      if (type == 'odometer' && log['source'] == 'trip') continue;
      final date = DateTime.tryParse((log['date'] ?? '').toString());
      if (date == null) continue;
      final volume = log['volume'];
      final mileage = log['mileage'] ?? log['value'];
      final amount = log['amount'];
      final details = <String>[
        _clock(date),
        if (volume is num)
          '${volume.toStringAsFixed(1).replaceAll('.', ',')} L',
        if (mileage is num) '${formatKilometers(mileage.toInt())} km',
      ];
      entries.add(
        _Entry(
          kind: type == 'odometer' ? 'kilometer' : type,
          title: (log['title'] ?? 'Catatan').toString(),
          meta: details.join(' · '),
          date: date,
          value: amount is num && amount > 0
              ? formatRupiah(amount.toInt())
              : null,
          onTap: (c) => push(c, HistoryScreen(state: state)),
        ),
      );
    }
    for (final t in state.activeTrips) {
      entries.add(
        _Entry(
          kind: 'trip',
          title: 'Trip GPS · ${_km1(t.km)} km',
          meta:
              '${_clock(t.startedAt)} – ${_clock(t.endedAt)} · ${formatDuration(Duration(seconds: t.durationSeconds))}',
          date: t.startedAt,
          value: null,
          onTap: (c) => push(c, TripScreen(state: state)),
        ),
      );
    }
    entries.sort((a, b) => b.date.compareTo(a.date));
    return entries
        .where((e) => _filter == 'semua' || e.kind == _filter)
        .take(8)
        .toList();
  }

  void _add(String type) =>
      push(context, ManualLogScreen(state: state, initialType: type));

  @override
  Widget build(BuildContext context) {
    final entries = _entries();
    final now = state.now;
    final groups = <(String, List<_Entry>)>[];
    for (final e in entries) {
      final label = _dayLabel(e.date, now);
      if (groups.isNotEmpty && groups.last.$1 == label) {
        groups.last.$2.add(e);
      } else {
        groups.add((label, [e]));
      }
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionTitle(
          'Aktivitas',
          action: 'Riwayat Lengkap',
          onTap: () => push(context, HistoryScreen(state: state)),
        ),
        Row(
          children: [
            _QuickTile(
              key: const ValueKey('quick-bbm'),
              icon: Icons.local_gas_station_outlined,
              label: 'BBM',
              color: const Color(0xFF1565C0),
              onTap: () => _add('bbm'),
            ),
            const SizedBox(width: 8),
            _QuickTile(
              key: const ValueKey('quick-servis'),
              icon: Icons.build_outlined,
              label: 'Servis',
              color: AppColors.green,
              onTap: () => _add('servis'),
            ),
            const SizedBox(width: 8),
            _QuickTile(
              key: const ValueKey('quick-biaya'),
              icon: Icons.payments_outlined,
              label: 'Biaya',
              color: AppColors.ink,
              onTap: () => _add('biaya'),
            ),
            const SizedBox(width: 8),
            _QuickTile(
              key: const ValueKey('quick-kilometer'),
              icon: Icons.speed_outlined,
              label: 'Kilometer',
              color: AppColors.red,
              onTap: () => _add('kilometer'),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: [
            for (final (key, label) in _filters)
              InkWell(
                onTap: () => setState(() => _filter = key),
                borderRadius: BorderRadius.circular(22),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Pill(label, active: _filter == key),
                ),
              ),
          ],
        ),
        const SizedBox(height: 10),
        CardBox(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (groups.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  child: Text(
                    _filter == 'semua'
                        ? 'Belum ada aktivitas. Tambahkan kilometer, BBM, servis, atau biaya, atau rekam trip.'
                        : 'Belum ada aktivitas untuk filter ini.',
                    style: const TextStyle(color: AppColors.muted),
                  ),
                ),
              for (final (label, items) in groups) ...[
                Padding(
                  padding: const EdgeInsets.only(top: 14, bottom: 10),
                  child: Text(
                    label,
                    style: const TextStyle(
                      fontSize: 10,
                      letterSpacing: .8,
                      fontWeight: FontWeight.w800,
                      color: AppColors.muted,
                    ),
                  ),
                ),
                for (final (i, e) in items.indexed)
                  _TimelineRow(entry: e, last: i == items.length - 1),
              ],
              if (groups.isNotEmpty) ...[
                const Divider(height: 1),
                TextButton(
                  key: const ValueKey('home-activity-all'),
                  onPressed: () => push(context, HistoryScreen(state: state)),
                  style: TextButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                  ),
                  child: const Text(
                    'Lihat Semua Aktivitas',
                    style: TextStyle(
                      color: AppColors.red,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _QuickTile extends StatelessWidget {
  const _QuickTile({
    super.key,
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Expanded(
    child: Material(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: AppColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          height: 68,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 20, color: color),
              const SizedBox(height: 5),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class _TimelineRow extends StatelessWidget {
  const _TimelineRow({required this.entry, required this.last});
  final _Entry entry;
  final bool last;

  (IconData, Color, Color) get _style => switch (entry.kind) {
    'trip' => (Icons.route_outlined, AppColors.red, AppColors.redTint),
    'bbm' => (
      Icons.local_gas_station_outlined,
      const Color(0xFF1565C0),
      const Color(0xFFE3F0FF),
    ),
    'servis' => (Icons.build_outlined, AppColors.green, AppColors.greenTint),
    'sparepart' => (
      Icons.tire_repair_outlined,
      AppColors.ink,
      AppColors.amberTint,
    ),
    'biaya' => (Icons.payments_outlined, AppColors.ink, AppColors.amberTint),
    _ => (Icons.speed_outlined, AppColors.red, AppColors.redTint),
  };

  @override
  Widget build(BuildContext context) {
    final (icon, fg, bg) = _style;
    return InkWell(
      onTap: () => entry.onTap(context),
      borderRadius: BorderRadius.circular(12),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              width: 36,
              child: Column(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: bg,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, size: 18, color: fg),
                  ),
                  if (!last)
                    Expanded(
                      child: Container(
                        width: 2,
                        margin: const EdgeInsets.only(top: 4),
                        color: AppColors.border,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Padding(
                padding: EdgeInsets.only(bottom: last ? 8 : 16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            entry.title,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              height: 1.3,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            entry.meta,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.muted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (entry.value != null)
                      Padding(
                        padding: const EdgeInsets.only(left: 10),
                        child: Text(
                          entry.value!,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Promotional card for the OBD adapter; the shop button jumps to Toko.
class HomeObdPromo extends StatelessWidget {
  const HomeObdPromo({super.key, required this.state});
  final OtoKuState state;

  @override
  Widget build(BuildContext context) => Container(
    key: const ValueKey('home-obd-promo'),
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(16),
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [AppColors.navy, AppColors.darkSurface],
      ),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'PROMO · ADAPTOR OBD',
          style: TextStyle(
            fontSize: 10,
            letterSpacing: .8,
            fontWeight: FontWeight.w800,
            color: Color(0xFFFFB3B6),
          ),
        ),
        const SizedBox(height: 3),
        const Text(
          'Adaptor OBD OtoKu',
          style: TextStyle(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 2),
        const Text(
          'Pantau RPM, suhu mesin, dan kode masalah dengan bahasa sederhana.',
          style: TextStyle(
            color: Color(0xFFD9DCE3),
            fontSize: 12,
            height: 1.35,
          ),
        ),
        TextButton(
          key: const ValueKey('home-obd-try'),
          onPressed: () => openObd(context, state),
          style: TextButton.styleFrom(
            minimumSize: const Size(0, 36),
            padding: const EdgeInsets.symmetric(horizontal: 2),
            tapTargetSize: MaterialTapTargetSize.padded,
            foregroundColor: const Color(0xFFD9DCE3),
          ),
          child: const Text(
            'Coba simulasinya dulu',
            style: TextStyle(
              fontSize: 12,
              decoration: TextDecoration.underline,
              decorationColor: Color(0xFFD9DCE3),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Harga',
                    style: TextStyle(color: Color(0xFFD9DCE3), fontSize: 11),
                  ),
                  Text(
                    'Rp 179.000',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -.5,
                    ),
                  ),
                ],
              ),
            ),
            FilledButton.icon(
              key: const ValueKey('home-obd-shop'),
              onPressed: () =>
                  ServicesScope.of(context)
                      .goToTab(context, AppServices.tabShop),
              style: FilledButton.styleFrom(
                minimumSize: const Size(0, 48),
                padding: const EdgeInsets.symmetric(horizontal: 16),
              ),
              iconAlignment: IconAlignment.end,
              icon: const Icon(Icons.arrow_forward, size: 16),
              label: const Text('Lihat di Toko'),
            ),
          ],
        ),
      ],
    ),
  );
}
