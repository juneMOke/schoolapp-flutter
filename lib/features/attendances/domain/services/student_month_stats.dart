import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/core/presence/domain/presence_status.dart';
import 'package:school_app_flutter/features/attendances/domain/entities/register/class_presence_month.dart';

/// La synthèse d'un élève sur un mois — calculée, **jamais stockée**.
///
/// Règles de la spec (Présences des élèves v2, §14) :
/// - jours de classe : lundi → vendredi, jusqu'à aujourd'hui ;
/// - présences : présent + retard ; taux = présences / jours de classe
///   (1 sans jour de classe) ;
/// - un jour sans appel est « non pointé » — présent une fois le mois clos ;
/// - à surveiller : au moins [watchUnjustifiedAbsences] absences non
///   justifiées, ou un taux sous [watchMinRate] dès qu'un jour est pointé ;
/// - assiduité parfaite : pointé, sans retard ni absence.
class StudentMonthStats extends Equatable {
  final int schoolDays;
  final int presences;
  final int late;
  final int lateMinutes;
  final int lateUnjustified;
  final int absentJustified;
  final int absentUnjustified;
  final int notMarked;

  const StudentMonthStats({
    required this.schoolDays,
    required this.presences,
    required this.late,
    required this.lateMinutes,
    required this.lateUnjustified,
    required this.absentJustified,
    required this.absentUnjustified,
    required this.notMarked,
  });

  /// Seuils fixes en V1 (spec, points à arbitrer : réglables par école plus
  /// tard).
  static const int watchUnjustifiedAbsences = 2;
  static const double watchMinRate = 0.85;

  int get absent => absentJustified + absentUnjustified;

  /// Jours où l'élève a été pointé.
  int get marked => schoolDays - notMarked;

  double get rate => schoolDays == 0 ? 1 : presences / schoolDays;

  bool get toWatch =>
      absentUnjustified >= watchUnjustifiedAbsences ||
      (marked > 0 && rate < watchMinRate);

  bool get perfect => marked > 0 && late == 0 && absent == 0;

  /// La synthèse de [studentId] sur les [schoolDays] du mois.
  factory StudentMonthStats.of(
    ClassPresenceMonth month,
    String studentId, {
    required List<String> schoolDays,
  }) {
    var presences = 0;
    var late = 0;
    var lateMinutes = 0;
    var lateUnjustified = 0;
    var absentJustified = 0;
    var absentUnjustified = 0;
    var notMarked = 0;
    for (final day in schoolDays) {
      if (!month.calledDays.contains(day)) {
        if (month.closed) {
          presences++;
        } else {
          notMarked++;
        }
        continue;
      }
      final incident = month.incidentOf(day, studentId);
      switch (incident?.status ?? PresenceStatus.present) {
        case PresenceStatus.none:
        case PresenceStatus.present:
          presences++;
        case PresenceStatus.late:
          presences++;
          late++;
          lateMinutes += incident!.mark.lateMinutes;
          if (incident.mark.needsJustification) lateUnjustified++;
        case PresenceStatus.absent:
          if (incident!.mark.needsJustification) {
            absentUnjustified++;
          } else {
            absentJustified++;
          }
      }
    }
    return StudentMonthStats(
      schoolDays: schoolDays.length,
      presences: presences,
      late: late,
      lateMinutes: lateMinutes,
      lateUnjustified: lateUnjustified,
      absentJustified: absentJustified,
      absentUnjustified: absentUnjustified,
      notMarked: notMarked,
    );
  }

  @override
  List<Object?> get props => [
    schoolDays,
    presences,
    late,
    lateMinutes,
    lateUnjustified,
    absentJustified,
    absentUnjustified,
    notMarked,
  ];
}
