import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/features/attendances/domain/entities/offline/student_attendance_stats.dart';
import 'package:school_app_flutter/features/attendances/domain/entities/student_absence_entry.dart';

/// Vue derivee de [StudentAttendanceStats] (calcul 100% local) pour l'onglet
/// Presence. Les compteurs sont derives a l'affichage (jamais stockes) ; le
/// taux vient du calcul local (dénominateur = jours réellement appelés).
class PresenceSummaryViewData {
  final StudentAttendanceStats stats;

  const PresenceSummaryViewData(this.stats);

  int get present => stats.present;
  int get justified => stats.justifiedAbsences;
  int get unjustified => stats.unjustifiedAbsences;

  /// Jours scolaires sur la periode (= jours reellement appeles).
  int get total => stats.daysCalled;

  /// Taux [0..100], `null` si aucun jour appele (pas de division par zero).
  double? get rate => stats.rate == null ? null : stats.rate! * 100;

  /// Taux arrondi pour l'affichage (0 si indisponible : gate par [hasSchoolDays]).
  int get ratePercent => (rate ?? 0).round();

  /// Seuils de lecture rapide (>= 95 vert, 88-94 ambre, < 88 rouge).
  Color get rateColor {
    final r = rate ?? 0;
    if (r >= 95) return AppColors.vertSavane;
    if (r >= 88) return AppColors.warning;
    return AppColors.error;
  }

  /// `true` s'il existe au moins un jour scolaire (appele) sur la periode.
  bool get hasSchoolDays => total > 0;

  /// Assiduite parfaite : des jours scolaires, mais aucune absence.
  bool get isPerfect => hasSchoolDays && justified == 0 && unjustified == 0;

  /// Absences de la periode, triees du plus recent au plus ancien.
  List<StudentAbsenceEntry> get sortedAbsences {
    final list = [...stats.entries];
    list.sort((a, b) => b.date.compareTo(a.date));
    return list;
  }
}
