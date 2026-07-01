import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/features/academics/domain/entities/notation/type_evaluation.dart';

/// Statut tri-état dérivé (spec §8) d'une période / sous-période / examen.
/// Le contrat backend n'expose que `ouverte`/`cloturee` : « en cours » vs « à
/// venir » est dérivé de l'avancement (cf. `CoursNotationViewModel`).
enum BucketStatut { closed, current, upcoming }

/// État d'avancement d'une évaluation (spec §5) : toutes les notes saisies,
/// saisie partielle, ou rien saisi (à venir).
enum EvalState { complete, partial, upcoming }

/// Couleur + voile doux + icône d'un type d'évaluation (carré de type, §5).
({Color color, Color soft, IconData icon}) evalTypeVisual(
  TypeEvaluation type,
) => switch (type) {
  TypeEvaluation.interro => (
    color: AppColors.academicsInterro,
    soft: AppColors.academicsInterroSoft,
    icon: Icons.edit_outlined,
  ),
  TypeEvaluation.devoir => (
    color: AppColors.academicsDevoir,
    soft: AppColors.academicsDevoirSoft,
    icon: Icons.assignment_outlined,
  ),
  TypeEvaluation.examen => (
    color: AppColors.academicsExamen,
    soft: AppColors.academicsExamenSoft,
    icon: Icons.school_outlined,
  ),
  TypeEvaluation.unknown => (
    color: AppColors.textMuted,
    soft: AppColors.surfaceAlt,
    icon: Icons.help_outline_rounded,
  ),
};

/// Couleur + voile doux d'un statut tri-état (médaillon / pastille / sélection).
({Color color, Color soft}) bucketStatutVisual(BucketStatut statut) =>
    switch (statut) {
      BucketStatut.closed => (
        color: AppColors.academicsStatutClosed,
        soft: AppColors.academicsStatutClosedSoft,
      ),
      BucketStatut.current => (
        color: AppColors.academicsStatutCurrent,
        soft: AppColors.academicsStatutCurrentSoft,
      ),
      BucketStatut.upcoming => (
        color: AppColors.academicsStatutUpcoming,
        soft: AppColors.academicsStatutUpcomingSoft,
      ),
    };

/// Couleur + voile doux du badge d'avancement d'une évaluation (§5).
({Color color, Color soft}) evalStateVisual(EvalState state) => switch (state) {
  EvalState.complete => (
    color: AppColors.academicsStatutClosed,
    soft: AppColors.academicsStatutClosedSoft,
  ),
  EvalState.partial => (
    color: AppColors.academicsStatutCurrent,
    soft: AppColors.academicsStatutCurrentSoft,
  ),
  EvalState.upcoming => (
    color: AppColors.academicsStatutUpcoming,
    soft: AppColors.academicsStatutUpcomingSoft,
  ),
};

/// Date courte localisée d'une évaluation (ex. « 12 mai 2026 » / « May 12 2026 »).
/// Passe par [MaterialLocalizations] pour éviter une dépendance directe à `intl`.
String formatEvalDate(BuildContext context, DateTime date) {
  final ml = MaterialLocalizations.of(context);
  return '${ml.formatShortMonthDay(date)} ${ml.formatYear(date)}';
}

/// Formate un nombre de points sans décimale superflue (10 → « 10 », 7.5 →
/// « 7.5 »).
String formatPoints(double value) {
  if (value == value.roundToDouble()) return value.toStringAsFixed(0);
  return value.toStringAsFixed(1).replaceFirst(RegExp(r'\.0$'), '');
}

/// Formate un pourcentage entier (64.0 → « 64 % »).
String formatPercent(double value) => '${value.round()} %';

/// Tonalité (couleur + voile doux) d'un pourcentage de note globale (spec §9) :
/// < 50 % échec (rouge) · 50–59 % fragile (ambre) · ≥ 60 % bonne (vert).
({Color color, Color soft}) scoreTone(double percent) {
  if (percent < 50) {
    return (
      color: AppColors.academicsScoreFail,
      soft: AppColors.academicsScoreFailSoft,
    );
  }
  if (percent < 60) {
    return (
      color: AppColors.academicsScoreWeak,
      soft: AppColors.academicsScoreWeakSoft,
    );
  }
  return (
    color: AppColors.academicsScoreGood,
    soft: AppColors.academicsScoreGoodSoft,
  );
}
