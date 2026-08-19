import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/components/dialogs/eteelo_dialog_body.dart';

/// Le socle des modales à saisie : il doit ancrer l'en-tête et le pied quand la
/// place le permet, tout faire défiler quand elle manque — et, dans les DEUX
/// sens, DÉPLACER les zones au lieu de les recréer, faute de quoi le champ
/// focalisé perd son `FocusNode` et le clavier se referme (défaut H-1).
void main() {
  /// Le pied : deux bandeaux, dont le dernier sert de repère de position.
  const cleDernierPied = Key('pied-bas');

  Widget sujet({
    required double hauteurOfferte,
    double seuil = 360,
    double hauteurCorps = 0,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: Align(
          alignment: Alignment.topLeft,
          child: SizedBox(
            width: 400,
            height: hauteurOfferte,
            child: EteeloDialogBody(
              minPinnedHeight: seuil,
              header: Container(height: 90, color: Colors.blue),
              headerDividers: const [Divider(height: 2)],
              bodyPadding: const EdgeInsets.all(16),
              body: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const TextField(
                    decoration: InputDecoration(labelText: 'Montant'),
                  ),
                  SizedBox(height: hauteurCorps),
                ],
              ),
              footer: [
                Container(height: 60, color: Colors.red),
                Container(key: cleDernierPied, height: 60, color: Colors.amber),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Finder dansUnDefilement(Finder cible) =>
      find.ancestor(of: cible, matching: find.byType(SingleChildScrollView));

  testWidgets('contenu court : la modale reste compacte, le pied la termine', (
    tester,
  ) async {
    await tester.pumpWidget(sujet(hauteurOfferte: 500));

    expect(tester.takeException(), isNull);

    // La modale ne s'étire pas jusqu'aux 500 dp offerts : elle garde sa hauteur
    // naturelle. C'est ce qu'un `Column(mainAxisSize.min)` doit préserver — une
    // modale courte ne doit pas devenir une pleine page.
    final basDuPied = tester.getBottomLeft(find.byKey(cleDernierPied)).dy;
    expect(basDuPied, lessThan(500));
    expect(basDuPied, moreOrLessEquals(300, epsilon: 1));
  });

  testWidgets('corps débordant : le pied reste ancré au bas de l\'espace '
      'offert, hors du défilement', (tester) async {
    await tester.pumpWidget(sujet(hauteurOfferte: 500, hauteurCorps: 1200));

    expect(tester.takeException(), isNull);

    // Le corps déborde, donc la modale occupe tout : le pied touche le bas.
    expect(
      tester.getBottomLeft(find.byKey(cleDernierPied)).dy,
      moreOrLessEquals(500, epsilon: 0.5),
    );
    // Et il est ANCRÉ : seul le corps défile sous lui.
    expect(dansUnDefilement(find.byKey(cleDernierPied)), findsNothing);
    expect(dansUnDefilement(find.byType(TextField)), findsOneWidget);
  });

  testWidgets('place insuffisante : tout défile, rien ne déborde', (
    tester,
  ) async {
    // 120 dp : ce qu'il reste à une modale sur un téléphone en paysage clavier
    // ouvert. Les zones figées en réclament plus du double.
    await tester.pumpWidget(sujet(hauteurOfferte: 120));

    expect(
      tester.takeException(),
      isNull,
      reason: 'les zones figées doivent rejoindre le défilement, pas déborder',
    );
    // Un seul défilement, et il porte AUSSI le pied : c'est ce qui distingue
    // cette disposition de l'autre.
    expect(find.byType(SingleChildScrollView), findsOneWidget);
    expect(dansUnDefilement(find.byKey(cleDernierPied)), findsOneWidget);
  });

  testWidgets('la bascule DÉPLACE les zones : le champ garde son focus et son '
      'contenu', (tester) async {
    await tester.pumpWidget(sujet(hauteurOfferte: 500));

    await tester.enterText(find.byType(TextField), '4200');
    await tester.pump();
    final champ = tester.state<EditableTextState>(find.byType(EditableText));
    expect(champ.widget.focusNode.hasFocus, isTrue);

    // Le clavier monte : la hauteur offerte passe sous le seuil.
    await tester.pumpWidget(sujet(hauteurOfferte: 120));
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(
      find.text('4200'),
      findsOneWidget,
      reason: 'un champ recréé aurait perdu sa saisie',
    );
    expect(
      tester.state<EditableTextState>(find.byType(EditableText)),
      same(champ),
      reason: 'le State doit survivre au déplacement, pas être reconstruit',
    );
    expect(
      champ.widget.focusNode.hasFocus,
      isTrue,
      reason: 'un FocusNode détruit refermerait le clavier — boucle H-1',
    );

    // Et le chemin de retour, qui est celui qui rouvrait la boucle.
    await tester.pumpWidget(sujet(hauteurOfferte: 500));
    await tester.pump();
    expect(tester.takeException(), isNull);
    expect(
      tester.state<EditableTextState>(find.byType(EditableText)),
      same(champ),
    );
    expect(champ.widget.focusNode.hasFocus, isTrue);
  });

  testWidgets(
    'hauteur non bornée : bascule en défilement plutôt que de rompre',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: SizedBox(
                width: 400,
                child: EteeloDialogBody(
                  header: Container(height: 90, color: Colors.blue),
                  body: const SizedBox(height: 200),
                  footer: [Container(height: 60, color: Colors.red)],
                ),
              ),
            ),
          ),
        ),
      );

      expect(
        tester.takeException(),
        isNull,
        reason: '`Flexible` sous une hauteur infinie romprait le layout',
      );
    },
  );
}
