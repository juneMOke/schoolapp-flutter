import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/widgets/eteelo_select/eteelo_select_constants.dart';
import 'package:school_app_flutter/core/widgets/eteelo_select/eteelo_select_field.dart';
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
    testWidgets('hideLabel : rien de peint, mais le champ reste nomme', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EteeloSelectInput<String>(
              label: 'Trier',
              hideLabel: true,
              placeholder: 'Choisir',
              value: null,
              items: const [EteeloSelectItem(value: 'A', label: 'A-Z')],
              onChanged: (_) {},
            ),
          ),
        ),
      );

      expect(find.text('Trier'), findsNothing);
      expect(find.bySemanticsLabel('Trier'), findsOneWidget);
      semantics.dispose();
    });

    testWidgets('l\'aide s\'affiche, et l\'erreur prend sa place', (
      tester,
    ) async {
      Widget build({String? errorText}) => MaterialApp(
        home: Scaffold(
          body: EteeloSelectInput<String>(
            label: 'Motif',
            helperText: 'Renseigne par l\'enseignant',
            errorText: errorText,
            value: null,
            items: const [EteeloSelectItem(value: 'A', label: 'Maladie')],
            onChanged: (_) {},
          ),
        ),
      );

      await tester.pumpWidget(build());
      expect(find.text('Renseigne par l\'enseignant'), findsOneWidget);

      await tester.pumpWidget(build(errorText: 'Motif obligatoire'));
      await tester.pump();
      // Empilees, l'aide se lirait comme une seconde erreur.
      expect(find.text('Motif obligatoire'), findsOneWidget);
      expect(find.text('Renseigne par l\'enseignant'), findsNothing);
    });

    testWidgets('densite compacte : gabarit de puce, pas de champ', (
      tester,
    ) async {
      Widget build(EteeloSelectDensity density) => MaterialApp(
        home: Scaffold(
          body: Align(
            alignment: Alignment.topLeft,
            child: SizedBox(
              width: 200,
              child: EteeloSelectInput<String>(
                label: 'Niveau',
                hideLabel: true,
                density: density,
                minWidth: 0,
                value: null,
                items: const [EteeloSelectItem(value: 'A', label: 'P1')],
                onChanged: (_) {},
              ),
            ),
          ),
        ),
      );

      await tester.pumpWidget(build(EteeloSelectDensity.compact));
      final compact = tester.getSize(find.byType(EteeloSelectField)).height;

      // Le conteneur du champ est animé : sans laisser la transition finir, on
      // mesurerait une hauteur en cours de route.
      await tester.pumpWidget(build(EteeloSelectDensity.standard));
      await tester.pumpAndSettle();
      final standard = tester.getSize(find.byType(EteeloSelectField)).height;

      expect(compact, EteeloSelectConstants.fieldHeightCompact);
      expect(standard, EteeloSelectConstants.fieldHeight);
      expect(compact, lessThan(standard));
    });

    testWidgets('placeholder en alerte : un vide qui bloque se voit', (
      tester,
    ) async {
      Widget build(EteeloSelectPlaceholderTone tone) => MaterialApp(
        home: Scaffold(
          body: EteeloSelectInput<String>(
            label: 'Niveau',
            hideLabel: true,
            placeholder: 'Niveau requis',
            placeholderTone: tone,
            value: null,
            items: const [EteeloSelectItem(value: 'A', label: 'P1')],
            onChanged: (_) {},
          ),
        ),
      );

      await tester.pumpWidget(build(EteeloSelectPlaceholderTone.muted));
      expect(
        tester.widget<Text>(find.text('Niveau requis')).style?.color,
        AppColors.textMuted,
      );

      await tester.pumpWidget(build(EteeloSelectPlaceholderTone.alert));
      await tester.pump();
      final alerted = tester.widget<Text>(find.text('Niveau requis'));
      expect(alerted.style?.color, AppColors.terreCuite);
      expect(alerted.style?.fontWeight, FontWeight.w600);
    });
  });
}
