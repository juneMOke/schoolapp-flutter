import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/features/academics/domain/entities/sujet/evaluation_cadre.dart';
import 'package:school_app_flutter/features/academics/domain/entities/sujet/sujet_bareme.dart';
import 'package:school_app_flutter/features/academics/domain/entities/sujet/sujet_question.dart';

void main() {
  group('SujetBareme', () {
    SujetBareme of(double total) => SujetBareme(total: total, maxPoints: 20);

    test('les quatre cas', () {
      expect(of(0).status, BaremeStatus.empty);
      expect(of(18).status, BaremeStatus.under);
      expect(of(20).status, BaremeStatus.complete);
      expect(of(23).status, BaremeStatus.over);
    });

    test('écart et progression plafonnée', () {
      expect(of(18).gap, 2);
      expect(of(23).gap, 3);
      expect(of(10).fraction, 0.5);
      expect(of(30).fraction, 1);
    });

    test('tolère l’arrondi des décimaux', () {
      expect(of(19.9999).status, BaremeStatus.complete);
    });
  });

  test('question incomplète : énoncé vide ou points non positifs', () {
    expect(
      const SujetQuestion(id: 'a', enonce: 'X', points: 2).isIncomplete,
      isFalse,
    );
    expect(
      const SujetQuestion(id: 'a', enonce: ' ', points: 2).isIncomplete,
      isTrue,
    );
    expect(const SujetQuestion(id: 'a', enonce: 'X').isIncomplete, isTrue);
    expect(
      const SujetQuestion(id: 'a', enonce: 'X', points: 0).isIncomplete,
      isTrue,
    );
  });

  test('cadre normalisé', () {
    const cadre = EvaluationCadre(
      dureeMinutes: 0,
      programme: [' A ', '', 'B'],
      consignes: '  ',
    );
    expect(cadre.normalized(), const EvaluationCadre(programme: ['A', 'B']));
  });
}
