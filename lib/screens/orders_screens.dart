import 'package:flutter/material.dart';

import '../models/commerce.dart';
import '../services/app_services.dart';
import '../state/oto_ku_state.dart';
import '../ui/common.dart';
import '../ui/product_art.dart';
import 'account_screens.dart';

Color statusColor(String status) => switch (status) {
  Pesanan.done => AppColors.green,
  Pesanan.cancelled => AppColors.muted,
  _ => AppColors.amber,
};

/// Pesanan tab: Sparepart purchases and Booking layanan, newest first.
class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key, required this.state});
  final OtoKuState state;

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  String filter = 'Semua';

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: widget.state,
    builder: (context, _) {
      final orders = widget.state.orders
          .where(
            (o) => switch (filter) {
              'Sparepart' => o.kind == PesananKind.sparepart,
              'Layanan' => o.kind == PesananKind.layanan,
              _ => true,
            },
          )
          .toList();
      return ColoredBox(
        color: AppColors.bg,
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 24),
            children: [
              const Text(
                'Pesanan Saya',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -.8,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${orders.length} pesanan',
                style: const TextStyle(color: AppColors.muted, fontSize: 13),
              ),
              const SizedBox(height: 16),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'Semua', label: Text('Semua')),
                  ButtonSegment(value: 'Sparepart', label: Text('Sparepart')),
                  ButtonSegment(value: 'Layanan', label: Text('Layanan')),
                ],
                selected: {filter},
                onSelectionChanged: (s) => setState(() => filter = s.first),
                showSelectedIcon: false,
                style: SegmentedButton.styleFrom(
                  backgroundColor: AppColors.surfaceLow,
                  foregroundColor: AppColors.muted,
                  selectedBackgroundColor: AppColors.red,
                  selectedForegroundColor: Colors.white,
                  side: BorderSide.none,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              if (orders.isEmpty)
                CardBox(
                  child: Column(
                    children: [
                      const Icon(
                        Icons.receipt_long_outlined,
                        size: 36,
                        color: AppColors.muted,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        filter == 'Semua'
                            ? 'Belum ada pesanan'
                            : 'Belum ada pesanan $filter',
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Pesanan sparepart dan booking layanan kamu akan muncul di sini.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppColors.muted),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        children: [
                          TextButton(
                            onPressed: () =>
                                ServicesScope.of(context).tab.value =
                                    AppServices.tabShop,
                            child: const Text('Belanja di Shop'),
                          ),
                          TextButton(
                            onPressed: () =>
                                ServicesScope.of(context).tab.value =
                                    AppServices.tabPeta,
                            child: const Text('Cari bengkel'),
                          ),
                        ],
                      ),
                    ],
                  ),
                )
              else
                for (final order in orders)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: OrderCard(
                      order: order,
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => OrderDetailScreen(
                            state: widget.state,
                            orderId: order.id,
                          ),
                        ),
                      ),
                    ),
                  ),
              if (orders.isNotEmpty)
                const Padding(
                  padding: EdgeInsets.fromLTRB(4, 4, 4, 0),
                  child: Text(
                    'Status pesanan adalah simulasi lokal. Tidak ada pembayaran atau pengiriman nyata.',
                    style: TextStyle(color: AppColors.muted, fontSize: 12),
                  ),
                ),
            ],
          ),
        ),
      );
    },
  );
}

class OrderCard extends StatelessWidget {
  const OrderCard({super.key, required this.order, required this.onTap});
  final Pesanan order;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => CardBox(
    key: ValueKey('order-${order.id}'),
    onTap: onTap,
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        order.isBooking
            ? Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: AppColors.surfaceLow,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.build_circle_outlined,
                  color: AppColors.red,
                  size: 30,
                ),
              )
            : ProductArt(icon: order.title.contains('Oli') ? 'oil' : 'brake'),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      order.id,
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  StatusChip(order.status, statusColor(order.status)),
                  const Icon(
                    Icons.chevron_right,
                    size: 18,
                    color: AppColors.muted,
                  ),
                ],
              ),
              const SizedBox(height: 5),
              Text(
                order.title,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                ),
              ),
              if (order.detail.isNotEmpty)
                Text(
                  order.detail,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: AppColors.muted, fontSize: 12),
                ),
              const SizedBox(height: 8),
              Text(
                Pesanan.dateLabel(order.createdAt),
                style: const TextStyle(color: AppColors.muted, fontSize: 12),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class OrderDetailScreen extends StatelessWidget {
  const OrderDetailScreen({
    super.key,
    required this.state,
    required this.orderId,
  });
  final OtoKuState state;
  final String orderId;

  Future<void> _cancel(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Batalkan pesanan?'),
        content: const Text(
          'Pesanan ini ditandai Dibatalkan di perangkat ini.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Kembali'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Batalkan'),
          ),
        ],
      ),
    );
    if (ok == true) await state.cancelPesanan(orderId);
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: state,
    builder: (context, _) {
      final order = state.orderById(orderId);
      if (order == null) {
        return const AppPage(
          title: 'Detail Pesanan',
          child: Center(child: Text('Pesanan tidak ditemukan.')),
        );
      }
      final next = order.nextStep;
      final vehicle = state.vehicles
          .where((v) => v.id == order.vehicleId)
          .firstOrNull;
      return AppPage(
        title: 'Detail Pesanan',
        child: ScrollPage(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                order.id,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 12),
              CardBox(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text(
                          'Status: ',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                        StatusChip(order.status, statusColor(order.status)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Status ini simulasi lokal; belum ada konfirmasi pembayaran, penjual, atau bengkel yang sebenarnya.',
                      style: TextStyle(
                        color: AppColors.muted,
                        height: 1.4,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              const SectionTitle('Ringkasan'),
              CardBox(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      order.title,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 6),
                    if (order.isBooking) ...[
                      if (order.services.isNotEmpty)
                        Text('Layanan: ${order.services.join(', ')}'),
                      if (order.scheduledDate != null)
                        Text(
                          'Jadwal: ${Pesanan.dateLabel(order.scheduledDate!)} ${order.timeSlot ?? ''}',
                        ),
                      if (order.notes.trim().isNotEmpty)
                        Text('Catatan: ${order.notes.trim()}'),
                    ] else
                      for (final line in order.lines)
                        Text(
                          '${line.quantity}x ${line.name} · ${formatRupiah(line.subtotal)}',
                        ),
                    if (vehicle != null)
                      Text('Kendaraan: ${vehicle.name} · ${vehicle.plate}'),
                    Text('Dibuat: ${Pesanan.dateLabel(order.createdAt)}'),
                  ],
                ),
              ),
              const SectionTitle('Pembayaran'),
              CardBox(
                child: Text(
                  order.isBooking
                      ? '${order.total > 0 ? 'Estimasi biaya layanan ${formatRupiah(order.total)} (demo). ' : 'Estimasi biaya belum tersedia. '}Dibayar langsung di bengkel; tidak ada pembayaran di aplikasi.'
                      : 'Total ${formatRupiah(order.total)}. Belum ada pembayaran; integrasi pembayaran tidak tersedia pada prototipe ini.',
                  style: const TextStyle(height: 1.5),
                ),
              ),
              if (next != null) ...[
                const SizedBox(height: 16),
                FilledButton(
                  key: const ValueKey('advance-order'),
                  onPressed: () => state.advancePesanan(order.id),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                  ),
                  child: Text('${next.$2} (simulasi)'),
                ),
              ],
              if (order.canCancel) ...[
                const SizedBox(height: 8),
                OutlinedButton(
                  key: const ValueKey('cancel-order'),
                  onPressed: () => _cancel(context),
                  child: const Text('Batalkan Pesanan'),
                ),
              ],
            ],
          ),
        ),
      );
    },
  );
}

