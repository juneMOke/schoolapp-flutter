import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/components/controls/eteelo_activatable.dart';
import 'package:school_app_flutter/core/components/tables/data_table_models.dart';
import 'package:school_app_flutter/core/components/tables/data_table_row_item.dart';

/// Une ligne de listing s'ouvre au clavier comme à la souris.
///
/// Toutes les tables partagées passent par [DataTableRowItem]. Tant que la
/// ligne n'était qu'un `GestureDetector`, Tab la sautait et seul l'œil de fin
/// de ligne était atteignable : un listing entier fermé au clavier.
void main() {
  Future<void> pumpRow(WidgetTester tester, {VoidCallback? onTap}) {
    return tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DataTableRowItem(
            row: DataTableRowSpec(
              id: 'r1',
              displayName: 'Mukendi Ilunga',
              cells: const [DataTableCellSpec(text: 'Mukendi Ilunga')],
              onTap: onTap,
            ),
            columns: const [DataTableColumnDef(label: 'Nom')],
            isEven: true,
          ),
        ),
      ),
    );
  }

  testWidgets('Tab atteint la ligne, Entrée l’ouvre', (tester) async {
    var opened = 0;
    await pumpRow(tester, onTap: () => opened++);

    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();

    expect(opened, 1);
  });

  testWidgets('Espace ouvre aussi la ligne', (tester) async {
    var opened = 0;
    await pumpRow(tester, onTap: () => opened++);

    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    await tester.pump();

    expect(opened, 1);
  });

  testWidgets('le clic ouvre toujours la ligne', (tester) async {
    var opened = 0;
    await pumpRow(tester, onTap: () => opened++);

    await tester.tap(find.text('Mukendi Ilunga'));
    await tester.pump();

    expect(opened, 1);
  });

  testWidgets('la ligne s’annonce comme un bouton nommé', (tester) async {
    final semantics = tester.ensureSemantics();
    await pumpRow(tester, onTap: () {});

    expect(
      tester.getSemantics(find.byType(EteeloActivatable)),
      containsSemantics(
        isButton: true,
        isEnabled: true,
        isFocusable: true,
        hasTapAction: true,
        label: 'Mukendi Ilunga',
      ),
    );
    semantics.dispose();
  });

  testWidgets('sans action, la ligne n’est pas une étape de tabulation', (
    tester,
  ) async {
    await pumpRow(tester);

    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();

    expect(
      FocusManager.instance.primaryFocus?.context?.widget,
      isNot(isA<FocusableActionDetector>()),
    );
  });
}
