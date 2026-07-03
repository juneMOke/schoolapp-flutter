import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';

/// Tonalité d'un pourcentage autour du seuil de réussite (spec §5).
///
/// [none] = valeur `null` (« non noté », rendu « — »).
enum ResultatsPctTone { fail, neutral, good, none }

/// Code couleur des pourcentages et des notes, piloté par le seuil de réussite
/// (retourné par le backend dans `stats.seuil`). Logique pure et testable, sans
/// dépendance UI/l10n : `< seuil` → rouge ; `≥ seuil+20` → vert savane ; entre
/// les deux → neutre (texte primaire, barre bleu ardoise) ; `null` → sourdine.
class ResultatsScorePalette {
  const ResultatsScorePalette._();

  /// Écart au-dessus du seuil à partir duquel un score bascule « vert » (§5).
  static const double goodBand = 20;

  static ResultatsPctTone toneFor(double? pourcentage, double seuil) {
    if (pourcentage == null) {
      return ResultatsPctTone.none;
    }
    if (pourcentage < seuil) {
      return ResultatsPctTone.fail;
    }
    if (pourcentage >= seuil + goodBand) {
      return ResultatsPctTone.good;
    }
    return ResultatsPctTone.neutral;
  }

  /// Couleur du texte du pourcentage.
  static Color textColor(ResultatsPctTone tone) => switch (tone) {
    ResultatsPctTone.fail => AppColors.error,
    ResultatsPctTone.neutral => AppColors.textPrimary,
    ResultatsPctTone.good => AppColors.vertSavane,
    ResultatsPctTone.none => AppColors.textMuted,
  };

  /// Couleur de la mini-barre du pourcentage.
  static Color barColor(ResultatsPctTone tone) => switch (tone) {
    ResultatsPctTone.fail => AppColors.error,
    ResultatsPctTone.neutral => AppColors.bleuArdoise,
    ResultatsPctTone.good => AppColors.vertSavane,
    ResultatsPctTone.none => AppColors.border,
  };

  /// Couleur d'une cellule `note / max` du bulletin par domaine (§8) : rouge si
  /// le ratio est sous le seuil, sinon texte primaire. `max == 0` → neutre.
  static Color noteColor(double obtenu, double max, double seuil) {
    if (max <= 0) {
      return AppColors.textPrimary;
    }
    return (obtenu / max) * 100 < seuil
        ? AppColors.error
        : AppColors.textPrimary;
  }
}
