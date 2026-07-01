import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/features/academics/data/models/notation/evaluation_model.dart';
import 'package:school_app_flutter/features/academics/domain/entities/notation/type_evaluation.dart';

void main() {
  group('EvaluationModel.fromJson + toEntity', () {
    test('INTERRO rattachée à une sous-période', () {
      final json = <String, dynamic>{
        'id': 'ev-1',
        'coursId': 'cours-1',
        'type': 'INTERRO',
        'date': '2025-11-10',
        'maxPoints': 10.0,
        'poids': 2,
        'sousPeriodeId': 'sous-periode-1',
        'periodeScolaireId': null,
        'chapitreIds': ['chap-1', 'chap-2'],
      };

      final entity = EvaluationModel.fromJson(json).toEntity();

      expect(entity.id, 'ev-1');
      expect(entity.coursId, 'cours-1');
      expect(entity.type, TypeEvaluation.interro);
      expect(entity.date, DateTime(2025, 11, 10));
      expect(entity.maxPoints, 10.0);
      expect(entity.poids, 2);
      expect(entity.sousPeriodeId, 'sous-periode-1');
      expect(entity.periodeScolaireId, isNull);
      expect(entity.chapitreIds, const ['chap-1', 'chap-2']);
    });

    test('EXAMEN : maxPoints entier (num) coercé en double, chapitres absents '
        '-> []', () {
      final json = <String, dynamic>{
        'id': 'ev-2',
        'coursId': 'cours-1',
        'type': 'EXAMEN',
        'date': '2025-12-01',
        'maxPoints': 20, // entier côté wire
        'poids': 1,
        'periodeScolaireId': 'periode-1',
        // sousPeriodeId et chapitreIds absents
      };

      final entity = EvaluationModel.fromJson(json).toEntity();

      expect(entity.type, TypeEvaluation.examen);
      expect(entity.maxPoints, 20.0);
      expect(entity.sousPeriodeId, isNull);
      expect(entity.periodeScolaireId, 'periode-1');
      expect(entity.chapitreIds, isEmpty);
    });

    test('type inconnu -> TypeEvaluation.unknown (résilience)', () {
      final json = <String, dynamic>{
        'id': 'ev-3',
        'coursId': 'cours-1',
        'type': 'SOMETHING_NEW',
        'date': '2025-12-01',
        'maxPoints': 20.0,
        'poids': 1,
        'periodeScolaireId': 'periode-1',
      };

      final entity = EvaluationModel.fromJson(json).toEntity();

      expect(entity.type, TypeEvaluation.unknown);
    });
  });
}
