import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/features/academics/data/models/notation/note_evaluation_model.dart';
import 'package:school_app_flutter/features/academics/domain/entities/notation/statut_note.dart';

void main() {
  group('NoteEvaluationModel.fromJson + toEntity', () {
    test('note persistée NOTEE : tous les champs mappés', () {
      final json = <String, dynamic>{
        'id': 'n1',
        'evaluationId': 'ev1',
        'studentId': 's1',
        'pointsObtenus': 12, // entier côté wire
        'statut': 'NOTEE',
      };

      final entity = NoteEvaluationModel.fromJson(json).toEntity();

      expect(entity.id, 'n1');
      expect(entity.evaluationId, 'ev1');
      expect(entity.studentId, 's1');
      expect(entity.pointsObtenus, 12.0);
      expect(entity.statut, StatutNote.notee);
    });

    test('EN_ATTENTE : points null, statut mappé', () {
      final json = <String, dynamic>{
        'id': 'n2',
        'evaluationId': 'ev1',
        'studentId': 's2',
        'pointsObtenus': null,
        'statut': 'EN_ATTENTE',
      };

      final entity = NoteEvaluationModel.fromJson(json).toEntity();

      expect(entity.pointsObtenus, isNull);
      expect(entity.statut, StatutNote.enAttente);
    });

    test('statut inconnu -> unknown (résilience)', () {
      final json = <String, dynamic>{
        'id': 'n3',
        'evaluationId': 'ev1',
        'studentId': 's3',
        'statut': 'WAT',
      };

      final entity = NoteEvaluationModel.fromJson(json).toEntity();

      expect(entity.statut, StatutNote.unknown);
    });
  });
}
