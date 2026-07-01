import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/features/academics/domain/entities/notation/cours_notation_detail.dart';
import 'package:school_app_flutter/features/academics/domain/entities/notation/evaluation_summary.dart';
import 'package:school_app_flutter/features/academics/domain/entities/notation/examen_notation.dart';
import 'package:school_app_flutter/features/academics/domain/entities/notation/moyenne_eleve.dart';
import 'package:school_app_flutter/features/academics/domain/entities/notation/periode_notation.dart';
import 'package:school_app_flutter/features/academics/domain/entities/notation/sous_periode_notation.dart';
import 'package:school_app_flutter/features/academics/domain/entities/notation/statut_periode.dart';
import 'package:school_app_flutter/features/academics/domain/entities/notation/statut_saisie_evaluation.dart';
import 'package:school_app_flutter/features/academics/domain/entities/notation/type_evaluation.dart';
import 'package:school_app_flutter/features/academics/presentation/helpers/academics_notation_visuals.dart';

/// Genre d'un pas de la frise : une sous-période ou l'examen de période.
enum BucketKind { sousPeriode, examen }

/// Vue dérivée d'une [CoursNotationDetail] pour la page détail (spec §10).
///
/// Aplatit le contrat backend (périodes ▸ sous-périodes ▸ évaluations groupées)
/// en la hiérarchie de la spec : onglets de période → frise de buckets
/// (sous-périodes + examen) → liste d'évaluations à plat. Tous les compteurs,
/// statuts tri-état et la « prochaine évaluation » sont **dérivés**, jamais
/// stockés. [now] est injecté pour la testabilité (calcul de prochaine éval).
class CoursNotationViewModel extends Equatable {
  final int effectif;
  final List<PeriodeVm> periodes;

  /// Nombre total d'évaluations (toutes périodes, sous-périodes et examens).
  final int totalEvaluations;

  /// Nombre d'évaluations dont la saisie n'est pas terminée (chip « à saisir »).
  final int aSaisir;

  /// Première évaluation à venir (date >= aujourd'hui), ou `null`.
  final EvalVm? prochaineEval;

  const CoursNotationViewModel({
    required this.effectif,
    required this.periodes,
    required this.totalEvaluations,
    required this.aSaisir,
    required this.prochaineEval,
  });

  /// `true` si le cours n'a aucune évaluation (état « vide » de la page).
  bool get isEmpty => totalEvaluations == 0;

  /// Index de la période à présenter par défaut : la première « en cours »,
  /// sinon la première.
  int get defaultPeriodeIndex {
    final i = periodes.indexWhere((p) => p.statut == BucketStatut.current);
    return i < 0 ? 0 : i;
  }

  factory CoursNotationViewModel.fromDetail(
    CoursNotationDetail detail, {
    required DateTime now,
  }) {
    final effectif = detail.effectif;
    final periodes = [
      for (final p in detail.periodes) PeriodeVm._fromPeriode(p, effectif),
    ];

    final allEvals = [
      for (final p in periodes)
        for (final b in p.buckets) ...b.evaluations,
    ];
    final today = DateTime(now.year, now.month, now.day);
    EvalVm? prochaine;
    for (final e in allEvals) {
      final d = DateTime(e.date.year, e.date.month, e.date.day);
      if (d.isBefore(today)) continue;
      if (prochaine == null || e.date.isBefore(prochaine.date)) {
        prochaine = e;
      }
    }

    return CoursNotationViewModel(
      effectif: effectif,
      periodes: periodes,
      totalEvaluations: allEvals.length,
      aSaisir: allEvals.where((e) => e.state != EvalState.complete).length,
      prochaineEval: prochaine,
    );
  }

  @override
  List<Object?> get props => [
    effectif,
    periodes,
    totalEvaluations,
    aSaisir,
    prochaineEval,
  ];
}

/// Une période scolaire (onglet de premier niveau, spec §2).
class PeriodeVm extends Equatable {
  final String id;
  final int ordre;
  final BucketStatut statut;
  final List<BucketVm> buckets;

