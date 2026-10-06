import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/features/academics/domain/entities/notation/evaluation_groupe.dart';
import 'package:school_app_flutter/features/academics/domain/entities/notation/evaluation_summary.dart';
import 'package:school_app_flutter/features/academics/domain/entities/notation/periode_notation.dart';
import 'package:school_app_flutter/features/academics/domain/entities/notation/sous_periode_notation.dart';
import 'package:school_app_flutter/features/academics/domain/entities/notation/statut_periode.dart';
import 'package:school_app_flutter/features/academics/domain/entities/notation/statut_saisie_evaluation.dart';
import 'package:school_app_flutter/features/academics/domain/entities/notation/type_evaluation.dart';
import 'package:school_app_flutter/features/academics/presentation/helpers/eval_duree.dart';
import 'package:school_app_flutter/features/academics/presentation/helpers/eval_title.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

EvaluationSummary _eval(String id, TypeEvaluation type) => EvaluationSummary(
  id: id,
  type: type,
  chapitres: const [],
  date: DateTime.utc(2026, 6, 12),
  maxPoints: 10,
  poids: 1,
  statutSaisie: StatutSaisieEvaluation.nonSaisie,
  pourcentageSaisie: 0,
);

void main() {
  final l10n = lookupAppLocalizations(const Locale('fr'));

  final periode = PeriodeNotation(
    periodeScolaireId: 'p1',
    ordre: 1,
    statut: StatutPeriode.ouverte,
    sousPeriodes: [
      SousPeriodeNotation(
        sousPeriodeId: 'sp1',
        ordre: 1,
        statut: StatutPeriode.ouverte,
        nombreElevesNotes: 0,
        nombreEleves50: 0,
        moyennesEleves: const [],
        evaluationsParType: [
          EvaluationGroupe(
            type: TypeEvaluation.interro,
            evaluations: [
              _eval('a', TypeEvaluation.interro),
              _eval('b', TypeEvaluation.interro),
            ],
          ),
          EvaluationGroupe(
            type: TypeEvaluation.devoir,
            evaluations: [_eval('c', TypeEvaluation.devoir)],
          ),
        ],
      ),
      const SousPeriodeNotation(
        sousPeriodeId: 'sp2',
        ordre: 2,
        statut: StatutPeriode.ouverte,
        nombreElevesNotes: 0,
        nombreEleves50: 0,
        moyennesEleves: [],
        evaluationsParType: [],
      ),
    ],
  );

  String title(
    TypeEvaluation type, {
    String? sousPeriodeId = 'sp1',
    List<String> chapitres = const [],
  }) => buildEvalTitle(
    l10n,
    type: type,
    periode: periode,
    sousPeriodeId: sousPeriodeId,
    periodeCount: 2,
    chapitreTitres: chapitres,
  );

  group('buildEvalTitle', () {
    test('rang = évaluations du même type sur la sous-période + 1', () {
      expect(title(TypeEvaluation.interro), 'Interrogation 3');
      expect(title(TypeEvaluation.devoir), 'Devoir 2');
      expect(
        title(TypeEvaluation.interro, sousPeriodeId: 'sp2'),
        'Interrogation 1',
      );
    });

    test('un seul chapitre coché entre dans le titre', () {
      expect(
        title(TypeEvaluation.interro, chapitres: ['Proportionnalité']),
        'Interrogation 3 — Proportionnalité',
      );
      expect(
        title(TypeEvaluation.interro, chapitres: ['A', 'B']),
        'Interrogation 3',
      );
    });

    test('examen : rattaché à la période', () {
      expect(title(TypeEvaluation.examen), 'Examen — Semestre 1');
    });
  });

  group('formatDuree', () {
    test('sous l’heure, heures pleines, heures et minutes', () {
      expect(formatDuree(l10n, 45), '45 min');
      expect(formatDuree(l10n, 60), '1 h');
      expect(formatDuree(l10n, 90), '1 h 30');
      expect(formatDuree(l10n, 125), '2 h 05');
    });
  });
}
