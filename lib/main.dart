import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:marionette_flutter/marionette_flutter.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'data/oto_ku_repository.dart';

Future<void> main() async {
  // Marionette gives AI agents (via the marionette MCP server) eyes and hands
  // on the running app in debug builds; release builds use the normal binding.
  if (kDebugMode) {
    MarionetteBinding.ensureInitialized();
  } else {
    WidgetsFlutterBinding.ensureInitialized();
  }
  if (Platform.isLinux || Platform.isMacOS || Platform.isWindows) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }
  final repository = await SqliteOtoKuRepository.open();
  runApp(OtoKuApp(repository: repository));
}

String formatKilometers(int value) => value.toString().replaceAllMapped(
  RegExp(r'\B(?=(\d{3})+(?!\d))'),
  (_) => '.',
);

class AppColors {
  static const red = Color(0xFFE11D48), redDark = Color(0xFFDC2626);
  static const ink = Color(0xFF18181B), muted = Color(0xFF71717A);
  static const bg = Color(0xFFF8F8F9), border = Color(0xFFE4E4E7);
  static const green = Color(0xFF15803D), amber = Color(0xFFD97706);
  static const redTint = Color(0xFFFFF1F2), greenTint = Color(0xFFDCFCE7);
  static const amberTint = Color(0xFFFEF3C7), darkSurface = Color(0xFF18181B);
  // Kinetic Precision warm-neutral surfaces.
  static const surfaceLow = Color(0xFFF4F4F5);
  static const surfaceHigh = Color(0xFFE4E4E7);
  static const navy = Color(0xFF27272A);
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
  String get id => name.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '-');
  String get imageAsset => switch (icon) {
    'oil' => 'assets/product_images/engine_oil.jpg',
    'brake' =>
      name.contains('Mobil')
          ? 'assets/product_images/car_brake_pads.jpg'
          : 'assets/product_images/motorcycle_brake_pads.jpg',
    'filter' => 'assets/product_images/air_filter.jpg',
    'battery' => 'assets/product_images/motorcycle_battery.jpg',
    'lamp' => 'assets/product_images/led_bulb.jpg',
    _ => '',
  };
}

class Workshop {
  final String name, rating, distance, services, category, address;
  final bool partner, bookingEnabled;
  Workshop(
    this.name,
    this.rating,
    this.distance,
    this.services, {
    this.category = 'Bengkel',
    this.address = 'Bekasi Utara · lokasi demo',
    this.partner = false,
    this.bookingEnabled = false,
  });
}

class OtoKuState extends ChangeNotifier {
  OtoKuState({OtoKuRepository? repository})
    : repository = repository ?? MemoryOtoKuRepository();

  final OtoKuRepository repository;
  bool onboardingComplete = false;
  bool initialized = false;
  final logs = <Map<String, dynamic>>[];
  final bookings = <String>[];
  final completedMaintenance = <String>{};

  Vehicle vehicle = Vehicle(
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
      fitment: ProductFitment.possibleUnverified,
    ),
    Product(
      'Kampas Rem Depan Beat',
      'Rem',
      'Rp 85.000',
      'brake',
      fitment: ProductFitment.possibleUnverified,
    ),
    Product(
      'Filter Udara Honda Beat',
      'Filter',
      'Rp 42.000',
      'filter',
      fitment: ProductFitment.possibleUnverified,
    ),
    Product('Aki Motor YTZ5S', 'Aki', 'Rp 185.000', 'battery'),
    Product('Lampu LED Universal', 'Aksesori', 'Rp 75.000', 'lamp'),
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
      'Belum dinilai',
      '2.1 km (demo)',
      'Servis Rutin · Ganti Oli',
      category: 'Bengkel',
      partner: true,
      bookingEnabled: true,
    ),
    Workshop(
      'AutoCare Plus',
      'Belum dinilai',
      '3.4 km (demo)',
      'Spesialis CVT · Rem · Oli',
      category: 'Bengkel',
    ),
    Workshop(
      'Speed Motor',
      'Belum dinilai',
      '4.2 km (demo)',
      'Servis Lengkap · Body Part',
      category: 'Bengkel',
    ),
    Workshop(
      'SPBU Pertamina Demo',
      'Belum dinilai',
      '1.8 km (demo)',
      'Bahan bakar · area Bekasi Utara',
      category: 'SPBU',
    ),
    Workshop(
      'Minimarket Demo',
      'Belum dinilai',
      '0.9 km (demo)',
      'Kebutuhan perjalanan · area Bekasi Utara',
      category: 'Minimarket',
    ),
  ];
  final cart = <Product>[];
  final orders = <String>[];
  Future<void> restore() async {
    onboardingComplete = await repository.hasCompletedOnboarding();
    final saved = await repository.loadState();
    if (saved != null) {
      final savedVehicle = saved['vehicle'];
      final details = savedVehicle is Map
          ? Map<String, dynamic>.from(savedVehicle)
          : <String, dynamic>{};
      final mileage = details['mileage'] ?? saved['mileage'];
      vehicle = Vehicle(
        brand: details['brand'] as String? ?? vehicle.brand,
        model: details['model'] as String? ?? vehicle.model,
        plate: details['plate'] as String? ?? vehicle.plate,
        type: details['type'] as String? ?? vehicle.type,
        year: details['year'] as int? ?? vehicle.year,
        mileage: mileage is int && mileage >= 0 ? mileage : vehicle.mileage,
      );
      obdConnected = saved['obdConnected'] == true;
      orders
        ..clear()
        ..addAll((saved['orders'] as List<dynamic>? ?? []).cast<String>());
      cart
        ..clear()
        ..addAll(
          (saved['cart'] as List<dynamic>? ?? [])
              .cast<String>()
              .map((id) => products.where((product) => product.id == id))
              .where((matches) => matches.isNotEmpty)
              .map((matches) => matches.first),
        );
      logs
        ..clear()
        ..addAll(
          (saved['logs'] as List<dynamic>? ?? []).whereType<Map>().map(
            (log) => Map<String, dynamic>.from(log),
          ),
        );
      bookings
        ..clear()
        ..addAll((saved['bookings'] as List<dynamic>? ?? []).cast<String>());
      completedMaintenance
        ..clear()
        ..addAll(
          (saved['completedMaintenance'] as List<dynamic>? ?? [])
              .cast<String>(),
        );
    }
    initialized = true;
    notifyListeners();
  }

  Future<void> finishOnboarding() async {
    onboardingComplete = true;
    await repository.completeOnboarding();
    notifyListeners();
  }

  Future<void> _persist() => repository.saveState({
    'mileage': vehicle.mileage,
    'vehicle': {
      'brand': vehicle.brand,
      'model': vehicle.model,
      'plate': vehicle.plate,
      'type': vehicle.type,
      'year': vehicle.year,
      'mileage': vehicle.mileage,
    },
    'obdConnected': obdConnected,
    'cart': cart.map((product) => product.id).toList(),
    'orders': orders,
    'logs': logs,
    'bookings': bookings,
    'completedMaintenance': completedMaintenance.toList(),
  });

  Future<void> connectObd() async {
    obdConnected = true;
    notifyListeners();
    await _persist();
  }

  Future<void> disconnectObd() async {
    obdConnected = false;
    notifyListeners();
    await _persist();
  }

  int quantityOf(Product product) =>
      cart.where((item) => item.id == product.id).length;

  int get cartSubtotal => cart.fold(
    0,
    (sum, product) =>
        sum + int.parse(product.price.replaceAll(RegExp(r'[^0-9]'), '')),
  );

  Future<void> add(Product p) async {
    cart.add(p);
    notifyListeners();
    await _persist();
  }

  Future<void> removeOne(Product product) async {
    final index = cart.lastIndexWhere((item) => item.id == product.id);
    if (index >= 0) cart.removeAt(index);
    notifyListeners();
    await _persist();
  }

  Future<String> checkout() async {
    if (cart.isEmpty) throw StateError('Cart is empty.');
    final id =
        '#SP${DateTime.now().millisecondsSinceEpoch.toString().substring(5)}';
    final date = DateTime.now();
    final summary = cart
        .map((product) => '${quantityOf(product)}x ${product.name}')
        .toSet()
        .join(', ');
    final order =
        '$id • $summary • Menunggu pembayaran • Rp ${formatKilometers(cartSubtotal)} • ${date.day}/${date.month}/${date.year}';
    orders.insert(0, order);
    cart.clear();
    notifyListeners();
    await _persist();
    return order;
  }

  Future<String> addBooking(
    String workshop, {
    required List<String> services,
    required DateTime date,
    required String time,
    String notes = '',
  }) async {
    final booking =
        'Booking $workshop · ${services.join(', ')} · ${date.day}/${date.month}/${date.year} $time${notes.trim().isEmpty ? '' : ' · Catatan: ${notes.trim()}'}';
    bookings.insert(0, booking);
    orders.insert(
      0,
      '#SV${DateTime.now().millisecondsSinceEpoch.toString().substring(5)} • $booking • Menunggu konfirmasi • ${date.day}/${date.month}/${date.year}',
    );
    notifyListeners();
    await _persist();
    return booking;
  }

  Future<void> addLog(Map<String, dynamic> log) async {
    logs.insert(0, log);
    notifyListeners();
    await _persist();
  }

  Future<void> completeMaintenance(String title) async {
    completedMaintenance.add(title);
    notifyListeners();
    await _persist();
  }

  Future<void> updateVehicle(Vehicle updated) async {
    if (updated.mileage < vehicle.mileage) {
      throw ArgumentError('Odometer cannot decrease without correction.');
    }
    final mileageChanged = updated.mileage != vehicle.mileage;
    vehicle = updated;
    if (mileageChanged) {
      logs.insert(0, {
        'type': 'odometer',
        'title': 'Kilometer diperbarui',
        'value': updated.mileage,
        'date': DateTime.now().toIso8601String(),
        'source': 'manual',
      });
    }
    notifyListeners();
    await _persist();
  }

  Future<void> updateMileage(int mileage) => updateVehicle(
    Vehicle(
      brand: vehicle.brand,
      model: vehicle.model,
      plate: vehicle.plate,
      type: vehicle.type,
      year: vehicle.year,
      mileage: mileage,
    ),
  );
}

class OtoKuApp extends StatefulWidget {
  final OtoKuRepository? repository;
  const OtoKuApp({super.key, this.repository});
  @override
  State<OtoKuApp> createState() => _OtoKuAppState();
}

