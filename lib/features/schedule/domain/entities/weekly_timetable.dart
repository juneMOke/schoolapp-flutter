import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/features/schedule/domain/entities/timetable_row.dart';
import 'package:school_app_flutter/features/schedule/domain/entities/weekday.dart';

/// Emploi du temps hebdomadaire **récurrent** : une matrice créneau × jour.
///
/// L'emploi du temps n'a pas d'instances datées par semaine : c'est une grille
/// type qui se répète. [teacherId] est renseigné pour `my-timetable`
/// (enseignant connecté, [classroomId] nul) ; [classroomId] pour `grid`
/// (grille d'une classe, [teacherId] nul).
///
/// [days] = colonnes de la matrice (LUN→SAM) ; [rows] = créneaux de sonnerie
/// triés (les lignes). Pour chaque ligne, `row.cells[day]` donne la séance de
/// cette case, ou `null` si le créneau est libre.
class WeeklyTimetable extends Equatable {
  final String academicYearId;
  final String? teacherId;
  final String? classroomId;
  final List<Weekday> days;
  final List<TimetableRow> rows;

  const WeeklyTimetable({
    required this.academicYearId,
    this.teacherId,
    this.classroomId,
    required this.days,
    required this.rows,
  });

  @override
  List<Object?> get props => [
    academicYearId,
    teacherId,
    classroomId,
    days,
    rows,
  ];
}
