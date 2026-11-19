import 'package:flutter/material.dart';

import '../models/vehicle.dart';
import '../state/oto_ku_state.dart';
import '../ui/common.dart';
import '../ui/vehicle_art.dart';
import 'maintenance_screens.dart';
import 'obd_screens.dart';

/// "Kendaraan Saya": all vehicles, switch the active one, add, edit, delete.
class VehiclesScreen extends StatelessWidget {
  const VehiclesScreen({super.key, required this.state});
  final OtoKuState state;

  Future<void> _delete(BuildContext context, Vehicle v) async {
    final messenger = ScaffoldMessenger.of(context);
    if (state.vehicles.length <= 1) {
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(
        const SnackBar(
          content: Text(
            'Minimal satu kendaraan diperlukan. Tambahkan kendaraan lain sebelum menghapus ini.',
          ),
        ),
      );
      return;
    }
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Hapus ${v.name}?'),
        content: const Text(
          'Catatan, jadwal perawatan, dan trip untuk kendaraan ini ikut terhapus dari perangkat.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (ok == true) await state.deleteVehicle(v.id);
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: state,
    builder: (context, _) => AppPage(
      title: 'Kendaraan Saya',
      bottomBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: FilledButton.icon(
            key: const ValueKey('add-vehicle'),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => VehicleFormScreen(state: state),
              ),
            ),
            icon: const Icon(Icons.add),
            label: const Text('Tambah Kendaraan'),
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
            ),
          ),
        ),
      ),
      child: ScrollPage(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Pilih kendaraan aktif. Perawatan, kecocokan sparepart, dan catatan mengikuti kendaraan aktif.',
              style: TextStyle(color: AppColors.muted, fontSize: 13),
            ),
            const SizedBox(height: 12),
            for (final v in state.vehicles)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: CardBox(
                  key: ValueKey('vehicle-${v.id}'),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) =>
                          VehicleDetailScreen(state: state, vehicleId: v.id),
                    ),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: v.id == state.activeVehicleId
                            ? AppColors.redTint
                            : AppColors.surfaceLow,
                        child: Icon(
                          v.kind == VehicleKind.mobil
                              ? Icons.directions_car
                              : Icons.two_wheeler,
                          color: AppColors.red,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              v.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            Text(
                              '${v.plate} · ${formatKilometers(v.mileage)} km',
                              style: const TextStyle(
                                color: AppColors.muted,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 4),
                            if (v.id == state.activeVehicleId)
                              const StatusChip('Aktif', AppColors.green)
                            else
                              GestureDetector(
                                onTap: () => state.setActiveVehicle(v.id),
                                child: Container(
                                  key: ValueKey('activate-${v.id}'),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    border: Border.all(color: AppColors.red),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: const Text(
                                    'Jadikan aktif',
                                    style: TextStyle(
                                      color: AppColors.red,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      IconButton(
                        tooltip: 'Ubah ${v.name}',
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) =>
                                VehicleFormScreen(state: state, vehicle: v),
                          ),
                        ),
                        icon: const Icon(Icons.edit_outlined),
                      ),
                      IconButton(
                        tooltip: 'Hapus ${v.name}',
                        onPressed: () => _delete(context, v),
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
      ),
    ),
  );
}

class VehicleFormScreen extends StatefulWidget {
  const VehicleFormScreen({super.key, required this.state, this.vehicle});
  final OtoKuState state;

  /// Null to add a new vehicle.
  final Vehicle? vehicle;

  @override
  State<VehicleFormScreen> createState() => _VehicleFormScreenState();
}

class _VehicleFormScreenState extends State<VehicleFormScreen> {
  late final _brand = TextEditingController(text: widget.vehicle?.brand ?? '');
  late final _model = TextEditingController(text: widget.vehicle?.model ?? '');
  late final _plate = TextEditingController(text: widget.vehicle?.plate ?? '');
  late final _type = TextEditingController(text: widget.vehicle?.type ?? '');
  late final _year = TextEditingController(
    text: '${widget.vehicle?.year ?? ''}',
  );
  late final _mileage = TextEditingController(
    text: '${widget.vehicle?.mileage ?? ''}',
  );
  late VehicleKind kind = widget.vehicle?.kind ?? VehicleKind.motor;
  bool saving = false;

  bool get editing => widget.vehicle != null;

  @override
  void dispose() {
    for (final c in [_brand, _model, _plate, _type, _year, _mileage]) {
      c.dispose();
    }
    super.dispose();
  }

