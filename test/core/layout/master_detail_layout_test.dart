import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/layout/master_detail_layout.dart';

/// [MasterDetailLayout] ne décide pas de sa forme : la page ne le pose que
/// lorsque la largeur reçue porte la liste ET la fiche (Facturation,
/// Journal, Communiqués mesurent avant de l'appeler), et pousse la fiche en
/// page entière en deçà. Le test le pose donc sur un poste — sur un
/// téléphone, ses 440 dp de liste débordaient : un artefact du harnais, pas
/// un défaut (la sonde 360×740 l'avait relevé deux fois).
void main() {
  Future<void> pump(WidgetTester tester, VoidCallback? onClose) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1440, 900);
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MasterDetailLayout(
            master: const TextField(),
            detail: const Text('fiche'),
            onCloseDetail: onClose,
          ),
        ),
      ),
    );
  }

  testWidgets('Échap referme la fiche ouverte', (tester) async {
    var closed = 0;
    await pump(tester, () => closed++);
    await tester.tap(find.byType(TextField));
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    expect(closed, 1);
  });

  testWidgets('rien d\'ouvert : Échap ne fait rien', (tester) async {
    await pump(tester, null);
    await tester.tap(find.byType(TextField));
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    expect(find.text('fiche'), findsOneWidget);
  });
}
