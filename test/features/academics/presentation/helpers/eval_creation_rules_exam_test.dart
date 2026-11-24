import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/features/academics/domain/entities/notation/cours_notation_detail.dart';
import 'package:school_app_flutter/features/academics/domain/entities/notation/intitule_colonne.dart';
import 'package:school_app_flutter/features/academics/domain/entities/notation/periode_notation.dart';
import 'package:school_app_flutter/features/academics/domain/entities/notation/statut_periode.dart';
import 'package:school_app_flutter/features/academics/domain/entities/notation/type_evaluation.dart';
import 'package:school_app_flutter/features/academics/presentation/helpers/eval_creation_rules.dart';

EvalCreationRules _rules(ColonneExamen examen) => EvalCreationRules(
  detail: CoursNotationDetail(
    coursId: 'c',
    classroomId: 'cl',
    brancheNom: 'Maths',
    effectif: 1,
    periodes: [
      for (final ordre in [1, 2])
        PeriodeNotation(
          periodeScolaireId: 'p$ordre',
          ordre: ordre,
          statut: StatutPeriode.ouverte,
          sousPeriodes: const [],
          intituleExamen: examen,
        ),
    ],
  ),
  type: TypeEvaluation.interro,
  periodeId: 'p1',
  sousPeriodeId: null,
  date: null,
);

void main() {
  test('en ligne, sans plafonds : intituleExamen null grise l\'examen', () {
    expect(_rules(const ColonneExamen.absente()).disabledTypes, {
      TypeEvaluation.examen,
    });
  });

  test('serveur ancien ou examen nommé : rien de grisé', () {
    expect(_rules(const ColonneExamen.inconnue()).disabledTypes, isEmpty);
    expect(
      _rules(
        const ColonneExamen.nommee(
          IntituleColonne(libelle: 'Examen', libelleCourt: 'Exam.'),
        ),
      ).disabledTypes,
      isEmpty,
    );
  });
}
