import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/features/course_programme/domain/entities/chapitre_enums.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Tonalité, icône et libellé d'un statut de chapitre — jamais la couleur
/// seule : badge = icône + texte.
class ChapitreStatutVisual {
  final Color accent;
  final Color soft;
  final IconData icon;

  const ChapitreStatutVisual._(this.accent, this.soft, this.icon);

  static ChapitreStatutVisual of(ChapitreStatut statut) => switch (statut) {
    ChapitreStatut.planifie => const ChapitreStatutVisual._(
      AppColors.programmePlanifie,
      AppColors.programmePlanifieSoft,
      Icons.event_outlined,
    ),
    ChapitreStatut.enCours => const ChapitreStatutVisual._(
      AppColors.programmeEnCours,
      AppColors.programmeEnCoursSoft,
      Icons.edit_outlined,
    ),
    ChapitreStatut.termine => const ChapitreStatutVisual._(
      AppColors.programmeTermine,
      AppColors.programmeTermineSoft,
      Icons.check_circle_outline_rounded,
    ),
  };

  static String label(AppLocalizations l10n, ChapitreStatut statut) =>
      switch (statut) {
        ChapitreStatut.planifie => l10n.chapitreStatutPlanifie,
        ChapitreStatut.enCours => l10n.chapitreStatutEnCours,
        ChapitreStatut.termine => l10n.chapitreStatutTermine,
      };
}
