import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/components/tables/eteelo_column_table.dart';

/// Un livre plus large que l'écran défile de côté ; la colonne figée garde
/// l'agent à l'écran pendant que ses montants passent dessous.
void main() {
  const widths = <double?>[null, 200, 200, 200];

  Future<void> pump(
    WidgetTester tester, {
    required bool frozen,
    Widget agent = const Text('Mbuyi Jeanne'),
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 400,
            child: EteeloColumnTable(
              minWidth: 900,
              widths: widths,
              frozenFirstColumn: frozen,
              headers: const ['Agent', 'Base', 'Prime', 'Net'],
              rowCount: 1,
              row: (context, _) => EteeloColumnTableRow(
                widths: widths,
                onTap: () {},
                cells: [
                  agent,
                  const Text('100'),
                  const Text('20'),
                  const Text('120'),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> scrollBy(WidgetTester tester, double dx) async {
    await tester.drag(find.byType(SingleChildScrollView), Offset(-dx, 0));
    await tester.pumpAndSettle();
  }

  testWidgets('figée : l\'agent reste à gauche après le défilement', (
    tester,
  ) async {
    await pump(tester, frozen: true);
    final before = tester.getTopLeft(find.text('Mbuyi Jeanne')).dx;
    final net = tester.getTopLeft(find.text('120')).dx;

    await scrollBy(tester, 300);

    expect(tester.getTopLeft(find.text('Mbuyi Jeanne')).dx, before);
    expect(tester.getTopLeft(find.text('AGENT')).dx, lessThan(50));
    // Les montants, eux, ont défilé.
    expect(tester.getTopLeft(find.text('120')).dx, lessThan(net));
  });

  testWidgets('sans option : l\'agent part avec le reste', (tester) async {
    await pump(tester, frozen: false);
    final before = tester.getTopLeft(find.text('Mbuyi Jeanne')).dx;

    await scrollBy(tester, 300);

    expect(tester.getTopLeft(find.text('Mbuyi Jeanne')).dx, lessThan(before));
  });

  testWidgets('un agent sur deux lignes garde la hauteur de sa rangée', (
    tester,
  ) async {
    const agent = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [Text('Mbuyi Jeanne'), Text('Vacataire')],
    );
    await pump(tester, frozen: false, agent: agent);
    final free = tester.getSize(find.byType(EteeloColumnTableRow)).height;

    await tester.pumpWidget(const SizedBox());
    await pump(tester, frozen: true, agent: agent);

    expect(tester.takeException(), isNull);
    expect(tester.getSize(find.byType(EteeloColumnTableRow)).height, free);
  });

  testWidgets('rien ne transparaît dans la marge à gauche de l\'agent', (
    tester,
  ) async {
    await pump(tester, frozen: true);
    await scrollBy(tester, 300);

    final masks = find.descendant(
      of: find.byType(EteeloColumnTableRow),
      matching: find.byType(ColoredBox),
    );
    final left = tester
        .widgetList(masks)
        .map((w) => tester.getTopLeft(find.byWidget(w)).dx)
        .reduce((a, b) => a < b ? a : b);
    expect(left, lessThanOrEqualTo(0));
  });
}
