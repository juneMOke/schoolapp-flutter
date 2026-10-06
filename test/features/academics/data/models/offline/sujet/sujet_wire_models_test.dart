import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/features/academics/data/models/offline/academics_metier_pull_models.dart';
import 'package:school_app_flutter/features/academics/data/models/offline/evaluation_input_model.dart';
import 'package:school_app_flutter/features/academics/data/models/offline/evaluation_row.dart';
import 'package:school_app_flutter/features/academics/data/models/offline/sujet/copie_log_row.dart';
import 'package:school_app_flutter/features/academics/data/models/offline/sujet/evaluation_sujet_row.dart';
import 'package:school_app_flutter/features/academics/data/models/offline/sujet/sujet_wire_models.dart';
import 'package:school_app_flutter/features/academics/domain/entities/sujet/sujet_question.dart';

void main() {
  const q = SujetQuestion(
    id: 'q1',
    enonce: 'Calculez',
    points: 3.5,
    reponseAttendue: '98 g/mol',
  );

  group('SujetPushRequestModel', () {
    final model = SujetPushRequestModel(
      evaluationId: 'ev-1',
      authorId: 'u-1',
      clientUpdatedAt: DateTime.utc(2026, 10, 6, 8).millisecondsSinceEpoch,
      maxPoints: 10,
      sujet: const EvaluationSujetRow(
        dureeMinutes: 30,
        programme: ['Réactions'],
        questions: [q],
      ),
    );

    test('corps du contrat SujetSyncRequest', () {
      final body = model.toBody();
      expect(body['clientUpdatedAt'], '2026-10-06T08:00:00.000Z');
      expect(body['maxPoints'], 10);
      expect(body['consignes'], isNull);
      expect(body['questions'], [
        {
          'id': 'q1',
          'ordre': 1,
          'enonce': 'Calculez',
          'points': 3.5,
          'reponseAttendue': '98 g/mol',
        },
      ]);
      expect(body.containsKey('evaluationId'), isFalse);
    });

    test('aller-retour du payload d’outbox', () {
      final back = SujetPushRequestModel.fromJsonString(model.toJsonString());
      expect(back.evaluationId, 'ev-1');
      expect(back.clientUpdatedAt, model.clientUpdatedAt);
      expect(back.maxPoints, 10);
      expect(back.sujet.questions, [q]);
      expect(back.sujet.programme, ['Réactions']);
    });
  });

  test('CopieLogPushRequestModel : corps et aller-retour', () {
    const row = CopieLogRow(
      id: 'l-1',
      evaluationId: 'ev-1',
      kind: 'SHARE',
      canal: 'SYSTEME',
      corrige: true,
      occurredAt: 0,
    );
    const model = CopieLogPushRequestModel(authorId: 'u-1', entry: row);
    expect(model.toBody()['entry'], {
      'id': 'l-1',
      'kind': 'SHARE',
      'canal': 'SYSTEME',
      'corrige': true,
      'occurredAt': '1970-01-01T00:00:00.000Z',
    });
    final back = CopieLogPushRequestModel.fromJsonString(model.toJsonString());
    expect(back.entry.evaluationId, 'ev-1');
    expect(back.entry.corrige, isTrue);
  });

  group('EvaluationDeltaDto (EvaluationSyncView)', () {
    Map<String, dynamic> view({String? sujetAt}) => {
      'id': 'ev-1',
      'coursId': 'c-1',
      'type': 'DEVOIR',
      'date': '2026-10-14',
      'maxPoints': 20,
      'poids': 2,
      'sousPeriodeId': 'sp-1',
      'serverUpdatedAt': '2026-10-06T09:00:00Z',
      'titre': 'Devoir 1',
      'dureeMinutes': 60,
      'programme': ['A', ' '],
      'consignes': 'Calculatrice',
      'sujetClientUpdatedAt': sujetAt,
      'questions': [
        {'id': 'q1', 'ordre': 1, 'enonce': 'Calculez', 'points': 3.5},
      ],
      'copieLog': [
        {
          'id': 'l-1',
          'kind': 'PRINT',
          'canal': null,
          'corrige': false,
          'occurredAt': '2026-10-06T10:00:00Z',
          'authorUserId': 'u-2',
        },
        {'kind': 'PRINT'},
      ],
      'publication': {
        'sujet': {'publishedAt': '2026-10-06T11:00:00Z', 'revision': 1},
        'corrige': null,
        'notes': null,
      },
    };

    test('ligne, sujet, journal et publications', () {
      final dto = EvaluationDeltaDto.fromJson(
        view(sujetAt: '2026-10-06T08:00:00Z'),
      );
      expect(dto.toLocalRow(0).titre, 'Devoir 1');
      final sujet = dto.toSujetRow();
      expect(sujet.programme, ['A']);
      expect(sujet.questions.single.points, 3.5);
      expect(sujet.syncStatus, 'SYNCED');
      expect(dto.toCopieLogRows().single.authorUserId, 'u-2');
      expect(dto.publications.sujet!.revision, 1);
      expect(dto.publications.notes, isNull);
    });

    test('sujet jamais envoyé : statut d’envoi nul', () {
      expect(
        EvaluationDeltaDto.fromJson(view()).toSujetRow().syncStatus,
        isNull,
      );
    });

    test('une vue d’avant le sujet se lit sans erreur', () {
      final dto = EvaluationDeltaDto.fromJson({
        'id': 'ev-1',
        'coursId': 'c-1',
        'type': 'INTERRO',
        'date': '2026-10-14',
        'maxPoints': 10,
        'serverUpdatedAt': '2026-10-06T09:00:00Z',
      });
      expect(dto.questions, isEmpty);
      expect(dto.toCopieLogRows(), isEmpty);
      expect(dto.toLocalRow(0).titre, isNull);
    });
  });

  test('EvaluationInputModel porte le titre et le cadre', () {
    final model = EvaluationInputModel.fromRow(
      const EvaluationRow(
        id: 'ev-1',
        coursId: 'c-1',
        type: 'DEVOIR',
        evalDate: 0,
        maxPoints: 20,
        poids: 2,
        sousPeriodeId: 'sp-1',
        updatedAt: 0,
        titre: 'Devoir 1',
      ),
      sujet: const EvaluationSujetRow(dureeMinutes: 60, programme: ['A']),
    );
    final json = model.toJson();
    expect(json['titre'], 'Devoir 1');
    expect(json['dureeMinutes'], 60);
    expect(json['programme'], ['A']);
    expect(json.containsKey('consignes'), isFalse);
    expect(EvaluationInputModel.fromJson(json).toJson(), json);
  });
}
