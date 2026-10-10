import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:otoku/main.dart';

void main() {
  testWidgets('OtoKu opens its prototype shell', (tester) async {
    await tester.pumpWidget(const OtoKuApp());
    await tester.pump(const Duration(milliseconds: 1200));
    await tester.pumpAndSettle();
    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Shop'), findsOneWidget);
    expect(find.text('Peta'), findsOneWidget);
    expect(find.text('Honda Beat 2021'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Hubungkan OBD'),
      180,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Hubungkan OBD'), findsOneWidget);
    expect(find.text('Mode simulasi untuk prototipe'), findsOneWidget);
  });

  testWidgets('OBD demo clearly identifies simulated vehicle information', (
    tester,
  ) async {
    await tester.pumpWidget(const OtoKuApp());
    await tester.pump(const Duration(milliseconds: 1200));
    await tester.pumpAndSettle();

    await tester.drag(
      find.byType(CustomScrollView).first,
      const Offset(0, -260),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Lihat demo OBD'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Hubungkan OBD'));
    await tester.pumpAndSettle();

    expect(find.text('OBD Demo Aktif'), findsOneWidget);
    expect(find.text('Data OBD Demo'), findsOneWidget);
    expect(
      find.text('Data simulasi — bukan data kendaraan langsung'),
      findsOneWidget,
    );
    await tester.scrollUntilVisible(
      find.text('64'),
      160,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('64'), findsOneWidget);
  });
}
