import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:otoku/main.dart';

void main() {
  testWidgets('OtoKu opens its prototype shell', (tester) async {
    await tester.pumpWidget(const OtoKuApp());
    await tester.pump(const Duration(milliseconds: 1200));
    await tester.pumpAndSettle();
    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Honda Beat 2021'), findsOneWidget);
    expect(find.text('Hubungkan OBD'), findsOneWidget);
  });

  testWidgets('OBD connection reveals live vehicle information', (
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
    await tester.tap(find.text('Lihat OBD OtoKu'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Hubungkan OBD'));
    await tester.pumpAndSettle();

    expect(find.text('OBD OtoKu Terhubung'), findsOneWidget);
    expect(find.text('Data Kendaraan (Real-time)'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('64'),
      160,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('64'), findsOneWidget);
  });
}
