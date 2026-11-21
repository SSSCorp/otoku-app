import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:otoku/data/oto_ku_repository.dart';
import 'package:otoku/main.dart';
import 'package:otoku/screens/obd_screens.dart';
import 'package:otoku/services/app_services.dart';

import 'fakes.dart';

/// Pumps the app with fakes, skipping onboarding unless [onboarded] is false.
Future<AppServices> launch(
  WidgetTester tester, {
  MemoryOtoKuRepository? repository,
  AppServices? services,
  bool onboarded = true,
}) async {
  ObdSimulationTiming.scan = Duration.zero;
  ObdSimulationTiming.connect = Duration.zero;
  tester.view.physicalSize = const Size(800, 1500);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  final s = services ?? testServices();
  await tester.pumpWidget(
    OtoKuApp(
      repository:
          repository ?? MemoryOtoKuRepository(onboardingComplete: onboarded),
      services: s,
    ),
  );
  await tester.pump(const Duration(milliseconds: 1200));
  await tester.pumpAndSettle();
  return s;
}

Future<void> openTab(WidgetTester tester, String label) async {
  await tester.tap(
    find.descendant(of: find.byType(NavigationBar), matching: find.text(label)),
  );
  await tester.pumpAndSettle();
}

/// Scrolls the first scrollable until [finder] is visible and tappable.
Future<void> reveal(WidgetTester tester, Finder finder) async {
  await tester.scrollUntilVisible(
    finder,
    180,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
}

Future<void> tapText(WidgetTester tester, String text) async {
  final finder = find.text(text);
  await tester.ensureVisible(finder.first);
  await tester.pumpAndSettle();
  await tester.tap(finder.first);
  await tester.pumpAndSettle();
}

Future<void> back(WidgetTester tester) async {
  await tester.tap(find.byIcon(Icons.arrow_back).last);
  await tester.pumpAndSettle();
}
