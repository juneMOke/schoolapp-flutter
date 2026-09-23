import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/components/charts/eteelo_kpi_card.dart';
import 'package:school_app_flutter/core/components/charts/eteelo_kpi_card_data.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';

/// `filledSecondaryInk` est une **option** : son absence doit laisser le rendu
/// exactement tel qu'il était, sans quoi les cartes bi-devise déjà en place
/// changeraient d'aspect sans que personne l'ait demandé.
void main() {
  Future<void> pump(WidgetTester tester, EteeloKpiCardData data) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: Align(
              alignment: Alignment.topLeft,
              child: SizedBox(width: 260, child: EteeloKpiCard(data: data)),
            ),
          ),
        ),
      ),
    );
  }

  Color? colorOf(WidgetTester tester, String text) =>
      tester.widget<Text>(find.text(text)).style?.color;

  EteeloKpiCardData build({Color? secondaryInk}) => EteeloKpiCardData(
    label: 'Attendu',
    valueLines: const ['184 500 \$', '3 420 000 FC'],
    accent: AppColors.bleuArdoise,
    accentSoft: AppColors.bleuArdoiseSoft,
    icon: Icons.receipt_long_outlined,
    filledBackground: const Color(0xFF184662),
    filledSecondaryInk: secondaryInk,
  );

  testWidgets('sans nuance, les deux montants portent la même encre', (
    tester,
  ) async {
    await pump(tester, build());

    expect(colorOf(tester, '184 500 \$'), AppColors.insInkMain);
    expect(colorOf(tester, '3 420 000 FC'), AppColors.insInkMain);
  });

  testWidgets('avec nuance, seule la seconde ligne change', (tester) async {
    await pump(tester, build(secondaryInk: AppColors.paveInkAttendu));

    // La première garde l'encre pleine : c'est le montant principal.
    expect(colorOf(tester, '184 500 \$'), AppColors.insInkMain);
    expect(colorOf(tester, '3 420 000 FC'), AppColors.paveInkAttendu);
  });

  testWidgets('la nuance ne déborde pas sur une carte à valeur unique', (
    tester,
  ) async {
    await pump(
      tester,
      const EteeloKpiCardData(
        label: 'Rien payé',
        value: 42,
        accent: AppColors.error,
        accentSoft: AppColors.feeStatusDueSoft,
        icon: Icons.error_outline_rounded,
        filledBackground: Color(0xFF993630),
        // Déclarée alors qu'il n'y a qu'une valeur : elle ne doit rien peindre.
        filledSecondaryInk: AppColors.paveInkReste,
      ),
    );

    expect(colorOf(tester, '42'), AppColors.insInkMain);
  });
}
