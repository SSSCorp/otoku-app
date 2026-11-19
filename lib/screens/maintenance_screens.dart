import 'package:flutter/material.dart';

import '../models/vehicle.dart';
import '../state/oto_ku_state.dart';
import '../ui/charts.dart';
import '../ui/common.dart';
import 'place_widgets.dart';

String dueText(MaintenanceStatus s) => switch (s.level) {
  DueLevel.overdue => 'Terlewat ${formatKilometers(-s.remaining)} km',
  DueLevel.soon => 'Segera · ${formatKilometers(s.remaining)} km lagi',
  DueLevel.ok => '${formatKilometers(s.remaining)} km lagi',
};

Color dueColor(DueLevel level) => switch (level) {
  DueLevel.overdue => AppColors.red,
  DueLevel.soon => AppColors.amber,
  DueLevel.ok => AppColors.green,
};

String dueChipLabel(DueLevel level) => switch (level) {
  DueLevel.overdue => 'Terlewat',
  DueLevel.soon => 'Segera',
  DueLevel.ok => 'Terjadwal',
};

class MaintenanceScreen extends StatefulWidget {
  const MaintenanceScreen({super.key, required this.state});
  final OtoKuState state;

  @override
  State<MaintenanceScreen> createState() => _MaintenanceScreenState();
}

class _MaintenanceScreenState extends State<MaintenanceScreen> {
  String filter = 'Rekomendasi';

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: widget.state,
    builder: (context, _) {
      final state = widget.state;
      final current = state.vehicle.mileage;
      final statuses = state.maintenanceStatuses();
      final visible =
          statuses
              .where(
                (s) =>
                    filter == 'Semua' ||
                    (filter == 'Rekomendasi' && s.needsAttention),
              )
              .toList()
            ..sort((a, b) => a.remaining.compareTo(b.remaining));
      final history = state.activeRecords;
      final attention = state.maintenanceNeedingAttention;
      return AppPage(
        title: 'Jadwal Perawatan',
        child: ScrollPage(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${state.vehicle.name} · ${formatKilometers(current)} km',
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                children: [
                  for (final value in ['Rekomendasi', 'Semua', 'Selesai'])
                    ChoiceChip(
                      label: Text(value),
                      selected: filter == value,
                      onSelected: (_) => setState(() => filter = value),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                'Jadwal dihitung dari interval umum dan kilometer kendaraan; ini estimasi, bukan jadwal pabrikan.',
                style: TextStyle(color: AppColors.muted, fontSize: 12),
              ),
              const SizedBox(height: 12),
              if (filter == 'Selesai') ...[
                if (history.isEmpty)
                  const _Empty(
                    icon: Icons.history,
                    title: 'Belum ada perawatan selesai',
                    message: 'Tandai perawatan sebagai selesai agar muncul di riwayat servis.',
                  ),
                for (final r in history)
                  CardBox(
                    child: Row(
                      children: [
                        const Icon(Icons.check_circle, color: AppColors.green),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                r.task,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              Text(
                                '${formatDateId(r.date)} · ${formatKilometers(r.mileage)} km',
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
              ] else ...[
                if (visible.isEmpty)
                  const _Empty(
                    icon: Icons.verified_outlined,
                    title: 'Tidak ada perawatan mendesak',
                    message: 'Semua perawatan masih terjadwal. Pilih "Semua" untuk melihat daftar lengkap.',
                  ),
                for (final s in visible)
                  _TaskCard(
                    status: s,
                    current: current,
                    onDone: () =>
                        widget.state.completeMaintenance(s.task.title),
                  ),
                if (filter == 'Rekomendasi' && attention.isNotEmpty) ...[
                  const SectionTitle('Bengkel terdekat'),
                  NearestBengkelSection(
                    state: state,
                    task: attention.first.task.title,
                    reason:
                        'Untuk ${attention.first.task.title}. Booking terisi otomatis dengan kendaraan dan layanan yang sesuai.',
                  ),
                ],
              ],
            ],
          ),
        ),
      );
    },
  );
}

class _TaskCard extends StatelessWidget {
  const _TaskCard({
    required this.status,
    required this.current,
    required this.onDone,
  });
  final MaintenanceStatus status;
  final int current;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    final s = status;
    final color = dueColor(s.level);
    final base = s.lastDone?.mileage ?? (s.dueAt - s.task.intervalKm);
    final progress = ((current - base) / s.task.intervalKm)
        .clamp(0.0, 1.0)
        .toDouble();
    return CardBox(
      key: ValueKey('task-${s.task.title}'),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: AppColors.bg,
            child: Icon(s.task.icon, color: AppColors.red),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        s.task.title,
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ),
                    const SizedBox(width: 8),
                    StatusChip(dueChipLabel(s.level), color),
                  ],
                ),
                Text(
                  dueText(s),
                  style: TextStyle(
                    color: s.level == DueLevel.ok ? AppColors.muted : color,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: progress,
                  minHeight: 6,
                  borderRadius: BorderRadius.circular(8),
                  color: color,
                  backgroundColor: AppColors.border,
                ),
                const SizedBox(height: 5),
                Text(
                  'Jatuh tempo ${formatKilometers(s.dueAt)} km · tiap ${formatKilometers(s.task.intervalKm)} km${s.lastDone != null ? ' · terakhir ${formatKilometers(s.lastDone!.mileage)} km' : ''}',
                  style: const TextStyle(color: AppColors.muted, fontSize: 11),
                ),
              ],
            ),
          ),
          IconButton(
            key: ValueKey('done-${s.task.title}'),
            tooltip: 'Tandai selesai',
            onPressed: onDone,
            icon: const Icon(
              Icons.check_circle_outline,
              color: AppColors.muted,
            ),
          ),
        ],
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty({
    required this.icon,
    required this.title,
    required this.message,
  });
  final IconData icon;
  final String title, message;
  @override
  Widget build(BuildContext context) => CardBox(
    child: Column(
      children: [
        Icon(icon, size: 34, color: AppColors.muted),
        const SizedBox(height: 8),
        Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
        const SizedBox(height: 4),
        Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(color: AppColors.muted),
        ),
      ],
    ),
  );
}

