import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/features/academics/data/models/notation/cours_notation_detail_model.dart';
import 'package:school_app_flutter/features/academics/domain/entities/notation/statut_periode.dart';
import 'package:school_app_flutter/features/academics/domain/entities/notation/statut_saisie_evaluation.dart';
import 'package:school_app_flutter/features/academics/domain/entities/notation/type_evaluation.dart';

void main() {
  Map<String, dynamic> buildEvaluationJson() => <String, dynamic>{
    'id': 'ev-1',
    'type': 'INTERRO',
    'nom': 'Interrogation du 2025-11-10',
    'chapitres': <String>['Chapitre 1', 'Chapitre 2'],
    'date': '2025-11-10',
    'maxPoints': 20.0,
    'poids': 1,
    'statutSaisie': 'COMPLETE',
    'pourcentageSaisie': 100.0,
  };

  Map<String, dynamic> buildJson() => <String, dynamic>{
    'coursId': 'cours-1',
    'classroomId': 'class-1',
    'brancheNom': 'Mathématiques',
    'effectif': 30,
    'periodes': <Map<String, dynamic>>[
      <String, dynamic>{
        'periodeScolaireId': 'per-1',
        'ordre': 1,
        'statut': 'OUVERTE',
        'sousPeriodes': <Map<String, dynamic>>[
          <String, dynamic>{
            'sousPeriodeId': 'sp-1',
            'ordre': 1,
            'statut': 'OUVERTE',
            'moyenneClasse': 62.5,
            'nombreElevesNotes': 28,
            'nombreEleves50': 20,
            'moyennesEleves': <Map<String, dynamic>>[
              <String, dynamic>{
                'studentId': 'stu-1',
                'firstName': 'Ada',
                'lastName': 'Lovelace',
                'middleName': null,
                'moyenne': 75,
              },
              <String, dynamic>{
                'studentId': 'stu-2',
                'firstName': 'Alan',
                'lastName': 'Turing',
                'moyenne': null,
              },
            ],
            'evaluationsParType': <Map<String, dynamic>>[
              <String, dynamic>{
                'type': 'INTERRO',
                'evaluations': <Map<String, dynamic>>[buildEvaluationJson()],
              },
            ],
          },
        ],
        'examen': <String, dynamic>{
          'evaluationId': 'ex-1',
          'nom': 'Examen S1',
          'date': '2025-12-15',
          'poids': 3,
          'maxPoints': 100.0,
          'moyenneGenerale': 58.0,
          'statutSaisie': 'EN_ATTENTE',
          'pourcentageSaisie': 80.0,
        },
      },
    ],
  };

  test('fromJson -> toEntity mappe toute la hiérarchie', () {
    final entity = CoursNotationDetailModel.fromJson(buildJson()).toEntity();

    expect(entity.coursId, 'cours-1');
    expect(entity.classroomId, 'class-1');
    expect(entity.brancheNom, 'Mathématiques');
    expect(entity.effectif, 30);
    expect(entity.periodes, hasLength(1));

    final periode = entity.periodes.first;
    expect(periode.periodeScolaireId, 'per-1');
    expect(periode.ordre, 1);
    expect(periode.statut, StatutPeriode.ouverte);
    expect(periode.sousPeriodes, hasLength(1));

    final sousPeriode = periode.sousPeriodes.first;
    expect(sousPeriode.sousPeriodeId, 'sp-1');
    expect(sousPeriode.statut, StatutPeriode.ouverte);
    expect(sousPeriode.moyenneClasse, 62.5);
    expect(sousPeriode.nombreElevesNotes, 28);
    expect(sousPeriode.nombreEleves50, 20);

    expect(sousPeriode.moyennesEleves, hasLength(2));
    expect(sousPeriode.moyennesEleves.first.studentId, 'stu-1');
    // `moyenne` arrive en int dans le JSON -> doit devenir un double (résilience).
    expect(sousPeriode.moyennesEleves.first.moyenne, 75.0);
    expect(sousPeriode.moyennesEleves.first.middleName, isNull);
    expect(sousPeriode.moyennesEleves[1].moyenne, isNull);

    expect(sousPeriode.evaluationsParType, hasLength(1));
    final groupe = sousPeriode.evaluationsParType.first;
    expect(groupe.type, TypeEvaluation.interro);
    expect(groupe.evaluations, hasLength(1));

    final evaluation = groupe.evaluations.first;
    expect(evaluation.id, 'ev-1');
    expect(evaluation.type, TypeEvaluation.interro);
    expect(evaluation.nom, 'Interrogation du 2025-11-10');
    expect(evaluation.chapitres, ['Chapitre 1', 'Chapitre 2']);
    expect(evaluation.date, DateTime(2025, 11, 10));
    expect(evaluation.maxPoints, 20.0);
    expect(evaluation.poids, 1);
    expect(evaluation.statutSaisie, StatutSaisieEvaluation.complete);
    expect(evaluation.pourcentageSaisie, 100.0);

    final examen = periode.examen;
    expect(examen, isNotNull);
    expect(examen!.evaluationId, 'ex-1');
    expect(examen.nom, 'Examen S1');
    expect(examen.date, DateTime(2025, 12, 15));
    expect(examen.poids, 3);
    expect(examen.maxPoints, 100.0);
    expect(examen.moyenneGenerale, 58.0);
    expect(examen.statutSaisie, StatutSaisieEvaluation.enAttente);
    expect(examen.pourcentageSaisie, 80.0);
  });

  test('brancheNom absent -> null (résilience backend)', () {
    final json = buildJson()..remove('brancheNom');

    final entity = CoursNotationDetailModel.fromJson(json).toEntity();

    expect(entity.brancheNom, isNull);
  });

  test('examen null -> entité examen null', () {
    final json = buildJson();
    (json['periodes'] as List).first['examen'] = null;

    final entity = CoursNotationDetailModel.fromJson(json).toEntity();

    expect(entity.periodes.first.examen, isNull);
  });

  test('statut inconnu -> StatutPeriode.unknown (fallback)', () {
    final json = buildJson();
    (json['periodes'] as List).first['statut'] = 'ARCHIVEE';

    final entity = CoursNotationDetailModel.fromJson(json).toEntity();

    expect(entity.periodes.first.statut, StatutPeriode.unknown);
  });

  test('moyenneClasse null -> entité null + listes vides supportées', () {
    final json = buildJson();
    final sousPeriode =
        (json['periodes'] as List).first['sousPeriodes'][0]
            as Map<String, dynamic>;
    sousPeriode['moyenneClasse'] = null;
    sousPeriode['moyennesEleves'] = <Map<String, dynamic>>[];
    sousPeriode['evaluationsParType'] = <Map<String, dynamic>>[];

    final entity = CoursNotationDetailModel.fromJson(json).toEntity();
    final entitySousPeriode = entity.periodes.first.sousPeriodes.first;

    expect(entitySousPeriode.moyenneClasse, isNull);
    expect(entitySousPeriode.moyennesEleves, isEmpty);
    expect(entitySousPeriode.evaluationsParType, isEmpty);
  });

  test('statut CLOTUREE -> StatutPeriode.cloturee', () {
    final json = buildJson();
    (json['periodes'] as List).first['sousPeriodes'][0]['statut'] = 'CLOTUREE';

    final entity = CoursNotationDetailModel.fromJson(json).toEntity();

    expect(
      entity.periodes.first.sousPeriodes.first.statut,
      StatutPeriode.cloturee,
    );
  });

  test('type d\'évaluation inconnu -> TypeEvaluation.unknown (fallback)', () {
    final json = buildJson();
    final groupe =
        (json['periodes'] as List)
                .first['sousPeriodes'][0]['evaluationsParType'][0]
            as Map<String, dynamic>;
    groupe['type'] = 'PROJET';
    (groupe['evaluations'][0] as Map<String, dynamic>)['type'] = 'PROJET';

    final entity = CoursNotationDetailModel.fromJson(json).toEntity();
    final entityGroupe =
        entity.periodes.first.sousPeriodes.first.evaluationsParType.first;

    expect(entityGroupe.type, TypeEvaluation.unknown);
    expect(entityGroupe.evaluations.first.type, TypeEvaluation.unknown);
  });

  test('statutSaisie inconnu -> StatutSaisieEvaluation.unknown (fallback)', () {
    final json = buildJson();
    (json['periodes'] as List)
            .first['sousPeriodes'][0]['evaluationsParType'][0]['evaluations'][0]['statutSaisie'] =
        'VERROUILLE';
    (json['periodes'] as List).first['examen']['statutSaisie'] = 'VERROUILLE';

    final entity = CoursNotationDetailModel.fromJson(json).toEntity();
    final evaluation = entity
        .periodes
        .first
        .sousPeriodes
        .first
        .evaluationsParType
        .first
        .evaluations
        .first;

    expect(evaluation.statutSaisie, StatutSaisieEvaluation.unknown);
    expect(
      entity.periodes.first.examen!.statutSaisie,
      StatutSaisieEvaluation.unknown,
    );
  });
}
