import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/components/charts/donut_chart_section.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/enrollment_stats.dart';
import 'package:school_app_flutter/features/enrollment/presentation/helpers/level_code_sorter.dart';

/// Teintes des parts du donut « Répartition des effectifs par classe », rangées
/// pour que deux classes voisines contrastent franchement.
///
/// Attention aux alias de tokens : `enrollmentStatsAccent` EST `bleuArdoise` et
/// `enrollmentStatsPre` EST `info` — les ajouter tous deux peindrait deux
/// classes de la même couleur.
const _levelPalette = <Color>[
  AppColors.enrollmentStatsAccent,
  AppColors.enrollmentStatsRe,
  AppColors.enrollmentStatsFirst,
  AppColors.terreCuite,
  AppColors.enrollmentStatsPre,
  AppColors.enrollmentStatsInProgress,
];

/// Nombre de teintes avant que la palette ne reprenne, éclaircie.
int get levelDonutPaletteLength => _levelPalette.length;

/// Couleur de la part [index], dans l'ordre pédagogique des niveaux.
///
/// Une école aligne facilement plus de niveaux que la palette n'a de teintes
/// (maternelle + primaire + secondaire) : au-delà du premier tour, la teinte de
/// base est éclaircie d'un cran par tour, pour que deux parts voisines ne
/// tombent jamais exactement sur la même couleur.
Color levelDonutColor(int index) {
  final base = _levelPalette[index % _levelPalette.length];
  final lap = index ~/ _levelPalette.length;
  if (lap == 0) return base;
  final hsl = HSLColor.fromColor(base);
  return hsl
      .withLightness((hsl.lightness + 0.16 * lap).clamp(0.25, 0.85))
      .toColor();
}

/// Parts du donut « Répartition des effectifs par classe » et effectif total.
///
/// Agrège les effectifs par code de niveau, tous cycles confondus — comme
/// l'histogramme qu'il remplace — puis les ordonne par effectif décroissant :
/// la légende se lit comme l'anneau, de la plus grosse classe à la plus petite.
/// À effectif égal, l'ordre pédagogique ([compareLevelCodes]) départage, sinon
/// deux classes ex æquo changeraient de place d'une période à l'autre.
///
/// Les niveaux à effectif nul sont écartés : une part de 0 % ne se dessine pas
/// et n'encombre que la légende.
({List<DonutChartSection> sections, int total}) buildLevelDonut(
  CycleDistribution distribution,
) {
  final levelTotals = <String, int>{};
  for (final cycle in distribution.cycles) {
    for (final level in cycle.levels) {
      levelTotals[level.code] = (levelTotals[level.code] ?? 0) + level.value;
    }
  }

  final entries = levelTotals.entries.where((entry) => entry.value > 0).toList()
    ..sort((a, b) {
      final byCount = b.value.compareTo(a.value);
      return byCount != 0 ? byCount : compareLevelCodes(a.key, b.key);
    });

  final total = entries.fold<int>(0, (sum, entry) => sum + entry.value);

  return (
    sections: [
      for (var i = 0; i < entries.length; i++)
        DonutChartSection(
          label: entries[i].key,
          count: entries[i].value,
          percent: total == 0 ? 0 : entries[i].value / total * 100,
          color: levelDonutColor(i),
        ),
    ],
    total: total,
  );
}

/// Disposition de la carte « Répartition des effectifs par classe ».
///
/// Une école aligne bien plus de classes que le donut du genre n'a de segments :
/// en une seule colonne, la légende déborde la hauteur de carte et les
/// dernières classes ne sont atteignables qu'au défilement — c'est-à-dire
/// invisibles. Au-delà de [_singleColumnMax] entrées la légende passe sur deux
/// colonnes, et la carte grandit juste assez pour les tenir, sans dépasser
/// [AppDimensions.enrollmentStatsDonutMaxHeight]. Le plancher est plus haut que
/// les autres cartes du dashboard : c'est lui qui donne son diamètre à
/// l'anneau, qui occupe la hauteur disponible.
({int columns, double height}) levelDonutLayout(int sectionCount) {
  final columns = sectionCount > _singleColumnMax ? 2 : 1;
  final rows = (sectionCount / columns).ceil();
  final wanted =
      rows * AppDimensions.enrollmentStatsDonutLegendRowHeight +
      AppDimensions.spacingS;
  return (
    columns: columns,
    height: wanted.clamp(
      AppDimensions.enrollmentStatsLevelDonutMinHeight,
      AppDimensions.enrollmentStatsDonutMaxHeight,
    ),
  );
}

/// Nombre d'entrées de légende encore lisibles sur une seule colonne.
const _singleColumnMax = 5;
