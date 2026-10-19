import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/features/home/presentation/pages/accueil_page.dart';

import '../../helpers/shell_harness.dart';

/// Tourner une 10" (1280 ↔ 800) ou partager l'écran fait changer la coquille
/// de forme (barre latérale, rail, tiroir). Avant, c'étaient deux arbres distincts : l'écran était REMONTÉ,
/// et le brouillon de notes, le panier ou l'appel en cours se perdaient.
void main() {
  Future<void> resize(WidgetTester tester, Size size) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    await tester.pumpAndSettle();
  }

  testWidgets('l\'écran survit aux trois formes de la coquille', (
    tester,
  ) async {
    addTearDown(tester.view.reset);
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1;
    await tester.pumpWidget(buildShellHarness());
    await tester.pumpAndSettle();
    final screen = tester.element(find.byType(AccueilPage));

    // 10" tournée en portrait : rail.
    await resize(tester, const Size(800, 1280));
    expect(find.byTooltip('Étendre le menu'), findsOneWidget);
    expect(tester.element(find.byType(AccueilPage)), same(screen));

    // Écran partagé, téléphone : tiroir.
    await resize(tester, const Size(600, 960));
    expect(find.byTooltip('Ouvrir le menu'), findsOneWidget);
    expect(tester.element(find.byType(AccueilPage)), same(screen));

    await resize(tester, const Size(1280, 800));
    expect(find.byTooltip('Ouvrir le menu'), findsNothing);
    expect(tester.element(find.byType(AccueilPage)), same(screen));
  });
}
