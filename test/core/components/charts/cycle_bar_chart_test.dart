import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/components/charts/bar_chart_item.dart';
import 'package:school_app_flutter/core/components/charts/cycle_bar_chart.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';

void main() {
  const items = [
    BarChartItem(
      label: 'MAT1',
      value: 30,
      color: AppColors.enrollmentStatsAccent,
    ),
    BarChartItem(label: 'P1', value: 42, color: AppColors.enrollmentStatsFirst),
    BarChartItem(label: 'P2', value: 18, color: AppColors.enrollmentStatsRe),
  ];

  Future<void> pumpChart(
    WidgetTester tester, {
    required bool vertical,
    List<BarChartItem> barItems = items,
    bool showLeftAxis = true,
    double minimumBarHeight = 0,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 600,
            child: CycleBarChart(
              items: barItems,
              verticalBottomLabels: vertical,
              showLeftAxis: showLeftAxis,
              minimumBarHeight: minimumBarHeight,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('sans l option, les libelles restent horizontaux', (
    tester,
  ) async {
    await pumpChart(tester, vertical: false);

    expect(
      find.descendant(
        of: find.byType(CycleBarChart),
        matching: find.byType(RotatedBox),
      ),
      findsNothing,
    );
  });

  testWidgets('avec l option, chaque libelle est pivote d un quart de tour', (
    tester,
  ) async {
    await pumpChart(tester, vertical: true);

    final rotated = tester
        .widgetList<RotatedBox>(
          find.descendant(
            of: find.byType(CycleBarChart),
            matching: find.byType(RotatedBox),
          ),
        )
        .toList();

    expect(rotated, hasLength(items.length));
    for (final box in rotated) {
      expect(box.quarterTurns, 1);
    }
    expect(find.text('MAT1'), findsOneWidget);
  });

  testWidgets('un libelle pivote tient sur une ligne, sans troncature', (
    tester,
  ) async {
    await pumpChart(tester, vertical: true);

    expect(tester.widget<Text>(find.text('MAT1')).maxLines, 1);

    // fl_chart impose une hauteur tight au titre : une fois pivote, c est la
    // largeur du texte qui est bornee. Si la reserve etait sous-dimensionnee,
    // le libelle le plus long serait ellipse (plus etroit que sa largeur
    // intrinseque) ou replie (plus haut qu un libelle court).
    final longest = tester.renderObject<RenderBox>(find.text('MAT1'));
    final shortest = tester.renderObject<RenderBox>(find.text('P1'));

    expect(longest.size.height, shortest.size.height);
    expect(
      longest.size.width,
      greaterThanOrEqualTo(longest.getMaxIntrinsicWidth(double.infinity)),
    );
  });

  testWidgets(
    'la hauteur du graphique compense la reserve prise par les libelles',
    (tester) async {
      await pumpChart(tester, vertical: false);
      final horizontalHeight = tester
          .getSize(find.byType(CycleBarChart))
          .height;

      await pumpChart(tester, vertical: true);
      final verticalHeight = tester.getSize(find.byType(CycleBarChart)).height;

      expect(horizontalHeight, AppDimensions.enrollmentStatsChartSectionHeight);
      expect(verticalHeight, greaterThan(horizontalHeight));
    },
  );

  testWidgets('un libelle court ne rogne pas la hauteur du trace', (
    tester,
  ) async {
    await pumpChart(
      tester,
      vertical: true,
      barItems: const [
        BarChartItem(
          label: '1',
          value: 5,
          color: AppColors.enrollmentStatsAccent,
        ),
      ],
    );

    expect(
      tester.getSize(find.byType(CycleBarChart)).height,
      AppDimensions.enrollmentStatsChartSectionHeight,
    );
  });

  testWidgets('un libelle aberrant est plafonne, jamais replie', (
    tester,
  ) async {
    await pumpChart(
      tester,
      vertical: true,
      barItems: const [
        BarChartItem(
          label: 'MATERNELLE-SUPERIEURE-BIS',
          value: 5,
          color: AppColors.enrollmentStatsAccent,
        ),
        BarChartItem(
          label: 'P1',
          value: 8,
          color: AppColors.enrollmentStatsFirst,
        ),
      ],
    );

    // Le plafond protege le trace : la reserve ne depasse jamais le maximum.
    expect(
      tester.getSize(find.byType(CycleBarChart)).height,
      AppDimensions.enrollmentStatsChartSectionHeight +
          AppDimensions.enrollmentStatsChartVerticalLabelMaxExtent -
          AppDimensions.enrollmentStatsChartBottomTitleHeight,
    );

    // Le libelle est alors ellipse, sur une ligne unique.
    final capped = tester.renderObject<RenderBox>(
      find.text('MATERNELLE-SUPERIEURE-BIS'),
    );
    final shortest = tester.renderObject<RenderBox>(find.text('P1'));
    expect(capped.size.height, shortest.size.height);
  });

  group('largeur des barres', () {
    /// La largeur réellement demandée à fl_chart pour la première barre.
    double barWidthOf(WidgetTester tester) {
      final chart = tester.widget<BarChart>(find.byType(BarChart));
      return chart.data.barGroups.first.barRods.first.width;
    }

    Future<void> pumpAt(WidgetTester tester, double width, int barCount) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: width,
              child: CycleBarChart(
                items: [
                  for (var i = 0; i < barCount; i++)
                    BarChartItem(
                      label: 'B$i',
                      value: 10.0 + i,
                      color: AppColors.enrollmentStatsAccent,
                    ),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('une barre occupe ~53 % du pas, pas une largeur en dur', (
      tester,
    ) async {
      // Régression : la largeur était posée en dur (`length > 4 ? 20 : 32`),
      // sans rapport avec l'espace disponible — à cinq barres dans une carte
      // large, 20 dp ne faisaient que ~23 % du pas et le rythme se lisait
      // comme une rangée de traits. La spec veut 46/86.
      const width = 436.0;
      const barCount = 5;
      await pumpAt(tester, width, barCount);

      final pitch =
          (width - AppDimensions.enrollmentStatsChartLeftAxisWidth) / barCount;
      expect(
        barWidthOf(tester) / pitch,
        closeTo(AppDimensions.enrollmentStatsChartBarWidthRatio, 0.01),
      );
    });

    testWidgets('cinq barres ne sont pas plus fines que quatre', (
      tester,
    ) async {
      // L'ancien seuil `> 4` faisait chuter la barre de 32 à 20 dp d'un coup :
      // passer de « Ce mois » à « Aujourd'hui » amincissait le tracé.
      // Largeurs choisies sous le plafond de 46 dp, sinon les deux cas y
      // seraient écrêtés et le rapport ne prouverait rien.
      await pumpAt(tester, 356, 4);
      final atFour = barWidthOf(tester);
      await pumpAt(tester, 356, 5);
      final atFive = barWidthOf(tester);

      expect(atFive, lessThan(atFour));
      expect(
        atFive / atFour,
        closeTo(4 / 5, 0.02),
        reason: 'la largeur doit suivre le pas, sans marche d\'escalier',
      );
    });

    testWidgets('la barre reste bornée quand le pas est immense', (
      tester,
    ) async {
      await pumpAt(tester, 1200, 2);
      expect(barWidthOf(tester), AppDimensions.enrollmentStatsChartBarMaxWidth);
    });
  });

  testWidgets('l’axe vertical se retire, et rend sa largeur au tracé', (
    tester,
  ) async {
    // Assez de barres pour que la largeur ne bute pas sur son plafond : à
    // trois barres dans 600 dp, elles sont déjà au maximum et l'axe ne change
    // rien.
    final many = [
      for (var i = 0; i < 20; i++)
        const BarChartItem(label: 'J', value: 40, color: AppColors.bleuArdoise),
    ];

    await pumpChart(tester, vertical: false, barItems: many);
    final withAxis = tester.widget<BarChart>(find.byType(BarChart));
    expect(withAxis.data.titlesData.leftTitles.sideTitles.showTitles, isTrue);
    final wideBars = withAxis.data.barGroups.first.barRods.first.width;

    await pumpChart(
      tester,
      vertical: false,
      barItems: many,
      showLeftAxis: false,
    );
    final without = tester.widget<BarChart>(find.byType(BarChart));

    expect(without.data.titlesData.leftTitles.sideTitles.showTitles, isFalse);
    expect(
      without.data.titlesData.leftTitles.sideTitles.reservedSize,
      0,
      reason:
          'un axe masqué qui garderait sa réserve laisserait une marge vide',
    );
    expect(
      without.data.barGroups.first.barRods.first.width,
      greaterThan(wideBars),
      reason: 'les 36 dp de l’axe reviennent aux barres',
    );
  });

  testWidgets('une valeur minuscule garde une hauteur visible', (tester) async {
    // ⚠️ Le cas qui l'impose : une journée à 300 sous un maximum à 9 000 000
    // rend une barre d'une fraction de pixel — indiscernable d'un zéro. Et
    // depuis que les écrans peuvent masquer les barres nulles, une barre non
    // nulle invisible se lit comme un jour supprimé.
    const lopsided = [
      BarChartItem(label: 'A', value: 9000000, color: AppColors.bleuArdoise),
      BarChartItem(label: 'B', value: 300, color: AppColors.bleuArdoise),
      BarChartItem(label: 'C', value: 0, color: AppColors.bleuArdoise),
    ];

    await pumpChart(tester, vertical: false, barItems: lopsided);
    final flat = tester.widget<BarChart>(find.byType(BarChart));
    final unfloored = flat.data.barGroups[1].barRods.first.toY;

    await pumpChart(
      tester,
      vertical: false,
      barItems: lopsided,
      minimumBarHeight: 2,
    );
    final floored = tester.widget<BarChart>(find.byType(BarChart));

    expect(floored.data.barGroups[1].barRods.first.toY, greaterThan(unfloored));
    expect(
      floored.data.barGroups[2].barRods.first.toY,
      0,
      reason:
          'zéro reste zéro — un plancher qui le relèverait ferait voir un '
          'encaissement là où il n’y en a pas',
    );
    expect(
      floored.data.barGroups.first.barRods.first.toY,
      9000000,
      reason: 'une valeur qui dépasse le plancher n’est jamais modifiée',
    );
  });

  testWidgets('les libellés d’axe portent des chiffres de largeur fixe', (
    tester,
  ) async {
    await pumpChart(tester, vertical: false);

    final labels = tester
        .widgetList<Text>(find.byType(Text))
        .where((t) => items.any((item) => item.label == t.data))
        .toList();

    expect(labels, isNotEmpty);
    // L'axe est une RANGÉE de nombres. Sans largeur fixe, « 11 » et « 08 » ne
    // tombent pas au même endroit sous leurs barres : le décalage est d'un
    // pixel par libellé, mais il se cumule sur trente et un jours et fait
    // onduler l'axe.
    for (final label in labels) {
      expect(
        (label.style?.fontFeatures ?? const <FontFeature>[]).any(
          (f) => f.feature == 'tnum',
        ),
        isTrue,
        reason: 'le libellé « ${label.data} » n’est pas tabulaire',
      );
    }
  });

  testWidgets('une barre au plancher annonce sa VRAIE valeur, pas sa hauteur', (
    tester,
  ) async {
    const tiny = [
      BarChartItem(
        label: '01/05',
        value: 1000000,
        color: AppColors.bleuArdoise,
      ),
      BarChartItem(label: '02/05', value: 300, color: AppColors.bleuArdoise),
      BarChartItem(
        label: '03/05',
        value: 7000000,
        color: AppColors.bleuArdoise,
      ),
    ];

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 600,
            child: CycleBarChart(
              items: tiny,
              showValueLabels: true,
              minimumBarHeight: 2,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final data = tester.widget<BarChart>(find.byType(BarChart)).data;
    final group = data.barGroups[1];
    final rod = group.barRods.first;

    // La barre est bien REMONTÉE pour rester visible…
    expect(rod.toY, greaterThan(300));
    // …mais son étiquette dit 300, pas la hauteur à laquelle on l'a dessinée.
    // Le plancher est une décision de DESSIN ; l'étiquette est une donnée. Sur
    // un écran d'argent, un chiffre faux est pire qu'une barre invisible.
    final label = data.barTouchData.touchTooltipData.getTooltipItem(
      group,
      1,
      rod,
      0,
    );
    expect(label?.text, '300');
  });

  testWidgets('sans axe ni étiquettes, le relief garde son montant', (
    tester,
  ) async {
    final many = [
      for (var d = 1; d <= 20; d++)
        BarChartItem(
          label: '${d.toString().padLeft(2, '0')}/05',
          value: 100000.0 * d,
          color: AppColors.bleuArdoise,
        ),
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 900,
            child: CycleBarChart(
              items: many,
              // Le cas d'une fenêtre large : trop de barres pour les chiffrer
              // toutes, et pas d'axe vertical.
              showValueLabels: false,
              showLeftAxis: false,
              highlightedIndexes: const {7},
              labelHighlightedBars: true,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final data = tester.widget<BarChart>(find.byType(BarChart)).data;

    // Seule la barre en relief porte son montant en permanence…
    for (var i = 0; i < data.barGroups.length; i++) {
      expect(
        data.barGroups[i].showingTooltipIndicators.isNotEmpty,
        i == 7,
        reason: 'barre $i',
      );
    }
    // …et sans bulle sombre : c'est un montant posé sur la barre.
    expect(
      data.barTouchData.touchTooltipData.getTooltipColor(data.barGroups[7]),
      Colors.transparent,
    );
    // Sans quoi le relief ne reposerait que sur la couleur, qui ne porte jamais
    // seule une information.
    final label = data.barTouchData.touchTooltipData.getTooltipItem(
      data.barGroups[7],
      7,
      data.barGroups[7].barRods.first,
      0,
    );
    expect(label?.text, isNot(contains('\n')));
    expect(label?.text, '800K');
  });
}
