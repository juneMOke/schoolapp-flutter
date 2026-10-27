import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/components/dialogs/eteelo_dialog_actions.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';

/// Le pied d'une modale carte : côte à côte en largeur, empilé en étroit,
/// l'action principale toujours la plus en vue.
void main() {
  Future<void> pump(WidgetTester tester, double width) => tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Center(
          child: SizedBox(
            width: width,
            child: EteeloDialogActions(
              actions: [
                ElevatedButton(onPressed: () {}, child: const Text('Annuler')),
                ElevatedButton(onPressed: () {}, child: const Text('Valider')),
              ],
            ),
          ),
        ),
      ),
    ),
  );

  testWidgets('en largeur : côte à côte, la principale à droite', (
    tester,
  ) async {
    await pump(tester, AppDimensions.dialogActionsStackBelow + 100);

    final cancel = tester.getCenter(find.text('Annuler'));
    final validate = tester.getCenter(find.text('Valider'));
    expect(cancel.dy, validate.dy);
    expect(validate.dx, greaterThan(cancel.dx));
  });

  testWidgets('en étroit : empilées, la principale en tête', (tester) async {
    await pump(tester, AppDimensions.dialogActionsStackBelow - 100);

    final cancel = tester.getCenter(find.text('Annuler'));
    final validate = tester.getCenter(find.text('Valider'));
    expect(validate.dy, lessThan(cancel.dy));
  });
}
