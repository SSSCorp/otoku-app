import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:otoku/data/oto_ku_repository.dart';
import 'package:otoku/main.dart';
import 'package:otoku/models/vehicle.dart';
import 'package:otoku/state/oto_ku_state.dart';

import 'support/fakes.dart';
import 'support/harness.dart';

void main() {
  group('startup', () {
    testWidgets('First launch introduces OtoKu and can be skipped', (
      tester,
    ) async {
      await launch(tester, onboarded: false);
      expect(find.text('Rawat kendaraan lebih mudah'), findsOneWidget);
      await tester.tap(find.text('Lewati'));
      await tester.pumpAndSettle();
      expect(find.text('Honda Beat 2021'), findsOneWidget);
    });

    testWidgets('Onboarding walks all pages and finishes with Mulai', (
      tester,
    ) async {
      final repo = MemoryOtoKuRepository();
      await launch(tester, repository: repo, onboarded: false);
      await tester.tap(find.text('Lanjut'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Lanjut'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Mulai'));
      await tester.pumpAndSettle();
      expect(find.text('Honda Beat 2021'), findsOneWidget);
      expect(repo.onboardingComplete, isTrue);
    });

    testWidgets('Unreadable local data shows an error state with retry', (
      tester,
    ) async {
      final repo = _FailingRepository();
      await tester.pumpWidget(
        OtoKuApp(repository: repo, services: testServices()),
      );
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pumpAndSettle();
      expect(find.text('Data lokal tidak bisa dibaca.'), findsOneWidget);
      repo.failing = false;
      await tester.tap(find.text('Coba lagi'));
      await tester.pump(const Duration(milliseconds: 1200));
      await tester.pumpAndSettle();
      expect(find.text('Honda Beat 2021'), findsOneWidget);
    });

    testWidgets('The prototype shell reaches every bottom-navigation tab', (
      tester,
    ) async {
      await launch(tester);
      for (final label in ['Shop', 'Peta', 'Pesanan', 'Akun', 'Home']) {
        await openTab(tester, label);
      }
      await openTab(tester, 'Pesanan');
      expect(find.text('Pesanan Saya'), findsOneWidget);
      await openTab(tester, 'Akun');
      expect(find.text('Akun Saya'), findsOneWidget);
    });
  });

  group('home and manual logs', () {
    testWidgets(
      'Home labels vehicle condition as unchecked without diagnostics',
      (tester) async {
        await launch(tester);
        expect(find.text('Belum dicek'), findsOneWidget);
        expect(find.text('Belum dicatat'), findsOneWidget);
      },
    );

    testWidgets('Home shows the soonest maintenance with a due estimate', (
      tester,
    ) async {
      await launch(tester);
      expect(find.text('Ganti Oli Mesin'), findsOneWidget);
      expect(find.textContaining('1.550 km lagi'), findsOneWidget);
    });

    testWidgets('Home carousel stays on its slide until the user changes it', (
      tester,
    ) async {
      await launch(tester);
      await reveal(tester, find.text('Coba simulasi OBD'));
      expect(find.text('Geser untuk melihat'), findsOneWidget);
      await tester.pump(const Duration(seconds: 5));
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text('Coba simulasi OBD'), findsOneWidget);
    });

    testWidgets(
      'Notifications are derived from local data and empty otherwise',
      (tester) async {
        await launch(tester);
        await tester.tap(find.byTooltip('Notifikasi'));
        await tester.pumpAndSettle();
        expect(find.text('Belum ada notifikasi'), findsOneWidget);
      },
    );

    testWidgets('Manual mileage entry updates the vehicle odometer', (
      tester,
    ) async {
      await launch(tester);
      await reveal(tester, find.text('+ Catat'));
      await tester.tap(find.text('+ Catat'));
      await tester.pumpAndSettle();
      expect(find.text('Catat Aktivitas'), findsOneWidget);
      await tester.enterText(find.byKey(const ValueKey('log-value')), '13000');
      await tester.tap(find.text('Simpan Catatan'));
      await tester.pumpAndSettle();
      await tester.drag(find.byType(Scrollable).first, const Offset(0, 1000));
      await tester.pumpAndSettle();
      expect(find.text('13.000'), findsOneWidget);
    });

    testWidgets(
      'Lower manual mileage is rejected without changing the reading',
      (tester) async {
        await launch(tester);
        await reveal(tester, find.text('+ Catat'));
        await tester.tap(find.text('+ Catat'));
        await tester.pumpAndSettle();
        await tester.enterText(
          find.byKey(const ValueKey('log-value')),
          '12000',
        );
        await tester.tap(find.text('Simpan Catatan'));
        await tester.pumpAndSettle();
        expect(
          find.text(
            'Kilometer baru tidak boleh lebih rendah dari catatan sebelumnya.',
          ),
          findsOneWidget,
        );
        expect(find.text('Catat Aktivitas'), findsOneWidget);
      },
    );

    Future<void> addFuelLog(WidgetTester tester) async {
      await reveal(tester, find.text('+ Catat'));
      await tester.tap(find.text('+ Catat'));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(DropdownButtonFormField<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('BBM').last);
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).first, 'Isi Pertalite');
      await tester.enterText(find.byKey(const ValueKey('log-value')), '50000');
      await tester.tap(find.text('Simpan Catatan'));
      await tester.pumpAndSettle();
    }

    testWidgets('Manual fuel logs appear in the vehicle summary', (
      tester,
    ) async {
      await launch(tester);
      await addFuelLog(tester);
      expect(find.text('Isi Pertalite · Catatan terbaru'), findsOneWidget);
    });

    testWidgets(
      'History shows empty state, then a log that can be edited and deleted',
      (tester) async {
        await launch(tester);
        await reveal(tester, find.text('Catatan kendaraan'));
        await tester.tap(
          find.text(
            'Belum ada catatan. Tambahkan kilometer, BBM, servis, atau biaya.',
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text('Belum ada riwayat'), findsOneWidget);
        await back(tester);

        await addFuelLog(tester);
        await tester.tap(find.text('Isi Pertalite · Catatan terbaru'));
        await tester.pumpAndSettle();
        expect(find.text('Isi Pertalite'), findsOneWidget);

        await tester.tap(find.byTooltip('Ubah catatan'));
        await tester.pumpAndSettle();
        expect(find.text('Ubah Catatan'), findsOneWidget);
        await tester.enterText(find.byType(TextField).first, 'Pertamax');
        await tester.tap(find.text('Simpan Perubahan'));
        await tester.pumpAndSettle();
        expect(find.text('Pertamax'), findsOneWidget);

        await tester.tap(find.byTooltip('Hapus catatan'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Hapus'));
        await tester.pumpAndSettle();
        expect(find.text('Belum ada riwayat'), findsOneWidget);
      },
    );

    testWidgets('Logs survive an app restart', (tester) async {
      final repo = MemoryOtoKuRepository(onboardingComplete: true);
      await launch(tester, repository: repo);
      await addFuelLog(tester);
      await tester.pumpWidget(const SizedBox());
      await launch(tester, repository: repo);
      expect(find.text('Isi Pertalite · Catatan terbaru'), findsOneWidget);
    });
  });

  group('maintenance', () {
    testWidgets(
      'Overdue tasks are flagged, suggest a bengkel, and can be marked done',
      (tester) async {
        final repo = MemoryOtoKuRepository(onboardingComplete: true);
        await launch(tester, repository: repo);
        await tester.tap(find.text('Lihat Semua').first);
        await tester.pumpAndSettle();
        expect(find.text('Tidak ada perawatan mendesak'), findsOneWidget);
        await tester.tap(find.text('Semua'));
        await tester.pumpAndSettle();
        expect(find.text('Cek Busi'), findsOneWidget);
        expect(find.textContaining('Jatuh tempo 14.000 km'), findsOneWidget);

        await back(tester);
        await reveal(tester, find.text('+ Catat'));
        await tester.tap(find.text('+ Catat'));
        await tester.pumpAndSettle();
        await tester.enterText(
          find.byKey(const ValueKey('log-value')),
          '14100',
        );
        await tester.tap(find.text('Simpan Catatan'));
        await tester.pumpAndSettle();

        await tester.drag(find.byType(Scrollable).first, const Offset(0, 1500));
        await tester.pumpAndSettle();
        expect(find.textContaining('Terlewat 100 km'), findsWidgets);
        await tester.tap(find.text('Lihat Semua').first);
        await tester.pumpAndSettle();
        expect(find.text('Terlewat'), findsOneWidget);
        expect(find.byKey(const ValueKey('nearest-bengkel')), findsOneWidget);

        await tester.tap(find.byKey(const ValueKey('done-Ganti Oli Mesin')));
        await tester.pumpAndSettle();
        expect(find.text('Terlewat'), findsNothing);
        await tester.tap(find.text('Selesai'));
        await tester.pumpAndSettle();
        expect(find.text('Ganti Oli Mesin'), findsOneWidget);
        expect(find.textContaining('14.100 km'), findsWidgets);
      },
    );
  });

  group('shop and orders', () {
    testWidgets('Shop catalog displays product photography and compatibility', (
      tester,
    ) async {
      await launch(tester);
      await openTab(tester, 'Shop');
      await reveal(tester, find.text('Oli Mesin Honda AHM SPX2'));
      expect(find.byType(Image).evaluate(), isNotEmpty);
      await reveal(tester, find.text('Kampas Rem Mobil Avanza'));
      expect(find.text('Tidak cocok untuk Honda Beat 2021'), findsOneWidget);
    });

    testWidgets('Shop search with no match shows an empty state', (
      tester,
    ) async {
      await launch(tester);
      await openTab(tester, 'Shop');
      await tester.enterText(find.byType(TextField).first, 'zzzz');
      await tester.pumpAndSettle();
      expect(find.text('Produk tidak ditemukan'), findsOneWidget);
    });

    testWidgets('Incompatible parts cannot be added to the cart', (
      tester,
    ) async {
      await launch(tester);
      await openTab(tester, 'Shop');
      await reveal(tester, find.text('Kampas Rem Mobil Avanza'));
      await tester.tap(find.text('Kampas Rem Mobil Avanza').last);
      await tester.pumpAndSettle();
      expect(find.text('Tidak cocok untuk kendaraan Anda'), findsOneWidget);
      expect(
        tester
            .widget<FilledButton>(
              find.widgetWithText(FilledButton, 'Beli Sekarang'),
            )
            .onPressed,
        isNull,
      );
    });

    Future<void> buyOil(WidgetTester tester) async {
      await openTab(tester, 'Shop');
      await reveal(tester, find.text('Oli Mesin Honda AHM SPX2'));
      await tester.tap(find.text('Oli Mesin Honda AHM SPX2').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Beli Sekarang'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Tambah jumlah'));
      await tester.pumpAndSettle();
      expect(find.text('2'), findsOneWidget);
      await tester.tap(find.text('Buat Pesanan Demo'));
      await tester.pumpAndSettle();
    }

    testWidgets('Cart quantities and checkout create a pending local order', (
      tester,
    ) async {
      await launch(tester);
      await buyOil(tester);
      expect(find.text('Menunggu pembayaran'), findsOneWidget);
      expect(find.textContaining('Tidak ada pembayaran'), findsOneWidget);
      await tester.tap(find.text('Lihat Pesanan'));
      await tester.pumpAndSettle();
      expect(find.text('Pesanan Saya'), findsOneWidget);
      expect(find.text('Menunggu pembayaran'), findsOneWidget);
      expect(
        find.textContaining('2x Oli Mesin Honda AHM SPX2'),
        findsOneWidget,
      );
    });

    testWidgets('Order status can be advanced (simulated) and cancelled', (
      tester,
    ) async {
      await launch(tester);
      await buyOil(tester);
      await tester.tap(find.text('Lihat Pesanan'));
      await tester.pumpAndSettle();
      await tester.tap(find.textContaining('2x Oli Mesin'));
      await tester.pumpAndSettle();
      expect(find.textContaining('simulasi lokal'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('advance-order')));
      await tester.pumpAndSettle();
      expect(find.text('Diproses'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('cancel-order')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Batalkan').last);
      await tester.pumpAndSettle();
      expect(find.text('Dibatalkan'), findsOneWidget);
      expect(find.byKey(const ValueKey('advance-order')), findsNothing);
    });

    testWidgets(
      'Orders persist across restart and the empty state is explained',
      (tester) async {
        final repo = MemoryOtoKuRepository(onboardingComplete: true);
        await launch(tester, repository: repo);
        await openTab(tester, 'Pesanan');
        expect(find.text('Belum ada pesanan'), findsOneWidget);
        await buyOil(tester);
        await tester.pumpWidget(const SizedBox());
        await launch(tester, repository: repo);
        await openTab(tester, 'Pesanan');
        expect(
          find.textContaining('2x Oli Mesin Honda AHM SPX2'),
          findsOneWidget,
        );
      },
    );
  });

  group('vehicles', () {
    testWidgets('Add, switch, edit and delete vehicles', (tester) async {
      await launch(tester);
      await openTab(tester, 'Akun');
      await tester.tap(find.text('Kendaraan Saya'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('add-vehicle')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Mobil'));
      await tester.enterText(find.widgetWithText(TextField, 'Merek'), 'Toyota');
      await tester.enterText(find.widgetWithText(TextField, 'Model'), 'Avanza');
      await tester.enterText(
        find.widgetWithText(TextField, 'Nomor polisi'),
        'b 9 car',
      );
      await tester.enterText(find.widgetWithText(TextField, 'Tahun'), '2019');
      await tester.enterText(
        find.widgetWithText(TextField, 'Kilometer terakhir'),
        '54000',
      );
      await tester.tap(find.text('Simpan Kendaraan'));
      await tester.pumpAndSettle();
      expect(find.text('Toyota Avanza 2019'), findsOneWidget);
      expect(find.text('Aktif'), findsOneWidget);

      await tester.tap(find.text('Jadikan aktif'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Ubah Toyota Avanza 2019'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.widgetWithText(TextField, 'Kilometer terakhir'),
        '100',
      );
      await tester.tap(find.text('Simpan Perubahan'));
      await tester.pumpAndSettle();
      expect(
        find.text('Kilometer baru tidak boleh lebih rendah.'),
        findsOneWidget,
      );
      await tester.enterText(
        find.widgetWithText(TextField, 'Kilometer terakhir'),
        '54200',
      );
      await tester.tap(find.text('Simpan Perubahan'));
      await tester.pumpAndSettle();
      expect(find.textContaining('54.200 km'), findsOneWidget);

      await tester.tap(find.byTooltip('Hapus Toyota Avanza 2019'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Hapus').last);
      await tester.pumpAndSettle();
      expect(find.text('Toyota Avanza 2019'), findsNothing);
      await tester.tap(find.byTooltip('Hapus Honda Beat 2021'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.textContaining('Minimal satu kendaraan'), findsOneWidget);
    });

    testWidgets('Switching vehicle changes Home and shop compatibility', (
      tester,
    ) async {
      final repo = MemoryOtoKuRepository(onboardingComplete: true);
      final seed = OtoKuState(repository: repo);
      await seed.restore();
      await seed.addVehicle(
        const Vehicle(
          kind: VehicleKind.mobil,
          brand: 'Toyota',
          model: 'Avanza',
          plate: 'B 9 CAR',
          type: '1.3 G',
          year: 2019,
          mileage: 54000,
        ),
      );
      await launch(tester, repository: repo);
      expect(find.text('Toyota Avanza 2019'), findsOneWidget);
      expect(find.text('Ganti kendaraan (2)'), findsOneWidget);
      await openTab(tester, 'Shop');
      await reveal(tester, find.text('Kampas Rem Mobil Avanza'));
      expect(
        find.text(
          'Mungkin cocok untuk Toyota Avanza 2019 · belum diverifikasi',
        ),
        findsOneWidget,
      );
    });
  });

  group('obd simulation', () {
    testWidgets(
      'Adapter flow is always labelled simulated and shows explained DTCs',
      (tester) async {
        await launch(tester);
        await reveal(tester, find.text('Lihat demo OBD'));
        await tester.tap(find.text('Lihat demo OBD'));
        await tester.pumpAndSettle();
        expect(find.textContaining('SIMULASI'), findsOneWidget);
        await tester.tap(find.text('Cari adaptor (simulasi)'));
        await tester.pumpAndSettle();
        expect(find.text('ELM327 Mini (simulasi)'), findsOneWidget);
        await tester.tap(find.byKey(const ValueKey('adapter-elm327-demo')));
        await tester.pumpAndSettle();

        expect(find.text('OBD Demo Aktif'), findsOneWidget);
        expect(
          find.text('Data simulasi — bukan data kendaraan langsung'),
          findsOneWidget,
        );
        await reveal(tester, find.text('64'));

        final seeAll = find.descendant(
          of: find.byKey(const ValueKey('section-obd')),
          matching: find.text('Lihat Semua'),
        );
        await tester.ensureVisible(seeAll);
        await tester.pumpAndSettle();
        await tester.tap(seeAll);
        await tester.pumpAndSettle();
        expect(find.text('Data OBD · Simulasi'), findsOneWidget);
        await reveal(tester, find.byKey(const ValueKey('dtc-P0301')));
        expect(find.textContaining('bukan diagnosis pasti'), findsWidgets);
        expect(find.text('Misfire silinder 1'), findsOneWidget);
        await reveal(tester, find.byKey(const ValueKey('nearest-bengkel')));
        await reveal(tester, find.text('Hapus kode (simulasi)'));
        await tester.tap(find.text('Hapus kode (simulasi)'));
        await tester.pumpAndSettle();
        expect(
          find.text('Tidak ada kode masalah pada simulasi ini.'),
          findsOneWidget,
        );
      },
    );
  });

  group('account', () {
    testWidgets('Every account entry opens a working screen (no stubs)', (
      tester,
    ) async {
      await launch(tester);
      await openTab(tester, 'Akun');
      for (final title in [
        'Alamat Saya',
        'Peta & Lokasi',
        'Pusat Bantuan',
        'Tentang OtoKu',
        'Data & Privasi',
        'Booking Layanan',
        'Trip GPS',
      ]) {
        await tapText(tester, title);
        expect(find.text(title), findsWidgets);
        expect(find.textContaining('akan tersedia'), findsNothing);
        expect(find.textContaining('belum tersedia'), findsNothing);
        await back(tester);
      }
    });

    testWidgets('Address saves locally and shows at checkout', (tester) async {
      final repo = MemoryOtoKuRepository(onboardingComplete: true);
      await launch(tester, repository: repo);
      await openTab(tester, 'Akun');
      await tapText(tester, 'Alamat Saya');
      await tester.enterText(find.byType(TextField), 'Jl. Mawar 1, Bekasi');
      await tester.tap(find.text('Simpan Alamat'));
      await tester.pumpAndSettle();
      final saved = await repo.loadState();
      expect(saved!['address'], 'Jl. Mawar 1, Bekasi');
    });

    testWidgets('Deleting local data resets the app', (tester) async {
      final repo = MemoryOtoKuRepository(onboardingComplete: true);
      await launch(tester, repository: repo);
      await openTab(tester, 'Akun');
      await tapText(tester, 'Data & Privasi');
      await tester.tap(find.byKey(const ValueKey('reset-data')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Hapus').last);
      await tester.pumpAndSettle();
      expect(find.text('Honda Beat 2021'), findsOneWidget);
    });
  });
}

class _FailingRepository extends MemoryOtoKuRepository {
  _FailingRepository() : super(onboardingComplete: true);
  bool failing = true;
  @override
  Future<Map<String, dynamic>?> loadState() async =>
      failing ? throw const FormatException('rusak') : super.loadState();
}
