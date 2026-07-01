import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/features/academics/data/models/notation/saisir_note_request_model.dart';
import 'package:school_app_flutter/features/academics/domain/entities/notation/saisir_note_request.dart';
import 'package:school_app_flutter/features/academics/domain/entities/notation/statut_note.dart';

void main() {
  group('toJson — pointsObtenus émis SSI statut == NOTEE', () {
    test('NOTEE : émet studentId, statut wire et pointsObtenus', () {
      final json = const SaisirNoteRequestModel(
        studentId: 's1',
        statut: StatutNote.notee,
        pointsObtenus: 15,
      ).toJson();

      expect(json['studentId'], 's1');
      expect(json['statut'], 'NOTEE');
      expect(json['pointsObtenus'], 15);
    });

    test('ABSENT_JUSTIFIE : n\'émet pas pointsObtenus', () {
      final json = const SaisirNoteRequestModel(
        studentId: 's1',
        statut: StatutNote.absentJustifie,
      ).toJson();

      expect(json['statut'], 'ABSENT_JUSTIFIE');
      expect(json.containsKey('pointsObtenus'), isFalse);
    });

    test('EN_ATTENTE : n\'émet pas pointsObtenus', () {
      final json = const SaisirNoteRequestModel(
        studentId: 's1',
        statut: StatutNote.enAttente,
      ).toJson();

      expect(json['statut'], 'EN_ATTENTE');
      expect(json.containsKey('pointsObtenus'), isFalse);
    });
  });

  group('fromDomain', () {
    test('NOTEE : reprend les points du domaine', () {
      final request = SaisirNoteRequest.forStatut(
        studentId: 's1',
        statut: StatutNote.notee,
        pointsObtenus: 8,
      );

      final json = SaisirNoteRequestModel.fromDomain(request).toJson();

      expect(json['statut'], 'NOTEE');
      expect(json['pointsObtenus'], 8);
    });

    test(
      'ABSENT_NON_JUSTIFIE : points déjà nuls par construction, non émis',
      () {
        final request = SaisirNoteRequest.forStatut(
          studentId: 's1',
          statut: StatutNote.absentNonJustifie,
          pointsObtenus: 99, // ignoré côté domaine
        );

        final json = SaisirNoteRequestModel.fromDomain(request).toJson();

        expect(json['statut'], 'ABSENT_NON_JUSTIFIE');
        expect(json.containsKey('pointsObtenus'), isFalse);
      },
    );
  });
}
