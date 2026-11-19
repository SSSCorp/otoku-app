import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:marionette_flutter/marionette_flutter.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'data/oto_ku_repository.dart';
import 'models/commerce.dart';
import 'models/vehicle.dart';
import 'screens/account_screens.dart';
import 'screens/maintenance_screens.dart';
import 'screens/obd_screens.dart';
import 'screens/orders_screens.dart';
import 'screens/peta_screen.dart';
import 'screens/place_widgets.dart';
import 'screens/trip_screen.dart';
import 'screens/vehicle_screens.dart';
import 'services/app_services.dart';
import 'state/oto_ku_state.dart';
import 'ui/common.dart';
import 'ui/product_art.dart';

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

class OtoKuApp extends StatefulWidget {
  final OtoKuRepository? repository;

  /// Map, location and routing dependencies; tests inject fakes.
  final AppServices? services;
  const OtoKuApp({super.key, this.repository, this.services});
  @override
  State<OtoKuApp> createState() => _OtoKuAppState();
}

class _OtoKuAppState extends State<OtoKuApp> {
  late final state = OtoKuState(repository: widget.repository);
  late final services = widget.services ?? AppServices();

  @override
  void dispose() {
    if (widget.services == null) services.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ServicesScope(
    services: services,
    child: MaterialApp(
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
        fontFamily: 'Plus Jakarta Sans',
        dividerColor: AppColors.border,
        textTheme: const TextTheme(
          headlineMedium: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            letterSpacing: -.5,
            color: AppColors.ink,
          ),
          titleLarge: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            letterSpacing: -.3,
            color: AppColors.ink,
          ),
          titleMedium: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            letterSpacing: -.2,
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

class SplashScreen extends StatefulWidget {
  final OtoKuState state;
  const SplashScreen({super.key, required this.state});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _openApp();
  }

  Future<void> _openApp() async {
    setState(() => _failed = false);
    await widget.state.restore();
    if (widget.state.loadError != null) {
      if (mounted) setState(() => _failed = true);
      return;
    }
    await Future<void>.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;
    final next = widget.state.onboardingComplete
        ? AppShell(state: widget.state)
        : OnboardingScreen(state: widget.state);
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => next));
  }

