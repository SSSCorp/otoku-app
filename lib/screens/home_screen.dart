import 'package:flutter/material.dart';

import '../models/vehicle.dart';
import '../state/oto_ku_state.dart';
import '../ui/common.dart';
import 'maintenance_screens.dart';
import 'obd_screens.dart';
import 'home_sections.dart';
import 'trip_screen.dart';
import 'vehicle_screens.dart';

class HomeVehicleCard extends StatelessWidget {
  final OtoKuState state;
  final VoidCallback onTap;
  const HomeVehicleCard({super.key, required this.state, required this.onTap});
  @override
  Widget build(BuildContext context) {
    final vehicle = state.vehicle;
    final lastService = state.logs
        .where((log) => log['type'] == 'servis')
        .map((log) => DateTime.tryParse('${log['date']}'))
        .whereType<DateTime>()
        .fold<DateTime?>(
          null,
          (latest, d) => latest == null || d.isAfter(latest) ? d : latest,
        );
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.border),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: 174,
                child: Stack(
                  clipBehavior: Clip.hardEdge,
                  children: [
                    const Positioned.fill(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Color(0xFFF0F3FF),
                              Color(0xFFE2E8F8),
                              Color(0xFFDCE2F3),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      right: -7,
                      top: -9,
                      child: Container(
                        width: 180,
                        height: 180,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white.withValues(alpha: .6),
                            width: 1.5,
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      right: 12,
                      top: -18,
                      child: Container(
                        width: 220,
                        height: 220,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white.withValues(alpha: .35),
                            width: 1,
                          ),
                        ),
                      ),
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child:
                          vehicle.brand == 'Honda' &&
                              vehicle.model.toLowerCase().contains('beat')
                          ? Image.asset(
                              'assets/honda_beat.png',
                              width: 194,
                              height: 194,
                              fit: BoxFit.contain,
                              alignment: Alignment.centerRight,
                              semanticLabel: 'Honda Beat merah dan hitam',
                            )
                          : Padding(
                              padding: const EdgeInsets.only(right: 14),
                              child: Icon(
                                vehicle.kind == VehicleKind.mobil
                                    ? Icons.directions_car_filled_outlined
                                    : Icons.two_wheeler_outlined,
                                size: 96,
                                color: AppColors.muted.withValues(alpha: .6),
                              ),
                            ),
                    ),
                    Positioned(
                      left: 16,
                      top: 16,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: .88),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.circle, size: 7, color: AppColors.green),
                            SizedBox(width: 6),
                            Text(
                              'KENDARAAN AKTIF',
                              style: TextStyle(
                                fontSize: 9,
                                letterSpacing: .8,
                                fontWeight: FontWeight.w800,
                                color: AppColors.ink,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Positioned(
                      left: 16,
                      bottom: 16,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.ink,
                          borderRadius: BorderRadius.circular(7),
                        ),
                        child: Text(
                          vehicle.plate,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      right: 12,
                      bottom: 12,
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: .94),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.open_in_full,
                          size: 17,
                          color: AppColors.ink,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 13, 16, 14),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            vehicle.name,
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -.3,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${vehicle.type.isEmpty ? vehicle.kind.label : vehicle.type} · Kendaraan saya',
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.muted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right, color: AppColors.muted),
                  ],
                ),
              ),
              const Divider(height: 1, indent: 16, endIndent: 16),
              Padding(
                padding: const EdgeInsets.fromLTRB(13, 12, 13, 14),
                child: Builder(
                  builder: (context) {
                    final stats = <_VehicleStatData>[
                      _VehicleStatData(
                        icon: Icons.speed_outlined,
                        value: formatKilometers(vehicle.mileage),
                        unit: 'km',
                        label: 'JARAK TEMPUH',
                      ),
                      _VehicleStatData(
                        icon: Icons.build_outlined,
                        value: lastService == null
                            ? 'Belum dicatat'
                            : formatDateId(lastService),
                        unit: '',
                        label: 'SERVIS TERAKHIR',
                      ),
                      _VehicleStatData(
                        icon: Icons.info_outline,
                        value: !state.obdConnected
                            ? 'Belum dicek'
                            : state.obdCodes.isEmpty
                            ? 'Normal (sim.)'
                            : '${state.obdCodes.length} kode (sim.)',
                        unit: '',
                        label: 'KONDISI',
                      ),
                    ];
                    return Row(
                      children: [
                        for (final (index, stat) in stats.indexed) ...[
                          if (index > 0) const SizedBox(width: 6),
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                color: AppColors.surfaceLow,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: _VehicleStat(
                                icon: stat.icon,
                                value: stat.value,
                                unit: stat.unit,
                                label: stat.label,
                              ),
                            ),
                          ),
                        ],
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _VehicleStatData {
  final IconData icon;
  final String value, unit, label;
  const _VehicleStatData({
    required this.icon,
    required this.value,
    required this.unit,
    required this.label,
  });
}

class _VehicleStat extends StatelessWidget {
  final IconData icon;
  final String value, unit, label;
  const _VehicleStat({
    required this.icon,
    required this.value,
    required this.unit,
    required this.label,
  });
  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, size: 15, color: AppColors.muted),
      const SizedBox(height: 4),
      Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: AppColors.ink,
            ),
          ),
          if (unit.isNotEmpty)
            Text(
              ' $unit',
              style: const TextStyle(fontSize: 10, color: AppColors.muted),
            ),
        ],
      ),
      const SizedBox(height: 3),
      Text(
        label,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 8,
          letterSpacing: .45,
          color: AppColors.muted,
          fontWeight: FontWeight.w700,
        ),
      ),
    ],
  );
}

