import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/widgets/eteelo_select_input.dart';

void main() {
  group('EteeloSelectInput', () {
    testWidgets('affiche label et placeholder', (tester) async {
      String? selected;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EteeloSelectInput<String>(
              label: 'Cycle',
              placeholder: 'Choisir',
              value: selected,
              items: const [
                EteeloSelectItem(value: 'PRIMAIRE', label: 'Primaire'),
              ],
              onChanged: (value) => selected = value,
            ),
          ),
        ),
      );

      expect(find.text('Cycle'), findsOneWidget);
      expect(find.text('Choisir'), findsOneWidget);
    });

    testWidgets('mode sheet met a jour la valeur', (tester) async {
      String? selected;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return EteeloSelectInput<String>(
                  label: 'Niveau',
                  placeholder: 'Choisir',
                  panelMode: EteeloSelectPanelMode.sheet,
                  value: selected,
                  items: const [
                    EteeloSelectItem(value: 'M1', label: 'Maternelle 1'),
                    EteeloSelectItem(value: 'M2', label: 'Maternelle 2'),
                  ],
                  onChanged: (value) {
                    setState(() => selected = value);
                  },
                );
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('Choisir').first);
      await tester.pumpAndSettle();

      expect(find.text('Maternelle 2'), findsOneWidget);
      await tester.tap(find.text('Maternelle 2').first);
      await tester.pumpAndSettle();

      expect(find.text('Maternelle 2'), findsOneWidget);
    });
  });
}
