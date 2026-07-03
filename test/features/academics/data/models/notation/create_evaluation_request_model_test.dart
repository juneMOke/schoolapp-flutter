import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/features/academics/data/models/notation/create_evaluation_request_model.dart';
import 'package:school_app_flutter/features/academics/domain/entities/notation/create_evaluation_request.dart';
import 'package:school_app_flutter/features/academics/domain/entities/notation/type_evaluation.dart';

void main() {
  final tDate = DateTime(2025, 11, 10);

  group('toJson — émission conditionnelle', () {
    test('EXAMEN minimal : un seul id temporel, ni poids ni chapitres', () {
      final json = CreateEvaluationRequestModel(
        type: 'EXAMEN',
        date: tDate,
        maxPoints: 20,
        periodeScolaireId: 'periode-1',
      ).toJson();

      expect(json['type'], 'EXAMEN');
      expect(json['date'], '2025-11-10');
      expect(json['maxPoints'], 20.0);
      expect(json['periodeScolaireId'], 'periode-1');
      // Champs à NE PAS émettre.
      expect(json.containsKey('sousPeriodeId'), isFalse);
      expect(json.containsKey('poids'), isFalse);
      expect(json.containsKey('chapitreIds'), isFalse);
    });

    test('INTERRO avec poids et chapitres : tout est émis', () {
      final json = CreateEvaluationRequestModel(
        type: 'INTERRO',
        date: tDate,
        maxPoints: 10,
        poids: 2,
        sousPeriodeId: 'sous-periode-1',
        chapitreIds: const ['chap-1', 'chap-2'],
      ).toJson();

      expect(json['type'], 'INTERRO');
      expect(json['date'], '2025-11-10');
      expect(json['maxPoints'], 10.0);
      expect(json['poids'], 2);
      expect(json['sousPeriodeId'], 'sous-periode-1');
      expect(json['chapitreIds'], const ['chap-1', 'chap-2']);
      expect(json.containsKey('periodeScolaireId'), isFalse);
    });

    test('chapitreIds vide est omis', () {
      final json = CreateEvaluationRequestModel(
        type: 'DEVOIR',
        date: tDate,
        maxPoints: 10,
        sousPeriodeId: 'sous-periode-1',
        chapitreIds: const [],
      ).toJson();

      expect(json.containsKey('chapitreIds'), isFalse);
    });
  });

  group('fromDomain', () {
    test('EXAMEN : convertit le type en valeur wire et porte la période', () {
      final request = CreateEvaluationRequest.examen(
        date: tDate,
        maxPoints: 20,
        periodeScolaireId: 'periode-1',
      );

      final json = CreateEvaluationRequestModel.fromDomain(request).toJson();

      expect(json['type'], 'EXAMEN');
      expect(json['periodeScolaireId'], 'periode-1');
      expect(json.containsKey('sousPeriodeId'), isFalse);
      expect(json.containsKey('poids'), isFalse);
    });

    test('INTERRO journalière : type wire et sous-période', () {
      final request = CreateEvaluationRequest.journaliere(
        type: TypeEvaluation.interro,
        date: tDate,
        maxPoints: 10,
        sousPeriodeId: 'sous-periode-1',
        poids: 4,
      );

      final json = CreateEvaluationRequestModel.fromDomain(request).toJson();

      expect(json['type'], 'INTERRO');
      expect(json['sousPeriodeId'], 'sous-periode-1');
      expect(json['poids'], 4);
      expect(json.containsKey('periodeScolaireId'), isFalse);
    });
  });
}
