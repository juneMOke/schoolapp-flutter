import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/widgets/eteelo_text_input.dart';

/// Au clavier physique, Entrée passe au champ suivant d'un formulaire.
///
/// Flutter, par défaut, rend le focus : sur un poste, Entrée au milieu d'un
/// formulaire laissait l'utilisateur sans curseur.
void main() {
  final controllers = <TextEditingController>[];

  tearDown(() {
    for (final c in controllers) {
      c.dispose();
    }
    controllers.clear();
  });

  Widget field({ValueChanged<String>? onSubmitted, int maxLines = 1}) {
    final controller = TextEditingController();
    controllers.add(controller);
    return EteeloTextInput(
      controller: controller,
      label: 'Champ',
      onSubmitted: onSubmitted,
      maxLines: maxLines,
    );
  }

  Future<TextInputAction?> actionOf(
    WidgetTester tester,
    Widget input, {
    TargetPlatform? platform,
  }) async {
    debugDefaultTargetPlatformOverride = platform;
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: input)));
    final action = tester
        .widget<TextField>(find.byType(TextField))
        .textInputAction;
    debugDefaultTargetPlatformOverride = null;
    return action;
  }

  testWidgets('poste de bureau : Entrée passe au champ suivant', (
    tester,
  ) async {
    expect(
      await actionOf(tester, field(), platform: TargetPlatform.linux),
      TextInputAction.next,
    );
  });

  testWidgets('un champ qui valide garde son action', (tester) async {
    expect(
      await actionOf(
        tester,
        field(onSubmitted: (_) {}),
        platform: TargetPlatform.windows,
      ),
      isNull,
    );
  });

  testWidgets('un champ multiligne garde son retour à la ligne', (
    tester,
  ) async {
    expect(
      await actionOf(
        tester,
        field(maxLines: 3),
        platform: TargetPlatform.linux,
      ),
      isNull,
    );
  });

  testWidgets('la tablette garde son clavier virtuel inchangé', (tester) async {
    expect(await actionOf(tester, field()), isNull);
  });

  testWidgets('Entrée, au bureau, déplace le focus au champ suivant', (
    tester,
  ) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.linux;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: Column(children: [field(), field()])),
      ),
    );
    await tester.showKeyboard(find.byType(TextField).first);
    await tester.testTextInput.receiveAction(TextInputAction.next);
    await tester.pump();
    final second = tester
        .widget<EditableText>(find.byType(EditableText).last)
        .focusNode
        .hasFocus;
    debugDefaultTargetPlatformOverride = null;

    expect(second, isTrue);
  });
}