  const PeriodeVm({
    required this.id,
    required this.ordre,
    required this.statut,
    required this.buckets,
  });

  /// Clé du bucket sélectionné par défaut : le « en cours », sinon le premier
  /// avec des évaluations, sinon le premier. `null` si aucun bucket.
  String? get defaultBucketKey {
    if (buckets.isEmpty) return null;
    final current = buckets.where((b) => b.statut == BucketStatut.current);
    if (current.isNotEmpty) return current.first.key;
    final withEvals = buckets.where((b) => b.evaluations.isNotEmpty);
    if (withEvals.isNotEmpty) return withEvals.first.key;
    return buckets.first.key;
  }

  factory PeriodeVm._fromPeriode(PeriodeNotation p, int effectif) {
    final buckets = <BucketVm>[
      for (final sp in p.sousPeriodes) BucketVm._fromSousPeriode(sp, effectif),
      if (p.examen != null) BucketVm._fromExamen(p.examen!, effectif),
    ];
    return PeriodeVm(
      id: p.periodeScolaireId,
      ordre: p.ordre,
      statut: switch (p.statut) {
        StatutPeriode.cloturee => BucketStatut.closed,
        StatutPeriode.ouverte => BucketStatut.current,
        StatutPeriode.unknown => BucketStatut.upcoming,
      },
      buckets: buckets,
    );
  }

  @override
  List<Object?> get props => [id, ordre, statut, buckets];
}

/// Un pas de la frise (spec §3) + le panneau associé (spec §4).
class BucketVm extends Equatable {
  final String key;
  final BucketKind kind;
  final int ordre;
  final BucketStatut statut;
  final List<EvalVm> evaluations;

  /// Moyenne de classe (%) — `null` si aucun élève noté.
  final double? moyenneClasse;
  final int nombreElevesNotes;
  final int nombreEleves50;
  final List<MoyenneEleve> moyennesEleves;

  /// `true` si le relevé par élève est disponible (sous-période uniquement —
  /// le contrat examen ne porte pas les moyennes par élève).
  final bool supportsReleve;

  /// Légende de la frise : nombre de notes saisies / total (dérivé) et nombre
  /// d'évaluations.
  final int saisiesNotes;
  final int totalNotes;

  const BucketVm({
    required this.key,
    required this.kind,
    required this.ordre,
    required this.statut,
    required this.evaluations,
    required this.moyenneClasse,
    required this.nombreElevesNotes,
    required this.nombreEleves50,
    required this.moyennesEleves,
    required this.supportsReleve,
    required this.saisiesNotes,
    required this.totalNotes,
  });

  int get evalCount => evaluations.length;

  /// `true` si des notes manquent encore → moyenne « provisoire » (§4/§9).
  bool get isProvisoire =>
      evaluations.any((e) => e.state != EvalState.complete);

  factory BucketVm._fromSousPeriode(SousPeriodeNotation sp, int effectif) {
    final evals =
        sp.evaluationsParType
            .expand((g) => g.evaluations)
            .map((e) => EvalVm._fromSummary(e, effectif))
            .toList()
          ..sort((a, b) => a.date.compareTo(b.date));
    final hasEvals = evals.isNotEmpty;
    return BucketVm(
      key: 'sp:${sp.sousPeriodeId}',
      kind: BucketKind.sousPeriode,
      ordre: sp.ordre,
      statut: switch (sp.statut) {
        StatutPeriode.cloturee => BucketStatut.closed,
        StatutPeriode.ouverte =>
          hasEvals ? BucketStatut.current : BucketStatut.upcoming,
        StatutPeriode.unknown => BucketStatut.upcoming,
      },
      evaluations: evals,
      moyenneClasse: sp.moyenneClasse,
      nombreElevesNotes: sp.nombreElevesNotes,
      nombreEleves50: sp.nombreEleves50,
      moyennesEleves: sp.moyennesEleves,
      supportsReleve: true,
      saisiesNotes: evals.fold(0, (s, e) => s + e.saisies),
      totalNotes: evals.length * effectif,
    );
  }

