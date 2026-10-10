import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

void main() => runApp(const OtoKuApp());

class AppColors {
  static const red = Color(0xFFE21B23), redDark = Color(0xFFB81218);
  static const ink = Color(0xFF171717), muted = Color(0xFF6B6B6B);
  static const bg = Color(0xFFF7F7F7), border = Color(0xFFE8E8E8);
  static const green = Color(0xFF22A447), amber = Color(0xFFF59E0B);
  static const redTint = Color(0xFFFDECEC), greenTint = Color(0xFFE6F6EA);
  static const amberTint = Color(0xFFFEF3DC), darkSurface = Color(0xFF1A1A1A);
}

class Vehicle {
  final String brand, model, plate, type;
  final int year, mileage;
  Vehicle({
    required this.brand,
    required this.model,
    required this.plate,
    required this.type,
    required this.year,
    required this.mileage,
  });
  String get name => '$brand $model $year';
}

enum ProductFitment { confirmed, possibleUnverified, incompatible, unknown }

class Product {
  final String name, category, price, icon;
  final ProductFitment fitment;
  Product(
    this.name,
    this.category,
    this.price,
    this.icon, {
    this.fitment = ProductFitment.unknown,
  });
}

class Workshop {
  final String name, rating, distance, services;
  Workshop(this.name, this.rating, this.distance, this.services);
}

class OtoKuState extends ChangeNotifier {
  final vehicle = Vehicle(
    brand: 'Honda',
    model: 'Beat',
    plate: 'B 1234 XYZ',
    type: 'CBS',
    year: 2021,
    mileage: 12450,
  );
  bool obdConnected = false;
  final List<Product> products = [
    Product(
      'Oli Mesin Honda AHM SPX2',
      'Oli & Cairan',
      'Rp 65.000',
      'oil',
      fitment: ProductFitment.confirmed,
    ),
    Product(
      'Kampas Rem Depan Beat',
      'Rem',
      'Rp 85.000',
      'brake',
      fitment: ProductFitment.confirmed,
    ),
    Product(
      'Filter Udara Honda Beat',
      'Filter',
      'Rp 42.000',
      'filter',
      fitment: ProductFitment.confirmed,
    ),
    Product('Aki Motor YTZ5S', 'Aki', 'Rp 185.000', 'battery'),
    Product('Lampu LED Universal', 'Aksesori', 'Rp 75.000', 'lamp'),
    Product('Scanner OBD Bluetooth', 'Perangkat OBD', 'Rp 249.000', 'obd'),
    Product(
      'Kampas Rem Mobil Avanza',
      'Rem',
      'Rp 210.000',
      'brake',
      fitment: ProductFitment.incompatible,
    ),
  ];
  final workshops = [
    Workshop(
      'Bengkel Jaya Motor',
      '4.7 (238)',
      '2.1 km',
      'Servis Rutin · Ganti Oli',
    ),
    Workshop(
      'AutoCare Plus',
      '4.6 (120)',
      '3.4 km',
      'Spesialis CVT · Rem · Oli',
    ),
    Workshop('Speed Motor', '4.5 (98)', '4.2 km', 'Servis Lengkap · Body Part'),
  ];
  final cart = <Product>[];
  final orders = <String>[
    '#SP250922001 • Kampas Rem Depan • Honda Beat • Rp 85.000 • Diproses • 22 Sep 2025',
    '#SP250918003 • Oli Shell Advance • Rp 79.000 • Pesanan Selesai • 18 Sep 2025',
    '#SV250915002 • Ganti Oli • Bengkel Jaya Motor • Rp 60.000 • Selesai • 15 Sep 2025',
    '#SV250901004 • Servis Rutin • Bengkel AutoCare • Rp 80.000 • Selesai • 01 Sep 2025',
  ];
  void connectObd() {
    obdConnected = true;
    notifyListeners();
  }

  void disconnectObd() {
    obdConnected = false;
    notifyListeners();
  }

  void add(Product p) {
    if (!cart.contains(p)) cart.add(p);
    notifyListeners();
  }

  void checkout(String label) {
    orders.insert(
      0,
      '#SP${DateTime.now().millisecondsSinceEpoch.toString().substring(5)} • $label • Diproses',
    );
    cart.clear();
    notifyListeners();
  }

  void addBooking(String workshop) {
    orders.insert(
      0,
      '#SV${DateTime.now().millisecondsSinceEpoch.toString().substring(5)} • Booking $workshop • Diproses',
    );
    notifyListeners();
  }
}

class OtoKuApp extends StatefulWidget {
  const OtoKuApp({super.key});
  @override
  State<OtoKuApp> createState() => _OtoKuAppState();
}

class _OtoKuAppState extends State<OtoKuApp> {
  final state = OtoKuState();
  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: state,
    builder: (context, child) => MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'OtoKu',
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: AppColors.bg,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.red,
          primary: AppColors.red,
          surface: Colors.white,
        ),
        fontFamily: 'SF Pro Text',
        fontFamilyFallback: const ['Roboto', 'Arial'],
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.red,
            foregroundColor: Colors.white,
            minimumSize: const Size(48, 48),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(11),
            ),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.red,
            side: const BorderSide(color: AppColors.red),
            minimumSize: const Size(48, 48),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(11),
            ),
          ),
        ),
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: Colors.white,
          indicatorColor: AppColors.redTint,
          height: 64,
          labelTextStyle: WidgetStateProperty.resolveWith(
            (states) => TextStyle(
              fontSize: 11,
              fontWeight: states.contains(WidgetState.selected)
                  ? FontWeight.w700
                  : FontWeight.w500,
              color: states.contains(WidgetState.selected)
                  ? AppColors.red
                  : AppColors.muted,
            ),
          ),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.bg,
          foregroundColor: AppColors.ink,
          elevation: 0,
        ),
      ),
      home: SplashScreen(state: state),
    ),
  );
}

class SplashScreen extends StatefulWidget {
  final OtoKuState state;
  const SplashScreen({super.key, required this.state});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Timer(const Duration(milliseconds: 1100), () {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => AppShell(state: widget.state)),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.ink,
    body: SafeArea(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CarMark(size: 118),
            const SizedBox(height: 26),
            RichText(
              text: const TextSpan(
                style: TextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -1.4,
                ),
                children: [
                  TextSpan(
                    text: 'Oto',
                    style: TextStyle(color: Colors.white),
                  ),
                  TextSpan(
                    text: 'Ku',
                    style: TextStyle(color: AppColors.red),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              'Perawatan kendaraan lebih mudah,\nselalu terpantau.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white70,
                height: 1.5,
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class AppShell extends StatefulWidget {
  final OtoKuState state;
  const AppShell({super.key, required this.state});
  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int index = 0;
  final pages = const ['Home', 'Shop', 'Peta', 'Pesanan', 'Akun'];
  @override
  Widget build(BuildContext context) {
    final body = [
      HomeScreen(state: widget.state),
      CatalogScreen(state: widget.state),
      WorkshopListScreen(state: widget.state),
      OrdersScreen(state: widget.state),
      AccountScreen(state: widget.state),
    ][index];
    return Scaffold(
      body: body,
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (i) => setState(() => index = i),
        height: 72,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.grid_view_outlined),
            selectedIcon: Icon(Icons.grid_view),
            label: 'Shop',
          ),
          NavigationDestination(
            icon: Icon(Icons.map_outlined),
            selectedIcon: Icon(Icons.map),
            label: 'Peta',
          ),
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long),
            label: 'Pesanan',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Akun',
          ),
        ],
      ),
    );
  }
}

class Page extends StatelessWidget {
  final String title;
  final Widget child;
  final List<Widget>? actions;
  final Widget? bottomBar;
  const Page({
    super.key,
    required this.title,
    required this.child,
    this.actions,
    this.bottomBar,
  });
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(
        title,
        style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
      ),
      actions: actions,
      leading: Navigator.canPop(context)
          ? IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back),
            )
          : null,
    ),
    body: SafeArea(child: child),
    bottomNavigationBar: bottomBar,
  );
}

class ScrollPage extends StatelessWidget {
  final Widget child;
  const ScrollPage({super.key, required this.child});
  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
    child: child,
  );
}

class CardBox extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  final Color color;
  final VoidCallback? onTap;
  const CardBox({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.color = Colors.white,
    this.onTap,
  });
  @override
  Widget build(BuildContext context) => Card(
    margin: EdgeInsets.zero,
    elevation: 0,
    color: color,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(18),
      side: const BorderSide(color: AppColors.border),
    ),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Padding(padding: padding, child: child),
    ),
  );
}

class SectionTitle extends StatelessWidget {
  final String title;
  final String? action;
  final VoidCallback? onTap;
  const SectionTitle(this.title, {super.key, this.action, this.onTap});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 10, top: 24),
    child: Row(
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        const Spacer(),
        if (action != null)
          TextButton(
            onPressed: onTap,
            child: Text(
              action!,
              style: const TextStyle(
                color: AppColors.red,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
      ],
    ),
  );
}

