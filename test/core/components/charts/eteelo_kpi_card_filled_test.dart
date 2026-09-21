import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/components/charts/eteelo_kpi_card.dart';
import 'package:school_app_flutter/core/components/charts/eteelo_kpi_card_data.dart';
import 'package:school_app_flutter/core/components/charts/eteelo_kpi_card_parts.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';

/// La variante **pavé plein** de la carte KPI (spec couleurs §03).
///
/// Comme pour la carte de section, l'essentiel est que la carte claire — celle
/// de tous les autres tableaux de bord — ne s'aperçoive de rien.
void main() {
  const fondPave = Color(0xFF184662); // pave(#1B4D6B)

  const rempli = EteeloKpiCardData(
    label: 'Inscriptions · aujourd\'hui',
    value: 14,
    subline: 'Même période 2024–2025 : 11',
    accent: AppColors.bleuArdoise,
    accentSoft: AppColors.enrollmentStatsAccentSoft,
    icon: Icons.how_to_reg_rounded,
    filledBackground: fondPave,
  );

  const clair = EteeloKpiCardData(
    label: 'Inscriptions · aujourd\'hui',
    value: 14,
    accent: AppColors.bleuArdoise,
    accentSoft: AppColors.enrollmentStatsAccentSoft,
    icon: Icons.how_to_reg_rounded,
  );

  Future<void> pump(WidgetTester tester, EteeloKpiCardData data) =>
      tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            // Sans l'entrée animée : on mesure la carte, pas son apparition.
            data: const MediaQueryData(disableAnimations: true),
            // `Align` dans un défilement, et non un `SizedBox` posé dans le
            // corps du `Scaffold` : celui-ci étire la carte sur toute la
            // hauteur disponible, si bien qu'on mesurerait la contrainte du
            // parent (600 dp) au lieu du plancher de la carte.
            child: Scaffold(
              body: SingleChildScrollView(
                child: Align(
                  alignment: Alignment.topLeft,
                  child: SizedBox(width: 320, child: EteeloKpiCard(data: data)),
                ),
              ),
            ),
          ),
        ),
      );

  BoxDecoration decorationOf(WidgetTester tester) =>
      tester
              .widget<Container>(
                find
                    .descendant(
                      of: find.byType(EteeloKpiCard),
                      matching: find.byType(Container),
                    )
                    .first,
              )
              .decoration!
          as BoxDecoration;

  group('pavé plein', () {
    testWidgets('la donnée seule décide de l\'habillage', (tester) async {
      expect(rempli.isFilled, isTrue);
      expect(clair.isFilled, isFalse);
    });

    testWidgets('le fond est celui que l\'appelant a dérivé', (tester) async {
      await pump(tester, rempli);

      expect(decorationOf(tester).color, fondPave);
    });

    testWidgets('aucun liseré d\'accent : la teinte porte déjà l\'identité', (
      tester,
    ) async {
      await pump(tester, rempli);

      final border = decorationOf(tester).border! as Border;
      expect(border.left.color, Colors.transparent);
      expect(
        border.left.width,
        border.top.width,
        reason: 'un bord uniforme, pas le liseré gauche de 3 dp',
      );
    });

    testWidgets('le halo est posé sous le contenu', (tester) async {
      await pump(tester, rempli);

      expect(find.byType(EteeloKpiCardHalo), findsOneWidget);
    });

    testWidgets('le libellé passe en capitales au-dessus de la valeur', (
      tester,
    ) async {
      await pump(tester, rempli);

      expect(find.text('INSCRIPTIONS · AUJOURD\'HUI'), findsOneWidget);
      expect(find.text('14'), findsOneWidget);
      expect(find.text('Même période 2024–2025 : 11'), findsOneWidget);
    });

    testWidgets('la valeur est crème, jamais l\'accent', (tester) async {
      await pump(tester, rempli);

      final valeur = tester.widget<Text>(find.text('14'));
      expect(valeur.style!.color, AppColors.insInkMain);
    });
  });

  group('carte claire — le défaut ne bouge pas', () {
    testWidgets('fond blanc, liseré d\'accent, aucun halo', (tester) async {
      await pump(tester, clair);

      final decoration = decorationOf(tester);
      expect(decoration.color, AppColors.enrollmentStatsCardSurface);
      expect((decoration.border! as Border).left.color, AppColors.bleuArdoise);
      expect((decoration.border! as Border).left.width, 3);
      expect(find.byType(EteeloKpiCardHalo), findsNothing);
    });

    testWidgets('le libellé garde sa casse et la valeur son accent', (
      tester,
    ) async {
      await pump(tester, clair);

      expect(find.text('Inscriptions · aujourd\'hui'), findsOneWidget);
      expect(
        tester.widget<Text>(find.text('14')).style!.color,
        AppColors.bleuArdoise,
      );
      // La **hauteur** du gabarit historique n'est pas vérifiée ici : elle
      // l'est déjà par `eteelo_kpi_card_test.dart`, dans une bande de quatre
      // cartes — la forme du harnais change la largeur offerte, donc le
      // repliement du libellé, donc la hauteur. La réasserter dans un harnais
      // d'une autre forme ne mesurerait pas la même chose.
    });
  });
}
