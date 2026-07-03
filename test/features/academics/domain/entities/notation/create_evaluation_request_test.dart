import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/features/academics/domain/entities/notation/create_evaluation_request.dart';
import 'package:school_app_flutter/features/academics/domain/entities/notation/type_evaluation.dart';

void main() {
  final tDate = DateTime(2025, 11, 10);

  group('CreateEvaluationRequest.examen', () {
    test('rattache la période scolaire et laisse la sous-période nulle', () {
      final request = CreateEvaluationRequest.examen(
        date: tDate,
        maxPoints: 20,
        periodeScolaireId: 'periode-1',
      );

      expect(request.type, TypeEvaluation.examen);
      expect(request.periodeScolaireId, 'periode-1');
      expect(request.sousPeriodeId, isNull);
      // poids omis par défaut (le backend appliquera 1).
      expect(request.poids, isNull);
      expect(request.chapitreIds, isEmpty);
    });

    test('conserve poids et chapitres fournis', () {
      final request = CreateEvaluationRequest.examen(
        date: tDate,
        maxPoints: 20,
        periodeScolaireId: 'periode-1',
        poids: 3,
        chapitreIds: const ['chap-1', 'chap-2'],
      );

      expect(request.poids, 3);
      expect(request.chapitreIds, const ['chap-1', 'chap-2']);
    });
  });

  group('CreateEvaluationRequest.journaliere', () {
    test('INTERRO rattache la sous-période et laisse la période nulle', () {
      final request = CreateEvaluationRequest.journaliere(
        type: TypeEvaluation.interro,
        date: tDate,
        maxPoints: 10,
        sousPeriodeId: 'sous-periode-1',
      );

      expect(request.type, TypeEvaluation.interro);
      expect(request.sousPeriodeId, 'sous-periode-1');
      expect(request.periodeScolaireId, isNull);
    });

    test('DEVOIR rattache la sous-période et laisse la période nulle', () {
      final request = CreateEvaluationRequest.journaliere(
        type: TypeEvaluation.devoir,
        date: tDate,
        maxPoints: 10,
        sousPeriodeId: 'sous-periode-1',
      );

      expect(request.type, TypeEvaluation.devoir);
      expect(request.sousPeriodeId, 'sous-periode-1');
      expect(request.periodeScolaireId, isNull);
    });
  });

  test('égalité par valeur (Equatable)', () {
    final a = CreateEvaluationRequest.examen(
      date: tDate,
      maxPoints: 20,
      periodeScolaireId: 'periode-1',
    );
    final b = CreateEvaluationRequest.examen(
      date: tDate,
      maxPoints: 20,
      periodeScolaireId: 'periode-1',
    );

    expect(a, b);
  });

  group('validation à l\'exécution (active aussi en release)', () {
    test('journaliere refuse EXAMEN', () {
      expect(
        () => CreateEvaluationRequest.journaliere(
          type: TypeEvaluation.examen,
          date: tDate,
          maxPoints: 10,
          sousPeriodeId: 'sous-periode-1',
        ),
        throwsArgumentError,
      );
    });

    test('journaliere refuse unknown', () {
      expect(
        () => CreateEvaluationRequest.journaliere(
          type: TypeEvaluation.unknown,
          date: tDate,
          maxPoints: 10,
          sousPeriodeId: 'sous-periode-1',
        ),
        throwsArgumentError,
      );
    });

    test('maxPoints <= 0 est rejeté', () {
      expect(
        () => CreateEvaluationRequest.examen(
          date: tDate,
          maxPoints: 0,
          periodeScolaireId: 'periode-1',
        ),
        throwsArgumentError,
      );
      expect(
        () => CreateEvaluationRequest.journaliere(
          type: TypeEvaluation.interro,
          date: tDate,
          maxPoints: -1,
          sousPeriodeId: 'sous-periode-1',
        ),
        throwsArgumentError,
      );
    });

    test('poids <= 0 (s\'il est fourni) est rejeté', () {
      expect(
        () => CreateEvaluationRequest.examen(
          date: tDate,
          maxPoints: 20,
          periodeScolaireId: 'periode-1',
          poids: 0,
        ),
        throwsArgumentError,
      );
    });

    test('id temporel vide est rejeté', () {
      expect(
        () => CreateEvaluationRequest.examen(
          date: tDate,
          maxPoints: 20,
          periodeScolaireId: '',
        ),
        throwsArgumentError,
      );
      expect(
        () => CreateEvaluationRequest.journaliere(
          type: TypeEvaluation.devoir,
          date: tDate,
          maxPoints: 10,
          sousPeriodeId: '',
        ),
        throwsArgumentError,
      );
    });
  });
}
