import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/components/tables/data_table_tone.dart';
import 'package:school_app_flutter/core/components/tables/eteelo_column_table.dart';
import 'package:school_app_flutter/core/components/tables/eteelo_column_table_cards.dart';

const _tone = DataTableTone(
  header: Color(0xFF203040),
  headerInk: Color(0xFFF8F0E9),
  headerInkSorted: Color(0xFFFAFAF7),
  zebra: Color(0xFFF3EEEA),
  border: Color(0xFFDDCCBB),
);

const _widths = <double?>[null, 100];

Widget _table({double width = 800}) => MaterialApp(
  home: Scaffold(
    body: SizedBox(
      width: width,
      child: SingleChildScrollView(
        child: EteeloColumnTable(
          minWidth: 300,
          widths: _widths,
          headers: const ['Agent', 'Net'],
          tone: _tone,
          cardsBelow: 600,
          rowCount: 3,
          row: (context, index) => EteeloColumnTableRow(
            widths: _widths,
            onTap: () {},
            cells: [Text('Agent $index'), Text('${index * 10} \$')],
          ),
          footer: const Column(
            children: [
              EteeloColumnTableRow(
                widths: _widths,
                cells: [Text('Total · USD'), Text('30 \$')],
              ),
            ],
          ),
        ),
      ),
    ),
  ),
);

Color? _materialColorAbove(WidgetTester tester, String text) => tester
    .widget<Material>(
      find.ancestor(of: find.text(text), matching: find.byType(Material)).first,
    )
    .color;

void main() {
  testWidgets('teinté : bandeau d en-tête plein, encre crème, zébrure', (
    tester,
  ) async {
    await tester.pumpWidget(_table());

    final header = tester.widget<Text>(find.text('AGENT'));
    expect(header.style?.color, _tone.headerInk);
    expect(_materialColorAbove(tester, 'Agent 0'), isNull);
    expect(_materialColorAbove(tester, 'Agent 1'), _tone.zebra);
    expect(_materialColorAbove(tester, 'Agent 2'), isNull);
    expect(find.byType(EteeloColumnTableCards), findsNothing);
  });

  testWidgets('sous le seuil : une carte par ligne et par total', (
    tester,
  ) async {
    await tester.pumpWidget(_table(width: 360));

    expect(find.byType(EteeloColumnTableCards), findsOneWidget);
    expect(find.text('AGENT'), findsNothing);
    // Chaque cellule suivante est nommée par sa colonne.
    expect(find.text('Net'), findsNWidgets(4));
    expect(find.text('Total · USD'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('sans teinte ni seuil, rendu historique', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 360,
            child: EteeloColumnTable(
              minWidth: 300,
              widths: _widths,
              headers: const ['Agent', 'Net'],
              rowCount: 2,
              row: (context, index) => EteeloColumnTableRow(
                widths: _widths,
                cells: [Text('Agent $index'), const Text('1')],
              ),
            ),
          ),
        ),
      ),
    );

    expect(find.byType(EteeloColumnTableCards), findsNothing);
    expect(_materialColorAbove(tester, 'Agent 1'), isNull);
  });

  testWidgets('teinté : le tableau porte le cadre de sa teinte', (
    tester,
  ) async {
    await tester.pumpWidget(_table());

    final framed = tester.widgetList<DecoratedBox>(find.byType(DecoratedBox));
    expect(
      framed.any((box) {
        final decoration = box.decoration;
        return decoration is BoxDecoration &&
            decoration.border == Border.all(color: _tone.border);
      }),
      isTrue,
    );
  });

  testWidgets('en cartes, un intertitre de groupe reste un titre', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 360,
            child: EteeloColumnTable(
              minWidth: 300,
              widths: _widths,
              headers: const ['Agent', 'Net'],
              tone: _tone,
              cardsBelow: 600,
              rowCount: 2,
              row: (context, index) => EteeloColumnTableRow(
                widths: _widths,
                cells: index == 0
                    ? const [Text('Enseignants'), SizedBox.shrink()]
                    : const [Text('Agent 1'), Text('10 \$')],
              ),
            ),
          ),
        ),
      ),
    );

    expect(
      find.ancestor(
        of: find.text('Enseignants'),
        matching: find.byType(InkWell),
      ),
      findsNothing,
    );
    expect(
      find.ancestor(of: find.text('Agent 1'), matching: find.byType(InkWell)),
      findsOneWidget,
    );
  });
}
