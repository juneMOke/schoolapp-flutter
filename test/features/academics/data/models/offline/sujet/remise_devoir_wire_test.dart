import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/features/academics/data/models/offline/academics_metier_pull_models.dart';
import 'package:school_app_flutter/features/academics/data/models/offline/evaluation_input_model.dart';
import 'package:school_app_flutter/features/academics/data/models/offline/sujet/evaluation_sujet_row.dart';
import 'package:school_app_flutter/features/academics/data/models/offline/sujet/sujet_wire_models.dart';
import 'package:school_app_flutter/features/academics/domain/entities/sujet/remise_devoir.dart';

/// La remise d'un devoir (V179) d'un bout à l'autre : création, sujet, pull,
/// ligne locale — et jamais hors devoir.
void main() {
  const enLigne = RemiseDevoir(
    mode: ModeRemise.enLigne,
    heureLimite: '17:30',
    depotTardifPermis: true,
  );

  EvaluationInputModel input(String type, RemiseDevoir? remise) =>
      EvaluationInputModel(
        id: 'e1',
        coursId: 'c1',
        type: type,
        date: DateTime.utc(2026, 10, 20),
        maxPoints: 20,
        poids: 1,
        sousPeriodeId: 'sp',
        remise: remise,
      );

  group('création', () {
    test('un devoir emporte ses trois champs', () {
      final json = input('DEVOIR', enLigne).toJson();
      expect(json['modeRemise'], 'EN_LIGNE');
      expect(json['heureLimite'], '17:30');
      expect(json['depotTardifPermis'], isTrue);
      expect(EvaluationInputModel.fromJson(json).remise, enLigne);
    });

    test('une interrogation n en émet aucun, même par erreur', () {
      final json = input('INTERRO', enLigne).toJson();
      expect(
        json.keys,
        isNot(
          anyElement(isIn(['modeRemise', 'heureLimite', 'depotTardifPermis'])),
        ),
      );
    });
  });

  group('sujet', () {
    test('la remise part avec le sujet et revient de la file', () {
      const request = SujetPushRequestModel(
        evaluationId: 'e1',
        clientUpdatedAt: 1000,
        sujet: EvaluationSujetRow(remise: enLigne),
      );
      expect(request.toBody()['modeRemise'], 'EN_LIGNE');
      final back = SujetPushRequestModel.fromJsonString(request.toJsonString());
      expect(back.sujet.remise, enLigne);
    });

    test('hors devoir, la remise est absente : rien n est effacé', () {
      const request = SujetPushRequestModel(
        evaluationId: 'e1',
        clientUpdatedAt: 1000,
        sujet: EvaluationSujetRow(),
      );
      expect(request.toBody().containsKey('modeRemise'), isFalse);
      expect(
        SujetPushRequestModel.fromJsonString(
          request.toJsonString(),
        ).sujet.remise,
        isNull,
      );
    });
  });

  group('ligne locale', () {
    test('un devoir relit sa remise ; une interrogation n en a pas', () {
      final columns = {
        'heure_limite': '08:00',
        'mode_remise': 'EN_LIGNE',
        'depot_tardif_permis': 0,
      };
      expect(
        EvaluationSujetRow.fromMap({'type': 'DEVOIR', ...columns}).remise,
        const RemiseDevoir(mode: ModeRemise.enLigne, heureLimite: '08:00'),
      );
      expect(
        EvaluationSujetRow.fromMap({'type': 'INTERRO', ...columns}).remise,
        isNull,
      );
    });

    test('sans remise, la ligne n écrit pas ses colonnes', () {
      expect(
        const EvaluationSujetRow().toMap().containsKey('mode_remise'),
        isFalse,
      );
      expect(
        const EvaluationSujetRow(
          remise: enLigne,
        ).toMap()['depot_tardif_permis'],
        1,
      );
    });
  });

  group('pull', () {
    Map<String, dynamic> view(String type, [Map<String, dynamic>? extra]) => {
      'id': 'e1',
      'coursId': 'c1',
      'type': type,
      'date': '2026-10-20',
      'maxPoints': 20,
      'serverUpdatedAt': '2026-10-20T08:00:00Z',
      ...?extra,
    };

    test('un devoir descend avec sa remise', () {
      final dto = EvaluationDeltaDto.fromJson(
        view('DEVOIR', {'modeRemise': 'EN_LIGNE', 'heureLimite': '17:30'}),
      );
      expect(dto.toSujetRow().remise?.mode, ModeRemise.enLigne);
    });

    test('un devoir d un serveur ancien prend la remise par défaut', () {
      expect(
        EvaluationDeltaDto.fromJson(view('DEVOIR')).remise,
        RemiseDevoir.parDefaut,
      );
    });

    test('un examen n a pas de remise', () {
      expect(EvaluationDeltaDto.fromJson(view('EXAMEN')).remise, isNull);
    });
  });
}
