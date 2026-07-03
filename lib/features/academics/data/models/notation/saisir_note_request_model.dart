import 'package:school_app_flutter/features/academics/domain/entities/notation/saisir_note_request.dart';
import 'package:school_app_flutter/features/academics/domain/entities/notation/statut_note.dart';

/// Corps JSON du `PUT` de saisie (`SaisirNoteRequest`).
///
/// [toJson] applique la règle d'émission conditionnelle du contrat :
/// - `statut` en valeur wire majuscule (NOTEE / ABSENT_JUSTIFIE / … ) ;
/// - `pointsObtenus` **émis uniquement si `statut == NOTEE`** (le backend le
///   remet à null pour les autres statuts, cf. règle 2). Par construction du
///   [SaisirNoteRequest] domaine, `pointsObtenus` est alors non nul.
class SaisirNoteRequestModel {
  final String studentId;
  final double? pointsObtenus;
  final StatutNote statut;

  const SaisirNoteRequestModel({
    required this.studentId,
    required this.statut,
    this.pointsObtenus,
  });

  factory SaisirNoteRequestModel.fromDomain(SaisirNoteRequest request) =>
      SaisirNoteRequestModel(
        studentId: request.studentId,
        statut: request.statut,
        pointsObtenus: request.pointsObtenus,
      );

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{
      'studentId': studentId,
      'statut': statut.toApiValue(),
    };
    // Points émis seulement pour NOTEE (sinon ignorés/remis à null côté backend).
    if (statut == StatutNote.notee) {
      json['pointsObtenus'] = pointsObtenus;
    }
    return json;
  }
}