/// Create or edit a manual activity log (mileage, BBM, servis, biaya, sparepart).
class ManualLogScreen extends StatefulWidget {
  const ManualLogScreen({
    super.key,
    required this.state,
    this.existing,
    this.initialType,
    this.initialTitle,
  });
  final OtoKuState state;

  /// When set, the screen edits this log instead of creating a new one.
  final Map<String, dynamic>? existing;
  final String? initialType, initialTitle;

  @override
  State<ManualLogScreen> createState() => _ManualLogScreenState();
}

class _ManualLogScreenState extends State<ManualLogScreen> {
  static const types = ['Kilometer', 'BBM', 'Servis', 'Biaya', 'Sparepart'];
  late final _title = TextEditingController(
    text: '${widget.existing?['title'] ?? widget.initialTitle ?? ''}',
  );
  late final _value = TextEditingController(
    text: _initial(widget.existing?['amount']),
  );
  late final _mileage = TextEditingController(
    text: _initial(widget.existing?['mileage']),
  );
  late final _volume = TextEditingController(
    text: _initial(widget.existing?['volume']),
  );
  late final _notes = TextEditingController(
    text: '${widget.existing?['notes'] ?? ''}',
  );
  late String type = _typeLabel(
    widget.existing?['type'] as String? ?? widget.initialType,
  );
  bool saving = false;

  bool get editing => widget.existing != null;

  static String _initial(Object? v) => v == null
      ? ''
      : (v is double && v == v.roundToDouble() ? v.toInt().toString() : '$v');

  static String _typeLabel(String? raw) => switch (raw) {
    'bbm' => 'BBM',
    'servis' => 'Servis',
    'biaya' => 'Biaya',
    'sparepart' => 'Sparepart',
    _ => 'Kilometer',
  };

  @override
  void dispose() {
    _title.dispose();
    _value.dispose();
    _mileage.dispose();
    _volume.dispose();
    _notes.dispose();
    super.dispose();
  }

