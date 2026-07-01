import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/features/academics/data/models/notation/note_eleve_model.dart';
import 'package:school_app_flutter/features/academics/domain/entities/notation/statut_note.dart';

void main() {
  group('NoteEleveModel.fromJson + toEntity', () {
    test('élève noté : points (num) coercés en double + statut mappé', () {
      final json = <String, dynamic>{
        'studentId': 's1',
        'firstName': 'Jean',
        'lastName': 'Dupont',
        'middleName': 'Marie',
        'pointsObtenus': 15, // entier côté wire
        'statut': 'NOTEE',
      };

      final entity = NoteEleveModel.fromJson(json).toEntity();

      expect(entity.studentId, 's1');
      expect(entity.firstName, 'Jean');
      expect(entity.lastName, 'Dupont');
      expect(entity.middleName, 'Marie');
      expect(entity.pointsObtenus, 15.0);
      expect(entity.statut, StatutNote.notee);
    });

    test('élève sans saisie : statut null préservé (≠ unknown)', () {
      final json = <String, dynamic>{
        'studentId': 's2',
        'firstName': 'Awa',
        'lastName': 'Kone',
        // middleName, pointsObtenus, statut absents/null
        'pointsObtenus': null,
        'statut': null,
      };

      final entity = NoteEleveModel.fromJson(json).toEntity();

      expect(entity.middleName, isNull);
      expect(entity.pointsObtenus, isNull);
      expect(entity.statut, isNull);
    });

    test('statut inconnu (non-null) -> StatutNote.unknown (résilience)', () {
      final json = <String, dynamic>{
        'studentId': 's3',
        'firstName': 'Bob',
        'lastName': 'Martin',
        'statut': 'SOMETHING_NEW',
      };

      final entity = NoteEleveModel.fromJson(json).toEntity();

      expect(entity.statut, StatutNote.unknown);
    });

    test('ABSENT_JUSTIFIE avec points null', () {
      final json = <String, dynamic>{
        'studentId': 's4',
        'firstName': 'Zoé',
        'lastName': 'Ba',
        'pointsObtenus': null,
        'statut': 'ABSENT_JUSTIFIE',
      };

      final entity = NoteEleveModel.fromJson(json).toEntity();

      expect(entity.statut, StatutNote.absentJustifie);
      expect(entity.pointsObtenus, isNull);
    });
  });
}
