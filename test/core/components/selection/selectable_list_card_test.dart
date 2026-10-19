import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/components/selection/selectable_list_card.dart';

void main() {
  Future<List<String>> pump(WidgetTester tester, int count) async {
    final chosen = <String>[];
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: SelectableListCard(
              title: 'Professeurs',
              filterLabel: 'Filtrer',
              selectedId: 'p1',
              items: [
                for (var i = 0; i < count; i++)
                  SelectableListItem(id: 'p$i', label: 'Élève $i'),
              ],
              onSelected: chosen.add,
            ),
          ),
        ),
      ),
    );
    return chosen;
  }

  testWidgets('courte, pas de filtre ; un clic choisit', (tester) async {
    final chosen = await pump(tester, 3);
    expect(find.byType(TextField), findsNothing);
    await tester.tap(find.text('Élève 2'));
    expect(chosen, ['p2']);
  });

  testWidgets('longue, un filtre qui ignore les accents', (tester) async {
    await pump(tester, 12);
    await tester.enterText(find.byType(TextField), 'eleve 11');
    await tester.pump();
    expect(find.text('Élève 11'), findsOneWidget);
    expect(find.text('Élève 2'), findsNothing);
  });

  testWidgets('l’élément ouvert est annoncé sélectionné', (tester) async {
    await pump(tester, 3);
    expect(
      tester.getSemantics(find.text('Élève 1')),
      isSemantics(isSelected: true, isButton: true),
    );
    expect(
      tester.getSemantics(find.text('Élève 2')),
      isSemantics(isSelected: false),
    );
  });

  testWidgets('au clavier : Tab puis Entrée', (tester) async {
    final chosen = await pump(tester, 3);
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    expect(chosen, ['p0']);
  });
}
