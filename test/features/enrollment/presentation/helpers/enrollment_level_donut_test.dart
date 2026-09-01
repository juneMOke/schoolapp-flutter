import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/enrollment_stats.dart';
import 'package:school_app_flutter/features/enrollment/presentation/helpers/enrollment_level_donut.dart';

void main() {
  group('buildLevelDonut', () {
    test('agrege les effectifs par code de niveau, tous cycles confondus', () {
      const distribution = CycleDistribution(
        cycles: [
          CycleStat(
            code: 'MAT',
            total: 20,
            levels: [LevelStat(code: 'M1', value: 20)],
          ),
          CycleStat(
            code: 'PRIM',
            total: 55,
            levels: [
              LevelStat(code: 'P2', value: 25),
              LevelStat(code: 'P1', value: 30),
            ],
          ),
        ],
      );

      final donut = buildLevelDonut(distribution);

      expect(donut.total, 75);
      // De la plus grosse classe a la plus petite, pas l ordre d arrivee.
      expect(donut.sections.map((s) => s.label), ['P1', 'P2', 'M1']);
      expect(donut.sections.map((s) => s.count), [30, 25, 20]);
    });

    test('le pourcentage rapporte la classe a l effectif total', () {
      const distribution = CycleDistribution(
        cycles: [
          CycleStat(
            code: 'PRIM',
            total: 100,
            levels: [
              LevelStat(code: 'P1', value: 25),
              LevelStat(code: 'P2', value: 75),
            ],
          ),
        ],
      );

      final donut = buildLevelDonut(distribution);

      expect(donut.sections.map((s) => s.percent), [75.0, 25.0]);
    });

    test('un meme code present dans deux cycles est cumule', () {
      const distribution = CycleDistribution(
        cycles: [
          CycleStat(
            code: 'A',
            total: 10,
            levels: [LevelStat(code: 'P1', value: 10)],
          ),
          CycleStat(
            code: 'B',
            total: 5,
            levels: [LevelStat(code: 'P1', value: 5)],
          ),
        ],
      );

      final donut = buildLevelDonut(distribution);

      expect(donut.sections, hasLength(1));
      expect(donut.sections.single.count, 15);
    });

    test('une classe vide n encombre pas la legende', () {
      const distribution = CycleDistribution(
        cycles: [
          CycleStat(
            code: 'PRIM',
            total: 30,
            levels: [
              LevelStat(code: 'P1', value: 30),
              LevelStat(code: 'P2', value: 0),
            ],
          ),
        ],
      );

      final donut = buildLevelDonut(distribution);

      expect(donut.sections.map((s) => s.label), ['P1']);
    });

    test('a effectif egal, l ordre pedagogique departage', () {
      // Sans ce depart, deux classes ex aequo changeraient de place d une
      // periode a l autre, au gre de l ordre de la Map.
      const distribution = CycleDistribution(
        cycles: [
          CycleStat(
            code: 'PRIM',
            total: 60,
            levels: [
              LevelStat(code: 'P3', value: 20),
              LevelStat(code: 'P1', value: 20),
              LevelStat(code: 'P2', value: 20),
            ],
          ),
        ],
      );

      final donut = buildLevelDonut(distribution);

      expect(donut.sections.map((s) => s.label), ['P1', 'P2', 'P3']);
    });

    test('une distribution vide ne produit aucune part', () {
      final donut = buildLevelDonut(const CycleDistribution(cycles: []));

      expect(donut.total, 0);
      expect(donut.sections, isEmpty);
    });
  });

  group('levelDonutColor', () {
    test(
      'les classes d un meme tour de palette ont des teintes distinctes',
      () {
        final firstLap = [
          for (var i = 0; i < levelDonutPaletteLength; i++) levelDonutColor(i),
        ];

        expect(firstLap.toSet(), hasLength(firstLap.length));
      },
    );

    test('au dela de la palette, la teinte est eclaircie, pas reprise', () {
      // Une ecole aligne facilement plus de niveaux que la palette n a de
      // teintes : sans ce decalage, deux classes porteraient exactement la
      // meme couleur.
      expect(
        levelDonutColor(levelDonutPaletteLength),
        isNot(levelDonutColor(0)),
      );
      expect(
        levelDonutColor(2 * levelDonutPaletteLength),
        isNot(levelDonutColor(levelDonutPaletteLength)),
      );
    });
  });

  group('levelDonutLayout', () {
    test('une poignee de classes tient sur une colonne', () {
      final layout = levelDonutLayout(4);

      expect(layout.columns, 1);
      // Le plancher de la carte : il donne son diametre a l anneau.
      expect(layout.height, AppDimensions.enrollmentStatsLevelDonutMinHeight);
    });

    test('au-dela, la legende passe sur deux colonnes', () {
      // 9 classes (3 maternelles + 6 primaires) : en une colonne les quatre
      // dernieres sortaient de la carte.
      final layout = levelDonutLayout(9);

      expect(layout.columns, 2);
    });

    test('la carte grandit juste assez pour tenir la legende', () {
      final layout = levelDonutLayout(15);

      expect(layout.columns, 2);
      expect(
        layout.height,
        greaterThan(AppDimensions.enrollmentStatsLevelDonutMinHeight),
      );
      expect(
        layout.height,
        (15 / 2).ceil() * AppDimensions.enrollmentStatsDonutLegendRowHeight +
            AppDimensions.spacingS,
      );
    });

    test('la hauteur reste plafonnee sur un referentiel demesure', () {
      expect(
        levelDonutLayout(60).height,
        AppDimensions.enrollmentStatsDonutMaxHeight,
      );
    });
  });
}