class CheckoutScreen extends StatelessWidget {
  const CheckoutScreen({super.key, required this.state});
  final OtoKuState state;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: state,
    builder: (context, _) {
      final items = state.products
          .where((p) => state.quantityOf(p) > 0)
          .toList();
      return AppPage(
        title: 'Keranjang & Checkout',
        child: ScrollPage(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Ringkasan pesanan',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 8),
              if (items.isEmpty)
                CardBox(
                  child: Column(
                    children: [
                      const Icon(
                        Icons.shopping_bag_outlined,
                        size: 34,
                        color: AppColors.muted,
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Keranjang kosong. Tambahkan produk dari Shop.',
                      ),
                      TextButton(
                        onPressed: () =>
                            ServicesScope.of(context)
                                .goToTab(context, AppServices.tabShop),
                        child: const Text('Buka Shop'),
                      ),
                    ],
                  ),
                ),
              for (final product in items)
                CardBox(
                  child: Row(
                    children: [
                      ProductArt(icon: product.icon, image: product.imageAsset),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              product.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              product.price,
                              style: const TextStyle(
                                color: AppColors.muted,
                                fontSize: 12,
                              ),
                            ),
                            Row(
                              children: [
                                IconButton(
                                  tooltip: 'Kurangi jumlah',
                                  onPressed: () => state.removeOne(product),
                                  icon: const Icon(Icons.remove_circle_outline),
                                ),
                                Text(
                                  '${state.quantityOf(product)}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                IconButton(
                                  tooltip: 'Tambah jumlah',
                                  onPressed: () => state.add(product),
                                  icon: const Icon(Icons.add_circle_outline),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Text(
                        formatRupiah(
                          product.priceValue * state.quantityOf(product),
                        ),
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ],
                  ),
                ),
              const SectionTitle('Alamat pengiriman · simulasi'),
              CardBox(
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => AddressScreen(state: state),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        state.address.isEmpty
                            ? 'Alamat belum diatur (opsional). Checkout ini simulasi lokal; tidak ada pengiriman nyata.'
                            : state.address,
                      ),
                    ),
                    const Icon(Icons.chevron_right),
                  ],
                ),
              ),
              const SectionTitle('Pembayaran'),
              const CardBox(
                child: Text(
                  'Belum ada pembayaran. Pesanan akan berstatus Menunggu pembayaran.',
                ),
              ),
              const SizedBox(height: 12),
              CardBox(
                child: Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Subtotal demo',
                        style: TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ),
                    Text(
                      formatRupiah(state.cartSubtotal),
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              FilledButton(
                onPressed: items.isEmpty
                    ? null
                    : () async {
                        final order = await state.checkout();
                        if (!context.mounted) return;
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute<void>(
                            builder: (_) => OrderConfirmationScreen(
                              state: state,
                              order: order,
                            ),
                          ),
                        );
                      },
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(52),
                ),
                child: const Text('Buat Pesanan Demo'),
              ),
            ],
          ),
        ),
      );
    },
  );
}

class OrderConfirmationScreen extends StatelessWidget {
  const OrderConfirmationScreen({
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
      title: 'Pesanan Dibuat',
      child: ScrollPage(
        child: Column(
          children: [
            const CardBox(
              color: AppColors.amberTint,
              child: Column(
                children: [
                  Icon(
                    Icons.receipt_long_outlined,
                    color: AppColors.amber,
                    size: 44,
                  ),
                  SizedBox(height: 10),
                  Text(
                    'Menunggu pembayaran',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'Pesanan demo tersimpan lokal. Tidak ada pembayaran atau pengiriman yang dilakukan.',
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
                  Text('Total ${formatRupiah(order.total)}'),
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
