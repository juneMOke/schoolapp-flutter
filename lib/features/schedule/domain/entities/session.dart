import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/features/schedule/domain/entities/weekday.dart';

/// Séance placée à l'emploi du temps (réponse plate `SessionDto` du POST de
/// placement d'un cours).
///
/// Read-model **dénormalisé** : porte déjà les libellés classe / matière /
/// enseignant résolus côté backend.
class Session extends Equatable {
  final String id;
  final String academicYearId;
  final String coursId;
  final String timeSlotId;
  final Weekday day;

  /// Salle de cours, optionnelle.
  final String? room;

  final String teacherId;
  final String classroomId;
  final String teacherLabel;
  final String classroomLabel;
  final String subjectLabel;

  const Session({
    required this.id,
    required this.academicYearId,
    required this.coursId,
    required this.timeSlotId,
    required this.day,
    this.room,
    required this.teacherId,
    required this.classroomId,
    required this.teacherLabel,
    required this.classroomLabel,
    required this.subjectLabel,
  });

  @override
  List<Object?> get props => [
    id,
    academicYearId,
    coursId,
    timeSlotId,
    day,
    room,
    teacherId,
    classroomId,
    teacherLabel,
    classroomLabel,
    subjectLabel,
  ];
}
