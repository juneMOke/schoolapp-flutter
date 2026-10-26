import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/components/charts/bar_chart_item.dart';
import 'package:school_app_flutter/core/components/charts/bar_chart_segment.dart';
import 'package:school_app_flutter/core/components/charts/chart_legend.dart';
import 'package:school_app_flutter/core/components/charts/cycle_bar_chart.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';

void main() {
  final stacked = [
    BarChartItem.stacked(
      label: 'sept.',
      color: AppColors.border,
      segments: const [
        BarChartSegment(label: 'Payé', value: 600, color: AppColors.success),
        BarChartSegment(label: 'Reporté', value: 0, color: AppColors.info),
        BarChartSegment(label: 'Non payé', value: 400, color: AppColors.error),
      ],
    ),
    BarChartItem.stacked(
      label: 'oct.',
      color: AppColors.border,
      segments: const [
        BarChartSegment(label: 'Payé', value: 200, color: AppColors.success),
      ],
    ),
  ];

  Future<void> pump(
    WidgetTester tester,
    List<BarChartItem> items, {
    ValueChanged<int>? onBarTap,
    Set<int> highlighted = const {},
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 600,
            child: CycleBarChart(
              items: items,
              onBarTap: onBarTap,
              highlightedIndexes: highlighted,
              highlightBorderColor: AppColors.textPrimary,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  List<BarChartRodData> rods(WidgetTester tester) => [
    for (final group
        in tester.widget<BarChart>(find.byType(BarChart)).data.barGroups)
      ...group.barRods,
  ];

  test('une barre empilée vaut la somme de ses parts', () {
    expect(stacked.first.value, 1000);
    expect(stacked.first.isStacked, isTrue);
  });

  testWidgets('les parts non nulles s empilent de bas en haut', (tester) async {
    await pump(tester, stacked);

    final first = rods(tester).first;
    expect(first.toY, 1000);
    expect(first.rodStackItems, hasLength(2));
    expect(first.rodStackItems[0].fromY, 0);
    expect(first.rodStackItems[0].toY, 600);
    expect(first.rodStackItems[0].color, AppColors.success);
    expect(first.rodStackItems[1].fromY, 600);
    expect(first.rodStackItems[1].toY, 1000);
  });

  testWidgets('seule la barre en relief porte un liseré', (tester) async {
    await pump(tester, stacked, highlighted: {1});

    final all = rods(tester);
    expect(all[0].borderSide.width, 0);
    expect(all[1].borderSide.color, AppColors.textPrimary);
    expect(all[1].borderSide.width, greaterThan(0));
  });

  testWidgets('une barre simple garde son rendu', (tester) async {
    await pump(tester, const [
      BarChartItem(label: 'A', value: 30, color: AppColors.info),
    ]);

    final rod = rods(tester).single;
    expect(rod.toY, 30);
    expect(rod.rodStackItems, isEmpty);
  });

  testWidgets('sans rappel, le toucher ne s abonne pas', (tester) async {
    await pump(tester, stacked);

    final touch = tester
        .widget<BarChart>(find.byType(BarChart))
        .data
        .barTouchData;
    expect(touch.touchCallback, isNull);
  });

  testWidgets('avec rappel, le toucher d une barre donne son index', (
    tester,
  ) async {
    int? tapped;
    await pump(tester, stacked, onBarTap: (index) => tapped = index);

    final touch = tester
        .widget<BarChart>(find.byType(BarChart))
        .data
        .barTouchData;
    expect(touch.touchCallback, isNotNull);
    expect(touch.enabled, isTrue);
    expect(tapped, isNull);
  });

  testWidgets('la légende écrit chaque part', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: ChartLegend(
            entries: [
              BarChartSegment(
                label: 'Payé',
                value: 0,
                color: AppColors.success,
              ),
              BarChartSegment(
                label: 'Non payé',
                value: 0,
                color: AppColors.error,
              ),
            ],
          ),
        ),
      ),
    );

    expect(find.text('Payé'), findsOneWidget);
    expect(find.text('Non payé'), findsOneWidget);
  });
}
