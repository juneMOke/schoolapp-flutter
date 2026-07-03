import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/features/academics/domain/entities/notation/statut_periode.dart';
import 'package:school_app_flutter/features/resultats/data/models/periode_scolaire_model.dart';
import 'package:school_app_flutter/features/resultats/domain/entities/decoupage.dart';

void main() {
  group('PeriodeScolaireModel (parseur tolérant)', () {
    test('contrat réel PeriodeScolaireResumeDto → entité complète', () {
      final entity = PeriodeScolaireModel.fromJson(const {
        'periodeScolaireId': 'ps-2',
        'ordre': 2,
        'periodType': 'SEMESTER',
        'libelle': 'Semestre 2',
        'startDate': '2026-02-01',
        'endDate': '2026-07-15',
        'statut': 'OUVERTE',
        'courant': true,
      }).toEntity();

      expect(entity.id, 'ps-2');
      expect(entity.ordre, 2);
      expect(entity.decoupage, Decoupage.semestre);
      expect(entity.statut, StatutPeriode.ouverte);
      expect(entity.libelle, 'Semestre 2');
      expect(entity.startDate, DateTime(2026, 2, 1));
      expect(entity.endDate, DateTime(2026, 7, 15));
      expect(entity.courant, isTrue);
    });

    test('clés canoniques → entité mappée (découpage + statut + libellé)', () {
      final model = PeriodeScolaireModel.fromJson(const {
        'id': 'p1',
        'ordre': 1,
        'periodType': 'TRIMESTRE',
        'statut': 'OUVERTE',
        'libelle': '1er trimestre',
      });
      final entity = model.toEntity();

      expect(entity.id, 'p1');
      expect(entity.ordre, 1);
      expect(entity.decoupage, Decoupage.trimestre);
      expect(entity.statut, StatutPeriode.ouverte);
      expect(entity.libelle, '1er trimestre');
      // Champs dates/courant absents → défauts sûrs.
      expect(entity.startDate, isNull);
      expect(entity.endDate, isNull);
      expect(entity.courant, isFalse);
    });

    test('clés wire alternatives acceptées (id/ordre/type/status/label)', () {
      final model = PeriodeScolaireModel.fromJson(const {
        'periodeScolaireId': 'p2',
        'order': '2',
        'decoupage': 'SEMESTER',
        'status': 'CLOTUREE',
        'label': 'Semestre 2',
      });
      final entity = model.toEntity();

      expect(entity.id, 'p2');
      expect(entity.ordre, 2);
      expect(entity.decoupage, Decoupage.semestre);
      expect(entity.statut, StatutPeriode.cloturee);
      expect(entity.libelle, 'Semestre 2');
    });

    test('id absent → FormatException (période inexploitable)', () {
      expect(
        () => PeriodeScolaireModel.fromJson(const {'ordre': 1}),
        throwsA(isA<FormatException>()),
      );
    });

    test('ordre absent → défaut 0 ; periodType inconnu → unknown', () {
      final entity = PeriodeScolaireModel.fromJson(const {
        'id': 'p3',
        'periodType': 'YEAR',
      }).toEntity();

      expect(entity.ordre, 0);
      expect(entity.decoupage, Decoupage.unknown);
      expect(entity.statut, StatutPeriode.unknown);
    });

    test('libellé vide → null (l\'UI composera T{n}/S{n})', () {
      final entity = PeriodeScolaireModel.fromJson(const {
        'id': 'p4',
        'ordre': 1,
        'libelle': '   ',
      }).toEntity();

      expect(entity.libelle, isNull);
    });
  });
}
