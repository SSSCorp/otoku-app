import 'package:flutter/material.dart';

import '../core/app_config.dart';
import '../services/app_services.dart';
import '../services/location_service.dart';
import '../state/oto_ku_state.dart';
import '../ui/common.dart';
import 'orders_screens.dart';
import 'trip_screen.dart';
import 'vehicle_screens.dart';

class AccountScreen extends StatelessWidget {
  const AccountScreen({super.key, required this.state});
  final OtoKuState state;

  @override
  Widget build(BuildContext c) {
    void open(Widget page) =>
        Navigator.of(c).push(MaterialPageRoute<void>(builder: (_) => page));
    final services = ServicesScope.of(c);
    final actions = <({String title, IconData icon, VoidCallback onTap})>[
      (
        title: 'Kendaraan Saya',
        icon: Icons.two_wheeler,
        onTap: () => open(VehiclesScreen(state: state)),
      ),
      (
        title: 'Pesanan Saya',
        icon: Icons.receipt_long_outlined,
        onTap: () => services.tab.value = AppServices.tabPesanan,
      ),
      (
        title: 'Booking Layanan',
        icon: Icons.event_note,
        onTap: () => open(BookingHistoryScreen(state: state)),
      ),
      (
        title: 'Trip GPS',
        icon: Icons.route_outlined,
        onTap: () => open(TripScreen(state: state)),
      ),
      (
        title: 'Alamat Saya',
        icon: Icons.location_on_outlined,
        onTap: () => open(AddressScreen(state: state)),
      ),
      (
        title: 'Peta & Lokasi',
        icon: Icons.map_outlined,
        onTap: () => open(MapSettingsScreen(state: state)),
      ),
      (
        title: 'Pusat Bantuan',
        icon: Icons.help_outline,
        onTap: () => open(const HelpScreen()),
      ),
      (
        title: 'Tentang OtoKu',
        icon: Icons.info_outline,
        onTap: () => open(const AboutScreen()),
      ),
      (
        title: 'Data & Privasi',
        icon: Icons.shield_outlined,
        onTap: () => open(DataPrivacyScreen(state: state)),
      ),
    ];
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Akun Saya',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 12),
          CardBox(
            onTap: () => open(DataPrivacyScreen(state: state)),
            child: const Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: Color(0xFFE8E8E8),
                  child: Icon(Icons.person_outline, color: AppColors.ink),
                ),
                SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Mode prototipe lokal',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        'Tanpa akun · tanpa server',
                        style: TextStyle(color: AppColors.muted, fontSize: 12),
                      ),
                      Text(
                        'Data tersimpan di perangkat ini',
                        style: TextStyle(color: AppColors.red, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right),
              ],
            ),
          ),
          const SizedBox(height: 14),
          for (final action in actions)
            CardBox(
              onTap: action.onTap,
              child: Row(
                children: [
                  Icon(action.icon, color: AppColors.red),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      action.title,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                  const Icon(Icons.chevron_right, color: AppColors.muted),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// Booking layanan only (a filtered view of Pesanan).
class BookingHistoryScreen extends StatelessWidget {
  const BookingHistoryScreen({super.key, required this.state});
  final OtoKuState state;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: state,
    builder: (context, _) {
      final bookings = state.orders.where((o) => o.isBooking).toList();
      return AppPage(
        title: 'Booking Layanan',
        child: ScrollPage(
          child: Column(
            children: [
              if (bookings.isEmpty)
                CardBox(
                  child: Column(
                    children: [
                      const Icon(
                        Icons.event_busy_outlined,
                        size: 36,
                        color: AppColors.muted,
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Belum ada booking layanan',
                        style: TextStyle(fontWeight: FontWeight.w800),
                      ),
                      const Text(
                        'Pilih bengkel di Peta untuk membuat booking.',
                        style: TextStyle(color: AppColors.muted),
                      ),
                      TextButton(
                        onPressed: () =>
                            ServicesScope.of(context)
                                .goToTab(context, AppServices.tabPeta),
                        child: const Text('Buka Peta'),
                      ),
                    ],
                  ),
                ),
              for (final o in bookings)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: OrderCard(
                    order: o,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) =>
                            OrderDetailScreen(state: state, orderId: o.id),
                      ),
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

class AddressScreen extends StatefulWidget {
  const AddressScreen({super.key, required this.state});
  final OtoKuState state;

  @override
  State<AddressScreen> createState() => _AddressScreenState();
}

class _AddressScreenState extends State<AddressScreen> {
  late final _controller = TextEditingController(text: widget.state.address);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AppPage(
    title: 'Alamat Saya',
    bottomBar: SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        child: FilledButton(
          onPressed: () async {
            await widget.state.setAddress(_controller.text);
            if (context.mounted) Navigator.pop(context);
          },
          style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
          child: const Text('Simpan Alamat'),
        ),
      ),
    ),
    child: ScrollPage(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Alamat disimpan hanya di perangkat ini dan dipakai untuk checkout simulasi. Tidak ada pengiriman nyata.',
            style: TextStyle(color: AppColors.muted),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _controller,
            maxLines: 4,
            decoration: const InputDecoration(labelText: 'Alamat lengkap'),
          ),
        ],
      ),
    ),
  );
}

class MapSettingsScreen extends StatelessWidget {
  const MapSettingsScreen({super.key, required this.state});
  final OtoKuState state;

  @override
  Widget build(BuildContext context) {
    final services = ServicesScope.of(context);
    final config = services.config;
    final location = services.location;
    return AppPage(
      title: 'Peta & Lokasi',
      child: ListenableBuilder(
        listenable: location,
        builder: (context, _) => ScrollPage(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CardBox(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Penyedia peta',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      config.effectiveProvider == MapProvider.google
                          ? 'Google Maps (MAP_PROVIDER=google)'
                          : 'OpenStreetMap (bawaan)',
                      key: const ValueKey('map-provider-label'),
                    ),
                    if (config.googleFellBack)
                      const Text(
                        'Google Maps diminta tetapi GOOGLE_MAPS_API_KEY kosong, jadi OpenStreetMap dipakai.',
                        style: TextStyle(color: AppColors.red, fontSize: 12),
                      ),
                    const SizedBox(height: 6),
                    const Text(
                      'Atur lewat --dart-define=MAP_PROVIDER=osm|google dan GOOGLE_MAPS_API_KEY saat menjalankan aplikasi.',
                      style: TextStyle(color: AppColors.muted, fontSize: 12),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              CardBox(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Izin lokasi',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 6),
                    Text(switch (location.access) {
                      LocationAccess.ready => 'Aktif. Posisimu dipakai untuk jarak, trip, dan deteksi SPBU saat aplikasi terbuka.',
                      LocationAccess.unknown => 'Belum diperiksa.',
                      _ => location.problemMessage ?? '',
                    }),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: [
                        if (!location.isReady)
                          FilledButton(
                            onPressed: location.request,
                            child: const Text('Izinkan lokasi'),
                          ),
                        OutlinedButton(
                          onPressed: location.openAppSettings,
                          child: const Text('Pengaturan aplikasi'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              const CardBox(
                child: Text(
                  'Ubin peta disimpan sementara di perangkat (maks. 200 MB, 7 hari) agar peta lebih cepat dan hemat data. Peta © OpenStreetMap contributors.',
                  style: TextStyle(
                    color: AppColors.muted,
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  static const faqs = [
    (
      'Apakah OtoKu butuh akun?',
      'Tidak. Semua data tersimpan lokal di perangkat ini. Tidak ada server, akun, atau sinkronisasi.',
    ),
    (
      'Apakah pembayaran sungguhan?',
      'Tidak. Checkout dan status pesanan hanyalah simulasi; tidak ada uang yang diproses.',
    ),
    (
      'Apakah data OBD asli?',
      'Tidak. Adaptor, data mesin, dan kode masalah adalah simulasi dan selalu diberi label.',
    ),
    (
      'Kenapa jarak ke bengkel berbeda dari Google Maps?',
      'Jarak di daftar adalah garis lurus dari posisimu. Tombol Rute & ETA memakai OSRM untuk jarak lewat jalan.',
    ),
    (
      'Apakah trip terekam saat layar mati?',
      'Tidak. Trip GPS hanya terekam selama OtoKu terbuka.',
    ),
    (
      'Bagaimana menghapus data?',
      'Buka Akun → Data & Privasi → Hapus data lokal.',
    ),
  ];

  @override
  Widget build(BuildContext context) => AppPage(
    title: 'Pusat Bantuan',
    child: ScrollPage(
      child: Column(
        children: [
          for (final (q, a) in faqs)
            CardBox(
              padding: EdgeInsets.zero,
              child: ExpansionTile(
                shape: const Border(),
                title: Text(
                  q,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
                childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                expandedCrossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    a,
                    style: const TextStyle(color: AppColors.muted, height: 1.4),
                  ),
                ],
              ),
            ),
        ],
      ),
    ),
  );
}

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) => AppPage(
    title: 'Tentang OtoKu',
    child: const ScrollPage(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'OtoKu',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
          ),
          SizedBox(height: 6),
          Text(
            'Prototipe pendamping kendaraan yang berjalan sepenuhnya lokal: tanpa backend, akun, atau pembayaran nyata.',
            style: TextStyle(height: 1.4),
          ),
          SectionTitle('Atribusi'),
          CardBox(
            child: Text(
              'Peta © OpenStreetMap contributors (ODbL). Rute: OSRM (router.project-osrm.org). Foto produk adalah ilustrasi dari Wikimedia Commons; kredit ada di assets/product_images/ATTRIBUTION.md. Lokasi tempat berasal dari OpenStreetMap; jam dan layanan adalah contoh yang belum diverifikasi.',
              style: TextStyle(height: 1.45),
            ),
          ),
        ],
      ),
    ),
  );
}

class DataPrivacyScreen extends StatelessWidget {
  const DataPrivacyScreen({super.key, required this.state});
  final OtoKuState state;

  Future<void> _reset(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus data lokal?'),
        content: const Text(
          'Kendaraan, catatan, pesanan, trip, dan keranjang di perangkat ini akan dihapus dan tidak bisa dikembalikan.',
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
    if (ok != true) return;
    await state.resetLocalData();
    if (context.mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Data lokal dihapus.')));
      ServicesScope.of(context).goToTab(context, AppServices.tabHome);
    }
  }

  @override
  Widget build(BuildContext context) => AppPage(
    title: 'Data & Privasi',
    child: ScrollPage(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const CardBox(
            child: Text(
              'Semua data (kendaraan, catatan, pesanan, trip) tersimpan di database SQLite pada perangkat ini. Lokasi hanya dipakai saat aplikasi terbuka dan tidak dikirim ke server OtoKu. Peta dan rute memakai layanan OpenStreetMap/OSRM yang menerima permintaan ubin dan koordinat rute.',
              style: TextStyle(height: 1.45),
            ),
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            key: const ValueKey('reset-data'),
            onPressed: () => _reset(context),
            icon: const Icon(Icons.delete_forever_outlined),
            label: const Text('Hapus data lokal'),
          ),
        ],
      ),
    ),
  );
}
