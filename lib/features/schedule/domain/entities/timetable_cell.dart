import 'package:equatable/equatable.dart';

/// Contenu d'une case de la grille : une séance placée à un créneau, un jour.
///
/// Read-model **dénormalisé** : la case porte déjà tous les libellés résolus
/// côté backend (classe / matière / enseignant), afin d'être répliquée offline
/// en local sans aucune jointure.
class TimetableCell extends Equatable {
  final String sessionId;
  final String coursId;
  final String classroomId;
  final String classroomLabel;
  final String teacherId;
  final String teacherLabel;
  final String subjectLabel;

  /// Salle de cours, optionnelle.
  final String? room;

  const TimetableCell({
    required this.sessionId,
    required this.coursId,
    required this.classroomId,
    required this.classroomLabel,
    required this.teacherId,
    required this.teacherLabel,
    required this.subjectLabel,
    this.room,
  });

  @override
  List<Object?> get props => [
    sessionId,
    coursId,
    classroomId,
    classroomLabel,
    teacherId,
    teacherLabel,
    subjectLabel,
    room,
  ];
}
