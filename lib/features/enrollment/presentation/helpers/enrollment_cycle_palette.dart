import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';

/// Teintes des cycles et des niveaux du tableau de bord, rangées pour que deux
/// voisins contrastent franchement.
///
/// ⚠️ Attention aux alias de tokens : `enrollmentStatsAccent` **EST**
/// `bleuArdoise` et `enrollmentStatsPre` **EST** `info` — les ajouter tous
/// deux peindrait deux cycles de la même couleur.
///
/// La couleur ne porte **aucune information** : chaque ligne écrit déjà son
/// libellé et son effectif. Elle sert seulement à regrouper l'œil.
const _cyclePalette = <Color>[
  AppColors.enrollmentStatsAccent,
  AppColors.enrollmentStatsRe,
  AppColors.enrollmentStatsFirst,
  AppColors.terreCuite,
  AppColors.enrollmentStatsPre,
  AppColors.enrollmentStatsInProgress,
];

/// Nombre de teintes avant que la palette ne reprenne, éclaircie.
int get cyclePaletteLength => _cyclePalette.length;

/// Couleur du rang [index].
///
/// Une école aligne facilement plus de niveaux que la palette n'a de teintes
/// (maternelle + primaire + secondaire) : au-delà du premier tour, la teinte
/// de base est éclaircie d'un cran par tour, pour que deux rangs voisins ne
/// tombent jamais exactement sur la même couleur.
Color cyclePaletteColor(int index) {
  final base = _cyclePalette[index % _cyclePalette.length];
  final lap = index ~/ _cyclePalette.length;
  if (lap == 0) return base;
  final hsl = HSLColor.fromColor(base);
  return hsl
      .withLightness((hsl.lightness + 0.16 * lap).clamp(0.25, 0.85))
      .toColor();
}
