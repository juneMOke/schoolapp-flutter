import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/components/dialogs/eteelo_form_dialog.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';

/// Sur un téléphone, une modale de saisie prend tout l'écran : centrée, elle
/// laissait ~230 dp de champ entre ses marges.
void main() {
  Future<Rect> fieldRect(WidgetTester tester, Size screen) async {
    tester.view.physicalSize = screen;
    tester.view.devicePixelRatio = 1;
    tester.view.padding = const FakeViewPadding(top: 24, bottom: 24);
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () => EteeloFormDialog.show<void>(
              context,
              EteeloFormDialog(
                title: 'Avance',
                body: const TextField(key: Key('champ')),
                actions: [
                  FilledButton(onPressed: () {}, child: const Text('OK')),
                ],
              ),
            ),
            child: const Text('ouvrir'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('ouvrir'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    return tester.getRect(find.byKey(const Key('champ')));
  }

  testWidgets('téléphone : plein écran, sous les barres système', (
    tester,
  ) async {
    final field = await fieldRect(tester, const Size(360, 740));

    expect(field.width, greaterThan(300));
    expect(field.top, greaterThan(24));
  });

  testWidgets('grand écran : modale centrée, à sa largeur', (tester) async {
    final field = await fieldRect(tester, const Size(1280, 800));

    expect(field.width, lessThan(AppDimensions.formDialogMaxWidth));
    expect(field.left, greaterThan(200));
  });

  testWidgets('téléphone : la modale couvre aussi les bandes système', (
    tester,
  ) async {
    await fieldRect(tester, const Size(360, 740));

    // Sous le `SafeArea` de la route, la page assombrie restait visible en
    // haut et en bas ; la modale pose le sien, à l'intérieur.
    expect(tester.getSize(find.byType(Dialog)), const Size(360, 740));
  });
}
