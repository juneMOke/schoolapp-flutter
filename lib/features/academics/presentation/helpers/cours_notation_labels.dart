import 'package:school_app_flutter/features/academics/domain/entities/notation/type_evaluation.dart';
import 'package:school_app_flutter/features/academics/presentation/helpers/academics_notation_visuals.dart';
import 'package:school_app_flutter/features/academics/presentation/helpers/cours_notation_view_model.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Libellés localisés dérivés du view-model (centralisés pour cohérence entre
/// les onglets, la frise, le panneau et le relevé).

/// Libellé d'un type d'évaluation (eyebrow de l'en-tête, cartes de type).
String typeEvaluationLabel(AppLocalizations l10n, TypeEvaluation type) =>
    switch (type) {
      TypeEvaluation.interro => l10n.evalTypeInterro,
      TypeEvaluation.devoir => l10n.evalTypeDevoir,
      TypeEvaluation.examen => l10n.evalTypeExamen,
      TypeEvaluation.unknown => l10n.evalTypeInterro,
    };

/// Libellé d'une période scolaire selon le découpage : « Semestre N » /
/// « Trimestre N ». Partagé par les onglets de la page détail et la cascade de
/// la modale de création (qui travaille sur `PeriodeNotation`, sans view-model).
String periodeScolaireLabel(
  AppLocalizations l10n,
  int ordre,
  PeriodeDecoupage decoupage,
) => switch (decoupage) {
  PeriodeDecoupage.semestre => l10n.courseDetailSemesterLabel(ordre),
  PeriodeDecoupage.trimestre => l10n.courseDetailTrimesterLabel(ordre),
};

/// Libellé d'un onglet de premier niveau (spec §2), dérivé du [PeriodeVm].
String periodeLabel(AppLocalizations l10n, PeriodeVm periode) =>
    periodeScolaireLabel(l10n, periode.ordre, periode.decoupage);

/// Nom du découpage au singulier, pour le libellé de champ « période scolaire »
/// de la modale de création : « Semestre » / « Trimestre » (dynamique).
String decoupageFieldLabel(AppLocalizations l10n, PeriodeDecoupage decoupage) =>
    switch (decoupage) {
      PeriodeDecoupage.semestre => l10n.evalCreateFieldSemestre,
      PeriodeDecoupage.trimestre => l10n.evalCreateFieldTrimestre,
    };

/// Libellé d'un pas de la frise : « Période N » pour une sous-période (renommée
/// côté UI), « Examen » pour l'examen de période.
String bucketLabel(AppLocalizations l10n, BucketVm bucket) =>
    switch (bucket.kind) {
      BucketKind.sousPeriode => l10n.courseDetailPeriodLabel(bucket.ordre),
      BucketKind.examen => l10n.courseDetailExamLabel,
    };

String statutLabel(AppLocalizations l10n, BucketStatut statut) =>
    switch (statut) {
      BucketStatut.closed => l10n.courseDetailStatutClosed,
      BucketStatut.current => l10n.courseDetailStatutCurrent,
      BucketStatut.upcoming => l10n.courseDetailStatutUpcoming,
    };
