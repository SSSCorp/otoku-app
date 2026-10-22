import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:otoku/main.dart';

Future<void> launchToHome(WidgetTester tester) async {
  await tester.pumpWidget(const OtoKuApp());
  await tester.pump(const Duration(milliseconds: 1200));
  await tester.pumpAndSettle();
  if (find.text('Lewati').evaluate().isNotEmpty) {
    await tester.tap(find.text('Lewati'));
    await tester.pumpAndSettle();
  }
}

/// Scrolls until [finder] exists, then ensures it is fully on screen and
/// tappable (scrollUntilVisible can stop while the target is still built
/// off-screen inside the scrollable's cache extent).
Future<void> reveal(WidgetTester tester, Finder finder) async {
  await tester.scrollUntilVisible(
    finder,
    180,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('First launch introduces OtoKu and can be skipped', (
    tester,
  ) async {
    await tester.pumpWidget(const OtoKuApp());
    await tester.pump(const Duration(milliseconds: 1200));
    await tester.pumpAndSettle();

    expect(find.text('Rawat kendaraan lebih mudah'), findsOneWidget);
    await tester.tap(find.text('Lewati'));
    await tester.pumpAndSettle();
    expect(find.text('Honda Beat 2021'), findsOneWidget);
  });

  testWidgets('OtoKu opens its prototype shell', (tester) async {
    await launchToHome(tester);
    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Shop'), findsOneWidget);
    expect(find.text('Peta'), findsOneWidget);
    expect(find.text('Honda Beat 2021'), findsOneWidget);
    await reveal(tester, find.text('OtoKu OBD-II Scanner'));
    expect(find.text('OtoKu OBD-II Scanner'), findsOneWidget);
    expect(find.text('Hubungkan OBD'), findsNothing);
    expect(find.text('Lihat'), findsOneWidget);
  });

  testWidgets('Manual mileage entry updates the vehicle odometer', (
    tester,
  ) async {
    await launchToHome(tester);
    await reveal(tester, find.text('Catat aktivitas'));
    await tester.tap(find.text('Catat aktivitas'));
    await tester.pumpAndSettle();

    expect(find.text('Catat Aktivitas'), findsOneWidget);
    await tester.enterText(find.byKey(const ValueKey('log-value')), '13000');
    await tester.tap(find.text('Simpan Catatan'));
    await tester.pumpAndSettle();
    await tester.drag(find.byType(Scrollable).first, const Offset(0, 1000));
    await tester.pumpAndSettle();

    expect(find.text('13.000'), findsOneWidget);
  });

  testWidgets('Lower manual mileage is rejected without changing the reading', (
    tester,
  ) async {
    await launchToHome(tester);
    await reveal(tester, find.text('Catat aktivitas'));
    await tester.tap(find.text('Catat aktivitas'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const ValueKey('log-value')), '12000');
    await tester.tap(find.text('Simpan Catatan'));
    await tester.pumpAndSettle();

    expect(
      find.text(
        'Kilometer baru tidak boleh lebih rendah dari catatan sebelumnya.',
      ),
      findsOneWidget,
    );
    expect(find.text('Catat Aktivitas'), findsOneWidget);
  });

  testWidgets('Manual fuel logs appear in the vehicle summary', (tester) async {
    await launchToHome(tester);
    await reveal(tester, find.text('Catat aktivitas'));
    await tester.tap(find.text('Catat aktivitas'));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('BBM').last);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, 'Isi Pertalite');
    await tester.enterText(find.byKey(const ValueKey('log-value')), '50000');
    await tester.tap(find.text('Simpan Catatan'));
    await tester.pumpAndSettle();

    await reveal(tester, find.text('Honda Beat 2021'));
    await tester.tap(find.text('Honda Beat 2021'));
    await tester.pumpAndSettle();
    await reveal(tester, find.text('Riwayat & Tracking'));
    await tester.tap(find.text('Riwayat & Tracking'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Isi Pertalite'), findsOneWidget);
  });

  testWidgets('Home quick action explains trip tracking is not available yet', (
    tester,
  ) async {
    await launchToHome(tester);
    await reveal(tester, find.text('Mulai Trip'));
    await tester.tap(find.text('Mulai Trip'));
    await tester.pumpAndSettle();

    expect(
      find.textContaining('Pelacakan GPS trip belum tersedia.'),
      findsOneWidget,
    );
    expect(
      find.textContaining('mencatat kilometer secara manual'),
      findsOneWidget,
    );
  });

  testWidgets(
    'Map category filters show local SPBU results without a map key',
    (tester) async {
      await launchToHome(tester);
      await tester.tap(find.text('Peta').last);
      await tester.pumpAndSettle();

      expect(find.text('Peta & Tempat'), findsOneWidget);
      await tester.tap(find.text('SPBU').first);
      await tester.pumpAndSettle();
      expect(find.text('SPBU Pertamina Demo'), findsOneWidget);
      expect(find.text('Bengkel Jaya Motor'), findsNothing);
      expect(find.textContaining('Peta ilustrasi'), findsOneWidget);
    },
  );

  testWidgets('Booking requires at least one service selection', (
    tester,
  ) async {
    await launchToHome(tester);
    await tester.tap(find.text('Peta').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Bengkel partner'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Bengkel Jaya Motor'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Booking partner demo'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('booking-oil')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Lanjutkan'));
    await tester.pumpAndSettle();

    expect(find.text('Pilih minimal satu layanan.'), findsOneWidget);
    expect(find.text('Menunggu konfirmasi bengkel'), findsNothing);
  });

  testWidgets('Partner booking is saved as awaiting confirmation', (
    tester,
  ) async {
    await launchToHome(tester);
    await tester.tap(find.text('Peta').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Bengkel partner'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Bengkel Jaya Motor'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Booking partner demo'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Lanjutkan'));
    await tester.pumpAndSettle();

    expect(find.text('Menunggu konfirmasi bengkel'), findsOneWidget);
    expect(find.textContaining('Booking Bengkel Jaya Motor'), findsOneWidget);
    await tester.tap(find.text('Lihat Pesanan'));
    await tester.pumpAndSettle();
    expect(find.text('Menunggu konfirmasi'), findsOneWidget);
  });

  testWidgets('Shop catalog displays downloaded product photography', (
    tester,
  ) async {
    await launchToHome(tester);
    await tester.tap(find.text('Shop').last);
    await tester.pumpAndSettle();
    await reveal(tester, find.text('Oli Mesin Honda AHM SPX2'));

    expect(find.byType(Image).evaluate(), isNotEmpty);
  });

  testWidgets('Cart quantities and checkout create a pending local order', (
    tester,
  ) async {
    await launchToHome(tester);
    await tester.tap(find.text('Shop').last);
    await tester.pumpAndSettle();
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

    expect(find.text('Menunggu pembayaran'), findsOneWidget);
    expect(find.textContaining('Tidak ada pembayaran'), findsOneWidget);
    await tester.tap(find.text('Lihat Pesanan'));
    await tester.pumpAndSettle();
    expect(find.text('Menunggu pembayaran'), findsOneWidget);
    expect(find.textContaining('2x Oli Mesin Honda AHM SPX2'), findsOneWidget);
  });

  testWidgets(
    'Home labels vehicle condition as unchecked without diagnostics',
    (tester) async {
      await launchToHome(tester);

      expect(find.text('Belum dicek'), findsOneWidget);
    },
  );

  testWidgets('Home carousel stays on its slide until the user changes it', (
    tester,
  ) async {
    await launchToHome(tester);
    await reveal(tester, find.text('OtoKu OBD-II Scanner'));

    await tester.pump(const Duration(seconds: 5));
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('OtoKu OBD-II Scanner'), findsOneWidget);
  });

  testWidgets('OBD demo clearly identifies simulated vehicle information', (
    tester,
  ) async {
    await launchToHome(tester);

    await reveal(tester, find.text('OtoKu OBD-II Scanner'));
    await tester.tap(find.text('Lihat'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Lihat simulasi OBD'));
    await tester.pumpAndSettle();

    expect(find.text('OBD Demo Aktif'), findsOneWidget);
    expect(find.text('Data OBD Demo'), findsOneWidget);
    expect(
      find.text('Data simulasi — bukan data kendaraan langsung'),
      findsOneWidget,
    );
    await reveal(tester, find.text('64'));
    expect(find.text('64'), findsOneWidget);
  });
}
