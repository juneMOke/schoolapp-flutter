import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/components/cards/eteelo_stats_card.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';

void main() {
  Future<void> pump(WidgetTester tester, Widget card) => tester.pumpWidget(
    MaterialApp(
      home: Scaffold(body: SizedBox(width: 500, child: card)),
    ),
  );

  group('EteeloStatsCard — pastille d\'icône de tête', () {
    testWidgets('sans icône, la carte n\'en réserve aucune place', (
      tester,
    ) async {
      await pump(
        tester,
        const EteeloStatsCard(title: 'Par cycle', child: Text('contenu')),
      );

      expect(find.byType(Icon), findsNothing);
      expect(find.text('Par cycle'), findsOneWidget);
    });

    testWidgets('avec icône, le glyphe paraît à la taille du token', (
      tester,
    ) async {
      await pump(
        tester,
        const EteeloStatsCard(
          title: 'Rythme des inscriptions',
          icon: Icons.bar_chart_outlined,
          child: Text('contenu'),
        ),
      );

      final icon = tester.widget<Icon>(find.byIcon(Icons.bar_chart_outlined));
      expect(icon.size, AppDimensions.statsCardIconSize);
      expect(icon.color, AppColors.bleuArdoise);
    });

    testWidgets('la pastille est muette pour les lecteurs d\'écran', (
      tester,
    ) async {
      // Purement décorative : le titre porte déjà l'information, et la relire
      // n'ajouterait qu'un « icône » sans objet.
      await pump(
        tester,
        const EteeloStatsCard(
          title: 'Filles et garçons',
          icon: Icons.people_outline,
          child: Text('contenu'),
        ),
      );

      expect(
        find.ancestor(
          of: find.byIcon(Icons.people_outline),
          matching: find.byType(ExcludeSemantics),
        ),
        findsWidgets,
      );
    });

    testWidgets('l\'icône cohabite avec un sous-titre et des actions', (
      tester,
    ) async {
      // Le chemin « Wrap » de l'en-tête est distinct du chemin nu : les deux
      // doivent porter la pastille.
      await pump(
        tester,
        const EteeloStatsCard(
          title: 'Répartition par niveau',
          subtitle: 'Sur la période',
          hint: '7 niveaux concernés',
          icon: Icons.layers_outlined,
          actions: [Text('PDF')],
          child: Text('contenu'),
        ),
      );

      expect(tester.takeException(), isNull);
      expect(find.byIcon(Icons.layers_outlined), findsOneWidget);
      expect(find.text('Sur la période'), findsOneWidget);
      expect(find.text('7 niveaux concernés'), findsOneWidget);
      expect(find.text('PDF'), findsOneWidget);
    });

    testWidgets('un titre long garde sa place à côté de la pastille', (
      tester,
    ) async {
      // `Flexible` autour du bloc de titres : sans lui, un titre long
      // déborderait de la rangée plutôt que de se replier.
      await pump(
        tester,
        const EteeloStatsCard(
          title: 'Répartition par niveau sur la fenêtre choisie, en détail',
          icon: Icons.layers_outlined,
          child: Text('contenu'),
        ),
      );

      expect(tester.takeException(), isNull);
    });
  });
}
