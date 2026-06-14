import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/core/entities/stats_context.dart';
import 'package:school_app_flutter/features/attendances/domain/entities/attendance_overview/absence_reason_stats.dart';
import 'package:school_app_flutter/features/attendances/domain/entities/attendance_overview/attendance_evolution.dart';
import 'package:school_app_flutter/features/attendances/domain/entities/attendance_overview/attendance_kpis.dart';
import 'package:school_app_flutter/features/attendances/domain/entities/attendance_overview/class_attendance_stat.dart';
import 'package:school_app_flutter/features/attendances/domain/entities/attendance_overview/top_absent_class.dart';
import 'package:school_app_flutter/features/attendances/domain/entities/attendance_overview/weekday_absence_stat.dart';

/// Tableau de bord de presence a l'echelle de l'ecole, pour une periode
/// (annee / mois / semaine). Donnees de `/api/v1/attendance-stats/overview`.
class AttendanceOverview extends Equatable {
  final StatsContext context;
  final AttendanceKpis kpis;
  final AttendanceEvolution evolution;
  final List<ClassAttendanceStat> byClass;
  final List<TopAbsentClass> topAbsentClasses;
  final List<AbsenceReasonStats> byAbsenceReason;
  final List<WeekdayAbsenceStat> byWeekday;

  const AttendanceOverview({
    required this.context,
    required this.kpis,
    required this.evolution,
    this.byClass = const [],
    this.topAbsentClasses = const [],
    this.byAbsenceReason = const [],
    this.byWeekday = const [],
  });

  @override
  List<Object?> get props => [
    context,
    kpis,
    evolution,
    byClass,
    topAbsentClasses,
    byAbsenceReason,
    byWeekday,
  ];
}