class Pill extends StatelessWidget {
  final String text;
  final bool active;
  final bool selectedTint;
  const Pill(
    this.text, {
    super.key,
    this.active = false,
    this.selectedTint = false,
  });
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
    decoration: BoxDecoration(
      color: active
          ? AppColors.red
          : selectedTint
          ? AppColors.redTint
          : const Color(0xFFF1F1EF),
      borderRadius: BorderRadius.circular(22),
      border: Border.all(
        color: active || selectedTint ? AppColors.red : Colors.transparent,
      ),
    ),
    child: Text(
      text,
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        color: active
            ? Colors.white
            : selectedTint
            ? AppColors.red
            : AppColors.muted,
      ),
    ),
  );
}

class HomeVehicleCard extends StatelessWidget {
  final OtoKuState state;
  final VoidCallback onTap;
  const HomeVehicleCard({super.key, required this.state, required this.onTap});
  @override
  Widget build(BuildContext context) {
    final vehicle = state.vehicle;
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
                              Color(0xFFFCE7E6),
                              Color(0xFFF5D9D6),
                              Color(0xFFF0E8E2),
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
                      child: Image.asset(
                        'assets/honda_beat.png',
                        width: 194,
                        height: 194,
                        fit: BoxFit.contain,
                        alignment: Alignment.centerRight,
                        semanticLabel: 'Honda Beat merah dan hitam',
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
                            '${vehicle.type} · Kendaraan saya',
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
                child: Row(
                  children: [
                    Expanded(
                      child: _VehicleStat(
                        icon: Icons.speed_outlined,
                        value: '12.450',
                        unit: 'km',
                        label: 'JARAK TEMPUH',
                      ),
                    ),
                    Container(width: 1, height: 34, color: AppColors.border),
                    Expanded(
                      child: _VehicleStat(
                        icon: Icons.build_outlined,
                        value: 'Mar 2025',
                        unit: '',
                        label: 'SERVIS TERAKHIR',
                      ),
                    ),
                    Container(width: 1, height: 34, color: AppColors.border),
                    const Expanded(
                      child: _VehicleStat(
                        icon: Icons.favorite_border,
                        value: 'Baik',
                        unit: '',
                        label: 'KONDISI',
                        good: true,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _VehicleStat extends StatelessWidget {
  final IconData icon;
  final String value, unit, label;
  final bool good;
  const _VehicleStat({
    required this.icon,
    required this.value,
    required this.unit,
    required this.label,
    this.good = false,
  });
  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, size: 15, color: good ? AppColors.green : AppColors.muted),
      const SizedBox(height: 4),
      Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: good ? AppColors.green : AppColors.ink,
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
                  RichText(
                    text: const TextSpan(
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.8,
                      ),
                      children: [
                        TextSpan(
                          text: 'Oto',
                          style: TextStyle(color: AppColors.ink),
                        ),
                        TextSpan(
                          text: 'Ku',
                          style: TextStyle(color: AppColors.red),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => showNotificationSheet(context),
                    icon: const Icon(Icons.notifications_none),
                  ),
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: AppColors.ink,
                    child: const Text(
                      'AB',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
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
                HomeVehicleCard(
                  state: state,
                  onTap: () => push(context, VehicleDetailScreen(state: state)),
                ),
                const SizedBox(height: 14),
                SectionTitle(
                  'Perawatan Berikutnya',
                  action: 'Lihat Semua',
                  onTap: () => push(context, MaintenanceScreen(state: state)),
                ),
                MaintenanceCard(
                  onTap: () => push(context, MaintenanceScreen(state: state)),
                ),
                const SizedBox(height: 16),
                state.obdConnected
                    ? ConnectedObdCard(state: state)
                    : LockedObdCard(state: state),
                if (state.obdConnected) ...[
                  SectionTitle(
                    'Data OBD Demo',
                    action: 'Lihat Semua',
                    onTap: () => push(context, ObdScreen(state: state)),
                  ),
                  MetricGrid(
                    onTap: () => push(context, ObdScreen(state: state)),
                  ),
                  SectionTitle(
                    'Kondisi Kendaraan (Demo)',
                    action: 'Lihat Detail',
                    onTap: () => push(context, ObdScreen(state: state)),
                  ),
                  HealthSummary(state: state),
                ],
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

class LockedObdCard extends StatelessWidget {
  final OtoKuState state;
  const LockedObdCard({super.key, required this.state});
  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(16),
      gradient: const LinearGradient(
        colors: [Color(0xFF262626), AppColors.darkSurface],
      ),
      boxShadow: [
        BoxShadow(
          color: AppColors.red.withValues(alpha: .12),
          blurRadius: 24,
          offset: const Offset(0, 5),
        ),
      ],
    ),
    padding: const EdgeInsets.all(16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Hubungkan OBD',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    'Mode simulasi untuk prototipe',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'OBD asli belum diaktifkan. Data yang ditampilkan di prototipe adalah simulasi.',
                    style: TextStyle(
                      color: Colors.white70,
                      height: 1.4,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const OBDIllustration(),
          ],
        ),
        const SizedBox(height: 14),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: () => showObdSheet(context, state),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.red,
              foregroundColor: Colors.white,
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Lihat demo OBD'),
                SizedBox(width: 8),
                Icon(Icons.chevron_right),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
        const Row(
          children: [
            Expanded(
              child: ObdFeature(
                icon: Icons.speed_outlined,
                label: 'Data simulasi',
              ),
            ),
            Expanded(
              child: ObdFeature(
                icon: Icons.manage_search,
                label: 'Deteksi masalah',
              ),
            ),
            Expanded(
              child: ObdFeature(
                icon: Icons.build_outlined,
                label: 'Rekomendasi servis',
              ),
            ),
            Expanded(
              child: ObdFeature(
                icon: Icons.hub_outlined,
                label: 'Terintegrasi sparepart & bengkel',
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

class OBDIllustration extends StatelessWidget {
  const OBDIllustration({super.key});
  @override
  Widget build(BuildContext context) => Container(
    width: 62,
    height: 58,
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: .08),
      borderRadius: BorderRadius.circular(12),
    ),
    child: const Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.memory, color: Colors.white70, size: 27),
        Text(
          'OtoKu',
          style: TextStyle(
            color: Colors.white70,
            fontSize: 8,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    ),
  );
}

class ObdFeature extends StatelessWidget {
  final IconData icon;
  final String label;
  const ObdFeature({super.key, required this.icon, required this.label});
  @override
  Widget build(BuildContext context) => Column(
    children: [
      Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white30),
        ),
        child: Icon(icon, color: Colors.white70, size: 16),
      ),
      const SizedBox(height: 5),
      Text(
        label,
        textAlign: TextAlign.center,
        maxLines: 2,
        style: const TextStyle(
          color: Colors.white70,
          fontSize: 8,
          height: 1.15,
        ),
      ),
    ],
  );
}

class ConnectedObdCard extends StatelessWidget {
  final OtoKuState state;
  const ConnectedObdCard({super.key, required this.state});
  @override
  Widget build(BuildContext context) => CardBox(
    color: AppColors.greenTint,
    onTap: () => showObdSheet(context, state),
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

class LockedMetrics extends StatelessWidget {
  const LockedMetrics({super.key});
  @override
  Widget build(BuildContext context) => GridView.count(
    shrinkWrap: true,
    physics: const NeverScrollableScrollPhysics(),
    crossAxisCount: 3,
    childAspectRatio: 1.15,
    mainAxisSpacing: 8,
    crossAxisSpacing: 8,
    children:
        [
              'RPM',
              'Kecepatan',
              'Suhu Mesin',
              'Tegangan Aki',
              'Level BBM',
              'Konsumsi BBM',
            ]
            .map(
              (x) => CardBox(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.lock_outline,
                      size: 18,
                      color: AppColors.muted,
                    ),
                    const Spacer(),
                    Text(
                      '—',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      x,
                      style: const TextStyle(
                        fontSize: 10,
                        color: AppColors.muted,
                      ),
                    ),
                  ],
                ),
              ),
            )
            .toList(),
  );
}

class MetricGrid extends StatelessWidget {
  final VoidCallback onTap;
  const MetricGrid({super.key, required this.onTap});
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
      children:
          [
                ['1.250', 'RPM', 'rpm'],
                ['0', 'Kecepatan', 'km/h'],
                ['87', 'Suhu Mesin', '°C'],
                ['13,8', 'Tegangan Aki', 'V'],
                ['64', 'Level BBM', '%'],
                ['42,5', 'Konsumsi BBM', 'km/L'],
              ]
              .map(
                (x) => CardBox(
                  onTap: onTap,
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        [
                          Icons.speed_outlined,
                          Icons.navigation_outlined,
                          Icons.thermostat_outlined,
                          Icons.battery_charging_full_outlined,
                          Icons.local_gas_station_outlined,
                          Icons.local_fire_department_outlined,
                        ][[
                          'RPM',
                          'Kecepatan',
                          'Suhu Mesin',
                          'Tegangan Aki',
                          'Level BBM',
                          'Konsumsi BBM',
                        ].indexOf(x[1])],
                        size: 16,
                        color: AppColors.muted,
                      ),
                      const SizedBox(height: 5),
                      Text(
                        x[0],
                        style: const TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        x[1],
                        style: const TextStyle(
                          fontSize: 10,
                          color: AppColors.muted,
                        ),
                      ),
                      Text(
                        x[2],
                        style: const TextStyle(
                          fontSize: 10,
                          color: AppColors.muted,
                        ),
                      ),
                    ],
                  ),
                ),
              )
              .toList(),
    ),
  );
}

class HealthSummary extends StatelessWidget {
  final OtoKuState state;
  const HealthSummary({super.key, required this.state});
  @override
  Widget build(BuildContext context) => CardBox(
    padding: const EdgeInsets.all(12),
    child: Column(
      children: [
        Row(
          children: [
            Expanded(child: HealthItem('Mesin', 'Normal', true)),
            Expanded(child: HealthItem('Sistem Pengisian', 'Normal', true)),
          ],
        ),
        Row(
          children: [
            Expanded(child: HealthItem('Emisi', 'Normal', true)),
            Expanded(child: HealthItem('Ada 1 kode masalah', 'P0301', false)),
          ],
        ),
      ],
    ),
  );
}

class MaintenanceCard extends StatelessWidget {
  final VoidCallback onTap;
  const MaintenanceCard({super.key, required this.onTap});
  @override
  Widget build(BuildContext context) => CardBox(
    color: AppColors.redTint,
    onTap: onTap,
    child: Row(
      children: [
        const CircleAvatar(
          backgroundColor: Colors.white,
          child: Icon(Icons.oil_barrel_outlined, color: AppColors.red),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Ganti Oli Mesin',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
              const Text(
                'Dalam 1.550 km',
                style: TextStyle(color: AppColors.muted, fontSize: 12),
              ),
              const SizedBox(height: 2),
              const Text(
                'Perkiraan: Okt 2025',
                style: TextStyle(color: AppColors.muted, fontSize: 10),
              ),
            ],
          ),
        ),
        const Icon(Icons.chevron_right, color: AppColors.red),
      ],
    ),
  );
}

class Metric extends StatelessWidget {
  final String icon, value, label;
  const Metric(this.icon, this.value, this.label, {super.key});
  @override
  Widget build(BuildContext context) => Column(
    children: [
      Text(
        icon,
        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
      ),
      const SizedBox(height: 3),
      Text(
        value,
        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
      ),
      Text(label, style: const TextStyle(color: AppColors.muted, fontSize: 10)),
    ],
  );
}

class StatusChip extends StatelessWidget {
  final String text;
  final Color color;
  const StatusChip(this.text, this.color, {super.key});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
      color: color.withValues(alpha: .14),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(
      text,
      style: TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: 12),
    ),
  );
}

