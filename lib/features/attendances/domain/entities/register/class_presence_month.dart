import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/core/offline/record_sync_state.dart';
import 'package:school_app_flutter/core/presence/domain/school_day_calendar.dart';
import 'package:school_app_flutter/features/attendances/domain/entities/register/class_presence_line.dart';
import 'package:school_app_flutter/features/attendances/domain/entities/register/class_presence_student.dart';

/// Les appels d'une classe sur un mois, tels que la tablette les connaît :
/// les jours appelés et, ces jours-là, les retards et absences de chacun.
///
/// Seuls les appels **validés** comptent ; un brouillon n'est pas un appel.
class ClassPresenceMonth extends Equatable {
  final String classroomId;
  final String academicYearId;

  /// `YYYY-MM`.
  final String month;

  /// La classe d'aujourd'hui, par numéro d'ordre.
  final List<ClassPresenceStudent> students;

  /// Les jours où l'appel a été fait (`YYYY-MM-DD`).
  final Set<String> calledDays;

  /// Jour → élève → son retard ou son absence. Un élève absent de la table
  /// un jour appelé était présent.
  final Map<String, Map<String, ClassPresenceLine>> incidents;

  /// Le mois est clôturé : ses jours sans appel comptent présents.
  final bool closed;

  /// L'envoi le moins avancé des appels du mois.
  final RecordSyncState sync;

  const ClassPresenceMonth({
    required this.classroomId,
    required this.academicYearId,
    required this.month,
    required this.students,
    required this.calledDays,
    required this.incidents,
    this.closed = false,
    this.sync = RecordSyncState.synced,
  });

  /// Les jours de classe du mois (lundi → vendredi), jusqu'à [today] et dans
  /// l'année scolaire [year]. Vide = vacances.
  List<String> schoolDays({required String today, SchoolYearBounds? year}) =>
      SchoolDayCalendar.workDaysOf(month, today: today, year: year);

  ClassPresenceLine? incidentOf(String day, String studentId) =>
      incidents[day]?[studentId];

  @override
  List<Object?> get props => [
    classroomId,
    academicYearId,
    month,
    students,
    calledDays,
    incidents,
    closed,
    sync,
  ];
}
