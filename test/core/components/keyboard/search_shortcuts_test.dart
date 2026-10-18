import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/components/keyboard/search_shortcuts.dart';

/// Ctrl+F, « / » et Échap sur la recherche d'un écran.
void main() {
  late TextEditingController search;
  late List<String> changes;
  late int escapesAbove;

  setUp(() {
    search = TextEditingController();
    changes = [];
    escapesAbove = 0;
  });

  tearDown(() => search.dispose());

  Future<void> pump(WidgetTester tester, {bool visible = true}) =>
      tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: CallbackShortcuts(
                // Ce que ferait la modale ou l'écran autour : fermer.
                bindings: {
                  const SingleActivator(LogicalKeyboardKey.escape): () =>
                      escapesAbove++,
                },
                child: Column(
                  children: [
                    TextField(key: const Key('other')),
                    TickerMode(
                      enabled: visible,
                      child: SearchFocusShortcut(
                        child: ClearOnEscape(
                          controller: search,
                          onCleared: changes.add,
                          child: TextField(
                            key: const Key('search'),
                            controller: search,
                          ),
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () => showDialog<void>(
                        context: context,
                        builder: (_) => const Dialog(child: Text('modale')),
                      ),
                      child: const Text('ouvrir'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );

  Future<void> ctrlF(WidgetTester tester) async {
    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyF);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await tester.pump();
  }

  Future<void> slash(WidgetTester tester) async {
    await tester.sendKeyDownEvent(LogicalKeyboardKey.slash, character: '/');
    await tester.sendKeyUpEvent(LogicalKeyboardKey.slash);
    await tester.pump();
  }

  bool primaryIsIn(WidgetTester tester, String key) {
    final primary = FocusManager.instance.primaryFocus?.context;
    if (primary == null) return false;
    final field = tester.element(find.byKey(Key(key)));
    var found = false;
    primary.visitAncestorElements((element) {
      if (element == field) found = true;
      return !found;
    });
    return found;
  }

  testWidgets(
    'Ctrl+F place le curseur dans la recherche, sans focus préalable',
    (tester) async {
      await pump(tester);
      await ctrlF(tester);
      expect(primaryIsIn(tester, 'search'), isTrue);
    },
  );

  testWidgets('Ctrl+F sélectionne la recherche précédente', (tester) async {
    search.text = 'Kabongo';
    await pump(tester);
    await ctrlF(tester);
    expect(
      search.selection,
      const TextSelection(baseOffset: 0, extentOffset: 7),
    );
  });

  testWidgets('« / » rejoint la recherche quand on ne tape pas', (
    tester,
  ) async {
    await pump(tester);
    await slash(tester);
    expect(primaryIsIn(tester, 'search'), isTrue);
  });

  testWidgets('« / » tapé dans un autre champ reste dans ce champ', (
    tester,
  ) async {
    await pump(tester);
    await tester.tap(find.byKey(const Key('other')));
    await tester.pump();
    await slash(tester);
    expect(primaryIsIn(tester, 'other'), isTrue);
  });

  testWidgets('une modale ouverte par-dessus garde Ctrl+F', (tester) async {
    await pump(tester);
    await tester.tap(find.text('ouvrir'));
    await tester.pumpAndSettle();
    await ctrlF(tester);
    expect(primaryIsIn(tester, 'search'), isFalse);
  });

  testWidgets('un écran hors champ ne répond pas', (tester) async {
    await pump(tester, visible: false);
    await ctrlF(tester);
    expect(primaryIsIn(tester, 'search'), isFalse);
  });

  testWidgets('Échap vide la recherche et prévient le filtre', (tester) async {
    await pump(tester);
    await tester.enterText(find.byKey(const Key('search')), 'kab');
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pump();

    expect(search.text, isEmpty);
    expect(changes, ['']);
    expect(escapesAbove, 0, reason: 'la touche est consommée');
    expect(primaryIsIn(tester, 'search'), isTrue);
  });

  testWidgets('Échap sur une recherche vide garde son sens ordinaire', (
    tester,
  ) async {
    await pump(tester);
    await tester.tap(find.byKey(const Key('search')));
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pump();

    expect(changes, isEmpty);
    expect(escapesAbove, 1);
  });
}
