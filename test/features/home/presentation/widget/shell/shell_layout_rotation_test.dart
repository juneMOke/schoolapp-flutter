import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/features/home/presentation/pages/accueil_page.dart';

import '../../helpers/shell_harness.dart';

/// Tourner une 10" (1280 ↔ 800) fait passer la coquille de la barre latérale
/// au tiroir. Avant, c'étaient deux arbres distincts : l'écran était REMONTÉ,
/// et le brouillon de notes, le panier ou l'appel en cours se perdaient.
void main() {
  Future<void> resize(WidgetTester tester, Size size) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    await tester.pumpAndSettle();
  }

  testWidgets('l\'écran survit au passage barre latérale → tiroir → barre', (
    tester,
  ) async {
    addTearDown(tester.view.reset);
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1;
    await tester.pumpWidget(buildShellHarness());
    await tester.pumpAndSettle();
    final screen = tester.element(find.byType(AccueilPage));
    expect(find.byType(Drawer), findsNothing);
    expect(find.byTooltip('Ouvrir le menu'), findsNothing);

    await resize(tester, const Size(800, 1280));
    expect(find.byTooltip('Ouvrir le menu'), findsOneWidget);
    expect(tester.element(find.byType(AccueilPage)), same(screen));

    await resize(tester, const Size(1280, 800));
    expect(find.byTooltip('Ouvrir le menu'), findsNothing);
    expect(tester.element(find.byType(AccueilPage)), same(screen));
  });
}
