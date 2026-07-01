import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/features/academics/domain/entities/notation/statut_note.dart';

/// Une ligne de la grille de saisie : l'identité d'un élève de la classe du
/// cours, enrichie de sa note pour l'évaluation courante (réponse
/// `NoteEleveDto`).
///
/// [pointsObtenus] et [statut] sont nuls tant qu'aucune note n'a été saisie pour
/// cet élève (et [pointsObtenus] l'est aussi quand [statut] n'est pas
/// [StatutNote.notee], le backend le remettant à null).
class NoteEleve extends Equatable {
  final String studentId;
  final String firstName;
  final String lastName;
  final String? middleName;

  /// Points obtenus, `null` si aucune saisie ou si [statut] != NOTEE.
  final double? pointsObtenus;

  /// `null` tant qu'aucune saisie n'existe pour cet élève.
  final StatutNote? statut;

  const NoteEleve({
    required this.studentId,
    required this.firstName,
    required this.lastName,
    this.middleName,
    this.pointsObtenus,
    this.statut,
  });

  @override
  List<Object?> get props => [
    studentId,
    firstName,
    lastName,
    middleName,
    pointsObtenus,
    statut,
  ];
}
