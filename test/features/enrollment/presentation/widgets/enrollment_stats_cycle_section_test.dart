import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/components/charts/gender_donut_chart.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/enrollment_stats.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/enrollment_stats_cycle_section.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

void main() {
  Future<void> pumpSection(
    WidgetTester tester,
    CycleDistribution distribution,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('fr'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: Scaffold(
          body: EnrollmentStatsCycleSection(distribution: distribution),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  const distribution = CycleDistribution(
    cycles: [
      CycleStat(
        code: 'PRIM',
        total: 70,
        levels: [
          LevelStat(code: 'P1', value: 30),
          LevelStat(code: 'P2', value: 40),
        ],
      ),
    ],
  );

  testWidgets('affiche un etat vide quand la distribution cycle est vide', (
    tester,
  ) async {
    await pumpSection(tester, const CycleDistribution(cycles: []));

    expect(find.text('Aucune donnée pour cette période'), findsOneWidget);
    expect(find.byType(GenderDonutChart), findsNothing);
  });

  testWidgets('rend la repartition des effectifs en anneau', (tester) async {
    await pumpSection(tester, distribution);

    final donut = tester.widget<GenderDonutChart>(
      find.byType(GenderDonutChart),
    );

    expect(find.text('Répartition des effectifs par classe'), findsOneWidget);
    expect(donut.total, 70);
    // P2 (40) passe devant P1 (30) : de la plus grosse a la plus petite.
    expect(donut.sections.map((s) => s.label), ['P2', 'P1']);
  });

  testWidgets('la legende dit l effectif et la part de chaque classe', (
    tester,
  ) async {
    await pumpSection(tester, distribution);

    // L information n est jamais portee par la seule couleur.
    expect(find.text('P1'), findsOneWidget);
    expect(find.text('30  ·  42 %'), findsOneWidget);
    expect(find.text('40  ·  57 %'), findsOneWidget);
  });

  testWidgets('une distribution a effectif nul reste un etat vide', (
    tester,
  ) async {
    await pumpSection(
      tester,
      const CycleDistribution(
        cycles: [
          CycleStat(
            code: 'PRIM',
            total: 0,
            levels: [LevelStat(code: 'P1', value: 0)],
          ),
        ],
      ),
    );

    expect(find.text('Aucune donnée pour cette période'), findsOneWidget);
  });

  testWidgets('toutes les classes restent dans la carte, sans defilement', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1180, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await pumpSection(
      tester,
      const CycleDistribution(
        cycles: [
          CycleStat(
            code: 'MAT',
            total: 96,
            levels: [
              LevelStat(code: 'M1', value: 34),
              LevelStat(code: 'M2', value: 31),
              LevelStat(code: 'M3', value: 31),
            ],
          ),
          CycleStat(
            code: 'PRIM',
            total: 268,
            levels: [
              LevelStat(code: 'P1', value: 58),
              LevelStat(code: 'P2', value: 51),
              LevelStat(code: 'P3', value: 46),
              LevelStat(code: 'P4', value: 42),
              LevelStat(code: 'P5', value: 38),
              LevelStat(code: 'P6', value: 33),
            ],
          ),
        ],
      ),
    );

    // La derniere classe de la legende doit tenir DANS la carte : en une seule
    // colonne elle tombait sous le bord, atteignable au seul defilement.
    final card = tester.getRect(find.byType(GenderDonutChart));
    final lastLegendEntry = tester.getRect(find.text('P6'));

    expect(lastLegendEntry.bottom, lessThanOrEqualTo(card.bottom));
    expect(lastLegendEntry.right, lessThanOrEqualTo(card.right));
  });

  testWidgets('l anneau occupe toute la hauteur de la carte', (tester) async {
    tester.view.physicalSize = const Size(1180, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await pumpSection(tester, distribution);

    final data = tester.widget<PieChart>(find.byType(PieChart)).data;
    final outerRadius = data.centerSpaceRadius + data.sections.first.radius;
    final card = tester.getSize(find.byType(GenderDonutChart));

    // Le diametre suit la hauteur disponible, aux marges pres : c est ce qui
    // distingue cet anneau des donuts a rayon fixe du reste de l app.
    expect(
      outerRadius * 2,
      closeTo(card.height - 2 * AppDimensions.spacingS, 1),
    );
  });
}
