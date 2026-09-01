import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/components/charts/bar_chart_item.dart';
import 'package:school_app_flutter/core/components/charts/cycle_bar_chart.dart';
import 'package:school_app_flutter/core/components/charts/donut_chart_section.dart';
import 'package:school_app_flutter/core/components/charts/evolution_line_chart.dart';
import 'package:school_app_flutter/core/components/charts/gender_donut_chart.dart';
import 'package:school_app_flutter/core/components/charts/line_chart_point.dart';
import 'package:school_app_flutter/core/components/motion/eteelo_entrance.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/theme/app_motion.dart';

void main() {
  Widget host(Widget child) => MaterialApp(
    home: Scaffold(body: SizedBox(width: 600, child: child)),
  );

  Widget reducedMotionHost(Widget child) => host(
    MediaQuery(
      data: const MediaQueryData(disableAnimations: true),
      child: child,
    ),
  );

  const bars = [
    BarChartItem(
      label: 'P1',
      value: 30,
      color: AppColors.enrollmentStatsAccent,
    ),
    BarChartItem(label: 'P2', value: 42, color: AppColors.enrollmentStatsFirst),
  ];

  List<double> rods(WidgetTester tester) => tester
      .widgetList<BarChart>(find.byType(BarChart))
      .map((chart) => chart.data.barGroups.first.barRods.first.toY)
      .toList();

  group('CycleBarChart', () {
    testWidgets('les barres poussent depuis la base', (tester) async {
      await tester.pumpWidget(host(const CycleBarChart(items: bars)));

      // Sans entree menee ici, fl_chart naitrait deja a sa valeur finale : ses
      // charts n animent que d un jeu de donnees au suivant, jamais le premier.
      expect(rods(tester).single, 0);

      await tester.pumpAndSettle();

      expect(rods(tester).single, 30);
    });

    testWidgets('reduced-motion : valeur finale des la premiere frame', (
      tester,
    ) async {
      await tester.pumpWidget(
        reducedMotionHost(const CycleBarChart(items: bars)),
      );

      expect(rods(tester).single, 30);
      // La transition d un jeu de donnees au suivant est coupee elle aussi.
      expect(
        tester.widget<BarChart>(find.byType(BarChart)).duration,
        Duration.zero,
      );
    });

    testWidgets('l entree finie, fl_chart reprend la main sur les donnees', (
      tester,
    ) async {
      await tester.pumpWidget(host(const CycleBarChart(items: bars)));
      await tester.pumpAndSettle();

      final chart = tester.widget<BarChart>(find.byType(BarChart));
      expect(chart.duration, AppMotion.entrance);
      expect(chart.curve, AppMotion.outCurve);
    });

    testWidgets('un graphique attend son rang dans la cascade', (tester) async {
      await tester.pumpWidget(
        host(
          const Column(
            children: [
              EteeloEntrance(index: 0, child: CycleBarChart(items: bars)),
              EteeloEntrance(index: 3, child: CycleBarChart(items: bars)),
            ],
          ),
        ),
      );
      // Le minuteur du rang 0 part a la premiere avance du temps ; celui du
      // rang 3 attend 180 ms.
      await tester.pump(AppMotion.stagger);
      await tester.pump(AppMotion.stagger);

      // Se tracer derriere une carte encore transparente reviendrait a ne rien
      // montrer : le dernier rang n a pas encore commence.
      final started = rods(tester);
      expect(started.first, greaterThan(0));
      expect(started.last, 0);

      await tester.pumpAndSettle();

      expect(rods(tester), everyElement(30.0));
    });
  });

  group('EvolutionLineChart', () {
    const points = [
      LineChartPoint(label: 'S1', value: 82),
      LineChartPoint(label: 'S2', value: 91),
      LineChartPoint(label: 'S3', value: 88),
    ];

    List<FlSpot> spots(WidgetTester tester) => tester
        .widget<LineChart>(find.byType(LineChart))
        .data
        .lineBarsData
        .first
        .spots;

    Widget chart() => const EvolutionLineChart(
      points: points,
      lineColor: AppColors.enrollmentStatsAccent,
      highlightColor: AppColors.enrollmentStatsRe,
      minY: 70,
      maxY: 100,
    );

    testWidgets('la courbe se trace de gauche a droite', (tester) async {
      await tester.pumpWidget(host(chart()));

      // Au depart, rien n est encore tire : seul le point d origine existe.
      expect(spots(tester), hasLength(1));
      expect(spots(tester).single.x, 0);

      await tester.pump(AppMotion.stagger);
      await tester.pump(AppMotion.stagger);

      // A mi-parcours la tete est entre deux points, jamais calee sur l un
      // d eux : sans elle le trace avancerait par a-coups.
      final partial = spots(tester);
      expect(partial.length, lessThan(points.length + 1));
      expect(partial.last.x, greaterThan(0));
      expect(partial.last.x, lessThan((points.length - 1).toDouble()));
      // Les points deja franchis gardent leur valeur reelle : l echelle ne
      // bouge pas pendant le trace.
      expect(partial.first.y, 82);

      await tester.pumpAndSettle();

      expect(spots(tester).map((s) => s.y), [82.0, 91.0, 88.0]);
    });

    testWidgets('reduced-motion : courbe complete des la premiere frame', (
      tester,
    ) async {
      await tester.pumpWidget(reducedMotionHost(chart()));

      expect(spots(tester).map((s) => s.y), [82.0, 91.0, 88.0]);
    });
  });

  group('GenderDonutChart', () {
    const sections = [
      DonutChartSection(
        label: 'Garcons',
        count: 24,
        percent: 60,
        color: AppColors.enrollmentStatsMale,
      ),
      DonutChartSection(
        label: 'Filles',
        count: 16,
        percent: 40,
        color: AppColors.enrollmentStatsFemale,
      ),
    ];

    List<PieChartSectionData> pieSections(WidgetTester tester) =>
        tester.widget<PieChart>(find.byType(PieChart)).data.sections;

    Widget chart() => const GenderDonutChart(
      sections: sections,
      total: 40,
      centerLabel: 'eleves',
    );

    testWidgets('l anneau se deroule derriere une section fantome', (
      tester,
    ) async {
      await tester.pumpWidget(host(chart()));

      var drawn = pieSections(tester);
      // Le fantome ferme le cercle : les parts reelles sont a zero et fl_chart
      // ne dessine rien tant qu il occupe tout le tour.
      expect(drawn, hasLength(sections.length + 1));
      expect(
        drawn.take(sections.length).map((s) => s.value),
        everyElement(0.0),
      );
      expect(drawn.last.value, 100.0);
      expect(drawn.last.color, Colors.transparent);

      await tester.pumpAndSettle();

      drawn = pieSections(tester);
      // A l arrivee le fantome est nul : fl_chart saute les sections nulles,
      // il ne laisse donc ni angle ni separateur dans l anneau.
      expect(drawn.take(sections.length).map((s) => s.value), [60.0, 40.0]);
      expect(drawn.last.value, 0.0);
    });

    testWidgets('le total central monte au rythme du balayage', (tester) async {
      await tester.pumpWidget(host(chart()));

      expect(find.text('0'), findsOneWidget);
      expect(find.text('40'), findsNothing);

      await tester.pumpAndSettle();

      expect(find.text('40'), findsOneWidget);
    });

    testWidgets('reduced-motion : anneau et total complets des la premiere '
        'frame', (tester) async {
      await tester.pumpWidget(reducedMotionHost(chart()));

      final drawn = pieSections(tester);
      expect(drawn.take(sections.length).map((s) => s.value), [60.0, 40.0]);
      expect(drawn.last.value, 0.0);
      expect(find.text('40'), findsOneWidget);
    });
  });
}