  Future<void> _reset() async {
    await widget.state.resetLocalData();
    await _openApp();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.ink,
    body: SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
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
              if (_failed) ...[
                const Icon(
                  Icons.error_outline,
                  color: Colors.white70,
                  size: 34,
                ),
                const SizedBox(height: 10),
                const Text(
                  'Data lokal tidak bisa dibaca.',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Coba lagi, atau hapus data lokal untuk memulai dari awal.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white70, height: 1.4),
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: _openApp,
                  child: const Text('Coba lagi'),
                ),
                TextButton(
                  onPressed: _reset,
                  child: const Text(
                    'Hapus data lokal',
                    style: TextStyle(color: Colors.white70),
                  ),
                ),
              ] else
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

class _AppShellState extends State<AppShell> with WidgetsBindingObserver {
  AppServices? _services;
  bool _promptOpen = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_services != null) return;
    final services = _services = ServicesScope.of(context);
    services.tab.addListener(_onTab);
    services.visits.addListener(_onVisit);
    // Already-granted permission starts the live position (and SPBU visit
    // detection) without prompting; the prompt happens on the Peta tab.
    services.location.refresh();
    services.visits.start();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState lifecycle) {
    final services = _services;
    if (services == null) return;
    if (lifecycle == AppLifecycleState.resumed) {
      services.location.refresh();
      services.visits.start();
    } else if (lifecycle == AppLifecycleState.paused) {
      // Location is only used while the app is open.
      services.visits.stop();
      services.location.stop();
    }
  }

  void _onTab() => setState(() {});

  Future<void> _onVisit() async {
    final services = _services!;
    final place = services.visits.pending;
    if (place == null || _promptOpen || !mounted) return;
    _promptOpen = true;
    final log = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Kamu di SPBU?'),
        content: Text(
          'Sepertinya kamu berhenti di ${place.name}. Catat pengisian BBM sekarang?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Nanti'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Catat BBM'),
          ),
        ],
      ),
    );
    _promptOpen = false;
    services.visits.dismiss();
    if (log == true && mounted) {
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => ManualLogScreen(
            state: widget.state,
            initialType: 'bbm',
            initialTitle: 'Isi BBM di ${place.name}',
          ),
        ),
      );
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _services?.tab.removeListener(_onTab);
    _services?.visits.removeListener(_onVisit);
    _services?.visits.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final services = _services!;
    final index = services.tab.value;
    final state = widget.state;
    return Scaffold(
      body: ListenableBuilder(
        listenable: state,
        builder: (context, _) => switch (index) {
          0 => HomeScreen(state: state),
          1 => CatalogScreen(state: state),
          2 => PetaScreen(state: state),
          3 => OrdersScreen(state: state),
          _ => AccountScreen(state: state),
        },
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (i) => services.tab.value = i,
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
    final hasAttention = state.maintenanceNeedingAttention.isNotEmpty;
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
                if (state.saveError != null)
                  const CardBox(
                    color: AppColors.redTint,
                    child: Text(
                      'Perubahan terakhir belum tersimpan ke penyimpanan lokal. Coba ulangi.',
                      style: TextStyle(color: AppColors.red),
                    ),
                  ),
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
                const SizedBox(height: 14),
                SectionTitle(
                  'Perawatan Berikutnya',
                  action: 'Lihat Semua',
                  onTap: () => push(context, MaintenanceScreen(state: state)),
                ),
                MaintenanceCard(
                  state: state,
                  onTap: () => push(context, MaintenanceScreen(state: state)),
                ),
                if (hasAttention) ...[
                  const SizedBox(height: 10),
                  NearestBengkelSection(
                    state: state,
                    limit: 1,
                    task: state.maintenanceNeedingAttention.first.task.title,
                    reason:
                        'Bengkel terdekat untuk ${state.maintenanceNeedingAttention.first.task.title}:',
                  ),
                ],
                const SizedBox(height: 16),
                state.obdConnected
                    ? ConnectedObdCard(state: state)
                    : LockedObdCard(state: state),
                if (state.obdConnected) ...[
                  SectionTitle(
                    key: const ValueKey('section-obd'),
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
                const SizedBox(height: 18),
                SectionTitle(
                  'Catatan kendaraan',
                  action: '+ Catat',
                  onTap: () => push(context, ManualLogScreen(state: state)),
                ),
                CardBox(
                  onTap: () => push(context, HistoryScreen(state: state)),
                  child: Text(
                    state.logs.isEmpty
                        ? 'Belum ada catatan. Tambahkan kilometer, BBM, servis, atau biaya.'
                        : '${state.logs.first['title']} · Catatan terbaru',
                    style: const TextStyle(color: AppColors.muted),
                  ),
                ),
                const SectionTitle('Perjalanan'),
                CardBox(
                  onTap: () => push(context, TripScreen(state: state)),
                  child: const Row(
                    children: [
                      Icon(Icons.route_outlined, color: AppColors.red),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Trip GPS · rekam jarak dan durasi perjalanan',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                      Icon(Icons.chevron_right, color: AppColors.muted),
                    ],
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
  Widget build(BuildContext context) => Container(
    height: 192,
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(16),
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [AppColors.navy, AppColors.darkSurface],
      ),
      boxShadow: [
        BoxShadow(
          color: AppColors.red.withValues(alpha: .14),
          blurRadius: 24,
          offset: const Offset(0, 6),
        ),
      ],
    ),
    clipBehavior: Clip.antiAlias,
    child: Stack(
      children: [
        PageView(
          controller: _controller,
          onPageChanged: (page) => setState(() => _page = page),
          children: [
            _ObdAdSlide(
              eyebrow: 'FITUR OtoKu',
              title: 'Coba simulasi OBD',
              body: 'Contoh data kendaraan — OBD belum terhubung.',
              action: 'Lihat demo OBD',
              icon: Icons.memory_outlined,
              onTap: () => openObd(context, widget.state),
            ),
            _ObdAdSlide(
              eyebrow: 'LEBIH TERPANTAU',
              title: 'Data mesin, lebih mudah dipahami',
              body: 'Pantau RPM, suhu mesin, dan indikasi masalah dengan bahasa sederhana.',
              action: 'Coba simulasi',
              icon: Icons.insights_outlined,
              onTap: () => openObd(context, widget.state),
            ),
            _ObdAdSlide(
              eyebrow: 'LENGKAPI PERAWATAN',
              title: 'Perawatan kendaraan lebih mudah',
              body: 'Temukan suku cadang dan layanan yang sesuai untuk kendaraanmu.',
              action: 'Buka Shop',
              icon: Icons.shopping_bag_outlined,
              onTap: () => push(context, CatalogScreen(state: widget.state)),
            ),
          ],
        ),
        Positioned(
          left: 18,
          bottom: 12,
          child: Row(
            children: [
              ...List.generate(
                3,
                (index) => AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.only(right: 5),
                  width: index == _page ? 16 : 5,
                  height: 5,
                  decoration: BoxDecoration(
                    color: index == _page ? AppColors.red : Colors.white38,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              const Text(
                'Geser untuk melihat',
                style: TextStyle(color: Colors.white60, fontSize: 10),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _ObdAdSlide extends StatelessWidget {
  final String eyebrow, title, body, action;
  final IconData? icon;
  final VoidCallback onTap;
  const _ObdAdSlide({
    required this.eyebrow,
    required this.title,
    required this.body,
    required this.action,
    required this.onTap,
    this.icon,
  });

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(18, 16, 18, 26),
    child: Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                children: [
                  Icon(icon, color: AppColors.red, size: 18),
                  const SizedBox(width: 7),
                  Text(
                    eyebrow,
                    style: const TextStyle(
                      color: AppColors.red,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: .7,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                body,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 11,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 9),
              InkWell(
                onTap: onTap,
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        action,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(width: 3),
                      const Icon(
                        Icons.arrow_forward,
                        color: AppColors.red,
                        size: 15,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Container(
          width: 58,
          height: 58,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: .08),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.white.withValues(alpha: .08)),
          ),
          child: Icon(icon ?? Icons.memory, color: Colors.white70, size: 28),
        ),
      ],
    ),
  );
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
    final color = dueColor(next.level);
    return CardBox(
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: next.level == DueLevel.ok
                  ? AppColors.greenTint
                  : AppColors.redTint,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              next.task.icon,
              color: next.level == DueLevel.ok
                  ? AppColors.green
                  : AppColors.red,
            ),
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
                        next.task.title,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ),
                    const SizedBox(width: 8),
                    StatusChip(dueChipLabel(next.level), color),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  'Estimasi: ${dueText(next)}',
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
                  const Text(
                    'Shop',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -.5,
                    ),
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
                            ['Sparepart', Icons.two_wheeler],
                            ['Oli & Cairan', Icons.oil_barrel_outlined],
                            ['Rem', Icons.disc_full],
                            ['Filter', Icons.filter_alt_outlined],
                            ['Aki', Icons.battery_full],
                            ['Aksesori', Icons.lightbulb_outline],
                            ['Semua', Icons.grid_view_outlined],
                          ]
                          .map(
                            (x) => InkWell(
                              onTap: () => setState(() => cat = x[0] as String),
                              borderRadius: BorderRadius.circular(12),
                              child: Column(
                                children: [
                                  Container(
                                    width: 52,
                                    height: 52,
                                    decoration: BoxDecoration(
                                      color: cat == x[0]
                                          ? AppColors.redTint
                                          : Colors.white,
                                      border: Border.all(
                                        color: cat == x[0]
                                            ? AppColors.red
                                            : AppColors.border,
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Icon(
                                      x[1] as IconData,
                                      color: cat == x[0]
                                          ? AppColors.red
                                          : AppColors.ink,
                                    ),
                                  ),
                                  const SizedBox(height: 5),
                                  Text(
                                    x[0] as String,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: cat == x[0]
                                          ? FontWeight.w700
                                          : FontWeight.w500,
                                      color: cat == x[0]
                                          ? AppColors.red
                                          : AppColors.muted,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                          .toList(),
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
                        fitment: p.fitmentFor(widget.state.vehicle),
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
  final ProductFitment fitment;
  final VoidCallback onTap;
  const ProductCard({
    super.key,
    required this.p,
    required this.vehicleName,
    required this.fitment,
    required this.onTap,
  });
  @override
  Widget build(BuildContext c) => CardBox(
    onTap: onTap,
    child: Row(
      children: [
        ProductArt(icon: p.icon, image: p.imageAsset),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(p.name, style: const TextStyle(fontWeight: FontWeight.w800)),
              Text(
                switch (fitment) {
                  ProductFitment.confirmed => 'Cocok untuk $vehicleName',
                  ProductFitment.possibleUnverified =>
                    'Mungkin cocok untuk $vehicleName · belum diverifikasi',
                  ProductFitment.incompatible =>
                    'Tidak cocok untuk $vehicleName',
                  ProductFitment.unknown => 'Kompatibilitas belum diketahui',
                },
                style: TextStyle(
                  color: switch (fitment) {
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
              const Text(
                'Stok belum dikonfirmasi · demo',
                style: TextStyle(color: AppColors.muted, fontSize: 10),
              ),
            ],
          ),
        ),
        const Icon(Icons.chevron_right),
      ],
    ),
  );
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
