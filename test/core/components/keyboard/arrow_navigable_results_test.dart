import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/components/keyboard/arrow_navigable_results.dart';

/// Les résultats d'une modale de recherche se parcourent aux flèches.
void main() {
  late FocusNode anchor;
  late List<String> chosen;

  setUp(() {
    anchor = FocusNode();
    chosen = [];
  });

  tearDown(() => anchor.dispose());

  Future<void> pump(WidgetTester tester, List<String> results) =>
      tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SearchToResultsShortcut(
              anchor: anchor,
              child: Column(
                children: [
                  const TextField(key: Key('field')),
                  ArrowNavigableResults(
                    anchor: anchor,
                    child: Column(
                      children: [
                        for (final name in results)
                          InkWell(
                            key: Key(name),
                            onTap: () => chosen.add(name),
                            child: SizedBox(height: 48, child: Text(name)),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

  bool focused(WidgetTester tester, String key) =>
      Focus.of(tester.element(find.text(key))).hasPrimaryFocus;

  bool fieldFocused(WidgetTester tester) => tester
      .widget<EditableText>(
        find.descendant(
          of: find.byKey(const Key('field')),
          matching: find.byType(EditableText),
        ),
      )
      .focusNode
      .hasFocus;

  Future<void> press(WidgetTester tester, LogicalKeyboardKey key) async {
    await tester.sendKeyEvent(key);
    await tester.pump();
  }

  testWidgets('↓ depuis le champ descend sur la première ligne, Entrée la '
      'choisit', (tester) async {
    await pump(tester, ['Mbuyi', 'Kabila', 'Lukusa']);
    await tester.tap(find.byKey(const Key('field')));
    await tester.pump();

    await press(tester, LogicalKeyboardKey.arrowDown);
    expect(focused(tester, 'Mbuyi'), isTrue);

    await press(tester, LogicalKeyboardKey.arrowDown);
    expect(focused(tester, 'Kabila'), isTrue);

    await press(tester, LogicalKeyboardKey.enter);
    expect(chosen, ['Kabila']);
  });

  testWidgets('↑ depuis la première ligne remonte au champ', (tester) async {
    await pump(tester, ['Mbuyi', 'Kabila']);
    await tester.tap(find.byKey(const Key('field')));
    await tester.pump();

    await press(tester, LogicalKeyboardKey.arrowDown);
    await press(tester, LogicalKeyboardKey.arrowUp);
    expect(fieldFocused(tester), isTrue);
  });

  testWidgets('sans résultat, ↓ reste au champ', (tester) async {
    await pump(tester, const []);
    await tester.tap(find.byKey(const Key('field')));
    await tester.pump();

    await press(tester, LogicalKeyboardKey.arrowDown);
    expect(fieldFocused(tester), isTrue);
  });
}