class _OtoKuAppState extends State<OtoKuApp> {
  late final state = OtoKuState(repository: widget.repository);

  @override
  void initState() {
    super.initState();
    appTabIndex.value = 0;
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: state,
    builder: (context, child) => MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'OtoKu',
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: AppColors.bg,
        canvasColor: AppColors.bg,
        colorScheme: const ColorScheme(
          brightness: Brightness.light,
          primary: AppColors.red,
          onPrimary: Colors.white,
          primaryContainer: Color(0xFFFFE4E6),
          onPrimaryContainer: Color(0xFF4C0519),
          secondary: Color(0xFF52525B),
          onSecondary: Colors.white,
          secondaryContainer: Color(0xFFF4F4F5),
          onSecondaryContainer: AppColors.ink,
          tertiary: Color(0xFF3F3F46),
          onTertiary: Colors.white,
          tertiaryContainer: Color(0xFFF4F4F5),
          onTertiaryContainer: AppColors.ink,
          error: AppColors.redDark,
          onError: Colors.white,
          errorContainer: Color(0xFFFFF1F2),
          onErrorContainer: Color(0xFF9F1239),
          surface: Colors.white,
          onSurface: AppColors.ink,
          onSurfaceVariant: Color(0xFF52525B),
          surfaceContainerLowest: Colors.white,
          surfaceContainerLow: AppColors.surfaceLow,
          surfaceContainer: Color(0xFFEFEFF1),
          surfaceContainerHigh: AppColors.surfaceHigh,
          surfaceContainerHighest: Color(0xFFE9E9EB),
          outline: Color(0xFFA1A1AA),
          outlineVariant: AppColors.border,
          inverseSurface: AppColors.ink,
          onInverseSurface: Color(0xFFFAFAFA),
          inversePrimary: Color(0xFFFDA4AF),
          surfaceTint: AppColors.red,
          shadow: Color(0xFF09090B),
          scrim: Color(0xFF09090B),
        ),
        fontFamily: 'Plus Jakarta Sans',
        dividerColor: AppColors.border,
        dialogTheme: DialogThemeData(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        bottomSheetTheme: const BottomSheetThemeData(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          modalBackgroundColor: Colors.white,
          modalBarrierColor: Color(0x9909090B),
        ),
        snackBarTheme: SnackBarThemeData(
          backgroundColor: AppColors.ink,
          contentTextStyle: const TextStyle(
            color: Colors.white,
            fontFamily: 'Plus Jakarta Sans',
            fontSize: 13,
          ),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        chipTheme: ChipThemeData(
          backgroundColor: AppColors.surfaceLow,
          selectedColor: AppColors.red,
          side: BorderSide.none,
          labelStyle: const TextStyle(
            color: AppColors.muted,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
          secondaryLabelStyle: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
          shape: const StadiumBorder(),
        ),
        tabBarTheme: const TabBarThemeData(
          indicatorColor: AppColors.red,
          labelColor: AppColors.red,
          unselectedLabelColor: AppColors.muted,
          dividerColor: AppColors.border,
        ),
        progressIndicatorTheme: const ProgressIndicatorThemeData(
          color: AppColors.red,
          linearTrackColor: AppColors.surfaceHigh,
          circularTrackColor: AppColors.surfaceHigh,
        ),
        textTheme: const TextTheme(
          headlineMedium: TextStyle(
            fontFamily: 'Space Grotesk',
            fontSize: 24,
            fontWeight: FontWeight.w700,
            letterSpacing: -.5,
            color: AppColors.ink,
          ),
          titleLarge: TextStyle(
            fontFamily: 'Space Grotesk',
            fontSize: 20,
            fontWeight: FontWeight.w700,
            letterSpacing: -.3,
            color: AppColors.ink,
          ),
          titleMedium: TextStyle(
            fontFamily: 'Space Grotesk',
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: -.1,
            color: AppColors.ink,
          ),
          bodyMedium: TextStyle(color: AppColors.ink, height: 1.35),
          bodySmall: TextStyle(color: AppColors.muted, height: 1.35),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColors.surfaceLow,
          hintStyle: const TextStyle(color: AppColors.muted),
          border: OutlineInputBorder(
            borderSide: BorderSide.none,
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.red,
            foregroundColor: Colors.white,
            minimumSize: const Size(48, 48),
            textStyle: const TextStyle(
              fontWeight: FontWeight.w700,
              letterSpacing: -.1,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
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

/// Warm ambient shadow from the Kinetic Precision layer-1 cards.
const _cardShadow = [
  BoxShadow(color: Color(0x0A18181B), blurRadius: 8, offset: Offset(0, 2)),
];

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
    _openApp();
  }

  Future<void> _openApp() async {
    await widget.state.restore();
    await Future<void>.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;
    final next = widget.state.onboardingComplete
        ? AppShell(state: widget.state)
        : OnboardingScreen(state: widget.state);
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => next));
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.ink,
    body: SafeArea(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/OtoKu Logo.png',
              width: 220,
              height: 88,
              fit: BoxFit.contain,
              semanticLabel: 'OtoKu',
            ),
            const SizedBox(height: 18),
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

class OnboardingScreen extends StatefulWidget {
  final OtoKuState state;
  const OnboardingScreen({super.key, required this.state});
  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _controller = PageController();
  int _page = 0;
  static const _pages = [
    (
      Icons.two_wheeler_outlined,
      'Rawat kendaraan lebih mudah',
      'Catat kilometer, servis, dan pengeluaran kendaraan dalam satu tempat.',
    ),
    (
      Icons.health_and_safety_outlined,
      'Kamu tetap bisa tanpa OBD',
      'Fitur perawatan manual tetap berjalan. Data OBD demo selalu diberi label simulasi.',
    ),
    (
      Icons.storefront_outlined,
      'Temukan produk dan bengkel',
      'Cari kebutuhan kendaraan dan lihat status kecocokannya sebelum memilih.',
    ),
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    await widget.state.finishOnboarding();
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => AppShell(state: widget.state)),
    );
  }

  void _next() {
    if (_page == _pages.length - 1) {
      _finish();
    } else {
      _controller.nextPage(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.bg,
    body: SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        child: Column(
          children: [
            Row(
              children: [
                Image.asset('assets/OtoKu Logo.png', width: 86, height: 32),
                const Spacer(),
                TextButton(onPressed: _finish, child: const Text('Lewati')),
              ],
            ),
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: _pages.length,
                onPageChanged: (index) => setState(() => _page = index),
                itemBuilder: (context, index) {
                  final page = _pages[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 180,
                          height: 180,
                          decoration: BoxDecoration(
                            color: AppColors.redTint,
                            borderRadius: BorderRadius.circular(48),
                          ),
                          child: Icon(page.$1, color: AppColors.red, size: 82),
                        ),
                        const SizedBox(height: 36),
                        Text(
                          page.$2,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 28,
                            height: 1.15,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          page.$3,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 16,
                            height: 1.5,
                            color: AppColors.muted,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _pages.length,
                (index) => AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  width: _page == index ? 22 : 7,
                  height: 7,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    color: _page == index ? AppColors.red : AppColors.border,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _next,
                child: Text(_page == _pages.length - 1 ? 'Mulai' : 'Lanjut'),
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
  void initState() {
    super.initState();
    index = appTabIndex.value;
    appTabIndex.addListener(_syncTab);
  }

  void _syncTab() {
    if (!mounted || index == appTabIndex.value) return;
    setState(() => index = appTabIndex.value);
  }

  @override
  void dispose() {
    appTabIndex.removeListener(_syncTab);
    super.dispose();
  }

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
        onDestinationSelected: (i) {
          appTabIndex.value = i;
          setState(() => index = i);
        },
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
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: AppColors.border),
      boxShadow: _cardShadow,
    ),
    child: Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(18),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(padding: padding, child: child),
      ),
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
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            letterSpacing: -.3,
          ),
        ),
        const Spacer(),
        if (action != null)
          TextButton(
            onPressed: onTap,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              minimumSize: Size.zero,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  action!,
                  style: const TextStyle(
                    color: AppColors.red,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
                const Icon(Icons.arrow_forward, size: 14, color: AppColors.red),
              ],
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
          : AppColors.surfaceLow,
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
                              Color(0xFFFAFAFA),
                              Color(0xFFF4F4F5),
                              Color(0xFFE9E7EA),
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
                        value: 'Belum dicatat',
                        unit: '',
                        label: 'SERVIS TERAKHIR',
                      ),
                      _VehicleStatData(
                        icon: Icons.info_outline,
                        value: 'Belum dicek',
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
                        onPressed: () => showNotificationSheet(context),
                        icon: const Icon(Icons.notifications_none),
                      ),
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
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: AppColors.red,
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
                GestureDetector(
                  onTap: () => openTab(context, 1),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceLow,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.search, color: AppColors.muted, size: 20),
                        SizedBox(width: 9),
                        Expanded(
                          child: Text(
                            'Cari sparepart, bengkel, atau layanan...',
                            style: TextStyle(
                              color: AppColors.muted,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        Icon(Icons.tune, color: AppColors.muted, size: 18),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                HomeVehicleCard(
                  state: state,
                  onTap: () => push(context, VehicleDetailScreen(state: state)),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _HomeQuickAction(
                        icon: Icons.add_circle_outline,
                        label: 'Catat aktivitas',
                        onTap: () =>
                            push(context, ManualLogScreen(state: state)),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _HomeQuickAction(
                        icon: Icons.route_outlined,
                        label: 'Mulai Trip',
                        onTap: () => showPrototypeNotice(
                          context,
                          'Mulai Trip',
                          'Pelacakan GPS trip belum tersedia. OtoKu tidak akan merekam lokasi; kamu tetap bisa mencatat kilometer secara manual.',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                SectionTitle(
                  'Perawatan Berikutnya',
                  action: 'Lihat Semua',
                  onTap: () => push(context, MaintenanceScreen(state: state)),
                ),
                MaintenanceCard(
                  state: state,
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

class _HomeQuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _HomeQuickAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.white,
    borderRadius: BorderRadius.circular(14),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppColors.red, size: 19),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: 3),
            const Icon(Icons.chevron_right, color: AppColors.muted, size: 16),
          ],
        ),
      ),
    ),
  );
}

class LockedObdCard extends StatefulWidget {
  final OtoKuState state;
  const LockedObdCard({super.key, required this.state});
  @override
  State<LockedObdCard> createState() => _LockedObdCardState();
}

class _LockedObdCardState extends State<LockedObdCard> {
  late final PageController _controller;
  int _page = 0;

  @override
  void initState() {
    super.initState();
    _controller = PageController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Column(
    children: [
      SizedBox(
        height: 104,
        child: PageView(
          controller: _controller,
          onPageChanged: (page) => setState(() => _page = page),
          children: [
            _ObdAdSlide(
              badge: 'DEMO',
              title: 'OtoKu OBD-II Scanner',
              body: 'Diagnosa & cek voltase aki dari HP',
              action: 'Lihat',
              icon: Icons.bluetooth_searching,
              onTap: () => showObdSheet(context, widget.state),
            ),
            _ObdAdSlide(
              badge: 'SIMULASI',
              title: 'Data mesin lebih jelas',
              body: 'RPM, suhu mesin & kode masalah',
              action: 'Coba',
              icon: Icons.insights_outlined,
              onTap: () => showObdSheet(context, widget.state),
            ),
            _ObdAdSlide(
              badge: 'SHOP',
              title: 'Lengkapi perawatan',
              body: 'Sparepart & layanan yang sesuai',
              action: 'Buka',
              icon: Icons.shopping_bag_outlined,
              onTap: () => openTab(context, 1),
            ),
          ],
        ),
      ),
      const SizedBox(height: 8),
      Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(
          3,
          (index) => AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.only(right: 6),
            width: index == _page ? 16 : 6,
            height: 6,
            decoration: BoxDecoration(
              color: index == _page ? AppColors.red : AppColors.surfaceHigh,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ),
      ),
    ],
  );
}

class _ObdAdSlide extends StatelessWidget {
  final String badge, title, body, action;
  final IconData icon;
  final VoidCallback onTap;
  const _ObdAdSlide({
    required this.badge,
    required this.title,
    required this.body,
    required this.action,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(12),
      gradient: const LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [Color(0xFF18181B), Color(0xFF27272A)],
      ),
      border: Border.all(color: const Color(0xFF3F3F46)),
      boxShadow: const [
        BoxShadow(
          color: Color(0x1418181B),
          blurRadius: 8,
          offset: Offset(0, 2),
        ),
      ],
    ),
    child: Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: .10),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.white.withValues(alpha: .15)),
          ),
          child: Icon(icon, color: const Color(0xFF34D399), size: 20),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                children: [
                  Flexible(
                    child: Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        height: 1.15,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.redDark,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      badge,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                body,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Color(0xFFA1A1AA), fontSize: 11),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: .15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withValues(alpha: .20)),
            ),
            child: Row(
              children: [
                Text(
                  action,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(Icons.arrow_forward, color: Colors.white, size: 13),
              ],
            ),
          ),
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
  final OtoKuState state;
  final VoidCallback onTap;
  const MaintenanceCard({super.key, required this.state, required this.onTap});
  @override
  Widget build(BuildContext context) {
    final done = state.completedMaintenance.contains('Ganti Oli Mesin');
    return CardBox(
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: done ? AppColors.greenTint : AppColors.redTint,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              Icons.oil_barrel_outlined,
              color: done ? AppColors.green : AppColors.red,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Flexible(
                      child: Text(
                        'Ganti Oli Mesin',
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ),
                    const SizedBox(width: 8),
                    StatusChip(
                      done ? 'Selesai' : 'Segera',
                      done ? AppColors.green : AppColors.red,
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  done
                      ? 'Ditandai selesai oleh kamu'
                      : 'Estimasi target: ${formatKilometers((14000 - state.vehicle.mileage).clamp(0, 14000))} km lagi',
                  style: const TextStyle(color: AppColors.muted, fontSize: 13),
                ),
                const SizedBox(height: 2),
                const Text(
                  'Jadwal perkiraan · cek buku servis',
                  style: TextStyle(color: AppColors.muted, fontSize: 12),
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

/// Selected bottom-navigation tab, shared so pushed screens can hand control
/// back to the tab shell instead of opening a full-screen copy without tabs.
final appTabIndex = ValueNotifier<int>(0);

void openTab(BuildContext context, int index) {
  appTabIndex.value = index;
  Navigator.of(context).popUntil((route) => route.isFirst);
}

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
                  ? 'Simulasi OBD aktif'
                  : 'Coba simulasi data OBD',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 8),
            Text(
              state.obdConnected
                  ? 'Contoh RPM, suhu mesin, dan kode masalah. Data ini bukan pembacaan langsung dari kendaraan.'
                  : 'Lihat contoh RPM, suhu mesin, dan kode masalah. Perangkat OBD belum terhubung.',
              style: const TextStyle(color: AppColors.muted, height: 1.4),
            ),
            const SizedBox(height: 18),
            FilledButton(
              onPressed: () {
                state.obdConnected ? state.disconnectObd() : state.connectObd();
                Navigator.pop(context);
              },
              child: Text(
                state.obdConnected ? 'Tutup simulasi' : 'Lihat simulasi OBD',
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
            leading: Icon(Icons.notifications_none, color: AppColors.muted),
            title: Text('Belum ada notifikasi'),
            subtitle: Text(
              'Pengingat akan muncul setelah kamu mencatat aktivitas atau pesanan.',
            ),
          ),
        ],
      ),
    ),
  );
}

class VehicleEditScreen extends StatefulWidget {
  final OtoKuState state;
  const VehicleEditScreen({super.key, required this.state});
  @override
  State<VehicleEditScreen> createState() => _VehicleEditScreenState();
}

class _VehicleEditScreenState extends State<VehicleEditScreen> {
  late final _brand = TextEditingController(text: widget.state.vehicle.brand);
  late final _model = TextEditingController(text: widget.state.vehicle.model);
  late final _plate = TextEditingController(text: widget.state.vehicle.plate);
  late final _type = TextEditingController(text: widget.state.vehicle.type);
  late final _year = TextEditingController(
    text: '${widget.state.vehicle.year}',
  );
  late final _mileage = TextEditingController(
    text: '${widget.state.vehicle.mileage}',
  );
  bool saving = false;

  @override
  void dispose() {
    _brand.dispose();
    _model.dispose();
    _plate.dispose();
    _type.dispose();
    _year.dispose();
    _mileage.dispose();
    super.dispose();
  }

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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Periksa kembali data kendaraan.')),
      );
      return;
    }
    if (mileage < widget.state.vehicle.mileage) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Kilometer baru tidak boleh lebih rendah.'),
        ),
      );
      return;
    }
    setState(() => saving = true);
    await widget.state.updateVehicle(
      Vehicle(
        brand: _brand.text.trim(),
        model: _model.text.trim(),
        plate: _plate.text.trim().toUpperCase(),
        type: _type.text.trim(),
        year: year,
        mileage: mileage,
      ),
    );
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) => Page(
    title: 'Ubah Kendaraan',
    bottomBar: SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        child: FilledButton(
          onPressed: saving ? null : _save,
          style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
          child: Text(saving ? 'Menyimpan...' : 'Simpan Perubahan'),
        ),
      ),
    ),
    child: ScrollPage(
      child: Column(
        children: [
          TextField(
            controller: _brand,
            decoration: const InputDecoration(labelText: 'Merek'),
          ),
          TextField(
            controller: _model,
            decoration: const InputDecoration(labelText: 'Model'),
          ),
          TextField(
            controller: _plate,
            textCapitalization: TextCapitalization.characters,
            decoration: const InputDecoration(labelText: 'Nomor polisi'),
          ),
          TextField(
            controller: _type,
            decoration: const InputDecoration(labelText: 'Tipe / varian'),
          ),
          TextField(
            controller: _year,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Tahun'),
          ),
          TextField(
            controller: _mileage,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Kilometer terakhir'),
          ),
          const SizedBox(height: 12),
          const Text(
            'Nomor rangka dan mesin tidak diminta; foto kendaraan belum dapat diubah pada prototipe ini.',
            style: TextStyle(color: AppColors.muted, fontSize: 12),
          ),
        ],
      ),
    ),
  );
}