class HomeScreen extends StatelessWidget {
  final OtoKuState state;
  const HomeScreen({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 0),
              child: Row(
                children: [
                  Image.asset(
                    'assets/OtoKu Logo.png',
                    width: 104,
                    height: 36,
                    alignment: Alignment.centerLeft,
                    fit: BoxFit.contain,
                    semanticLabel: 'OtoKu',
                  ),
                  const Spacer(),
                  Stack(
                    children: [
                      IconButton(
                        tooltip: 'Notifikasi',
                        onPressed: () => showNotificationSheet(context, state),
                        icon: const Icon(Icons.notifications_none),
                      ),
                      if (notificationsFor(state).isNotEmpty)
                        const Positioned(
                          top: 10,
                          right: 10,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: AppColors.red,
                              shape: BoxShape.circle,
                            ),
                            child: SizedBox(width: 8, height: 8),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(width: 4),
                  GestureDetector(
                    onTap: () => push(context, VehiclesScreen(state: state)),
                    child: Tooltip(
                      message: 'Kendaraan saya',
                      child: CircleAvatar(
                        radius: 18,
                        backgroundColor: AppColors.red,
                        child: Text(
                          state.vehicle.brand.isEmpty
                              ? 'OK'
                              : state.vehicle.brand
                                    .substring(
                                      0,
                                      state.vehicle.brand.length.clamp(1, 2),
                                    )
                                    .toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                if (state.saveError != null) ...[
                  const CardBox(
                    color: AppColors.redTint,
                    child: Text(
                      'Perubahan terakhir belum tersimpan ke penyimpanan lokal. Coba ulangi.',
                      style: TextStyle(color: AppColors.red),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                HomeVehicleCard(
                  state: state,
                  onTap: () => push(context, VehicleDetailScreen(state: state)),
                ),
                if (state.vehicles.length > 1)
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      onPressed: () =>
                          push(context, VehiclesScreen(state: state)),
                      icon: const Icon(Icons.swap_horiz, size: 18),
                      label: Text('Ganti kendaraan (${state.vehicles.length})'),
                    ),
                  ),
                const SizedBox(height: 12),
                MaintenanceCard(
                  state: state,
                  onTap: () => push(context, MaintenanceScreen(state: state)),
                ),
                SectionTitle(
                  'Perjalanan',
                  action: 'Lihat Semua',
                  onTap: () => push(context, TripScreen(state: state)),
                ),
                HomeTripCard(state: state),
                HomeActivitySection(state: state),
                const SizedBox(height: 24),
                state.obdConnected
                    ? ConnectedObdCard(state: state)
                    : HomeObdPromo(state: state),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

class ConnectedObdCard extends StatelessWidget {
  final OtoKuState state;
  const ConnectedObdCard({super.key, required this.state});
  @override
  Widget build(BuildContext context) => CardBox(
    color: AppColors.greenTint,
    onTap: () => openObd(context, state),
    child: Row(
      children: [
        const Icon(Icons.check_circle, color: AppColors.green),
        const SizedBox(width: 10),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'OBD Demo Aktif',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
              Text(
                'Data simulasi — bukan data kendaraan langsung',
                style: TextStyle(color: AppColors.muted, fontSize: 12),
              ),
            ],
          ),
        ),
        const Icon(Icons.chevron_right),
      ],
    ),
  );
}

class MaintenanceCard extends StatelessWidget {
  final OtoKuState state;
  final VoidCallback onTap;
  const MaintenanceCard({super.key, required this.state, required this.onTap});
  @override
  Widget build(BuildContext context) {
    final next = state.nextMaintenance;
    final ok = next.level == DueLevel.ok;
    return CardBox(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: ok ? AppColors.greenTint : AppColors.amberTint,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              ok ? next.task.icon : Icons.warning_amber_rounded,
              size: 20,
              color: ok ? AppColors.green : AppColors.ink,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'PERAWATAN BERIKUTNYA',
                  style: TextStyle(
                    fontSize: 10,
                    letterSpacing: .8,
                    fontWeight: FontWeight.w800,
                    color: AppColors.muted,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  next.task.title,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  dueText(next),
                  style: const TextStyle(color: AppColors.muted, fontSize: 12),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: AppColors.muted),
        ],
      ),
    );
  }
}

/// Reminders derived from local data: due maintenance, pending bookings,
/// simulated OBD codes and items waiting in the cart.
List<({IconData icon, String title, String body})> notificationsFor(
  OtoKuState state,
) => [
  for (final s in state.maintenanceNeedingAttention)
    (
      icon: Icons.build_outlined,
      title: '${s.task.title} · ${dueChipLabel(s.level)}',
      body: dueText(s),
    ),
  for (final o in state.orders.where((o) => !o.isFinal))
    (
      icon: Icons.receipt_long_outlined,
      title: '${o.title} · ${o.status}',
      body: o.id,
    ),
  if (state.obdConnected && state.obdCodes.isNotEmpty)
    (
      icon: Icons.sensors,
      title: 'Kode masalah OBD (simulasi)',
      body: state.obdCodes.join(', '),
    ),
  if (state.cart.isNotEmpty)
    (
      icon: Icons.shopping_bag_outlined,
      title: 'Keranjang belum di-checkout',
      body: '${state.cart.length} produk menunggu.',
    ),
];

void showNotificationSheet(BuildContext context, OtoKuState state) {
  final items = notificationsFor(state);
  showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (_) => Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Notifikasi',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 12),
          if (items.isEmpty)
            const ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.notifications_none, color: AppColors.muted),
              title: Text('Belum ada notifikasi'),
              subtitle: Text(
                'Pengingat perawatan, booking, dan pesanan akan muncul di sini.',
              ),
            ),
          for (final item in items)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(item.icon, color: AppColors.red),
              title: Text(item.title),
              subtitle: Text(item.body),
            ),
        ],
      ),
    ),
  );
}
