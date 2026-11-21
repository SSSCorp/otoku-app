import 'dart:async';

import 'package:flutter/material.dart';

import '../models/obd.dart';
import '../services/app_services.dart';
import '../state/oto_ku_state.dart';
import '../ui/common.dart';
import 'place_widgets.dart';

/// Delays of the simulated adapter flow; tests set these to zero.
class ObdSimulationTiming {
  static Duration scan = const Duration(milliseconds: 1800);
  static Duration connect = const Duration(milliseconds: 1200);
}

/// Opens the OBD screen when the simulated adapter is connected, otherwise the
/// connect flow.
void openObd(BuildContext context, OtoKuState state) {
  if (state.obdConnected) {
    Navigator.of(context)
        .push(MaterialPageRoute<void>(builder: (_) => ObdScreen(state: state)));
  } else {
    showObdSheet(context, state);
  }
}

void showObdSheet(BuildContext context, OtoKuState state) =>
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (_) => ObdConnectSheet(state: state),
    );

enum _Phase { idle, scanning, found, connecting }

/// Simulated adapter flow: scan → pick an adapter → connect. Nothing talks to
/// real hardware; the sheet and every screen after it say so.
class ObdConnectSheet extends StatefulWidget {
  const ObdConnectSheet({super.key, required this.state});
  final OtoKuState state;

  @override
  State<ObdConnectSheet> createState() => _ObdConnectSheetState();
}

class _ObdConnectSheetState extends State<ObdConnectSheet> {
  _Phase phase = _Phase.idle;
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _scan() {
    setState(() => phase = _Phase.scanning);
    _timer = Timer(ObdSimulationTiming.scan, () {
      if (mounted) setState(() => phase = _Phase.found);
    });
  }

  void _connect(SimulatedAdapter adapter) {
    setState(() => phase = _Phase.connecting);
    _timer = Timer(ObdSimulationTiming.connect, () async {
      await widget.state.connectObd(adapter: adapter.name);
      if (mounted) Navigator.pop(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        0,
        20,
        28 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const StatusChip(
            'SIMULASI · bukan perangkat OBD asli',
            AppColors.amber,
          ),
          const SizedBox(height: 10),
          Text(
            state.obdConnected
                ? 'Simulasi OBD aktif'
                : 'Coba simulasi data OBD',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 8),
          if (state.obdConnected) ...[
            Text(
              'Terhubung ke ${state.obdAdapter ?? 'adaptor simulasi'}. Data ini contoh, bukan pembacaan langsung dari kendaraan.',
              style: const TextStyle(color: AppColors.muted, height: 1.4),
            ),
            const SizedBox(height: 18),
            FilledButton(
              onPressed: () async {
                await state.disconnectObd();
                if (context.mounted) Navigator.pop(context);
              },
              child: const Text('Tutup simulasi'),
            ),
          ] else
            switch (phase) {
              _Phase.idle => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Lihat contoh RPM, suhu mesin, dan kode masalah dengan penjelasan. Tidak ada Bluetooth atau perangkat OBD yang dipakai.',
                    style: TextStyle(color: AppColors.muted, height: 1.4),
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _scan,
                      child: const Text('Cari adaptor (simulasi)'),
                    ),
                  ),
                ],
              ),
              _Phase.scanning => const Padding(
                padding: EdgeInsets.symmetric(vertical: 18),
                child: Row(
                  children: [
                    SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2.5),
                    ),
                    SizedBox(width: 14),
                    Text('Mencari adaptor simulasi…'),
                  ],
                ),
              ),
              _Phase.found => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Adaptor simulasi ditemukan. Pilih salah satu:',
                    style: TextStyle(color: AppColors.muted),
                  ),
                  const SizedBox(height: 8),
                  for (final adapter in SimulatedAdapter.found)
                    ListTile(
                      key: ValueKey('adapter-${adapter.id}'),
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(
                        Icons.bluetooth,
                        color: AppColors.red,
                      ),
                      title: Text(
                        adapter.name,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      subtitle: Text(
                        'Sinyal ${'●' * adapter.signal}${'○' * (3 - adapter.signal)}',
                      ),
                      trailing: const Text(
                        'Hubungkan',
                        style: TextStyle(
                          color: AppColors.red,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      onTap: () => _connect(adapter),
                    ),
                ],
              ),
              _Phase.connecting => const Padding(
                padding: EdgeInsets.symmetric(vertical: 18),
                child: Row(
                  children: [
                    SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2.5),
                    ),
                    SizedBox(width: 14),
                    Text('Menghubungkan (simulasi)…'),
                  ],
                ),
              ),
            },
        ],
      ),
    );
  }
}

