import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/widgets/eteelo_text_input.dart';

Future<TextEditingController> _pumpAndType(
  WidgetTester tester,
  String text, {
  EteeloTextInputType keyboardType = EteeloTextInputType.text,
  EteeloTextCapitalization capitalization = EteeloTextCapitalization.auto,
  List<TextInputFormatter>? inputFormatters,
  int maxLines = 1,
}) async {
  final controller = TextEditingController();
  addTearDown(controller.dispose);

  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: EteeloTextInput(
          controller: controller,
          label: 'Champ',
          keyboardType: keyboardType,
          capitalization: capitalization,
          inputFormatters: inputFormatters,
          maxLines: maxLines,
        ),
      ),
    ),
  );

  await tester.enterText(find.byType(TextField), text);
  await tester.pump();
  return controller;
}

void main() {
  testWidgets('par défaut, un champ texte capitalise chaque mot', (
    tester,
  ) async {
    final controller = await _pumpAndType(tester, 'daniel kabongo');
    expect(controller.text, 'Daniel Kabongo');
  });

  testWidgets('un champ multiligne ne capitalise que la première lettre', (
    tester,
  ) async {
    final controller = await _pumpAndType(
      tester,
      'absence non justifiée',
      keyboardType: EteeloTextInputType.multiline,
      maxLines: 3,
    );
    expect(controller.text, 'Absence non justifiée');
  });

  testWidgets('une hauteur > 1 ligne suffit à basculer en phrase', (
    tester,
  ) async {
    // Sans `keyboardType: multiline` : c'est la forme du champ qui décide, pas
    // la déclaration que l'appelant a pu oublier.
    final controller = await _pumpAndType(
      tester,
      'absence non justifiée',
      maxLines: 4,
    );
    expect(controller.text, 'Absence non justifiée');
  });

  for (final type in const [
    EteeloTextInputType.email,
    EteeloTextInputType.phone,
    EteeloTextInputType.number,
  ]) {
    testWidgets('un champ $type ne capitalise rien', (tester) async {
      final controller = await _pumpAndType(
        tester,
        'daniel kabongo',
        keyboardType: type,
      );
      expect(controller.text, 'daniel kabongo');
    });
  }

  testWidgets('l\'exception se déclare : capitalization none n\'écrit rien', (
    tester,
  ) async {
    final controller = await _pumpAndType(
      tester,
      'code-barres abc',
      capitalization: EteeloTextCapitalization.none,
    );
    expect(controller.text, 'code-barres abc');
  });

  testWidgets('les formatters de l\'appelant survivent à la capitalisation', (
    tester,
  ) async {
    final controller = await _pumpAndType(
      tester,
      'daniel kabongo',
      inputFormatters: [FilteringTextInputFormatter.deny(RegExp(r'\s'))],
    );
    // Le filtrage passe d'abord, la capitalisation s'applique au résultat.
    expect(controller.text, 'Danielkabongo');
  });

  testWidgets('la règle est portée au clavier logiciel', (tester) async {
    final controller = TextEditingController();
    final emailController = TextEditingController();
    addTearDown(controller.dispose);
    addTearDown(emailController.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              EteeloTextInput(controller: controller, label: 'Identité'),
              EteeloTextInput(
                controller: emailController,
                label: 'Email',
                keyboardType: EteeloTextInputType.email,
              ),
            ],
          ),
        ),
      ),
    );

    final fields = tester
        .widgetList<TextField>(find.byType(TextField))
        .toList(growable: false);
    expect(fields[0].textCapitalization, TextCapitalization.words);
    expect(fields[1].textCapitalization, TextCapitalization.none);
  });
}