  void _showError(String message) => ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));

  Future<void> _save() async {
    if (saving) return;
    final state = widget.state;
    final title = _title.text.trim();
    final value = int.tryParse(_value.text.trim());
    final mileage = int.tryParse(_mileage.text.trim());
    final volume = double.tryParse(_volume.text.trim().replaceAll(',', '.'));
    final previousMileage = widget.existing?['mileage'];
    if (type == 'BBM' &&
        _volume.text.trim().isNotEmpty &&
        (volume == null || volume < 0)) {
      return _showError('Masukkan volume BBM yang valid.');
    }
    if (type != 'Kilometer' &&
        _value.text.trim().isNotEmpty &&
        (value == null || value < 0)) {
      return _showError('Masukkan angka biaya yang valid.');
    }
    if (_mileage.text.trim().isNotEmpty && (mileage == null || mileage < 0)) {
      return _showError('Masukkan angka kilometer yang valid.');
    }
    if (type != 'Kilometer' &&
        mileage != null &&
        mileage < state.vehicle.mileage &&
        mileage != previousMileage) {
      return _showError(
        'Kilometer aktivitas lebih rendah dari catatan kendaraan. Periksa kembali.',
      );
    }
    if (type == 'Kilometer') {
      if (value == null || value < 0) {
        return _showError('Masukkan angka kilometer yang valid.');
      }
      if (value < state.vehicle.mileage) {
        return _showError(
          'Kilometer baru tidak boleh lebih rendah dari catatan sebelumnya.',
        );
      }
    } else if (title.isEmpty) {
      return _showError('Isi nama aktivitas terlebih dahulu.');
    }

    setState(() => saving = true);
    try {
      if (type == 'Kilometer') {
        await state.updateMileage(value!);
      } else {
        final data = {
          'type': type.toLowerCase(),
          'title': title,
          'amount': value,
          'volume': type == 'BBM' ? volume : null,
          'mileage': mileage,
          'notes': _notes.text.trim(),
        };
        if (editing) {
          await state.updateLog(widget.existing!['id'] as String, data);
        } else {
          await state.addLog({
            ...data,
            'date': state.now.toIso8601String(),
            'source': 'manual',
          });
        }
      }
      if (mounted) Navigator.pop(context);
    } catch (_) {
      if (mounted) _showError('Catatan belum dapat disimpan. Coba lagi.');
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => AppPage(
    title: editing ? 'Ubah Catatan' : 'Catat Aktivitas',
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
                : (editing ? 'Simpan Perubahan' : 'Simpan Catatan'),
          ),
        ),
      ),
    ),
    child: ScrollPage(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Catat tanpa OBD',
            style: TextStyle(color: AppColors.muted),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: type,
            decoration: const InputDecoration(labelText: 'Jenis catatan'),
            items: [
              for (final t in types) DropdownMenuItem(value: t, child: Text(t)),
            ],
            onChanged: editing
                ? null
                : (value) => setState(() => type = value ?? 'Kilometer'),
          ),
          const SizedBox(height: 14),
          if (type != 'Kilometer') ...[
            TextField(
              controller: _title,
              decoration: InputDecoration(
                labelText: type == 'BBM'
                    ? 'Jenis BBM / SPBU'
                    : 'Nama aktivitas',
                hintText: type == 'BBM'
                    ? 'Contoh: Pertalite'
                    : 'Contoh: Servis berkala',
              ),
            ),
            const SizedBox(height: 12),
          ],
          TextField(
            key: const ValueKey('log-value'),
            controller: _value,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: type == 'Kilometer'
                  ? 'Kilometer terbaru'
                  : 'Biaya total (opsional)',
              suffixText: type == 'Kilometer' ? 'km' : 'Rp',
            ),
          ),
          if (type == 'BBM') ...[
            const SizedBox(height: 12),
            TextField(
              controller: _volume,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: 'Volume BBM (opsional)',
                suffixText: 'liter',
              ),
            ),
          ],
          if (type != 'Kilometer') ...[
            const SizedBox(height: 12),
            TextField(
              controller: _mileage,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Kilometer saat aktivitas (opsional)',
                suffixText: 'km',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _notes,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Catatan tambahan (opsional)',
              ),
            ),
          ],
          const SizedBox(height: 16),
          Text(
            'Kendaraan: ${widget.state.vehicle.name}',
            style: const TextStyle(color: AppColors.muted),
          ),
        ],
      ),
    ),
  );
}

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key, required this.state});
  final OtoKuState state;

  @override
  State<HistoryScreen> createState() => _HistoryState();
}

class _HistoryState extends State<HistoryScreen> {
  int tab = 0;

