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
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 600,
            child: CycleBarChart(
              items: barItems,
              verticalBottomLabels: vertical,
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
}