void push(BuildContext context, Widget page) =>
    Navigator.push(context, MaterialPageRoute(builder: (_) => page));
void showObdSheet(BuildContext context, OtoKuState state) =>
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              state.obdConnected
                  ? 'OBD OtoKu Terhubung'
                  : 'Buka data kendaraan real-time',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 8),
            Text(
              state.obdConnected
                  ? 'Nikmati pemantauan kondisi kendaraan dan kode masalah secara berkala.'
                  : 'Dapatkan RPM, suhu mesin, konsumsi BBM, dan deteksi masalah lebih awal.',
              style: const TextStyle(color: AppColors.muted, height: 1.4),
            ),
            const SizedBox(height: 18),
            FilledButton(
              onPressed: () {
                state.obdConnected ? state.disconnectObd() : state.connectObd();
                Navigator.pop(context);
              },
              child: Text(
                state.obdConnected ? 'Putuskan OBD' : 'Hubungkan OBD',
              ),
            ),
          ],
        ),
      ),
    );
void showNotificationSheet(BuildContext context) {
  showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (_) => const Padding(
      padding: EdgeInsets.fromLTRB(20, 0, 20, 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Notifikasi',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
          ),
          SizedBox(height: 18),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.build_circle_outlined, color: AppColors.red),
            title: Text('Perawatan mendatang'),
            subtitle: Text('Ganti oli mesin dalam 1.550 km'),
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.shopping_bag_outlined),
            title: Text('Pesanan diproses'),
            subtitle: Text('Kampas Rem Depan sedang dikemas'),
          ),
        ],
      ),
    ),
  );
}

void showVehicleActions(BuildContext context) => showModalBottomSheet<void>(
  context: context,
  showDragHandle: true,
  builder: (_) => const SafeArea(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ListTile(
          leading: Icon(Icons.edit_outlined),
          title: Text('Ubah Data Kendaraan'),
        ),
        ListTile(
          leading: Icon(Icons.delete_outline, color: AppColors.red),
          title: Text(
            'Hapus Kendaraan',
            style: TextStyle(color: AppColors.red),
          ),
        ),
      ],
    ),
  ),
);

class VehicleDetailScreen extends StatelessWidget {
  final OtoKuState state;
  const VehicleDetailScreen({super.key, required this.state});
  @override
  Widget build(BuildContext context) => Page(
    title: 'Detail Kendaraan',
    actions: [
      IconButton(
        onPressed: () => showVehicleActions(context),
        icon: const Icon(Icons.more_horiz),
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
                  child: const VehiclePhoto(height: 190, detail: true),
                ),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    state.vehicle.name,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    state.vehicle.plate,
                    style: const TextStyle(color: AppColors.muted),
                  ),
                ),
                const SizedBox(height: 18),
                ...[
                  ['Merek', 'Honda'],
                  ['Model', 'Beat'],
                  ['Tahun', '2021'],
                  ['Tipe', 'CBS'],
                  ['No. Rangka', 'MH1JM3110MK123456'],
                  ['No. Mesin', 'JM31E1123456'],
                ].map((x) => InfoRow(x[0], x[1])),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F1EF),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    state.vehicle.plate,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ],
            ),
          ),
          SectionTitle('Aktivitas kendaraan'),
          ...[
            [
              'Riwayat & Tracking',
              Icons.timeline,
              () => push(context, HistoryScreen(state: state)),
            ],
            [
              'Jadwal Perawatan',
              Icons.event_note,
              () => push(context, MaintenanceScreen(state: state)),
            ],
            [
              'Data OBD',
              Icons.sensors,
              () => state.obdConnected
                  ? push(context, ObdScreen(state: state))
                  : showObdSheet(context, state),
            ],
          ].map(
            (x) => CardBox(
              onTap: x[2] as VoidCallback,
              child: Row(
                children: [
                  Icon(x[1] as IconData, color: AppColors.red),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      x[0] as String,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                  const Icon(Icons.chevron_right),
                ],
              ),
            ),
          ),
          CardBox(
            child: const ListTile(
              leading: Icon(Icons.edit_outlined),
              title: Text('Ubah Data Kendaraan'),
              trailing: Icon(Icons.chevron_right),
            ),
          ),
          const SizedBox(height: 8),
          CardBox(
            color: AppColors.redTint,
            child: const ListTile(
              leading: Icon(Icons.delete_outline, color: AppColors.red),
              title: Text(
                'Hapus Kendaraan',
                style: TextStyle(
                  color: AppColors.red,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

class InfoRow extends StatelessWidget {
  final String a, b;
  const InfoRow(this.a, this.b, {super.key});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(
      children: [
        Expanded(
          child: Text(
            a,
            style: const TextStyle(color: AppColors.muted, fontSize: 13),
          ),
        ),
        Text(
          b,
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
        ),
      ],
    ),
  );
}

class VehiclePhoto extends StatelessWidget {
  final double height;
  final bool detail;
  const VehiclePhoto({super.key, required this.height, this.detail = false});
  @override
  Widget build(BuildContext context) => SizedBox(
    height: height,
    width: double.infinity,
    child: Stack(
      clipBehavior: Clip.hardEdge,
      children: [
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFFF1F1EF),
                  Colors.white.withValues(alpha: .35),
                ],
              ),
            ),
          ),
        ),
        Align(
          alignment: detail ? Alignment.center : Alignment.centerRight,
          child: Image.asset(
            'assets/honda_beat.png',
            height: detail ? height : height * 1.4,
            width: detail ? double.infinity : height * 1.4,
            fit: BoxFit.contain,
            alignment: detail ? Alignment.center : Alignment.centerRight,
            semanticLabel: 'Honda Beat merah dan hitam',
          ),
        ),
      ],
    ),
  );
}

class VehicleIllustration extends StatelessWidget {
  final double height;
  const VehicleIllustration({super.key, this.height = 120});
  @override
  Widget build(BuildContext context) => SizedBox(
    height: height,
    width: double.infinity,
    child: CustomPaint(painter: VehiclePainter()),
  );
}

class VehiclePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.height / 130;
    final x = (size.width - 280 * scale) / 2;
    Offset pt(double dx, double dy) => Offset(x + dx * scale, dy * scale);
    final shadow = Paint()..color = const Color(0x1A171717);
    canvas.drawOval(
      Rect.fromCenter(
        center: pt(147, 116),
        width: 240 * scale,
        height: 12 * scale,
      ),
      shadow,
    );

    final wheel = Paint()..color = const Color(0xFF242528);
    final rim = Paint()..color = const Color(0xFFD5D5D0);
    final inner = Paint()..color = const Color(0xFF777A7A);
    for (final center in [pt(62, 99), pt(224, 99)]) {
      canvas.drawCircle(center, 25 * scale, wheel);
      canvas.drawCircle(center, 17 * scale, rim);
      canvas.drawCircle(center, 5 * scale, inner);
      final spokes = Paint()
        ..color = const Color(0xFF9B9D99)
        ..strokeWidth = 1.2 * scale;
      for (var i = 0; i < 8; i++) {
        final angle = i * 3.14159 / 4;
        canvas.drawLine(
          center +
              Offset(math.cos(angle) * 6 * scale, math.sin(angle) * 6 * scale),
          center +
              Offset(
                math.cos(angle) * 15 * scale,
                math.sin(angle) * 15 * scale,
              ),
          spokes,
        );
      }
    }

    final black = Paint()..color = const Color(0xFF28292C);
    final bodyPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFF0403B), Color(0xFFC91D25), Color(0xFF8E171E)],
      ).createShader(Rect.fromLTWH(x, 15 * scale, 260 * scale, 95 * scale));
    final body = Path()
      ..moveTo(x + 37 * scale, 86 * scale)
      ..quadraticBezierTo(
        x + 40 * scale,
        68 * scale,
        x + 58 * scale,
        61 * scale,
      )
      ..lineTo(x + 91 * scale, 54 * scale)
      ..lineTo(x + 111 * scale, 30 * scale)
      ..quadraticBezierTo(
        x + 127 * scale,
        22 * scale,
        x + 152 * scale,
        26 * scale,
      )
      ..lineTo(x + 179 * scale, 43 * scale)
      ..lineTo(x + 201 * scale, 49 * scale)
      ..quadraticBezierTo(
        x + 222 * scale,
        55 * scale,
        x + 231 * scale,
        75 * scale,
      )
      ..lineTo(x + 228 * scale, 91 * scale)
      ..lineTo(x + 205 * scale, 91 * scale)
      ..quadraticBezierTo(
        x + 194 * scale,
        67 * scale,
        x + 175 * scale,
        68 * scale,
      )
      ..quadraticBezierTo(
        x + 153 * scale,
        68 * scale,
        x + 144 * scale,
        94 * scale,
      )
      ..lineTo(x + 96 * scale, 94 * scale)
      ..quadraticBezierTo(
        x + 87 * scale,
        73 * scale,
        x + 66 * scale,
        75 * scale,
      )
      ..quadraticBezierTo(
        x + 47 * scale,
        76 * scale,
        x + 43 * scale,
        94 * scale,
      )
      ..lineTo(x + 35 * scale, 93 * scale)
      ..close();
    canvas.drawPath(body, bodyPaint);
    canvas.drawPath(
      body,
      Paint()
        ..color = const Color(0x55750E16)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2 * scale,
    );

    final seat = Path()
      ..moveTo(x + 106 * scale, 32 * scale)
      ..quadraticBezierTo(
        x + 125 * scale,
        18 * scale,
        x + 153 * scale,
        25 * scale,
      )
      ..lineTo(x + 174 * scale, 39 * scale)
      ..lineTo(x + 148 * scale, 42 * scale)
      ..lineTo(x + 113 * scale, 41 * scale)
      ..close();
    canvas.drawPath(seat, black);
    canvas.drawPath(
      seat,
      Paint()
        ..color = const Color(0xFF48494B)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1 * scale,
    );

    final metal = Paint()
      ..color = const Color(0xFF525457)
      ..strokeWidth = 4 * scale
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(pt(111, 58), pt(78, 88), metal);
    canvas.drawLine(pt(177, 63), pt(207, 85), metal);
    canvas.drawLine(pt(109, 89), pt(164, 89), metal);
    canvas.drawLine(pt(142, 89), pt(124, 62), metal);
    canvas.drawLine(pt(173, 63), pt(182, 91), metal);
    canvas.drawLine(
      pt(203, 51),
      pt(224, 49),
      Paint()
        ..color = const Color(0xFF252629)
        ..strokeWidth = 4 * scale
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawLine(
      pt(220, 48),
      pt(236, 65),
      Paint()
        ..color = const Color(0xFF252629)
        ..strokeWidth = 3 * scale
        ..strokeCap = StrokeCap.round,
    );

    final glint = Paint()
      ..color = const Color(0xFFFFB7A9)
      ..strokeWidth = 2 * scale
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(pt(155, 48), pt(179, 50), glint);
    canvas.drawLine(
      pt(220, 67),
      pt(230, 71),
      Paint()
        ..color = const Color(0xFFF8E9D9)
        ..strokeWidth = 3 * scale
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawLine(
      pt(44, 65),
      pt(32, 59),
      Paint()
        ..color = const Color(0xFF292A2C)
        ..strokeWidth = 4 * scale
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawLine(
      pt(34, 59),
      pt(29, 48),
      Paint()
        ..color = const Color(0xFF292A2C)
        ..strokeWidth = 3 * scale
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawLine(
      pt(39, 95),
      pt(54, 95),
      Paint()
        ..color = const Color(0xFF242528)
        ..strokeWidth = 3 * scale
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class CarMark extends StatelessWidget {
  final double size;
  const CarMark({super.key, required this.size});
  @override
  Widget build(BuildContext context) => SizedBox(
    width: size,
    height: size,
    child: CustomPaint(painter: CarMarkPainter()),
  );
}

class CarMarkPainter extends CustomPainter {
  @override
  void paint(Canvas c, Size s) {
    final p = Paint()
      ..color = AppColors.red
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round;
    final path = Path()
      ..moveTo(10, s.height * .62)
      ..quadraticBezierTo(
        s.width * .3,
        s.height * .2,
        s.width * .7,
        s.height * .4,
      )
      ..quadraticBezierTo(
        s.width * .9,
        s.height * .45,
        s.width - 8,
        s.height * .7,
      );
    c.drawPath(path, p);
    c.drawLine(
      Offset(12, s.height * .72),
      Offset(s.width - 12, s.height * .72),
      p,
    );
    c.drawCircle(Offset(s.width * .25, s.height * .75), 7, p);
    c.drawCircle(Offset(s.width * .75, s.height * .75), 7, p);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class MaintenanceScreen extends StatelessWidget {
  final OtoKuState state;
  const MaintenanceScreen({super.key, required this.state});
  @override
  Widget build(BuildContext context) => Page(
    title: 'Jadwal Perawatan',
    child: ScrollPage(
      child: Column(
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Pill('Rekomendasi', active: true),
              Pill('Semua'),
              Pill('Selesai'),
            ],
          ),
          const SizedBox(height: 14),
          ...[
            [
              'Ganti Oli Mesin',
              'Dalam 1.550 km',
              '12.450 / 14.000 km',
              Icons.oil_barrel_outlined,
            ],
            [
              'Cek Kampas Rem',
              'Dalam 3.000 km',
              '12.450 / 15.000 km',
              Icons.disc_full,
            ],
            [
              'Cek Filter Udara',
              'Dalam 3.000 km',
              '12.450 / 15.000 km',
              Icons.filter_alt_outlined,
            ],
            [
              'Cek Busi',
              'Dalam 5.000 km',
              '12.450 / 17.500 km',
              Icons.electrical_services,
            ],
            [
              'Ganti Oli Gear (CVT)',
              'Dalam 5.000 km',
              '12.450 / 17.500 km',
              Icons.settings_outlined,
            ],
          ].map(
            (x) => CardBox(
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: AppColors.bg,
                    child: Icon(x[3] as IconData, color: AppColors.red),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          x[0] as String,
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                        Text(
                          x[1] as String,
                          style: const TextStyle(
                            color: AppColors.muted,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 8),
                        LinearProgressIndicator(
                          value: .72,
                          minHeight: 6,
                          borderRadius: BorderRadius.circular(8),
                          color: (x[0] as String) == 'Ganti Oli Mesin'
                              ? AppColors.red
                              : const Color(0xFF999A96),
                          backgroundColor: AppColors.border,
                        ),
                        const SizedBox(height: 5),
                        Text(
                          x[2] as String,
                          style: const TextStyle(
                            color: AppColors.muted,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right),
                ],
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

class HistoryScreen extends StatefulWidget {
  final OtoKuState state;
  const HistoryScreen({super.key, required this.state});
  @override
  State<HistoryScreen> createState() => _HistoryState();
}

class _HistoryState extends State<HistoryScreen> {
  int tab = 0;
  @override
  Widget build(BuildContext context) => Page(
    title: 'Riwayat & Tracking',
    child: ScrollPage(
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: ['Timeline', 'Grafik', 'Biaya']
                .asMap()
                .entries
                .map(
                  (e) => GestureDetector(
                    onTap: () => setState(() => tab = e.key),
                    child: Pill(e.value, active: tab == e.key),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 18),
          if (tab == 0)
            const ServiceTimeline()
          else
            ChartPanel(
              title: tab == 1 ? 'Tren jarak tempuh' : 'Pengeluaran perawatan',
              cost: tab == 2,
            ),
        ],
      ),
    ),
  );
}

class ServiceTimeline extends StatelessWidget {
  const ServiceTimeline({super.key});
  @override
  Widget build(BuildContext context) => const Column(
    children: [
      TimelineGroup(
        date: 'Hari ini',
        mileage: '12.450 km',
        today: true,
        items: [
          TimelineItem(
            icon: Icons.local_gas_station_outlined,
            title: 'Isi Pertalite',
            detail: '8,2 L (Rp 6.100/L) · 12.450 km',
            price: 'Rp 50.000',
          ),
          TimelineItem(
            icon: Icons.build_outlined,
            title: 'Servis Rutin',
            detail: 'Ganti oli mesin · Cek filter udara · Cek CVT · 12.100 km',
            price: 'Rp 80.000',
          ),
        ],
      ),
      TimelineGroup(
        date: '10 Jul 2025',
        mileage: '11.800 km',
        items: [
          TimelineItem(
            icon: Icons.local_gas_station_outlined,
            title: 'Isi Pertalite',
            detail: '8,1 L (Rp 6.150/L) · 11.800 km',
            price: 'Rp 50.000',
          ),
        ],
      ),
      TimelineGroup(
        date: '15 Jun 2025',
        mileage: '11.200 km',
        items: [
          TimelineItem(
            icon: Icons.tire_repair_outlined,
            title: 'Ganti Kampas Rem',
            detail: '11.200 km',
            price: 'Rp 120.000',
          ),
        ],
      ),
      TimelineGroup(
        date: '20 Apr 2025',
        mileage: '10.500 km',
        items: [
          TimelineItem(
            icon: Icons.local_gas_station_outlined,
            title: 'Isi Pertalite',
            detail: '8,3 L (Rp 6.000/L) · 10.500 km',
            price: 'Rp 50.000',
          ),
        ],
      ),
      TimelineGroup(
        date: '12 Mar 2025',
        mileage: '9.800 km',
        items: [
          TimelineItem(
            icon: Icons.build_outlined,
            title: 'Servis Rutin',
            detail: 'Ganti oli mesin · Cek filter udara',
            price: 'Rp 80.000',
          ),
        ],
      ),
    ],
  );
}

class TimelineGroup extends StatelessWidget {
  final String date, mileage;
  final bool today;
  final List<TimelineItem> items;
  const TimelineGroup({
    super.key,
    required this.date,
    required this.mileage,
    required this.items,
    this.today = false,
  });
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 18),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 18,
          child: Column(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: today ? AppColors.red : const Color(0xFF9B9B96),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: today ? AppColors.redTint : const Color(0xFFE8E8E8),
                    width: 3,
                  ),
                ),
              ),
              Container(
                width: 1.5,
                height: items.length > 1 ? 142 : 92,
                color: const Color(0xFFE1E1DD),
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                date,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: today ? AppColors.red : AppColors.ink,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                mileage,
                style: const TextStyle(fontSize: 11, color: AppColors.muted),
              ),
              const SizedBox(height: 10),
              ...items.map(
                (item) => Padding(
                  padding: const EdgeInsets.only(bottom: 9),
                  child: item,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class TimelineItem extends StatelessWidget {
  final IconData icon;
  final String title, detail, price;
  const TimelineItem({
    super.key,
    required this.icon,
    required this.title,
    required this.detail,
    required this.price,
  });
  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: const Color(0xFFF0F0EE),
          borderRadius: BorderRadius.circular(9),
        ),
        child: Icon(icon, color: const Color(0xFF5F605C), size: 18),
      ),
      const SizedBox(width: 9),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 3),
            Text(
              detail,
              style: const TextStyle(
                color: AppColors.muted,
                fontSize: 10,
                height: 1.35,
              ),
            ),
          ],
        ),
      ),
      const SizedBox(width: 5),
      Text(
        price,
        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700),
      ),
    ],
  );
}

class ChartPanel extends StatelessWidget {
  final String title;
  final bool cost;
  const ChartPanel({super.key, required this.title, required this.cost});
  @override
  Widget build(BuildContext c) => CardBox(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
        const SizedBox(height: 20),
        SizedBox(
          height: 180,
          child: CustomPaint(
            painter: ChartPainter(cost: cost),
            child: const SizedBox.expand(),
          ),
        ),
        const SizedBox(height: 10),
        const Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            Text('Jun'),
            Text('Jul'),
            Text('Agu'),
            Text('Sep'),
            Text('Okt'),
          ],
        ),
      ],
    ),
  );
}

