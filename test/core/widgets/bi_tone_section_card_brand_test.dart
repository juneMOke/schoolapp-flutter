import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/widgets/bi_tone_section_card.dart';

/// La variante **dégradé de marque** de la carte de section.
///
/// Comme partout ailleurs dans ce lot, l'essentiel des assertions porte sur le
/// chemin par **défaut** : la carte bi-ton pâle est composée par plusieurs
/// écrans, et la variante ne doit lui coûter aucun changement.
void main() {
  double ratio(Color a, Color b) {
    final la = a.computeLuminance();
    final lb = b.computeLuminance();
    return (math.max(la, lb) + 0.05) / (math.min(la, lb) + 0.05);
  }

  Future<void> pump(WidgetTester tester, Widget card) => tester.pumpWidget(
    MaterialApp(
      home: Scaffold(body: SizedBox(width: 640, child: card)),
    ),
  );

  bool hasGradient(WidgetTester tester) => tester
      .widgetList<DecoratedBox>(find.byType(DecoratedBox))
      .any((box) => (box.decoration as BoxDecoration).gradient != null);

  Color titleColor(WidgetTester tester, String text) =>
      tester.widget<Text>(find.text(text)).style!.color!;

  group('variante « marque »', () {
    testWidgets('le bandeau prend le dégradé et le glyphe passe en or', (
      tester,
    ) async {
      await pump(
        tester,
        const BiToneSectionCard(
          title: 'Rechercher un élève',
          subtitle: 'Par classe ou par identité',
          icon: Icons.search_rounded,
          headerVariant: BiToneHeaderVariant.brand,
          child: Text('contenu'),
        ),
      );

      expect(hasGradient(tester), isTrue);
      expect(
        tester.widget<Icon>(find.byIcon(Icons.search_rounded)).color,
        AppColors.orDoux,
        reason:
            'sur un aplat déjà coloré, un médaillon d\'accent ne se '
            'détacherait plus : il devient un voile à glyphe or',
      );
    });

    testWidgets('les deux encres du bandeau sont opaques et lisibles', (
      tester,
    ) async {
      await pump(
        tester,
        const BiToneSectionCard(
          title: 'Rechercher un élève',
          subtitle: 'Par classe ou par identité',
          icon: Icons.search_rounded,
          headerVariant: BiToneHeaderVariant.brand,
          child: Text('contenu'),
        ),
      );

      final titre = titleColor(tester, 'Rechercher un élève');
      final sousTitre = titleColor(tester, 'Par classe ou par identité');
      expect(titre, AppColors.blancCasse);
      expect(sousTitre, AppColors.listeInkSubtitle);

      // Mesurées sur l'extrémité CLAIRE du dégradé : c'est elle qui contraint,
      // puisque les encres sont crème. Un blanc translucide, lui, aurait un
      // ratio dépendant du point de mesure — donc invérifiable.
      expect(
        ratio(titre, AppColors.bleuArdoiseLight),
        greaterThanOrEqualTo(4.5),
      );
      expect(
        ratio(sousTitre, AppColors.bleuArdoiseLight),
        greaterThanOrEqualTo(4.5),
      );
    });

    testWidgets('le bord de la carte suit la couleur fournie', (tester) async {
      const borde = Color(0xFFB9C0BC);
      await pump(
        tester,
        const BiToneSectionCard(
          title: 'Rechercher un élève',
          headerVariant: BiToneHeaderVariant.brand,
          borderColor: borde,
          child: Text('contenu'),
        ),
      );

      final carte = tester.widget<Container>(
        find
            .descendant(
              of: find.byType(BiToneSectionCard),
              matching: find.byType(Container),
            )
            .first,
      );
      expect(
        ((carte.decoration! as BoxDecoration).border! as Border).top.color,
        borde,
      );
    });
  });

  group('variante par défaut — rien ne bouge', () {
    testWidgets('aucun dégradé de marque, glyphe sur aplat d\'accent', (
      tester,
    ) async {
      await pump(
        tester,
        const BiToneSectionCard(
          title: 'Rechercher un élève',
          subtitle: 'Par classe ou par identité',
          icon: Icons.search_rounded,
          child: Text('contenu'),
        ),
      );

      // L'en-tête pâle a bien un dégradé horizontal, mais c'est le bi-ton
      // historique : ce qui se vérifie ici, c'est que le glyphe et les encres
      // n'ont pas basculé.
      expect(
        tester.widget<Icon>(find.byIcon(Icons.search_rounded)).color,
        AppColors.textOnDark,
      );
      expect(titleColor(tester, 'Rechercher un élève'), AppColors.textPrimary);
      expect(
        titleColor(tester, 'Par classe ou par identité'),
        AppColors.textMuted,
      );
    });

    testWidgets('le bord reste celui du socle quand rien n\'est fourni', (
      tester,
    ) async {
      await pump(
        tester,
        const BiToneSectionCard(
          title: 'Rechercher un élève',
          child: Text('contenu'),
        ),
      );

      final carte = tester.widget<Container>(
        find
            .descendant(
              of: find.byType(BiToneSectionCard),
              matching: find.byType(Container),
            )
            .first,
      );
      expect(
        ((carte.decoration! as BoxDecoration).border! as Border).top.color,
        AppColors.border,
      );
    });
  });
}
