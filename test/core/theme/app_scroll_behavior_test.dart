import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/theme/app_scroll_behavior.dart';

void main() {
  test('la souris sélectionne, elle ne fait pas glisser le contenu', () {
    const behavior = AppScrollBehavior();
    expect(behavior.dragDevices, isNot(contains(PointerDeviceKind.mouse)));
    expect(
      behavior.dragDevices,
      containsAll([
        PointerDeviceKind.touch,
        PointerDeviceKind.stylus,
        PointerDeviceKind.trackpad,
      ]),
    );
  });

  _horizontalScrollbar();
  _verticalScrollbar();
}

// Barre verticale : à la souris, elle seule dit que la page continue sous le
// bord de la fenêtre — elle reste donc affichée sur bureau.
void _verticalScrollbar() {
  Future<void> pumpTall(WidgetTester tester) => tester.pumpWidget(
    const MaterialApp(
      scrollBehavior: AppScrollBehavior(),
      home: Scaffold(
        body: SingleChildScrollView(child: SizedBox(height: 3000)),
      ),
    ),
  );

  testWidgets('bureau : la barre verticale reste affichée', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.windows;
    await pumpTall(tester);
    final scrollbar = tester.widget<Scrollbar>(find.byType(Scrollbar));
    expect(scrollbar.thumbVisibility, isTrue);
    debugDefaultTargetPlatformOverride = null;
  });

  testWidgets('tablette : aucune barre verticale', (tester) async {
    await pumpTall(tester);
    expect(find.byType(Scrollbar), findsNothing);
  });
}

// Barre horizontale : sans elle, la souris n'a aucune prise sur les colonnes
// cachées d'un tableau large (le glisser souris est retiré ci-dessus).
void _horizontalScrollbar() {
  Future<ScrollController> pumpWide(WidgetTester tester) async {
    final controller = ScrollController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      MaterialApp(
        scrollBehavior: const AppScrollBehavior(),
        home: Scaffold(
          body: SingleChildScrollView(
            controller: controller,
            scrollDirection: Axis.horizontal,
            child: const SizedBox(width: 3000, height: 200),
          ),
        ),
      ),
    );
    return controller;
  }

  testWidgets('bureau : une barre horizontale est posée sur le défilement', (
    tester,
  ) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.linux;
    final controller = await pumpWide(tester);
    // La barre tient le contrôleur du défilement : c'est elle que la souris
    // saisit (thème `scrollbarTheme.interactive`).
    final scrollbar = tester.widget<Scrollbar>(find.byType(Scrollbar));
    expect(scrollbar.controller, same(controller));
    debugDefaultTargetPlatformOverride = null;
  });

  testWidgets('tablette : aucune barre ajoutée', (tester) async {
    await pumpWide(tester);
    expect(find.byType(Scrollbar), findsNothing);
  });
}
