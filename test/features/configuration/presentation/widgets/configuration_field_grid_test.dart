import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/features/configuration/presentation/widgets/configuration_field_grid.dart';

void main() {
  Future<double> fieldWidth(WidgetTester tester, double boxWidth) async {
    tester.view.physicalSize = const Size(1600, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        home: Center(
          child: SizedBox(
            width: boxWidth,
            child: const ConfigurationFieldGrid(
              wideColumns: 4,
              children: [
                SizedBox(key: Key('a'), height: 10),
                SizedBox(height: 10),
                SizedBox(height: 10),
                SizedBox(height: 10),
              ],
            ),
          ),
        ),
      ),
    );
    return tester.getSize(find.byKey(const Key('a'))).width;
  }

  testWidgets(
    'sur grand écran, une boîte étroite garde une colonne pleine largeur',
    (tester) async {
      expect(await fieldWidth(tester, 500), 500);
    },
  );

  testWidgets('la boîte large prend les colonnes demandées', (tester) async {
    expect(await fieldWidth(tester, 1000), lessThan(1000 / 3));
  });
}
