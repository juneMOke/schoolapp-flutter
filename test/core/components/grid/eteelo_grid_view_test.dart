import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/components/grid/eteelo_grid_view.dart';

void main() {
  Widget buildHarness({required double width, required Widget child}) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: SizedBox(width: width, child: child),
        ),
      ),
    );
  }

  testWidgets('répartit les items sur plusieurs colonnes selon la largeur', (
    tester,
  ) async {
    await tester.pumpWidget(
      buildHarness(
        width: 760, // ~2 colonnes pour maxExtent 360
        child: EteeloGridView(
          itemCount: 2,
          itemBuilder: (context, index) =>
              SizedBox(height: 80, child: Text('$index')),
        ),
      ),
    );

    final firstTopLeft = tester.getTopLeft(find.text('0'));
    final secondTopLeft = tester.getTopLeft(find.text('1'));

    // Deux colonnes : même ligne (dy égal), colonnes différentes (dx croissant).
    expect(secondTopLeft.dy, firstTopLeft.dy);
    expect(secondTopLeft.dx, greaterThan(firstTopLeft.dx));
  });

  testWidgets('passe en une seule colonne sous 360px', (tester) async {
    await tester.pumpWidget(
      buildHarness(
        width: 350,
        child: EteeloGridView(
          itemCount: 2,
          itemBuilder: (context, index) =>
              SizedBox(height: 100, child: Text('$index')),
        ),
      ),
    );

    final firstTopLeft = tester.getTopLeft(find.text('0'));
    final secondTopLeft = tester.getTopLeft(find.text('1'));

    expect(secondTopLeft.dx, firstTopLeft.dx);
    expect(secondTopLeft.dy, greaterThan(firstTopLeft.dy));
  });

  testWidgets('état vide ne rend aucun item', (tester) async {
    await tester.pumpWidget(
      buildHarness(
        width: 400,
        child: EteeloGridView(
          itemCount: 0,
          itemBuilder: (context, index) => const Text('x'),
        ),
      ),
    );

    expect(find.text('x'), findsNothing);
  });
}
