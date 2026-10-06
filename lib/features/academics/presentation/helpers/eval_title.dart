import 'package:flutter/widgets.dart';
import 'package:school_app_flutter/features/academics/domain/entities/notation/periode_notation.dart';
import 'package:school_app_flutter/features/academics/domain/entities/notation/type_evaluation.dart';
import 'package:school_app_flutter/features/academics/presentation/helpers/academics_notation_visuals.dart';
import 'package:school_app_flutter/features/academics/presentation/helpers/cours_notation_labels.dart';
import 'package:school_app_flutter/features/academics/presentation/helpers/cours_notation_view_model.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Titre d'une évaluation, calculé à la création (spec §4) et stocké tel quel.
///
/// - Examen : « Examen — Semestre 1 ».
/// - Un seul chapitre coché : « Interrogation 3 — Proportionnalité ».
/// - Sinon : « Interrogation 3 », où 3 = évaluations du même type déjà
///   rattachées à la même sous-période, plus un.
///
/// Le serveur ne recompte pas : deux tablettes hors ligne peuvent produire le
/// même rang, c'est accepté (arbitrage back n°1).
String buildEvalTitle(
  AppLocalizations l10n, {
  required TypeEvaluation type,
  required PeriodeNotation? periode,
  required String? sousPeriodeId,
  required int periodeCount,
  List<String> chapitreTitres = const [],
}) {
  final typeLabel = typeEvaluationLabel(l10n, type);
  if (type == TypeEvaluation.examen) {
    if (periode == null) return typeLabel;
    final decoupage = periodeDecoupageFromCount(periodeCount);
    return l10n.evalTitleWithSuffix(
      typeLabel,
      periodeScolaireLabel(l10n, periode.ordre, decoupage),
    );
  }
  final base = l10n.evalTitleRanked(
    typeLabel,
    _sameTypeCount(periode, sousPeriodeId, type) + 1,
  );
  return chapitreTitres.length == 1
      ? l10n.evalTitleWithSuffix(base, chapitreTitres.single)
      : base;
}

int _sameTypeCount(
  PeriodeNotation? periode,
  String? sousPeriodeId,
  TypeEvaluation type,
) {
  for (final sp in periode?.sousPeriodes ?? const []) {
    if (sp.sousPeriodeId != sousPeriodeId) continue;
    return sp.evaluationsParType
        .where((g) => g.type == type)
        .fold(0, (sum, g) => sum + g.evaluations.length);
  }
  return 0;
}

/// Nom affiché : le titre stocké, sinon « Interrogation du 12 juin 2026 » —
/// le repli que le serveur dérive aussi pour l'historique.
String evalDisplayName(BuildContext context, EvalVm eval) {
  final nom = eval.nom;
  if (nom != null && nom.trim().isNotEmpty) return nom;
  final l10n = AppLocalizations.of(context)!;
  return l10n.evalDerivedName(
    typeEvaluationLabel(l10n, eval.type),
    formatEvalDate(context, eval.date),
  );
}
