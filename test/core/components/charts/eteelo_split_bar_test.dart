import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/components/charts/eteelo_split_bar.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';

/// Monte la barre dans une largeur connue, pour que les proportions se mesurent.
Future<void> _pump(
  WidgetTester tester,
  List<EteeloSplitBarSegment> segments, {
  bool reduceMotion = true,
  double width = 400,
}) async {
  await tester.pumpWidget(
    MediaQuery(
      data: MediaQueryData(disableAnimations: reduceMotion),
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: width,
                child: EteeloSplitBar(
                  segments: segments,
                  semanticsLabel: '182 filles, 181 garçons',
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

const _girls = EteeloSplitBarSegment(
  label: 'Filles',
  valueLabel: '182 · 50 %',
  value: 182,
  color: AppColors.enrollmentStatsFemale,
);

const _boys = EteeloSplitBarSegment(
  label: 'Garçons',
  valueLabel: '181 · 50 %',
  value: 181,
  color: AppColors.enrollmentStatsMale,
);

void main() {
  testWidgets('un segment occupe TOUTE la hauteur de la barre', (tester) async {
    // Régression : les segments sont des `ColoredBox` SANS enfant, posés dans
    // un Row dont le `crossAxisAlignment` valait `center` par défaut. Un Row
    // donne alors à ses enfants des contraintes transversales LÂCHES, et une
    // `ColoredBox` sans enfant s'y effondre à zéro de haut. La barre affichait
    // donc sa piste grise avec des segments larges mais invisibles — pendant
    // que la légende, elle, écrivait ses valeurs.
    //
    // Le test mesure la HAUTEUR : mesurer la seule largeur laissait passer le
    // défaut, puisque l'`Expanded` donne bien sa largeur au segment.
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 600,
            child: EteeloSplitBar(
              segments: [
                EteeloSplitBarSegment(
                  label: 'Filles',
                  valueLabel: '7 élèves',
                  value: 7,
                  color: Color(0xFF9D174D),
                ),
                EteeloSplitBarSegment(
                  label: 'Garçons',
                  valueLabel: '7 élèves',
                  value: 7,
                  color: Color(0xFF1B4D6B),
                ),
              ],
              semanticsLabel: 'répartition',
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final track = tester.getSize(
      find.byWidgetPredicate(
        (w) => w is ColoredBox && w.color == AppColors.surfaceAlt,
      ),
    );
    for (final color in [const Color(0xFF9D174D), const Color(0xFF1B4D6B)]) {
      final size = tester.getSize(
        find.byWidgetPredicate((w) => w is ColoredBox && w.color == color),
      );
      expect(
        size.height,
        track.height,
        reason: 'un segment invisible est une barre vide',
      );
      expect(size.width, greaterThan(0));
    }
  });
  testWidgets('la légende écrit chaque libellé ET sa valeur', (tester) async {
    await _pump(tester, const [_girls, _boys]);

    // Aucune information n'est portée par la seule couleur : le libellé et la
    // valeur sont écrits pour chaque segment.
    expect(find.text('Filles'), findsOneWidget);
    expect(find.text('182 · 50 %'), findsOneWidget);
    expect(find.text('Garçons'), findsOneWidget);
    expect(find.text('181 · 50 %'), findsOneWidget);
  });

  testWidgets('la barre porte une phrase a11y qui contient les valeurs', (
    tester,
  ) async {
    await _pump(tester, const [_girls, _boys]);

    expect(find.bySemanticsLabel('182 filles, 181 garçons'), findsOneWidget);
  });

  testWidgets('les largeurs suivent la part de chaque segment', (tester) async {
    // 3 contre 1 : le premier segment doit occuper trois fois le second.
    await _pump(tester, const [
      EteeloSplitBarSegment(
        label: 'A',
        valueLabel: '300',
        value: 300,
        color: Color(0xFF111111),
      ),
      EteeloSplitBarSegment(
        label: 'B',
        valueLabel: '100',
        value: 100,
        color: Color(0xFF222222),
      ),
    ]);

    final boxes = tester
        .widgetList<ColoredBox>(find.byType(ColoredBox))
        .where(
          (box) =>
              box.color == const Color(0xFF111111) ||
              box.color == const Color(0xFF222222),
        )
        .toList();
    expect(boxes, hasLength(2));

    final a = tester.getSize(
      find
          .ancestor(
            of: find.byWidget(boxes[0]),
            matching: find.byType(Expanded),
          )
          .first,
    );
    final b = tester.getSize(
      find
          .ancestor(
            of: find.byWidget(boxes[1]),
            matching: find.byType(Expanded),
          )
          .first,
    );
    expect(a.width / b.width, closeTo(3.0, 0.05));
  });

  testWidgets('un total nul rend la piste et des zéros, pas un trou', (
    tester,
  ) async {
    // Le cas d'une école le jour de l'ouverture : c'est un état, pas une
    // absence de rendu.
    await _pump(tester, const [
      EteeloSplitBarSegment(
        label: 'Filles',
        valueLabel: '0 · 0 %',
        value: 0,
        color: AppColors.enrollmentStatsFemale,
      ),
      EteeloSplitBarSegment(
        label: 'Garçons',
        valueLabel: '0 · 0 %',
        value: 0,
        color: AppColors.enrollmentStatsMale,
      ),
    ]);

    expect(tester.takeException(), isNull);
    expect(find.text('Filles'), findsOneWidget);
    expect(find.text('0 · 0 %'), findsNWidgets(2));
    // La piste occupe toute la largeur offerte.
    expect(
      tester.getSize(find.byType(ClipRRect).first).width,
      closeTo(400, 0.5),
    );
  });

  testWidgets('sans reduced-motion la barre s\'anime puis se stabilise', (
    tester,
  ) async {
    await _pump(tester, const [_girls, _boys], reduceMotion: false);
    expect(tester.takeException(), isNull);
    expect(find.text('Filles'), findsOneWidget);
  });

  testWidgets('une légende trop longue s\'abrège au lieu de déborder', (
    tester,
  ) async {
    // ⚠️ Le cas qui a rendu les rayures noir et jaune en production : la même
    // légende qui tenait sur une carte pleine largeur, posée sur une
    // demi-largeur. Un `Wrap` donne à ses enfants une largeur **non bornée** —
    // une entrée trop longue ne se replie donc pas, elle déborde.
    await _pump(tester, const [
      EteeloSplitBarSegment(
        label: 'Facturation (frais scolaires réglés au guichet)',
        valueLabel: '3 255 000,00 FC',
        value: 3255000,
        color: AppColors.bleuArdoise,
      ),
      EteeloSplitBarSegment(
        label: 'Boutique (achats facultatifs, hors attendu)',
        valueLabel: '865 000,00 FC',
        value: 865000,
        color: AppColors.terreCuite,
      ),
    ], width: 300);

    expect(
      tester.takeException(),
      isNull,
      reason: 'un débordement lève ici, et rend des rayures à l’écran',
    );
    // Le MONTANT n'est jamais tronqué : un chiffre coupé serait pire
    // qu'illisible. C'est le libellé qui cède.
    expect(find.text('3 255 000,00 FC'), findsOneWidget);
    expect(find.text('865 000,00 FC'), findsOneWidget);
  });
}