class MetricGrid extends StatelessWidget {
  const MetricGrid({super.key, required this.onTap});
  final VoidCallback onTap;

  static const _metrics = [
    ('1.250', 'RPM', 'rpm', Icons.speed_outlined),
    ('0', 'Kecepatan', 'km/h', Icons.navigation_outlined),
    ('87', 'Suhu Mesin', '°C', Icons.thermostat_outlined),
    ('13,8', 'Tegangan Aki', 'V', Icons.battery_charging_full_outlined),
    ('64', 'Level BBM', '%', Icons.local_gas_station_outlined),
    ('42,5', 'Konsumsi BBM', 'km/L', Icons.local_fire_department_outlined),
  ];

  @override
  Widget build(BuildContext context) => CardBox(
    padding: const EdgeInsets.all(8),
    child: GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 3,
      childAspectRatio: 1.08,
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      children: [
        for (final m in _metrics)
          CardBox(
            onTap: onTap,
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(m.$4, size: 16, color: AppColors.muted),
                const SizedBox(height: 5),
                Text(
                  m.$1,
                  style: const TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const Spacer(),
                Text(
                  m.$2,
                  style: const TextStyle(fontSize: 10, color: AppColors.muted),
                ),
                Text(
                  m.$3,
                  style: const TextStyle(fontSize: 10, color: AppColors.muted),
                ),
              ],
            ),
          ),
      ],
    ),
  );
}

class HealthItem extends StatelessWidget {
  const HealthItem(this.title, this.value, this.ok, {super.key});
  final String title, value;
  final bool ok;
  @override
  Widget build(BuildContext context) => ListTile(
    contentPadding: EdgeInsets.zero,
    leading: CircleAvatar(
      backgroundColor: ok ? const Color(0xFFDDF5E3) : const Color(0xFFFFE6E6),
      child: Icon(
        ok ? Icons.check : Icons.warning,
        color: ok ? AppColors.green : AppColors.red,
        size: 18,
      ),
    ),
    title: Text(title, style: const TextStyle(fontSize: 12)),
    subtitle: Text(
      value,
      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
    ),
  );
}

