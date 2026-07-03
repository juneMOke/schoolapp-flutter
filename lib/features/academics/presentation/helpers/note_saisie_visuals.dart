import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/features/academics/domain/entities/notation/statut_note.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Couleur + voile doux + icône d'un statut de note (spec §11) : pastilles de
/// ligne, compteurs par statut et fil de progression du mode Focus.
///
/// Reprend les tokens `academics*` : NOTEE vert (clôturée), EN_ATTENTE neutre,
/// ABSENT_JUSTIFIE ambre (en cours), ABSENT_NON_JUSTIFIE rouge (échec).
({Color color, Color soft, IconData icon}) noteStatutVisual(
  StatutNote statut,
) => switch (statut) {
  StatutNote.notee => (
    color: AppColors.academicsStatutClosed,
    soft: AppColors.academicsStatutClosedSoft,
    icon: Icons.check_circle_outline_rounded,
  ),
  StatutNote.enAttente => (
    color: AppColors.academicsStatutUpcoming,
    soft: AppColors.academicsStatutUpcomingSoft,
    icon: Icons.schedule_rounded,
  ),
  StatutNote.absentJustifie => (
    color: AppColors.academicsStatutCurrent,
    soft: AppColors.academicsStatutCurrentSoft,
    icon: Icons.schedule_rounded,
  ),
  StatutNote.absentNonJustifie => (
    color: AppColors.academicsScoreFail,
    soft: AppColors.academicsScoreFailSoft,
    icon: Icons.block_rounded,
  ),
  // Repli défensif : ne devrait jamais survenir dans un brouillon (le statut
  // y est toujours dérivé parmi les 4 valeurs ci-dessus).
  StatutNote.unknown => (
    color: AppColors.textMuted,
    soft: AppColors.surfaceAlt,
    icon: Icons.help_outline_rounded,
  ),
};

/// Libellé court d'un statut de note (pastille de ligne, spec §8/§11).
String noteStatutLabel(AppLocalizations l10n, StatutNote statut) =>
    switch (statut) {
      StatutNote.notee => l10n.evalStatutNotee,
      StatutNote.enAttente => l10n.evalStatutEnAttente,
      StatutNote.absentJustifie => l10n.evalStatutAbsJust,
      StatutNote.absentNonJustifie => l10n.evalStatutAbsNonJust,
      StatutNote.unknown => l10n.evalStatutEnAttente,
    };

/// Libellé « {n} {statut} » d'un compteur par statut (barre de mode, spec §7).
String noteStatutCountLabel(
  AppLocalizations l10n,
  StatutNote statut,
  int count,
) => switch (statut) {
  StatutNote.notee => l10n.evalCountNotee(count),
  StatutNote.enAttente => l10n.evalCountEnAttente(count),
  StatutNote.absentJustifie => l10n.evalCountAbsJust(count),
  StatutNote.absentNonJustifie => l10n.evalCountAbsNonJust(count),
  StatutNote.unknown => l10n.evalCountEnAttente(count),
};

/// Ordre d'affichage stable des statuts dans les compteurs (spec §7).
const List<StatutNote> noteStatutCountOrder = [
  StatutNote.notee,
  StatutNote.enAttente,
  StatutNote.absentJustifie,
  StatutNote.absentNonJustifie,
];