  void _error(String message) => ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));

  Future<void> _save() async {
    final year = int.tryParse(_year.text.trim());
    final mileage = int.tryParse(_mileage.text.trim());
    if (_brand.text.trim().isEmpty ||
        _model.text.trim().isEmpty ||
        _plate.text.trim().isEmpty ||
        year == null ||
        mileage == null ||
        year < 1900 ||
        year > DateTime.now().year + 1 ||
        mileage < 0) {
      return _error('Periksa kembali data kendaraan.');
    }
    if (editing && mileage < widget.vehicle!.mileage) {
      return _error('Kilometer baru tidak boleh lebih rendah.');
    }
    setState(() => saving = true);
    final draft =
        (widget.vehicle ??
                const Vehicle(
                  brand: '',
                  model: '',
                  plate: '',
                  type: '',
                  year: 2000,
                  mileage: 0,
                ))
            .copyWith(
              kind: kind,
              brand: _brand.text.trim(),
              model: _model.text.trim(),
              plate: _plate.text.trim().toUpperCase(),
              type: _type.text.trim(),
              year: year,
              mileage: mileage,
            );
    if (editing) {
      await widget.state.updateVehicle(draft);
    } else {
      await widget.state.addVehicle(draft);
    }
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) => AppPage(
    title: editing ? 'Ubah Kendaraan' : 'Tambah Kendaraan',
    bottomBar: SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        child: FilledButton(
          onPressed: saving ? null : _save,
          style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
          child: Text(
            saving
                ? 'Menyimpan...'
                : (editing ? 'Simpan Perubahan' : 'Simpan Kendaraan'),
          ),
        ),
      ),
    ),
    child: ScrollPage(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SegmentedButton<VehicleKind>(
            segments: [
              for (final k in VehicleKind.values)
                ButtonSegment(value: k, label: Text(k.label)),
            ],
            selected: {kind},
            onSelectionChanged: (s) => setState(() => kind = s.first),
            showSelectedIcon: false,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _brand,
            decoration: const InputDecoration(labelText: 'Merek'),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _model,
            decoration: const InputDecoration(labelText: 'Model'),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _plate,
            textCapitalization: TextCapitalization.characters,
            decoration: const InputDecoration(labelText: 'Nomor polisi'),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _type,
            decoration: const InputDecoration(labelText: 'Tipe / varian'),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _year,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Tahun'),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _mileage,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Kilometer terakhir',
              suffixText: 'km',
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Nomor rangka dan mesin tidak diminta. Data tersimpan lokal di perangkat ini.',
            style: TextStyle(color: AppColors.muted, fontSize: 12),
          ),
        ],
      ),
    ),
  );
}

class VehicleDetailScreen extends StatelessWidget {
  const VehicleDetailScreen({super.key, required this.state, this.vehicleId});
  final OtoKuState state;

  /// Defaults to the active vehicle.
  final String? vehicleId;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: state,
    builder: (context, _) {
      final v =
          state.vehicles
              .where((x) => x.id == (vehicleId ?? state.activeVehicleId))
              .firstOrNull ??
          state.vehicle;
      final active = v.id == state.activeVehicleId;
      return AppPage(
        title: 'Detail Kendaraan',
        actions: [
          IconButton(
            tooltip: 'Ubah kendaraan',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => VehicleFormScreen(state: state, vehicle: v),
              ),
            ),
            icon: const Icon(Icons.edit_outlined),
          ),
        ],
        child: ScrollPage(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CardBox(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F1EF),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child:
                          v.brand == 'Honda' &&
                              v.model.toLowerCase().contains('beat')
                          ? const VehiclePhoto(height: 190, detail: true)
                          : const VehicleIllustration(height: 190),
                    ),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        v.name,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        v.plate,
                        style: const TextStyle(color: AppColors.muted),
                      ),
                    ),
                    const SizedBox(height: 18),
                    InfoRow('Jenis', v.kind.label),
                    InfoRow('Merek', v.brand),
                    InfoRow('Model', v.model),
                    InfoRow('Tahun', '${v.year}'),
                    InfoRow('Tipe', v.type.isEmpty ? '-' : v.type),
                    InfoRow('Kilometer', '${formatKilometers(v.mileage)} km'),
                    const Padding(
                      padding: EdgeInsets.only(top: 8),
                      child: Text(
                        'Data kendaraan disimpan lokal pada perangkat ini.',
                        style: TextStyle(color: AppColors.muted, fontSize: 12),
                      ),
                    ),
                    const SizedBox(height: 10),
                    if (active)
                      const StatusChip('Kendaraan aktif', AppColors.green)
                    else
                      OutlinedButton(
                        onPressed: () => state.setActiveVehicle(v.id),
                        child: const Text('Jadikan kendaraan aktif'),
                      ),
                  ],
                ),
              ),
              if (active) ...[
                const SectionTitle('Aktivitas kendaraan'),
                _Link(
                  'Riwayat & Tracking',
                  Icons.timeline,
                  () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => HistoryScreen(state: state),
                    ),
                  ),
                ),
                _Link(
                  'Jadwal Perawatan',
                  Icons.event_note,
                  () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => MaintenanceScreen(state: state),
                    ),
                  ),
                ),
                _Link(
                  'Data OBD (simulasi)',
                  Icons.sensors,
                  () => openObd(context, state),
                ),
              ],
              _Link(
                'Semua Kendaraan',
                Icons.garage_outlined,
                () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => VehiclesScreen(state: state),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

class _Link extends StatelessWidget {
  const _Link(this.title, this.icon, this.onTap);
  final String title;
  final IconData icon;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => CardBox(
    onTap: onTap,
    child: Row(
      children: [
        Icon(icon, color: AppColors.red),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
        const Icon(Icons.chevron_right),
      ],
    ),
  );
}
