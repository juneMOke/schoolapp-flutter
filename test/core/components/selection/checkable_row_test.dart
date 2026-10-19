import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/components/selection/checkable_row.dart';

/// Au guichet, la case seule se visait à l'ongle : le libellé coche aussi.
void main() {
  Future<List<bool>> pump(WidgetTester tester, {required bool value}) async {
    final changes = <bool>[];
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CheckableRow(
            value: value,
            onChanged: changes.add,
            child: Row(
              children: [
                Checkbox(value: value, onChanged: (v) => changes.add(v!)),
                const Expanded(child: Text('Frais scolaires')),
              ],
            ),
          ),
        ),
      ),
    );
    return changes;
  }

  testWidgets('toucher le libellé coche, puis décoche', (tester) async {
    var changes = await pump(tester, value: false);
    await tester.tap(find.text('Frais scolaires'));
    expect(changes, [true]);

    changes = await pump(tester, value: true);
    await tester.tap(find.text('Frais scolaires'));
    expect(changes, [false]);
  });

  testWidgets('la case garde son geste, sans double bascule', (tester) async {
    final changes = await pump(tester, value: false);
    await tester.tap(find.byType(Checkbox));
    expect(changes, [true]);
  });

  testWidgets('case et libellé se lisent ensemble', (tester) async {
    await pump(tester, value: false);
    expect(
      tester.getSemantics(find.byType(Checkbox)),
      matchesSemantics(
        label: 'Frais scolaires',
        hasCheckedState: true,
        hasEnabledState: true,
        isEnabled: true,
        isFocusable: true,
        hasTapAction: true,
        hasFocusAction: true,
      ),
    );
  });

  testWidgets('un seul arrêt de tabulation : la case', (tester) async {
    await pump(tester, value: false);
    final row = tester.widget<InkWell>(
      find
          .descendant(
            of: find.byType(CheckableRow),
            matching: find.byType(InkWell),
          )
          .first,
    );
    expect(row.canRequestFocus, isFalse);
  });
}
