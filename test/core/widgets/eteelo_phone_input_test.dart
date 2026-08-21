import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/helpers/phone_number_format.dart';
import 'package:school_app_flutter/core/widgets/eteelo_phone_input.dart';

void main() {
  group('EteeloPhoneInput', () {
    late TextEditingController controller;

    setUp(() => controller = TextEditingController());
    tearDown(() => controller.dispose());

    // Le placeholder porte le même exemple que la valeur de test : on lit
    // donc la partie nationale dans le champ, pas via find.text.
    String nationalShown(WidgetTester tester) =>
        tester.widget<TextField>(find.byType(TextField)).controller!.text;

    Future<void> pumpInput(
      WidgetTester tester, {
      bool readOnly = false,
      String? errorText,
      ValueChanged<String>? onChanged,
    }) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 320,
              child: EteeloPhoneInput(
                controller: controller,
                label: 'Téléphone',
                required: true,
                readOnly: readOnly,
                errorText: errorText,
                onChanged: onChanged,
                dialCodeSemanticLabel: 'Indicatif pays',
              ),
            ),
          ),
        ),
      );
    }

    testWidgets('affiche l\'indicatif et l\'exemple en placeholder', (
      tester,
    ) async {
      await pumpInput(tester);

      expect(find.text('+243'), findsOneWidget);
      expect(find.text(PhoneCountry.congoDrc.flagEmoji), findsOneWidget);
      expect(
        find.text(PhoneCountry.congoDrc.exampleNationalNumber),
        findsOneWidget,
      );
    });

    testWidgets('une saisie nationale remplit le controller en E.164', (
      tester,
    ) async {
      String? emitted;
      await pumpInput(tester, onChanged: (value) => emitted = value);

      await tester.enterText(find.byType(TextField), '816939060');
      await tester.pump();

      expect(controller.text, '+243816939060');
      expect(emitted, '+243816939060');
    });

    testWidgets('un champ vidé ne laisse pas un indicatif orphelin', (
      tester,
    ) async {
      await pumpInput(tester);

      await tester.enterText(find.byType(TextField), '816939060');
      await tester.pump();
      await tester.enterText(find.byType(TextField), '');
      await tester.pump();

      expect(controller.text, isEmpty);
    });

    testWidgets('refuse les caractères non numériques et la surlongueur', (
      tester,
    ) async {
      await pumpInput(tester);

      await tester.enterText(find.byType(TextField), '+81a69 39-060999');
      await tester.pump();

      expect(nationalShown(tester), '816939060');
      expect(controller.text, '+243816939060');
    });

    testWidgets('affiche la partie nationale d\'une valeur E.164 initiale', (
      tester,
    ) async {
      controller.text = '+243816939060';
      await pumpInput(tester);

      expect(nationalShown(tester), '816939060');
    });

    testWidgets('comprend un format hérité sans réécrire le controller', (
      tester,
    ) async {
      controller.text = '0816939060';
      await pumpInput(tester);

      // La mise en forme est comprise à l'affichage...
      expect(nationalShown(tester), '816939060');
      // ...mais la valeur d'origine reste intacte : un formulaire juste
      // ouvert ne doit pas être vu comme modifié.
      expect(controller.text, '0816939060');
    });

    testWidgets('suit une réécriture externe du controller', (tester) async {
      await pumpInput(tester);

      controller.text = '+243999888777';
      await tester.pump();

      expect(find.text('999888777'), findsOneWidget);
    });

    testWidgets('affiche le message d\'erreur fourni', (tester) async {
      await pumpInput(tester, errorText: 'Numéro invalide');

      expect(find.text('Numéro invalide'), findsOneWidget);
    });

    testWidgets('reste lisible en lecture seule', (tester) async {
      controller.text = '+243816939060';
      await pumpInput(tester, readOnly: true);

      expect(find.text('+243'), findsOneWidget);
      expect(nationalShown(tester), '816939060');
      expect(tester.widget<TextField>(find.byType(TextField)).readOnly, isTrue);
    });

    testWidgets('le 0 du plan national saute au lieu de manger un chiffre', (
      tester,
    ) async {
      await pumpInput(tester);

      // Habitude congolaise : on tape le numéro avec son 0.
      await tester.enterText(find.byType(TextField), '0816939060');
      await tester.pump();

      expect(nationalShown(tester), '816939060');
      expect(controller.text, '+243816939060');
    });

    testWidgets('un numéro étranger n\'est ni tronqué ni recomposé', (
      tester,
    ) async {
      controller.text = '+32470123456';
      await pumpInput(tester);

      // Affiché entier, indicatif compris, avec la case en mode « autre pays ».
      expect(nationalShown(tester), '+32470123456');
      expect(find.text('+243'), findsNothing);
      expect(find.byIcon(Icons.public), findsOneWidget);

      // Une édition ne le rapatrie pas dans le plan congolais.
      await tester.enterText(find.byType(TextField), '+3247012345');
      await tester.pump();
      expect(controller.text, '+3247012345');
    });

    testWidgets('vider un numéro étranger rend la main au plan national', (
      tester,
    ) async {
      controller.text = '+32470123456';
      await pumpInput(tester);

      await tester.enterText(find.byType(TextField), '');
      await tester.pump();

      expect(controller.text, isEmpty);
      expect(find.text('+243'), findsOneWidget);

      await tester.enterText(find.byType(TextField), '816939060');
      await tester.pump();
      expect(controller.text, '+243816939060');
    });

    testWidgets('taper sur la case indicatif donne le focus au champ', (
      tester,
    ) async {
      await pumpInput(tester);
      expect(
        tester.widget<TextField>(find.byType(TextField)).focusNode?.hasFocus,
        isFalse,
      );

      await tester.tap(find.text('+243'));
      await tester.pump();

      expect(
        tester.widget<TextField>(find.byType(TextField)).focusNode?.hasFocus,
        isTrue,
      );
    });

    testWidgets('la case reste annoncée quand aucun libellé n\'est fourni', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EteeloPhoneInput(controller: controller, label: 'Téléphone'),
          ),
        ),
      );

      // Sans libellé de remplacement, le contenu de la case reste lisible.
      expect(find.text('+243'), findsOneWidget);
    });
  });
}
