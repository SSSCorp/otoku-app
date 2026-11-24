import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:marionette_flutter/marionette_flutter.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'data/oto_ku_repository.dart';
import 'screens/account_screens.dart';
import 'screens/maintenance_screens.dart';
import 'screens/orders_screens.dart';
import 'screens/home_screen.dart';
import 'screens/peta_screen.dart';
import 'screens/shop_screen.dart';
import 'services/app_services.dart';
import 'state/oto_ku_state.dart';
import 'ui/common.dart';

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
        colorScheme: const ColorScheme(
          brightness: Brightness.light,
          primary: AppColors.red,
          onPrimary: Colors.white,
          primaryContainer: AppColors.redTint,
          onPrimaryContainer: Color(0xFF6B0D11),
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
          inversePrimary: Color(0xFFFFB3B6),
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
            label: 'Beranda',
          ),
          NavigationDestination(
            icon: Icon(Icons.grid_view_outlined),
            selectedIcon: Icon(Icons.grid_view),
            label: 'Toko',
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
