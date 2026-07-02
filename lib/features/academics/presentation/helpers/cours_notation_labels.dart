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

String periodeLabel(AppLocalizations l10n, PeriodeVm periode) =>
    l10n.courseDetailPeriodLabel(periode.ordre);

String bucketLabel(AppLocalizations l10n, BucketVm bucket) =>
    switch (bucket.kind) {
      BucketKind.sousPeriode => l10n.courseDetailSubPeriodLabel(bucket.ordre),
      BucketKind.examen => l10n.courseDetailExamLabel,
    };

String statutLabel(AppLocalizations l10n, BucketStatut statut) =>
    switch (statut) {
      BucketStatut.closed => l10n.courseDetailStatutClosed,
      BucketStatut.current => l10n.courseDetailStatutCurrent,
      BucketStatut.upcoming => l10n.courseDetailStatutUpcoming,
    };
