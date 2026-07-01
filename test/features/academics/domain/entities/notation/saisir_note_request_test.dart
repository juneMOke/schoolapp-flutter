import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/features/academics/domain/entities/notation/saisir_note_request.dart';
import 'package:school_app_flutter/features/academics/domain/entities/notation/statut_note.dart';

void main() {
  group('SaisirNoteRequest.forStatut — cohérence statut/points', () {
    test('NOTEE avec points : porte les points', () {
      final request = SaisirNoteRequest.forStatut(
        studentId: 's1',
        statut: StatutNote.notee,
        pointsObtenus: 15,
      );

      expect(request.statut, StatutNote.notee);
      expect(request.pointsObtenus, 15);
      expect(request.studentId, 's1');
    });

    test('NOTEE sans points -> ArgumentError', () {
      expect(
        () => SaisirNoteRequest.forStatut(
          studentId: 's1',
          statut: StatutNote.notee,
        ),
        throwsArgumentError,
      );
    });

    test(
      'statuts non-NOTEE : points forcés à null même si fournis (règle 2)',
      () {
        for (final statut in const [
          StatutNote.absentJustifie,
          StatutNote.absentNonJustifie,
          StatutNote.enAttente,
        ]) {
          final request = SaisirNoteRequest.forStatut(
            studentId: 's1',
            statut: statut,
            pointsObtenus: 99, // doit être ignoré
          );

          expect(request.statut, statut);
          expect(
            request.pointsObtenus,
            isNull,
            reason: '$statut ne porte pas de points',
          );
        }
      },
    );

    test('UNKNOWN -> ArgumentError (aucune saisie possible)', () {
      expect(
        () => SaisirNoteRequest.forStatut(
          studentId: 's1',
          statut: StatutNote.unknown,
        ),
        throwsArgumentError,
      );
    });

    test('studentId vide -> ArgumentError', () {
      expect(
        () => SaisirNoteRequest.forStatut(
          studentId: '',
          statut: StatutNote.enAttente,
        ),
        throwsArgumentError,
      );
    });
  });
}