class ChartPainter extends CustomPainter {
  final bool cost;
  ChartPainter({required this.cost});
  @override
  void paint(Canvas c, Size s) {
    final line = Paint()
      ..color = AppColors.red
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final grid = Paint()
      ..color = AppColors.border
      ..strokeWidth = 1;
    for (var i = 1; i < 5; i++) {
      c.drawLine(
        Offset(0, s.height * i / 5),
        Offset(s.width, s.height * i / 5),
        grid,
      );
    }
    final points = [.72, .55, .62, .3, .42];
    final path = Path()..moveTo(10, s.height * points[0]);
    for (var i = 1; i < points.length; i++) {
      final x = 10 + (s.width - 20) * i / (points.length - 1);
      path.lineTo(x, s.height * points[i]);
    }
    c.drawPath(path, line);
    for (var i = 0; i < points.length; i++) {
      final x = 10 + (s.width - 20) * i / (points.length - 1);
      c.drawCircle(
        Offset(x, s.height * points[i]),
        5,
        Paint()..color = AppColors.red,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class ObdScreen extends StatelessWidget {
  final OtoKuState state;
  const ObdScreen({super.key, required this.state});
  @override
  Widget build(BuildContext c) => Page(
    title: 'Data OBD',
    bottomBar: SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        child: FilledButton(
          onPressed: () => showRecommendation(c),
          style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
          child: const Text('Lihat Solusi & Rekomendasi'),
        ),
      ),
    ),
    child: ScrollPage(
      child: Column(
        children: [
          CardBox(
            color: AppColors.greenTint,
            child: const Row(
              children: [
                Icon(Icons.circle, color: AppColors.green, size: 12),
                SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'OBD Terhubung',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                    Text(
                      'Terakhir update: 2 menit yang lalu',
                      style: TextStyle(color: AppColors.muted, fontSize: 12),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [Pill('Simulasi', active: true), Pill('Diagnostik')],
          ),
          const SizedBox(height: 16),
          MetricGrid(onTap: () {}),
          const SectionTitle('Kondisi Kendaraan', action: 'Lihat detail'),
          Row(
            children: [
              Expanded(child: HealthItem('Mesin', 'Normal', true)),
              Expanded(child: HealthItem('Sistem Pengisian', 'Normal', true)),
            ],
          ),
          Row(
            children: [
              Expanded(child: HealthItem('Emisi', 'Normal', true)),
              Expanded(child: HealthItem('1 Kode Masalah', 'P0301', false)),
            ],
          ),
          const SectionTitle('Kode Masalah (DTC)'),
          CardBox(
            onTap: () => showRecommendation(c),
            child: const ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.error_outline, color: AppColors.red),
              title: Text(
                'P0301',
                style: TextStyle(fontWeight: FontWeight.w900),
              ),
              subtitle: Text('Cylinder 1 Misfire Detected'),
              trailing: StatusChip('Sedang', AppColors.amber),
            ),
          ),
        ],
      ),
    ),
  );
}

class HealthItem extends StatelessWidget {
  final String a, b;
  final bool ok;
  const HealthItem(this.a, this.b, this.ok, {super.key});
  @override
  Widget build(BuildContext c) => ListTile(
    contentPadding: EdgeInsets.zero,
    leading: CircleAvatar(
      backgroundColor: ok ? const Color(0xFFDDF5E3) : const Color(0xFFFFE6E6),
      child: Icon(
        ok ? Icons.check : Icons.warning,
        color: ok ? AppColors.green : AppColors.red,
        size: 18,
      ),
    ),
    title: Text(a, style: const TextStyle(fontSize: 12)),
    subtitle: Text(
      b,
      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
    ),
  );
}

void showRecommendation(BuildContext c) => showModalBottomSheet(
  context: c,
  showDragHandle: true,
  builder: (_) => Padding(
    padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Rekomendasi pemeriksaan',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 10),
        const Text(
          'Kode P0301 terdeteksi. Ini merupakan indikasi dan bukan diagnosis pasti. Periksa kendaraan lebih lanjut.',
          style: TextStyle(color: AppColors.muted, height: 1.45),
        ),
        const SizedBox(height: 15),
        const ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Icon(Icons.tire_repair_outlined),
          title: Text('Periksa sistem pembakaran'),
          subtitle: Text('Busi, kabel, dan injektor'),
        ),
        const ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Icon(Icons.shopping_bag_outlined),
          title: Text('Lihat sparepart yang sesuai'),
        ),
        const ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Icon(Icons.build_outlined),
          title: Text('Cari bengkel terdekat'),
        ),
      ],
    ),
  ),
);

class CatalogScreen extends StatefulWidget {
  final OtoKuState state;
  const CatalogScreen({super.key, required this.state});
  @override
  State<CatalogScreen> createState() => _CatalogState();
}

