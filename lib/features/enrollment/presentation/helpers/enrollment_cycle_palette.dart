import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';

/// Teintes des cycles et des niveaux du tableau de bord.
///
/// ## La couleur est clé sur le CODE du cycle, jamais sur son rang
///
/// La version précédente colorait par position dans la liste
/// (`cyclePaletteColor(i)`). Or « Par cycle » trie par effectif décroissant :
/// un cycle changeait donc de couleur dès que son classement changeait, d'une
/// fenêtre à l'autre. Une teinte qui bouge se lit comme une information ; ici
/// elle n'en portait aucune.
///
/// ## Pourquoi une table d'alias et pas un enum
///
/// ⚠️ Le code de cycle **n'est pas un enum**. Côté serveur il vient de
/// `school_level_groups.code`, dont l'unicité est posée par année scolaire
/// (`ux_levelgroups_code (academic_year_id, code)`) : c'est de la
/// **configuration par école**, libre. La spec suppose à tort trois cycles
/// figés. On reconnaît donc les familles usuelles — en français comme en
/// anglais, au singulier comme préfixées — et **tout code inconnu retombe sur
/// un repli déterministe**, pas sur un rang.
///
/// La couleur ne porte **aucune information** : chaque ligne écrit déjà son
/// libellé et son effectif. Elle sert seulement à regrouper l'œil.
const _cyclePalette = <Color>[
  AppColors.enrollmentStatsCyclePrimaire,
  AppColors.enrollmentStatsCycleSecondaire,
  AppColors.enrollmentStatsCycleMaternelle,
  AppColors.vertSavane,
  AppColors.orDoux,
  AppColors.enrollmentStatsInProgress,
];

/// Nombre de teintes avant que la palette ne reprenne, éclaircie.
int get cyclePaletteLength => _cyclePalette.length;

/// Fragments qui identifient une famille de cycle, dans l'ordre d'examen.
///
/// Des **fragments** et non des codes exacts : une école écrit « MATERNELLE »,
/// une autre « CYCLE_MATERNEL », une troisième « PRESCOLAIRE ».
const _cycleFamilies = <(List<String>, Color)>[
  (
    ['MATERNEL', 'PRESCOL', 'PRESCHOOL', 'KINDER', 'NURSER'],
    AppColors.enrollmentStatsCycleMaternelle,
  ),
  (
    ['PRIMAIR', 'PRIMARY', 'ELEMENT', 'EB', 'BASE'],
    AppColors.enrollmentStatsCyclePrimaire,
  ),
  (
    ['SECOND', 'COLLEG', 'LYCEE', 'HUMANIT', 'HIGH'],
    AppColors.enrollmentStatsCycleSecondaire,
  ),
];

/// Majuscules, sans accents ni séparateurs — pour que « Pré-scolaire »,
/// « PRESCOLAIRE » et « pre_scolaire » se reconnaissent tous les trois.
String _normalize(String code) {
  const accents = 'ÀÁÂÃÄÅÇÈÉÊËÌÍÎÏÑÒÓÔÕÖÙÚÛÜÝ';
  const plain = 'AAAAAACEEEEIIIINOOOOOUUUUY';
  final buffer = StringBuffer();
  for (final rune in code.toUpperCase().runes) {
    final char = String.fromCharCode(rune);
    final accentIndex = accents.indexOf(char);
    final normalized = accentIndex == -1 ? char : plain[accentIndex];
    // Chiffres gardés : « EB1 » et « EB2 » ne sont pas le même cycle.
    if (RegExp(r'[A-Z0-9]').hasMatch(normalized)) buffer.write(normalized);
  }
  return buffer.toString();
}

/// FNV-1a 32 bits — un hachage **stable**, écrit ici plutôt qu'emprunté à
/// `String.hashCode`, dont la valeur n'est garantie ni entre deux exécutions
/// ni entre deux versions du VM. La stabilité EST la propriété recherchée.
int _stableHash(String value) {
  var hash = 0x811C9DC5;
  for (final unit in value.codeUnits) {
    hash ^= unit;
    hash = (hash * 0x01000193) & 0xFFFFFFFF;
  }
  return hash;
}

/// La teinte d'un cycle, déduite de son seul [code].
///
/// Même code ⇒ même couleur, quel que soit le tri, le nombre de cycles
/// affichés ou la fenêtre choisie.
Color cycleColorForCode(String code) {
  final normalized = _normalize(code);
  if (normalized.isEmpty) return _cyclePalette.first;

  for (final (fragments, color) in _cycleFamilies) {
    for (final fragment in fragments) {
      if (normalized.contains(fragment)) return color;
    }
  }

  // Repli déterministe : le code, pas le rang.
  return cyclePaletteColor(_stableHash(normalized) % cyclePaletteLength);
}

/// Couleur du rang [index].
///
/// Sert le repli et les listes qui n'ont pas de code de cycle sous la main. Au
/// delà du premier tour, la teinte de base est éclaircie d'un cran par tour,
/// pour que deux rangs voisins ne tombent jamais exactement sur la même
/// couleur.
Color cyclePaletteColor(int index) {
  final base = _cyclePalette[index % _cyclePalette.length];
  final lap = index ~/ _cyclePalette.length;
  if (lap == 0) return base;
  final hsl = HSLColor.fromColor(base);
  return hsl
      .withLightness((hsl.lightness + 0.16 * lap).clamp(0.25, 0.85))
      .toColor();
}
