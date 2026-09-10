import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/components/controls/segmented_tab_filter.dart';

enum _TestMode { table, grid }

void main() {
  group('SegmentedTabFilter', () {
    testWidgets('affiche les options et notifie le changement', (tester) async {
      _TestMode selected = _TestMode.table;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return SegmentedTabFilter<_TestMode>(
                  options: const [
                    SegmentedTabOption(
                      label: 'Tableau',
                      value: _TestMode.table,
                    ),
                    SegmentedTabOption(label: 'Grille', value: _TestMode.grid),
                  ],
                  selected: selected,
                  onSelected: (value) => setState(() => selected = value),
                );
              },
            ),
          ),
        ),
      );

      expect(find.text('Tableau'), findsOneWidget);
      expect(find.text('Grille'), findsOneWidget);

      await tester.tap(find.text('Grille'));
      await tester.pumpAndSettle();

      expect(selected, _TestMode.grid);
    });

    testWidgets('expose une semantique de groupe exclusif avec selection', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SegmentedTabFilter<_TestMode>(
              semanticsLabel: 'Bascule vue',
              options: const [
                SegmentedTabOption(label: 'Tableau', value: _TestMode.table),
                SegmentedTabOption(label: 'Grille', value: _TestMode.grid),
              ],
              selected: _TestMode.table,
              onSelected: (_) {},
            ),
          ),
        ),
      );

      final tableSemantics = tester.getSemantics(find.text('Tableau').first);
      final gridSemantics = tester.getSemantics(find.text('Grille').first);

      expect(
        tableSemantics,
        matchesSemantics(
          label: 'Tableau',
          isButton: true,
          isSelected: true,
          hasSelectedState: true,
          isInMutuallyExclusiveGroup: true,
          hasTapAction: true,
        ),
      );
      expect(
        gridSemantics,
        matchesSemantics(
          label: 'Grille',
          isButton: true,
          isSelected: false,
          hasSelectedState: true,
          isInMutuallyExclusiveGroup: true,
          hasTapAction: true,
        ),
      );
    });
  });

  /// Le mode enroulé sert les barres de **navigation** — une fenêtre de temps à
  /// cinq onglets, dont chacun garde sa cible tactile. Les filtres historiques
  /// ne l'activent pas et doivent rendre exactement comme avant : c'est ce que
  /// vérifie le premier test du groupe.
  group('SegmentedTabFilter — mode enroulé', () {
    Widget host({required bool wrap, double width = 260}) => MaterialApp(
      home: Scaffold(
        body: Center(
          child: SizedBox(
            width: width,
            child: SegmentedTabFilter<_TestMode>(
              options: const [
                SegmentedTabOption(
                  label: 'Tableau',
                  value: _TestMode.table,
                  icon: Icons.table_rows_rounded,
                ),
                SegmentedTabOption(
                  label: 'Grille',
                  value: _TestMode.grid,
                  icon: Icons.grid_view_rounded,
                ),
              ],
              selected: _TestMode.table,
              onSelected: (_) {},
              wrap: wrap,
              style: wrap
                  ? SegmentedTabFilterStyle.window
                  : const SegmentedTabFilterStyle(),
            ),
          ),
        ),
      ),
    );

    testWidgets('par défaut la barre reste une ligne à hauteur imposée', (
      tester,
    ) async {
      // Largeur confortable : le mode historique ne s'enroule PAS, il déborde.
      // C'est sa limite, et la raison d'être du mode enroulé — ce test vérifie
      // seulement qu'il n'a pas changé de nature.
      await tester.pumpWidget(host(wrap: false, width: 420));

      expect(tester.takeException(), isNull);
      expect(find.byType(Wrap), findsNothing);
      expect(find.byType(Row), findsWidgets);
    });

    testWidgets('en mode enroulé les onglets passent dans un Wrap', (
      tester,
    ) async {
      await tester.pumpWidget(host(wrap: true));

      expect(find.byType(Wrap), findsOneWidget);
    });

    testWidgets('le preset « window » tient la cible tactile de 44 dp', (
      tester,
    ) async {
      await tester.pumpWidget(host(wrap: true));

      // Chaque onglet, pas seulement la barre : c'est l'onglet qu'on vise.
      for (final label in ['Tableau', 'Grille']) {
        final tapTarget = find
            .ancestor(of: find.text(label), matching: find.byType(InkWell))
            .first;
        expect(tester.getSize(tapTarget).height, greaterThanOrEqualTo(44.0));
      }
    });

    testWidgets('cinq onglets étroits s\'enroulent au lieu de déborder', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 300,
                child: SegmentedTabFilter<int>(
                  options: const [
                    SegmentedTabOption(label: 'Aujourd\'hui', value: 0),
                    SegmentedTabOption(label: 'Cette semaine', value: 1),
                    SegmentedTabOption(label: 'Ce mois', value: 2),
                    SegmentedTabOption(label: 'Année', value: 3),
                    SegmentedTabOption(label: 'Période précise', value: 4),
                  ],
                  selected: 0,
                  onSelected: (_) {},
                  wrap: true,
                  style: SegmentedTabFilterStyle.window,
                ),
              ),
            ),
          ),
        ),
      );

      // Le débordement d'un Row se signale par une exception de layout ; le
      // Wrap, lui, prend simplement un rang de plus.
      expect(tester.takeException(), isNull);
      final barHeight = tester.getSize(find.byType(Wrap)).height;
      expect(
        barHeight,
        greaterThan(44.0),
        reason: 'cinq onglets à 300 dp doivent occuper plus d\'un rang',
      );
    });

    testWidgets('en mode enroulé un onglet garde sa largeur intrinsèque', (
      tester,
    ) async {
      // Régression : un Container porteur d'un `alignment` se DILATE pour
      // remplir des contraintes bornées. Un Row donne à ses enfants une
      // largeur non bornée, donc l'onglet s'y rétractait sur son contenu ;
      // mais un Wrap borne la largeur de ses enfants, et chaque onglet
      // prenait alors TOUTE la barre — un onglet par rang, à n'importe
      // quelle largeur, ce qui se lisait comme une colonne.
      // Une vraie surface large : la surface de test par défaut fait 800 dp,
      // où cinq onglets pleins tiennent légitimement sur deux rangs.
      tester.view.physicalSize = const Size(1400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 1400,
              child: SegmentedTabFilter<int>(
                options: const [
                  SegmentedTabOption(label: 'Aujourd\'hui', value: 0),
                  SegmentedTabOption(label: 'Cette semaine', value: 1),
                  SegmentedTabOption(label: 'Ce mois', value: 2),
                  SegmentedTabOption(label: 'Année', value: 3),
                  SegmentedTabOption(label: 'Période précise', value: 4),
                ],
                selected: 0,
                onSelected: (_) {},
                wrap: true,
                style: SegmentedTabFilterStyle.window,
              ),
            ),
          ),
        ),
      );

      // Cinq onglets courts dans 900 dp tiennent sur UN rang : ils partagent
      // donc tous la même ordonnée.
      final tops = <double>{
        for (final label in [
          'Aujourd\'hui',
          'Cette semaine',
          'Ce mois',
          'Année',
          'Période précise',
        ])
          tester.getTopLeft(find.text(label)).dy,
      };
      expect(
        tops,
        hasLength(1),
        reason: 'les cinq onglets doivent tenir sur une seule rangée',
      );

      // Et aucun ne s'étale sur toute la barre.
      final tab = find
          .ancestor(of: find.text('Ce mois'), matching: find.byType(InkWell))
          .first;
      expect(tester.getSize(tab).width, lessThan(300.0));
    });

    test('« wrap » et « expand » s\'excluent', () {
      // Le premier donne aux onglets leur largeur intrinsèque sur plusieurs
      // rangs, le second les étire sur une seule ligne : les combiner ne veut
      // rien dire, et l'assertion le dit à la construction plutôt qu'au rendu.
      expect(
        () => SegmentedTabFilter<int>(
          options: const [SegmentedTabOption(label: 'A', value: 0)],
          selected: 0,
          onSelected: (_) {},
          wrap: true,
          expand: true,
        ),
        throwsA(isA<AssertionError>()),
      );
    });
  });

  group('cible tactile minimale', () {
    Future<double> tabHeight(
      WidgetTester tester, {
      required SegmentedTabFilterStyle style,
    }) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SegmentedTabFilter<String>(
              style: style,
              options: const [
                SegmentedTabOption(label: 'Un', value: 'a'),
                SegmentedTabOption(label: 'Deux', value: 'b'),
              ],
              selected: 'a',
              onSelected: (_) {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      return tester.getSize(find.byType(InkWell).first).height;
    }

    testWidgets('sans paramètre, la barre garde exactement sa taille', (
      tester,
    ) async {
      // Vingt et un écrans passent par ce composant : le défaut ne bouge pas.
      final height = await tabHeight(
        tester,
        style: const SegmentedTabFilterStyle(),
      );
      expect(height, lessThan(44));
    });

    testWidgets('avec 44, la cible RENDUE fait 44 — trait de barre compris', (
      tester,
    ) async {
      // ⚠️ Mesuré, pas déduit. Le conteneur annonce 38, le segment se rétracte
      // sur son contenu, et le trait de 1 dp se prend DANS la hauteur : un
      // calcul qui l'oubliait tombait deux pixels trop court.
      final height = await tabHeight(
        tester,
        style: const SegmentedTabFilterStyle(minimumTapTarget: 44),
      );
      expect(height, 44);
    });
  });
}
