import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/features/attendances/domain/entities/student_absence_entry.dart';
import 'package:school_app_flutter/features/attendances/domain/entities/student_attendance_summary.dart';

/// Vue derivee de [StudentAttendanceSummary] pour l'onglet Presence.
///
/// Les compteurs sont derives a l'affichage (jamais stockes) ; le taux vient
/// du backend (`presenceRate`) et n'est pas recalcule.
class PresenceSummaryViewData {
  final StudentAttendanceSummary summary;

  const PresenceSummaryViewData(this.summary);

  int get present => summary.presentDays;
  int get justified => summary.justifiedAbsenceDays;
  int get unjustified => summary.unjustifiedAbsenceDays;

  /// Jours scolaires sur la periode (present + absences).
  int get total => present + justified + unjustified;

  /// Taux fourni par le backend.
  double get rate => summary.presenceRate;

  /// Taux arrondi pour l'affichage.
  int get ratePercent => rate.round();

  /// Seuils de lecture rapide (>= 95 vert, 88-94 ambre, < 88 rouge).
  Color get rateColor {
    if (rate >= 95) return AppColors.vertSavane;
    if (rate >= 88) return AppColors.warning;
    return AppColors.error;
  }

  /// `true` s'il existe au moins un jour scolaire sur la periode.
  bool get hasSchoolDays => total > 0;

  /// Assiduite parfaite : des jours scolaires, mais aucune absence.
  bool get isPerfect => hasSchoolDays && justified == 0 && unjustified == 0;

  /// Absences de la periode, triees du plus recent au plus ancien.
  List<StudentAbsenceEntry> get sortedAbsences {
    final list = [...summary.absences];
    list.sort((a, b) => b.date.compareTo(a.date));
    return list;
  }
}
