import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/components/tables/eteelo_column_rule.dart';
import 'package:school_app_flutter/core/components/tables/eteelo_column_table.dart';

void main() {
  Future<void> pump(
    WidgetTester tester, {
    int? ruleAfter,
    bool raised = false,
  }) => tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: SizedBox(
          width: 600,
          child: _Host(ruleAfter: ruleAfter, raised: raised),
        ),
      ),
    ),
  );

  testWidgets('le filet écarte les deux cellules qui le bordent', (
    tester,
  ) async {
    await pump(tester, ruleAfter: 1);

    // La cellule « 12 » finit à 8 dp du filet ; « RAS » part 8 dp après lui.
    final amount = tester.getRect(find.text('12'));
    final note = tester.getRect(find.text('RAS'));
    final rule = tester.widget<EteeloColumnRule>(find.byType(EteeloColumnRule));
    expect(rule.after, 1);
    expect(note.left - amount.right, greaterThanOrEqualTo(16));
    expect(find.byType(CustomPaint), findsWidgets);
  });

  testWidgets('sans filet, aucune portée ni écart', (tester) async {
    await pump(tester);
    expect(find.byType(EteeloColumnRule), findsNothing);
  });

  testWidgets('le tableau mis en avant pose une carte ombrée', (tester) async {
    await pump(tester, raised: true);
    final boxes = tester.widgetList<DecoratedBox>(find.byType(DecoratedBox));
    expect(
      boxes.any(
        (box) =>
            box.decoration is BoxDecoration &&
            ((box.decoration as BoxDecoration).boxShadow?.isNotEmpty ?? false),
      ),
      isTrue,
    );
  });
}

/// Un tableau de trois colonnes : l'agent, un montant aligné à droite, une
/// note.
class _Host extends StatelessWidget {
  final int? ruleAfter;
  final bool raised;

  const _Host({required this.ruleAfter, required this.raised});

  @override
  Widget build(BuildContext context) => EteeloColumnTable(
    minWidth: 400,
    widths: _widths,
    headers: const ['Agent', 'Net', 'Pointage'],
    endAligned: const {1},
    ruleAfter: ruleAfter,
    raised: raised,
    rowCount: 1,
    row: (context, _) => const EteeloColumnTableRow(
      widths: _widths,
      cells: [
        Text('Ruth'),
        Text('12', textAlign: TextAlign.end),
        Text('RAS'),
      ],
    ),
  );

  static const _widths = <double?>[null, 100, 100];
}