class VehicleDetailScreen extends StatelessWidget {
  final OtoKuState state;
  const VehicleDetailScreen({super.key, required this.state});
  @override
  Widget build(BuildContext context) => Page(
    title: 'Detail Kendaraan',
    actions: [
      IconButton(
        tooltip: 'Ubah kendaraan',
        onPressed: () => push(context, VehicleEditScreen(state: state)),
        icon: const Icon(Icons.edit_outlined),
      ),
    ],
    child: ScrollPage(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CardBox(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Stack(
                  children: [
                    Container(
                      height: 190,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: AppColors.surfaceLow,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child:
                          state.vehicle.brand == 'Honda' &&
                              state.vehicle.model.toLowerCase().contains('beat')
                          ? const VehiclePhoto(height: 190, detail: true)
                          : const VehicleIllustration(height: 190),
                    ),
                    Positioned(
                      top: 10,
                      right: 10,
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: .90),
                          shape: BoxShape.circle,
                          boxShadow: _cardShadow,
                        ),
                        child: const Icon(
                          Icons.zoom_in,
                          size: 18,
                          color: AppColors.ink,
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 10,
                      left: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: .95),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: Color(0xFF22C55E),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            const Text(
                              'KENDARAAN UTAMA',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                letterSpacing: .7,
                                color: AppColors.ink,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            state.vehicle.name,
                            style: const TextStyle(
                              fontFamily: 'Space Grotesk',
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -.4,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${state.vehicle.type} · Data kendaraan lokal',
                            style: const TextStyle(
                              color: AppColors.muted,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.ink,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        state.vehicle.plate,
                        style: const TextStyle(
                          color: Colors.white,
                          fontFamily: 'Space Grotesk',
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                          letterSpacing: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    _VehiclePill(
                      label: 'JARAK TEMPUH',
                      value: formatKilometers(state.vehicle.mileage),
                      unit: 'Kilometer',
                    ),
                    const SizedBox(width: 6),
                    _VehiclePill(
                      label: 'TAHUN',
                      value: '${state.vehicle.year}',
                      unit: 'Registrasi',
                    ),
                    const SizedBox(width: 6),
                    _VehiclePill(
                      label: 'VARIAN',
                      value: state.vehicle.type,
                      unit: 'Pabrikan',
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          CardBox(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'SPESIFIKASI UNIT',
                        style: TextStyle(
                          color: AppColors.muted,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                    Icon(Icons.two_wheeler, size: 19, color: AppColors.muted),
                  ],
                ),
                const SizedBox(height: 4),
                ...[
                  ['Merek', state.vehicle.brand],
                  ['Model', state.vehicle.model],
                  ['Tahun Pembuatan', '${state.vehicle.year}'],
                  ['Tipe Varian', state.vehicle.type],
                  ['Nomor Registrasi (Plat)', state.vehicle.plate],
                ].map(
                  (row) => Container(
                    padding: const EdgeInsets.symmetric(vertical: 11),
                    decoration: const BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: AppColors.surfaceHigh),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            row[0],
                            style: const TextStyle(
                              color: AppColors.muted,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        Text(
                          row[1],
                          style: TextStyle(
                            fontFamily: 'Space Grotesk',
                            fontSize: 13,
                            fontWeight: row[0].startsWith('Nomor')
                                ? FontWeight.w700
                                : FontWeight.w600,
                            letterSpacing: row[0].startsWith('Nomor') ? 1 : 0,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceLow,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.verified_user_outlined,
                        color: AppColors.red,
                        size: 19,
                      ),
                      const SizedBox(width: 9),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text(
                              'Data tersimpan lokal',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Spesifikasi dari katalog demo. OBD belum tersinkronisasi ke akun.',
                              style: TextStyle(
                                color: AppColors.muted,
                                fontSize: 11,
                                height: 1.35,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Aktivitas & Fitur Kendaraan',
                  style: TextStyle(
                    fontFamily: 'Space Grotesk',
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -.2,
                  ),
                ),
              ),
              Text(
                '4 MENU',
                style: TextStyle(
                  color: AppColors.muted,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _VehicleMenuTile(
            icon: Icons.trending_up,
            iconBg: AppColors.redTint,
            iconColor: AppColors.red,
            title: 'Riwayat & Tracking',
            subtitle: 'Log servis, biaya bensin & catatan',
            onTap: () => push(context, HistoryScreen(state: state)),
          ),
          const SizedBox(height: 8),
          _VehicleMenuTile(
            icon: Icons.calendar_month,
            iconBg: const Color(0xFFFFEDD5),
            iconColor: const Color(0xFFC2410C),
            title: 'Jadwal Perawatan',
            subtitle: 'Ganti oli & cek komponen berkala',
            badge: 'Jatuh Tempo',
            onTap: () => push(context, MaintenanceScreen(state: state)),
          ),
          const SizedBox(height: 8),
          _VehicleMenuTile(
            icon: Icons.sensors,
            iconBg: const Color(0xFFD1FAE5),
            iconColor: const Color(0xFF047857),
            title: 'Data OBD & Telemetri',
            subtitle: state.obdConnected
                ? 'Simulasi OBD aktif · data demo'
                : 'Belum terhubung · coba simulasi',
            showDot: state.obdConnected,
            onTap: () => state.obdConnected
                ? push(context, ObdScreen(state: state))
                : showObdSheet(context, state),
          ),
          const SizedBox(height: 8),
          _VehicleMenuTile(
            icon: Icons.edit_note,
            iconBg: AppColors.surfaceHigh,
            iconColor: AppColors.ink,
            title: 'Ubah Data Kendaraan',
            subtitle: 'Koreksi odometer, plat, atau nama',
            onTap: () => push(context, VehicleEditScreen(state: state)),
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: () => openTab(context, 2),
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
            ),
            icon: const Icon(Icons.build_circle_outlined, size: 19),
            label: const Text('Jadwalkan Servis'),
          ),
        ],
      ),
    ),
  );
}

class _VehiclePill extends StatelessWidget {
  final String label, value, unit;
  const _VehiclePill({
    required this.label,
    required this.value,
    required this.unit,
  });
  @override
  Widget build(BuildContext context) => Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
      decoration: BoxDecoration(
        color: AppColors.surfaceLow,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppColors.muted,
              fontSize: 9,
              fontWeight: FontWeight.w600,
              letterSpacing: .6,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontFamily: 'Space Grotesk',
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            unit,
            style: const TextStyle(color: AppColors.muted, fontSize: 9),
          ),
        ],
      ),
    ),
  );
}

class _VehicleMenuTile extends StatelessWidget {
  final IconData icon;
  final Color iconBg, iconColor;
  final String title, subtitle;
  final String? badge;
  final bool showDot;
  final VoidCallback onTap;
  const _VehicleMenuTile({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.badge,
    this.showDot = false,
  });
  @override
  Widget build(BuildContext context) => Material(
    color: Colors.white,
    borderRadius: BorderRadius.circular(12),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
          boxShadow: _cardShadow,
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: iconColor, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      if (showDot) ...[
                        const SizedBox(width: 6),
                        Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            color: Color(0xFF10B981),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ],
                      if (badge != null) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 1,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.redTint,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            badge!,
                            style: const TextStyle(
                              color: AppColors.red,
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.muted, size: 20),
          ],
        ),
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
                  AppColors.surfaceLow,
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

class MaintenanceScreen extends StatefulWidget {
  final OtoKuState state;
  const MaintenanceScreen({super.key, required this.state});
  @override
  State<MaintenanceScreen> createState() => _MaintenanceScreenState();
}

class _MaintenanceScreenState extends State<MaintenanceScreen> {
  String filter = 'Rekomendasi';
  static const tasks = <({String title, int target, IconData icon})>[
    (title: 'Ganti Oli Mesin', target: 14000, icon: Icons.oil_barrel_outlined),
    (title: 'Cek Kampas Rem', target: 15000, icon: Icons.disc_full),
    (title: 'Cek Filter Udara', target: 15000, icon: Icons.filter_alt_outlined),
    (title: 'Cek Busi', target: 17500, icon: Icons.electrical_services),
    (
      title: 'Ganti Oli Gear (CVT)',
      target: 17500,
      icon: Icons.settings_outlined,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final current = widget.state.vehicle.mileage;
    final visible = tasks.where((task) {
      final done = widget.state.completedMaintenance.contains(task.title);
      return filter == 'Semua' || (filter == 'Selesai' ? done : !done);
    }).toList();
    return Page(
      title: 'Jadwal Perawatan',
      child: ScrollPage(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 8,
              children: ['Rekomendasi', 'Semua', 'Selesai']
                  .map(
                    (value) => ChoiceChip(
                      label: Text(value),
                      selected: filter == value,
                      onSelected: (_) => setState(() => filter = value),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 8),
            const Text(
              'Jarak target adalah estimasi demo, bukan jadwal pabrikan.',
              style: TextStyle(color: AppColors.muted, fontSize: 12),
            ),
            const SizedBox(height: 12),
            if (visible.isEmpty)
              const CardBox(
                child: Text('Belum ada perawatan pada filter ini.'),
              ),
            ...visible.map((task) {
              final done = widget.state.completedMaintenance.contains(
                task.title,
              );
              final remaining = task.target - current;
              final progress = (current / task.target)
                  .clamp(0.0, 1.0)
                  .toDouble();
              return CardBox(
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: AppColors.bg,
                      child: Icon(task.icon, color: AppColors.red),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            task.title,
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                          Text(
                            done
                                ? 'Ditandai selesai oleh kamu'
                                : remaining >= 0
                                ? 'Estimasi: ${formatKilometers(remaining)} km lagi'
                                : 'Estimasi terlewat ${formatKilometers(-remaining)} km',
                            style: const TextStyle(
                              color: AppColors.muted,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 8),
                          LinearProgressIndicator(
                            value: progress,
                            minHeight: 6,
                            borderRadius: BorderRadius.circular(8),
                            color: done ? AppColors.green : AppColors.red,
                            backgroundColor: AppColors.border,
                          ),
                          const SizedBox(height: 5),
                          Text(
                            '${formatKilometers(current)} / ${formatKilometers(task.target)} km · demo',
                            style: const TextStyle(
                              color: AppColors.muted,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: done ? 'Selesai' : 'Tandai selesai',
                      onPressed: done
                          ? null
                          : () => widget.state.completeMaintenance(task.title),
                      icon: Icon(
                        done ? Icons.check_circle : Icons.check_circle_outline,
                        color: done ? AppColors.green : AppColors.muted,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

class ManualLogScreen extends StatefulWidget {
  final OtoKuState state;
  const ManualLogScreen({super.key, required this.state});
  @override
  State<ManualLogScreen> createState() => _ManualLogScreenState();
}

class _ManualLogScreenState extends State<ManualLogScreen> {
  final _title = TextEditingController();
  final _value = TextEditingController();
  final _mileage = TextEditingController();
  final _volume = TextEditingController();
  final _notes = TextEditingController();
  String type = 'Kilometer';
  bool saving = false;

  @override
  void dispose() {
    _title.dispose();
    _value.dispose();
    _mileage.dispose();
    _volume.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (saving) return;
    final title = _title.text.trim();
    final value = int.tryParse(_value.text.trim());
    final mileage = int.tryParse(_mileage.text.trim());
    final volume = double.tryParse(_volume.text.trim().replaceAll(',', '.'));
    if (type == 'BBM' &&
        _volume.text.trim().isNotEmpty &&
        (volume == null || volume < 0)) {
      _showError('Masukkan volume BBM yang valid.');
      return;
    }
    if (type != 'Kilometer' &&
        _value.text.trim().isNotEmpty &&
        (value == null || value < 0)) {
      _showError('Masukkan angka biaya yang valid.');
      return;
    }
    if (_mileage.text.trim().isNotEmpty && (mileage == null || mileage < 0)) {
      _showError('Masukkan angka kilometer yang valid.');
      return;
    }
    if (type != 'Kilometer' &&
        mileage != null &&
        mileage < widget.state.vehicle.mileage) {
      _showError(
        'Kilometer aktivitas lebih rendah dari catatan kendaraan. Periksa kembali.',
      );
      return;
    }
    if (type == 'Kilometer') {
      if (value == null || value < 0) {
        _showError('Masukkan angka kilometer yang valid.');
        return;
      }
      if (value < widget.state.vehicle.mileage) {
        _showError(
          'Kilometer baru tidak boleh lebih rendah dari catatan sebelumnya.',
        );
        return;
      }
    } else if (title.isEmpty) {
      _showError('Isi nama aktivitas terlebih dahulu.');
      return;
    }

    setState(() => saving = true);
    try {
      if (type == 'Kilometer') {
        await widget.state.updateMileage(value!);
      } else {
        await widget.state.addLog({
          'type': type.toLowerCase(),
          'title': title,
          'amount': value,
          'volume': type == 'BBM' ? volume : null,
          'mileage': mileage,
          'notes': _notes.text.trim(),
          'date': DateTime.now().toIso8601String(),
          'source': 'manual',
        });
      }
      if (mounted) Navigator.pop(context);
    } catch (_) {
      if (mounted) _showError('Catatan belum dapat disimpan. Coba lagi.');
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  void _showError(String message) => ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));

  @override
  Widget build(BuildContext context) => Page(
    title: 'Catat Aktivitas',
    bottomBar: SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        child: FilledButton(
          onPressed: saving ? null : _save,
          style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
          child: Text(saving ? 'Menyimpan...' : 'Simpan Catatan'),
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
            items: const ['Kilometer', 'BBM', 'Servis', 'Biaya', 'Sparepart']
                .map(
                  (value) => DropdownMenuItem(value: value, child: Text(value)),
                )
                .toList(),
            onChanged: (value) => setState(() => type = value ?? 'Kilometer'),
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
  final OtoKuState state;
  const HistoryScreen({super.key, required this.state});
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
  );
}

class ServiceTimeline extends StatelessWidget {
  final OtoKuState state;
  const ServiceTimeline({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    if (state.logs.isEmpty) {
      return const CardBox(
        child: Text(
          'Belum ada riwayat. Catatan yang kamu buat akan tersimpan di sini.',
        ),
      );
    }
    return Column(
      children: state.logs.map((log) {
        final type = (log['type'] ?? 'catatan').toString();
        final amount = log['amount'];
        final mileage = log['mileage'] ?? log['value'];
        final notes = (log['notes'] ?? '').toString();
        final date = DateTime.tryParse((log['date'] ?? '').toString());
        final dateLabel = date == null
            ? 'Tanggal tidak tersedia'
            : '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
        final volume = log['volume'];
        final details = <String>[
          if (volume is num) '${volume.toStringAsFixed(1)} L',
          if (mileage is num) '${formatKilometers(mileage.toInt())} km',
          if (amount is num && amount > 0)
            'Rp ${formatKilometers(amount.toInt())}',
          if (notes.isNotEmpty) notes,
          if (log['source'] == 'manual') 'Dicatat manual',
        ];
        final icon = switch (type) {
          'bbm' => Icons.local_gas_station_outlined,
          'servis' => Icons.build_outlined,
          'biaya' => Icons.payments_outlined,
          'sparepart' => Icons.tire_repair_outlined,
          _ => Icons.speed_outlined,
        };
        return CardBox(
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
                      dateLabel,
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
            ],
          ),
        );
      }).toList(),
    );
  }
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
                    color: today ? AppColors.redTint : AppColors.surfaceHigh,
                    width: 3,
                  ),
                ),
              ),
              Container(
                width: 1.5,
                height: items.length > 1 ? 142 : 92,
                color: AppColors.surfaceHigh,
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
          color: AppColors.surfaceLow,
          borderRadius: BorderRadius.circular(9),
        ),
        child: Icon(icon, color: AppColors.muted, size: 18),
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
  final List<num> values;
  const ChartPanel({super.key, required this.title, required this.values});
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
            painter: ChartPainter(values: values),
            child: const SizedBox.expand(),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          '${values.length} catatan lokal · data demo',
          style: const TextStyle(color: AppColors.muted, fontSize: 11),
        ),
      ],
    ),
  );
}

class ChartPainter extends CustomPainter {
  final List<num> values;
  ChartPainter({required this.values});
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
    final minValue = values.reduce(math.min).toDouble();
    final maxValue = values.reduce(math.max).toDouble();
    final points = values
        .map(
          (value) => maxValue == minValue
              ? .5
              : .88 -
                    ((value.toDouble() - minValue) / (maxValue - minValue)) *
                        .76,
        )
        .toList();
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
  bool shouldRepaint(covariant ChartPainter oldDelegate) =>
      oldDelegate.values.toString() != values.toString();
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
                      'OBD Demo Aktif',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                    Text(
                      'Data simulasi lokal · bukan live',
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
          const SectionTitle('Kode Masalah (Contoh Demo)'),
          CardBox(
            onTap: () => showRecommendation(c),
            child: const ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.error_outline, color: AppColors.red),
              title: Text(
                'P0301',
                style: TextStyle(fontWeight: FontWeight.w900),
              ),
              subtitle: Text(
                'Contoh P0301 · perlu diagnosis bengkel; tidak memastikan komponen rusak.',
              ),
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
      backgroundColor: ok ? AppColors.greenTint : AppColors.redTint,
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
    final list = widget.state.products
        .where(
          (p) =>
              (cat == 'Semua' ||
                  p.category == cat ||
                  (cat == 'Sparepart' && p.category != 'Aksesori')) &&
              (query.isEmpty ||
                  '${p.name} ${p.category}'.toLowerCase().contains(
                    query.toLowerCase().trim(),
                  )),
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
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(
                              text: 'OtoKu',
                              style: TextStyle(
                                color: AppColors.red,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            TextSpan(
                              text: '  ·  Shop',
                              style: TextStyle(
                                color: AppColors.ink,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                        style: TextStyle(fontSize: 21, letterSpacing: -.4),
                      ),
                      const SizedBox(height: 1),
                      Row(
                        children: [
                          const Icon(
                            Icons.location_on,
                            size: 13,
                            color: AppColors.red,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            widget.state.vehicle.name,
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.muted,
                            ),
                          ),
                        ],
                      ),
                    ],
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
                    prefixIcon: const Icon(
                      Icons.search,
                      color: AppColors.muted,
                    ),
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
                    children:
                        [
                              'Semua',
                              'Sparepart',
                              'Oli & Cairan',
                              'Rem',
                              'Filter',
                              'Aki',
                              'Aksesori',
                            ]
                            .map(
                              (value) => Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: ChoiceChip(
                                  label: Text(value),
                                  selected: cat == value,
                                  showCheckmark: false,
                                  onSelected: (_) =>
                                      setState(() => cat = value),
                                  backgroundColor: AppColors.surfaceLow,
                                  selectedColor: AppColors.red,
                                  labelStyle: TextStyle(
                                    color: cat == value
                                        ? Colors.white
                                        : AppColors.muted,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 12,
                                  ),
                                  side: BorderSide.none,
                                  shape: const StadiumBorder(),
                                ),
                              ),
                            )
                            .toList(),
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: const LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [Color(0xFF18181B), Color(0xFF27272A)],
                    ),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x1418181B),
                        blurRadius: 24,
                        offset: Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Stack(
                    children: [
                      Positioned(
                        right: -24,
                        bottom: -24,
                        child: Container(
                          width: 144,
                          height: 144,
                          decoration: BoxDecoration(
                            color: AppColors.red.withValues(alpha: .25),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.red,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: const Text(
                                    'UNGGULAN',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 9,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: .6,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: .10),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: const Row(
                                    children: [
                                      Icon(
                                        Icons.bluetooth,
                                        size: 12,
                                        color: Color(0xFF34D399),
                                      ),
                                      SizedBox(width: 4),
                                      Text(
                                        'Plug & Play BLE',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 9,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Pantau Mesin Real-Time dengan OtoKu OBD-II',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700,
                                          height: 1.25,
                                        ),
                                      ),
                                      SizedBox(height: 4),
                                      Text(
                                        'Contoh data diagnostik di smartphone. Mode demo — belum membaca kendaraan.',
                                        style: TextStyle(
                                          color: Color(0xFFD4D4D8),
                                          fontSize: 11,
                                          height: 1.4,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Container(
                                  width: 56,
                                  height: 56,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: .10),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: Colors.white.withValues(
                                        alpha: .10,
                                      ),
                                    ),
                                  ),
                                  child: const Icon(
                                    Icons.memory,
                                    color: Colors.white,
                                    size: 28,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.only(top: 8),
                              decoration: const BoxDecoration(
                                border: Border(
                                  top: BorderSide(color: Color(0x1AFFFFFF)),
                                ),
                              ),
                              child: Row(
                                children: [
                                  const Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Contoh harga · demo',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 15,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                        Text(
                                          'Belum ada pembelian nyata',
                                          style: TextStyle(
                                            color: Color(0xFF34D399),
                                            fontSize: 10,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  FilledButton.icon(
                                    onPressed: () =>
                                        showObdSheet(c, widget.state),
                                    style: FilledButton.styleFrom(
                                      backgroundColor: AppColors.red,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 14,
                                        vertical: 9,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    icon: const Text(
                                      'Lihat Demo',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    label: const Icon(
                                      Icons.shopping_bag_outlined,
                                      size: 15,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                SectionTitle(
                  'Produk (${list.length})',
                  action: query.isNotEmpty || cat != 'Semua'
                      ? 'Hapus filter'
                      : null,
                  onTap: () => setState(() {
                    query = '';
                    cat = 'Semua';
                  }),
                ),
                const Text(
                  'Kecocokan ditampilkan jika sudah dikonfirmasi untuk kendaraan aktif.',
                  style: TextStyle(color: AppColors.muted, fontSize: 13),
                ),
                const SizedBox(height: 10),
                if (list.isEmpty)
                  CardBox(
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
                  )
                else
                  ...list.map(
                    (p) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: ProductCard(
                        p: p,
                        vehicleName: widget.state.vehicle.name,
                        onAdd: () {
                          widget.state.add(p);
                          ScaffoldMessenger.of(c).showSnackBar(
                            SnackBar(
                              content: Text(
                                '${p.name} ditambahkan ke keranjang',
                              ),
                            ),
                          );
                        },
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
  final String vehicleName;
  final VoidCallback onTap;
  final VoidCallback onAdd;
  const ProductCard({
    super.key,
    required this.p,
    required this.vehicleName,
    required this.onTap,
    required this.onAdd,
  });
  @override
  Widget build(BuildContext c) => CardBox(
    onTap: onTap,
    padding: const EdgeInsets.all(10),
    child: Row(
      children: [
        ProductArt(icon: p.icon, image: p.imageAsset, size: 80),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(p.name, style: const TextStyle(fontWeight: FontWeight.w800)),
              Text(
                switch (p.fitment) {
                  ProductFitment.confirmed => 'Cocok untuk $vehicleName',
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
              const SizedBox(height: 5),
              Text(
                p.price,
                style: const TextStyle(
                  color: AppColors.red,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const Text(
                'Stok belum dikonfirmasi · demo',
                style: TextStyle(color: AppColors.muted, fontSize: 10),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        IconButton.filled(
          tooltip: 'Tambah ${p.name} ke keranjang',
          onPressed: onAdd,
          style: IconButton.styleFrom(
            backgroundColor: AppColors.red,
            foregroundColor: Colors.white,
            minimumSize: const Size(40, 40),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(11),
            ),
          ),
          icon: const Icon(Icons.add_shopping_cart, size: 18),
        ),
      ],
    ),
  );
}

class ProductArt extends StatelessWidget {
  final String icon;
  final String? image;
  final double size;
  const ProductArt({super.key, required this.icon, this.image, this.size = 68});
  @override
  Widget build(BuildContext c) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      color: AppColors.surfaceLow,
      borderRadius: BorderRadius.circular(14),
    ),
    child: image == null || image!.isEmpty
        ? CustomPaint(painter: PartPainter(icon))
        : Padding(
            padding: const EdgeInsets.all(5),
            child: Image.asset(
              image!,
              fit: BoxFit.contain,
              semanticLabel: 'Foto produk ilustrasi',
              errorBuilder: (_, _, _) =>
                  CustomPaint(painter: PartPainter(icon)),
            ),
          ),
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
                            color: AppColors.surfaceLow,
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

class WorkshopListScreen extends StatefulWidget {
  final OtoKuState state;
  const WorkshopListScreen({super.key, required this.state});
  @override
  State<WorkshopListScreen> createState() => _WorkshopListScreenState();
}

class _WorkshopListScreenState extends State<WorkshopListScreen> {
  String category = 'Semua';
  String query = '';

  List<Workshop> get filtered => widget.state.workshops.where((place) {
    final matchesCategory = switch (category) {
      'Semua' => true,
      'Bengkel partner' => place.category == 'Bengkel' && place.partner,
      'Bengkel non-partner' => place.category == 'Bengkel' && !place.partner,
      _ => place.category == category,
    };
    final search =
        '${place.name} ${place.category} ${place.address} ${place.services}'
            .toLowerCase();
    return matchesCategory && search.contains(query.toLowerCase().trim());
  }).toList();

  @override
  Widget build(BuildContext c) => Material(
    color: AppColors.bg,
    child: SafeArea(
      child: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
            sliver: SliverToBoxAdapter(
              child: Row(
                children: [
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Peta & Tempat',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -.3,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Bekasi Utara · lokasi demo',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.muted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const CircleAvatar(
                    radius: 18,
                    backgroundColor: AppColors.red,
                    child: Text(
                      'OK',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            sliver: SliverToBoxAdapter(
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  const DemoMapPreview(),
                  Positioned(
                    left: 12,
                    right: 12,
                    top: 12,
                    child: Material(
                      elevation: 3,
                      shadowColor: AppColors.ink.withValues(alpha: .12),
                      borderRadius: BorderRadius.circular(14),
                      child: TextField(
                        onChanged: (value) => setState(() => query = value),
                        decoration: InputDecoration(
                          hintText: 'Cari bengkel, SPBU, minimarket...',
                          prefixIcon: const Icon(
                            Icons.search,
                            color: AppColors.muted,
                          ),
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 10,
                          ),
                          border: OutlineInputBorder(
                            borderSide: BorderSide.none,
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: SizedBox(
              height: 56,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
                scrollDirection: Axis.horizontal,
                children:
                    [
                          'Semua',
                          'Bengkel partner',
                          'Bengkel non-partner',
                          'Minimarket',
                          'SPBU',
                        ]
                        .map(
                          (value) => Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ChoiceChip(
                              label: Text(value),
                              selected: category == value,
                              showCheckmark: false,
                              onSelected: (_) =>
                                  setState(() => category = value),
                              backgroundColor: Colors.white,
                              selectedColor: AppColors.redTint,
                              labelStyle: TextStyle(
                                color: category == value
                                    ? AppColors.red
                                    : AppColors.muted,
                                fontWeight: FontWeight.w600,
                                fontSize: 11,
                              ),
                              side: BorderSide(
                                color: category == value
                                    ? AppColors.red.withValues(alpha: .25)
                                    : AppColors.border,
                              ),
                              shape: const StadiumBorder(),
                            ),
                          ),
                        )
                        .toList(),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 24),
            sliver: SliverList.list(
              children: [
                Row(
                  children: [
                    Text(
                      '${filtered.length} tempat',
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                      ),
                    ),
                    const Spacer(),
                    const Text(
                      'Area Bekasi & Sekitarnya',
                      style: TextStyle(fontSize: 11, color: AppColors.muted),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                if (filtered.isEmpty)
                  const CardBox(
                    child: Text('Tempat tidak ditemukan. Coba filter lain.'),
                  ),
                ...filtered.map(
                  (place) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: WorkshopCard(
                      w: place,
                      onTap: () => push(
                        c,
                        WorkshopDetailScreen(
                          state: widget.state,
                          workshop: place,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

class DemoMapPreview extends StatelessWidget {
  const DemoMapPreview({super.key});
  @override
  Widget build(BuildContext context) => Container(
    height: 230,
    clipBehavior: Clip.antiAlias,
    decoration: BoxDecoration(
      color: const Color(0xFFE7EEE4),
      borderRadius: BorderRadius.circular(22),
      border: Border.all(color: AppColors.border),
      boxShadow: const [
        BoxShadow(
          color: Color(0x10151C27),
          blurRadius: 12,
          offset: Offset(0, 4),
        ),
      ],
    ),
    child: Stack(
      children: [
        const Positioned.fill(child: CustomPaint(painter: DemoRoadPainter())),
        const Positioned(
          left: 40,
          top: 72,
          child: Icon(Icons.location_on, color: AppColors.red, size: 32),
        ),
        const Positioned(
          right: 54,
          top: 88,
          child: Icon(Icons.location_on, color: AppColors.ink, size: 28),
        ),
        const Positioned(
          left: 174,
          top: 100,
          child: Icon(Icons.location_on, color: AppColors.ink, size: 26),
        ),
        Positioned(
          right: 12,
          bottom: 38,
          child: Material(
            color: Colors.white,
            elevation: 2,
            shape: const CircleBorder(),
            child: IconButton(
              tooltip: 'Pusatkan peta',
              onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Lokasi saat ini tidak tersedia di mode demo'),
                ),
              ),
              icon: const Icon(
                Icons.my_location,
                color: AppColors.ink,
                size: 19,
              ),
            ),
          ),
        ),
        Positioned(
          left: 10,
          bottom: 10,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: .94),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              'Peta ilustrasi · lokasi demo',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: AppColors.muted,
              ),
            ),
          ),
        ),
      ],
    ),
  );
}

class DemoRoadPainter extends CustomPainter {
  const DemoRoadPainter();
  @override
  void paint(Canvas canvas, Size size) {
    final road = Paint()
      ..color = const Color(0xFFF8F5E9)
      ..strokeWidth = 14
      ..strokeCap = StrokeCap.round;
    final thinRoad = Paint()
      ..color = const Color(0xFFD5DCCB)
      ..strokeWidth = 3;
    canvas.drawLine(
      Offset(-12, size.height * .72),
      Offset(size.width * .95, size.height * .18),
      road,
    );
    canvas.drawLine(
      Offset(size.width * .25, -12),
      Offset(size.width * .52, size.height + 12),
      road,
    );
    canvas.drawLine(
      Offset(size.width * .78, -12),
      Offset(size.width * .68, size.height + 12),
      thinRoad,
    );
    canvas.drawLine(
      Offset(-12, size.height * .3),
      Offset(size.width + 12, size.height * .83),
      thinRoad,
    );
  }

  @override
  bool shouldRepaint(covariant DemoRoadPainter oldDelegate) => false;
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
                '${w.category} · ${w.distance}',
                style: const TextStyle(
                  color: AppColors.muted,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                w.partner
                    ? 'Partner OtoKu · demo'
                    : 'Lokasi demo · belum diverifikasi',
                style: TextStyle(
                  color: w.partner ? AppColors.green : AppColors.muted,
                  fontSize: 12,
                ),
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

class _PlaceAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _PlaceAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => Expanded(
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Column(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: const [
                  BoxShadow(color: Color(0x10151C27), blurRadius: 5),
                ],
              ),
              child: Icon(icon, color: AppColors.red, size: 20),
            ),
            const SizedBox(height: 5),
            Text(
              label,
              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
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
    title: 'Detail Tempat',
    bottomBar: workshop.bookingEnabled
        ? SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: FilledButton(
                onPressed: () =>
                    push(c, BookingScreen(state: state, workshop: workshop)),
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                ),
                child: const Text('Booking partner demo'),
              ),
            ),
          )
        : null,
    child: ScrollPage(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 230,
            width: double.infinity,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppColors.navy, Color(0xFF394558)],
              ),
            ),
            child: Stack(
              children: [
                Positioned(
                  right: -35,
                  top: -55,
                  child: Container(
                    width: 220,
                    height: 220,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withValues(alpha: .08),
                        width: 24,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  right: 35,
                  bottom: -90,
                  child: Container(
                    width: 220,
                    height: 220,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withValues(alpha: .06),
                        width: 18,
                      ),
                    ),
                  ),
                ),
                Center(
                  child: Icon(
                    workshop.category == 'Bengkel'
                        ? Icons.storefront_outlined
                        : workshop.category == 'SPBU'
                        ? Icons.local_gas_station
                        : Icons.storefront,
                    color: Colors.white.withValues(alpha: .9),
                    size: 86,
                  ),
                ),
                Positioned(
                  left: 14,
                  top: 14,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: .12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      workshop.partner ? 'MITRA OtoKu · DEMO' : 'TEMPAT · DEMO',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: .4,
                      ),
                    ),
                  ),
                ),
                const Positioned(
                  left: 12,
                  bottom: 10,
                  child: Text(
                    'Foto tempat belum tersedia',
                    style: TextStyle(color: Colors.white70, fontSize: 10),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Text(
            workshop.name,
            style: const TextStyle(
              fontSize: 23,
              fontWeight: FontWeight.w800,
              letterSpacing: -.5,
            ),
          ),
          const SizedBox(height: 5),
          Row(
            children: [
              Text(
                '${workshop.category} · ${workshop.distance}',
                style: const TextStyle(color: AppColors.muted, fontSize: 12),
              ),
              const Spacer(),
              StatusChip(
                workshop.partner ? 'Partner demo' : 'Belum diverifikasi',
                workshop.partner ? AppColors.green : AppColors.muted,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            workshop.partner
                ? 'Status mitra contoh; lokasi dan layanan belum diverifikasi.'
                : 'Tempat non-partner; tidak didukung atau diverifikasi OtoKu.',
            style: const TextStyle(
              color: AppColors.muted,
              fontSize: 12,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 5),
          Row(
            children: [
              const Icon(
                Icons.location_on_outlined,
                size: 16,
                color: AppColors.red,
              ),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  workshop.address,
                  style: const TextStyle(color: AppColors.muted, fontSize: 12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.surfaceLow,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              children: [
                _PlaceAction(
                  icon: Icons.directions_outlined,
                  label: 'Rute',
                  onTap: () => showPrototypeNotice(
                    c,
                    'Rute',
                    'Navigasi peta belum tersedia pada demo.',
                  ),
                ),
                _PlaceAction(
                  icon: Icons.call_outlined,
                  label: 'Hubungi',
                  onTap: () => showPrototypeNotice(
                    c,
                    'Hubungi',
                    'Nomor kontak tempat belum tersedia.',
                  ),
                ),
                _PlaceAction(
                  icon: Icons.bookmark_border,
                  label: 'Simpan',
                  onTap: () => ScaffoldMessenger.of(c).showSnackBar(
                    const SnackBar(content: Text('Tempat disimpan dalam demo')),
                  ),
                ),
                _PlaceAction(
                  icon: Icons.share_outlined,
                  label: 'Bagikan',
                  onTap: () => showPrototypeNotice(
                    c,
                    'Bagikan',
                    'Tautan tempat demo belum tersedia.',
                  ),
                ),
              ],
            ),
          ),
          if (workshop.category == 'Bengkel') ...[
            const SectionTitle('Layanan populer'),
            CardBox(
              color: AppColors.surfaceLow,
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: AppColors.muted),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Text(
                      workshop.partner
                          ? 'Layanan dan tarif mitra belum dikonfirmasi.'
                          : 'Bengkel non-partner tidak menyediakan booking di aplikasi.',
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 12,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
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
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: selected ? AppColors.redTint.withValues(alpha: .45) : Colors.white,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(
        color: selected ? AppColors.red : AppColors.border,
        width: selected ? 1.5 : 1,
      ),
      boxShadow: _cardShadow,
    ),
    child: Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              ProductArt(icon: 'oil', size: 52),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    Text(
                      '$price · $duration',
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 11,
                      ),
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
        ),
      ),
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
  bool oilSelected = true, cvtSelected = false, submitting = false;

  DateTime get selectedDate => DateTime.now().add(Duration(days: day + 1));

  @override
  void dispose() {
    _notes.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (submitting) return;
    final services = <String>[
      if (oilSelected) 'Ganti Oli Mesin',
      if (cvtSelected) 'Servis CVT',
    ];
    if (services.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih minimal satu layanan.')),
      );
      return;
    }
    setState(() => submitting = true);
    try {
      final booking = await widget.state.addBooking(
        widget.workshop.name,
        services: services,
        date: selectedDate,
        time: times[time],
        notes: _notes.text,
      );
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) =>
              BookingConfirmationScreen(state: widget.state, booking: booking),
        ),
      );
    } finally {
      if (mounted) setState(() => submitting = false);
    }
  }

  @override
  Widget build(BuildContext c) => Page(
    title: 'Booking Layanan',
    bottomBar: SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        child: FilledButton(
          onPressed: submitting ? null : _submit,
          style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
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
                  widget.workshop.name,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                Text(
                  widget.workshop.address,
                  style: const TextStyle(color: AppColors.muted),
                ),
                const SizedBox(height: 8),
                Text(
                  'Kendaraan: ${widget.state.vehicle.name} · ${widget.state.vehicle.plate}',
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
          ),
          const SectionTitle('Pilih Layanan'),
          BookingServiceTile(
            key: const ValueKey('booking-oil'),
            title: 'Ganti Oli Mesin',
            price: 'Estimasi demo Rp 50.000',
            duration: '30 menit (demo)',
            selected: oilSelected,
            onTap: () => setState(() => oilSelected = !oilSelected),
          ),
          BookingServiceTile(
            title: 'Servis CVT',
            price: 'Estimasi demo Rp 80.000',
            duration: '45 menit (demo)',
            selected: cvtSelected,
            onTap: () => setState(() => cvtSelected = !cvtSelected),
          ),
          const SectionTitle('Pilih Tanggal · jadwal demo'),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: List.generate(5, (i) {
              final date = DateTime.now().add(Duration(days: i + 1));
              final selected = day == i;
              return GestureDetector(
                onTap: () => setState(() => day = i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  width: 66,
                  padding: const EdgeInsets.symmetric(vertical: 9),
                  decoration: BoxDecoration(
                    color: selected ? AppColors.red : Colors.white,
                    borderRadius: BorderRadius.circular(13),
                    border: Border.all(
                      color: selected ? AppColors.red : AppColors.border,
                    ),
                    boxShadow: selected
                        ? const [
                            BoxShadow(
                              color: Color(0x1FE21B23),
                              blurRadius: 9,
                              offset: Offset(0, 3),
                            ),
                          ]
                        : null,
                  ),
                  child: Column(
                    children: [
                      Text(
                        weekdays[date.weekday - 1],
                        style: TextStyle(
                          fontSize: 10,
                          color: selected ? Colors.white70 : AppColors.muted,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${date.day}',
                        style: TextStyle(
                          fontSize: 17,
                          color: selected ? Colors.white : AppColors.ink,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        months[date.month - 1],
                        style: TextStyle(
                          fontSize: 9,
                          color: selected ? Colors.white70 : AppColors.muted,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
          const SectionTitle('Pilih Waktu · slot belum dikonfirmasi bengkel'),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: times
                .asMap()
                .entries
                .map(
                  (entry) => GestureDetector(
                    onTap: () => setState(() => time = entry.key),
                    child: Pill(entry.value, active: time == entry.key),
                  ),
                )
                .toList(),
          ),
          const SectionTitle('Catatan (opsional)'),
          TextField(
            controller: _notes,
            maxLines: 3,
            decoration: const InputDecoration(
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

class BookingConfirmationScreen extends StatelessWidget {
  final OtoKuState state;
  final String booking;
  const BookingConfirmationScreen({
    super.key,
    required this.state,
    required this.booking,
  });

  @override
  Widget build(BuildContext context) => Page(
    title: 'Permintaan Booking',
    child: ScrollPage(
      child: Column(
        children: [
          CardBox(
            color: AppColors.amberTint,
            child: const Column(
              children: [
                Icon(Icons.schedule, color: AppColors.amber, size: 44),
                SizedBox(height: 10),
                Text(
                  'Menunggu konfirmasi bengkel',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
                SizedBox(height: 6),
                Text(
                  'Permintaan tersimpan lokal. Jadwal belum dikonfirmasi dan pembayaran belum dilakukan.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.muted),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          CardBox(child: Text(booking)),
          const SizedBox(height: 18),
          FilledButton(
            onPressed: () => push(context, OrdersScreen(state: state)),
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
            ),
            child: const Text('Lihat Pesanan'),
          ),
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: () =>
                Navigator.popUntil(context, (route) => route.isFirst),
            child: const Text('Kembali ke Home'),
          ),
        ],
      ),
    ),
  );
}

class OrdersScreen extends StatefulWidget {
  final OtoKuState state;
  const OrdersScreen({super.key, required this.state});
  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  String filter = 'Semua';

  @override
  Widget build(BuildContext context) {
    final orders = widget.state.orders.where((order) {
      if (filter == 'Sparepart') return order.startsWith('#SP');
      if (filter == 'Layanan') return order.startsWith('#SV');
      return true;
    }).toList();
    return ColoredBox(
      color: AppColors.bg,
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 24),
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: 'OtoKu',
                          style: TextStyle(
                            color: AppColors.red,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        TextSpan(
                          text: '  ·  Pesanan',
                          style: TextStyle(
                            color: AppColors.ink,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    style: TextStyle(fontSize: 21, letterSpacing: -.4),
                  ),
                ),
                IconButton(
                  tooltip: 'Bantuan pesanan',
                  onPressed: () => showPrototypeNotice(
                    context,
                    'Bantuan',
                    'Pesanan lokal demo. Status pembayaran dan pengiriman belum tersedia.',
                  ),
                  icon: const Icon(Icons.help_outline, color: AppColors.muted),
                ),
              ],
            ),
            const SizedBox(height: 3),
            Row(
              children: [
                Text(
                  '${orders.length} aktivitas',
                  style: const TextStyle(color: AppColors.muted, fontSize: 12),
                ),
                const Spacer(),
                if (orders.isNotEmpty)
                  const Icon(Icons.circle, color: AppColors.red, size: 7),
              ],
            ),
            const SizedBox(height: 14),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'Semua', label: Text('Semua')),
                ButtonSegment(value: 'Sparepart', label: Text('Sparepart')),
                ButtonSegment(value: 'Layanan', label: Text('Layanan')),
              ],
              selected: {filter},
              onSelectionChanged: (selection) =>
                  setState(() => filter = selection.first),
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
                      'Pesanan dan booking kamu akan muncul di sini.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.muted),
                    ),
                  ],
                ),
              )
            else
              ...orders.map(
                (order) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: OrderCard(
                    order: order,
                    onTap: () => push(context, OrderDetailScreen(order: order)),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
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
        'Menunggu pembayaran',
        'Menunggu konfirmasi',
      ].contains(x),
      orElse: () => 'Status tidak diketahui',
    );
    final normalizedStatus = status == 'Pesanan Selesai' ? 'Selesai' : status;
    final details = fields.length > 2
        ? fields
              .sublist(2, fields.length - 1)
              .where((field) => field != status)
              .join(' · ')
        : '';
    final date = fields.length > 1 ? fields.last : '';
    return CardBox(
      padding: const EdgeInsets.all(14),
      onTap: onTap,
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                order.startsWith('#SV')
                    ? Icons.build_circle_outlined
                    : Icons.inventory_2_outlined,
                size: 17,
                color: AppColors.muted,
              ),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  fields.first,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: .1,
                  ),
                ),
              ),
              StatusChip(
                normalizedStatus,
                normalizedStatus == 'Diproses' ||
                        normalizedStatus == 'Dikirim' ||
                        normalizedStatus.startsWith('Menunggu')
                    ? AppColors.amber
                    : normalizedStatus == 'Dibatalkan'
                    ? AppColors.muted
                    : AppColors.green,
              ),
              const SizedBox(width: 2),
              const Icon(Icons.chevron_right, size: 18, color: AppColors.muted),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(height: 1),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ProductArt(
                icon: order.contains('Oli') ? 'oil' : 'brake',
                size: 58,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      fields.length > 1 ? fields[1] : order,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (details.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        details,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.muted,
                          fontSize: 11,
                        ),
                      ),
                    ],
                    const SizedBox(height: 6),
                    Text(
                      date,
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            decoration: BoxDecoration(
              color: AppColors.surfaceLow,
              borderRadius: BorderRadius.circular(11),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.info_outline,
                  size: 15,
                  color: AppColors.muted,
                ),
                const SizedBox(width: 7),
                Expanded(
                  child: Text(
                    order.startsWith('#SV')
                        ? 'Permintaan demo · menunggu respons bengkel'
                        : 'Transaksi simulasi · belum ada pembayaran',
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 10,
                    ),
                  ),
                ),
                const Text(
                  'Detail',
                  style: TextStyle(
                    color: AppColors.red,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
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
          CardBox(
            child: Text(
              'Status: ${order.split(' • ').firstWhere((field) => ['Menunggu pembayaran', 'Menunggu konfirmasi', 'Diproses', 'Dikirim', 'Selesai', 'Dibatalkan'].contains(field), orElse: () => 'Belum diketahui')}\nStatus demo lokal; belum ada konfirmasi pembayaran, penjual, atau bengkel.',
              style: const TextStyle(height: 1.5),
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
              'Belum ada pembayaran. Integrasi pembayaran belum tersedia.',
              style: TextStyle(height: 1.6),
            ),
          ),
        ],
      ),
    ),
  );
}

void showPrototypeNotice(BuildContext context, String title, String message) {
  showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Tutup'),
        ),
      ],
    ),
  );
}

class AccountScreen extends StatelessWidget {
  final OtoKuState state;
  const AccountScreen({super.key, required this.state});

  @override
  Widget build(BuildContext c) {
    final actions = <({String title, IconData icon, VoidCallback onTap})>[
      (
        title: 'Kendaraan Saya',
        icon: Icons.two_wheeler,
        onTap: () => push(c, VehicleDetailScreen(state: state)),
      ),
      (
        title: 'Pesanan Saya',
        icon: Icons.receipt_long_outlined,
        onTap: () => push(c, OrdersScreen(state: state)),
      ),
      (
        title: 'Booking Layanan',
        icon: Icons.event_note,
        onTap: () => push(c, OrdersScreen(state: state)),
      ),
      (
        title: 'Alamat Saya',
        icon: Icons.location_on_outlined,
        onTap: () => showPrototypeNotice(
          c,
          'Alamat Saya',
          'Alamat belum disimpan. Checkout demo tidak melakukan pengiriman.',
        ),
      ),
      (
        title: 'Metode Pembayaran',
        icon: Icons.account_balance_wallet_outlined,
        onTap: () => showPrototypeNotice(
          c,
          'Metode Pembayaran',
          'Tidak ada data pembayaran yang disimpan atau diproses dalam prototipe.',
        ),
      ),
      (
        title: 'Pusat Bantuan',
        icon: Icons.help_outline,
        onTap: () => showPrototypeNotice(
          c,
          'Pusat Bantuan',
          'Dukungan akun akan tersedia setelah layanan backend dikonfigurasi.',
        ),
      ),
      (
        title: 'Tentang OtoKu',
        icon: Icons.info_outline,
        onTap: () => showPrototypeNotice(
          c,
          'Tentang OtoKu',
          'Prototipe lokal. Data demo diberi label dan disimpan pada perangkat.',
        ),
      ),
    ];
    Widget menuGroup(
      List<({String title, IconData icon, VoidCallback onTap})> items,
    ) => DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
        boxShadow: _cardShadow,
      ),
      child: Column(
        children: [
          for (var i = 0; i < items.length; i++) ...[
            ListTile(
              minLeadingWidth: 24,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              leading: Icon(items[i].icon, color: AppColors.muted, size: 22),
              title: Text(
                items[i].title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              trailing: const Icon(
                Icons.chevron_right,
                color: AppColors.muted,
                size: 20,
              ),
              onTap: items[i].onTap,
            ),
            if (i < items.length - 1)
              const Divider(height: 1, indent: 52, endIndent: 16),
          ],
        ],
      ),
    );

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
        children: [
          Row(
            children: [
              const CircleAvatar(
                radius: 28,
                backgroundColor: AppColors.surfaceHigh,
                child: Text(
                  'OK',
                  style: TextStyle(
                    color: AppColors.ink,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Akun Saya',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -.4,
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      'Mode prototipe lokal · data di perangkat',
                      style: TextStyle(color: AppColors.muted, fontSize: 11),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Pengaturan akun',
                onPressed: () => showPrototypeNotice(
                  c,
                  'Pengaturan Akun',
                  'Pengaturan profil tersedia dalam mode demo.',
                ),
                icon: const Icon(
                  Icons.settings_outlined,
                  color: AppColors.muted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          CardBox(
            color: AppColors.surfaceLow,
            padding: const EdgeInsets.all(14),
            onTap: () => push(c, VehicleDetailScreen(state: state)),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceHigh,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.two_wheeler, color: AppColors.red),
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              state.vehicle.name,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                              ),
                            ),
                          ),
                          const SizedBox(width: 7),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.greenTint,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Text(
                              'Aktif',
                              style: TextStyle(
                                color: AppColors.green,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${state.vehicle.plate} · ${formatKilometers(state.vehicle.mileage)} km',
                        style: const TextStyle(
                          color: AppColors.muted,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: () => push(c, VehicleDetailScreen(state: state)),
                  child: const Text('Ubah'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          menuGroup(actions.take(5).toList()),
          const SizedBox(height: 14),
          menuGroup(actions.skip(5).toList()),
          const SizedBox(height: 14),
          CardBox(
            child: Row(
              children: [
                const Icon(Icons.info_outline, color: AppColors.red),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Prototipe lokal. Tidak ada autentikasi atau sinkronisasi akun.',
                    style: TextStyle(
                      color: AppColors.muted,
                      fontSize: 12,
                      height: 1.4,
                    ),
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

class CheckoutScreen extends StatelessWidget {
  final OtoKuState state;
  const CheckoutScreen({super.key, required this.state});

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: state,
    builder: (context, _) {
      final items = state.products
          .where((product) => state.quantityOf(product) > 0)
          .toList();
      return Page(
        title: 'Keranjang & Checkout',
        bottomBar: SafeArea(
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
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Subtotal simulasi',
                        style: TextStyle(color: AppColors.muted, fontSize: 11),
                      ),
                      Text(
                        'Rp ${formatKilometers(state.cartSubtotal)}',
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
                FilledButton(
                  onPressed: items.isEmpty
                      ? null
                      : () async {
                          final order = await state.checkout();
                          if (!context.mounted) return;
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (_) => OrderConfirmationScreen(
                                state: state,
                                order: order,
                              ),
                            ),
                          );
                        },
                  child: const Text('Buat Pesanan Demo'),
                ),
              ],
            ),
          ),
        ),
        child: ScrollPage(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: AppColors.redTint,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.red.withValues(alpha: .12),
                  ),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.shield_outlined, color: AppColors.red, size: 17),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Checkout simulasi · tidak ada pembayaran nyata',
                        style: TextStyle(
                          color: AppColors.redDark,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Ringkasan pesanan',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  Text(
                    '${items.length} item',
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              if (items.isEmpty)
                const CardBox(
                  child: Text('Keranjang kosong. Tambahkan produk dari Shop.'),
                ),
              ...items.map(
                (product) => CardBox(
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
                        'Rp ${formatKilometers(int.parse(product.price.replaceAll(RegExp(r'[^0-9]'), '')) * state.quantityOf(product))}',
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ],
                  ),
                ),
              ),
              const SectionTitle('Alamat pengiriman'),
              CardBox(
                onTap: () => showPrototypeNotice(
                  context,
                  'Alamat Pengiriman',
                  'Penyimpanan alamat belum tersedia pada prototipe lokal.',
                ),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: AppColors.redTint,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.location_on_outlined,
                        color: AppColors.red,
                        size: 19,
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Alamat belum diatur',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
                          SizedBox(height: 3),
                          Text(
                            'Checkout ini tidak melakukan pengiriman.',
                            style: TextStyle(
                              color: AppColors.muted,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right, color: AppColors.muted),
                  ],
                ),
              ),
              const SectionTitle('Pembayaran'),
              const CardBox(
                color: AppColors.surfaceLow,
                child: Row(
                  children: [
                    Icon(
                      Icons.do_not_disturb_on_outlined,
                      color: AppColors.muted,
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Tidak ada pembayaran',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
                          SizedBox(height: 3),
                          Text(
                            'Mode simulasi · payment_mode: mock',
                            style: TextStyle(
                              color: AppColors.muted,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    StatusChip('SIMULASI', AppColors.muted),
                  ],
                ),
              ),
              const SectionTitle('Rincian pembayaran'),
              CardBox(
                child: Column(
                  children: [
                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Subtotal produk',
                            style: TextStyle(
                              color: AppColors.muted,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        Text(
                          'Rp ${formatKilometers(state.cartSubtotal)}',
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 10),
                      child: Divider(height: 1),
                    ),
                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Total simulasi',
                            style: TextStyle(fontWeight: FontWeight.w800),
                          ),
                        ),
                        Text(
                          'Rp ${formatKilometers(state.cartSubtotal)}',
                          style: const TextStyle(
                            color: AppColors.red,
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

class OrderConfirmationScreen extends StatelessWidget {
  final OtoKuState state;
  final String order;
  const OrderConfirmationScreen({
    super.key,
    required this.state,
    required this.order,
  });

  @override
  Widget build(BuildContext context) => Page(
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
          CardBox(child: Text(order)),
          const SizedBox(height: 18),
          FilledButton(
            onPressed: () => push(context, OrdersScreen(state: state)),
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
            ),
            child: const Text('Lihat Pesanan'),
          ),
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: () =>
                Navigator.popUntil(context, (route) => route.isFirst),
            child: const Text('Kembali ke Home'),
          ),
        ],
      ),
    ),
  );
}
