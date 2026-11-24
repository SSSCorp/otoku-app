import 'package:flutter/material.dart';

import '../models/commerce.dart';
import '../services/app_services.dart';
import '../state/oto_ku_state.dart';
import '../ui/common.dart';
import '../ui/product_art.dart';
import 'obd_screens.dart';
import 'orders_screens.dart';

class CatalogScreen extends StatefulWidget {
  final OtoKuState state;
  const CatalogScreen({super.key, required this.state});
  @override
  State<CatalogScreen> createState() => _CatalogState();
}

class _CatalogState extends State<CatalogScreen> {
  static const _categories = [
    'Semua',
    'Oli & Cairan',
    'Rem',
    'Filter',
    'Aki',
    'Aksesori',
  ];
  String query = '', cat = 'Semua';
  final _gridKey = GlobalKey();

  OtoKuState get state => widget.state;

  void _showAllParts() {
    setState(() {
      query = '';
      cat = 'Semua';
    });
    final target = _gridKey.currentContext;
    if (target != null) {
      Scrollable.ensureVisible(
        target,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOut,
      );
    }
  }

  void _addToCart(Product p) {
    state.add(p);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text('${p.name} ditambahkan ke keranjang.')),
      );
  }

  @override
  Widget build(BuildContext c) {
    final list = state.products
        .where(
          (p) =>
              (cat == 'Semua' || p.category == cat) &&
              (query.isEmpty ||
                  '${p.name} ${p.category}'.toLowerCase().contains(
                    query.toLowerCase().trim(),
                  )),
        )
        .toList();
    final filtered = query.isNotEmpty || cat != 'Semua';
    return SafeArea(
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 16, 0),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Toko',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -.8,
                      ),
                    ),
                  ),
                  Badge(
                    isLabelVisible: state.cart.isNotEmpty,
                    label: Text('${state.cart.length}'),
                    child: Material(
                      color: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: IconButton(
                        key: const ValueKey('shop-cart'),
                        tooltip: 'Keranjang',
                        onPressed: () => push(c, CheckoutScreen(state: state)),
                        icon: const Icon(Icons.shopping_bag_outlined),
                        constraints: const BoxConstraints.tightFor(
                          width: 48,
                          height: 48,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
              child: TextField(
                onChanged: (x) => setState(() => query = x),
                decoration: InputDecoration(
                  hintText: 'Cari oli, kampas rem, aki…',
                  prefixIcon: const Icon(Icons.search, color: AppColors.muted),
                  filled: true,
                  fillColor: AppColors.surfaceLow,
                  border: OutlineInputBorder(
                    borderSide: BorderSide.none,
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: _ShopBanner(state: state, onShowParts: _showAllParts),
            ),
          ),
          SliverToBoxAdapter(
            child: SizedBox(
              height: 52,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
                itemCount: _categories.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (_, i) {
                  final name = _categories[i];
                  final on = cat == name;
                  return Material(
                    color: on ? AppColors.ink : Colors.white,
                    shape: StadiumBorder(
                      side: BorderSide(
                        color: on ? AppColors.ink : AppColors.border,
                      ),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: InkWell(
                      onTap: () => setState(() => cat = name),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 18),
                        child: Center(
                          child: Text(
                            name,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: on ? Colors.white : AppColors.ink,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          SliverToBoxAdapter(
            key: _gridKey,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Pilihan untuk ${state.vehicle.name}',
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -.3,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          'Produk (${list.length})',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.muted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (filtered)
                    TextButton(
                      onPressed: () => setState(() {
                        query = '';
                        cat = 'Semua';
                      }),
                      child: const Text(
                        'Hapus filter',
                        style: TextStyle(
                          color: AppColors.red,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          if (list.isEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: CardBox(
                  child: Column(
                    children: [
                      const Icon(
                        Icons.search_off_outlined,
                        size: 34,
                        color: AppColors.muted,
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Produk tidak ditemukan',
                        style: TextStyle(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Coba kata kunci atau kategori lain.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppColors.muted),
                      ),
                      TextButton(
                        onPressed: () => setState(() {
                          query = '';
                          cat = 'Semua';
                        }),
                        child: const Text('Tampilkan semua produk'),
                      ),
                    ],
                  ),
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverGrid.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  mainAxisExtent: 272,
                ),
                itemCount: list.length,
                itemBuilder: (_, i) {
                  final p = list[i];
                  return ProductGridCard(
                    p: p,
                    fitment: p.fitmentFor(state.vehicle),
                    onTap: () =>
                        push(c, ProductDetailScreen(state: state, product: p)),
                    onAdd: () => _addToCart(p),
                  );
                },
              ),
            ),
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(20, 16, 20, 28),
              child: Text(
                'Kecocokan ditampilkan jika sudah dikonfirmasi untuk kendaraan aktif. Stok belum dikonfirmasi · demo.',
                style: TextStyle(color: AppColors.muted, fontSize: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Promotional carousel at the top of the shop. The OBD adapter is a
/// catalogue entry only: its button opens the simulated OBD flow.
class _ShopBanner extends StatefulWidget {
  const _ShopBanner({required this.state, required this.onShowParts});
  final OtoKuState state;
  final VoidCallback onShowParts;

  @override
  State<_ShopBanner> createState() => _ShopBannerState();
}

class _ShopBannerState extends State<_ShopBanner> {
  final _controller = PageController();
  int _page = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final services = ServicesScope.of(context);
    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: SizedBox(
            height: 204,
            child: PageView(
              controller: _controller,
              onPageChanged: (i) => setState(() => _page = i),
              children: [
                _BannerSlide(
                  key: const ValueKey('obd-promo'),
                  dark: true,
                  eyebrow: 'PROMO · ADAPTOR OBD',
                  title: 'Kenali kondisi motormu sendiri',
                  caption: 'Harga',
                  price: 'Rp 179.000',
                  note: 'Pembelian belum tersedia · coba lewat simulasi',
                  action: 'Coba Simulasi',
                  actionKey: const ValueKey('obd-promo-open'),
                  onTap: () => openObd(context, widget.state),
                  visual: const _ObdChip(),
                ),
                _BannerSlide(
                  eyebrow: 'UNTUK HONDA BEAT',
                  title: 'Perawatan rutin, suku cadang yang pas',
                  caption: 'Mulai dari',
                  price: 'Rp 42.000',
                  action: 'Lihat Sparepart',
                  onTap: widget.onShowParts,
                  visual: const _ProductStack(),
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.surfaceLow,
                      AppColors.surfaceHigh,
                      Color(0xFFDCE2F3),
                    ],
                  ),
                ),
                _BannerSlide(
                  eyebrow: 'BOOKING LAYANAN',
                  title: 'Servis di bengkel terdekat, tanpa antre',
                  note: 'Pilih jadwal, bayar langsung di bengkel.',
                  action: 'Cari Bengkel',
                  onTap: () => services.goToTab(context, AppServices.tabPeta),
                  visual: Container(
                    width: 76,
                    height: 76,
                    decoration: BoxDecoration(
                      color: AppColors.redTint,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: const Icon(
                      Icons.place_outlined,
                      size: 34,
                      color: AppColors.red,
                    ),
                  ),
                  outlined: true,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (var i = 0; i < 3; i++)
              InkWell(
                onTap: () => _controller.animateToPage(
                  i,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOut,
                ),
                child: SizedBox(
                  width: 26,
                  height: 32,
                  child: Center(
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: i == _page ? 20 : 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: i == _page
                            ? AppColors.red
                            : const Color(0xFFC5CDE4),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _BannerSlide extends StatelessWidget {
  const _BannerSlide({
    super.key,
    required this.eyebrow,
    required this.title,
    required this.action,
    required this.onTap,
    required this.visual,
    this.caption,
    this.price,
    this.note,
    this.actionKey,
    this.dark = false,
    this.outlined = false,
    this.gradient,
  });
  final String eyebrow, title, action;
  final String? caption, price, note;
  final Key? actionKey;
  final VoidCallback onTap;
  final Widget visual;
  final bool dark, outlined;
  final Gradient? gradient;

  @override
  Widget build(BuildContext context) {
    final fg = dark ? Colors.white : AppColors.ink;
    final sub = dark ? const Color(0xFFD9DCE3) : AppColors.muted;
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 18, 18, 16),
      decoration: BoxDecoration(
        color: outlined ? Colors.white : null,
        border: outlined ? Border.all(color: AppColors.border) : null,
        borderRadius: BorderRadius.circular(22),
        gradient: dark
            ? const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppColors.navy, AppColors.darkSurface],
              )
            : gradient,
      ),
      child: Stack(
        children: [
          Positioned(
            right: -30,
            top: -10,
            child: Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: (dark ? Colors.white : AppColors.border).withValues(
                    alpha: dark ? .12 : 1,
                  ),
                ),
              ),
            ),
          ),
          Positioned(right: 4, top: 12, child: visual),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                eyebrow,
                style: TextStyle(
                  fontSize: 10,
                  letterSpacing: .8,
                  fontWeight: FontWeight.w800,
                  color: dark ? const Color(0xFFFFB3B6) : AppColors.muted,
                ),
              ),
              const SizedBox(height: 6),
              SizedBox(
                width: 200,
                child: Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: fg,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -.5,
                    height: 1.2,
                  ),
                ),
              ),
              const Spacer(),
              if (note != null && price != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    note!,
                    style: TextStyle(fontSize: 10, color: sub),
                  ),
                ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: price != null
                        ? Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                caption ?? '',
                                style: TextStyle(fontSize: 11, color: sub),
                              ),
                              Text(
                                price!,
                                style: TextStyle(
                                  color: fg,
                                  fontSize: 21,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -.5,
                                  height: 1.1,
                                ),
                              ),
                            ],
                          )
                        : Text(
                            note ?? '',
                            style: TextStyle(fontSize: 12, color: sub),
                          ),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    key: actionKey,
                    onPressed: onTap,
                    style: FilledButton.styleFrom(
                      backgroundColor: !dark && price != null
                          ? AppColors.ink
                          : AppColors.red,
                      minimumSize: const Size(0, 46),
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(action),
                        const SizedBox(width: 6),
                        const Icon(Icons.arrow_forward, size: 16),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ObdChip extends StatelessWidget {
  const _ObdChip();
  @override
  Widget build(BuildContext context) => Container(
    width: 84,
    height: 84,
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(24),
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF3A4250), Color(0xFF1B222E)],
      ),
      border: Border.all(color: Colors.white.withValues(alpha: .16)),
    ),
    child: const Icon(Icons.memory, color: Colors.white, size: 40),
  );
}

class _ProductStack extends StatelessWidget {
  const _ProductStack();
  Widget _dot(String asset) => Container(
    width: 62,
    height: 62,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: Colors.white,
      border: Border.all(color: Colors.white, width: 3),
    ),
    clipBehavior: Clip.antiAlias,
    child: Image.asset(asset, fit: BoxFit.cover, excludeFromSemantics: true),
  );
  @override
  Widget build(BuildContext context) => SizedBox(
    width: 130,
    height: 150,
    child: Stack(
      children: [
        Positioned(
          right: 0,
          top: 0,
          child: _dot('assets/product_images/engine_oil.jpg'),
        ),
        Positioned(
          right: 48,
          top: 38,
          child: _dot('assets/product_images/air_filter.jpg'),
        ),
        Positioned(
          right: 0,
          top: 74,
          child: _dot('assets/product_images/motorcycle_brake_pads.jpg'),
        ),
      ],
    ),
  );
}

class ProductGridCard extends StatelessWidget {
  final Product p;
  final ProductFitment fitment;
  final VoidCallback onTap, onAdd;
  const ProductGridCard({
    super.key,
    required this.p,
    required this.fitment,
    required this.onTap,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext c) {
    final (label, bg, fg) = switch (fitment) {
      ProductFitment.confirmed => (
        'Cocok',
        AppColors.greenTint,
        const Color(0xFF005C27),
      ),
      ProductFitment.possibleUnverified => (
        'Mungkin cocok',
        AppColors.amberTint,
        AppColors.ink,
      ),
      ProductFitment.incompatible => (
        'Tidak cocok',
        AppColors.redTint,
        const Color(0xFF6B0D11),
      ),
      ProductFitment.unknown => (
        'Belum diketahui',
        Colors.white,
        AppColors.ink,
      ),
    };
    final blocked = fitment == ProductFitment.incompatible;
    return Opacity(
      opacity: blocked ? .78 : 1,
      child: CardBox(
        onTap: onTap,
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 132,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: ColoredBox(
                        color: AppColors.surfaceLow,
                        child: Image.asset(
                          p.imageAsset,
                          fit: BoxFit.cover,
                          semanticLabel: 'Foto produk ilustrasi',
                          errorBuilder: (_, _, _) =>
                              CustomPaint(painter: PartPainter(p.icon)),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    left: 8,
                    top: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: bg,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        label,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: fg,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 10, 4, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    p.category,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.muted,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    p.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.only(left: 4),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      p.price,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -.3,
                      ),
                    ),
                  ),
                  IconButton.filled(
                    tooltip: blocked
                        ? 'Tidak cocok untuk kendaraan aktif'
                        : 'Tambah ke keranjang',
                    onPressed: blocked ? null : onAdd,
                    style: IconButton.styleFrom(
                      backgroundColor: AppColors.red,
                      disabledBackgroundColor: AppColors.surfaceLow,
                      minimumSize: const Size(44, 44),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    icon: const Icon(Icons.add, size: 20),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ProductDetailScreen extends StatelessWidget {
  final OtoKuState state;
  final Product product;
  const ProductDetailScreen({
    super.key,
    required this.state,
    required this.product,
  });

  @override
  Widget build(BuildContext c) {
    final fitment = product.fitmentFor(state.vehicle);
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      height: 245,
                      child: Stack(
                        children: [
                          Container(
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: const Color(0xFFECEDEA),
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(18),
                              child: Image.asset(
                                product.imageAsset,
                                fit: BoxFit.contain,
                                semanticLabel: 'Foto ilustrasi ${product.name}',
                              ),
                            ),
                          ),
                          Positioned(
                            top: 10,
                            left: 10,
                            child: CircleIconButton(
                              icon: Icons.arrow_back,
                              onTap: () => Navigator.pop(c),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      product.name,
                      style: const TextStyle(
                        fontSize: 21,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      '${product.category} · Foto ilustrasi katalog',
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Text(
                          product.price,
                          style: const TextStyle(
                            color: AppColors.red,
                            fontSize: 21,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const Spacer(),
                        const StatusChip('Data katalog demo', AppColors.muted),
                      ],
                    ),
                    const SizedBox(height: 10),
                    if (fitment == ProductFitment.unknown ||
                        fitment == ProductFitment.possibleUnverified)
                      CardBox(
                        child: Text(
                          fitment == ProductFitment.possibleUnverified
                              ? 'Kecocokan produk ini belum diverifikasi untuk kendaraan Anda.'
                              : 'Informasi kompatibilitas belum tersedia.',
                          style: const TextStyle(color: AppColors.muted),
                        ),
                      ),
                    if (fitment == ProductFitment.incompatible)
                      const CardBox(
                        color: AppColors.redTint,
                        child: Text(
                          'Tidak cocok untuk kendaraan Anda',
                          style: TextStyle(
                            color: AppColors.red,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    const CardBox(
                      child: Text(
                        'Produk dan harga ini data demo lokal. Stok, penjual, dan ketentuan pemasangan belum dikonfirmasi.',
                        style: TextStyle(color: AppColors.muted, height: 1.4),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SafeArea(
              top: false,
              child: Container(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  border: Border(top: BorderSide(color: AppColors.border)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: fitment != ProductFitment.incompatible
                            ? () {
                                state.add(product);
                                ScaffoldMessenger.of(c).showSnackBar(
                                  const SnackBar(
                                    content: Text('Ditambahkan ke keranjang'),
                                  ),
                                );
                              }
                            : null,
                        child: const Text('Tambah ke Keranjang'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: FilledButton(
                        onPressed: fitment != ProductFitment.incompatible
                            ? () {
                                state.add(product);
                                push(c, CheckoutScreen(state: state));
                              }
                            : null,
                        child: const Text('Beli Sekarang'),
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

class CircleIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const CircleIconButton({super.key, required this.icon, required this.onTap});
  @override
  Widget build(BuildContext context) => Material(
    color: Colors.white,
    shape: const CircleBorder(),
    child: IconButton(
      onPressed: onTap,
      icon: Icon(icon, size: 20),
      constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
    ),
  );
}

class FeatureRow extends StatelessWidget {
  final IconData icon;
  final String title, subtitle;
  const FeatureRow({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
  });
  @override
  Widget build(BuildContext context) => ListTile(
    contentPadding: EdgeInsets.zero,
    leading: Icon(icon, color: AppColors.ink),
    title: Text(
      title,
      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
    ),
    subtitle: Text(
      subtitle,
      style: const TextStyle(color: AppColors.muted, fontSize: 11),
    ),
  );
}