  List<num> _valuesForTab() => widget.state.logs.reversed
      .map((log) => tab == 1 ? (log['mileage'] ?? log['value']) : log['amount'])
      .whereType<num>()
      .where((value) => value > 0)
      .toList();

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: widget.state,
    builder: (context, _) => AppPage(
      title: 'Riwayat & Tracking',
      child: ScrollPage(
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                for (final (i, label) in [
                  'Timeline',
                  'Grafik',
                  'Biaya',
                ].indexed)
                  GestureDetector(
                    onTap: () => setState(() => tab = i),
                    child: Pill(label, active: tab == i),
                  ),
              ],
            ),
            const SizedBox(height: 18),
            if (tab == 0)
              ServiceTimeline(state: widget.state)
            else if (_valuesForTab().length < 2)
              CardBox(
                child: Text(
                  _valuesForTab().isEmpty
                      ? 'Belum ada cukup catatan untuk membuat grafik.'
                      : 'Tambahkan satu catatan lagi untuk melihat tren.',
                  style: const TextStyle(color: AppColors.muted),
                ),
              )
            else
              ChartPanel(
                title: tab == 1 ? 'Tren jarak tempuh' : 'Pengeluaran perawatan',
                values: _valuesForTab(),
              ),
          ],
        ),
      ),
    ),
  );
}

class ServiceTimeline extends StatelessWidget {
  const ServiceTimeline({super.key, required this.state});
  final OtoKuState state;

  Future<void> _confirmDelete(
    BuildContext context,
    Map<String, dynamic> log,
  ) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus catatan?'),
        content: Text(
          log['type'] == 'odometer'
              ? 'Catatan "${log['title']}" dihapus dari riwayat. Kilometer kendaraan tidak berubah.'
              : 'Catatan "${log['title']}" akan dihapus dari riwayat.',
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
    if (ok == true) await state.deleteLog(log['id'] as String);
  }

  @override
  Widget build(BuildContext context) {
    final logs = state.logs;
    if (logs.isEmpty) {
      return const _Empty(
        icon: Icons.timeline,
        title: 'Belum ada riwayat',
        message: 'Catatan kilometer, BBM, servis, dan biaya yang kamu buat akan tersimpan di sini.',
      );
    }
    return Column(
      children: [
        for (final log in logs)
          Builder(
            builder: (context) {
              final type = (log['type'] ?? 'catatan').toString();
              final amount = log['amount'];
              final mileage = log['mileage'] ?? log['value'];
              final notes = (log['notes'] ?? '').toString();
              final date = DateTime.tryParse((log['date'] ?? '').toString());
              final volume = log['volume'];
              final details = <String>[
                if (volume is num) '${volume.toStringAsFixed(1)} L',
                if (mileage is num) '${formatKilometers(mileage.toInt())} km',
                if (amount is num && amount > 0)
                  'Rp ${formatKilometers(amount.toInt())}',
                if (notes.isNotEmpty) notes,
                if (log['source'] == 'manual') 'Dicatat manual',
                if (log['source'] == 'trip') 'Dari trip GPS',
                if (log['source'] == 'booking') 'Dari booking selesai',
                if (log['source'] == 'maintenance') 'Dari jadwal perawatan',
              ];
              final icon = switch (type) {
                'bbm' => Icons.local_gas_station_outlined,
                'servis' => Icons.build_outlined,
                'biaya' => Icons.payments_outlined,
                'sparepart' => Icons.tire_repair_outlined,
                _ => Icons.speed_outlined,
              };
              return CardBox(
                key: ValueKey('log-${log['id']}'),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(icon, color: AppColors.red),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            (log['title'] ?? 'Catatan').toString(),
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                          Text(
                            date == null
                                ? 'Tanggal tidak tersedia'
                                : formatDateId(date),
                            style: const TextStyle(
                              color: AppColors.muted,
                              fontSize: 12,
                            ),
                          ),
                          if (details.isNotEmpty)
                            Text(
                              details.join(' · '),
                              style: const TextStyle(
                                color: AppColors.muted,
                                fontSize: 12,
                              ),
                            ),
                        ],
                      ),
                    ),
                    if (type != 'odometer')
                      IconButton(
                        tooltip: 'Ubah catatan',
                        visualDensity: VisualDensity.compact,
                        icon: const Icon(Icons.edit_outlined, size: 20),
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) =>
                                ManualLogScreen(state: state, existing: log),
                          ),
                        ),
                      ),
                    IconButton(
                      tooltip: 'Hapus catatan',
                      visualDensity: VisualDensity.compact,
                      icon: const Icon(Icons.delete_outline, size: 20),
                      onPressed: () => _confirmDelete(context, log),
                    ),
                  ],
                ),
              );
            },
          ),
      ],
    );
  }
}
