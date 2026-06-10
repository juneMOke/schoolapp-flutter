import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/widgets/eteelo_select_input.dart';

void main() {
  group('EteeloSelectInput', () {
    testWidgets('en lecture (readOnly) : fond editable + valeur affichee', (
      tester,
    ) async {
      var changed = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EteeloSelectInput<String>(
              label: 'Cycle',
              value: 'PRIMAIRE',
              readOnly: true,
              items: const [
                EteeloSelectItem(value: 'PRIMAIRE', label: 'Primaire'),
              ],
              onChanged: (_) => changed = true,
            ),
          ),
        ),
      );

      // Pas de couleur particulière : fond = surface (comme un champ au repos).
      final container = tester.widget<AnimatedContainer>(
        find.byType(AnimatedContainer),
      );
      expect(
        (container.decoration! as BoxDecoration).color,
        equals(AppColors.surface),
      );
      // La valeur est affichée en lecture...
      expect(find.text('Primaire'), findsOneWidget);
      // ...et le champ est non interactif (aucun DropdownButton à ouvrir).
      expect(find.byType(DropdownButton<String>), findsNothing);
      await tester.tap(find.text('Primaire'));
      await tester.pumpAndSettle();
      expect(changed, isFalse);
    });

    testWidgets('desactive sans readOnly : garde le grise (repere cascade)', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EteeloSelectInput<String>(
              label: 'Niveau',
              value: null,
              enabled: false,
              items: const [],
              onChanged: (_) {},
            ),
          ),
        ),
      );

      final container = tester.widget<AnimatedContainer>(
        find.byType(AnimatedContainer),
      );
      expect(
        (container.decoration! as BoxDecoration).color,
        equals(AppColors.surfaceAlt),
      );
    });

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

    testWidgets(
      'ne plante pas si la valeur est absente des options (cascade geo en cours)',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: EteeloSelectInput<String>(
                label: 'Quartier',
                value: 'Bitshaku-Tshaku', // pas (encore) dans les options
                items: const [
                  EteeloSelectItem(value: 'A', label: 'A'),
                  EteeloSelectItem(value: 'B', label: 'B'),
                ],
                onChanged: (_) {},
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
      },
    );

    testWidgets('ne plante pas avec des options en doublon par valeur', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EteeloSelectInput<String>(
              label: 'Quartier',
              value: 'X',
              items: const [
                EteeloSelectItem(value: 'X', label: 'X'),
                EteeloSelectItem(value: 'X', label: 'X (doublon)'),
                EteeloSelectItem(value: 'Y', label: 'Y'),
              ],
              onChanged: (_) {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });
  });
}