  factory BucketVm._fromExamen(ExamenNotation e, int effectif) {
    final eval = EvalVm._fromExamen(e, effectif);
    return BucketVm(
      key: 'exam:${e.evaluationId}',
      kind: BucketKind.examen,
      ordre: 0,
      statut: switch (eval.state) {
        EvalState.complete => BucketStatut.closed,
        EvalState.partial => BucketStatut.current,
        EvalState.upcoming => BucketStatut.upcoming,
      },
      evaluations: [eval],
      moyenneClasse: e.moyenneGenerale,
      nombreElevesNotes: 0,
      nombreEleves50: 0,
      moyennesEleves: const [],
      supportsReleve: false,
      saisiesNotes: eval.saisies,
      totalNotes: effectif,
    );
  }

  @override
  List<Object?> get props => [
    key,
    kind,
    ordre,
    statut,
    evaluations,
    moyenneClasse,
    nombreElevesNotes,
    nombreEleves50,
    moyennesEleves,
    supportsReleve,
    saisiesNotes,
    totalNotes,
  ];
}

/// Une ligne d'évaluation (spec §5).
class EvalVm extends Equatable {
  final String id;
  final TypeEvaluation type;
  final String nom;
  final List<String> chapitres;
  final DateTime date;
  final double maxPoints;
  final int poids;
  final EvalState state;

  /// Pourcentage d'élèves dont la note est saisie (0–100).
  final double pourcentageSaisie;

  /// Nombre d'élèves dont la note est saisie (dérivé du pourcentage × effectif).
  final int saisies;
  final int total;

  const EvalVm({
    required this.id,
    required this.type,
    required this.nom,
    required this.chapitres,
    required this.date,
    required this.maxPoints,
    required this.poids,
    required this.state,
    required this.pourcentageSaisie,
    required this.saisies,
    required this.total,
  });

  factory EvalVm._fromSummary(EvaluationSummary e, int effectif) => EvalVm(
    id: e.id,
    type: e.type,
    nom: e.nom,
    chapitres: e.chapitres,
    date: e.date,
    maxPoints: e.maxPoints,
    poids: e.poids,
    state: _stateFrom(e.statutSaisie, e.pourcentageSaisie),
    pourcentageSaisie: e.pourcentageSaisie,
    saisies: _saisies(e.pourcentageSaisie, effectif),
    total: effectif,
  );

  factory EvalVm._fromExamen(ExamenNotation e, int effectif) => EvalVm(
    id: e.evaluationId,
    type: TypeEvaluation.examen,
    nom: e.nom,
    chapitres: const [],
    date: e.date,
    maxPoints: e.maxPoints,
    poids: e.poids,
    state: _stateFrom(e.statutSaisie, e.pourcentageSaisie),
    pourcentageSaisie: e.pourcentageSaisie,
    saisies: _saisies(e.pourcentageSaisie, effectif),
    total: effectif,
  );

  static int _saisies(double pourcentage, int effectif) =>
      (pourcentage.clamp(0, 100) / 100 * effectif).round();

  static EvalState _stateFrom(StatutSaisieEvaluation statut, double pct) =>
      switch (statut) {
        StatutSaisieEvaluation.complete => EvalState.complete,
        StatutSaisieEvaluation.enAttente => EvalState.partial,
        StatutSaisieEvaluation.nonSaisie =>
          pct > 0 ? EvalState.partial : EvalState.upcoming,
        StatutSaisieEvaluation.unknown =>
          pct >= 100
              ? EvalState.complete
              : pct > 0
              ? EvalState.partial
              : EvalState.upcoming,
      };

  @override
  List<Object?> get props => [
    id,
    type,
    nom,
    chapitres,
    date,
    maxPoints,
    poids,
    state,
    pourcentageSaisie,
    saisies,
    total,
  ];
}