class HealthSummary extends StatelessWidget {
  const HealthSummary({super.key, required this.state});
  final OtoKuState state;
  @override
  Widget build(BuildContext context) {
    final codes = state.obdCodes;
    return CardBox(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          const Row(
            children: [
              Expanded(child: HealthItem('Mesin', 'Normal', true)),
              Expanded(child: HealthItem('Sistem Pengisian', 'Normal', true)),
            ],
          ),
          Row(
            children: [
              const Expanded(child: HealthItem('Emisi', 'Normal', true)),
              Expanded(
                child: codes.isEmpty
                    ? const HealthItem('Kode masalah', 'Tidak ada', true)
                    : HealthItem(
                        '${codes.length} kode masalah',
                        codes.join(', '),
                        false,
                      ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class ObdScreen extends StatelessWidget {
  const ObdScreen({super.key, required this.state});
  final OtoKuState state;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: state,
    builder: (context, _) {
      if (!state.obdConnected) {
        return AppPage(
          title: 'Data OBD',
          child: ScrollPage(
            child: Column(
              children: [
                const CardBox(
                  child: Column(
                    children: [
                      Icon(
                        Icons.sensors_off_outlined,
                        size: 40,
                        color: AppColors.muted,
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Simulasi OBD tidak aktif',
                        style: TextStyle(fontWeight: FontWeight.w800),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Hubungkan adaptor simulasi untuk melihat contoh data dan kode masalah.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppColors.muted),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: () => showObdSheet(context, state),
                  child: const Text('Cari adaptor (simulasi)'),
                ),
              ],
            ),
          ),
        );
      }
      final codes = state.obdCodes;
      return AppPage(
        title: 'Data OBD · Simulasi',
        child: ScrollPage(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CardBox(
                color: AppColors.amberTint,
                child: Row(
                  children: [
                    const Icon(Icons.science_outlined, color: AppColors.amber),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'OBD Demo Aktif',
                            style: TextStyle(fontWeight: FontWeight.w800),
                          ),
                          Text(
                            'Data simulasi lokal · bukan live · ${state.obdAdapter ?? ''}',
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
              const SizedBox(height: 16),
              MetricGrid(onTap: () {}),
              const SectionTitle('Kondisi Kendaraan (simulasi)'),
              HealthSummary(state: state),
              SectionTitle(
                codes.isEmpty
                    ? 'Kode Masalah'
                    : 'Kode Masalah (${codes.length}, simulasi)',
              ),
              if (codes.isEmpty)
                const CardBox(
                  child: Row(
                    children: [
                      Icon(Icons.check_circle_outline, color: AppColors.green),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Tidak ada kode masalah pada simulasi ini.',
                        ),
                      ),
                    ],
                  ),
                ),
              for (final code in codes)
                _DtcCard(info: DtcInfo.lookup(code), state: state),
              if (codes.isNotEmpty) ...[
                const SectionTitle('Bengkel terdekat'),
                NearestBengkelSection(
                  state: state,
                  task: 'Pemeriksaan Kode OBD',
                  reason:
                      'Kode ${codes.join(', ')} perlu diperiksa mekanik. Booking terisi otomatis dengan layanan pemeriksaan.',
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: () => state.clearObdCodes(),
                  icon: const Icon(Icons.restart_alt),
                  label: const Text('Hapus kode (simulasi)'),
                ),
              ],
              const SizedBox(height: 8),
              TextButton(
                onPressed: () async {
                  await state.disconnectObd();
                  if (context.mounted) Navigator.pop(context);
                },
                child: const Text('Putuskan simulasi'),
              ),
            ],
          ),
        ),
      );
    },
  );
}

class _DtcCard extends StatelessWidget {
  const _DtcCard({required this.info, required this.state});
  final DtcInfo info;
  final OtoKuState state;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: CardBox(
      key: ValueKey('dtc-${info.code}'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.error_outline, color: AppColors.red),
              const SizedBox(width: 8),
              Text(
                info.code,
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                ),
              ),
              const Spacer(),
              StatusChip(info.severity.label, info.severity.color),
            ],
          ),
          const SizedBox(height: 4),
          Text(info.title, style: const TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text(
            'Contoh ${info.code}: ${info.explanation} Ini bukan diagnosis pasti; perlu pemeriksaan bengkel.',
            style: const TextStyle(
              color: AppColors.muted,
              height: 1.4,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Yang bisa diperiksa:',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
          ),
          for (final check in info.checks)
            Text('• $check', style: const TextStyle(fontSize: 12.5)),
          const SizedBox(height: 4),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () {
                final services = ServicesScope.of(context);
                services.goToTab(context, AppServices.tabShop);
              },
              icon: const Icon(Icons.shopping_bag_outlined, size: 18),
              label: Text('Lihat sparepart (${info.partCategory})'),
            ),
          ),
        ],
      ),
    ),
  );
}
