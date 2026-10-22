import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/features/academics/data/models/notation/saisir_note_request_model.dart';
import 'package:school_app_flutter/features/academics/data/models/offline/academics_metier_pull_models.dart';
import 'package:school_app_flutter/features/academics/data/models/offline/note_evaluation_row.dart';
import 'package:school_app_flutter/features/academics/data/models/offline/note_input_model.dart';
import 'package:school_app_flutter/features/academics/domain/entities/notation/saisir_note_request.dart';
import 'package:school_app_flutter/features/academics/domain/entities/notation/statut_note.dart';

void main() {
  NoteEvaluationRow row(String? commentaire) => NoteEvaluationRow(
    id: 'n1',
    evaluationId: 'e1',
    studentId: 's1',
    pointsObtenus: 12,
    statut: 'NOTEE',
    updatedAt: 1000,
    commentaire: commentaire,
  );

  group('ligne de lot (NoteLineInput)', () {
    test('sans commentaire, le champ est omis : le serveur garde le sien', () {
      expect(
        NoteInputModel.fromRow(row(null)).toJson(),
        isNot(contains('commentaire')),
      );
    });

    test('un commentaire vidé part en "" : le serveur le retire', () {
      expect(NoteInputModel.fromRow(row('')).toJson()['commentaire'], '');
    });

    test('un texte part tel quel et revient de la file', () {
      final json = NoteInputModel.fromRow(row('Bien')).toJson();
      expect(json['commentaire'], 'Bien');
      expect(NoteInputModel.fromJson(json).commentaire, 'Bien');
    });
  });

  test('saisie unitaire : même règle', () {
    SaisirNoteRequestModel model(String? commentaire) =>
        SaisirNoteRequestModel.fromDomain(
          SaisirNoteRequest.forStatut(
            studentId: 's1',
            statut: StatutNote.absentJustifie,
            commentaire: commentaire,
          ),
        );
    expect(model(null).toJson(), isNot(contains('commentaire')));
    expect(model('').toJson()['commentaire'], '');
  });

  test('pull : le commentaire du serveur descend dans la ligne', () {
    final dto = NoteDeltaDto.fromJson({
      'id': 'n1',
      'evaluationId': 'e1',
      'studentId': 's1',
      'statut': 'NOTEE',
      'pointsObtenus': 12,
      'serverUpdatedAt': '2026-10-20T08:00:00Z',
      'commentaire': 'Bon travail',
    });
    expect(dto.toLocalRow(1).commentaire, 'Bon travail');
  });
}
