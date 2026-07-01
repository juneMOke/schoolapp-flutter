import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/features/academics/domain/entities/notation/cours_notation_detail.dart';
import 'package:school_app_flutter/features/academics/domain/entities/notation/evaluation_groupe.dart';
import 'package:school_app_flutter/features/academics/domain/entities/notation/evaluation_summary.dart';
import 'package:school_app_flutter/features/academics/domain/entities/notation/examen_notation.dart';
import 'package:school_app_flutter/features/academics/domain/entities/notation/periode_notation.dart';
import 'package:school_app_flutter/features/academics/domain/entities/notation/sous_periode_notation.dart';
import 'package:school_app_flutter/features/academics/domain/entities/notation/statut_periode.dart';
import 'package:school_app_flutter/features/academics/domain/entities/notation/statut_saisie_evaluation.dart';
import 'package:school_app_flutter/features/academics/domain/entities/notation/type_evaluation.dart';
import 'package:school_app_flutter/features/academics/presentation/helpers/academics_notation_visuals.dart';
import 'package:school_app_flutter/features/academics/presentation/helpers/cours_notation_view_model.dart';

void main() {
  EvaluationSummary eval({
    required String id,
    required TypeEvaluation type,
    required DateTime date,
    required StatutSaisieEvaluation statut,
    required double pct,
    double max = 10,
    int poids = 1,
  }) => EvaluationSummary(
    id: id,
    type: type,
    nom: 'Éval $id',
    chapitres: const [],
    date: date,
    maxPoints: max,
    poids: poids,
    statutSaisie: statut,
    pourcentageSaisie: pct,
  );

  CoursNotationDetail buildDetail() => CoursNotationDetail(
    coursId: 'cours-1',
    classroomId: 'class-1',
    brancheNom: 'Mathématiques',
    effectif: 10,
    periodes: [
      // Période 1 : clôturée, 1 sous-période clôturée avec 1 éval complète.
      PeriodeNotation(
        periodeScolaireId: 'p1',
        ordre: 1,
        statut: StatutPeriode.cloturee,
        sousPeriodes: [
          SousPeriodeNotation(
            sousPeriodeId: 'p1-sp1',
            ordre: 1,
            statut: StatutPeriode.cloturee,
            moyenneClasse: 70,
            nombreElevesNotes: 10,
            nombreEleves50: 8,
            moyennesEleves: const [],
            evaluationsParType: [
              EvaluationGroupe(
                type: TypeEvaluation.interro,
                evaluations: [
                  eval(
                    id: 'e1',
                    type: TypeEvaluation.interro,
                    date: DateTime(2026, 1, 10),
                    statut: StatutSaisieEvaluation.complete,
                    pct: 100,
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
      // Période 2 : ouverte, 1 sous-période ouverte (2 évals) + examen à venir.
      PeriodeNotation(
        periodeScolaireId: 'p2',
        ordre: 2,
        statut: StatutPeriode.ouverte,
        sousPeriodes: [
          SousPeriodeNotation(
            sousPeriodeId: 'p2-sp1',
            ordre: 1,
            statut: StatutPeriode.ouverte,
            moyenneClasse: 55,
            nombreElevesNotes: 9,
            nombreEleves50: 5,
            moyennesEleves: const [],
            evaluationsParType: [
              EvaluationGroupe(
                type: TypeEvaluation.devoir,
                evaluations: [
                  eval(
                    id: 'eA',
                    type: TypeEvaluation.devoir,
                    date: DateTime(2026, 6, 5),
                    statut: StatutSaisieEvaluation.enAttente,
                    pct: 30,
                    max: 20,
                    poids: 2,
                  ),
                ],
              ),
              EvaluationGroupe(
                type: TypeEvaluation.interro,
                evaluations: [
                  eval(
                    id: 'eB',
                    type: TypeEvaluation.interro,
                    date: DateTime(2026, 5, 12),
                    statut: StatutSaisieEvaluation.complete,
                    pct: 100,
                  ),
                ],
              ),
            ],
          ),
        ],
        examen: ExamenNotation(
          evaluationId: 'ex1',
          nom: 'Examen S2',
          date: DateTime(2026, 6, 20),
          poids: 1,
          maxPoints: 40,
          moyenneGenerale: null,
          statutSaisie: StatutSaisieEvaluation.nonSaisie,
          pourcentageSaisie: 0,
        ),
      ),
    ],
  );

  final now = DateTime(2026, 6, 1);

  test('aplatit périodes/sous-périodes/examen et dérive les statuts', () {
    final vm = CoursNotationViewModel.fromDetail(buildDetail(), now: now);

    expect(vm.periodes.length, 2);
    expect(vm.periodes[0].statut, BucketStatut.closed);
    expect(vm.periodes[1].statut, BucketStatut.current);
    // Onglet par défaut = première période en cours (ouverte).
    expect(vm.defaultPeriodeIndex, 1);

    final p2 = vm.periodes[1];
    // Buckets = sous-périodes + examen.
    expect(p2.buckets.length, 2);
    expect(p2.buckets[0].kind, BucketKind.sousPeriode);
    expect(p2.buckets[1].kind, BucketKind.examen);
    // Sous-période ouverte avec évals -> en cours ; examen sans note -> à venir.
    expect(p2.buckets[0].statut, BucketStatut.current);
    expect(p2.buckets[1].statut, BucketStatut.upcoming);
    // Bucket par défaut = la sous-période en cours.
    expect(p2.defaultBucketKey, p2.buckets[0].key);
  });

  test('trie les évaluations par date et dérive leur état', () {
    final vm = CoursNotationViewModel.fromDetail(buildDetail(), now: now);
    final sp = vm.periodes[1].buckets[0];

    // Triées chronologiquement : eB (12 mai) avant eA (5 juin).
    expect(sp.evaluations.map((e) => e.id).toList(), ['eB', 'eA']);
    expect(sp.evaluations[0].state, EvalState.complete);
    expect(sp.evaluations[1].state, EvalState.partial);
    // Notes dérivées : eB 100% * 10 = 10, eA 30% * 10 = 3 -> 13/20.
    expect(sp.saisiesNotes, 13);
    expect(sp.totalNotes, 20);
    expect(sp.isProvisoire, isTrue);
  });

  test('examen : bucket sans relevé, une seule évaluation', () {
    final vm = CoursNotationViewModel.fromDetail(buildDetail(), now: now);
    final examen = vm.periodes[1].buckets[1];

    expect(examen.supportsReleve, isFalse);
    expect(examen.evaluations.length, 1);
    expect(examen.evaluations.first.type, TypeEvaluation.examen);
    expect(examen.evaluations.first.state, EvalState.upcoming);
  });

  test('compteurs d\'en-tête et prochaine évaluation', () {
    final vm = CoursNotationViewModel.fromDetail(buildDetail(), now: now);

    // 1 (p1) + 2 (p2 sp1) + 1 (examen) = 4.
    expect(vm.totalEvaluations, 4);
    // Non complètes : eA (partial) + examen (upcoming) = 2.
    expect(vm.aSaisir, 2);
    expect(vm.isEmpty, isFalse);
    // Première éval à venir (date >= 1er juin) = eA (5 juin), avant l'examen.
    expect(vm.prochaineEval?.id, 'eA');
  });

  test('cours sans évaluation -> isEmpty', () {
    const detail = CoursNotationDetail(
      coursId: 'c',
      classroomId: 'cl',
      brancheNom: 'X',
      effectif: 10,
      periodes: [],
    );
    final vm = CoursNotationViewModel.fromDetail(detail, now: now);
    expect(vm.isEmpty, isTrue);
    expect(vm.prochaineEval, isNull);
  });
}