class _CatalogState extends State<CatalogScreen> {
  String query = '', cat = 'Semua';
  @override
  Widget build(BuildContext c) {
    final cats = [
      'Semua',
      'Sparepart',
      'Oli & Cairan',
      'Aksesori',
      'Perangkat OBD',
      'Rem',
      'Filter',
      'Aki',
    ];
    final list = widget.state.products
        .where(
          (p) =>
              (cat == 'Semua' ||
                  p.category == cat ||
                  (cat == 'Sparepart' &&
                      !['Aksesori', 'Perangkat OBD'].contains(p.category))) &&
              (query.isEmpty ||
                  p.name.toLowerCase().contains(query.toLowerCase())),
        )
        .toList();
    return SafeArea(
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 0),
              child: Row(
                children: [
                  const Text(
                    'Shop',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
                  ),
                  const Spacer(),
                  if (widget.state.cart.isNotEmpty)
                    Badge(
                      label: Text('${widget.state.cart.length}'),
                      child: IconButton(
                        onPressed: () =>
                            push(c, CheckoutScreen(state: widget.state)),
                        icon: const Icon(Icons.shopping_bag_outlined),
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
                TextField(
                  onChanged: (x) => setState(() => query = x),
                  decoration: InputDecoration(
                    hintText: 'Cari produk...',
                    prefixIcon: const Icon(Icons.search),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderSide: BorderSide.none,
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: cats
                        .map(
                          (x) => Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: GestureDetector(
                              onTap: () => setState(() => cat = x),
                              child: Pill(x, active: cat == x),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ),
                const SizedBox(height: 18),
                const Text(
                  'Kategori',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                ),
                const SizedBox(height: 10),
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 4,
                  childAspectRatio: .82,
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                  children:
                      [
                            ['Oli & Cairan', Icons.oil_barrel_outlined],
                            ['Rem', Icons.disc_full],
                            ['Filter', Icons.filter_alt_outlined],
                            ['Aki', Icons.battery_full],
                            ['Lampu', Icons.lightbulb_outline],
                            ['Body Part', Icons.two_wheeler],
                            ['CVT', Icons.settings_outlined],
                            ['Lainnya', Icons.more_horiz],
                          ]
                          .map(
                            (x) => InkWell(
                              onTap: () => setState(
                                () => cat =
                                    [
                                      'Body Part',
                                      'CVT',
                                      'Lainnya',
                                    ].contains(x[0])
                                    ? 'Semua'
                                    : x[0] as String,
                              ),
                              borderRadius: BorderRadius.circular(12),
                              child: Column(
                                children: [
                                  Container(
                                    width: 52,
                                    height: 52,
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      border: Border.all(
                                        color: AppColors.border,
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Icon(
                                      x[1] as IconData,
                                      color: AppColors.ink,
                                    ),
                                  ),
                                  const SizedBox(height: 5),
                                  Text(
                                    x[0] as String,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      fontSize: 9,
                                      color: AppColors.muted,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                          .toList(),
                ),
                SectionTitle(
                  'Produk untuk kendaraan aktif',
                  action: 'Lihat semua',
                ),
                const Text(
                  'Kecocokan hanya ditandai jika sudah dikonfirmasi.',
                  style: TextStyle(color: AppColors.muted, fontSize: 13),
                ),
                const SizedBox(height: 10),
                ...list.map(
                  (p) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: ProductCard(
                      p: p,
                      onTap: () => push(
                        c,
                        ProductDetailScreen(state: widget.state, product: p),
                      ),
                    ),
                  ),
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

class ProductCard extends StatelessWidget {
  final Product p;
  final VoidCallback onTap;
  const ProductCard({super.key, required this.p, required this.onTap});
  @override
  Widget build(BuildContext c) => CardBox(
    onTap: onTap,
    child: Row(
      children: [
        ProductArt(icon: p.icon),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(p.name, style: const TextStyle(fontWeight: FontWeight.w800)),
              Text(
                switch (p.fitment) {
                  ProductFitment.confirmed => 'Cocok untuk Honda Beat 2021',
                  ProductFitment.possibleUnverified =>
                    'Kecocokan belum diverifikasi',
                  ProductFitment.incompatible =>
                    'Tidak cocok untuk kendaraan ini',
                  ProductFitment.unknown => 'Kompatibilitas belum diketahui',
                },
                style: TextStyle(
                  color: switch (p.fitment) {
                    ProductFitment.confirmed => AppColors.green,
                    ProductFitment.incompatible => AppColors.red,
                    _ => AppColors.muted,
                  },
                  fontSize: 11,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                p.price,
                style: const TextStyle(
                  color: AppColors.red,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
        const Icon(Icons.chevron_right),
      ],
    ),
  );
}

class ProductArt extends StatelessWidget {
  final String icon;
  const ProductArt({super.key, required this.icon});
  @override
  Widget build(BuildContext c) => Container(
    width: 68,
    height: 68,
    decoration: BoxDecoration(
      color: const Color(0xFFF2F1ED),
      borderRadius: BorderRadius.circular(14),
    ),
    child: CustomPaint(painter: PartPainter(icon)),
  );
}

class PartPainter extends CustomPainter {
  final String type;
  PartPainter(this.type);
  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.shortestSide / 68;
    final center = Offset(size.width / 2, size.height / 2);
    final shadow = Paint()..color = const Color(0x20000000);
    final dark = Paint()..color = const Color(0xFF35373A);
    if (type == 'brake') {
      final pad = Path()
        ..moveTo(16 * scale, 20 * scale)
        ..quadraticBezierTo(20 * scale, 15 * scale, 29 * scale, 16 * scale)
        ..lineTo(52 * scale, 23 * scale)
        ..lineTo(48 * scale, 47 * scale)
        ..quadraticBezierTo(35 * scale, 53 * scale, 19 * scale, 46 * scale)
        ..close();
      canvas.drawPath(pad.shift(Offset(0, 3 * scale)), shadow);
      canvas.drawPath(
        pad,
        Paint()
          ..shader =
              const LinearGradient(
                colors: [Color(0xFF5C6062), Color(0xFF292B2D)],
              ).createShader(
                Rect.fromLTWH(12 * scale, 14 * scale, 44 * scale, 40 * scale),
              ),
      );
      canvas.drawPath(
        pad,
        Paint()
          ..color = const Color(0xFF8C8E8C)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1 * scale,
      );
      final groove = Paint()
        ..color = const Color(0xFFB1B1AC)
        ..strokeWidth = 1.4 * scale
        ..strokeCap = StrokeCap.round;
      for (var i = 0; i < 4; i++) {
        canvas.drawLine(
          Offset((23 + i * 6) * scale, 25 * scale),
          Offset((21 + i * 6) * scale, 39 * scale),
          groove,
        );
      }
      canvas.drawCircle(
        Offset(44 * scale, 21 * scale),
        2 * scale,
        Paint()..color = const Color(0xFFE4E1D7),
      );
    } else if (type == 'oil') {
      final bottle = Path()
        ..moveTo(26 * scale, 16 * scale)
        ..lineTo(40 * scale, 16 * scale)
        ..lineTo(40 * scale, 23 * scale)
        ..lineTo(47 * scale, 28 * scale)
        ..lineTo(50 * scale, 51 * scale)
        ..quadraticBezierTo(49 * scale, 55 * scale, 45 * scale, 55 * scale)
        ..lineTo(20 * scale, 55 * scale)
        ..quadraticBezierTo(17 * scale, 54 * scale, 18 * scale, 50 * scale)
        ..lineTo(21 * scale, 29 * scale)
        ..lineTo(27 * scale, 24 * scale)
        ..close();
      canvas.drawPath(bottle.shift(Offset(0, 3 * scale)), shadow);
      canvas.drawPath(
        bottle,
        Paint()
          ..shader =
              const LinearGradient(
                colors: [Color(0xFFE34A25), Color(0xFFA91C18)],
              ).createShader(
                Rect.fromLTWH(18 * scale, 15 * scale, 33 * scale, 42 * scale),
              ),
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(23 * scale, 34 * scale, 23 * scale, 12 * scale),
          Radius.circular(2 * scale),
        ),
        Paint()..color = const Color(0xFFF7E8D1),
      );
      final text = TextPainter(
        text: TextSpan(
          text: 'AHM',
          style: TextStyle(
            color: const Color(0xFF282828),
            fontSize: 5 * scale,
            fontWeight: FontWeight.w900,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      text.paint(canvas, Offset(29 * scale, 37 * scale));
      canvas.drawRect(
        Rect.fromLTWH(28 * scale, 11 * scale, 10 * scale, 6 * scale),
        Paint()..color = const Color(0xFF242628),
      );
    } else if (type == 'filter') {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(17 * scale, 18 * scale, 34 * scale, 34 * scale),
          Radius.circular(7 * scale),
        ),
        Paint()..color = const Color(0xFFE4E0D5),
      );
      final pleat = Paint()
        ..color = const Color(0xFF85847E)
        ..strokeWidth = 2 * scale;
      for (var i = 0; i < 6; i++) {
        canvas.drawLine(
          Offset((21 + i * 5) * scale, 21 * scale),
          Offset((21 + i * 5) * scale, 49 * scale),
          pleat,
        );
      }
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(17 * scale, 17 * scale, 34 * scale, 5 * scale),
          Radius.circular(3 * scale),
        ),
        dark,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(17 * scale, 48 * scale, 34 * scale, 5 * scale),
          Radius.circular(3 * scale),
        ),
        dark,
      );
    } else if (type == 'battery') {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(17 * scale, 21 * scale, 34 * scale, 32 * scale),
          Radius.circular(5 * scale),
        ),
        dark,
      );
      canvas.drawRect(
        Rect.fromLTWH(24 * scale, 16 * scale, 7 * scale, 6 * scale),
        Paint()..color = const Color(0xFFC9C8C0),
      );
      canvas.drawRect(
        Rect.fromLTWH(38 * scale, 16 * scale, 7 * scale, 6 * scale),
        Paint()..color = const Color(0xFFC9C8C0),
      );
      canvas.drawLine(
        Offset(27 * scale, 32 * scale),
        Offset(41 * scale, 32 * scale),
        Paint()
          ..color = Colors.white
          ..strokeWidth = 2 * scale,
      );
      canvas.drawLine(
        Offset(34 * scale, 25 * scale),
        Offset(34 * scale, 39 * scale),
        Paint()
          ..color = Colors.white
          ..strokeWidth = 2 * scale,
      );
    } else {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(24 * scale, 14 * scale, 20 * scale, 7 * scale),
          Radius.circular(2 * scale),
        ),
        dark,
      );
      canvas.drawOval(
        Rect.fromLTWH(20 * scale, 19 * scale, 28 * scale, 34 * scale),
        Paint()
          ..shader =
              const LinearGradient(
                colors: [Color(0xFFFFE7A3), Color(0xFFE4A947)],
              ).createShader(
                Rect.fromLTWH(20 * scale, 19 * scale, 28 * scale, 34 * scale),
              ),
      );
      canvas.drawOval(
        Rect.fromLTWH(27 * scale, 27 * scale, 14 * scale, 18 * scale),
        Paint()..color = const Color(0xFFFFF5D7),
      );
    }
    canvas.drawCircle(
      Offset(center.dx + 20 * scale, center.dy + 23 * scale),
      1.3 * scale,
      Paint()..color = Colors.white.withValues(alpha: .75),
    );
  }

  @override
  bool shouldRepaint(covariant PartPainter oldDelegate) =>
      oldDelegate.type != type;
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
  Widget build(BuildContext c) => Scaffold(
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
                          child: Center(
                            child: Icon(
                              product.icon == 'brake'
                                  ? Icons.disc_full
                                  : product.icon == 'oil'
                                  ? Icons.oil_barrel_outlined
                                  : Icons.build_circle_outlined,
                              size: 116,
                              color: const Color(0xFF454743),
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
                        Positioned(
                          top: 10,
                          right: 10,
                          child: CircleIconButton(
                            icon: Icons.favorite_border,
                            onTap: () {},
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: List.generate(
                      5,
                      (i) => Expanded(
                        child: Container(
                          height: 48,
                          margin: EdgeInsets.only(right: i == 4 ? 0 : 7),
                          decoration: BoxDecoration(
                            color: i == 0
                                ? const Color(0xFFECEDEA)
                                : Colors.white,
                            border: Border.all(
                              color: i == 0 ? AppColors.ink : AppColors.border,
                              width: i == 0 ? 1.5 : 1,
                            ),
                            borderRadius: BorderRadius.circular(9),
                          ),
                          child: Icon(
                            product.icon == 'brake'
                                ? Icons.disc_full
                                : Icons.build,
                            size: 22,
                            color: AppColors.muted,
                          ),
                        ),
                      ),
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
                  const Text(
                    'Honda Beat · Honda Genuine Parts',
                    style: TextStyle(color: AppColors.muted, fontSize: 12),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '★ 4.8 (120 ulasan)',
                    style: TextStyle(
                      color: AppColors.amber,
                      fontWeight: FontWeight.w700,
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
                      if (product.fitment == ProductFitment.confirmed)
                        const StatusChip('Stok tersedia', AppColors.green),
                    ],
                  ),
                  const SizedBox(height: 10),
                  if (product.fitment == ProductFitment.unknown ||
                      product.fitment == ProductFitment.possibleUnverified)
                    CardBox(
                      child: Text(
                        product.fitment == ProductFitment.possibleUnverified
                            ? 'Kecocokan produk ini belum diverifikasi untuk kendaraan Anda.'
                            : 'Informasi kompatibilitas belum tersedia.',
                        style: const TextStyle(color: AppColors.muted),
                      ),
                    ),
                  if (product.fitment == ProductFitment.incompatible)
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
                  if (product.fitment == ProductFitment.confirmed)
                    const Column(
                      children: [
                        FeatureRow(
                          icon: Icons.verified_outlined,
                          title: '100% Original',
                          subtitle: 'Garansi resmi',
                        ),
                        FeatureRow(
                          icon: Icons.build_outlined,
                          title: 'Bisa pasang di bengkel',
                          subtitle: 'Rekomendasi OtoKu',
                        ),
                        FeatureRow(
                          icon: Icons.local_shipping_outlined,
                          title: 'Pengiriman cepat',
                          subtitle: '1–2 hari',
                        ),
                      ],
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
                      onPressed: product.fitment != ProductFitment.incompatible
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
                      onPressed: product.fitment != ProductFitment.incompatible
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

class WorkshopListScreen extends StatelessWidget {
  final OtoKuState state;
  const WorkshopListScreen({super.key, required this.state});
  @override
  Widget build(BuildContext c) => SafeArea(
    child: ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Peta',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 4),
        const Text(
          'Demo area Bekasi Utara • data tempat contoh',
          style: TextStyle(color: AppColors.muted),
        ),
        const SizedBox(height: 12),
        const CardBox(
          color: Color(0xFFFFF7E6),
          child: Text(
            'Peta dan lokasi langsung belum terhubung. Cari berdasarkan area untuk melihat data demo.',
            style: TextStyle(fontSize: 12),
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          decoration: InputDecoration(
            hintText: 'Cari tempat atau area...',
            prefixIcon: const Icon(Icons.search),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderSide: BorderSide.none,
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),
        const SizedBox(height: 14),
        const Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            Pill('Semua', active: true),
            Pill('Terdekat'),
            Pill('Terbaik'),
          ],
        ),
        const SizedBox(height: 16),
        ...state.workshops.map(
          (w) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: WorkshopCard(
              w: w,
              onTap: () =>
                  push(c, WorkshopDetailScreen(state: state, workshop: w)),
            ),
          ),
        ),
      ],
    ),
  );
}

class WorkshopCard extends StatelessWidget {
  final Workshop w;
  final VoidCallback onTap;
  const WorkshopCard({super.key, required this.w, required this.onTap});
  @override
  Widget build(BuildContext c) => CardBox(
    onTap: onTap,
    child: Row(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: AppColors.ink,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            Icons.storefront_outlined,
            color: AppColors.red,
            size: 40,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(w.name, style: const TextStyle(fontWeight: FontWeight.w800)),
              Text(
                '★ ${w.rating}  ·  ${w.distance}',
                style: const TextStyle(
                  color: AppColors.amber,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 5),
              const Text(
                'Bengkel demo • belum diverifikasi',
                style: TextStyle(color: AppColors.muted, fontSize: 12),
              ),
              Text(
                w.services,
                style: const TextStyle(color: AppColors.muted, fontSize: 11),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class WorkshopDetailScreen extends StatelessWidget {
  final OtoKuState state;
  final Workshop workshop;
  const WorkshopDetailScreen({
    super.key,
    required this.state,
    required this.workshop,
  });
  @override
  Widget build(BuildContext c) => Page(
    title: 'Detail Bengkel',
    bottomBar: SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        child: FilledButton(
          onPressed: () =>
              push(c, BookingScreen(state: state, workshop: workshop)),
          style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
          child: const Text('Booking demo'),
        ),
      ),
    ),
    child: ScrollPage(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CardBox(
            color: AppColors.ink,
            child: SizedBox(
              height: 150,
              child: Center(
                child: Icon(
                  Icons.storefront_outlined,
                  color: AppColors.red,
                  size: 72,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            workshop.name,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
          ),
          Text(
            '★ ${workshop.rating} · ${workshop.distance}',
            style: const TextStyle(
              color: AppColors.amber,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Bengkel demo • jam operasional belum diverifikasi',
            style: TextStyle(color: AppColors.muted),
          ),
          const SizedBox(height: 12),
          const Row(
            children: [
              OutlinedButton(onPressed: null, child: Text('Rute')),
              OutlinedButton(onPressed: null, child: Text('Hubungi')),
              OutlinedButton(onPressed: null, child: Text('Simpan')),
            ],
          ),
          const SectionTitle('Layanan populer'),
          ServiceRow('Ganti Oli Mesin', 'Rp 50.000', '30 menit'),
          ServiceRow('Servis CVT', 'Rp 80.000', '45 menit'),
        ],
      ),
    ),
  );
}

class BookingServiceTile extends StatelessWidget {
  final String title, price, duration;
  final bool selected;
  final VoidCallback onTap;
  const BookingServiceTile({
    super.key,
    required this.title,
    required this.price,
    required this.duration,
    required this.selected,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) => CardBox(
    onTap: onTap,
    child: Row(
      children: [
        const ProductArt(icon: 'oil'),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
              Text(
                '$price · $duration',
                style: const TextStyle(color: AppColors.muted, fontSize: 12),
              ),
            ],
          ),
        ),
        Icon(
          selected ? Icons.check_circle : Icons.radio_button_unchecked,
          color: selected ? AppColors.red : AppColors.muted,
        ),
      ],
    ),
  );
}

class ServiceRow extends StatelessWidget {
  final String a, b, d;
  const ServiceRow(this.a, this.b, this.d, {super.key});
  @override
  Widget build(BuildContext c) => CardBox(
    child: Row(
      children: [
        const Icon(Icons.build_circle_outlined, color: AppColors.red),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(a, style: const TextStyle(fontWeight: FontWeight.w800)),
              Text(
                '$b · $d',
                style: const TextStyle(color: AppColors.muted, fontSize: 12),
              ),
            ],
          ),
        ),
        const Text(
          'Pilih',
          style: TextStyle(color: AppColors.red, fontWeight: FontWeight.w800),
        ),
      ],
    ),
  );
}

class BookingScreen extends StatefulWidget {
  final OtoKuState state;
  final Workshop workshop;
  const BookingScreen({super.key, required this.state, required this.workshop});
  @override
  State<BookingScreen> createState() => _BookingState();
}

class _BookingState extends State<BookingScreen> {
  int day = 1, time = 2;
  bool oilSelected = true, cvtSelected = false;
  @override
  Widget build(BuildContext c) => Page(
    title: 'Booking Layanan',
    bottomBar: SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        child: FilledButton(
          onPressed: () {
            widget.state.addBooking(widget.workshop.name);
            Navigator.popUntil(c, (r) => r.isFirst);
          },
          style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
          child: const Text('Lanjutkan'),
        ),
      ),
    ),
    child: ScrollPage(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CardBox(
            child: Row(
              children: [
                const Icon(Icons.storefront_outlined, size: 40),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.workshop.name,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    const Text(
                      'Bekasi Utara',
                      style: TextStyle(color: AppColors.muted),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SectionTitle('Pilih Layanan'),
          BookingServiceTile(
            title: 'Ganti Oli Mesin',
            price: 'Rp 50.000',
            duration: '30 menit',
            selected: oilSelected,
            onTap: () => setState(() => oilSelected = !oilSelected),
          ),
          BookingServiceTile(
            title: 'Servis CVT',
            price: 'Rp 80.000',
            duration: '45 menit',
            selected: cvtSelected,
            onTap: () => setState(() => cvtSelected = !cvtSelected),
          ),
          const SectionTitle('Pilih Tanggal'),
          Wrap(
            spacing: 8,
            children: List.generate(
              5,
              (i) => GestureDetector(
                onTap: () => setState(() => day = i),
                child: Pill(
                  [
                    'Sen 22 Sep',
                    'Sel 23 Sep',
                    'Rab 24 Sep',
                    'Kam 25 Sep',
                    'Jum 26 Sep',
                  ][i],
                  active: day == i,
                ),
              ),
            ),
          ),
          const SectionTitle('Pilih Waktu'),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children:
                [
                  '08:00',
                  '09:00',
                  '10:00',
                  '11:00',
                  '13:00',
                  '14:00',
                  '15:00',
                  '16:00',
                ].map((x) {
                  final i = [
                    '08:00',
                    '09:00',
                    '10:00',
                    '11:00',
                    '13:00',
                    '14:00',
                    '15:00',
                    '16:00',
                  ].indexOf(x);
                  return GestureDetector(
                    onTap: () => setState(() => time = i),
                    child: Pill(x, active: time == i),
                  );
                }).toList(),
          ),
          const SectionTitle('Catatan (opsional)'),
          const TextField(
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'Contoh: minta dicek bagian lain juga',
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(borderSide: BorderSide.none),
            ),
          ),
        ],
      ),
    ),
  );
}

class OrdersScreen extends StatelessWidget {
  final OtoKuState state;
  const OrdersScreen({super.key, required this.state});
  @override
  Widget build(BuildContext c) => SafeArea(
    child: ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Pesanan Saya',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 18),
        const Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            Pill('Sparepart', selectedTint: true),
            Pill('Layanan'),
            Pill('Semua'),
          ],
        ),
        const SizedBox(height: 16),
        ...state.orders.map(
          (x) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: OrderCard(
              order: x,
              onTap: () => push(c, OrderDetailScreen(order: x)),
            ),
          ),
        ),
      ],
    ),
  );
}

class OrderCard extends StatelessWidget {
  final String order;
  final VoidCallback onTap;
  const OrderCard({super.key, required this.order, required this.onTap});
  @override
  Widget build(BuildContext context) {
    final fields = order.split(' • ');
    final status = fields.firstWhere(
      (x) => [
        'Diproses',
        'Dikirim',
        'Selesai',
        'Pesanan Selesai',
        'Dibatalkan',
      ].contains(x),
      orElse: () => 'Diproses',
    );
    final date = fields.length > 1 ? fields.last : '';
    return CardBox(
      onTap: onTap,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ProductArt(icon: order.contains('Oli') ? 'oil' : 'brake'),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        fields.first,
                        style: const TextStyle(
                          color: AppColors.muted,
                          fontSize: 10,
                        ),
                      ),
                    ),
                    StatusChip(
                      status,
                      status == 'Diproses' || status == 'Dikirim'
                          ? AppColors.amber
                          : AppColors.green,
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                Text(
                  fields.length > 1 ? fields[1] : order,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                ),
                if (fields.length > 2)
                  Text(
                    fields.sublist(2, fields.length - 1).join(' · '),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 10,
                    ),
                  ),
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    date,
                    style: const TextStyle(color: AppColors.muted, fontSize: 9),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class OrderDetailScreen extends StatelessWidget {
  final String order;
  const OrderDetailScreen({super.key, required this.order});
  @override
  Widget build(BuildContext context) => Page(
    title: 'Detail Pesanan',
    child: ScrollPage(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            order.split(' • ').first,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 16),
          const CardBox(
            child: Column(
              children: [
                ListTile(
                  leading: Icon(Icons.check_circle, color: AppColors.green),
                  title: Text('Pesanan dibuat'),
                  subtitle: Text('Berhasil dibuat'),
                ),
                ListTile(
                  leading: Icon(Icons.inventory_2_outlined),
                  title: Text('Sedang dikemas'),
                  subtitle: Text('Pesanan sedang diproses'),
                ),
                ListTile(
                  leading: Icon(Icons.local_shipping_outlined),
                  title: Text('Dikirim'),
                  subtitle: Text('Menunggu proses pengiriman'),
                ),
                ListTile(
                  leading: Icon(Icons.home_outlined),
                  title: Text('Selesai'),
                  subtitle: Text('Belum selesai'),
                ),
              ],
            ),
          ),
          const SectionTitle('Ringkasan'),
          CardBox(
            child: Text(
              order.replaceAll(' • ', '\n'),
              style: const TextStyle(height: 1.6),
            ),
          ),
          const SectionTitle('Pembayaran'),
          const CardBox(
            child: Text(
              'Pembayaran mock\nTotal mengikuti ringkasan pesanan',
              style: TextStyle(height: 1.6),
            ),
          ),
        ],
      ),
    ),
  );
}

class AccountScreen extends StatelessWidget {
  final OtoKuState state;
  const AccountScreen({super.key, required this.state});
  @override
  Widget build(BuildContext c) => SafeArea(
    child: ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            const Text(
              'Akun Saya',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
            ),
            const Spacer(),
            IconButton(
              onPressed: () {},
              tooltip: 'Pengaturan akun',
              icon: const Icon(Icons.settings_outlined),
            ),
          ],
        ),
        const SizedBox(height: 12),
        const CardBox(
          child: Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: Color(0xFFE8E8E8),
                child: Text(
                  'AB',
                  style: TextStyle(
                    color: AppColors.ink,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              SizedBox(width: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Agus Budiyanto',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                  ),
                  Text(
                    'agus.budiyanto@email.com',
                    style: TextStyle(color: AppColors.muted, fontSize: 12),
                  ),
                  Text(
                    'Lihat Profil ›',
                    style: TextStyle(color: AppColors.red, fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        ...[
          'Kendaraan Saya',
          'Pesanan Saya',
          'Booking Layanan',
          'Alamat Saya',
          'Metode Pembayaran',
          'Voucher & Promo',
          'Pusat Bantuan',
          'Tentang OtoKu',
        ].map(
          (x) => CardBox(
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(x),
              trailing: const Icon(Icons.chevron_right),
            ),
          ),
        ),
        const SizedBox(height: 10),
        const CardBox(
          child: ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.logout, color: AppColors.red),
            title: Text(
              'Logout',
              style: TextStyle(
                color: AppColors.red,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
      ],
    ),
  );
}

class CheckoutScreen extends StatelessWidget {
  final OtoKuState state;
  const CheckoutScreen({super.key, required this.state});
  @override
  Widget build(BuildContext c) => Page(
    title: 'Checkout',
    child: ScrollPage(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Ringkasan pesanan',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 14),
          ...state.cart.map(
            (p) => CardBox(
              child: Row(
                children: [
                  ProductArt(icon: p.icon),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      p.name,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                  Text(
                    p.price,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ],
              ),
            ),
          ),
          const SectionTitle('Alamat pengiriman'),
          const CardBox(
            child: Text(
              'Agus Budiyanto\nBekasi Utara\nAlamat mock untuk prototype',
              style: TextStyle(height: 1.5),
            ),
          ),
          const SectionTitle('Metode pembayaran'),
          const CardBox(
            child: Row(
              children: [
                Icon(Icons.account_balance_wallet_outlined),
                SizedBox(width: 10),
                Text('Pembayaran mock'),
                Spacer(),
                Icon(Icons.check_circle, color: AppColors.green),
              ],
            ),
          ),
          const SizedBox(height: 22),
          FilledButton(
            onPressed: () {
              state.checkout(
                state.cart.isNotEmpty ? state.cart.first.name : 'Sparepart',
              );
              Navigator.popUntil(c, (r) => r.isFirst);
            },
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
            ),
            child: const Text('Buat Pesanan'),
          ),
        ],
      ),
    ),
  );
}
