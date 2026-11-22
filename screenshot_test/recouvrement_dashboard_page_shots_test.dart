// Captures de la PAGE entière du tableau de bord du Recouvrement v2 — HORS CI.
//
//   flutter test screenshot_test/recouvrement_dashboard_page_shots_test.dart \
//     --update-goldens
//
// Les PNG s'écrivent sous `screenshot_test/goldens/` (non versionnés).
import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../test/features/recouvrement/fixtures/recovery_fixtures.dart';
import '../test/features/recouvrement/presentation/pages/recouvrement_dashboard_page_harness.dart';
import 'recouvrement_shots.dart';

void main() {
  setUpAll(() async {
    DashboardHarness.registerFallbacks();
    await loadRealFonts();
  });
  late DashboardHarness h;
  setUp(() {
    h = DashboardHarness()..setUp();
    h.stubDashboard((_) => Right(recoveryDashboardFixture()));
  });
  tearDown(() => h.tearDown());

  for (final (w, hgt) in [(1280.0, 5200.0), (800.0, 6400.0), (360.0, 9800.0)]) {
    testWidgets('page $w', (tester) async {
      await h.pump(tester, size: Size(w, hgt));
      await expectLater(
        find.byType(Scaffold).first,
        matchesGoldenFile('goldens/dashboard_page_${w.toInt()}.png'),
      );
    });
  }
}
