import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/widgets/eteelo_text_input.dart';

void main() {
  group('EteeloTextInput', () {
    late TextEditingController controller;

    setUp(() {
      controller = TextEditingController();
    });

    tearDown(() {
      controller.dispose();
    });

    Future<void> pumpInput(
      WidgetTester tester, {
      bool required = false,
      bool readOnly = false,
      String? errorText,
      EteeloTextInputType keyboardType = EteeloTextInputType.text,
      int maxLines = 1,
    }) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 280,
              child: EteeloTextInput(
                controller: controller,
                label: 'Prenom',
                placeholder: 'Saisir le prenom',
                required: required,
                readOnly: readOnly,
                errorText: errorText,
                keyboardType: keyboardType,
                maxLines: maxLines,
              ),
            ),
          ),
        ),
      );
    }

    testWidgets('affiche le label et l asterisque si requis', (tester) async {
      await pumpInput(tester, required: true);

      expect(find.textContaining('Prenom'), findsOneWidget);
      expect(find.textContaining('*'), findsOneWidget);
    });

    testWidgets('compense le padding horizontal au focus', (tester) async {
      await pumpInput(tester);

      final containerBefore = tester.widget<AnimatedContainer>(
        find.byType(AnimatedContainer),
      );
      final paddingBefore = containerBefore.padding as EdgeInsets;
      expect(paddingBefore.left, 12);

      await tester.tap(find.byType(TextField));
      await tester.pumpAndSettle();

      final containerAfter = tester.widget<AnimatedContainer>(
        find.byType(AnimatedContainer),
      );
      final paddingAfter = containerAfter.padding as EdgeInsets;
      expect(paddingAfter.left, 11);
    });

    testWidgets('utilise un fond readonly specifique', (tester) async {
      await pumpInput(tester, readOnly: true);

      final container = tester.widget<AnimatedContainer>(
        find.byType(AnimatedContainer),
      );
      final decoration = container.decoration! as BoxDecoration;
      expect(decoration.color, isNotNull);
      expect(decoration.color, equals(const Color(0xFFF1EDE2)));
    });

    testWidgets('affiche le message d erreur sous le champ', (tester) async {
      await pumpInput(tester, errorText: 'Champ obligatoire');

      expect(find.text('Champ obligatoire'), findsOneWidget);
    });

    testWidgets('expose le champ avec un libelle semantique obligatoire', (
      tester,
    ) async {
      await pumpInput(tester, required: true);

      expect(find.bySemanticsLabel('Prenom, obligatoire'), findsOneWidget);
    });

    testWidgets('integre l erreur dans le hint semantique', (tester) async {
      await pumpInput(tester, errorText: 'Champ obligatoire');

      expect(
        tester.getSemantics(find.byType(TextField)),
        matchesSemantics(
          label: 'Prenom',
          hint: 'Saisir le prenom. Erreur: Champ obligatoire',
          isTextField: true,
          hasEnabledState: true,
          isEnabled: true,
          isFocusable: true,
          validationResult: SemanticsValidationResult.valid,
        ),
      );
    });
  });
}
