import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/components/cards/eteelo_stats_card.dart';
import 'package:school_app_flutter/core/components/cards/eteelo_stats_card_parts.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/theme/color_mix.dart';

/// La variante **teintée** de la carte de section (spec couleurs §04).
///
/// Ce que ces tests protègent surtout, c'est le chemin **non** teinté : la
/// carte blanche est consommée par cinq modules, et la variante ne doit lui
/// coûter aucun changement.
void main() {
  const tone = AppColors.enrollmentStatsFemale; // carmin #9D174D

  Future<void> pump(WidgetTester tester, Widget card) => tester.pumpWidget(
    MaterialApp(
      home: Scaffold(body: SizedBox(width: 500, child: card)),
    ),
  );

  BoxDecoration decorationOf(WidgetTester tester) =>
      tester
              .widget<Container>(
                find
                    .descendant(
                      of: find.byType(EteeloStatsCard),
                      matching: find.byType(Container),
                    )
                    .first,
              )
              .decoration!
          as BoxDecoration;

  group('carte teintée', () {
    testWidgets('fond, bord et rayon dérivent tous du ton', (tester) async {
      await pump(
        tester,
        const EteeloStatsCard(
          title: 'Filles et garçons',
          tone: tone,
          toneStrength: 9,
          child: Text('contenu'),
        ),
      );

      final decoration = decorationOf(tester);
      expect(
        decoration.color,
        ColorMix.tint(AppColors.surfaceRaised, tone, 9),
        reason: 'le fond est le ton dilué à 9 %',
      );
      expect(
        (decoration.border! as Border).top.color,
        ColorMix.tint(AppColors.border, tone, 27),
        reason: 'le bord est trois fois plus saturé que le fond',
      );
    });

    testWidgets('le médaillon prend la géométrie et la couleur du ton', (
      tester,
    ) async {
      await pump(
        tester,
        const EteeloStatsCard(
          title: 'Filles et garçons',
          icon: Icons.people_outline,
          tone: tone,
          child: Text('contenu'),
        ),
      );

      final icon = tester.widget<Icon>(find.byIcon(Icons.people_outline));
      expect(icon.size, AppDimensions.insSectionMedallionIconSize);
      expect(icon.color, tone, reason: 'le glyphe suit le ton de la section');
    });

    testWidgets('un iconColor explicite l\'emporte sur le ton', (tester) async {
      await pump(
        tester,
        const EteeloStatsCard(
          title: 'Par cycle',
          icon: Icons.layers_outlined,
          tone: tone,
          iconColor: AppColors.vertSavane,
          child: Text('contenu'),
        ),
      );

      expect(
        tester.widget<Icon>(find.byIcon(Icons.layers_outlined)).color,
        AppColors.vertSavane,
      );
    });

    testWidgets('le filet sépare l\'en-tête du contenu', (tester) async {
      await pump(
        tester,
        const EteeloStatsCard(
          title: 'Rythme',
          tone: tone,
          child: Text('contenu'),
        ),
      );

      expect(find.byType(EteeloStatsCardFilet), findsOneWidget);
    });

    testWidgets('une force hors plage est refusée à la construction', (
      tester,
    ) async {
      // Au-delà de 13 la carte concurrence les pavés de chiffres : ce n'est
      // pas un réglage libre.
      expect(
        () => EteeloStatsCard(
          title: 'Trop dense',
          tone: tone,
          toneStrength: 20,
          child: const Text('contenu'),
        ),
        throwsAssertionError,
      );
    });
  });

  group('carte blanche — le défaut ne bouge pas', () {
    testWidgets('fond, rayon et glyphe restent ceux d\'avant', (tester) async {
      await pump(
        tester,
        const EteeloStatsCard(
          title: 'Par cycle',
          icon: Icons.layers_outlined,
          child: Text('contenu'),
        ),
      );

      expect(decorationOf(tester).color, AppColors.surfaceRaised);
      final icon = tester.widget<Icon>(find.byIcon(Icons.layers_outlined));
      expect(icon.size, AppDimensions.statsCardIconSize);
      expect(icon.color, AppColors.bleuArdoise);
    });

    testWidgets('aucun filet n\'apparaît sans ton', (tester) async {
      await pump(
        tester,
        const EteeloStatsCard(title: 'Par cycle', child: Text('contenu')),
      );

      expect(find.byType(EteeloStatsCardFilet), findsNothing);
    });
  });
}
